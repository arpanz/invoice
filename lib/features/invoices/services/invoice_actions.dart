import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/app/app_review_service.dart';
import '../../../core/billing/billing_service.dart';
import '../../../core/database/db_provider.dart';
import '../../../core/utils/file_export.dart';
import '../../../core/utils/pdf_helper.dart';
import '../../../shared_widgets/app_dialog.dart';
import '../models/invoice_model.dart';
import 'invoice_render_service.dart';
import 'pdf_generator_service.dart';
import '../widgets/payments_sheet.dart';
import '../../../core/theme/app_icons.dart';

/// Invoice actions shared by the preview, the Invoices tab and History, so
/// each behaves the same wherever it is started.
class InvoiceActions {
  InvoiceActions._();

  /// Shares [invoice] as a PDF ([pdfBytes] if already rendered), then asks
  /// whether it was sent. Returns the invoice with `sentAt` set if the user
  /// marked it as sent, else null.
  static Future<InvoiceModel?> share(
    BuildContext context,
    InvoiceModel invoice, {
    Uint8List? pdfBytes,
  }) async {
    try {
      final bytes = pdfBytes ??
          await InvoiceRenderService.renderInvoice(
            invoice,
            isPro: context.read<BillingService>().isPro,
          );
      final path = await PdfGeneratorService.saveAndGetPath(bytes, invoice.invoiceNumber);
      final result = await SharePlus.instance.share(
        ShareParams(
          files: [XFile(path)],
          text: 'Invoice ${invoice.invoiceNumber} for ${invoice.clientName}',
        ),
      );
      // Counted now; the review card waits until the question below is
      // answered, so the two never stack.
      await AppReviewService.instance.registerSignificantAction(prompt: false);

      // Opening the share sheet is not sending: ask, unless the user backed
      // out of the sheet or the invoice is already marked as sent.
      if (!context.mounted ||
          invoice.sentAt != null ||
          result.status == ShareResultStatus.dismissed) {
        // No question follows here, so the review card may show now.
        if (result.status != ShareResultStatus.dismissed) AppReviewService.instance.maybeRequestReview();
        return null;
      }
      final mark = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Mark as sent?'),
          content: Text('Did you send ${invoice.invoiceNumber} to ${invoice.clientName}?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Not yet')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Mark as sent')),
          ],
        ),
      );
      if (mark != true) return null;
      final sentAt = await setSent(invoice.id, true);
      // Just sent an invoice: a good moment to ask.
      AppReviewService.instance.maybeRequestReview();
      return invoice.copyWith(sentAt: sentAt);
    } catch (e) {
      debugPrint('Share invoice failed: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not share the invoice. Please try again.')),
        );
      }
      return null;
    }
  }

  /// Saves [invoice] as a PDF where the user can find it (Downloads on
  /// Android), with a working "View" action. Falls back to the share sheet.
  static Future<void> saveToDevice(
    BuildContext context,
    InvoiceModel invoice, {
    Uint8List? pdfBytes,
  }) async {
    try {
      final bytes = pdfBytes ??
          await InvoiceRenderService.renderInvoice(
            invoice,
            isPro: context.read<BillingService>().isPro,
          );
      final name = FileExport.pdfName('Invoice', invoice.invoiceNumber);
      final saved = await FileExport.savePdf(bytes, name);
      await AppReviewService.instance.registerSignificantAction();
      if (saved == null) {
        await FileExport.saveViaShareSheet(bytes, name);
        return;
      }
      if (!context.mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Saved $name to ${saved.placeLabel}'),
          persist: false,
          action: SnackBarAction(
            label: 'View',
            onPressed: () async {
              if (!await FileExport.open(saved)) {
                messenger.showSnackBar(
                  const SnackBar(content: Text('No app found to open PDFs. Install a PDF viewer to open it.')),
                );
              }
            },
          ),
        ),
      );
    } catch (e) {
      debugPrint('Save invoice failed: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not save the PDF. Please try again.')),
        );
      }
    }
  }

  /// Moves [invoice] to [target] through its payments:
  /// - Paid: records a payment for the balance, dated today.
  /// - Partially paid: opens the record-payment form (adds a payment).
  /// - Unpaid: after confirming, deletes every recorded payment.
  /// Returns true if anything changed.
  static Future<bool> changePaymentStatus(
    BuildContext context,
    InvoiceModel invoice,
    InvoiceStatus target,
  ) async {
    try {
      switch (target) {
        case InvoiceStatus.paid:
          await DbProvider.markPaidInFull(invoice.id);
          return true;
        case InvoiceStatus.partiallyPaid:
          final payment = await RecordPaymentSheet.show(
            context,
            invoice: invoice,
            balance: invoice.grandTotal - invoice.paidAmount,
          );
          if (payment == null) return false;
          await DbProvider.addPayment(payment);
          return true;
        case InvoiceStatus.unpaid:
          if (invoice.paidAmount <= 0.005) return false;
          final count = (await DbProvider.paymentsFor(invoice.id)).length;
          if (!context.mounted) return false;
          final ok = await AppDialog.showConfirmation(
            context: context,
            title: 'Mark as unpaid?',
            message: count == 1
                ? 'This deletes the 1 payment recorded for ${invoice.invoiceNumber}.'
                : 'This deletes the $count payments recorded for ${invoice.invoiceNumber}.',
            variant: AppDialogVariant.danger,
            icon: AppIcons.warning,
            confirmLabel: 'Delete payments',
            isDestructive: true,
          );
          if (ok != true) return false;
          await DbProvider.clearPayments(invoice.id);
          return true;
        case InvoiceStatus.overdue:
          // Overdue is worked out from the due date, never set by hand.
          return false;
      }
    } catch (e) {
      debugPrint('Change payment status failed: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not update the payment. Please try again.')),
        );
      }
      return false;
    }
  }

  /// Opens the system print dialog for [invoice].
  static Future<void> printPdf(BuildContext context, InvoiceModel invoice) async {
    try {
      final bytes = await InvoiceRenderService.renderInvoice(
        invoice,
        isPro: context.read<BillingService>().isPro,
      );
      await Printing.layoutPdf(
        onLayout: (_) async => bytes,
        name: 'Invoice_${invoice.invoiceNumber}',
      );
    } catch (e) {
      debugPrint('Print invoice failed: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open printing. Please try again.')),
        );
      }
    }
  }

  /// Stores whether the invoice was sent. Returns the stored time, or null.
  static Future<DateTime?> setSent(String invoiceId, bool sent) async {
    final sentAt = sent ? DateTime.now() : null;
    await DbProvider.update(
      DbProvider.tableInvoices,
      {'sent_at': sentAt?.millisecondsSinceEpoch},
      'id = ?',
      [invoiceId],
    );
    return sentAt;
  }

  /// Asks for confirmation, then deletes [invoice], its lines, its stored
  /// design and its cached PDF. Returns true if it was deleted.
  static Future<bool> confirmAndDelete(BuildContext context, InvoiceModel invoice) async {
    final confirm = await AppDialog.showDelete(
      context: context,
      title: 'Delete Invoice?',
      message: 'Delete ${invoice.invoiceNumber}? This cannot be undone.',
    );
    if (confirm != true) return false;
    try {
      await DbProvider.deleteInvoice(invoice.id);
      await InvoiceRenderService.forgetInvoice(invoice.id);
      await PdfHelper.deletePdf(invoice.invoiceNumber);
      return true;
    } catch (e) {
      debugPrint('Delete invoice failed: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not delete the invoice. Please try again.')),
        );
      }
      return false;
    }
  }
}
