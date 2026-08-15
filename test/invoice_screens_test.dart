import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:invoice/core/billing/billing_service.dart';
import 'package:invoice/core/providers/currency_provider.dart';
import 'package:invoice/features/dashboard/screens/dashboard_screen.dart';
import 'package:invoice/features/invoices/models/invoice_model.dart';
import 'package:invoice/features/invoices/models/line_item_model.dart';
import 'package:invoice/features/invoices/screens/create_invoice_screen.dart';
import 'package:invoice/features/invoices/screens/invoice_preview_screen.dart';
import 'package:provider/provider.dart';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  Widget wrapWithProviders(Widget child) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CurrencyProvider()),
        ChangeNotifierProvider(create: (_) => BillingService()),
      ],
      child: MaterialApp(home: child),
    );
  }

  testWidgets('DashboardScreen renders summary cards and filter chips', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(wrapWithProviders(const DashboardScreen()));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Invoices'), findsOneWidget);
    expect(find.text('Total Paid'), findsOneWidget);
    expect(find.text('Total Unpaid'), findsOneWidget);
    expect(find.text('All'), findsOneWidget);
    expect(find.text('Unpaid'), findsOneWidget);
  });

  testWidgets('CreateInvoiceScreen renders modular cards and bottom bar', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(wrapWithProviders(const CreateInvoiceScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Create Invoice'), findsOneWidget);
    expect(find.text('Templates'), findsOneWidget);
    expect(find.text('Bill From'), findsOneWidget);
    expect(find.text('Bill To'), findsOneWidget);
    expect(find.text('Items'), findsOneWidget);
    expect(find.text('Discount'), findsOneWidget);
    expect(find.text('Tax'), findsOneWidget);
    expect(find.text('Shipping'), findsOneWidget);
    expect(find.text('Total'), findsOneWidget);
    expect(find.text('Balance Due'), findsOneWidget);
    expect(find.text('Preview'), findsOneWidget);
    expect(find.text('Save'), findsOneWidget);
  });

  testWidgets('InvoicePreviewScreen renders header, total, and action buttons', (
    WidgetTester tester,
  ) async {
    final invoice = InvoiceModel(
      id: 'test-inv-1',
      invoiceNumber: 'INV00001',
      clientName: 'Acme Corporation',
      invoiceDate: DateTime(2026, 8, 14),
      dueDate: DateTime(2026, 8, 21),
      subtotal: 250.0,
      grandTotal: 250.0,
      status: InvoiceStatus.unpaid,
      createdAt: DateTime(2026, 8, 14),
      updatedAt: DateTime(2026, 8, 14),
      lineItems: [
        const LineItemModel(
          id: 'li-1',
          invoiceId: 'test-inv-1',
          description: 'Consulting Services',
          quantity: 1,
          unitPrice: 250.0,
          total: 250.0,
        ),
      ],
    );

    await tester.pumpWidget(wrapWithProviders(InvoicePreviewScreen(invoice: invoice)));
    await tester.pump();

    expect(find.text('INV00001'), findsWidgets);
    expect(find.text('Acme Corporation'), findsOneWidget);
    expect(find.text('Send Invoice'), findsOneWidget);
    expect(find.text('Download'), findsOneWidget);
    expect(find.text('Print'), findsOneWidget);
    expect(find.text('Edit'), findsOneWidget);
    expect(find.text('More'), findsOneWidget);
  });
}
