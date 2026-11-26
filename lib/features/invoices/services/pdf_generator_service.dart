import 'dart:io';
import 'dart:ui' as ui;
import '../../../core/utils/number_text.dart';
import '../../../core/utils/amount_in_words.dart';
import '../../../core/utils/document_totals.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/document_custom_field.dart';
import '../models/invoice_customization_config.dart';
import '../models/invoice_model.dart';
import '../models/pdf_theme.dart';
import 'dummy_invoice_data.dart';
import '../../../core/models/currency_model.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/pdf_helper.dart';
import '../../../core/utils/pdf_script_fonts.dart';
import '../../estimates/models/estimate_model.dart';

class BusinessProfile {
  final String businessName;
  final String? address;
  final String? phone;
  final String? email;
  final String? website;
  final String? gstin;
  final String? bankName;
  final String? accountNumber;
  final String? ifscCode;
  final String? upiId;
  final String? logoPath;
  final String? signaturePath;
  final String currency;
  final String? invoiceTitleOverride;

  const BusinessProfile({
    required this.businessName,
    this.address,
    this.phone,
    this.email,
    this.website,
    this.gstin,
    this.bankName,
    this.accountNumber,
    this.ifscCode,
    this.upiId,
    this.logoPath,
    this.signaturePath,
    this.currency = 'INR',
    this.invoiceTitleOverride,
  });

  BusinessProfile copyWith({
    String? businessName,
    String? address,
    String? phone,
    String? email,
    String? website,
    String? gstin,
    String? bankName,
    String? accountNumber,
    String? ifscCode,
    String? upiId,
    String? logoPath,
    String? signaturePath,
    String? currency,
    String? invoiceTitleOverride,
  }) {
    return BusinessProfile(
      businessName: businessName ?? this.businessName,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      website: website ?? this.website,
      gstin: gstin ?? this.gstin,
      bankName: bankName ?? this.bankName,
      accountNumber: accountNumber ?? this.accountNumber,
      ifscCode: ifscCode ?? this.ifscCode,
      upiId: upiId ?? this.upiId,
      logoPath: logoPath ?? this.logoPath,
      signaturePath: signaturePath ?? this.signaturePath,
      currency: currency ?? this.currency,
      invoiceTitleOverride: invoiceTitleOverride ?? this.invoiceTitleOverride,
    );
  }

  Currency? get currencyConfig => SupportedCurrencies.getByCode(currency);
  String get taxIdLabel => currencyConfig?.defaultTax.taxIdLabel ?? 'Tax ID';
  String get bankRoutingLabel => currencyConfig?.defaultTax.bankRoutingLabel ?? 'Routing / IFSC';
  String get bankAccountLabel => currencyConfig?.defaultTax.bankAccountLabel ?? 'Account Number';
  String get digitalPaymentLabel => currencyConfig?.defaultTax.digitalPaymentLabel ?? 'Digital Payment';
  String get invoiceTitle => invoiceTitleOverride ?? currencyConfig?.defaultTax.invoiceTitle ?? 'INVOICE';

  /// True when this profile renders an estimate.
  bool get isEstimate => invoiceTitleOverride == 'ESTIMATE';
  String get numberLabel => isEstimate ? 'Estimate #' : 'Invoice #';
  String get dueLabel => isEstimate ? 'Valid Until' : 'Due Date';

  /// The document title for [invoice]: a tax title only when tax applies.
  String titleFor(InvoiceModel invoice) {
    if (invoiceTitleOverride != null) return invoiceTitleOverride!;
    final base = currencyConfig?.defaultTax.invoiceTitle ?? 'INVOICE';
    final hasTax = invoice.sgstRate + invoice.cgstRate + invoice.igstRate > 0 ||
        invoice.lineItems.any((l) => (l.taxRate ?? 0) > 0);
    if (hasTax) return base;
    const withoutTax = {
      'TAX INVOICE': 'INVOICE',
      'SALES TAX INVOICE': 'INVOICE',
      'MUSHAK 6.3 INVOICE': 'INVOICE',
      'FAKTURA VAT': 'FAKTURA',
      'FAKTUR PAJAK': 'FAKTUR',
      'HÓA ĐƠN GTGT': 'HÓA ĐƠN',
    };
    return withoutTax[base] ?? base;
  }
  bool get isDualTax => currencyConfig?.defaultTax.isDualTax ?? false;
  String get taxShortName => currencyConfig?.defaultTax.shortName ?? 'Tax';
  int get decimalPlaces => currencyConfig?.decimalPlaces ?? 2;
}

class PdfGeneratorService {
  /// Up to two initials from a business name, for monogram badges.
  static String _initials(String name) {
    final words = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return '';
    final letters = words.take(2).map((w) => String.fromCharCode(w.runes.first).toUpperCase());
    return letters.join();
  }

  PdfGeneratorService._();

  static Future<Uint8List> generateEstimatePdf({
    required EstimateModel estimate,
    required BusinessProfile businessProfile,
    required bool isPro,
    PdfTheme? theme,
    InvoiceCustomizationConfig? customizationConfig,
    bool isSamplePreview = false,
  }) async {
    final estimateProfile = BusinessProfile(
      businessName: businessProfile.businessName,
      address: businessProfile.address,
      phone: businessProfile.phone,
      email: businessProfile.email,
      website: businessProfile.website,
      gstin: businessProfile.gstin,
      bankName: businessProfile.bankName,
      accountNumber: businessProfile.accountNumber,
      ifscCode: businessProfile.ifscCode,
      upiId: businessProfile.upiId,
      logoPath: businessProfile.logoPath,
      signaturePath: businessProfile.signaturePath,
      currency: estimate.currency,
      invoiceTitleOverride: 'ESTIMATE',
    );

    final inv = InvoiceModel(
      id: estimate.id,
      invoiceNumber: estimate.estimateNumber,
      clientId: estimate.clientId,
      clientName: estimate.clientName,
      clientEmail: estimate.clientEmail,
      clientPhone: estimate.clientPhone,
      clientAddress: estimate.clientAddress,
      clientGstin: estimate.clientGstin,
      invoiceDate: estimate.estimateDate,
      dueDate: estimate.expiryDate,
      subtotal: estimate.subtotal,
      discountType: estimate.discountType,
      discountValue: estimate.discountValue,
      discountAmount: estimate.discountAmount,
      sgstRate: estimate.sgstRate,
      cgstRate: estimate.cgstRate,
      igstRate: estimate.igstRate,
      taxAmount: estimate.taxAmount,
      grandTotal: estimate.grandTotal,
      status: InvoiceStatus.unpaid,
      notes: estimate.notes,
      customFields: estimate.customFields,
      currency: estimate.currency,
      createdAt: estimate.createdAt,
      updatedAt: estimate.updatedAt,
      lineItems: estimate.lineItems,
    );

    return generateInvoicePdf(
      invoice: inv,
      businessProfile: estimateProfile,
      isPro: isPro,
      theme: theme,
      customizationConfig: customizationConfig,
      isSamplePreview: isSamplePreview,
    );
  }

