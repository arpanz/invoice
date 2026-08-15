import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:invoice/core/billing/billing_service.dart';
import 'package:invoice/core/database/db_provider.dart';
import 'package:invoice/core/providers/currency_provider.dart';
import 'package:invoice/features/dashboard/screens/dashboard_screen.dart';
import 'package:invoice/features/invoices/models/invoice_model.dart';
import 'package:invoice/features/invoices/models/line_item_model.dart';
import 'package:invoice/features/invoices/models/pdf_theme.dart';
import 'package:invoice/features/invoices/screens/create_invoice_screen.dart';
import 'package:invoice/features/invoices/screens/invoice_history_screen.dart';
import 'package:invoice/features/invoices/screens/invoice_preview_screen.dart';
import 'package:invoice/features/invoices/services/pdf_generator_service.dart';
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

  group('InvoiceModel & Partially Paid Status Tests', () {
    test('InvoiceStatus extension handles partiallyPaid correctly', () {
      expect(InvoiceStatus.partiallyPaid.label, 'Partially Paid');
      expect(InvoiceStatus.partiallyPaid.value, 'partially_paid');

      expect(InvoiceStatusExtension.fromString('partially_paid'), InvoiceStatus.partiallyPaid);
      expect(InvoiceStatusExtension.fromString('partiallypaid'), InvoiceStatus.partiallyPaid);
      expect(InvoiceStatusExtension.fromString('partial'), InvoiceStatus.partiallyPaid);
      expect(InvoiceStatusExtension.fromString('paid'), InvoiceStatus.paid);
      expect(InvoiceStatusExtension.fromString('unpaid'), InvoiceStatus.unpaid);
      expect(InvoiceStatusExtension.fromString('overdue'), InvoiceStatus.overdue);
    });

    test('InvoiceModel correctly calculates balanceDue and isOverdue', () {
      final now = DateTime.now();
      final invoice = InvoiceModel(
        id: 'inv-test-1',
        invoiceNumber: 'INV00001',
        clientName: 'Alpha Corp',
        invoiceDate: now.subtract(const Duration(days: 10)),
        dueDate: now.subtract(const Duration(days: 3)),
        subtotal: 1000.0,
        grandTotal: 1000.0,
        paidAmount: 400.0,
        status: InvoiceStatus.partiallyPaid,
        createdAt: now,
        updatedAt: now,
      );

      expect(invoice.balanceDue, 600.0);
      expect(invoice.isOverdue, true);

      final map = invoice.toMap();
      expect(map['status'], 'partially_paid');
      expect(map['paid_amount'], 400.0);

      final fromMap = InvoiceModel.fromMap(map);
      expect(fromMap.status, InvoiceStatus.partiallyPaid);
      expect(fromMap.paidAmount, 400.0);
      expect(fromMap.balanceDue, 600.0);
    });
  });

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
    expect(find.text('Partially Paid'), findsOneWidget);
    expect(find.text('Paid'), findsOneWidget);
    expect(find.text('Overdue'), findsOneWidget);
  });

  testWidgets('InvoiceHistoryScreen renders AppBar, search button, and filter chips', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(wrapWithProviders(const InvoiceHistoryScreen()));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('History'), findsOneWidget);
    expect(find.byIcon(Icons.search_rounded), findsOneWidget);
    expect(find.text('All'), findsOneWidget);
    expect(find.text('Unpaid'), findsOneWidget);
    expect(find.text('Partially Paid'), findsOneWidget);
    expect(find.text('Overdue'), findsOneWidget);
    expect(find.text('Paid'), findsOneWidget);

    // Tap search icon to toggle search bar
    await tester.tap(find.byIcon(Icons.search_rounded));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(TextField), findsOneWidget);
    expect(find.byIcon(Icons.close_rounded), findsOneWidget);
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
    expect(find.byIcon(Icons.account_balance_outlined), findsOneWidget);
    expect(find.text('Shipping'), findsOneWidget);
    expect(find.text('Total'), findsOneWidget);
    expect(find.text('Balance Due'), findsOneWidget);
    expect(find.text('Preview'), findsOneWidget);
    expect(find.text('Save'), findsOneWidget);
  });

  testWidgets('InvoicePreviewScreen renders partially paid info and actions', (
    WidgetTester tester,
  ) async {
    final invoice = InvoiceModel(
      id: 'test-inv-partial',
      invoiceNumber: 'INV00099',
      clientName: 'Acme Corporation',
      invoiceDate: DateTime(2026, 8, 14),
      dueDate: DateTime(2026, 8, 21),
      subtotal: 500.0,
      grandTotal: 500.0,
      paidAmount: 200.0,
      status: InvoiceStatus.partiallyPaid,
      createdAt: DateTime(2026, 8, 14),
      updatedAt: DateTime(2026, 8, 14),
      lineItems: [
        const LineItemModel(
          id: 'li-1',
          invoiceId: 'test-inv-partial',
          description: 'Consulting Services',
          quantity: 1,
          unitPrice: 500.0,
          total: 500.0,
        ),
      ],
    );

    await tester.pumpWidget(wrapWithProviders(InvoicePreviewScreen(invoice: invoice)));
    await tester.pump();

    expect(find.text('INV00099'), findsWidgets);
    expect(find.text('Acme Corporation'), findsOneWidget);
    expect(find.text('Partially Paid'), findsWidgets);
    expect(find.text('Paid: ₹200.00'), findsOneWidget);
    expect(find.text('Balance Due: ₹300.00'), findsOneWidget);
    expect(find.text('Send Invoice'), findsOneWidget);
    expect(find.text('Download'), findsOneWidget);
    expect(find.text('Print'), findsOneWidget);
    expect(find.text('Edit'), findsOneWidget);
  });

  test('PdfGeneratorService generates PDF with Partially Paid status & balance due', () async {
    final invoice = InvoiceModel(
      id: 'pdf-inv-partial',
      invoiceNumber: 'INV00077',
      clientName: 'Global Tech Inc',
      invoiceDate: DateTime(2026, 8, 15),
      dueDate: DateTime(2026, 8, 25),
      subtotal: 1000.0,
      grandTotal: 1000.0,
      paidAmount: 350.0,
      status: InvoiceStatus.partiallyPaid,
      createdAt: DateTime(2026, 8, 15),
      updatedAt: DateTime(2026, 8, 15),
      lineItems: [
        const LineItemModel(
          id: 'li-1',
          invoiceId: 'pdf-inv-partial',
          description: 'Software Development',
          quantity: 1,
          unitPrice: 1000.0,
          total: 1000.0,
        ),
      ],
    );

    final profile = const BusinessProfile(
      businessName: 'My Dev Business',
      address: '123 Code Street',
      phone: '+1 555-0199',
      email: 'biz@example.com',
    );

    final pdfBytes = await PdfGeneratorService.generateInvoicePdf(
      invoice: invoice,
      businessProfile: profile,
      isPro: true,
      theme: PdfTheme.defaultTheme,
    );

    expect(pdfBytes, isNotNull);
    expect(pdfBytes.length, greaterThan(1000));
  });
}
