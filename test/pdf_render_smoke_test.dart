import 'package:flutter_test/flutter_test.dart';
import 'package:invoice/features/invoices/models/invoice_customization_config.dart';
import 'package:invoice/features/invoices/models/invoice_model.dart';
import 'package:invoice/features/invoices/models/line_item_model.dart';
import 'package:invoice/features/invoices/services/pdf_generator_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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
}