  static Future<Uint8List> generateInvoicePdf({
    required InvoiceModel invoice,
    required BusinessProfile businessProfile,
    required bool isPro,
    PdfTheme? theme,
    InvoiceCustomizationConfig? customizationConfig,
    bool isSamplePreview = false,
    DateTime? paidOn,
  }) async {
    final config = customizationConfig ??
        (theme != null
            ? InvoiceCustomizationConfig.fromTheme(theme)
            : InvoiceCustomizationConfig.defaultConfig);
    final activeTheme = config.toPdfTheme();
    final pageFonts = await documentFonts(
      config,
      [
        // Every text field, so a script used anywhere (issuer snapshot,
        // payment method, notes...) gets its font.
        ...invoice.toMap().values.whereType<String>(),
        for (final item in invoice.lineItems) ...[item.description, item.unit ?? '', item.hsnSac ?? ''],
        businessProfile.businessName,
        businessProfile.address ?? '',
        businessProfile.bankName ?? '',
        config.customFooterMessage ?? '',
      ].join('\n'),
    );

    final pdf = pw.Document(
      title: 'Invoice ${invoice.invoiceNumber}',
      author: businessProfile.businessName,
    );

    final attachments = <pw.MemoryImage>[];
    if (config.showAttachments && !businessProfile.isEstimate) {
      for (final path in invoice.attachments) {
        final image = await _loadAttachmentImage(path);
        if (image != null) attachments.add(image);
      }
    }
    final currencySymbol = CurrencyFormatter.getCurrencySymbol(
      businessProfile.currency,
    );
    final dateFormat = DateFormat('dd MMM yyyy');
    final doc = _DocumentLayout(
      invoice: invoice,
      profile: businessProfile,
      theme: activeTheme,
      config: config,
      s: config.density.scaleFactor,
      logo: await loadImage(businessProfile.logoPath),
      signature: await loadImage(businessProfile.signaturePath),
      isPro: isPro,
      isSample: isSamplePreview,
      paidOn: paidOn,
      // Every printed figure comes from the same calculation the editor
      // uses, so the rows always add up to the total.
      totals: DocumentTotals.ofInvoice(invoice),
      money: (v) => CurrencyFormatter.format(v, currencyCode: invoice.currency, currencySymbol: currencySymbol),
      date: dateFormat.format,
    );

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: doc.pageMargin,
          buildBackground: doc.background,
          theme: pageFonts,
        ),
        // The footer keeps the same height on every page: MultiPage measures
        // it before the page count is final, and a footer that grew later
        // would be drawn over page 1's content.
        footer: doc.pageFooter,
        build: (_) => [...doc.build(), ...doc.attachmentPages(attachments)],
      ),
    );

    return pdf.save();
  }

  static const freePlanCredit = 'Generated by Invoice Maker Pro';

  static Future<pw.ThemeData> documentFonts(InvoiceCustomizationConfig config, String text) async {
    final fonts = await _PdfFonts.load(config.fontFamily);
    final scriptFonts = await PdfScriptFonts.fontsFor(text);
    return pw.ThemeData.withFont(
      base: fonts.base,
      bold: fonts.bold,
      fontFallback: [...fonts.fallback, ...scriptFonts],
    );
  }

  static Future<pw.MemoryImage?> loadImage(String? path) async {
    if (path == null || path.isEmpty) return null;
    try {
      return pw.MemoryImage(await File(path).readAsBytes());
    } catch (_) {
      return null;
    }
  }

  static Future<pw.MemoryImage?> _loadAttachmentImage(String path) async {
    try {
      final bytes = await File(path).readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      try {
        final frame = await codec.getNextFrame();
        try {
          // Embed JPEGs directly. Encode other formats as PNG so the PDF
          // can also carry photos in formats the device decoded itself.
          if (bytes.length >= 2 && bytes[0] == 0xff && bytes[1] == 0xd8) {
            return pw.MemoryImage(bytes);
          }
          final png = await frame.image.toByteData(format: ui.ImageByteFormat.png);
          return png == null ? null : pw.MemoryImage(png.buffer.asUint8List());
        } finally {
          frame.image.dispose();
        }
      } finally {
        codec.dispose();
      }
    } catch (_) {
      return null;
    }
  }

  static InvoiceStatus? statusStampFor(
    InvoiceModel invoice,
    InvoiceCustomizationConfig config, {
    bool isEstimate = false,
  }) {
    if (isEstimate || !config.showStatusStamp) return null;
    final effective = invoice.effectiveStatus;
    if (effective == InvoiceStatus.paid) {
      final recorded = InvoiceModel.paymentStatusFor(invoice.paidAmount, invoice.grandTotal);
      return recorded == InvoiceStatus.unpaid ? null : recorded;
    }
    return effective == InvoiceStatus.unpaid ? null : effective;
  }

  /// UPI IDs look like `name@bank`, and bank handles are letters only;
  /// anything else (an email, a PayPal handle) would make a QR that payment
  /// apps reject, so it is better to print none.
  static final RegExp _upiIdPattern = RegExp(r'^[A-Za-z0-9._-]{2,256}@[A-Za-z]{2,64}$');

  /// A UPI deep link that any UPI app can pay from.
  ///
  /// Built by hand because `Uri(queryParameters:)` writes spaces as `+`,
  /// which several UPI apps show literally in the payee name.
  static String upiPayUri({
    required String upiId,
    required String businessName,
    required double amount,
    required String invoiceNumber,
  }) {
    final e = Uri.encodeComponent;
    final name = businessName.trim();
    return [
      'upi://pay?pa=${e(upiId.trim())}',
      if (name.isNotEmpty) 'pn=${e(name)}',
      'am=${e(amount.toStringAsFixed(2))}',
      'cu=INR',
      'tn=${e('Invoice ${invoiceNumber.trim()}')}',
    ].join('&');
  }

  /// The scan-to-pay link for [invoice], or null when it should carry none:
  /// estimates, non-rupee invoices, settled invoices, a hidden or malformed
  /// UPI ID. [balance] is the amount still owed, as printed on the PDF.
  static String? upiQrData({
    required InvoiceModel invoice,
    required BusinessProfile profile,
    required InvoiceCustomizationConfig config,
    required double balance,
  }) {
    if (profile.isEstimate || !config.showUpiDetails) return null;
    if (invoice.currency.toUpperCase() != 'INR') return null;
    if (invoice.effectiveStatus == InvoiceStatus.paid) return null;
    final upiId = profile.upiId?.trim() ?? '';
    if (!_upiIdPattern.hasMatch(upiId)) return null;
    // Judged on the printed amount, so a rounding crumb never asks for 0.00.
    if (double.parse(balance.toStringAsFixed(2)) <= 0) return null;
    return upiPayUri(
      upiId: upiId,
      businessName: profile.businessName,
      amount: balance,
      invoiceNumber: invoice.invoiceNumber,
    );
  }

  static Future<String> saveAndGetPath(
    Uint8List pdfBytes,
    String invoiceNumber,
  ) async {
    return await PdfHelper.savePdf(pdfBytes, invoiceNumber);
  }
}

enum _TableStyle { ruled, filled, ledger, receipt }

