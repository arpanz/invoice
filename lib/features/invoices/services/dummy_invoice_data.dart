import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/invoice_model.dart';
import '../models/line_item_model.dart';
import '../models/pdf_theme.dart';
import 'pdf_generator_service.dart';

class DummyInvoiceData {
  DummyInvoiceData._();

  static InvoiceModel get sampleInvoice => InvoiceModel(
        id: 'dummy-sample-inv',
        invoiceNumber: 'INV-2026-0842',
        clientId: 'client-apex-1',
        clientName: 'Nova Digital Ventures LLC',
        clientEmail: 'accounts@novaventures.io',
        clientPhone: '+1 (415) 890-2340',
        clientAddress: '120 Broadway, 22nd Floor, New York, NY 10005',
        clientGstin: 'US-EIN-94820194',
        invoiceDate: DateTime(2026, 8, 15),
        dueDate: DateTime(2026, 8, 29),
        subtotal: 7800.0,
        discountType: DiscountType.percentage,
        discountValue: 10.0,
        discountAmount: 780.0,
        sgstRate: 0,
        cgstRate: 0,
        igstRate: 8.5,
        taxAmount: 596.7,
        grandTotal: 7616.7,
        status: InvoiceStatus.unpaid,
        notes:
            'Payment is due within 14 days of invoice date. Please transfer funds to the bank account specified below. Thank you for your partnership!',
        currency: 'USD',
        createdAt: DateTime(2026, 8, 15),
        updatedAt: DateTime(2026, 8, 15),
        lineItems: const [
          LineItemModel(
            id: 'dli-1',
            invoiceId: 'dummy-sample-inv',
            description: 'Enterprise Cloud Architecture & Security Audit',
            quantity: 1,
            unitPrice: 3200.0,
            total: 3200.0,
            sortOrder: 0,
          ),
          LineItemModel(
            id: 'dli-2',
            invoiceId: 'dummy-sample-inv',
            description: 'Full-Stack Flutter Mobile App Core Modules',
            quantity: 30,
            unitPrice: 120.0,
            total: 3600.0,
            sortOrder: 1,
          ),
          LineItemModel(
            id: 'dli-3',
            invoiceId: 'dummy-sample-inv',
            description: 'Automated CI/CD Pipeline & Automated Testing Suite',
            quantity: 1,
            unitPrice: 1000.0,
            total: 1000.0,
            sortOrder: 2,
          ),
        ],
      );

  static const BusinessProfile sampleProfile = BusinessProfile(
    businessName: 'Apex Global Technologies Inc.',
    address: '452 Innovation Blvd, Suite 800, San Francisco, CA 94107',
    phone: '+1 (555) 234-5678',
    email: 'billing@apextechnologies.io',
    gstin: 'US-EIN-88492019',
    bankName: 'Silicon Valley Commerce Bank',
    accountNumber: '9482 1049 8832',
    ifscCode: 'SVCB-US-33',
    currency: 'USD',
  );

  static InvoiceModel getSampleInvoice([String? currency]) {
    if (currency == null || currency.isEmpty) return sampleInvoice;
    return sampleInvoice.copyWith(currency: currency);
  }

  static BusinessProfile getSampleProfile([String? currency]) {
    if (currency == null || currency.isEmpty) return sampleProfile;
    return sampleProfile.copyWith(currency: currency);
  }

  /// Draws a clean, high-resolution vector corporate logo badge
  static pw.Widget buildVectorLogo(PdfTheme theme, {double size = 48}) {
    return pw.Container(
      width: size * 2.5,
      height: size,
      child: pw.Row(
        children: [
          pw.Container(
            width: size,
            height: size,
            decoration: pw.BoxDecoration(
              color: theme.primaryColor,
              borderRadius: pw.BorderRadius.circular(8),
              boxShadow: [
                pw.BoxShadow(
                  color: PdfColor.fromHex('#000000'),
                  offset: const PdfPoint(0, 1),
                  blurRadius: 3,
                ),
              ],
            ),
            child: pw.Center(
              child: pw.Text(
                'AP',
                style: pw.TextStyle(
                  color: PdfColors.white,
                  fontSize: size * 0.42,
                  fontWeight: pw.FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
          pw.SizedBox(width: 8),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              pw.Text(
                'APEX',
                style: pw.TextStyle(
                  color: theme.darkColor,
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              pw.Text(
                'GLOBAL TECH',
                style: pw.TextStyle(
                  color: theme.slateColor,
                  fontSize: 7.5,
                  fontWeight: pw.FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Draws an authentic calligraphic vector digital signature
  static pw.Widget buildVectorSignature(PdfTheme theme) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Container(
          width: 120,
          height: 38,
          child: pw.CustomPaint(
            painter: (PdfGraphics canvas, PdfPoint size) {
              canvas
                ..setStrokeColor(theme.primaryColor)
                ..setLineWidth(1.4)
                ..moveTo(10, 14)
                ..curveTo(25, 32, 35, 35, 45, 18)
                ..curveTo(52, 6, 40, 4, 38, 16)
                ..curveTo(36, 28, 60, 32, 75, 15)
                ..curveTo(85, 4, 70, 8, 88, 22)
                ..curveTo(96, 30, 108, 12, 115, 18)
                ..strokePath()
                // Underline flourish
                ..setStrokeColor(theme.slateColor)
                ..setLineWidth(0.8)
                ..moveTo(15, 8)
                ..curveTo(50, 4, 85, 10, 118, 7)
                ..strokePath();
            },
          ),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          'Alexander Wright',
          style: pw.TextStyle(
            fontSize: 9,
            fontWeight: pw.FontWeight.bold,
            color: theme.darkColor,
          ),
        ),
        pw.Text(
          'Authorized Officer • Apex Global',
          style: pw.TextStyle(
            fontSize: 7.5,
            color: theme.slateColor,
          ),
        ),
      ],
    );
  }
}
