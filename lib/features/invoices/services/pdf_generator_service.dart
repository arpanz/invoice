import 'dart:io';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/invoice_model.dart';
import '../models/pdf_theme.dart';
import 'dummy_invoice_data.dart';
import '../../../core/models/currency_model.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/pdf_helper.dart';
import '../../estimates/models/estimate_model.dart';

class BusinessProfile {
  final String businessName;
  final String? address;
  final String? phone;
  final String? email;
  final String? gstin;
  final String? bankName;
  final String? accountNumber;
  final String? ifscCode;
  final String? logoPath;
  final String? signaturePath;
  final String currency;
  final String? invoiceTitleOverride;

  const BusinessProfile({
    required this.businessName,
    this.address,
    this.phone,
    this.email,
    this.gstin,
    this.bankName,
    this.accountNumber,
    this.ifscCode,
    this.logoPath,
    this.signaturePath,
    this.currency = 'INR',
    this.invoiceTitleOverride,
  });

  Currency? get currencyConfig => SupportedCurrencies.getByCode(currency);
  String get taxIdLabel => currencyConfig?.defaultTax.taxIdLabel ?? 'Tax ID';
  String get bankRoutingLabel => currencyConfig?.defaultTax.bankRoutingLabel ?? 'Routing / IFSC';
  String get bankAccountLabel => currencyConfig?.defaultTax.bankAccountLabel ?? 'Account Number';
  String get invoiceTitle => invoiceTitleOverride ?? currencyConfig?.defaultTax.invoiceTitle ?? 'INVOICE';
  bool get isDualTax => currencyConfig?.defaultTax.isDualTax ?? false;
  String get taxShortName => currencyConfig?.defaultTax.shortName ?? 'Tax';
  int get decimalPlaces => currencyConfig?.decimalPlaces ?? 2;
}

class PdfGeneratorService {
  PdfGeneratorService._();

  static Future<_PdfFonts>? _fontsFuture;

  static Future<Uint8List> generateEstimatePdf({
    required EstimateModel estimate,
    required BusinessProfile businessProfile,
    required bool isPro,
    PdfTheme? theme,
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
      isSamplePreview: isSamplePreview,
    );
  }

