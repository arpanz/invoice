import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../../core/billing/free_limits.dart';
import '../../../core/database/db_provider.dart';
import '../../../core/utils/payment_terms.dart';
import '../../../shared_widgets/app_dialog.dart';
import '../../invoices/models/invoice_customization_config.dart';
import '../../invoices/models/invoice_model.dart';
import '../../invoices/models/pdf_theme.dart';
import '../../invoices/services/invoice_render_service.dart';
import '../../invoices/services/pdf_generator_service.dart';
import '../models/estimate_model.dart';
import '../screens/create_estimate_screen.dart' show defaultEstimateNote;

/// Estimate actions shared by the Estimates tab and the estimate preview.
class EstimateActions {
  EstimateActions._();

  /// True when [estimate] has been turned into an invoice. Its status can't
  /// be changed and it can't be converted again.
  static bool isLocked(EstimateModel estimate) =>
      estimate.status == EstimateStatus.converted || estimate.convertedInvoiceId != null;

  /// Asks, checks the free plan, then converts [estimate] into a new invoice
  /// in one transaction. Returns the invoice, or null if nothing was created.
  static Future<InvoiceModel?> convert(BuildContext context, EstimateModel estimate) async {
    if (isLocked(estimate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This estimate is already converted to an invoice.')),
      );
      return null;
    }
    final confirm = await AppDialog.showConvertEstimate(
      context: context,
      estimateNumber: estimate.estimateNumber,
      clientName: estimate.clientName,
    );
    if (confirm != true || !context.mounted) return null;
    if (!await FreeLimits.canCreateInvoice(context)) return null;

    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      final termsDays = paymentTermsDays(prefs.getString('default_payment_terms'));
      final invoiceNote = prefs.getString('biz_notes');
      // The estimate's own boilerplate ("valid for 30 days") does not belong
      // on an invoice; a note the user wrote does.
      final keepNote = estimate.notes != null && estimate.notes!.trim() != defaultEstimateNote;
      final notes = keepNote
          ? estimate.notes
          : ((invoiceNote?.trim().isNotEmpty ?? false) ? invoiceNote!.trim() : null);
      final snapshot = await InvoiceRenderService.captureIssuerSnapshot();
      final newInvoiceId = const Uuid().v4();

      final invoice = await DbProvider.convertEstimate(
        estimate,
        (number) {
          final draft = estimate.toInvoiceModel(
            newInvoiceId: newInvoiceId,
            newInvoiceNumber: number,
            invoiceDate: now,
            dueDate: now.add(Duration(days: termsDays)),
          );
          return draft.copyWith(
            issuerSnapshot: snapshot,
            notes: notes,
            clearNotes: notes == null,
          );
        },
        newId: () => const Uuid().v4(),
      );

      // The invoice starts with the estimate's design.
      final ownConfig = InvoiceCustomizationConfig.tryFromJsonString(
        prefs.getString('estimate_customization_${estimate.id}'),
      );
      final ownTheme = prefs.getString('estimate_theme_${estimate.id}');
      if (ownConfig != null) {
        await InvoiceRenderService.saveDesignForInvoice(invoice.id, ownConfig);
      } else if (ownTheme != null) {
        await InvoiceRenderService.saveThemeForInvoice(invoice.id, PdfTheme.fromId(ownTheme));
      }
      return invoice;
    } on AlreadyConvertedException {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('This estimate is already converted to an invoice.')),
        );
      }
      return null;
    } catch (e) {
      debugPrint('Convert estimate failed: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not convert the estimate. Please try again.')),
        );
      }
      return null;
    }
  }

  /// Asks for confirmation, then deletes [estimate] and its lines.
  static Future<bool> confirmAndDelete(BuildContext context, EstimateModel estimate) async {
    final confirm = await AppDialog.showDelete(
      context: context,
      title: 'Delete Estimate?',
      message: 'Delete ${estimate.estimateNumber}? This cannot be undone.',
    );
    if (confirm != true) return false;
    try {
      await DbProvider.deleteEstimate(estimate.id);
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('estimate_customization_${estimate.id}');
      await prefs.remove('estimate_theme_${estimate.id}');
      return true;
    } catch (e) {
      debugPrint('Delete estimate failed: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not delete the estimate. Please try again.')),
        );
      }
      return false;
    }
  }

  /// The design for an estimate: its own design, its own template, then the
  /// defaults (the same order as invoices).
  static Future<InvoiceCustomizationConfig> designForEstimate(String estimateId) async {
    final prefs = await SharedPreferences.getInstance();
    return InvoiceRenderService.designFrom(
      ownConfig: prefs.getString('estimate_customization_$estimateId'),
      ownTheme: prefs.getString('estimate_theme_$estimateId'),
      defaultConfig: prefs.getString('default_invoice_customization'),
      defaultTheme: prefs.getString('default_pdf_theme'),
    );
  }

  /// The business profile as it is now (estimates are quotes, not records,
  /// so they are not frozen).
  static Future<BusinessProfile> profileFor(EstimateModel estimate) async {
    final prefs = await SharedPreferences.getInstance();
    return InvoiceRenderService.liveProfile(prefs, estimate.currency);
  }

  /// Renders [estimate]. [design] overrides the stored design.
  static Future<Uint8List> render(
    EstimateModel estimate, {
    required bool isPro,
    InvoiceCustomizationConfig? design,
  }) async {
    return PdfGeneratorService.generateEstimatePdf(
      estimate: estimate,
      businessProfile: await profileFor(estimate),
      isPro: isPro,
      customizationConfig: design ?? await designForEstimate(estimate.id),
    );
  }
}
