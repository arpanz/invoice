import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../core/utils/amount_in_words.dart';
import '../../core/utils/currency_formatter.dart';
import '../invoices/models/invoice_customization_config.dart';
import '../invoices/models/invoice_model.dart';
import '../invoices/models/payment_model.dart';
import '../invoices/services/invoice_render_service.dart';
import '../invoices/services/pdf_generator_service.dart';

class PaymentReceipt {
  final InvoiceModel invoice;
  final String number;
  final DateTime date;
  final double amount;
  final double totalPaid;
  final String? method;
  final String? note;

  const PaymentReceipt._({
    required this.invoice,
    required this.number,
    required this.date,
    required this.amount,
    required this.totalPaid,
    this.method,
    this.note,
  });

  double get balance =>
      (invoice.grandTotal - totalPaid).clamp(0, double.infinity);

  /// Six upper-case characters taken from a payment id.
  static String receiptSuffix(String paymentId) {
    final clean = paymentId.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').toUpperCase();
    return clean.length <= 6 ? clean : clean.substring(0, 6);
  }

  /// With no payment, summarizes all recorded payments (suffix ALL).
  factory PaymentReceipt.fromPayments(
    InvoiceModel invoice,
    List<PaymentModel> payments, {
    PaymentModel? payment,
  }) {
    final byDate = [...payments]
      ..sort((a, b) {
        final date = a.paidOn.compareTo(b.paidOn);
        return date == 0 ? _compareRecorded(a, b) : date;
      });
    if (byDate.isEmpty) throw ArgumentError('A receipt requires a payment');

    // The suffix comes from the payment's own id, so a receipt keeps its
    // number even if another payment on the invoice is deleted later.
    var suffix = 'ALL';
    var through = byDate.length;
    if (payment != null) {
      if (!payments.any((entry) => entry.id == payment.id)) {
        throw ArgumentError('The payment is missing from the invoice history');
      }
      suffix = receiptSuffix(payment.id);
      through = byDate.indexWhere((entry) => entry.id == payment.id) + 1;
    }
    final total = byDate
        .take(through)
        .fold(0.0, (sum, entry) => sum + entry.amount);
    return PaymentReceipt._(
      invoice: invoice,
      number: 'RCT-${invoice.invoiceNumber}-$suffix',
      date: payment?.paidOn ?? byDate.last.paidOn,
      amount: payment?.amount ?? total,
      totalPaid: total,
      method: payment == null
          ? (byDate.length == 1 ? byDate.single.method : 'Multiple payments')
          : payment.method,
      note: payment?.note,
    );
  }

  static int _compareRecorded(PaymentModel a, PaymentModel b) {
    final time = a.createdAt.compareTo(b.createdAt);
    return time == 0 ? a.id.compareTo(b.id) : time;
  }
}

class ReceiptPdfService {
  ReceiptPdfService._();

