import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/invoice_model.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/pdf_helper.dart';

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
  final String currency;

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
    this.currency = 'INR',
  });
}

class PdfGeneratorService {
  PdfGeneratorService._();

  static final PdfColor _primaryColor = PdfColor.fromHex('#2563EB');
  static final PdfColor _darkColor = PdfColor.fromHex('#0F172A');
  static final PdfColor _slateColor = PdfColor.fromHex('#64748B');
  static final PdfColor _lightGray = PdfColor.fromHex('#F1F5F9');
  static final PdfColor _borderColor = PdfColor.fromHex('#E2E8F0');
  static final PdfColor _tableHeaderBg = PdfColor.fromHex('#1E293B');
  static final PdfColor _accentGreen = PdfColor.fromHex('#10B981');

  static Future<Uint8List> generateInvoicePdf({
    required InvoiceModel invoice,
    required BusinessProfile businessProfile,
    required bool isPro,
  }) async {
    final pdf = pw.Document(
      title: 'Invoice ${invoice.invoiceNumber}',
      author: businessProfile.businessName,
    );

    pw.MemoryImage? logoImage;
    if (isPro && businessProfile.logoPath != null) {
      try {
        final logoFile = File(businessProfile.logoPath!);
        if (await logoFile.exists()) {
          final bytes = await logoFile.readAsBytes();
          logoImage = pw.MemoryImage(bytes);
        }
      } catch (_) {}
    }

    final currencySymbol = CurrencyFormatter.getCurrencySymbol(businessProfile.currency);
    final dateFormat = DateFormat('dd MMM yyyy');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          _buildHeader(invoice, businessProfile, logoImage, dateFormat),
          pw.SizedBox(height: 32),
          _buildAddressSection(invoice, businessProfile),
          pw.SizedBox(height: 32),
          _buildLineItemsTable(invoice, currencySymbol),
          pw.SizedBox(height: 24),
          _buildTotalsSection(invoice, currencySymbol),
          if (invoice.notes != null && invoice.notes!.isNotEmpty) ...[
            pw.SizedBox(height: 24),
            _buildNotesSection(invoice.notes!),
          ],
          pw.SizedBox(height: 32),
          _buildFooter(businessProfile, isPro),
        ],
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildHeader(
    InvoiceModel invoice,
    BusinessProfile profile,
    pw.MemoryImage? logo,
    DateFormat dateFormat,
  ) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Left: Logo + Business Name
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            if (logo != null)
              pw.Container(
                height: 60,
                width: 120,
                child: pw.Image(logo, fit: pw.BoxFit.contain),
              )
            else
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: pw.BoxDecoration(
                  color: _primaryColor,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Text(
                  profile.businessName.substring(0, profile.businessName.length > 2 ? 2 : profile.businessName.length).toUpperCase(),
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
            pw.SizedBox(height: 8),
            pw.Text(
              profile.businessName,
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
                color: _darkColor,
              ),
            ),
          ],
        ),
        // Right: INVOICE label + details
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(
              'INVOICE',
              style: pw.TextStyle(
                fontSize: 32,
                fontWeight: pw.FontWeight.bold,
                color: _primaryColor,
                letterSpacing: 2,
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: _lightGray,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  _buildInfoRow('Invoice #', invoice.invoiceNumber),
                  pw.SizedBox(height: 4),
                  _buildInfoRow('Date', dateFormat.format(invoice.invoiceDate)),
                  if (invoice.dueDate != null) ...[
                    pw.SizedBox(height: 4),
                    _buildInfoRow('Due Date', dateFormat.format(invoice.dueDate!)),
                  ],
                  pw.SizedBox(height: 4),
                  _buildStatusBadge(invoice.status),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildInfoRow(String label, String value) {
    return pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Text(
          '$label ',
          style: pw.TextStyle(fontSize: 10, color: _slateColor),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 10,
            fontWeight: pw.FontWeight.bold,
            color: _darkColor,
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildStatusBadge(InvoiceStatus status) {
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
        bgColor = PdfColor.fromHex('#FEF3C7');
        textColor = PdfColor.fromHex('#92400E');
        label = 'UNPAID';
    }

    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: pw.BoxDecoration(
        color: bgColor,
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Text(
        label,
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: pw.FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }

  static pw.Widget _buildAddressSection(InvoiceModel invoice, BusinessProfile profile) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // From
        pw.Expanded(
          child: pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: _borderColor),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'FROM',
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                    color: _slateColor,
                    letterSpacing: 1,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  profile.businessName,
                  style: pw.TextStyle(
                    fontSize: 13,
                    fontWeight: pw.FontWeight.bold,
                    color: _darkColor,
                  ),
                ),
                if (profile.address != null) ...[
                  pw.SizedBox(height: 4),
                  pw.Text(profile.address!, style: pw.TextStyle(fontSize: 10, color: _slateColor)),
                ],
                if (profile.phone != null) ...[
                  pw.SizedBox(height: 2),
                  pw.Text(profile.phone!, style: pw.TextStyle(fontSize: 10, color: _slateColor)),
                ],
                if (profile.email != null) ...[
                  pw.SizedBox(height: 2),
                  pw.Text(profile.email!, style: pw.TextStyle(fontSize: 10, color: _slateColor)),
                ],
                if (profile.gstin != null) ...[
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'GSTIN: ${profile.gstin}',
                    style: pw.TextStyle(fontSize: 9, color: _slateColor),
                  ),
                ],
              ],
            ),
          ),
        ),
        pw.SizedBox(width: 16),
        // Bill To
        pw.Expanded(
          child: pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: _lightGray,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'BILL TO',
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                    color: _slateColor,
                    letterSpacing: 1,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  invoice.clientName,
                  style: pw.TextStyle(
                    fontSize: 13,
                    fontWeight: pw.FontWeight.bold,
                    color: _darkColor,
                  ),
                ),
                if (invoice.clientAddress != null) ...[
                  pw.SizedBox(height: 4),
                  pw.Text(invoice.clientAddress!, style: pw.TextStyle(fontSize: 10, color: _slateColor)),
                ],
                if (invoice.clientPhone != null) ...[
                  pw.SizedBox(height: 2),
                  pw.Text(invoice.clientPhone!, style: pw.TextStyle(fontSize: 10, color: _slateColor)),
                ],
                if (invoice.clientEmail != null) ...[
                  pw.SizedBox(height: 2),
                  pw.Text(invoice.clientEmail!, style: pw.TextStyle(fontSize: 10, color: _slateColor)),
                ],
                if (invoice.clientGstin != null) ...[
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'GSTIN: ${invoice.clientGstin}',
                    style: pw.TextStyle(fontSize: 9, color: _slateColor),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildLineItemsTable(InvoiceModel invoice, String currencySymbol) {
    const headerStyle = pw.TextStyle(color: PdfColors.white, fontSize: 10);
    final headerBold = pw.TextStyle(
      color: PdfColors.white,
      fontSize: 10,
      fontWeight: pw.FontWeight.bold,
    );

    return pw.Table(
      border: pw.TableBorder.all(color: _borderColor, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(4),
        1: const pw.FlexColumnWidth(1.5),
        2: const pw.FlexColumnWidth(2),
        3: const pw.FlexColumnWidth(2),
      },
      children: [
        // Header row
        pw.TableRow(
          decoration: pw.BoxDecoration(color: _tableHeaderBg),
          children: [
            _tableCell('DESCRIPTION', style: headerBold, isHeader: true),
            _tableCell('QTY', style: headerBold, isHeader: true, align: pw.Alignment.centerRight),
            _tableCell('UNIT PRICE', style: headerBold, isHeader: true, align: pw.Alignment.centerRight),
            _tableCell('TOTAL', style: headerBold, isHeader: true, align: pw.Alignment.centerRight),
          ],
        ),
        // Item rows
        ...invoice.lineItems.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final isAlt = index % 2 == 1;
          final rowBg = isAlt ? _lightGray : PdfColors.white;
          final rowStyle = pw.TextStyle(fontSize: 10, color: _darkColor);
          final rowStyleSecondary = pw.TextStyle(fontSize: 10, color: _slateColor);

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
                '$currencySymbol${item.unitPrice.toStringAsFixed(2)}',
                style: rowStyleSecondary,
                align: pw.Alignment.centerRight,
              ),
              _tableCell(
                '$currencySymbol${item.total.toStringAsFixed(2)}',
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
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      alignment: align,
      child: pw.Text(text, style: style),
    );
  }

  static pw.Widget _buildTotalsSection(InvoiceModel invoice, String currencySymbol) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.end,
      children: [
        pw.Container(
          width: 260,
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: _borderColor),
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Column(
            children: [
              _buildTotalRow('Subtotal', '$currencySymbol${invoice.subtotal.toStringAsFixed(2)}'),
              if (invoice.discountType != DiscountType.none && invoice.discountAmount > 0) ...[
                pw.Divider(color: _borderColor, height: 1),
                _buildTotalRow(
                  invoice.discountType == DiscountType.percentage
                      ? 'Discount (${invoice.discountValue.toStringAsFixed(0)}%)'
                      : 'Discount',
                  '-$currencySymbol${invoice.discountAmount.toStringAsFixed(2)}',
                  valueColor: _accentGreen,
                ),
              ],
              if (invoice.sgstRate > 0) ...[
                pw.Divider(color: _borderColor, height: 1),
                _buildTotalRow(
                  'SGST (${invoice.sgstRate.toStringAsFixed(0)}%)',
                  '$currencySymbol${(invoice.subtotal * invoice.sgstRate / 100).toStringAsFixed(2)}',
                ),
              ],
              if (invoice.cgstRate > 0) ...[
                pw.Divider(color: _borderColor, height: 1),
                _buildTotalRow(
                  'CGST (${invoice.cgstRate.toStringAsFixed(0)}%)',
                  '$currencySymbol${(invoice.subtotal * invoice.cgstRate / 100).toStringAsFixed(2)}',
                ),
              ],
              if (invoice.igstRate > 0) ...[
                pw.Divider(color: _borderColor, height: 1),
                _buildTotalRow(
                  'IGST (${invoice.igstRate.toStringAsFixed(0)}%)',
                  '$currencySymbol${(invoice.subtotal * invoice.igstRate / 100).toStringAsFixed(2)}',
                ),
              ],
              pw.Container(
                decoration: pw.BoxDecoration(
                  color: _primaryColor,
                  borderRadius: const pw.BorderRadius.only(
                    bottomLeft: pw.Radius.circular(7),
                    bottomRight: pw.Radius.circular(7),
                  ),
                ),
                padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'GRAND TOTAL',
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    pw.Text(
                      '$currencySymbol${invoice.grandTotal.toStringAsFixed(2)}',
                      style: pw.TextStyle(
                        fontSize: 14,
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

  static pw.Widget _buildTotalRow(String label, String value, {PdfColor? valueColor}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: 10, color: _slateColor)),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: valueColor ?? _darkColor,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildNotesSection(String notes) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: _lightGray,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'NOTES',
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
              color: _slateColor,
              letterSpacing: 1,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Text(notes, style: pw.TextStyle(fontSize: 10, color: _slateColor)),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter(BusinessProfile profile, bool isPro) {
    return pw.Column(
      children: [
        if (profile.bankName != null || profile.accountNumber != null) ...[
          pw.Divider(color: _borderColor),
          pw.SizedBox(height: 8),
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
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                        color: _slateColor,
                        letterSpacing: 1,
                      ),
                    ),
                    pw.SizedBox(height: 6),
                    if (profile.bankName != null)
                      pw.Text('Bank: ${profile.bankName}',
                          style: pw.TextStyle(fontSize: 10, color: _slateColor)),
                    if (profile.accountNumber != null)
                      pw.Text('Account: ${profile.accountNumber}',
                          style: pw.TextStyle(fontSize: 10, color: _slateColor)),
                    if (profile.ifscCode != null)
                      pw.Text('IFSC: ${profile.ifscCode}',
                          style: pw.TextStyle(fontSize: 10, color: _slateColor)),
                  ],
                ),
              ),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'Thank you for your business!',
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        color: _primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ] else ...[
          pw.Divider(color: _borderColor),
          pw.SizedBox(height: 8),
          pw.Center(
            child: pw.Text(
              'Thank you for your business!',
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: _primaryColor,
              ),
            ),
          ),
        ],
        if (!isPro) ...[
          pw.SizedBox(height: 12),
          pw.Center(
            child: pw.Text(
              'Generated by Invoice Maker Pro',
              style: pw.TextStyle(
                fontSize: 8,
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
