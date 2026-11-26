import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:invoice/features/estimates/models/estimate_model.dart';
import 'package:invoice/features/invoices/models/document_custom_field.dart';
import 'package:invoice/features/invoices/models/pdf_theme.dart';
import 'package:invoice/features/invoices/models/invoice_customization_config.dart';
import 'package:invoice/features/invoices/models/invoice_model.dart';
import 'package:invoice/features/invoices/models/line_item_model.dart';
import 'package:invoice/features/invoices/services/pdf_generator_service.dart';

int _pageCount(Uint8List bytes) =>
    RegExp(r'/Type\s*/Page\b').allMatches(latin1.decode(bytes)).length;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final date = DateTime(2026, 11, 19);
  const profile = BusinessProfile(
    businessName: 'Acme Studio India',
    address: '2 Park Street, Kolkata',
    gstin: '19ABCDE1234F1Z5',
    currency: 'INR',
  );
  final line = LineItemModel.create(
    id: 'item',
    invoiceId: 'theme-invoice',
    description: 'Design services',
    quantity: 1,
    unitPrice: 100,
  );
  final invoice = InvoiceModel(
    id: line.invoiceId,
    invoiceNumber: 'INV-00001',
    clientName: 'Sample Client',
    clientAddress: '45 Market Street, Kolkata',
    invoiceDate: date,
    dueDate: date.add(const Duration(days: 15)),
    subtotal: 100,
    grandTotal: 100,
    currency: 'INR',
    status: InvoiceStatus.paid,
    paidAmount: 100,
    notes: 'Thank you for your business.',
    createdAt: date,
    updatedAt: date,
    lineItems: [line],
  );

  for (final theme in PdfTheme.all) {
    test('${theme.name} renders one-page and three-page invoices', () async {
      for (final (pages, rows) in [(1, 1), (3, 50)]) {
        final bytes = await PdfGeneratorService.generateInvoicePdf(
          invoice: invoice.copyWith(lineItems: List.filled(rows, line)),
          businessProfile: profile,
          isPro: false,
          paidOn: date,
          theme: theme,
        );
        expect(_pageCount(bytes), pages);
      }
    });
  }

  const newStyles = [
    PdfPaperStyle.cornerWave,
    PdfPaperStyle.diagonalBand,
    PdfPaperStyle.letterheadBar,
    PdfPaperStyle.stampBorder,
    PdfPaperStyle.gstLedger,
    PdfPaperStyle.receiptStrip,
  ];
  for (final style in newStyles) {
    test('${style.name} supports each density, header and address layout', () async {
      final base = InvoiceCustomizationConfig.fromTheme(
        PdfTheme.all.firstWhere((theme) => theme.paperStyle == style),
      );
      for (final density in InvoiceDensity.values) {
        for (final header in HeaderPosition.values) {
          for (final address in AddressLayout.values) {
            final bytes = await PdfGeneratorService.generateInvoicePdf(
              invoice: invoice,
              businessProfile: profile,
              isPro: false,
              paidOn: date,
              customizationConfig: base.copyWith(
                density: density,
                headerPosition: header,
                addressLayout: address,
              ),
            );
            expect(
              _pageCount(bytes),
              inInclusiveRange(1, 2),
              reason: '$density / $header / $address',
            );
          }
        }
      }
    });
  }

  test('all six new paper styles render on attachment pages', () async {
    final directory = await Directory.systemTemp.createTemp('theme_attachments');
    addTearDown(() => directory.delete(recursive: true));
    final photo = await File('${directory.path}/photo.png').writeAsBytes(
      base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAIAAACQd1PeAAAADElEQVR4nGP4z8AAAAMBAQDJ/pLvAAAAAElFTkSuQmCC',
      ),
    );
    for (final style in newStyles) {
      final base = InvoiceCustomizationConfig.fromTheme(
        PdfTheme.all.firstWhere((theme) => theme.paperStyle == style),
      );
      final bytes = await PdfGeneratorService.generateInvoicePdf(
        invoice: invoice.copyWith(attachments: List.filled(3, photo.path)),
        businessProfile: profile,
        isPro: false,
        customizationConfig: base.copyWith(
          density: InvoiceDensity.spacious,
          headerPosition: HeaderPosition.fullWidthBanner,
        ),
      );
      expect(_pageCount(bytes), 3, reason: style.name);
    }
  });

  test('renders an invoice with discount, per-line tax, HSN and shipping', () async {
    final now = DateTime(2026, 11, 19);
    final invoice = InvoiceModel(
      id: 'inv-1',
      invoiceNumber: 'INV00001',
      clientName: 'Client',
      invoiceDate: now,
      dueDate: now.add(const Duration(days: 15)),
      subtotal: 2000,
      discountType: DiscountType.percentage,
      discountValue: 10,
      sgstRate: 9,
      cgstRate: 9,
      shipping: 50,
      grandTotal: 0, // the PDF recomputes it
      currency: 'INR',
      createdAt: now,
      updatedAt: now,
      lineItems: [
        LineItemModel.create(
          id: 'a', invoiceId: 'inv-1', description: 'Design', quantity: 1.05,
          unitPrice: 1000, taxRate: 5, hsnSac: '9983', unit: 'hr', discountRate: 5,
        ),
        for (var i = 0; i < 40; i++)
          LineItemModel.create(id: 'b$i', invoiceId: 'inv-1', description: 'Row $i', quantity: 1, unitPrice: 25),
      ],
    );
    final bytes = await PdfGeneratorService.generateInvoicePdf(
      invoice: invoice,
      businessProfile: const BusinessProfile(businessName: 'Acme Studio', currency: 'INR'),
      isPro: false,
      customizationConfig: const InvoiceCustomizationConfig(),
    );
    expect(bytes.length, greaterThan(1000));
  });

  test('renders five custom fields on invoices and estimates in every theme', () async {
    final now = DateTime(2026, 11, 19);
    const profile = BusinessProfile(businessName: 'Acme Studio', currency: 'INR');
    final fields = [
      for (var i = 1; i <= 5; i++)
        DocumentCustomField(label: 'Reference $i', value: 'PO-000000000$i'),
    ];
    final estimate = EstimateModel(
      id: 'est-1',
      estimateNumber: 'EST/2026-27/00001',
      clientName: 'Client',
      estimateDate: now,
      expiryDate: now.add(const Duration(days: 15)),
      subtotal: 100,
      grandTotal: 100,
      createdAt: now,
      updatedAt: now,
      customFields: fields,
      lineItems: [
        LineItemModel.create(
          id: 'x', invoiceId: 'est-1', description: 'Work', quantity: 1, unitPrice: 100,
        ),
      ],
    );
    final invoice = estimate.toInvoiceModel(
      newInvoiceId: 'inv-2',
      newInvoiceNumber: 'INV/2026-27/00001',
      invoiceDate: now,
    );
    for (final theme in PdfTheme.all) {
      final invoiceBytes = await PdfGeneratorService.generateInvoicePdf(
        invoice: invoice, businessProfile: profile, isPro: true, theme: theme,
      );
      final estimateBytes = await PdfGeneratorService.generateEstimatePdf(
        estimate: estimate, businessProfile: profile, isPro: true, theme: theme,
      );
      expect(invoiceBytes.length, greaterThan(1000), reason: theme.id.name);
      expect(estimateBytes.length, greaterThan(1000), reason: theme.id.name);
    }
  });
}
