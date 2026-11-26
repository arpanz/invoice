import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/localization/l10n.dart';

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
    final l10n = context.l10n;
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
          text: l10n.invoiceFor(invoice.invoiceNumber, invoice.clientName),
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
          title: Text(l10n.markAsSent),
          content: Text(l10n.didYouSendTo(invoice.invoiceNumber, invoice.clientName)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.notYet)),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.markAsSentAction)),
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
          SnackBar(content: Text(l10n.couldNotShareTheInvoicePleaseTryAgain)),
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
    final l10n = context.l10n;
    try {
      final bytes = pdfBytes ??
          await InvoiceRenderService.renderInvoice(
            invoice,
            isPro: context.read<BillingService>().isPro,
          );
      final name = FileExport.pdfName('Invoice', invoice.invoiceNumber);
      final saved = await FileExport.savePdf(bytes, name, localizations: l10n);
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
          content: Text(l10n.savedTo(name, saved.placeLabel)),
          persist: false,
          action: SnackBarAction(
            label: l10n.view,
            onPressed: () async {
              if (!await FileExport.open(saved)) {
                messenger.showSnackBar(
                  SnackBar(content: Text(l10n.noAppFoundToOpenPdfsInstallA)),
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
          SnackBar(content: Text(l10n.couldNotSaveThePdfPleaseTryAgain)),
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
            title: context.l10n.markUnpaidQuestion,
            message: context.l10n.deleteRecordedPayments(count, invoice.invoiceNumber),
            variant: AppDialogVariant.danger,
            icon: AppIcons.warning,
            confirmLabel: context.l10n.deletePayments,
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
          SnackBar(content: Text(context.l10n.couldNotUpdateThePaymentPleaseTryAgain)),
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
          SnackBar(content: Text(context.l10n.couldNotOpenPrintingPleaseTryAgain)),
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
      title: context.l10n.deleteInvoiceQuestion,
      message: context.l10n.deleteThisCannotBeUndone(invoice.invoiceNumber),
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
          SnackBar(content: Text(context.l10n.couldNotDeleteTheInvoicePleaseTryAgain)),
        );
      }
      return false;
    }
  }
}
