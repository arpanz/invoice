import 'package:flutter_test/flutter_test.dart';
import 'package:invoice/core/utils/document_totals.dart';
import 'package:invoice/features/invoices/models/invoice_model.dart';
import 'package:invoice/features/invoices/models/line_item_model.dart';
import 'package:invoice/features/invoices/models/payment_model.dart';
import 'package:invoice/features/reports/services/report_service.dart';

InvoiceModel _makeInvoice({
  required String id,
  required String number,
  String? clientId,
  required String clientName,
  required DateTime invoiceDate,
  DateTime? dueDate,
  List<LineItemModel> lineItems = const [],
  double sgstRate = 0,
  double cgstRate = 0,
  double igstRate = 0,
  DiscountType discountType = DiscountType.none,
  double discountValue = 0,
  double shipping = 0,
  double paidAmount = 0,
  InvoiceStatus status = InvoiceStatus.unpaid,
  String currency = 'INR',
}) {
  final totals = DocumentTotals.forCurrency(
    currencyCode: currency,
    lines: lineItems,
    discountType: discountType,
    discountValue: discountValue,
    sgstRate: sgstRate,
    cgstRate: cgstRate,
    igstRate: igstRate,
    shipping: shipping,
  );
  return InvoiceModel(
    id: id,
    invoiceNumber: number,
    clientId: clientId,
    clientName: clientName,
    invoiceDate: invoiceDate,
    dueDate: dueDate,
    subtotal: totals.subtotal,
    discountType: discountType,
    discountValue: discountValue,
    discountAmount: totals.discountAmount,
    sgstRate: sgstRate,
    cgstRate: cgstRate,
    igstRate: igstRate,
    taxAmount: totals.taxAmount,
    shipping: totals.shipping,
    grandTotal: totals.grandTotal,
    paidAmount: paidAmount,
    status: status,
    currency: currency,
    createdAt: invoiceDate,
    updatedAt: invoiceDate,
    lineItems: lineItems,
  );
}

