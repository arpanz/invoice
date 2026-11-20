import 'dart:io';
import '../../../core/utils/number_text.dart';
import '../../../core/utils/amount_in_words.dart';
import '../../../core/utils/document_totals.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
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
  }) async {
    final config = customizationConfig ??
        (theme != null
            ? InvoiceCustomizationConfig.fromTheme(theme)
            : InvoiceCustomizationConfig.defaultConfig);
    final activeTheme = config.toPdfTheme();
    final scale = config.density.scaleFactor;
    final fonts = await _PdfFonts.load(config.fontFamily);
    // Indic scripts are fetched only when this document uses them.
    final scriptFonts = await PdfScriptFonts.fontsFor(
      [
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

    pw.MemoryImage? logoImage;
    if (businessProfile.logoPath != null) {
      try {
        final logoFile = File(businessProfile.logoPath!);
        if (await logoFile.exists()) {
          final bytes = await logoFile.readAsBytes();
          logoImage = pw.MemoryImage(bytes);
        }
      } catch (_) {}
    }

    pw.MemoryImage? signatureImage;
    if (businessProfile.signaturePath != null) {
      try {
        final sigFile = File(businessProfile.signaturePath!);
        if (await sigFile.exists()) {
          final bytes = await sigFile.readAsBytes();
          signatureImage = pw.MemoryImage(bytes);
        }
      } catch (_) {}
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
      s: scale,
      logo: logoImage,
      signature: signatureImage,
      isPro: isPro,
      isSample: isSamplePreview,
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
          theme: pw.ThemeData.withFont(
            base: fonts.base,
            bold: fonts.bold,
            fontFallback: [...fonts.fallback, ...scriptFonts],
          ),
        ),
        // The footer keeps the same height on every page: MultiPage measures
        // it before the page count is final, and a footer that grew later
        // would be drawn over page 1's content.
        footer: doc.pageFooter,
        build: (context) => doc.build(),
      ),
    );

    return pdf.save();
  }

  static Future<String> saveAndGetPath(
    Uint8List pdfBytes,
    String invoiceNumber,
  ) async {
    return await PdfHelper.savePdf(pdfBytes, invoiceNumber);
  }
}

/// How the line-item table's header row is drawn.
enum _TableStyle { ruled, filled }

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
  final DocumentTotals totals;
  final String Function(double) money;
  final String Function(DateTime) date;

  static const double _sideMargin = 46;
  static const double _bannerTopMargin = 30;

  PdfColor get _ink => theme.darkColor;
  PdfColor get _muted => theme.slateColor;
  /// Hairlines are a neutral tint of the text grey, so they stay visible on
  /// every paper tint (a theme's own border colour can vanish on cream).
  PdfColor get _rule => _mix(_muted, PdfColors.white, 0.72);
  PdfColor get _accent => theme.primaryColor;

  bool get _isBanner => config.headerPosition == HeaderPosition.fullWidthBanner;
  bool get _isMinimal => theme.paperStyle == PdfPaperStyle.minimalDividers;
  double get _bannerBodyHeight => 84 * s;
  double get _bannerHeight => _bannerTopMargin * 2 + _bannerBodyHeight;

  _TableStyle get _tableStyle => switch (theme.paperStyle) {
        PdfPaperStyle.fullWidthBanner ||
        PdfPaperStyle.asymmetricSplitHeader ||
        PdfPaperStyle.leftVerticalRibbon =>
          _TableStyle.filled,
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
    if (_isBanner) return const pw.EdgeInsets.fromLTRB(_sideMargin, _bannerTopMargin, _sideMargin, 30);
    return switch (theme.paperStyle) {
      PdfPaperStyle.leftVerticalRibbon => const pw.EdgeInsets.fromLTRB(_sideMargin + 14, 44, _sideMargin, 30),
      PdfPaperStyle.architecturalFrame => const pw.EdgeInsets.fromLTRB(52, 50, 52, 38),
      PdfPaperStyle.topAccentLine ||
      PdfPaperStyle.doubleRule ||
      PdfPaperStyle.warmParchment =>
        const pw.EdgeInsets.fromLTRB(_sideMargin, 50, _sideMargin, 30),
      _ => const pw.EdgeInsets.fromLTRB(_sideMargin, 44, _sideMargin, 30),
    };
  }

  pw.Widget background(pw.Context context) {
    final style = theme.paperStyle;
    return pw.FullPage(
      ignoreMargins: true,
      child: pw.Stack(
        children: [
          if (style == PdfPaperStyle.warmParchment)
            pw.Container(color: PdfColor.fromHex('#FFFDF8'))
          else if (style == PdfPaperStyle.securityDotGrid)
            pw.Container(color: PdfColor.fromHex('#FCFDFF')),

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
          if (_isBanner && context.pageNumber == 1)
            pw.Positioned(left: 0, right: 0, top: 0, child: pw.Container(height: _bannerHeight, color: _accent)),
        ],
      ),
    );
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
            child: isPro ? pw.SizedBox() : pw.Text('Generated by Invoice Maker Pro', style: small),
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

  List<pw.Widget> build() {
    final notes = invoice.notes;
    final footer = _paymentAndSignature();
    return [
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
    if (profile.isEstimate) return null;
    final (label, hex) = switch (invoice.effectiveStatus) {
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
      child: pw.Text(
        label,
        style: pw.TextStyle(fontSize: 7 * s, fontWeight: pw.FontWeight.bold, letterSpacing: 1.4, color: color),
      ),
    );
  }

  /// White type on the banner painted by [background].
  pw.Widget _bannerHeader() {
    final hasLogo = logo != null;
    return pw.Container(
      height: _bannerBodyHeight,
      margin: const pw.EdgeInsets.only(bottom: _bannerTopMargin),
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
      child: pw.Row(
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
    final filled = _tableStyle == _TableStyle.filled;
    final showQty = config.showQuantity;
    final showUnitPrice = config.showUnitPrice;
    // A filled header needs its text inset; a ruled table sits flush with
    // the margins, so the columns line up with everything else on the page.
    final edge = (filled ? 10.0 : 0.0) * s;
    final gap = 8.0 * s;

    final headStyle = _label(color: filled ? theme.tableHeaderTextColor : _muted);
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
        color: filled ? theme.tableHeaderBg : null,
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
        decoration: pw.BoxDecoration(
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

    return pw.Table(columnWidths: columnWidths, children: [header, ...rows]);
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

    final paymentBlock = payment.isEmpty
        ? pw.SizedBox()
        : pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('PAYMENT DETAILS', style: _label()),
              pw.SizedBox(height: 7 * s),
              pw.Table(
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