  static Future<Uint8List> generateInvoicePdf({
    required InvoiceModel invoice,
    required BusinessProfile businessProfile,
    required bool isPro,
    PdfTheme? theme,
    bool isSamplePreview = false,
  }) async {
    final activeTheme = theme ?? PdfTheme.defaultTheme;
    final fonts = await _loadFonts();
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

    // Page margins adjusted per paper style
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
            fontFallback: fonts.fallback,
          ),
        ),
        build: (context) => [
          _buildHeader(
            invoice,
            businessProfile,
            logoImage,
            dateFormat,
            activeTheme,
            isSamplePreview,
          ),
          pw.SizedBox(height: 20),
          _buildAddressSection(invoice, businessProfile, activeTheme),
          pw.SizedBox(height: 20),
          _buildLineItemsTable(invoice, businessProfile, currencySymbol, activeTheme),
          pw.SizedBox(height: 18),
          _buildTotalsSection(invoice, businessProfile, currencySymbol, activeTheme),
          if (invoice.notes != null && invoice.notes!.trim().isNotEmpty) ...[
            pw.SizedBox(height: 18),
            _buildNotesSection(invoice.notes!, activeTheme),
          ],
          pw.SizedBox(height: 20),
          _buildFooter(
            businessProfile,
            isPro,
            signatureImage,
            activeTheme,
            isSamplePreview,
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
                  const step = 24.0;
                  for (double x = 20; x < size.x - 20; x += step) {
                    for (double y = 20; y < size.y - 20; y += step) {
                      canvas.drawEllipse(x, y, 0.6, 0.6);
                    }
                  }
                  canvas.fillPath();
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
    bool isSamplePreview,
  ) {
    if (theme.paperStyle == PdfPaperStyle.fullWidthBanner) {
      return _buildGeometricBannerHeader(invoice, profile, logo, dateFormat, theme, isSamplePreview);
    }
    if (theme.paperStyle == PdfPaperStyle.asymmetricSplitHeader) {
      return _buildTwoToneSplitHeader(invoice, profile, logo, dateFormat, theme, isSamplePreview);
    }
    if (theme.paperStyle == PdfPaperStyle.minimalDividers) {
      return _buildModernMinimalHeader(invoice, profile, logo, dateFormat, theme, isSamplePreview);
    }

    // Standard & Framed Headers
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
                  height: 50,
                  width: 120,
                  alignment: pw.Alignment.centerLeft,
                  child: pw.Image(logo, fit: pw.BoxFit.contain),
                )
              else
                DummyInvoiceData.buildVectorLogo(theme, size: 40),
              pw.SizedBox(height: 6),
              pw.Text(
                profile.businessName,
                style: pw.TextStyle(
                  fontSize: 15,
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
                profile.invoiceTitle,
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                  color: theme.primaryColor,
                  letterSpacing: 2,
                ),
              ),
              pw.SizedBox(height: 6),
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: theme.lightGray,
                  borderRadius: pw.BorderRadius.circular(6),
                  border: pw.Border.all(color: theme.borderColor, width: 0.8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    _buildInfoRow('Invoice #', invoice.invoiceNumber, theme),
                    pw.SizedBox(height: 3),
                    _buildInfoRow('Date', dateFormat.format(invoice.invoiceDate), theme),
                    if (invoice.dueDate != null) ...[
                      pw.SizedBox(height: 3),
                      _buildInfoRow(
                        'Due Date',
                        dateFormat.format(invoice.dueDate!),
                        theme,
                      ),
                    ],
                    pw.SizedBox(height: 4),
                    _buildStatusBadge(invoice.status, theme),
                  ],
                ),
              ),
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
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
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
                  height: 42,
                  width: 100,
                  alignment: pw.Alignment.centerLeft,
                  child: pw.Image(logo, fit: pw.BoxFit.contain),
                )
              else
                pw.Row(
                  children: [
                    pw.Container(
                      width: 28,
                      height: 28,
                      decoration: pw.BoxDecoration(
                        color: theme.accentColor,
                        borderRadius: pw.BorderRadius.circular(6),
                      ),
                      child: pw.Center(
                        child: pw.Text(
                          'AP',
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    pw.SizedBox(width: 8),
                    pw.Text(
                      profile.businessName,
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 15,
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
                profile.invoiceTitle,
                style: pw.TextStyle(
                  color: PdfColors.white,
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                '#${invoice.invoiceNumber}',
                style: pw.TextStyle(
                  color: theme.accentColor,
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                dateFormat.format(invoice.invoiceDate),
                style: pw.TextStyle(
                  color: PdfColor.fromHex('#94A3B8'),
                  fontSize: 9,
                ),
              ),
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
              padding: const pw.EdgeInsets.all(14),
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
                  pw.Text(
                    profile.businessName,
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 15,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  if (profile.email != null) ...[
                    pw.SizedBox(height: 2),
                    pw.Text(
                      profile.email!,
                      style: pw.TextStyle(color: PdfColor.fromHex('#CBD5E1'), fontSize: 8.5),
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
              padding: const pw.EdgeInsets.all(14),
              color: theme.lightGray,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    profile.invoiceTitle,
                    style: pw.TextStyle(
                      color: theme.primaryColor,
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  pw.SizedBox(height: 3),
                  _buildInfoRow('Invoice #', invoice.invoiceNumber, theme),
                  _buildInfoRow('Date', dateFormat.format(invoice.invoiceDate), theme),
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
                    height: 44,
                    width: 110,
                    margin: const pw.EdgeInsets.only(bottom: 6),
                    alignment: pw.Alignment.centerLeft,
                    child: pw.Image(logo, fit: pw.BoxFit.contain),
                  )
                else
                  DummyInvoiceData.buildVectorLogo(theme, size: 36),
                pw.SizedBox(height: 4),
                pw.Text(
                  profile.businessName,
                  style: pw.TextStyle(
                    fontSize: 18,
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
                  profile.invoiceTitle,
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                    color: theme.darkColor,
                    letterSpacing: 3,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  '#${invoice.invoiceNumber}',
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                    color: theme.slateColor,
                  ),
                ),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 10),
        pw.Container(
          height: 1,
          color: theme.borderColor,
        ),
        pw.SizedBox(height: 8),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Row(
              children: [
                pw.Text(
                  'Date: ',
                  style: pw.TextStyle(fontSize: 9, color: theme.slateColor),
                ),
                pw.Text(
                  dateFormat.format(invoice.invoiceDate),
                  style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: theme.darkColor),
                ),
                if (invoice.dueDate != null) ...[
                  pw.SizedBox(width: 14),
                  pw.Text(
                    'Due Date: ',
                    style: pw.TextStyle(fontSize: 9, color: theme.slateColor),
                  ),
                  pw.Text(
                    dateFormat.format(invoice.dueDate!),
                    style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: theme.darkColor),
                  ),
                ],
              ],
            ),
            _buildStatusBadge(invoice.status, theme),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildInfoRow(String label, String value, PdfTheme theme) {
    return pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Text(
          '$label ',
          style: pw.TextStyle(fontSize: 8.5, color: theme.slateColor),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 8.5,
            fontWeight: pw.FontWeight.bold,
            color: theme.darkColor,
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildStatusBadge(InvoiceStatus status, PdfTheme theme) {
    PdfColor bgColor;
    PdfColor textColor;
    String label;

    switch (status) {
      case InvoiceStatus.paid:
        bgColor = PdfColor.fromHex('#D1FAE5');
        textColor = PdfColor.fromHex('#065F46');
        label = 'PAID';
        break;
      case InvoiceStatus.overdue:
        bgColor = PdfColor.fromHex('#FEE2E2');
        textColor = PdfColor.fromHex('#991B1B');
        label = 'OVERDUE';
        break;
      default:
        bgColor = theme.paperStyle == PdfPaperStyle.warmParchment
            ? PdfColor.fromHex('#FEF3C7')
            : PdfColor.fromHex('#FEF3C7');
        textColor = PdfColor.fromHex('#92400E');
        label = 'UNPAID';
    }

    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: pw.BoxDecoration(
        color: bgColor,
        borderRadius: pw.BorderRadius.circular(3),
      ),
      child: pw.Text(
        label,
        style: pw.TextStyle(
          fontSize: 7.5,
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
  ) {
    final isMinimal = theme.paperStyle == PdfPaperStyle.minimalDividers;

    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // From
        pw.Expanded(
          child: pw.Container(
            padding: const pw.EdgeInsets.all(10),
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
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                    color: isMinimal ? theme.primaryColor : theme.slateColor,
                    letterSpacing: 1,
                  ),
                ),
                pw.SizedBox(height: 5),
                pw.Text(
                  profile.businessName,
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                    color: theme.darkColor,
                  ),
                ),
                if (profile.address != null && profile.address!.trim().isNotEmpty) ...[
                  pw.SizedBox(height: 2),
                  pw.Text(
                    profile.address!,
                    style: pw.TextStyle(fontSize: 8.5, color: theme.slateColor),
                  ),
                ],
                if (profile.phone != null && profile.phone!.trim().isNotEmpty) ...[
                  pw.SizedBox(height: 2),
                  pw.Text(
                    profile.phone!,
                    style: pw.TextStyle(fontSize: 8.5, color: theme.slateColor),
                  ),
                ],
                if (profile.email != null && profile.email!.trim().isNotEmpty) ...[
                  pw.SizedBox(height: 2),
                  pw.Text(
                    profile.email!,
                    style: pw.TextStyle(fontSize: 8.5, color: theme.slateColor),
                  ),
                ],
                if (profile.gstin != null && profile.gstin!.trim().isNotEmpty) ...[
                  pw.SizedBox(height: 2),
                  pw.Text(
                    '${profile.taxIdLabel}: ${profile.gstin}',
                    style: pw.TextStyle(fontSize: 8, color: theme.slateColor),
                  ),
                ],
              ],
            ),
          ),
        ),
        pw.SizedBox(width: 12),
        // Bill To
        pw.Expanded(
          child: pw.Container(
            padding: const pw.EdgeInsets.all(10),
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
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                    color: isMinimal ? theme.primaryColor : theme.slateColor,
                    letterSpacing: 1,
                  ),
                ),
                pw.SizedBox(height: 5),
                pw.Text(
                  invoice.clientName,
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                    color: theme.darkColor,
                  ),
                ),
                if (invoice.clientAddress != null && invoice.clientAddress!.trim().isNotEmpty) ...[
                  pw.SizedBox(height: 2),
                  pw.Text(
                    invoice.clientAddress!,
                    style: pw.TextStyle(fontSize: 8.5, color: theme.slateColor),
                  ),
                ],
                if (invoice.clientPhone != null && invoice.clientPhone!.trim().isNotEmpty) ...[
                  pw.SizedBox(height: 2),
                  pw.Text(
                    invoice.clientPhone!,
                    style: pw.TextStyle(fontSize: 8.5, color: theme.slateColor),
                  ),
                ],
                if (invoice.clientEmail != null && invoice.clientEmail!.trim().isNotEmpty) ...[
                  pw.SizedBox(height: 2),
                  pw.Text(
                    invoice.clientEmail!,
                    style: pw.TextStyle(fontSize: 8.5, color: theme.slateColor),
                  ),
                ],
                if (invoice.clientGstin != null && invoice.clientGstin!.trim().isNotEmpty) ...[
                  pw.SizedBox(height: 2),
                  pw.Text(
                    '${profile.taxIdLabel}: ${invoice.clientGstin}',
                    style: pw.TextStyle(fontSize: 8, color: theme.slateColor),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildLineItemsTable(
    InvoiceModel invoice,
    BusinessProfile profile,
    String currencySymbol,
    PdfTheme theme,
  ) {
    final decimals = profile.decimalPlaces;
    final isMinimal = theme.paperStyle == PdfPaperStyle.minimalDividers;

    final headerTextStyle = pw.TextStyle(
      color: theme.tableHeaderTextColor,
      fontSize: 8.5,
      fontWeight: pw.FontWeight.bold,
      letterSpacing: isMinimal ? 0.5 : 0,
    );

    return pw.Table(
      border: isMinimal
          ? pw.TableBorder(
              top: pw.BorderSide(color: theme.primaryColor, width: 1.2),
              bottom: pw.BorderSide(color: theme.borderColor, width: 1),
              horizontalInside: pw.BorderSide(color: theme.borderColor, width: 0.5),
            )
          : pw.TableBorder.all(color: theme.borderColor, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(4.5),
        1: const pw.FlexColumnWidth(1.4),
        2: const pw.FlexColumnWidth(2.0),
        3: const pw.FlexColumnWidth(2.1),
      },
      children: [
        // Header row
        pw.TableRow(
          decoration: pw.BoxDecoration(color: theme.tableHeaderBg),
          children: [
            _tableCell('DESCRIPTION', style: headerTextStyle, isHeader: true),
            _tableCell(
              'QTY',
              style: headerTextStyle,
              isHeader: true,
              align: pw.Alignment.centerRight,
            ),
            _tableCell(
              'UNIT PRICE',
              style: headerTextStyle,
              isHeader: true,
              align: pw.Alignment.centerRight,
            ),
            _tableCell(
              'TOTAL',
              style: headerTextStyle,
              isHeader: true,
              align: pw.Alignment.centerRight,
            ),
          ],
        ),
        // Item rows
        ...invoice.lineItems.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final isAlt = index % 2 == 1;
          final rowBg = isAlt ? theme.lightGray : PdfColors.white;
          final rowStyle = pw.TextStyle(fontSize: 9, color: theme.darkColor);
          final rowStyleSecondary = pw.TextStyle(
            fontSize: 9,
            color: theme.slateColor,
          );

          return pw.TableRow(
            decoration: pw.BoxDecoration(color: rowBg),
            children: [
              _tableCell(item.description, style: rowStyle),
              _tableCell(
                item.quantity % 1 == 0
                    ? item.quantity.toInt().toString()
                    : item.quantity.toStringAsFixed(2),
                style: rowStyleSecondary,
                align: pw.Alignment.centerRight,
              ),
              _tableCell(
                '$currencySymbol${item.unitPrice.toStringAsFixed(decimals)}',
                style: rowStyleSecondary,
                align: pw.Alignment.centerRight,
              ),
              _tableCell(
                '$currencySymbol${item.total.toStringAsFixed(decimals)}',
                style: rowStyle,
                align: pw.Alignment.centerRight,
              ),
            ],
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
  }) {
    return pw.Container(
      padding: pw.EdgeInsets.symmetric(
        horizontal: 9,
        vertical: isHeader ? 7 : 6,
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
  ) {
    final decimals = profile.decimalPlaces;
    final isDual = profile.isDualTax;
    final taxShortName = profile.taxShortName;

    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.end,
      children: [
        pw.Container(
          width: 240,
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: theme.borderColor, width: 0.8),
            borderRadius: pw.BorderRadius.circular(6),
          ),
          child: pw.Column(
            children: [
              _buildTotalRow(
                'Subtotal',
                '$currencySymbol${invoice.subtotal.toStringAsFixed(decimals)}',
                theme,
              ),
              if (invoice.discountType != DiscountType.none &&
                  invoice.discountAmount > 0) ...[
                pw.Divider(color: theme.borderColor, height: 1, thickness: 0.5),
                _buildTotalRow(
                  invoice.discountType == DiscountType.percentage
                      ? 'Discount (${invoice.discountValue.toStringAsFixed(0)}%)'
                      : 'Discount',
                  '-$currencySymbol${invoice.discountAmount.toStringAsFixed(decimals)}',
                  theme,
                  valueColor: theme.paperStyle == PdfPaperStyle.minimalDividers
                      ? theme.darkColor
                      : theme.accentColor,
                ),
              ],
              if (isDual) ...[
                if (invoice.sgstRate > 0) ...[
                  pw.Divider(color: theme.borderColor, height: 1, thickness: 0.5),
                  _buildTotalRow(
                    'SGST (${invoice.sgstRate.toStringAsFixed(invoice.sgstRate % 1 == 0 ? 0 : 1)}%)',
                    '$currencySymbol${(invoice.subtotal * invoice.sgstRate / 100).toStringAsFixed(decimals)}',
                    theme,
                  ),
                ],
                if (invoice.cgstRate > 0) ...[
                  pw.Divider(color: theme.borderColor, height: 1, thickness: 0.5),
                  _buildTotalRow(
                    'CGST (${invoice.cgstRate.toStringAsFixed(invoice.cgstRate % 1 == 0 ? 0 : 1)}%)',
                    '$currencySymbol${(invoice.subtotal * invoice.cgstRate / 100).toStringAsFixed(decimals)}',
                    theme,
                  ),
                ],
                if (invoice.igstRate > 0) ...[
                  pw.Divider(color: theme.borderColor, height: 1, thickness: 0.5),
                  _buildTotalRow(
                    'IGST (${invoice.igstRate.toStringAsFixed(invoice.igstRate % 1 == 0 ? 0 : 1)}%)',
                    '$currencySymbol${(invoice.subtotal * invoice.igstRate / 100).toStringAsFixed(decimals)}',
                    theme,
                  ),
                ],
              ] else ...[
                if (invoice.taxAmount > 0 ||
                    invoice.igstRate > 0 ||
                    (invoice.sgstRate + invoice.cgstRate) > 0) ...[
                  pw.Divider(color: theme.borderColor, height: 1, thickness: 0.5),
                  _buildTotalRow(
                    () {
                      final rate = invoice.igstRate > 0
                          ? invoice.igstRate
                          : (invoice.sgstRate + invoice.cgstRate);
                      return rate > 0
                          ? '$taxShortName (${rate.toStringAsFixed(rate % 1 == 0 ? 0 : 1)}%)'
                          : taxShortName;
                    }(),
                    '$currencySymbol${invoice.taxAmount.toStringAsFixed(decimals)}',
                    theme,
                  ),
                ],
              ],
              pw.Container(
                decoration: pw.BoxDecoration(
                  color: theme.primaryColor,
                  borderRadius: const pw.BorderRadius.only(
                    bottomLeft: pw.Radius.circular(5),
                    bottomRight: pw.Radius.circular(5),
                  ),
                ),
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 9,
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'GRAND TOTAL',
                      style: pw.TextStyle(
                        fontSize: 10.5,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    pw.Text(
                      '$currencySymbol${invoice.grandTotal.toStringAsFixed(decimals)}',
                      style: pw.TextStyle(
                        fontSize: 12.5,
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
  }

  static pw.Widget _buildTotalRow(
    String label,
    String value,
    PdfTheme theme, {
    PdfColor? valueColor,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: 8.5, color: theme.slateColor)),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 8.5,
              fontWeight: pw.FontWeight.bold,
              color: valueColor ?? theme.darkColor,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildNotesSection(String notes, PdfTheme theme) {
    final isMinimal = theme.paperStyle == PdfPaperStyle.minimalDividers;

    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(10),
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
              fontSize: 7.5,
              fontWeight: pw.FontWeight.bold,
              color: theme.slateColor,
              letterSpacing: 1,
            ),
          ),
          pw.SizedBox(height: 3),
          pw.Text(notes, style: pw.TextStyle(fontSize: 8.5, color: theme.slateColor)),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter(
    BusinessProfile profile,
    bool isPro,
    pw.MemoryImage? signatureImage,
    PdfTheme theme,
    bool isSamplePreview,
  ) {
    return pw.Column(
      children: [
        if (profile.bankName != null || profile.accountNumber != null) ...[
          pw.Divider(color: theme.borderColor, thickness: 0.8),
          pw.SizedBox(height: 6),
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
                        fontSize: 8,
                        fontWeight: pw.FontWeight.bold,
                        color: theme.slateColor,
                        letterSpacing: 1,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    if (profile.bankName != null && profile.bankName!.trim().isNotEmpty)
                      pw.Text(
                        'Bank: ${profile.bankName}',
                        style: pw.TextStyle(fontSize: 8.5, color: theme.slateColor),
                      ),
                    if (profile.accountNumber != null && profile.accountNumber!.trim().isNotEmpty)
                      pw.Text(
                        '${profile.bankAccountLabel}: ${profile.accountNumber}',
                        style: pw.TextStyle(fontSize: 8.5, color: theme.slateColor),
                      ),
                    if (profile.ifscCode != null && profile.ifscCode!.trim().isNotEmpty)
                      pw.Text(
                        '${profile.bankRoutingLabel}: ${profile.ifscCode}',
                        style: pw.TextStyle(fontSize: 8.5, color: theme.slateColor),
                      ),
                  ],
                ),
              ),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    if (signatureImage != null)
                      pw.Container(
                        height: 40,
                        width: 85,
                        alignment: pw.Alignment.centerRight,
                        child: pw.Image(signatureImage, fit: pw.BoxFit.contain),
                      )
                    else
                      DummyInvoiceData.buildVectorSignature(theme),
                    pw.SizedBox(height: 6),
                    pw.Text(
                      'Thank you for your business!',
                      style: pw.TextStyle(
                        fontSize: 10,
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
          pw.SizedBox(height: 6),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              if (signatureImage != null)
                pw.Container(
                  height: 40,
                  width: 85,
                  child: pw.Image(signatureImage, fit: pw.BoxFit.contain),
                )
              else
                DummyInvoiceData.buildVectorSignature(theme),
            ],
          ),
          pw.SizedBox(height: 6),
          pw.Center(
            child: pw.Text(
              'Thank you for your business!',
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: theme.primaryColor,
              ),
            ),
          ),
        ],
        if (!isPro) ...[
          pw.SizedBox(height: 8),
          pw.Center(
            child: pw.Text(
              'Generated by Invoice Maker Pro',
              style: pw.TextStyle(
                fontSize: 7.5,
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

  static Future<_PdfFonts> _loadFonts() {
    return _fontsFuture ??= _PdfFonts.load();
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

  static Future<_PdfFonts> load() async {
    final base = await _loadFont('assets/fonts/NotoSans-Regular.ttf');
    final bold = await _loadFont('assets/fonts/NotoSans-Bold.ttf');
    final arabic = await _loadFont('assets/fonts/NotoSansArabic-Regular.ttf');
    final bengali = await _loadFont('assets/fonts/NotoSansBengali-Regular.ttf');
    final thai = await _loadFont('assets/fonts/NotoSansThai-Regular.ttf');

    return _PdfFonts(base: base, bold: bold, fallback: [arabic, bengali, thai]);
  }

  static Future<pw.Font> _loadFont(String assetPath) async {
    final fontData = await rootBundle.load(assetPath);
    return pw.Font.ttf(fontData);
  }
}
