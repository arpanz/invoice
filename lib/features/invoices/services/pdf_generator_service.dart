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
  /// Logo slot when the user has no logo (or its file is missing). Only the
  /// sample preview shows the demo logo; real documents show nothing rather
  /// than another company's branding.
  static pw.Widget _logoFallback(PdfTheme theme, double size, bool isSamplePreview) {
    if (isSamplePreview) return DummyInvoiceData.buildVectorLogo(theme, size: size);
    return pw.SizedBox();
  }

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
    final pageMargin = _getPageMargin(activeTheme);

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: pageMargin,
          buildBackground: (context) => _buildPageBackground(context, activeTheme),
          theme: pw.ThemeData.withFont(
            base: fonts.base,
            bold: fonts.bold,
            fontFallback: [...fonts.fallback, ...scriptFonts],
          ),
        ),
        // Page numbers only when the document runs past one page. The
        // footer keeps the same height either way: MultiPage measures it
        // before the page count is final, and a footer that grew later
        // would be drawn over page 1's content.
        footer: (context) => pw.Container(
          height: 18,
          alignment: pw.Alignment.bottomRight,
          child: context.pagesCount < 2
              ? null
              : pw.Text(
                  '${invoice.invoiceNumber}  ·  Page ${context.pageNumber} of ${context.pagesCount}',
                  style: pw.TextStyle(fontSize: 7.5, color: activeTheme.slateColor),
                ),
        ),
        build: (context) => [
          _buildHeader(
            invoice,
            businessProfile,
            logoImage,
            dateFormat,
            activeTheme,
            config,
            isSamplePreview,
            scale,
          ),
          pw.SizedBox(height: 20 * scale),
          _buildAddressSection(invoice, businessProfile, activeTheme, config, scale),
          pw.SizedBox(height: 20 * scale),
          _buildLineItemsTable(invoice, businessProfile, currencySymbol, activeTheme, config, scale),
          pw.SizedBox(height: 18 * scale),
          _buildTotalsSection(invoice, businessProfile, currencySymbol, activeTheme, scale),
          if (config.showNotes && invoice.notes != null && invoice.notes!.trim().isNotEmpty) ...[
            pw.SizedBox(height: 18 * scale),
            _buildNotesSection(invoice.notes!, activeTheme, scale),
          ],
          pw.SizedBox(height: 20 * scale),
          _buildFooter(
            businessProfile,
            isPro,
            signatureImage,
            activeTheme,
            config,
            isSamplePreview,
            scale,
          ),
        ],
      ),
    );

    return pdf.save();
  }

  static pw.EdgeInsets _getPageMargin(PdfTheme theme) {
    switch (theme.paperStyle) {
      case PdfPaperStyle.leftVerticalRibbon:
        return const pw.EdgeInsets.fromLTRB(48, 36, 36, 36);
      case PdfPaperStyle.architecturalFrame:
        return const pw.EdgeInsets.all(44);
      case PdfPaperStyle.fullWidthBanner:
        return const pw.EdgeInsets.fromLTRB(36, 32, 36, 36);
      default:
        return const pw.EdgeInsets.all(36);
    }
  }

  static pw.Widget _buildPageBackground(pw.Context context, PdfTheme theme) {
    return pw.FullPage(
      ignoreMargins: true,
      child: pw.Stack(
        children: [
          // Base Paper Tint
          if (theme.paperStyle == PdfPaperStyle.warmParchment)
            pw.Container(color: PdfColor.fromHex('#FFFDF9'))
          else if (theme.paperStyle == PdfPaperStyle.securityDotGrid)
            pw.Container(color: PdfColor.fromHex('#FAFCFF')),

          // 1. Nordic Architectural Frame
          if (theme.paperStyle == PdfPaperStyle.architecturalFrame)
            pw.Container(
              margin: const pw.EdgeInsets.all(18),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: theme.primaryColor, width: 1.5),
              ),
              child: pw.Container(
                margin: const pw.EdgeInsets.all(4),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(
                    color: theme.borderColor,
                    width: 0.6,
                  ),
                ),
              ),
            ),

          // 2. Left Vertical Margin Ribbon
          if (theme.paperStyle == PdfPaperStyle.leftVerticalRibbon)
            pw.Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: pw.Container(
                width: 18,
                color: theme.primaryColor,
                child: pw.Column(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Container(
                      height: 60,
                      width: 18,
                      color: theme.secondaryColor,
                    ),
                    pw.Container(
                      height: 60,
                      width: 18,
                      color: theme.accentColor,
                    ),
                  ],
                ),
              ),
            ),

          // 3. Top Accent Line
          if (theme.paperStyle == PdfPaperStyle.topAccentLine)
            pw.Positioned(
              left: 36,
              right: 36,
              top: 20,
              child: pw.Container(
                height: 3.5,
                decoration: pw.BoxDecoration(
                  color: theme.primaryColor,
                  borderRadius: pw.BorderRadius.circular(2),
                ),
              ),
            ),

          // 4. Security Guilloche Micro-Dot Grid Pattern
          if (theme.paperStyle == PdfPaperStyle.securityDotGrid)
            pw.Positioned.fill(
              child: pw.CustomPaint(
                painter: (PdfGraphics canvas, PdfPoint size) {
                  canvas.setFillColor(theme.borderColor);
                  const step = 28.0;
                  for (double x = 36; x < size.x - 36; x += step) {
                    for (double y = 36; y < size.y - 36; y += step) {
                      canvas.drawEllipse(x, y, 0.8, 0.8);
                      canvas.fillPath();
                    }
                  }
                },
              ),
            ),
        ],
      ),
    );
  }

  static pw.Widget _buildHeader(
    InvoiceModel invoice,
    BusinessProfile profile,
    pw.MemoryImage? logo,
    DateFormat dateFormat,
    PdfTheme theme,
    InvoiceCustomizationConfig config,
    bool isSamplePreview,
    double scale,
  ) {
    if (config.headerPosition == HeaderPosition.fullWidthBanner) {
      return _buildGeometricBannerHeader(invoice, profile, logo, dateFormat, theme, isSamplePreview, scale);
    }
    if (config.headerPosition == HeaderPosition.centeredLogo) {
      return _buildCenteredHeader(invoice, profile, logo, dateFormat, theme, isSamplePreview, scale);
    }
    if (config.headerPosition == HeaderPosition.logoRightDetailsLeft) {
      return _buildRightLogoHeader(invoice, profile, logo, dateFormat, theme, isSamplePreview, scale);
    }

    // Default: logoLeftDetailsRight
    if (theme.paperStyle == PdfPaperStyle.asymmetricSplitHeader) {
      return _buildTwoToneSplitHeader(invoice, profile, logo, dateFormat, theme, isSamplePreview, scale);
    }
    if (theme.paperStyle == PdfPaperStyle.minimalDividers) {
      return _buildModernMinimalHeader(invoice, profile, logo, dateFormat, theme, isSamplePreview, scale);
    }

    return _buildStandardHeader(invoice, profile, logo, dateFormat, theme, isSamplePreview, scale);
  }

  static pw.Widget _buildStandardHeader(
    InvoiceModel invoice,
    BusinessProfile profile,
    pw.MemoryImage? logo,
    DateFormat dateFormat,
    PdfTheme theme,
    bool isSamplePreview,
    double scale,
  ) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Left: Logo + Business Name
        pw.Expanded(
          flex: 6,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              if (logo != null)
                pw.Container(
                  height: 50 * scale,
                  width: 120 * scale,
                  alignment: pw.Alignment.centerLeft,
                  child: pw.Image(logo, fit: pw.BoxFit.contain),
                )
              else
                _logoFallback(theme, 40 * scale, isSamplePreview),
              pw.SizedBox(height: 6 * scale),
              pw.Text(
                profile.businessName,
                style: pw.TextStyle(
                  fontSize: 15 * scale,
                  fontWeight: pw.FontWeight.bold,
                  color: theme.darkColor,
                ),
              ),
            ],
          ),
        ),
        // Right: INVOICE title + metadata box
        pw.Expanded(
          flex: 5,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                profile.titleFor(invoice),
                style: pw.TextStyle(
                  fontSize: 24 * scale,
                  fontWeight: pw.FontWeight.bold,
                  color: theme.primaryColor,
                  letterSpacing: 2,
                ),
              ),
              pw.SizedBox(height: 6 * scale),
              pw.Container(
                padding: pw.EdgeInsets.all(10 * scale),
                decoration: pw.BoxDecoration(
                  color: theme.lightGray,
                  borderRadius: pw.BorderRadius.circular(6),
                  border: pw.Border.all(color: theme.borderColor, width: 0.8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    _buildInfoRow(profile.numberLabel, invoice.invoiceNumber, theme, scale),
                    pw.SizedBox(height: 3 * scale),
                    _buildInfoRow('Date', dateFormat.format(invoice.invoiceDate), theme, scale),
                    if (invoice.dueDate != null) ...[
                      pw.SizedBox(height: 3 * scale),
                      _buildInfoRow(
                        profile.dueLabel,
                        dateFormat.format(invoice.dueDate!),
                        theme,
                        scale,
                      ),
                    ],
                    pw.SizedBox(height: 4 * scale),
                    _statusBadgeFor(invoice, profile, theme, scale),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildRightLogoHeader(
    InvoiceModel invoice,
    BusinessProfile profile,
    pw.MemoryImage? logo,
    DateFormat dateFormat,
    PdfTheme theme,
    bool isSamplePreview,
    double scale,
  ) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Left: INVOICE title + metadata box
        pw.Expanded(
          flex: 5,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                profile.titleFor(invoice),
                style: pw.TextStyle(
                  fontSize: 24 * scale,
                  fontWeight: pw.FontWeight.bold,
                  color: theme.primaryColor,
                  letterSpacing: 2,
                ),
              ),
              pw.SizedBox(height: 6 * scale),
              pw.Container(
                padding: pw.EdgeInsets.all(10 * scale),
                decoration: pw.BoxDecoration(
                  color: theme.lightGray,
                  borderRadius: pw.BorderRadius.circular(6),
                  border: pw.Border.all(color: theme.borderColor, width: 0.8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow(profile.numberLabel, invoice.invoiceNumber, theme, scale),
                    pw.SizedBox(height: 3 * scale),
                    _buildInfoRow('Date', dateFormat.format(invoice.invoiceDate), theme, scale),
                    if (invoice.dueDate != null) ...[
                      pw.SizedBox(height: 3 * scale),
                      _buildInfoRow(
                        profile.dueLabel,
                        dateFormat.format(invoice.dueDate!),
                        theme,
                        scale,
                      ),
                    ],
                    pw.SizedBox(height: 4 * scale),
                    _statusBadgeFor(invoice, profile, theme, scale),
                  ],
                ),
              ),
            ],
          ),
        ),
        pw.SizedBox(width: 16),
        // Right: Logo + Business Name
        pw.Expanded(
          flex: 6,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              if (logo != null)
                pw.Container(
                  height: 50 * scale,
                  width: 120 * scale,
                  alignment: pw.Alignment.centerRight,
                  child: pw.Image(logo, fit: pw.BoxFit.contain),
                )
              else
                _logoFallback(theme, 40 * scale, isSamplePreview),
              pw.SizedBox(height: 6 * scale),
              pw.Text(
                profile.businessName,
                style: pw.TextStyle(
                  fontSize: 15 * scale,
                  fontWeight: pw.FontWeight.bold,
                  color: theme.darkColor,
                ),
                textAlign: pw.TextAlign.end,
              ),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildCenteredHeader(
    InvoiceModel invoice,
    BusinessProfile profile,
    pw.MemoryImage? logo,
    DateFormat dateFormat,
    PdfTheme theme,
    bool isSamplePreview,
    double scale,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        if (logo != null)
          pw.Container(
            height: 46 * scale,
            alignment: pw.Alignment.center,
            child: pw.Image(logo, fit: pw.BoxFit.contain),
          )
        else
          _logoFallback(theme, 38 * scale, isSamplePreview),
        pw.SizedBox(height: 4 * scale),
        pw.Text(
          profile.businessName,
          style: pw.TextStyle(
            fontSize: 16 * scale,
            fontWeight: pw.FontWeight.bold,
            color: theme.darkColor,
          ),
          textAlign: pw.TextAlign.center,
        ),
        pw.SizedBox(height: 6 * scale),
        pw.Text(
          profile.titleFor(invoice),
          style: pw.TextStyle(
            fontSize: 20 * scale,
            fontWeight: pw.FontWeight.bold,
            color: theme.primaryColor,
            letterSpacing: 2,
          ),
          textAlign: pw.TextAlign.center,
        ),
        pw.SizedBox(height: 6 * scale),
        pw.Container(
          padding: pw.EdgeInsets.symmetric(horizontal: 14 * scale, vertical: 6 * scale),
          decoration: pw.BoxDecoration(
            color: theme.lightGray,
            borderRadius: pw.BorderRadius.circular(6),
            border: pw.Border.all(color: theme.borderColor, width: 0.8),
          ),
          child: pw.Wrap(
            alignment: pw.WrapAlignment.center,
            crossAxisAlignment: pw.WrapCrossAlignment.center,
            spacing: 12 * scale,
            runSpacing: 4 * scale,
            children: [
              _buildInfoRow(profile.numberLabel, invoice.invoiceNumber, theme, scale),
              _buildInfoRow('Date', dateFormat.format(invoice.invoiceDate), theme, scale),
              if (invoice.dueDate != null)
                _buildInfoRow(profile.dueLabel, dateFormat.format(invoice.dueDate!), theme, scale),
              _statusBadgeFor(invoice, profile, theme, scale),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildGeometricBannerHeader(
    InvoiceModel invoice,
    BusinessProfile profile,
    pw.MemoryImage? logo,
    DateFormat dateFormat,
    PdfTheme theme,
    bool isSamplePreview,
    double scale,
  ) {
    return pw.Container(
      padding: pw.EdgeInsets.all(14 * scale),
      decoration: pw.BoxDecoration(
        color: theme.primaryColor,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              if (logo != null)
                pw.Container(
                  height: 42 * scale,
                  width: 100 * scale,
                  alignment: pw.Alignment.centerLeft,
                  child: pw.Image(logo, fit: pw.BoxFit.contain),
                )
              else
                pw.Row(
                  children: [
                    pw.Container(
                      width: 28 * scale,
                      height: 28 * scale,
                      decoration: pw.BoxDecoration(
                        color: theme.accentColor,
                        borderRadius: pw.BorderRadius.circular(6),
                      ),
                      child: pw.Center(
                        child: pw.Text(
                          isSamplePreview ? 'AP' : _initials(profile.businessName),
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 12 * scale,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    pw.SizedBox(width: 8 * scale),
                    pw.Text(
                      profile.businessName,
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 15 * scale,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                profile.titleFor(invoice),
                style: pw.TextStyle(
                  color: PdfColors.white,
                  fontSize: 20 * scale,
                  fontWeight: pw.FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              pw.SizedBox(height: 2 * scale),
              pw.Text(
                '#${invoice.invoiceNumber}',
                style: pw.TextStyle(
                  color: theme.accentColor,
                  fontSize: 11 * scale,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                dateFormat.format(invoice.invoiceDate),
                style: pw.TextStyle(
                  color: PdfColor.fromHex('#94A3B8'),
                  fontSize: 9 * scale,
                ),
              ),
              if (invoice.dueDate != null)
                pw.Text(
                  '${profile.dueLabel}: ${dateFormat.format(invoice.dueDate!)}',
                  style: pw.TextStyle(
                    color: PdfColor.fromHex('#CBD5E1'),
                    fontSize: 9 * scale,
                  ),
                ),
              pw.SizedBox(height: 4 * scale),
              _statusBadgeFor(invoice, profile, theme, scale),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildTwoToneSplitHeader(
    InvoiceModel invoice,
    BusinessProfile profile,
    pw.MemoryImage? logo,
    DateFormat dateFormat,
    PdfTheme theme,
    bool isSamplePreview,
    double scale,
  ) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: theme.borderColor, width: 1),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Left Half (Dark Tone)
          pw.Expanded(
            flex: 5,
            child: pw.Container(
              padding: pw.EdgeInsets.all(14 * scale),
              decoration: pw.BoxDecoration(
                color: theme.primaryColor,
                borderRadius: const pw.BorderRadius.only(
                  topLeft: pw.Radius.circular(7),
                  bottomLeft: pw.Radius.circular(7),
                ),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  if (logo != null) ...[
                    pw.Container(
                      height: 36 * scale,
                      width: 90 * scale,
                      alignment: pw.Alignment.centerLeft,
                      child: pw.Image(logo, fit: pw.BoxFit.contain),
                    ),
                    pw.SizedBox(height: 6 * scale),
                  ],
                  pw.Text(
                    profile.businessName,
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 15 * scale,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  if (profile.email != null) ...[
                    pw.SizedBox(height: 2 * scale),
                    pw.Text(
                      profile.email!,
                      style: pw.TextStyle(color: PdfColor.fromHex('#CBD5E1'), fontSize: 8.5 * scale),
                    ),
                  ],
                ],
              ),
            ),
          ),
          // Right Half (Light Tone)
          pw.Expanded(
            flex: 5,
            child: pw.Container(
              padding: pw.EdgeInsets.all(14 * scale),
              color: theme.lightGray,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    profile.titleFor(invoice),
                    style: pw.TextStyle(
                      color: theme.primaryColor,
                      fontSize: 16 * scale,
                      fontWeight: pw.FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  pw.SizedBox(height: 3 * scale),
                  _buildInfoRow(profile.numberLabel, invoice.invoiceNumber, theme, scale),
                  _buildInfoRow('Date', dateFormat.format(invoice.invoiceDate), theme, scale),
                  if (invoice.dueDate != null)
                    _buildInfoRow(profile.dueLabel, dateFormat.format(invoice.dueDate!), theme, scale),
                  pw.SizedBox(height: 4 * scale),
                  _statusBadgeFor(invoice, profile, theme, scale),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildModernMinimalHeader(
    InvoiceModel invoice,
    BusinessProfile profile,
    pw.MemoryImage? logo,
    DateFormat dateFormat,
    PdfTheme theme,
    bool isSamplePreview,
    double scale,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                if (logo != null)
                  pw.Container(
                    height: 44 * scale,
                    width: 110 * scale,
                    margin: pw.EdgeInsets.only(bottom: 6 * scale),
                    alignment: pw.Alignment.centerLeft,
                    child: pw.Image(logo, fit: pw.BoxFit.contain),
                  )
                else
                  _logoFallback(theme, 36 * scale, isSamplePreview),
                pw.SizedBox(height: 4 * scale),
                pw.Text(
                  profile.businessName,
                  style: pw.TextStyle(
                    fontSize: 18 * scale,
                    fontWeight: pw.FontWeight.bold,
                    color: theme.darkColor,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  profile.titleFor(invoice),
                  style: pw.TextStyle(
                    fontSize: 20 * scale,
                    fontWeight: pw.FontWeight.bold,
                    color: theme.darkColor,
                    letterSpacing: 3,
                  ),
                ),
                pw.SizedBox(height: 2 * scale),
                pw.Text(
                  '#${invoice.invoiceNumber}',
                  style: pw.TextStyle(
                    fontSize: 11 * scale,
                    fontWeight: pw.FontWeight.bold,
                    color: theme.slateColor,
                  ),
                ),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 10 * scale),
        pw.Container(
          height: 1,
          color: theme.borderColor,
        ),
        pw.SizedBox(height: 8 * scale),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Row(
              children: [
                pw.Text(
                  'Date: ',
                  style: pw.TextStyle(fontSize: 9 * scale, color: theme.slateColor),
                ),
                pw.Text(
                  dateFormat.format(invoice.invoiceDate),
                  style: pw.TextStyle(fontSize: 9 * scale, fontWeight: pw.FontWeight.bold, color: theme.darkColor),
                ),
                if (invoice.dueDate != null) ...[
                  pw.SizedBox(width: 14 * scale),
                  pw.Text(
                    '${profile.dueLabel}: ',
                    style: pw.TextStyle(fontSize: 9 * scale, color: theme.slateColor),
                  ),
                  pw.Text(
                    dateFormat.format(invoice.dueDate!),
                    style: pw.TextStyle(fontSize: 9 * scale, fontWeight: pw.FontWeight.bold, color: theme.darkColor),
                  ),
                ],
              ],
            ),
            _statusBadgeFor(invoice, profile, theme, scale),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildInfoRow(String label, String value, PdfTheme theme, double scale) {
    return pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Text(
          '$label ',
          style: pw.TextStyle(fontSize: 8.5 * scale, color: theme.slateColor),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 8.5 * scale,
            fontWeight: pw.FontWeight.bold,
            color: theme.darkColor,
          ),
        ),
      ],
    );
  }

  /// Payment status badge; estimates have no payment status.
  static pw.Widget _statusBadgeFor(
    InvoiceModel invoice,
    BusinessProfile profile,
    PdfTheme theme,
    double scale,
  ) =>
      profile.isEstimate ? pw.SizedBox() : _buildStatusBadge(invoice.effectiveStatus, theme, scale);

  static pw.Widget _buildStatusBadge(InvoiceStatus status, PdfTheme theme, double scale) {
    PdfColor bgColor;
    PdfColor textColor;
    String label;

    switch (status) {
      case InvoiceStatus.paid:
        bgColor = PdfColor.fromHex('#D1FAE5');
        textColor = PdfColor.fromHex('#065F46');
        label = 'PAID';
        break;
      case InvoiceStatus.partiallyPaid:
        bgColor = PdfColor.fromHex('#FEF3C7');
        textColor = PdfColor.fromHex('#92400E');
        label = 'PARTIALLY PAID';
        break;
      case InvoiceStatus.overdue:
        bgColor = PdfColor.fromHex('#FEE2E2');
        textColor = PdfColor.fromHex('#991B1B');
        label = 'OVERDUE';
        break;
      default:
        bgColor = PdfColor.fromHex('#FEF3C7');
        textColor = PdfColor.fromHex('#92400E');
        label = 'UNPAID';
    }

    return pw.Container(
      padding: pw.EdgeInsets.symmetric(horizontal: 7 * scale, vertical: 2 * scale),
      decoration: pw.BoxDecoration(
        color: bgColor,
        borderRadius: pw.BorderRadius.circular(3),
      ),
      child: pw.Text(
        label,
        style: pw.TextStyle(
          fontSize: 7.5 * scale,
          fontWeight: pw.FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }

  static pw.Widget _buildAddressSection(
    InvoiceModel invoice,
    BusinessProfile profile,
    PdfTheme theme,
    InvoiceCustomizationConfig config,
    double scale,
  ) {
    final isMinimal = theme.paperStyle == PdfPaperStyle.minimalDividers;

    final fromBox = pw.Container(
      padding: pw.EdgeInsets.all(10 * scale),
      decoration: pw.BoxDecoration(
        color: isMinimal ? null : PdfColors.white,
        border: isMinimal
            ? null
            : pw.Border.all(color: theme.borderColor, width: 0.8),
        borderRadius: isMinimal ? null : pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'FROM',
            style: pw.TextStyle(
              fontSize: 8 * scale,
              fontWeight: pw.FontWeight.bold,
              color: isMinimal ? theme.primaryColor : theme.slateColor,
              letterSpacing: 1,
            ),
          ),
          pw.SizedBox(height: 5 * scale),
          pw.Text(
            profile.businessName,
            style: pw.TextStyle(
              fontSize: 11 * scale,
              fontWeight: pw.FontWeight.bold,
              color: theme.darkColor,
            ),
          ),
          if (profile.address != null && profile.address!.trim().isNotEmpty) ...[
            pw.SizedBox(height: 2 * scale),
            pw.Text(
              profile.address!,
              style: pw.TextStyle(fontSize: 8.5 * scale, color: theme.slateColor),
            ),
          ],
          if (profile.phone != null && profile.phone!.trim().isNotEmpty) ...[
            pw.SizedBox(height: 2 * scale),
            pw.Text(
              profile.phone!,
              style: pw.TextStyle(fontSize: 8.5 * scale, color: theme.slateColor),
            ),
          ],
          if (profile.email != null && profile.email!.trim().isNotEmpty) ...[
            pw.SizedBox(height: 2 * scale),
            pw.Text(
              profile.email!,
              style: pw.TextStyle(fontSize: 8.5 * scale, color: theme.slateColor),
            ),
          ],
          if (profile.website != null && profile.website!.trim().isNotEmpty) ...[
            pw.SizedBox(height: 2 * scale),
            pw.Text(
              profile.website!,
              style: pw.TextStyle(fontSize: 8.5 * scale, color: theme.slateColor),
            ),
          ],
          if (profile.gstin != null && profile.gstin!.trim().isNotEmpty) ...[
            pw.SizedBox(height: 2 * scale),
            pw.Text(
              '${profile.taxIdLabel}: ${profile.gstin}',
              style: pw.TextStyle(fontSize: 8 * scale, color: theme.slateColor),
            ),
          ],
        ],
      ),
    );

    final billToBox = pw.Container(
      padding: pw.EdgeInsets.all(10 * scale),
      decoration: pw.BoxDecoration(
        color: isMinimal ? null : theme.lightGray,
        border: isMinimal
            ? null
            : pw.Border.all(color: theme.borderColor, width: 0.8),
        borderRadius: isMinimal ? null : pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'BILL TO',
            style: pw.TextStyle(
              fontSize: 8 * scale,
              fontWeight: pw.FontWeight.bold,
              color: isMinimal ? theme.primaryColor : theme.slateColor,
              letterSpacing: 1,
            ),
          ),
          pw.SizedBox(height: 5 * scale),
          pw.Text(
            invoice.clientName,
            style: pw.TextStyle(
              fontSize: 11 * scale,
              fontWeight: pw.FontWeight.bold,
              color: theme.darkColor,
            ),
          ),
          if (invoice.clientAddress != null && invoice.clientAddress!.trim().isNotEmpty) ...[
            pw.SizedBox(height: 2 * scale),
            pw.Text(
              invoice.clientAddress!,
              style: pw.TextStyle(fontSize: 8.5 * scale, color: theme.slateColor),
            ),
          ],
          if (invoice.clientPhone != null && invoice.clientPhone!.trim().isNotEmpty) ...[
            pw.SizedBox(height: 2 * scale),
            pw.Text(
              invoice.clientPhone!,
              style: pw.TextStyle(fontSize: 8.5 * scale, color: theme.slateColor),
            ),
          ],
          if (invoice.clientEmail != null && invoice.clientEmail!.trim().isNotEmpty) ...[
            pw.SizedBox(height: 2 * scale),
            pw.Text(
              invoice.clientEmail!,
              style: pw.TextStyle(fontSize: 8.5 * scale, color: theme.slateColor),
            ),
          ],
          if (invoice.clientGstin != null && invoice.clientGstin!.trim().isNotEmpty) ...[
            pw.SizedBox(height: 2 * scale),
            pw.Text(
              '${profile.taxIdLabel}: ${invoice.clientGstin}',
              style: pw.TextStyle(fontSize: 8 * scale, color: theme.slateColor),
            ),
          ],
        ],
      ),
    );

    if (config.addressLayout == AddressLayout.inverted) {
      return pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(child: billToBox),
          pw.SizedBox(width: 12),
          pw.Expanded(child: fromBox),
        ],
      );
    }

    if (config.addressLayout == AddressLayout.stacked) {
      return pw.Column(
        children: [
          pw.Container(width: double.infinity, child: fromBox),
          pw.SizedBox(height: 8 * scale),
          pw.Container(width: double.infinity, child: billToBox),
        ],
      );
    }

    // Default: sideBySide
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(child: fromBox),
        pw.SizedBox(width: 12),
        pw.Expanded(child: billToBox),
      ],
    );
  }

  static pw.Widget _buildLineItemsTable(
    InvoiceModel invoice,
    BusinessProfile profile,
    String currencySymbol,
    PdfTheme theme,
    InvoiceCustomizationConfig config,
    double scale,
  ) {
    final isMinimal = theme.paperStyle == PdfPaperStyle.minimalDividers;
    String money(double v) =>
        CurrencyFormatter.format(v, currencyCode: invoice.currency, currencySymbol: currencySymbol);

    final showQty = config.showQuantity;
    final showUnitPrice = config.showUnitPrice;

    final headerTextStyle = pw.TextStyle(
      color: theme.tableHeaderTextColor,
      fontSize: 8.5 * scale,
      fontWeight: pw.FontWeight.bold,
      letterSpacing: isMinimal ? 0.5 : 0,
    );

    final Map<int, pw.TableColumnWidth> columnWidths = {};
    int colIdx = 0;
    columnWidths[colIdx++] = const pw.FlexColumnWidth(5.0);
    if (showQty) columnWidths[colIdx++] = const pw.FlexColumnWidth(1.4);
    if (showUnitPrice) columnWidths[colIdx++] = const pw.FlexColumnWidth(2.0);
    columnWidths[colIdx++] = const pw.FlexColumnWidth(2.1);

    final headerCells = <pw.Widget>[
      _tableCell('DESCRIPTION', style: headerTextStyle, isHeader: true, scale: scale),
      if (showQty)
        _tableCell(
          'QTY',
          style: headerTextStyle,
          isHeader: true,
          align: pw.Alignment.centerRight,
          scale: scale,
        ),
      if (showUnitPrice)
        _tableCell(
          'UNIT PRICE',
          style: headerTextStyle,
          isHeader: true,
          align: pw.Alignment.centerRight,
          scale: scale,
        ),
      _tableCell(
        'TOTAL',
        style: headerTextStyle,
        isHeader: true,
        align: pw.Alignment.centerRight,
        scale: scale,
      ),
    ];

    return pw.Table(
      border: isMinimal
          ? pw.TableBorder(
              top: pw.BorderSide(color: theme.primaryColor, width: 1.2),
              bottom: pw.BorderSide(color: theme.borderColor, width: 1),
              horizontalInside: pw.BorderSide(color: theme.borderColor, width: 0.5),
            )
          : pw.TableBorder.all(color: theme.borderColor, width: 0.5),
      columnWidths: columnWidths,
      children: [
        // Header row
        pw.TableRow(
          repeat: true, // header again on every page
          decoration: pw.BoxDecoration(color: theme.tableHeaderBg),
          children: headerCells,
        ),
        // Item rows
        ...invoice.lineItems.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final isAlt = index % 2 == 1;
          final rowBg = isAlt ? theme.lightGray : PdfColors.white;
          final rowStyle = pw.TextStyle(fontSize: 9 * scale, color: theme.darkColor);
          final rowStyleSecondary = pw.TextStyle(
            fontSize: 9 * scale,
            color: theme.slateColor,
          );

          // HSN/SAC, the line's own discount and its own tax rate.
          final details = <String>[
            if (item.hsnSac != null) '${profile.isDualTax ? 'HSN/SAC' : 'Code'} ${item.hsnSac}',
            if (item.discountRate > 0) '${NumberText.trim(item.discountRate)}% off',
            if (config.showTaxColumn && item.taxRate != null)
              item.taxRate == 0 ? 'Tax exempt' : '${profile.taxShortName} ${NumberText.trim(item.taxRate!)}%',
          ];
          final descriptionCell = details.isEmpty
              ? _tableCell(item.description, style: rowStyle, scale: scale)
              : pw.Container(
                  padding: pw.EdgeInsets.symmetric(horizontal: 9 * scale, vertical: 6 * scale),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(item.description, style: rowStyle),
                      pw.SizedBox(height: 1.5 * scale),
                      pw.Text(
                        details.join('  ·  '),
                        style: pw.TextStyle(fontSize: 7 * scale, color: theme.slateColor),
                      ),
                    ],
                  ),
                );

          final cells = <pw.Widget>[
            descriptionCell,
            if (showQty)
              _tableCell(
                '${NumberText.trim(item.quantity, maxDecimals: 3)}${item.unit != null ? ' ${item.unit}' : ''}',
                style: rowStyleSecondary,
                align: pw.Alignment.centerRight,
                scale: scale,
              ),
            if (showUnitPrice)
              _tableCell(
                money(item.unitPrice),
                style: rowStyleSecondary,
                align: pw.Alignment.centerRight,
                scale: scale,
              ),
            _tableCell(
              money(item.total),
              style: rowStyle,
              align: pw.Alignment.centerRight,
              scale: scale,
            ),
          ];

          return pw.TableRow(
            decoration: pw.BoxDecoration(color: rowBg),
            children: cells,
          );
        }),
      ],
    );
  }

  static pw.Widget _tableCell(
    String text, {
    pw.TextStyle? style,
    bool isHeader = false,
    pw.Alignment align = pw.Alignment.centerLeft,
    double scale = 1.0,
  }) {
    return pw.Container(
      padding: pw.EdgeInsets.symmetric(
        horizontal: 9 * scale,
        vertical: (isHeader ? 7 : 6) * scale,
      ),
      alignment: align,
      child: pw.Text(text, style: style),
    );
  }

  static pw.Widget _buildTotalsSection(
    InvoiceModel invoice,
    BusinessProfile profile,
    String currencySymbol,
    PdfTheme theme,
    double scale,
  ) {
    final taxShortName = profile.taxShortName;
    // Every printed figure comes from the same calculation the editor uses,
    // so the rows always add up to the grand total.
    final totals = DocumentTotals.ofInvoice(invoice);
    String money(double v) =>
        CurrencyFormatter.format(v, currencyCode: invoice.currency, currencySymbol: currencySymbol);
    String taxLabel(TaxComponent c) {
      final name = switch (c.kind) {
        TaxComponentKind.cgst => 'CGST',
        TaxComponentKind.sgst => 'SGST',
        TaxComponentKind.igst => 'IGST',
        TaxComponentKind.single => taxShortName,
      };
      return '$name (${NumberText.trim(c.rate)}%)';
    }

    pw.Widget divider() => pw.Divider(color: theme.borderColor, height: 1, thickness: 0.5);
    final inWords = AmountInWords.format(totals.grandTotal, invoice.currency);

    final box = pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.end,
      children: [
        pw.Container(
          width: 240 * scale,
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: theme.borderColor, width: 0.8),
            borderRadius: pw.BorderRadius.circular(6),
          ),
          child: pw.Column(
            children: [
              _buildTotalRow('Subtotal', money(totals.subtotal), theme, scale),
              if (totals.discountAmount > 0) ...[
                divider(),
                _buildTotalRow(
                  invoice.discountType == DiscountType.percentage
                      ? 'Discount (${NumberText.trim(invoice.discountValue)}%)'
                      : 'Discount',
                  '-${money(totals.discountAmount)}',
                  theme,
                  scale,
                  valueColor: theme.paperStyle == PdfPaperStyle.minimalDividers
                      ? theme.darkColor
                      : theme.accentColor,
                ),
                if (totals.taxComponents.isNotEmpty) ...[
                  divider(),
                  _buildTotalRow('Taxable Amount', money(totals.taxableAmount), theme, scale),
                ],
              ],
              for (final c in totals.taxComponents) ...[
                divider(),
                _buildTotalRow(taxLabel(c), money(c.amount), theme, scale),
              ],
              if (totals.shipping > 0) ...[
                divider(),
                _buildTotalRow('Shipping', money(totals.shipping), theme, scale),
              ],
              if (invoice.status == InvoiceStatus.partiallyPaid || invoice.paidAmount > 0) ...[
                divider(),
                _buildTotalRow(
                  'Amount Paid',
                  money(invoice.paidAmount),
                  theme,
                  scale,
                  valueColor: PdfColor.fromHex('#059669'),
                ),
                pw.Divider(color: theme.borderColor, height: 1, thickness: 0.5),
                _buildTotalRow(
                  'Balance Due',
                  money((totals.grandTotal - invoice.paidAmount).clamp(0, double.infinity).toDouble()),
                  theme,
                  scale,
                  valueColor: PdfColor.fromHex('#D97706'),
                ),
              ],
              pw.Container(
                decoration: pw.BoxDecoration(
                  color: theme.primaryColor,
                  borderRadius: const pw.BorderRadius.only(
                    bottomLeft: pw.Radius.circular(5),
                    bottomRight: pw.Radius.circular(5),
                  ),
                ),
                padding: pw.EdgeInsets.symmetric(
                  horizontal: 12 * scale,
                  vertical: 9 * scale,
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'GRAND TOTAL',
                      style: pw.TextStyle(
                        fontSize: 10.5 * scale,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    pw.Text(
                      money(totals.grandTotal),
                      style: pw.TextStyle(
                        fontSize: 12.5 * scale,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
    if (inWords == null) return box;
    // Inseparable: the words stay on the same page as the totals box.
    return pw.Inseparable(
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          box,
          pw.SizedBox(height: 8 * scale),
          pw.Text(
            'Amount in words: $inWords',
            textAlign: pw.TextAlign.right,
            style: pw.TextStyle(
              fontSize: 8.5 * scale,
              color: theme.slateColor,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildTotalRow(
    String label,
    String value,
    PdfTheme theme,
    double scale, {
    PdfColor? valueColor,
  }) {
    return pw.Padding(
      padding: pw.EdgeInsets.symmetric(horizontal: 12 * scale, vertical: 6 * scale),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: 8.5 * scale, color: theme.slateColor)),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 8.5 * scale,
              fontWeight: pw.FontWeight.bold,
              color: valueColor ?? theme.darkColor,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildNotesSection(String notes, PdfTheme theme, double scale) {
    final isMinimal = theme.paperStyle == PdfPaperStyle.minimalDividers;

    return pw.Container(
      width: double.infinity,
      padding: pw.EdgeInsets.all(10 * scale),
      decoration: pw.BoxDecoration(
        color: isMinimal ? null : theme.lightGray,
        border: isMinimal ? pw.Border.all(color: theme.borderColor, width: 0.8) : null,
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'NOTES',
            style: pw.TextStyle(
              fontSize: 7.5 * scale,
              fontWeight: pw.FontWeight.bold,
              color: theme.slateColor,
              letterSpacing: 1,
            ),
          ),
          pw.SizedBox(height: 3 * scale),
          pw.Text(notes, style: pw.TextStyle(fontSize: 8.5 * scale, color: theme.slateColor)),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter(
    BusinessProfile profile,
    bool isPro,
    pw.MemoryImage? signatureImage,
    PdfTheme theme,
    InvoiceCustomizationConfig config,
    bool isSamplePreview,
    double scale,
  ) {
    final hasBankDetails = config.showBankDetails &&
        ((profile.bankName != null && profile.bankName!.trim().isNotEmpty) ||
         (profile.accountNumber != null && profile.accountNumber!.trim().isNotEmpty) ||
         (profile.ifscCode != null && profile.ifscCode!.trim().isNotEmpty));
    final hasUpiDetails = config.showUpiDetails &&
        (profile.upiId != null && profile.upiId!.trim().isNotEmpty);
    final showPaymentDetails = hasBankDetails || hasUpiDetails;

    final thankYouText = (config.customFooterMessage != null &&
            config.customFooterMessage!.trim().isNotEmpty)
        ? config.customFooterMessage!.trim()
        : 'Thank you for your business!';

    return pw.Column(
      children: [
        if (showPaymentDetails) ...[
          pw.Divider(color: theme.borderColor, thickness: 0.8),
          pw.SizedBox(height: 6 * scale),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'PAYMENT DETAILS',
                      style: pw.TextStyle(
                        fontSize: 8 * scale,
                        fontWeight: pw.FontWeight.bold,
                        color: theme.slateColor,
                        letterSpacing: 1,
                      ),
                    ),
                    pw.SizedBox(height: 4 * scale),
                    if (config.showBankDetails) ...[
                      if (profile.bankName != null && profile.bankName!.trim().isNotEmpty)
                        pw.Text(
                          'Bank: ${profile.bankName}',
                          style: pw.TextStyle(fontSize: 8.5 * scale, color: theme.slateColor),
                        ),
                      if (profile.accountNumber != null && profile.accountNumber!.trim().isNotEmpty)
                        pw.Text(
                          '${profile.bankAccountLabel}: ${profile.accountNumber}',
                          style: pw.TextStyle(fontSize: 8.5 * scale, color: theme.slateColor),
                        ),
                      if (profile.ifscCode != null && profile.ifscCode!.trim().isNotEmpty)
                        pw.Text(
                          '${profile.bankRoutingLabel}: ${profile.ifscCode}',
                          style: pw.TextStyle(fontSize: 8.5 * scale, color: theme.slateColor),
                        ),
                    ],
                    if (config.showUpiDetails &&
                        profile.upiId != null &&
                        profile.upiId!.trim().isNotEmpty)
                      pw.Text(
                        '${profile.digitalPaymentLabel}: ${profile.upiId}',
                        style: pw.TextStyle(fontSize: 8.5 * scale, color: theme.slateColor),
                      ),
                  ],
                ),
              ),
              if (config.showSignature)
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      if (signatureImage != null)
                        pw.Container(
                          height: 40 * scale,
                          width: 85 * scale,
                          alignment: pw.Alignment.centerRight,
                          child: pw.Image(signatureImage, fit: pw.BoxFit.contain),
                        )
                      else if (isSamplePreview)
                        DummyInvoiceData.buildVectorSignature(theme)
                      else
                        pw.SizedBox(height: 20 * scale),
                      pw.SizedBox(height: 6 * scale),
                      pw.Text(
                        thankYouText,
                        style: pw.TextStyle(
                          fontSize: 10 * scale,
                          fontWeight: pw.FontWeight.bold,
                          color: theme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                )
              else
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        thankYouText,
                        style: pw.TextStyle(
                          fontSize: 10 * scale,
                          fontWeight: pw.FontWeight.bold,
                          color: theme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ] else ...[
          pw.Divider(color: theme.borderColor, thickness: 0.8),
          pw.SizedBox(height: 6 * scale),
          if (config.showSignature) ...[
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                if (signatureImage != null)
                  pw.Container(
                    height: 40 * scale,
                    width: 85 * scale,
                    child: pw.Image(signatureImage, fit: pw.BoxFit.contain),
                  )
                else if (isSamplePreview)
                  DummyInvoiceData.buildVectorSignature(theme)
                else
                  pw.SizedBox(height: 20 * scale),
              ],
            ),
            pw.SizedBox(height: 6 * scale),
          ],
          pw.Center(
            child: pw.Text(
              thankYouText,
              style: pw.TextStyle(
                fontSize: 10 * scale,
                fontWeight: pw.FontWeight.bold,
                color: theme.primaryColor,
              ),
            ),
          ),
        ],
        if (!isPro) ...[
          pw.SizedBox(height: 8 * scale),
          pw.Center(
            child: pw.Text(
              'Generated by Invoice Maker Pro',
              style: pw.TextStyle(
                fontSize: 7.5 * scale,
                color: PdfColor.fromHex('#94A3B8'),
              ),
            ),
          ),
        ],
      ],
    );
  }

  static Future<String> saveAndGetPath(
    Uint8List pdfBytes,
    String invoiceNumber,
  ) async {
    return await PdfHelper.savePdf(pdfBytes, invoiceNumber);
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
    final fallbacks = [arabic, bengali, thai];

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
        base = await _loadFont('assets/fonts/NotoSans-Regular.ttf');
        bold = await _loadFont('assets/fonts/NotoSans-Bold.ttf');
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