void main() {
  final now = DateTime(2026, 11, 26, 14, 30); // Thursday

  group('ReportDateRange', () {
    test('today covers only today calendar day', () {
      final range = ReportDateRange.forPeriod(ReportPeriod.today, now: now);
      expect(range.contains(DateTime(2026, 11, 26, 0, 1)), isTrue);
      expect(range.contains(DateTime(2026, 11, 26, 23, 59)), isTrue);
      expect(range.contains(DateTime(2026, 11, 25, 23, 59)), isFalse);
      expect(range.contains(DateTime(2026, 11, 27, 0, 0)), isFalse);
    });

    test('thisWeek covers Monday through Sunday', () {
      // 2026-11-26 is Thursday -> Mon Nov 23 .. Sun Nov 29
      final range = ReportDateRange.forPeriod(ReportPeriod.thisWeek, now: now);
      expect(range.contains(DateTime(2026, 11, 22)), isFalse);
      expect(range.contains(DateTime(2026, 11, 23)), isTrue);
      expect(range.contains(DateTime(2026, 11, 29)), isTrue);
      expect(range.contains(DateTime(2026, 11, 30)), isFalse);
    });

    test('thisMonth and thisYear cover expected bounds', () {
      final month = ReportDateRange.forPeriod(ReportPeriod.thisMonth, now: now);
      expect(month.contains(DateTime(2026, 11, 1)), isTrue);
      expect(month.contains(DateTime(2026, 11, 30)), isTrue);
      expect(month.contains(DateTime(2026, 10, 31)), isFalse);
      expect(month.contains(DateTime(2026, 12, 1)), isFalse);

      final year = ReportDateRange.forPeriod(ReportPeriod.thisYear, now: now);
      expect(year.contains(DateTime(2026, 1, 1)), isTrue);
      expect(year.contains(DateTime(2026, 12, 31)), isTrue);
      expect(year.contains(DateTime(2025, 12, 31)), isFalse);
    });

    test('custom swaps reversed bounds and compares inclusively', () {
      final range = ReportDateRange.custom(
        DateTime(2026, 11, 20),
        DateTime(2026, 11, 10),
      );
      expect(range.start, DateTime(2026, 11, 10));
      expect(range.end, DateTime(2026, 11, 20));
      expect(range.contains(DateTime(2026, 11, 10)), isTrue);
      expect(range.contains(DateTime(2026, 11, 20)), isTrue);
      expect(range.contains(DateTime(2026, 11, 9)), isFalse);
    });
  });

  group('ReportService.aggregate', () {
    // 7 invoices across 6 clients and 6 distinct items, plus payments across months.
    final invoices = <InvoiceModel>[
      // 1. Paid invoice from Oct 2026, GST 18% (CGST 9 + SGST 9) on 1000 = 1180
      _makeInvoice(
        id: 'inv-1',
        number: 'INV00001',
        clientId: 'c1',
        clientName: 'Acme Corp',
        invoiceDate: DateTime(2026, 10, 10),
        dueDate: DateTime(2026, 10, 25),
        sgstRate: 9,
        cgstRate: 9,
        paidAmount: 1180,
        status: InvoiceStatus.paid,
        lineItems: [
          LineItemModel.create(
            id: 'l1',
            invoiceId: 'inv-1',
            description: 'UI Design',
            quantity: 2,
            unitPrice: 500,
          ),
        ],
      ),
      // 2. Overdue (past due date Nov 10) from Nov 2026, partially paid 500 of 2360
      _makeInvoice(
        id: 'inv-2',
        number: 'INV00002',
        clientId: 'c2',
        clientName: 'Beta Labs',
        invoiceDate: DateTime(2026, 11, 2),
        dueDate: DateTime(2026, 11, 10),
        igstRate: 18,
        paidAmount: 500,
        status: InvoiceStatus.partiallyPaid,
        lineItems: [
          LineItemModel.create(
            id: 'l2',
            invoiceId: 'inv-2',
            description: 'Web Development',
            quantity: 1,
            unitPrice: 2000,
          ),
        ],
      ),
      // 3. Overdue (past due date Nov 20) from Nov 2026, unpaid 1500
      _makeInvoice(
        id: 'inv-3',
        number: 'INV00003',
        clientId: 'c1',
        clientName: 'Acme Corp',
        invoiceDate: DateTime(2026, 11, 12),
        dueDate: DateTime(2026, 11, 20),
        paidAmount: 0,
        status: InvoiceStatus.unpaid,
        lineItems: [
          LineItemModel.create(
            id: 'l3',
            invoiceId: 'inv-3',
            description: 'ui design',
            quantity: 3,
            unitPrice: 500,
          ),
        ],
      ),
      // 4. Unpaid (not yet due: Dec 5) from Nov 26 (today), total 800
      _makeInvoice(
        id: 'inv-4',
        number: 'INV00004',
        clientId: 'c3',
        clientName: 'Gamma Co',
        invoiceDate: DateTime(2026, 11, 26),
        dueDate: DateTime(2026, 12, 5),
        paidAmount: 0,
        status: InvoiceStatus.unpaid,
        lineItems: [
          LineItemModel.create(
            id: 'l4',
            invoiceId: 'inv-4',
            description: 'Consulting',
            quantity: 4,
            unitPrice: 200,
          ),
        ],
      ),
      // 5. Partially paid (not yet due: Dec 10) from Nov 24, total 600, paid 200
      _makeInvoice(
        id: 'inv-5',
        number: 'INV00005',
        clientId: 'c4',
        clientName: 'Delta Studio',
        invoiceDate: DateTime(2026, 11, 24),
        dueDate: DateTime(2026, 12, 10),
        paidAmount: 200,
        status: InvoiceStatus.partiallyPaid,
        lineItems: [
          LineItemModel.create(
            id: 'l5',
            invoiceId: 'inv-5',
            description: 'Copywriting',
            quantity: 2,
            unitPrice: 300,
          ),
        ],
      ),
      // 6. Client 5 (paid, Nov 18) total 400
      _makeInvoice(
        id: 'inv-6',
        number: 'INV00006',
        clientId: 'c5',
        clientName: 'Epsilon Tech',
        invoiceDate: DateTime(2026, 11, 18),
        dueDate: DateTime(2026, 11, 28),
        paidAmount: 400,
        status: InvoiceStatus.paid,
        lineItems: [
          LineItemModel.create(
            id: 'l6',
            invoiceId: 'inv-6',
            description: 'Hosting',
            quantity: 1,
            unitPrice: 400,
          ),
        ],
      ),
      // 7. Client 6 (paid, Nov 19) total 100 - should drop out of top 5
      _makeInvoice(
        id: 'inv-7',
        number: 'INV00007',
        clientId: 'c6',
        clientName: 'Zeta Media',
        invoiceDate: DateTime(2026, 11, 19),
        dueDate: DateTime(2026, 11, 29),
        paidAmount: 100,
        status: InvoiceStatus.paid,
        lineItems: [
          LineItemModel.create(
            id: 'l7',
            invoiceId: 'inv-7',
            description: 'Domain Renewal',
            quantity: 1,
            unitPrice: 100,
          ),
        ],
      ),
      // 8. Different currency (USD) - excluded when currencyCode == 'INR'
      _makeInvoice(
        id: 'inv-usd',
        number: 'INV00008',
        clientId: 'c-usd',
        clientName: 'US Client',
        invoiceDate: DateTime(2026, 11, 20),
        paidAmount: 999,
        status: InvoiceStatus.paid,
        currency: 'USD',
        lineItems: [
          LineItemModel.create(
            id: 'l8',
            invoiceId: 'inv-usd',
            description: 'US Work',
            quantity: 1,
            unitPrice: 999,
          ),
        ],
      ),
    ];

    final payments = <PaymentModel>[
      // Paid in Oct for inv-1
      PaymentModel(
        id: 'p1',
        invoiceId: 'inv-1',
        amount: 1180,
        paidOn: DateTime(2026, 10, 15),
        method: 'UPI',
        createdAt: DateTime(2026, 10, 15),
      ),
      // Paid in Nov for inv-2
      PaymentModel(
        id: 'p2',
        invoiceId: 'inv-2',
        amount: 500,
        paidOn: DateTime(2026, 11, 5),
        method: 'Bank Transfer',
        createdAt: DateTime(2026, 11, 5),
      ),
      // Paid in Nov for inv-5, inv-6, inv-7
      PaymentModel(
        id: 'p3',
        invoiceId: 'inv-5',
        amount: 200,
        paidOn: DateTime(2026, 11, 25),
        createdAt: DateTime(2026, 11, 25),
      ),
      PaymentModel(
        id: 'p4',
        invoiceId: 'inv-6',
        amount: 400,
        paidOn: DateTime(2026, 11, 18),
        createdAt: DateTime(2026, 11, 18),
      ),
      PaymentModel(
        id: 'p5',
        invoiceId: 'inv-7',
        amount: 100,
        paidOn: DateTime(2026, 11, 19),
        createdAt: DateTime(2026, 11, 19),
      ),
      // Payment for USD invoice
      PaymentModel(
        id: 'p-usd',
        invoiceId: 'inv-usd',
        amount: 999,
        paidOn: DateTime(2026, 11, 20),
        createdAt: DateTime(2026, 11, 20),
      ),
    ];

    test(
      'allTime aggregates totals, overdue, tax, top 5 clients & items, and status breakdown',
      () {
        final summary = ReportService.aggregate(
          invoices: invoices,
          payments: payments,
          range: ReportDateRange.allTime(),
          currencyCode: 'INR',
          now: now,
        );

        // Total billed INR: 1180 + 2360 + 1500 + 800 + 600 + 400 + 100 = 6940
        expect(summary.totalBilled, closeTo(6940, 0.01));
        // Total collected INR: 1180 + 500 + 200 + 400 + 100 = 2380
        expect(summary.totalCollected, closeTo(2380, 0.01));
        // Outstanding: (2360-500) + 1500 + 800 + (600-200) = 1860 + 1500 + 800 + 400 = 4560
        expect(summary.totalOutstanding, closeTo(4560, 0.01));
        // Overdue: inv-2 (1860 balance) + inv-3 (1500 balance) = 3360, count = 2
        expect(summary.overdueCount, 2);
        expect(summary.overdueAmount, closeTo(3360, 0.01));
        expect(summary.invoiceCount, 7);
        expect(summary.averageInvoiceValue, closeTo(6940 / 7, 0.01));

        // Tax: inv-1 has 180 (CGST 90 + SGST 90), inv-2 has 360 (IGST 360) -> 540
        expect(summary.totalTax, closeTo(540, 0.01));
        expect(summary.taxBreakdown.cgst, closeTo(90, 0.01));
        expect(summary.taxBreakdown.sgst, closeTo(90, 0.01));
        expect(summary.taxBreakdown.igst, closeTo(360, 0.01));

        // Other currency note
        expect(summary.otherCurrencyCounts, {'USD': 1});

        // Status breakdown:
        // Paid: inv-1 (1180), inv-6 (400), inv-7 (100) => 3, 1680
        // Overdue: inv-2 (2360), inv-3 (1500) => 2, 3860
        // Partially paid: inv-5 (600) => 1, 600
        // Unpaid: inv-4 (800) => 1, 800
        expect(summary.statusBreakdown[InvoiceStatus.paid]!.count, 3);
        expect(
          summary.statusBreakdown[InvoiceStatus.paid]!.amount,
          closeTo(1680, 0.01),
        );
        expect(summary.statusBreakdown[InvoiceStatus.overdue]!.count, 2);
        expect(
          summary.statusBreakdown[InvoiceStatus.overdue]!.amount,
          closeTo(3860, 0.01),
        );
        expect(summary.statusBreakdown[InvoiceStatus.partiallyPaid]!.count, 1);
        expect(
          summary.statusBreakdown[InvoiceStatus.partiallyPaid]!.amount,
          closeTo(600, 0.01),
        );
        expect(summary.statusBreakdown[InvoiceStatus.unpaid]!.count, 1);
        expect(
          summary.statusBreakdown[InvoiceStatus.unpaid]!.amount,
          closeTo(800, 0.01),
        );

        // Top 5 clients:
        // 1. Acme Corp: 1180 + 1500 = 2680 (2 invoices)
        // 2. Beta Labs: 2360
        // 3. Gamma Co: 800
        // 4. Delta Studio: 600
        // 5. Epsilon Tech: 400
        // (Zeta Media 100 excluded)
        expect(summary.topClients.length, 5);
        expect(summary.topClients[0].name, 'Acme Corp');
        expect(summary.topClients[0].billedAmount, closeTo(2680, 0.01));
        expect(summary.topClients[0].invoiceCount, 2);
        expect(summary.topClients[1].name, 'Beta Labs');
        expect(summary.topClients[4].name, 'Epsilon Tech');

        // Top 5 items (UI Design combines inv-1 1000 + inv-3 1500 = 2500):
        // 1. UI Design: 2500 (qty 5, 2 invoices)
        // 2. Web Development: 2000
        // 3. Consulting: 800
        // 4. Copywriting: 600
        // 5. Hosting: 400
        expect(summary.topItems.length, 5);
        expect(summary.topItems[0].description, 'UI Design');
        expect(summary.topItems[0].revenue, closeTo(2500, 0.01));
        expect(summary.topItems[0].quantity, 5);
        expect(summary.topItems[0].invoiceCount, 2);
        expect(summary.topItems[1].description, 'Web Development');
        expect(summary.topItems[4].description, 'Hosting');

        // Monthly revenue: 12 months ending Nov 2026
        expect(summary.monthlyRevenue.length, 12);
        final oct = summary.monthlyRevenue[10];
        final nov = summary.monthlyRevenue[11];
        expect(oct.month, DateTime(2026, 10, 1));
        expect(oct.billed, closeTo(1180, 0.01));
        expect(oct.collected, closeTo(1180, 0.01));
        expect(nov.month, DateTime(2026, 11, 1));
        expect(nov.billed, closeTo(5760, 0.01));
        expect(nov.collected, closeTo(1200, 0.01));
      },
    );

    test(
      'thisMonth filters invoices by issue date and payments by payment date',
      () {
        final summary = ReportService.aggregate(
          invoices: invoices,
          payments: payments,
          range: ReportDateRange.forPeriod(ReportPeriod.thisMonth, now: now),
          currencyCode: 'INR',
          now: now,
        );

        expect(summary.invoiceCount, 6);
        expect(summary.totalBilled, closeTo(5760, 0.01));
        expect(summary.totalCollected, closeTo(1200, 0.01));
        expect(summary.monthlyRevenue.length, 1);
        expect(summary.monthlyRevenue.single.month, DateTime(2026, 11, 1));
      },
    );

    test('thisWeek filters to current Mon-Sun window', () {
      // Nov 23..29 includes inv-4 (Nov 26, 800) and inv-5 (Nov 24, 600)
      // Payments: p3 (Nov 25, 200)
      final summary = ReportService.aggregate(
        invoices: invoices,
        payments: payments,
        range: ReportDateRange.forPeriod(ReportPeriod.thisWeek, now: now),
        currencyCode: 'INR',
        now: now,
      );

      expect(summary.invoiceCount, 2);
      expect(summary.totalBilled, closeTo(1400, 0.01));
      expect(summary.totalCollected, closeTo(200, 0.01));
    });

    test('empty data returns zeroed summary with isEmpty true', () {
      final summary = ReportService.aggregate(
        invoices: const [],
        payments: const [],
        range: ReportDateRange.allTime(),
        currencyCode: 'INR',
        now: now,
      );

      expect(summary.isEmpty, isTrue);
      expect(summary.invoiceCount, 0);
      expect(summary.averageInvoiceValue, 0);
      expect(summary.topClients, isEmpty);
      expect(summary.topItems, isEmpty);
    });

    test('buildShareSummary produces readable text with key figures', () {
      final summary = ReportService.aggregate(
        invoices: invoices,
        payments: payments,
        range: ReportDateRange.forPeriod(ReportPeriod.thisMonth, now: now),
        currencyCode: 'INR',
        now: now,
      );
      final text = ReportService.buildShareSummary(
        summary,
        formatMoney: (v) => '₹${v.toStringAsFixed(0)}',
        businessName: 'Studio Paper',
      );

      expect(text, contains('Studio Paper — Financial Report'));
      expect(text, contains('Period: This month'));
      expect(text, contains('Billed: ₹5760 (6 invoices)'));
      expect(text, contains('Collected: ₹1200'));
      expect(text, contains('Top Clients:'));
      expect(text, contains('Top Items:'));
    });
  });
}