/// Lays out one document. The look is typographic: hairline rules and
/// white space carry the structure, one accent colour carries the brand,
/// and the amount to pay is the largest figure on the page.
class _DocumentLayout {
  _DocumentLayout({
    required this.invoice,
    required this.profile,
    required this.theme,
    required this.config,
    required this.s,
    required this.logo,
    required this.signature,
    required this.isPro,
    required this.isSample,
    required this.paidOn,
    required this.totals,
    required this.money,
    required this.date,
  });

  final InvoiceModel invoice;
  final BusinessProfile profile;
  final PdfTheme theme;
  final InvoiceCustomizationConfig config;

  /// Density scale for type and spacing.
  final double s;
  final pw.MemoryImage? logo;
  final pw.MemoryImage? signature;
  final bool isPro;
  final bool isSample;
  final DateTime? paidOn;
  final DocumentTotals totals;
  final String Function(double) money;
  final String Function(DateTime) date;

  static const double _sideMargin = 46;
  static const double _bannerTopMargin = 30;
  static const double _receiptSideMargin = 100;

  PdfColor get _ink => theme.darkColor;
  PdfColor get _muted => theme.slateColor;
  /// Hairlines are a neutral tint of the text grey, so they stay visible on
  /// every paper tint (a theme's own border colour can vanish on cream).
  PdfColor get _rule => _mix(_muted, PdfColors.white, 0.72);
  PdfColor get _accent => theme.primaryColor;

  bool get _isBanner => config.headerPosition == HeaderPosition.fullWidthBanner;
  bool get _isMinimal => theme.paperStyle == PdfPaperStyle.minimalDividers;
  bool get _isLedger => theme.paperStyle == PdfPaperStyle.gstLedger;
  PdfColor get _ledgerRule => _mix(_accent, theme.borderColor, 0.55);
  double get _bannerBodyHeight => 84 * s;
  double get _bannerHeight => _bannerTopMargin * 2 + _bannerBodyHeight;

  _TableStyle get _tableStyle => switch (theme.paperStyle) {
        PdfPaperStyle.fullWidthBanner ||
        PdfPaperStyle.asymmetricSplitHeader ||
        PdfPaperStyle.cornerWave ||
        PdfPaperStyle.diagonalBand ||
        PdfPaperStyle.leftVerticalRibbon =>
          _TableStyle.filled,
        PdfPaperStyle.gstLedger => _TableStyle.ledger,
        PdfPaperStyle.receiptStrip => _TableStyle.receipt,
        _ => _TableStyle.ruled,
      };

  double get _balance => (totals.grandTotal - invoice.paidAmount).clamp(0, double.infinity).toDouble();
  bool get _hasPayments => invoice.status == InvoiceStatus.partiallyPaid || invoice.paidAmount > 0;

  static bool _filled(String? v) => v != null && v.trim().isNotEmpty;

  static PdfColor _mix(PdfColor a, PdfColor b, double t) => PdfColor(
        a.red + (b.red - a.red) * t,
        a.green + (b.green - a.green) * t,
        a.blue + (b.blue - a.blue) * t,
      );

  // ---- Type ----

  pw.TextStyle _label({PdfColor? color}) => pw.TextStyle(
        fontSize: 6.8 * s,
        fontWeight: pw.FontWeight.bold,
        letterSpacing: 1.1,
        color: color ?? _muted,
      );

  pw.TextStyle _body({PdfColor? color, bool bold = false, double size = 9}) => pw.TextStyle(
        fontSize: size * s,
        fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        color: color ?? _ink,
        lineSpacing: 1.5 * s,
      );

  // ---- Page ----

  pw.EdgeInsets get pageMargin {
    if (theme.paperStyle == PdfPaperStyle.receiptStrip) {
      return pw.EdgeInsets.fromLTRB(
        _receiptSideMargin, _isBanner ? _bannerTopMargin : 44, _receiptSideMargin, 30,
      );
    }
    if (_isBanner) return const pw.EdgeInsets.fromLTRB(_sideMargin, _bannerTopMargin, _sideMargin, 30);
    return switch (theme.paperStyle) {
      PdfPaperStyle.leftVerticalRibbon => const pw.EdgeInsets.fromLTRB(_sideMargin + 14, 44, _sideMargin, 30),
      PdfPaperStyle.architecturalFrame => const pw.EdgeInsets.fromLTRB(52, 50, 52, 38),
      PdfPaperStyle.stampBorder => const pw.EdgeInsets.fromLTRB(50, 45, 50, 36),
      PdfPaperStyle.letterheadBar => const pw.EdgeInsets.fromLTRB(_sideMargin, 52, _sideMargin, 30),
      PdfPaperStyle.topAccentLine ||
      PdfPaperStyle.doubleRule ||
      PdfPaperStyle.warmParchment =>
        const pw.EdgeInsets.fromLTRB(_sideMargin, 50, _sideMargin, 30),
      _ => const pw.EdgeInsets.fromLTRB(_sideMargin, 44, _sideMargin, 30),
    };
  }

  pw.Widget background(pw.Context context) {
    final style = theme.paperStyle;
    final bannerPage = _isBanner && context.pageNumber == 1;
    return pw.FullPage(
      ignoreMargins: true,
      child: pw.Stack(
        children: [
          if (style == PdfPaperStyle.warmParchment)
            pw.Container(color: PdfColor.fromHex('#FFFDF8'))
          else if (style == PdfPaperStyle.securityDotGrid)
            pw.Container(color: PdfColor.fromHex('#FCFDFF')),
          if (theme.id == PdfThemeId.linenRule || theme.id == PdfThemeId.mistLine)
            pw.Positioned.fill(
              child: pw.Container(color: _mix(theme.lightGray, PdfColors.white, 0.3)),
            ),
          if (theme.id == PdfThemeId.mulberrySplit &&
              config.headerPosition == HeaderPosition.logoRightDetailsLeft &&
              context.pageNumber == 1)
            pw.Positioned(
              right: 0,
              top: 0,
              child: pw.Container(
                width: PdfPageFormat.a4.width * 0.52,
                height: 111 * s,
                decoration: pw.BoxDecoration(
                  color: theme.lightGray,
                  border: pw.Border(top: pw.BorderSide(color: theme.secondaryColor, width: 2)),
                ),
              ),
            ),
          if (style == PdfPaperStyle.receiptStrip)
            pw.Positioned.fill(
              child: pw.Container(
                color: theme.lightGray,
                padding: const pw.EdgeInsets.symmetric(horizontal: _receiptSideMargin - 15),
                child: pw.Container(color: PdfColors.white),
              ),
            ),

          // A fine dot grid, light enough to sit behind text.
          if (style == PdfPaperStyle.securityDotGrid)
            pw.Positioned.fill(
              child: pw.CustomPaint(
                painter: (PdfGraphics canvas, PdfPoint size) {
                  canvas.setFillColor(_mix(_rule, PdfColors.white, 0.35));
                  const step = 22.0;
                  for (double x = 24; x < size.x - 20; x += step) {
                    for (double y = 24; y < size.y - 20; y += step) {
                      canvas.drawEllipse(x, y, 0.55, 0.55);
                      canvas.fillPath();
                    }
                  }
                },
              ),
            ),

          // A single band of colour across the head of the sheet.
          if (style == PdfPaperStyle.topAccentLine && !_isBanner)
            pw.Positioned(left: 0, right: 0, top: 0, child: pw.Container(height: 7, color: _accent)),

          if (style == PdfPaperStyle.warmParchment && !_isBanner)
            pw.Positioned(left: 0, right: 0, top: 0, child: pw.Container(height: 3, color: theme.secondaryColor)),

          // A thick and a thin rule, mirrored at head and foot.
          if (style == PdfPaperStyle.doubleRule) ...[
            if (!_isBanner) ...[
              pw.Positioned(left: _sideMargin, right: _sideMargin, top: 26, child: pw.Container(height: 1.6, color: _accent)),
              pw.Positioned(left: _sideMargin, right: _sideMargin, top: 30, child: pw.Container(height: 0.4, color: _accent)),
            ],
            pw.Positioned(left: _sideMargin, right: _sideMargin, bottom: 22, child: pw.Container(height: 0.4, color: _accent)),
            pw.Positioned(left: _sideMargin, right: _sideMargin, bottom: 18, child: pw.Container(height: 1.6, color: _accent)),
          ],

          if (style == PdfPaperStyle.architecturalFrame && !_isBanner)
            pw.Container(
              margin: const pw.EdgeInsets.all(22),
              decoration: pw.BoxDecoration(border: pw.Border.all(color: _accent, width: 0.9)),
              child: pw.Container(
                margin: const pw.EdgeInsets.all(3.5),
                decoration: pw.BoxDecoration(border: pw.Border.all(color: _accent, width: 0.3)),
              ),
            ),

          if (style == PdfPaperStyle.leftVerticalRibbon)
            pw.Positioned(left: 0, top: 0, bottom: 0, child: pw.Container(width: 12, color: _accent)),

          // The banner bleeds to the edges of the first page.
          if (bannerPage)
            pw.Positioned(left: 0, right: 0, top: 0, child: pw.Container(height: _bannerHeight, color: _accent)),
          pw.Positioned.fill(
            child: pw.CustomPaint(
              painter: (canvas, size) => _paintPaper(canvas, size, bannerPage),
            ),
          ),
        ],
      ),
    );
  }