  static Future<Uint8List> generate(
    PaymentReceipt receipt, {
    required bool isPro,
    InvoiceCustomizationConfig? design,
  }) async {
    final invoice = receipt.invoice;
    final profile = await InvoiceRenderService.profileFor(invoice);
    final config =
        design ?? await InvoiceRenderService.designForInvoice(invoice.id);
    final theme = config.toPdfTheme();
    final accent = theme.primaryColor;
    final logo = await PdfGeneratorService.loadImage(profile.logoPath);
    final signature = config.showSignature
        ? await PdfGeneratorService.loadImage(profile.signaturePath)
        : null;
    final contact = [
      if (profile.address case final address? when address.isNotEmpty) address,
      [
        profile.phone,
        profile.email,
      ].whereType<String>().where((value) => value.isNotEmpty).join(' · '),
    ].where((value) => value.isNotEmpty).join('\n');
    final words = AmountInWords.format(
      receipt.amount,
      invoice.currency.toUpperCase(),
    );
    final pageFonts = await PdfGeneratorService.documentFonts(
      config,
      [
        profile.businessName,
        contact,
        invoice.clientName,
        invoice.invoiceNumber,
        receipt.method ?? '',
        receipt.note ?? '',
      ].join('\n'),
    );

    String money(double amount) =>
        CurrencyFormatter.format(amount, currencyCode: invoice.currency);
    final label = pw.TextStyle(fontSize: 10, color: theme.slateColor);
    final value = pw.TextStyle(
      fontSize: 11,
      color: theme.darkColor,
      fontWeight: pw.FontWeight.bold,
    );
    final pdf = pw.Document(
      title: 'Payment Receipt ${receipt.number}',
      author: profile.businessName,
    );
    const pageFormat = PdfPageFormat.a4;
    const margin = 48.0;

    pw.Widget row(String name, String content) => pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 5),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(width: 135, child: pw.Text(name, style: label)),
          pw.Expanded(child: pw.Text(content, style: value)),
        ],
      ),
    );

    pdf.addPage(
      pw.Page(
        pageFormat: pageFormat,
        margin: const pw.EdgeInsets.all(margin),
        theme: pageFonts,
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            pw.Expanded(
              child: pw.FittedBox(
                fit: pw.BoxFit.scaleDown,
                alignment: pw.Alignment.topLeft,
                child: pw.SizedBox(
                  width: pageFormat.width - margin * 2,
                  child: pw.Column(
                    mainAxisSize: pw.MainAxisSize.min,
                    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                    children: [
                      pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          if (logo != null) ...[
                            pw.Image(
                              logo,
                              width: 60,
                              height: 50,
                              fit: pw.BoxFit.contain,
                            ),
                            pw.SizedBox(width: 14),
                          ],
                          pw.Expanded(
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text(
                                  profile.businessName,
                                  style: value.copyWith(fontSize: 17),
                                ),
                                if (contact.isNotEmpty)
                                  pw.Text(contact, style: label),
                              ],
                            ),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 20),
                      pw.Divider(color: accent, thickness: 2),
                      pw.SizedBox(height: 14),
                      pw.Text(
                        'Payment Receipt',
                        style: value.copyWith(color: accent, fontSize: 28),
                      ),
                      pw.Text(receipt.number, style: label),
                      pw.SizedBox(height: 20),
                      row(
                        'Date received',
                        DateFormat('dd MMM yyyy').format(receipt.date),
                      ),
                      row('Received from', invoice.clientName),
                      row('Method', receipt.method ?? '—'),
                      if (receipt.note case final note? when note.isNotEmpty)
                        row('Note', note),
                      pw.SizedBox(height: 16),
                      pw.Text('Amount received', style: label),
                      pw.Text(
                        money(receipt.amount),
                        style: value.copyWith(color: accent, fontSize: 24),
                      ),
                      if (words != null) pw.Text(words, style: label),
                      pw.SizedBox(height: 16),
                      pw.Divider(color: theme.lightGray),
                      row('Invoice number', invoice.invoiceNumber),
                      row('Invoice total', money(invoice.grandTotal)),
                      row('Total paid to date', money(receipt.totalPaid)),
                      row('Balance remaining', money(receipt.balance)),
                      if (config.showSignature) ...[
                        pw.SizedBox(height: 24),
                        pw.Align(
                          alignment: pw.Alignment.centerRight,
                          child: pw.Column(
                            children: [
                              pw.SizedBox(
                                width: 130,
                                height: 45,
                                child: signature == null
                                    ? null
                                    : pw.Image(
                                        signature,
                                        fit: pw.BoxFit.contain,
                                      ),
                              ),
                              pw.SizedBox(
                                width: 130,
                                child: pw.Divider(color: theme.slateColor),
                              ),
                              pw.Text('Authorized signature', style: label),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            if (!isPro)
              pw.Text(
                PdfGeneratorService.freePlanCredit,
                style: label.copyWith(fontSize: 7),
              ),
          ],
        ),
      ),
    );
    return pdf.save();
  }
}
