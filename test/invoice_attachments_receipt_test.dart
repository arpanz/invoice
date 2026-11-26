import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:invoice/features/invoices/models/invoice_customization_config.dart';
import 'package:invoice/features/invoices/models/invoice_model.dart';
import 'package:invoice/features/invoices/models/payment_model.dart';
import 'package:invoice/features/invoices/services/pdf_generator_service.dart';
import 'package:invoice/features/receipts/receipt_pdf_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _date = DateTime(2026, 11, 19);
final _invoice = InvoiceModel(
  id: 'inv-1',
  invoiceNumber: 'INV00001',
  clientName: 'Client',
  invoiceDate: _date,
  subtotal: 100,
  grandTotal: 100,
  createdAt: _date,
  updatedAt: _date,
  issuerSnapshot: jsonEncode({'businessName': 'Acme Studio'}),
);

int _pageCount(Uint8List pdf) =>
    RegExp(r'/Type\s*/Page\b').allMatches(latin1.decode(pdf)).length;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const config = InvoiceCustomizationConfig();

  test('invoice attachments survive model serialization and copying', () {
    final invoice = _invoice.copyWith(
      attachments: ['/photos/one.jpg', '/photos/two.png'],
    );
    final map = invoice.toMap();
    expect(jsonDecode(map['attachments'] as String), invoice.attachments);
    expect(InvoiceModel.fromMap(map).attachments, invoice.attachments);
    expect(
      invoice.copyWith(clientName: 'New').attachments,
      invoice.attachments,
    );
    expect(invoice.copyWith(attachments: []).attachments, isEmpty);
    expect(
      InvoiceModel.fromMap(map..remove('attachments')).attachments,
      isEmpty,
    );
  });

  test(
    'attachment and stamp visibility default on and round-trip when off',
    () {
      expect(config.showAttachments, isTrue);
      expect(config.showStatusStamp, isTrue);
      final hidden = config.copyWith(
        showAttachments: false,
        showStatusStamp: false,
      );
      final parsed = InvoiceCustomizationConfig.tryFromJsonString(
        hidden.toJsonString(),
      )!;
      expect(parsed.showAttachments, isFalse);
      expect(parsed.showStatusStamp, isFalse);
    },
  );

  test('PAID stamp requires the full balance and enabled invoice stamps', () {
    final partlyPaid = _invoice.copyWith(
      paidAmount: 25,
      status: InvoiceStatus.partiallyPaid,
    );
    final fullyPaid = _invoice.copyWith(
      paidAmount: 100,
      status: InvoiceStatus.paid,
    );
    expect(PdfGeneratorService.statusStampFor(_invoice, config), isNull);
    expect(
      PdfGeneratorService.statusStampFor(partlyPaid, config),
      InvoiceStatus.partiallyPaid,
    );
    expect(
      PdfGeneratorService.statusStampFor(
        partlyPaid.copyWith(status: InvoiceStatus.paid),
        config,
      ),
      InvoiceStatus.partiallyPaid,
    );
    expect(
      PdfGeneratorService.statusStampFor(fullyPaid, config),
      InvoiceStatus.paid,
    );
    expect(
      PdfGeneratorService.statusStampFor(fullyPaid, config, isEstimate: true),
      isNull,
    );
    expect(
      PdfGeneratorService.statusStampFor(
        fullyPaid,
        config.copyWith(showStatusStamp: false),
      ),
      isNull,
    );
  });

  test(
    'invoice PDF adds up to two photos per appendix page and skips missing photos',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'invoice_pdf_test',
      );
      addTearDown(() => directory.delete(recursive: true));
      final image = File('${directory.path}/photo.png');
      await image.writeAsBytes(
        base64Decode(
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAIAAACQd1PeAAAADElEQVR4nGP4z8AAAAMBAQDJ/pLvAAAAAElFTkSuQmCC',
        ),
      );
      final corrupt = await File(
        '${directory.path}/corrupt.png',
      ).writeAsBytes([1, 2, 3]);
      final invoice = _invoice.copyWith(
        attachments: [
          image.path,
          '${directory.path}/missing.png',
          corrupt.path,
          image.path,
          image.path,
        ],
      );

      Future<Uint8List> render(InvoiceCustomizationConfig design) =>
          PdfGeneratorService.generateInvoicePdf(
            invoice: invoice,
            businessProfile: const BusinessProfile(businessName: 'Acme Studio'),
            isPro: false,
            customizationConfig: design,
          );

      expect(_pageCount(await render(config)), 3);
      expect(
        _pageCount(await render(config.copyWith(showAttachments: false))),
        1,
      );
    },
  );

  test(
    'single-payment and total receipts render one page with the correct amounts',
    () async {
      SharedPreferences.setMockInitialValues({});
      final first = PaymentModel(
        id: 'first',
        invoiceId: _invoice.id,
        amount: 35,
        paidOn: _date,
        createdAt: _date,
        method: 'UPI',
        note: 'Deposit',
      );
      final second = PaymentModel(
        id: 'second',
        invoiceId: _invoice.id,
        amount: 80,
        paidOn: _date.add(const Duration(days: 1)),
        createdAt: _date.add(const Duration(days: 1)),
      );
      final payments = [second, first];
      final individual = PaymentReceipt.fromPayments(
        _invoice,
        payments,
        payment: first,
      );
      expect(individual.number, 'RCT-INV00001-FIRST');
      expect(individual.amount, 35);
      expect(individual.totalPaid, 35);
      expect(individual.balance, 65);

      final total = PaymentReceipt.fromPayments(_invoice, payments);
      expect(total.number, 'RCT-INV00001-ALL');
      expect(total.amount, 115);
      expect(total.totalPaid, 115);
      expect(total.balance, 0);

      for (final receipt in [individual, total]) {
        final pdf = await ReceiptPdfService.generate(receipt, isPro: false);
        expect(pdf.length, greaterThan(1000));
        expect(_pageCount(pdf), 1);
      }
    },
  );
}