  void _paintPaper(PdfGraphics canvas, PdfPoint size, bool bannerPage) {
    final w = size.x;
    final h = size.y;

    switch (theme.paperStyle) {
      case PdfPaperStyle.cornerWave:
        final base = bannerPage ? _accent : PdfColors.white;
        canvas
          ..setFillColor(_mix(theme.secondaryColor, base, 0.84))
          ..moveTo(w * 0.45, h)
          ..curveTo(w * 0.66, h - 65, w * 0.86, h - 8, w, h - 125)
          ..lineTo(w, h)
          ..closePath()
          ..fillPath()
          ..setFillColor(_mix(theme.accentColor, base, 0.72))
          ..moveTo(w * 0.62, h)
          ..curveTo(w * 0.75, h - 46, w * 0.90, h - 6, w, h - 86)
          ..lineTo(w, h)
          ..closePath()
          ..fillPath();
      case PdfPaperStyle.diagonalBand:
        canvas
          ..setFillColor(theme.accentColor)
          ..moveTo(0, h - 22)
          ..lineTo(w, h - 4)
          ..lineTo(w, h - 1)
          ..lineTo(0, h - 19)
          ..closePath()
          ..fillPath()
          ..setFillColor(bannerPage ? _mix(_accent, PdfColors.black, 0.25) : _accent)
          ..moveTo(0, h - 19)
          ..lineTo(w, h - 1)
          ..lineTo(w, h)
          ..lineTo(w * 0.63, h)
          ..lineTo(0, h - 11)
          ..closePath()
          ..fillPath();
      case PdfPaperStyle.letterheadBar:
        canvas
          ..setFillColor(bannerPage ? _mix(_accent, PdfColors.black, 0.25) : _accent)
          ..drawRect(0, h - 24, w, 24)
          ..fillPath()
          ..setFillColor(theme.accentColor)
          ..drawRect(0, h - 26, w, 2)
          ..fillPath()
          ..setFillColor(theme.secondaryColor)
          ..drawRect(0, 0, w, 7)
          ..fillPath();
      case PdfPaperStyle.stampBorder:
        canvas
          ..setStrokeColor(_accent)
          ..setLineWidth(0.85)
          ..drawRect(12, 12, w - 24, h - 24)
          ..strokePath()
          ..setLineWidth(0.45)
          ..setStrokeColor(theme.secondaryColor)
          ..drawRect(18, 18, w - 36, h - 36)
          ..strokePath();
        if (bannerPage) {
          canvas
            ..setStrokeColor(theme.accentColor)
            ..moveTo(12, h - _bannerHeight)
            ..lineTo(12, h - 12)
            ..lineTo(w - 12, h - 12)
            ..lineTo(w - 12, h - _bannerHeight)
            ..strokePath();
        }
        canvas
          ..setStrokeColor(theme.accentColor)
          ..setLineWidth(1.6);
        for (final x in [18.0, w - 18]) {
          for (final y in [18.0, h - 18]) {
            canvas
              ..moveTo(x, y + (y < h / 2 ? 9 : -9))
              ..lineTo(x, y)
              ..lineTo(x + (x < w / 2 ? 9 : -9), y);
          }
        }
        canvas.strokePath();
      case PdfPaperStyle.gstLedger:
        canvas
          ..setFillColor(bannerPage ? theme.accentColor : _accent)
          ..drawRect(_sideMargin, h - 19, w - 2 * _sideMargin, 2)
          ..drawRect(_sideMargin, 17, w - 2 * _sideMargin, 0.75)
          ..fillPath();
      case PdfPaperStyle.receiptStrip:
        canvas
          ..saveContext()
          ..setLineWidth(0.9)
          ..setLineDashPattern([5, 3])
          ..setStrokeColor(bannerPage ? theme.accentColor : theme.secondaryColor)
          ..moveTo(_receiptSideMargin, h - 22)
          ..lineTo(w - _receiptSideMargin, h - 22)
          ..strokePath()
          ..setStrokeColor(theme.secondaryColor)
          ..moveTo(_receiptSideMargin, 18)
          ..lineTo(w - _receiptSideMargin, 18)
          ..strokePath()
          ..restoreContext();
      default:
        break;
    }
  }

