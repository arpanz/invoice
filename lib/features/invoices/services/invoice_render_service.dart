import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/database/db_provider.dart';
import '../models/invoice_customization_config.dart';
import '../models/invoice_model.dart';
import '../models/pdf_theme.dart';
import 'pdf_generator_service.dart';

/// The one way to turn a saved invoice into a PDF.
///
/// Every screen (preview, Invoices list, History, share, print, save) goes
/// through here, so the same invoice always produces the same document:
/// - the issuer details come from the snapshot taken when the invoice was
///   saved, not from today's business profile;
/// - the design is resolved in one fixed order (see [designForInvoice]).
class InvoiceRenderService {
  InvoiceRenderService._();

  static const _profileKeys = {
    'businessName': 'biz_name',
    'address': 'biz_address',
    'phone': 'biz_phone',
    'email': 'biz_email',
    'website': 'biz_website',
    'gstin': 'biz_gstin',
    'bankName': 'biz_bank_name',
    'accountNumber': 'biz_account',
    'ifscCode': 'biz_ifsc',
    'upiId': 'biz_upi',
    'logoPath': 'biz_logo_path',
    'signaturePath': 'biz_signature_path',
  };

  /// JSON of the current business profile, to store on an invoice at save.
  /// [signaturePath] overrides the profile signature for this invoice only.
  static Future<String> captureIssuerSnapshot({String? signaturePath}) async {
    final prefs = await SharedPreferences.getInstance();
    final map = <String, String?>{
      for (final e in _profileKeys.entries) e.key: prefs.getString(e.value),
    };
    if (signaturePath != null) map['signaturePath'] = signaturePath;
    return jsonEncode(map);
  }

  /// The business profile as it is now.
  static BusinessProfile liveProfile(SharedPreferences prefs, String currency) {
    return BusinessProfile(
      businessName: prefs.getString('biz_name') ?? 'My Business',
      address: prefs.getString('biz_address'),
      phone: prefs.getString('biz_phone'),
      email: prefs.getString('biz_email'),
      website: prefs.getString('biz_website'),
      gstin: prefs.getString('biz_gstin'),
      bankName: prefs.getString('biz_bank_name'),
      accountNumber: prefs.getString('biz_account'),
      ifscCode: prefs.getString('biz_ifsc'),
      upiId: prefs.getString('biz_upi'),
      logoPath: prefs.getString('biz_logo_path'),
      signaturePath: prefs.getString('biz_signature_path'),
      currency: currency,
    );
  }

  /// Parses a stored snapshot. Returns null when [json] is null or unreadable.
  static BusinessProfile? profileFromSnapshot(String? json, String currency) {
    if (json == null || json.isEmpty) return null;
    try {
      final map = (jsonDecode(json) as Map).cast<String, dynamic>();
      String? s(String k) {
        final v = map[k];
        return v is String && v.trim().isNotEmpty ? v : null;
      }

      return BusinessProfile(
        businessName: s('businessName') ?? 'My Business',
        address: s('address'),
        phone: s('phone'),
        email: s('email'),
        website: s('website'),
        gstin: s('gstin'),
        bankName: s('bankName'),
        accountNumber: s('accountNumber'),
        ifscCode: s('ifscCode'),
        upiId: s('upiId'),
        logoPath: s('logoPath'),
        signaturePath: s('signaturePath'),
        currency: currency,
      );
    } catch (e) {
      debugPrint('Unreadable issuer snapshot: $e');
      return null;
    }
  }

  /// Issuer details for [invoice]: its snapshot, or the live profile for
  /// invoices saved before snapshots existed.
  static Future<BusinessProfile> profileFor(InvoiceModel invoice) async {
    final fromSnapshot = profileFromSnapshot(invoice.issuerSnapshot, invoice.currency);
    if (fromSnapshot != null) return fromSnapshot;
    final prefs = await SharedPreferences.getInstance();
    return liveProfile(prefs, invoice.currency);
  }

  /// The design for an invoice, in this order:
  /// 1. the design customised for this invoice;
  /// 2. the template picked for this invoice;
  /// 3. the default design from Settings;
  /// 4. the default template.
  /// With a null [invoiceId], the defaults only (a new invoice).
  static Future<InvoiceCustomizationConfig> designForInvoice(String? invoiceId) async {
    final prefs = await SharedPreferences.getInstance();
    return designFrom(
      ownConfig: invoiceId == null ? null : prefs.getString('invoice_customization_$invoiceId'),
      ownTheme: invoiceId == null ? null : prefs.getString('invoice_theme_$invoiceId'),
      defaultConfig: prefs.getString('default_invoice_customization'),
      defaultTheme: prefs.getString('default_pdf_theme'),
    );
  }

