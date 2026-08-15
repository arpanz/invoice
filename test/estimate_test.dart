import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:invoice/core/billing/billing_service.dart';
import 'package:invoice/core/providers/currency_provider.dart';
import 'package:invoice/features/estimates/models/estimate_model.dart';
import 'package:invoice/features/estimates/screens/create_estimate_screen.dart';
import 'package:invoice/features/estimates/screens/estimate_list_screen.dart';
import 'package:invoice/features/estimates/screens/estimate_preview_screen.dart';
import 'package:invoice/features/invoices/models/invoice_model.dart';
import 'package:invoice/features/invoices/models/line_item_model.dart';
import 'package:invoice/features/invoices/services/pdf_generator_service.dart';
import 'package:invoice/main.dart';

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

  group('EstimateModel Unit Tests', () {
    test('EstimateModel serialization and conversion to invoice', () {
      final estimate = EstimateModel(
        id: 'est-101',
        estimateNumber: 'EST00001',
        clientId: 'client-1',
        clientName: 'Globex Corp',
        clientEmail: 'contact@globex.com',
        clientPhone: '+1 555-0199',
        clientAddress: '123 Enterprise Way',
        clientGstin: 'GSTIN12345',
        estimateDate: DateTime(2026, 8, 15),
        expiryDate: DateTime(2026, 9, 15),
        subtotal: 1000.0,
        discountType: DiscountType.percentage,
        discountValue: 10.0,
        discountAmount: 100.0,
        sgstRate: 9.0,
        cgstRate: 9.0,
        igstRate: 0.0,
        taxAmount: 162.0,
        grandTotal: 1062.0,
        status: EstimateStatus.pending,
        notes: 'Quote valid for 30 days',
        currency: 'USD',
        createdAt: DateTime(2026, 8, 15),
        updatedAt: DateTime(2026, 8, 15),
        lineItems: [
          const LineItemModel(
            id: 'li-1',
            invoiceId: 'est-101',
            description: 'Custom Development',
            quantity: 10,
            unitPrice: 100.0,
            total: 1000.0,
          ),
        ],
      );

      // Verify toMap & fromMap
      final map = estimate.toMap();
      final restored = EstimateModel.fromMap(map, items: estimate.lineItems);
      expect(restored.id, 'est-101');
      expect(restored.estimateNumber, 'EST00001');
      expect(restored.clientName, 'Globex Corp');
      expect(restored.grandTotal, 1062.0);
      expect(restored.status, EstimateStatus.pending);
      expect(restored.canConvert, isTrue);

      // Verify conversion to InvoiceModel
      final invoice = estimate.toInvoiceModel(
        newInvoiceId: 'inv-generated-1',
        newInvoiceNumber: 'INV00005',
      );
      expect(invoice.id, 'inv-generated-1');
      expect(invoice.invoiceNumber, 'INV00005');
      expect(invoice.clientName, 'Globex Corp');
      expect(invoice.subtotal, 1000.0);
      expect(invoice.discountAmount, 100.0);
      expect(invoice.taxAmount, 162.0);
      expect(invoice.grandTotal, 1062.0);
      expect(invoice.status, InvoiceStatus.unpaid);
      expect(invoice.lineItems.length, 1);
      expect(invoice.lineItems.first.description, 'Custom Development');
    });

    test('Estimate status properties & helpers', () {
      expect(EstimateStatus.pending.label, 'Pending');
      expect(EstimateStatus.accepted.label, 'Accepted');
      expect(EstimateStatus.declined.label, 'Declined');
      expect(EstimateStatus.converted.label, 'Converted');

      final expired = EstimateModel(
        id: 'est-old',
        estimateNumber: 'EST00002',
        clientName: 'Client',
        estimateDate: DateTime(2025, 1, 1),
        expiryDate: DateTime(2025, 2, 1),
        subtotal: 100,
        grandTotal: 100,
        createdAt: DateTime(2025, 1, 1),
        updatedAt: DateTime(2025, 1, 1),
      );
      expect(expired.isExpired, isTrue);

      final convertedEst = expired.copyWith(status: EstimateStatus.converted);
      expect(convertedEst.canConvert, isFalse);
    });
  });

  group('Estimate PDF Generation Tests', () {
    test('generateEstimatePdf produces valid PDF bytes', () async {
      final estimate = EstimateModel(
        id: 'est-pdf-test',
        estimateNumber: 'EST00099',
        clientName: 'Acme Test Corp',
        clientAddress: '100 Main St',
        estimateDate: DateTime(2026, 8, 15),
        expiryDate: DateTime(2026, 9, 15),
        subtotal: 500.0,
        grandTotal: 500.0,
        createdAt: DateTime(2026, 8, 15),
        updatedAt: DateTime(2026, 8, 15),
        lineItems: [
          const LineItemModel(
            id: 'li-1',
            invoiceId: 'est-pdf-test',
            description: 'Design Prototype',
            quantity: 1,
            unitPrice: 500.0,
            total: 500.0,
          ),
        ],
      );

      const profile = BusinessProfile(
        businessName: 'My Design Studio',
        address: '77 Studio Way',
        currency: 'USD',
      );

      final pdfBytes = await PdfGeneratorService.generateEstimatePdf(
        estimate: estimate,
        businessProfile: profile,
        isPro: true,
      );

      expect(pdfBytes, isNotEmpty);
      expect(pdfBytes.length, greaterThan(1000));
    });
  });

  group('Estimate UI & Widget Tests', () {
    testWidgets('EstimateListScreen renders KPI summary cards and filter chips', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(wrapWithProviders(const EstimateListScreen()));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Estimates'), findsOneWidget);
      expect(find.text('Estimated'), findsOneWidget);
      expect(find.text('Pending'), findsWidgets);
      expect(find.text('Accepted'), findsWidgets);
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Converted'), findsOneWidget);
      expect(find.text('Declined'), findsOneWidget);
    });

    testWidgets('CreateEstimateScreen renders form fields and quick validity pills', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(wrapWithProviders(const CreateEstimateScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Create Estimate'), findsOneWidget);
      expect(find.text('Estimate Number *'), findsOneWidget);
      expect(find.text('Estimate Date'), findsOneWidget);
      expect(find.text('Valid Until / Expiry'), findsOneWidget);
      expect(find.text('7 Days'), findsOneWidget);
      expect(find.text('14 Days'), findsOneWidget);
      expect(find.text('30 Days'), findsOneWidget);
      expect(find.text('PDF Theme'), findsOneWidget);
      expect(find.text('Items & Services'), findsOneWidget);
      expect(find.text('Preview PDF'), findsOneWidget);
      expect(find.text('Save Estimate'), findsOneWidget);
    });

    testWidgets('EstimatePreviewScreen renders estimate details and convert button', (
      WidgetTester tester,
    ) async {
      final estimate = EstimateModel(
        id: 'est-preview-1',
        estimateNumber: 'EST00042',
        clientName: 'Wayne Enterprises',
        estimateDate: DateTime(2026, 8, 15),
        expiryDate: DateTime(2026, 9, 15),
        subtotal: 1500.0,
        grandTotal: 1500.0,
        status: EstimateStatus.pending,
        createdAt: DateTime(2026, 8, 15),
        updatedAt: DateTime(2026, 8, 15),
        lineItems: [
          const LineItemModel(
            id: 'li-w1',
            invoiceId: 'est-preview-1',
            description: 'Security Audit',
            quantity: 1,
            unitPrice: 1500.0,
            total: 1500.0,
          ),
        ],
      );

      await tester.pumpWidget(wrapWithProviders(EstimatePreviewScreen(estimate: estimate)));
      await tester.pump();

      expect(find.text('EST00042'), findsOneWidget);
      expect(find.text('Convert to Invoice'), findsOneWidget);
      expect(find.text('Share PDF'), findsOneWidget);
      expect(find.text('Print'), findsOneWidget);
    });

    testWidgets('MainNavigationShell renders 5 items in bottom bar and create sheet', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(wrapWithProviders(const MainNavigationShell()));
      await tester.pump(const Duration(milliseconds: 200));

      // 5 items in bottom nav
      expect(find.text('Invoices'), findsWidgets);
      expect(find.text('Estimates'), findsOneWidget);
      expect(find.text('Clients'), findsOneWidget);
      expect(find.text('History'), findsOneWidget);
      expect(find.byIcon(Icons.add_rounded), findsOneWidget);

      // Tap on Estimates tab
      await tester.tap(find.text('Estimates'));
      await tester.pump(const Duration(milliseconds: 200));

      // Tap on Center (+) action button in the bottom navigation bar
      final centerAddButton = find.byWidgetPredicate(
        (w) => w is Icon && w.icon == Icons.add_rounded && w.size == 28,
      );
      expect(centerAddButton, findsOneWidget);
      await tester.tap(centerAddButton);
      await tester.pump(const Duration(milliseconds: 500));

      // Create sheet modal opens with 2 document options
      expect(find.text('Create New Document'), findsOneWidget);
      expect(find.text('New Invoice'), findsOneWidget);
      expect(find.text('New Estimate / Quote'), findsOneWidget);
    });
  });
}