  /// Fixed height: the free-plan credit on the left, page numbers on the
  /// right when the document runs past one page.
  pw.Widget pageFooter(pw.Context context) {
    final small = pw.TextStyle(fontSize: 7, color: _mix(_muted, PdfColors.white, 0.25));
    return pw.Container(
      height: 20,
      alignment: pw.Alignment.bottomCenter,
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Expanded(
            child: isPro ? pw.SizedBox() : pw.Text(PdfGeneratorService.freePlanCredit, style: small),
          ),
          if (context.pagesCount > 1)
            pw.Text(
              '${invoice.invoiceNumber}   ·   Page ${context.pageNumber} of ${context.pagesCount}',
              style: small,
            ),
        ],
      ),
    );
  }

  Iterable<pw.Widget> attachmentPages(List<pw.MemoryImage> images) sync* {
    final available = PdfPageFormat.a4.height - pageMargin.top - pageMargin.bottom;
    for (var i = 0; i < images.length; i += 2) {
      final hasPair = i + 1 < images.length;
      final height = (available - 80) / (hasPair ? 2 : 1);
      yield pw.NewPage();
      yield pw.Text(
        'Attachments',
        style: pw.TextStyle(color: _accent, fontSize: 22 * s, fontWeight: pw.FontWeight.bold),
      );
      yield pw.SizedBox(height: 10);
      yield pw.Container(
        height: height,
        alignment: pw.Alignment.center,
        child: pw.Image(images[i], fit: pw.BoxFit.contain),
      );
      if (hasPair) {
        yield pw.SizedBox(height: 10);
        yield pw.Container(
          height: height,
          alignment: pw.Alignment.center,
          child: pw.Image(images[i + 1], fit: pw.BoxFit.contain),
        );
      }
    }
  }

  List<pw.Widget> build() {
    final notes = invoice.notes;
    final footer = _paymentAndSignature();
    return [
      if (_isLedger && !_isBanner)
        pw.Container(
          padding: pw.EdgeInsets.all(11 * s),
          decoration: pw.BoxDecoration(
            color: theme.lightGray,
            border: pw.Border.all(color: _ledgerRule, width: 0.8),
          ),
          child: _header(),
        )
      else
        _header(),
      pw.SizedBox(height: (_isBanner ? 16 : 20) * s),
      _metaStrip(),
      pw.SizedBox(height: 20 * s),
      _parties(),
      pw.SizedBox(height: 26 * s),
      _lineItems(),
      pw.SizedBox(height: 14 * s),
      _totals(),
      if (config.showNotes && _filled(notes)) ...[
        pw.SizedBox(height: 22 * s),
        pw.Text('NOTES', style: _label()),
        pw.SizedBox(height: 5 * s),
        // A direct child, so long notes can run on to the next page.
        pw.Text(notes!.trim(), style: _body(color: _muted, size: 8.6)),
      ],
      pw.SizedBox(height: 24 * s),
      // One block, so the closing line never lands alone on a new page.
      pw.Inseparable(
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            if (footer != null) ...[
              footer,
              pw.SizedBox(height: 22 * s),
            ],
            pw.Text(
              _filled(config.customFooterMessage) ? config.customFooterMessage!.trim() : 'Thank you for your business.',
              style: _body(color: _ink, size: 9.5),
            ),
          ],
        ),
      ),
    ];
  }

  // ---- Header ----

  pw.Widget _header() {
    if (_isBanner) return _bannerHeader();
    switch (config.headerPosition) {
      case HeaderPosition.centeredLogo:
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            pw.Center(child: _brand(pw.CrossAxisAlignment.center)),
            pw.SizedBox(height: 12 * s),
            pw.Center(child: _title(pw.CrossAxisAlignment.center)),
          ],
        );
      case HeaderPosition.logoRightDetailsLeft:
        return pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(flex: 5, child: _title(pw.CrossAxisAlignment.start)),
            pw.SizedBox(width: 16),
            pw.Expanded(flex: 6, child: _brand(pw.CrossAxisAlignment.end)),
          ],
        );
      default:
        if (theme.paperStyle == PdfPaperStyle.asymmetricSplitHeader) return _splitHeader();
        return pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(flex: 6, child: _brand(pw.CrossAxisAlignment.start)),
            pw.SizedBox(width: 16),
            pw.Expanded(flex: 5, child: _title(pw.CrossAxisAlignment.end)),
          ],
        );
    }
  }

  static pw.TextAlign _textAlign(pw.CrossAxisAlignment a) => switch (a) {
        pw.CrossAxisAlignment.end => pw.TextAlign.right,
        pw.CrossAxisAlignment.center => pw.TextAlign.center,
        _ => pw.TextAlign.left,
      };

  static pw.Alignment _boxAlign(pw.CrossAxisAlignment a) => switch (a) {
        pw.CrossAxisAlignment.end => pw.Alignment.centerRight,
        pw.CrossAxisAlignment.center => pw.Alignment.center,
        _ => pw.Alignment.centerLeft,
      };

  /// The logo with the business name under it. With no logo, the name
  /// stands alone, set larger.
  pw.Widget _brand(pw.CrossAxisAlignment align, {PdfColor? color, bool onColor = false}) {
    final hasMark = logo != null || (isSample && !onColor);
    return pw.Column(
      crossAxisAlignment: align,
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        if (logo != null)
          pw.Container(
            height: 44 * s,
            width: 150 * s,
            alignment: _boxAlign(align),
            child: pw.Image(logo!, fit: pw.BoxFit.contain),
          )
        else if (isSample && !onColor)
          // Only the sample preview shows the demo logo; a real document
          // never carries another company's mark.
          DummyInvoiceData.buildVectorLogo(theme, size: 36 * s),
        if (hasMark) pw.SizedBox(height: 8 * s),
        pw.Text(
          profile.businessName,
          maxLines: 2,
          textAlign: _textAlign(align),
          style: pw.TextStyle(
            fontSize: (hasMark ? 12.5 : (_isMinimal ? 19 : 17)) * s,
            fontWeight: pw.FontWeight.bold,
            color: color ?? _ink,
            letterSpacing: hasMark ? 0 : -0.2,
          ),
        ),
      ],
    );
  }

  /// The document title, set large and light, with the payment stamp.
  pw.Widget _title(pw.CrossAxisAlignment align, {PdfColor? color, bool onColor = false}) {
    final text = profile.titleFor(invoice);
    final stamp = _stamp(onColor: onColor);
    return pw.Column(
      crossAxisAlignment: align,
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Text(
          text,
          textAlign: _textAlign(align),
          style: pw.TextStyle(
            fontSize: (text.length > 12 ? 17 : 25) * s,
            color: color ?? (_isMinimal ? _ink : _accent),
            letterSpacing: 1.6,
          ),
        ),
        if (stamp != null) ...[
          pw.SizedBox(height: 7 * s),
          stamp,
        ],
      ],
    );
  }

  /// A small outlined stamp for a settled or late invoice. An invoice that
  /// is simply awaiting payment carries none, and nor does an estimate.
  pw.Widget? _stamp({bool onColor = false}) {
    final status = PdfGeneratorService.statusStampFor(
      invoice,
      config,
      isEstimate: profile.isEstimate,
    );
    if (status == null) return null;
    final (label, hex) = switch (status) {
      InvoiceStatus.paid => ('PAID', '#15803D'),
      InvoiceStatus.partiallyPaid => ('PART PAID', '#A16207'),
      InvoiceStatus.overdue => ('OVERDUE', '#B91C1C'),
      InvoiceStatus.unpaid => ('', ''),
    };
    if (label.isEmpty) return null;
    final color = onColor ? PdfColors.white : PdfColor.fromHex(hex);
    return pw.Container(
      padding: pw.EdgeInsets.symmetric(horizontal: 6 * s, vertical: 2.2 * s),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: color, width: 0.9),
        borderRadius: pw.BorderRadius.circular(2),
      ),
      child: pw.Column(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(fontSize: 7 * s, fontWeight: pw.FontWeight.bold, letterSpacing: 1.4, color: color),
          ),
          if (status == InvoiceStatus.paid && paidOn != null)
            pw.Text(date(paidOn!), style: pw.TextStyle(fontSize: 6 * s, color: color)),
        ],
      ),
    );
  }

  /// White type on the banner painted by [background].
  pw.Widget _bannerHeader() {
    final hasLogo = logo != null;
    return pw.Container(
      height: _bannerBodyHeight,
      margin: const pw.EdgeInsets.only(bottom: _bannerTopMargin),
      padding: _isLedger ? pw.EdgeInsets.symmetric(horizontal: 11 * s) : null,
      decoration: _isLedger
          ? pw.BoxDecoration(border: pw.Border.all(color: theme.accentColor, width: 0.8))
          : null,
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Expanded(
            flex: 6,
            child: pw.Row(
              children: [
                if (!hasLogo) ...[
                  pw.Container(
                    width: 30 * s,
                    height: 30 * s,
                    alignment: pw.Alignment.center,
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.white, width: 0.9),
                      borderRadius: pw.BorderRadius.circular(2),
                    ),
                    child: pw.Text(
                      isSample ? 'AG' : PdfGeneratorService._initials(profile.businessName),
                      style: pw.TextStyle(color: PdfColors.white, fontSize: 11 * s, fontWeight: pw.FontWeight.bold, letterSpacing: 0.6),
                    ),
                  ),
                  pw.SizedBox(width: 11 * s),
                ],
                pw.Expanded(
                  child: hasLogo
                      ? _brand(pw.CrossAxisAlignment.start, color: PdfColors.white, onColor: true)
                      : pw.Text(
                          profile.businessName,
                          maxLines: 2,
                          style: pw.TextStyle(color: PdfColors.white, fontSize: 15 * s, fontWeight: pw.FontWeight.bold),
                        ),
                ),
              ],
            ),
          ),
          pw.SizedBox(width: 16),
          pw.Expanded(
            flex: 5,
            child: _title(pw.CrossAxisAlignment.end, color: PdfColors.white, onColor: true),
          ),
        ],
      ),
    );
  }

  /// Brand on a panel of colour, title on a panel of tint.
  pw.Widget _splitHeader() {
    return pw.Container(
      height: 92 * s,
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Expanded(
            child: pw.Container(
              color: _accent,
              padding: pw.EdgeInsets.symmetric(horizontal: 18 * s),
              alignment: pw.Alignment.centerLeft,
              child: _brand(pw.CrossAxisAlignment.start, color: PdfColors.white, onColor: true),
            ),
          ),
          pw.Expanded(
            child: pw.Container(
              color: theme.lightGray,
              padding: pw.EdgeInsets.symmetric(horizontal: 18 * s),
              alignment: pw.Alignment.centerRight,
              child: _title(pw.CrossAxisAlignment.end),
            ),
          ),
        ],
      ),
    );
  }

  // ---- Number, dates and the amount to pay ----

  pw.Widget _metaStrip() {
    pw.Widget cell(String label, String value, {bool end = false, bool strong = false}) {
      return pw.Column(
        crossAxisAlignment: end ? pw.CrossAxisAlignment.end : pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label, style: _label()),
          pw.SizedBox(height: 4 * s),
          pw.Text(
            value,
            textAlign: end ? pw.TextAlign.right : pw.TextAlign.left,
            style: strong ? _body(bold: true, size: 12, color: _isMinimal ? _ink : _accent) : _body(size: 9.5),
          ),
        ],
      );
    }

    final fields = invoice.customFields
        .where((field) => _filled(field.label) && _filled(field.value))
        .take(DocumentCustomField.maxFields)
        .toList();
    final due = invoice.dueDate;
    final amountLabel = profile.isEstimate
        ? 'ESTIMATE TOTAL'
        : (_hasPayments ? 'BALANCE DUE' : 'AMOUNT DUE');
    return pw.Container(
      padding: pw.EdgeInsets.symmetric(vertical: 10 * s),
      decoration: pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: _ink, width: 0.8),
          bottom: pw.BorderSide(color: _rule, width: 0.6),
        ),
      ),
      child: pw.Column(
        children: [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                flex: 30,
                child: cell(profile.isEstimate ? 'ESTIMATE NO.' : 'INVOICE NO.', invoice.invoiceNumber),
              ),
              pw.Expanded(flex: 22, child: cell('ISSUED', date(invoice.invoiceDate))),
              pw.Expanded(
                flex: 22,
                child: due == null ? pw.SizedBox() : cell(profile.dueLabel.toUpperCase(), date(due)),
              ),
              pw.Expanded(
                flex: 28,
                child: cell(amountLabel, money(profile.isEstimate ? totals.grandTotal : _balance), end: true, strong: true),
              ),
            ],
          ),
          for (var i = 0; i < fields.length; i += 3)
            pw.Padding(
              padding: pw.EdgeInsets.only(top: 9 * s),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  for (var j = i; j < i + 3; j++)
                    pw.Expanded(
                      child: j >= fields.length
                          ? pw.SizedBox()
                          : pw.Padding(
                              padding: pw.EdgeInsets.only(right: 8 * s),
                              child: cell(fields[j].label.trim(), fields[j].value.trim()),
                            ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ---- From and bill to ----

  pw.Widget _party(String label, String name, List<String?> lines) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label, style: _label()),
        pw.SizedBox(height: 6 * s),
        pw.Text(name, style: _body(bold: true, size: 10.5)),
        for (final line in lines)
          if (_filled(line))
            pw.Padding(
              padding: pw.EdgeInsets.only(top: 2.5 * s),
              child: pw.Text(line!.trim(), style: _body(color: _muted, size: 8.6)),
            ),
      ],
    );
  }

  pw.Widget _parties() {
    final from = _party('FROM', profile.businessName, [
      profile.address,
      profile.phone,
      profile.email,
      profile.website,
      if (_filled(profile.gstin)) '${profile.taxIdLabel}: ${profile.gstin}',
    ]);
    final billTo = _party('BILL TO', invoice.clientName, [
      invoice.clientAddress,
      invoice.clientPhone,
      invoice.clientEmail,
      if (_filled(invoice.clientGstin)) '${profile.taxIdLabel}: ${invoice.clientGstin}',
    ]);

    switch (config.addressLayout) {
      case AddressLayout.stacked:
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [from, pw.SizedBox(height: 14 * s), billTo],
        );
      case AddressLayout.inverted:
        return pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [pw.Expanded(child: billTo), pw.SizedBox(width: 28), pw.Expanded(child: from)],
        );
      default:
        return pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [pw.Expanded(child: from), pw.SizedBox(width: 28), pw.Expanded(child: billTo)],
        );
    }
  }

  // ---- Line items ----

  pw.Widget _lineItems() {
    final style = _tableStyle;
    final filled = style != _TableStyle.ruled;
    final ledger = style == _TableStyle.ledger;
    final receipt = style == _TableStyle.receipt;
    final showQty = config.showQuantity;
    final showUnitPrice = config.showUnitPrice;
    // A filled header needs its text inset; a ruled table sits flush with
    // the margins, so the columns line up with everything else on the page.
    final edge = (filled ? 10.0 : 0.0) * s;
    final gap = 8.0 * s;

    final headerBg = theme.tableHeaderBg;
    final preferredText = theme.tableHeaderTextColor;
    final bgLum = headerBg.luminance;
    final textLum = preferredText.luminance;
    final contrast = bgLum > textLum
        ? (bgLum + 0.05) / (textLum + 0.05)
        : (textLum + 0.05) / (bgLum + 0.05);
    final headerText = contrast >= 4.5
        ? preferredText
        : (bgLum > 0.179 ? PdfColors.black : PdfColors.white);
    final headStyle = _label(color: filled ? headerText : _muted);
    final lastIndex = 1 + (showQty ? 1 : 0) + (showUnitPrice ? 1 : 0);

    pw.Widget cell(pw.Widget child, int index, {required double vertical, bool right = false}) {
      return pw.Container(
        padding: pw.EdgeInsets.fromLTRB(
          index == 0 ? edge : gap,
          vertical,
          index == lastIndex ? edge : gap,
          vertical,
        ),
        alignment: right ? pw.Alignment.topRight : pw.Alignment.topLeft,
        child: child,
      );
    }

    final columnWidths = <int, pw.TableColumnWidth>{};
    var col = 0;
    columnWidths[col++] = const pw.FlexColumnWidth(5.2);
    if (showQty) columnWidths[col++] = const pw.FlexColumnWidth(1.4);
    if (showUnitPrice) columnWidths[col++] = const pw.FlexColumnWidth(2.0);
    columnWidths[col++] = const pw.FlexColumnWidth(2.1);

    var h = 0;
    final header = pw.TableRow(
      repeat: true, // the header again on every page
      decoration: pw.BoxDecoration(
        color: filled ? headerBg : null,
        border: filled ? null : pw.Border(bottom: pw.BorderSide(color: _ink, width: 0.8)),
      ),
      children: [
        cell(pw.Text('DESCRIPTION', style: headStyle), h++, vertical: 7 * s),
        if (showQty) cell(pw.Text('QTY', style: headStyle), h++, vertical: 7 * s, right: true),
        if (showUnitPrice) cell(pw.Text('RATE', style: headStyle), h++, vertical: 7 * s, right: true),
        cell(pw.Text('AMOUNT', style: headStyle), h++, vertical: 7 * s, right: true),
      ],
    );

    final rows = invoice.lineItems.map((item) {
      // HSN/SAC, the line's own discount and its own tax rate.
      final details = <String>[
        if (item.hsnSac != null) '${profile.isDualTax ? 'HSN/SAC' : 'Code'} ${item.hsnSac}',
        if (item.discountRate > 0) '${NumberText.trim(item.discountRate)}% off',
        if (config.showTaxColumn && item.taxRate != null)
          item.taxRate == 0 ? 'Tax exempt' : '${profile.taxShortName} ${NumberText.trim(item.taxRate!)}%',
      ];
      var i = 0;
      return pw.TableRow(
        decoration: ledger || receipt
            ? null
            : pw.BoxDecoration(
                border: pw.Border(bottom: pw.BorderSide(color: _rule, width: 0.5)),
              ),
        children: [
          cell(
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(item.description, style: _body()),
                if (details.isNotEmpty) ...[
                  pw.SizedBox(height: 2 * s),
                  pw.Text(details.join('   ·   '), style: _body(color: _muted, size: 7.2)),
                ],
              ],
            ),
            i++,
            vertical: 8 * s,
          ),
          if (showQty)
            cell(
              pw.Text(
                '${NumberText.trim(item.quantity, maxDecimals: 3)}${item.unit != null ? ' ${item.unit}' : ''}',
                style: _body(color: _muted),
              ),
              i++,
              vertical: 8 * s,
              right: true,
            ),
          if (showUnitPrice)
            cell(pw.Text(money(item.unitPrice), style: _body(color: _muted)), i++, vertical: 8 * s, right: true),
          cell(pw.Text(money(item.total), style: _body()), i++, vertical: 8 * s, right: true),
        ],
      );
    });

    final border = switch (style) {
      _TableStyle.ledger => pw.TableBorder.all(color: _ledgerRule, width: 0.65),
      _TableStyle.receipt => pw.TableBorder(
        top: pw.BorderSide(color: theme.secondaryColor, width: 0.7, style: pw.BorderStyle.dashed),
        bottom: pw.BorderSide(color: theme.secondaryColor, width: 0.7, style: pw.BorderStyle.dashed),
        horizontalInside: pw.BorderSide(color: _rule, width: 0.65, style: pw.BorderStyle.dashed),
      ),
      _ => null,
    };
    return pw.Table(border: border, columnWidths: columnWidths, children: [header, ...rows]);
  }

  // ---- Totals ----

  pw.Widget _totals() {
    String taxLabel(TaxComponent c) {
      final name = switch (c.kind) {
        TaxComponentKind.cgst => 'CGST',
        TaxComponentKind.sgst => 'SGST',
        TaxComponentKind.igst => 'IGST',
        TaxComponentKind.single => profile.taxShortName,
      };
      return '$name (${NumberText.trim(c.rate)}%)';
    }

    pw.Widget row(String label, String value, {bool strong = false}) {
      return pw.Padding(
        padding: pw.EdgeInsets.symmetric(vertical: 3.2 * s),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(label, style: _body(color: strong ? _ink : _muted, bold: strong, size: 8.8)),
            pw.Text(value, style: _body(bold: strong, size: 8.8)),
          ],
        ),
      );
    }

    /// The figure the reader must act on: the largest on the page.
    pw.Widget headline(String label, String value) {
      return pw.Container(
        margin: pw.EdgeInsets.only(top: 6 * s),
        padding: pw.EdgeInsets.only(top: 9 * s),
        decoration: pw.BoxDecoration(border: pw.Border(top: pw.BorderSide(color: _ink, width: 0.8))),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Padding(
              padding: pw.EdgeInsets.only(bottom: 2.5 * s),
              child: pw.Text(label, style: _label(color: _ink)),
            ),
            pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 17 * s,
                fontWeight: pw.FontWeight.bold,
                color: _isMinimal ? _ink : _accent,
              ),
            ),
          ],
        ),
      );
    }

    final hasDiscount = totals.discountAmount > 0;
    final totalLabel = profile.isEstimate ? 'ESTIMATE TOTAL' : 'TOTAL';
    final column = pw.Container(
      width: 232 * s,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          row('Subtotal', money(totals.subtotal)),
          if (hasDiscount) ...[
            row(
              invoice.discountType == DiscountType.percentage
                  ? 'Discount (${NumberText.trim(invoice.discountValue)}%)'
                  : 'Discount',
              '-${money(totals.discountAmount)}',
            ),
            if (totals.taxComponents.isNotEmpty) row('Taxable amount', money(totals.taxableAmount)),
          ],
          for (final c in totals.taxComponents) row(taxLabel(c), money(c.amount)),
          if (totals.shipping > 0) row('Shipping', money(totals.shipping)),
          if (_hasPayments) ...[
            pw.Container(
              margin: pw.EdgeInsets.only(top: 4 * s),
              padding: pw.EdgeInsets.only(top: 4 * s),
              decoration: pw.BoxDecoration(border: pw.Border(top: pw.BorderSide(color: _rule, width: 0.5))),
              child: row('Total', money(totals.grandTotal), strong: true),
            ),
            row('Paid', '-${money(invoice.paidAmount)}'),
            headline('BALANCE DUE', money(_balance)),
          ] else
            headline(totalLabel, money(totals.grandTotal)),
        ],
      ),
    );

    final inWords = AmountInWords.format(totals.grandTotal, invoice.currency);
    // Inseparable: the total never parts from the rows that add up to it.
    return pw.Inseparable(
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Align(alignment: pw.Alignment.centerRight, child: column),
          if (inWords != null) ...[
            pw.SizedBox(height: 7 * s),
            pw.Text(
              inWords,
              textAlign: pw.TextAlign.right,
              style: _body(color: _muted, size: 8.2),
            ),
          ],
        ],
      ),
    );
  }

  // ---- How to pay, and the signature ----

  pw.Widget? _paymentAndSignature() {
    final payment = <(String, String)>[
      if (config.showBankDetails) ...[
        if (_filled(profile.bankName)) ('Bank', profile.bankName!.trim()),
        if (_filled(profile.accountNumber)) (profile.bankAccountLabel, profile.accountNumber!.trim()),
        if (_filled(profile.ifscCode)) (profile.bankRoutingLabel, profile.ifscCode!.trim()),
      ],
      if (config.showUpiDetails && _filled(profile.upiId)) (profile.digitalPaymentLabel, profile.upiId!.trim()),
    ];
    if (payment.isEmpty && !config.showSignature) return null;

    final upiQr = PdfGeneratorService.upiQrData(
      invoice: invoice,
      profile: profile,
      config: config,
      balance: _balance,
    );
    // Big enough to scan off a phone screen at compact density, small enough
    // to sit beside the table without crowding the signature when spacious.
    final qrSize = (68 * s).clamp(60.0, 76.0);

    final table = pw.Table(
      columnWidths: const {0: pw.IntrinsicColumnWidth(), 1: pw.FlexColumnWidth()},
      children: [
        for (final (label, value) in payment)
          pw.TableRow(
            children: [
              pw.Padding(
                padding: pw.EdgeInsets.only(right: 14 * s, bottom: 3.5 * s),
                child: pw.Text(label, style: _body(color: _muted, size: 8.6)),
              ),
              pw.Padding(
                padding: pw.EdgeInsets.only(bottom: 3.5 * s),
                child: pw.Text(value, style: _body(size: 8.6)),
              ),
            ],
          ),
      ],
    );

    final paymentBlock = payment.isEmpty
        ? pw.SizedBox()
        : pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('PAYMENT DETAILS', style: _label()),
              pw.SizedBox(height: 7 * s),
              if (upiQr == null)
                table
              else
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(child: table),
                    pw.SizedBox(width: 12 * s),
                    // Fixed width, so a long caption wraps instead of
                    // pushing the signature off the row.
                    pw.SizedBox(
                      width: qrSize,
                      child: pw.Column(
                        mainAxisSize: pw.MainAxisSize.min,
                        children: [
                          pw.BarcodeWidget(
                            barcode: pw.Barcode.qrCode(),
                            data: upiQr,
                            width: qrSize,
                            height: qrSize,
                            drawText: false,
                            color: _ink,
                          ),
                          pw.SizedBox(height: 4 * s),
                          pw.Text(
                            // A set break, so it wraps the same way at every density.
                            'Scan to pay with\nany UPI app',
                            textAlign: pw.TextAlign.center,
                            style: pw.TextStyle(fontSize: 5.8 * s, color: _muted, lineSpacing: 1),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          );

    final signatureBlock = !config.showSignature
        ? null
        : pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              pw.Container(
                height: 42 * s,
                width: 130 * s,
                alignment: pw.Alignment.bottomCenter,
                child: signature != null
                    ? pw.Image(signature!, fit: pw.BoxFit.contain)
                    : (isSample ? DummyInvoiceData.buildVectorSignature(theme) : null),
              ),
              pw.Container(width: 130 * s, height: 0.6, color: _ink, margin: pw.EdgeInsets.only(top: 4 * s, bottom: 4 * s)),
              pw.Text('AUTHORISED SIGNATURE', style: _label()),
            ],
          );

    return pw.Container(
        padding: pw.EdgeInsets.only(top: 14 * s),
        decoration: pw.BoxDecoration(border: pw.Border(top: pw.BorderSide(color: _rule, width: 0.6))),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Expanded(child: paymentBlock),
            if (signatureBlock != null) ...[
              pw.SizedBox(width: 24),
              signatureBlock,
            ],
          ],
        ),
    );
  }
}