  /// The custom design saved as the default (Design Studio's "set as
  /// default"), or null when the default is a plain template or nothing is
  /// saved. A new invoice or estimate starts from it and stores it on its
  /// first save; storing only the template id would outrank this default
  /// and drop its fonts, colours and layout.
  static Future<InvoiceCustomizationConfig?> defaultCustomDesign() async {
    final prefs = await SharedPreferences.getInstance();
    return InvoiceCustomizationConfig.tryFromJsonString(prefs.getString('default_invoice_customization'));
  }

  /// Pure form of [designForInvoice].
  static InvoiceCustomizationConfig designFrom({
    String? ownConfig,
    String? ownTheme,
    String? defaultConfig,
    String? defaultTheme,
  }) {
    final own = InvoiceCustomizationConfig.tryFromJsonString(ownConfig ?? '');
    if (ownConfig != null && own != null) return own;
    if (ownTheme != null) return InvoiceCustomizationConfig.fromTheme(PdfTheme.fromId(ownTheme));
    final def = InvoiceCustomizationConfig.tryFromJsonString(defaultConfig ?? '');
    if (defaultConfig != null && def != null) return def;
    if (defaultTheme != null) return InvoiceCustomizationConfig.fromTheme(PdfTheme.fromId(defaultTheme));
    return const InvoiceCustomizationConfig();
  }

  /// Stores a design chosen for one invoice.
  static Future<void> saveDesignForInvoice(String invoiceId, InvoiceCustomizationConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('invoice_customization_$invoiceId', config.toJsonString());
    await prefs.setString('invoice_theme_$invoiceId', config.themeId.value);
  }

  /// Stores a template picked for one invoice, replacing any custom design.
  static Future<void> saveThemeForInvoice(String invoiceId, PdfTheme theme) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('invoice_customization_$invoiceId');
    await prefs.setString('invoice_theme_$invoiceId', theme.id.value);
  }

  /// Renders [invoice]. [design] overrides the stored design (live preview).
  static Future<Uint8List> renderInvoice(
    InvoiceModel invoice, {
    required bool isPro,
    InvoiceCustomizationConfig? design,
  }) async {
    final profile = await profileFor(invoice);
    final config = design ?? await designForInvoice(invoice.id);
    return PdfGeneratorService.generateInvoicePdf(
      invoice: invoice,
      businessProfile: profile,
      isPro: isPro,
      customizationConfig: config,
    );
  }

  /// Removes per-invoice preferences when an invoice is deleted.
  static Future<void> forgetInvoice(String invoiceId) async {
    final prefs = await SharedPreferences.getInstance();
    for (final key in [
      'invoice_customization_$invoiceId',
      'invoice_theme_$invoiceId',
    ]) {
      await prefs.remove(key);
    }
  }

  /// One-time passes after the v5 database upgrade:
  /// - invoices saved before snapshots existed get today's profile frozen onto
  ///   them, so from now on profile edits no longer change them;
  /// - the old "sent" flags in preferences move to the `sent_at` column.
  static Future<void> runOneTimeMigrations() async {
    final prefs = await SharedPreferences.getInstance();

    const snapshotDone = 'issuer_snapshot_backfill_v1_done';
    if (!(prefs.getBool(snapshotDone) ?? false)) {
      try {
        final snapshot = await captureIssuerSnapshot();
        await DbProvider.update(
          DbProvider.tableInvoices,
          {'issuer_snapshot': snapshot},
          'issuer_snapshot IS NULL',
          [],
        );
        await prefs.setBool(snapshotDone, true);
      } catch (e) {
        debugPrint('Issuer snapshot backfill failed: $e');
      }
    }

    const sentDone = 'sent_flag_migration_v1_done';
    if (!(prefs.getBool(sentDone) ?? false)) {
      try {
        const prefix = 'invoice_sent_';
        for (final key in prefs.getKeys().where((k) => k.startsWith(prefix)).toList()) {
          if (prefs.getBool(key) ?? false) {
            final id = key.substring(prefix.length);
            await DbProvider.execute(
              'UPDATE ${DbProvider.tableInvoices} SET sent_at = updated_at '
              'WHERE id = ? AND sent_at IS NULL',
              [id],
            );
          }
          await prefs.remove(key);
        }
        await prefs.setBool(sentDone, true);
      } catch (e) {
        debugPrint('Sent flag migration failed: $e');
      }
    }
  }
}
