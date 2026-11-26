import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:invoice/features/invoices/models/invoice_customization_config.dart';
import 'package:invoice/features/invoices/models/invoice_model.dart';
import 'package:invoice/features/invoices/models/line_item_model.dart';
import 'package:invoice/features/invoices/models/pdf_theme.dart';
import 'package:invoice/features/invoices/services/pdf_generator_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final now = DateTime(2026, 11, 19);

  InvoiceModel invoice({
    String currency = 'INR',
    double paid = 0,
    InvoiceStatus status = InvoiceStatus.unpaid,
    String number = 'INV#7',
  }) =>
      InvoiceModel(
        id: 'inv-1',
        invoiceNumber: number,
        clientName: 'Client',
        invoiceDate: now,
        dueDate: now.add(const Duration(days: 15)),
        subtotal: 1000,
        grandTotal: 0, // the PDF recomputes it
        paidAmount: paid,
        status: status,
        currency: currency,
        createdAt: now,
        updatedAt: now,
        lineItems: [
          LineItemModel.create(id: 'a', invoiceId: 'inv-1', description: 'Design', quantity: 1, unitPrice: 1000),
        ],
      );

  const profile = BusinessProfile(
    businessName: 'Acme & Sons Studio',
    currency: 'INR',
    upiId: ' acme.studio@okhdfc ',
    bankName: 'State Bank of India, Koramangala Industrial Layout Branch',
    accountNumber: '12345678901234',
    ifscCode: 'SBIN0001234',
  );
  const config = InvoiceCustomizationConfig();

  group('upiPayUri', () {
    test('encodes every value and prints the amount to 2dp', () {
      final uri = PdfGeneratorService.upiPayUri(
        upiId: 'acme@okhdfc',
        businessName: 'Acme & Sons Studio',
        amount: 1234.5,
        invoiceNumber: 'INV#7',
      );
      expect(
        uri,
        'upi://pay?pa=acme%40okhdfc&pn=Acme%20%26%20Sons%20Studio&am=1234.50&cu=INR&tn=Invoice%20INV%237',
      );
      expect(uri.contains('+'), isFalse);
    });

    test('leaves out the payee name when there is none', () {
      final uri = PdfGeneratorService.upiPayUri(
        upiId: 'acme@okhdfc',
        businessName: '  ',
        amount: 10,
        invoiceNumber: 'A1',
      );
      expect(uri, 'upi://pay?pa=acme%40okhdfc&am=10.00&cu=INR&tn=Invoice%20A1');
    });
  });

  group('upiQrData', () {
    String? data(InvoiceModel inv, {BusinessProfile p = profile, InvoiceCustomizationConfig c = config, double balance = 500}) =>
        PdfGeneratorService.upiQrData(invoice: inv, profile: p, config: c, balance: balance);

    test('an unpaid rupee invoice with a valid UPI ID gets a link', () {
      expect(data(invoice()), startsWith('upi://pay?pa=acme.studio%40okhdfc&'));
      expect(data(invoice()), contains('am=500.00'));
    });

    test('a non-rupee invoice gets none, even on an INR profile', () {
      expect(data(invoice(currency: 'USD')), isNull);
    });

    test('an estimate gets none', () {
      expect(data(invoice(), p: profile.copyWith(invoiceTitleOverride: 'ESTIMATE')), isNull);
    });

    test('a settled invoice gets none', () {
      expect(data(invoice(paid: 1000), balance: 0), isNull);
      expect(data(invoice(status: InvoiceStatus.paid)), isNull);
      expect(data(invoice(), balance: 0.004), isNull);
    });

    test('a malformed UPI ID gets none', () {
      for (final id in ['', 'acme', 'a@b', 'acme@1bank', 'ac me@okhdfc', 'acme@ok@hdfc', 'acme@okhdfc&am=1', 'me@gmail.com', 'pay@ok-hdfc']) {
        expect(data(invoice(), p: profile.copyWith(upiId: id)), isNull, reason: id);
      }
    });

    test('hiding UPI details hides the QR', () {
      expect(data(invoice(), c: config.copyWith(showUpiDetails: false)), isNull);
    });
  });

  test('renders an INR invoice with a UPI QR in every theme and density', () async {
    final out = Platform.environment['UPI_QR_PDF_DIR'];
    // Same text length, but the bank part starts with a digit, so the gate
    // drops the QR while the UPI row still prints. Any size gap between the
    // two renders is the QR itself.
    final noQrProfile = profile.copyWith(upiId: ' acme.studio@1khdfc ');
    final inv = invoice(paid: 200, status: InvoiceStatus.partiallyPaid);
    for (final theme in PdfTheme.all) {
      for (final density in InvoiceDensity.values) {
        for (final signature in [true, false]) {
          final cfg = InvoiceCustomizationConfig.fromTheme(theme).copyWith(density: density, showSignature: signature);
          final label = '${theme.id.name} ${density.name} ${signature ? 'sig' : 'nosig'}';
          // The PDF recomputes the total (1000) and owes 800 of it.
          expect(
            PdfGeneratorService.upiQrData(invoice: inv, profile: profile, config: cfg, balance: 800),
            contains('am=800.00'),
            reason: label,
          );
          Future<List<int>> render(BusinessProfile p) => PdfGeneratorService.generateInvoicePdf(
                invoice: inv,
                businessProfile: p,
                isPro: true,
                isSamplePreview: true,
                customizationConfig: cfg,
              );
          final withQr = await render(profile);
          final withoutQr = await render(noQrProfile);
          expect(withoutQr.length, greaterThan(1000), reason: label);
          expect(withQr.length - withoutQr.length, greaterThan(200), reason: label);
          if (out != null) {
            File('$out/${theme.id.name}_${density.name}_${signature ? 'sig' : 'nosig'}.pdf').writeAsBytesSync(withQr);
          }
        }
      }
    }
  });
}