class _PdfFonts {
  const _PdfFonts({
    required this.base,
    required this.bold,
    required this.fallback,
  });

  final pw.Font base;
  final pw.Font bold;
  final List<pw.Font> fallback;

  static final Map<InvoiceFontFamily, _PdfFonts> _cache = {};

  static Future<_PdfFonts> load(InvoiceFontFamily fontFamily) async {
    if (_cache.containsKey(fontFamily)) {
      return _cache[fontFamily]!;
    }

    final arabic = await _loadFont('assets/fonts/NotoSansArabic-Regular.ttf');
    final bengali = await _loadFont('assets/fonts/NotoSansBengali-Regular.ttf');
    final thai = await _loadFont('assets/fonts/NotoSansThai-Regular.ttf');
    final noto = await _loadFont('assets/fonts/NotoSans-Regular.ttf');
    final fallbacks = [noto, arabic, bengali, thai];

    pw.Font base;
    pw.Font bold;

    switch (fontFamily) {
      case InvoiceFontFamily.editorialSerif:
        try {
          base = await PdfGoogleFonts.loraRegular();
          bold = await PdfGoogleFonts.loraBold();
        } catch (_) {
          base = await _loadFont('assets/fonts/NotoSans-Regular.ttf');
          bold = await _loadFont('assets/fonts/NotoSans-Bold.ttf');
        }
        break;
      case InvoiceFontFamily.geometricSans:
        try {
          base = await PdfGoogleFonts.montserratRegular();
          bold = await PdfGoogleFonts.montserratBold();
        } catch (_) {
          base = await _loadFont('assets/fonts/NotoSans-Regular.ttf');
          bold = await _loadFont('assets/fonts/NotoSans-Bold.ttf');
        }
        break;
      case InvoiceFontFamily.modernMono:
        try {
          base = await PdfGoogleFonts.spaceMonoRegular();
          bold = await PdfGoogleFonts.spaceMonoBold();
        } catch (_) {
          base = await _loadFont('assets/fonts/NotoSans-Regular.ttf');
          bold = await _loadFont('assets/fonts/NotoSans-Bold.ttf');
        }
      case InvoiceFontFamily.cleanSans:
        // Inter is bundled; Noto stays in the fallback list for any glyph
        // Inter lacks.
        base = await _loadFont('assets/fonts/Inter-Regular.ttf');
        bold = await _loadFont('assets/fonts/Inter-SemiBold.ttf');
        break;
    }

    final fonts = _PdfFonts(base: base, bold: bold, fallback: fallbacks);
    _cache[fontFamily] = fonts;
    return fonts;
  }

  static Future<pw.Font> _loadFont(String assetPath) async {
    final fontData = await rootBundle.load(assetPath);
    return pw.Font.ttf(fontData);
  }
}
