import 'package:flutter_test/flutter_test.dart';
import 'package:invoice/core/utils/document_totals.dart';
import 'package:invoice/core/utils/number_text.dart';
import 'package:invoice/features/invoices/models/invoice_model.dart';
import 'package:invoice/features/invoices/models/line_item_model.dart';

LineItemModel line(double qty, double price, {double discount = 0, double? tax}) =>
    LineItemModel.create(
      id: 'l$qty$price',
      invoiceId: 'inv',
      description: 'x',
      quantity: qty,
      unitPrice: price,
      discountRate: discount,
      taxRate: tax,
    );

double sumOfPrinted(DocumentTotals t) =>
    DocumentTotals.roundTo(
      t.taxableAmount + t.taxComponents.fold(0.0, (s, c) => s + c.amount) + t.shipping,
      2,
    );

void main() {
  group('DocumentTotals', () {
    test('no discount, intra-state GST: matches the old formula', () {
      final t = DocumentTotals.compute(
        lines: [line(2, 500)],
        sgstRate: 9,
        cgstRate: 9,
        dualTaxCurrency: true,
      );
      expect(t.subtotal, 1000);
      expect(t.taxAmount, 180);
      expect(t.grandTotal, 1180);
      expect(t.taxComponents.map((c) => c.kind), [TaxComponentKind.cgst, TaxComponentKind.sgst]);
    });

    test('F3: tax rows use the discounted taxable value and add up', () {
      final t = DocumentTotals.compute(
        lines: [line(1, 1000)],
        discountType: DiscountType.percentage,
        discountValue: 10,
        sgstRate: 9,
        cgstRate: 9,
        dualTaxCurrency: true,
      );
      expect(t.discountAmount, 100);
      expect(t.taxableAmount, 900);
      expect(t.taxComponents.every((c) => c.amount == 81), isTrue);
      expect(t.grandTotal, 1062);
      expect(sumOfPrinted(t), t.grandTotal);
    });

    test('F4: shipping is its own figure and is in the total', () {
      final t = DocumentTotals.compute(lines: [line(1, 100)], igstRate: 10, shipping: 50);
      expect(t.shipping, 50);
      expect(t.grandTotal, 160);
    });

    test('F5: a line with its own rate is not taxed twice', () {
      final t = DocumentTotals.compute(
        lines: [line(1, 1000, tax: 5), line(1, 1000)],
        sgstRate: 9,
        cgstRate: 9,
        dualTaxCurrency: true,
      );
      // 1000 at 5% (2.5 + 2.5) and 1000 at 18% (9 + 9).
      expect(t.taxAmount, 50 + 180);
      expect(t.grandTotal, 2230);
      expect(t.taxComponents.length, 4);
    });

    test('exempt line (rate 0) carries no tax', () {
      final t = DocumentTotals.compute(lines: [line(1, 100, tax: 0)], igstRate: 18, dualTaxCurrency: true);
      expect(t.taxAmount, 0);
      expect(t.grandTotal, 100);
    });

    test('line discount lowers the line amount', () {
      final l = line(2, 100, discount: 25);
      expect(l.total, 150);
    });

    test('flat discount larger than subtotal clamps to zero taxable', () {
      final t = DocumentTotals.compute(
        lines: [line(1, 300)],
        discountType: DiscountType.flat,
        discountValue: 500,
        igstRate: 10,
      );
      expect(t.discountAmount, 300);
      expect(t.taxableAmount, 0);
      expect(t.grandTotal, 0);
    });

    test('mixed rates with a discount: printed rows always add up', () {
      final t = DocumentTotals.compute(
        lines: [line(3, 333.33, tax: 12), line(7, 19.99), line(1, 0.05, tax: 28)],
        discountType: DiscountType.percentage,
        discountValue: 7.5,
        sgstRate: 9,
        cgstRate: 9,
        dualTaxCurrency: true,
        shipping: 12.345,
      );
      expect(sumOfPrinted(t), t.grandTotal);
    });

    test('single-tax country prints one row of kind single', () {
      final t = DocumentTotals.compute(lines: [line(1, 100)], igstRate: 8.875);
      expect(t.taxComponents.single.kind, TaxComponentKind.single);
      expect(t.taxAmount, 8.88);
    });
  });

  group('NumberText.trim', () {
    test('keeps decimals that replaceAll(".0") destroyed (F7, F51)', () {
      expect(NumberText.trim(1.05), '1.05');
      expect(NumberText.trim(10.05), '10.05');
      expect(NumberText.trim(10.0), '10');
      expect(NumberText.trim(100), '100');
    });

    test('keeps half rates that toStringAsFixed(0) rounded (F50, F62)', () {
      expect(NumberText.trim(2.5), '2.5');
      expect(NumberText.trim(8.875), '8.875');
      expect(NumberText.trim(0), '0');
    });
  });

  group('F21: overdue is derived', () {
    InvoiceModel inv({required DateTime? due, double paid = 0, InvoiceStatus status = InvoiceStatus.unpaid}) =>
        InvoiceModel(
          id: 'i', invoiceNumber: 'INV00001', clientName: 'C', invoiceDate: DateTime(2026, 1, 1),
          dueDate: due, subtotal: 100, grandTotal: 100, paidAmount: paid, status: status,
          createdAt: DateTime(2026, 1, 1), updatedAt: DateTime(2026, 1, 1),
        );
    final past = DateTime.now().subtract(const Duration(days: 3));
    final today = DateTime.now();

    test('past due with a balance is overdue', () {
      expect(inv(due: past).effectiveStatus, InvoiceStatus.overdue);
      expect(inv(due: past, paid: 40, status: InvoiceStatus.partiallyPaid).isOverdue, isTrue);
    });
    test('due today is not overdue yet', () => expect(inv(due: today).isOverdue, isFalse));
    test('paid in full is never overdue', () {
      expect(inv(due: past, paid: 100, status: InvoiceStatus.paid).isOverdue, isFalse);
    });
    test('no due date is never overdue', () => expect(inv(due: null).isOverdue, isFalse));
  });
}
