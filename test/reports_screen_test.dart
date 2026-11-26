import 'package:invoice/l10n/gen/app_localizations.dart';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:invoice/core/database/db_provider.dart';
import 'package:invoice/core/models/currency_model.dart';
import 'package:invoice/core/providers/currency_provider.dart';
import 'package:invoice/core/theme/app_colors.dart';
import 'package:invoice/core/theme/app_typography.dart';
import 'package:invoice/features/invoices/models/invoice_model.dart';
import 'package:invoice/features/invoices/models/line_item_model.dart';
import 'package:invoice/features/invoices/models/payment_model.dart';
import 'package:invoice/features/reports/screens/reports_screen.dart';
import 'package:invoice/shared_widgets/empty_state_view.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late Database db;
  setUp(() async {
    AppColors.isDark = false;
    SharedPreferences.setMockInitialValues({
      'user_currency': jsonEncode(
        SupportedCurrencies.getByCode('INR')!.toJson(),
      ),
    });
    db = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: DbProvider.schemaVersion,
        singleInstance: false,
        onConfigure: DbProvider.configureForTesting,
        onCreate: DbProvider.createSchemaForTesting,
      ),
    );
    DbProvider.useDatabaseForTesting(db);
  });

  tearDown(() async {
    AppColors.isDark = false;
    await db.close();
  });

  Future<void> pumpReports(WidgetTester tester, {bool dark = false}) async {
    AppColors.isDark = dark;
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => CurrencyProvider(),
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: AppTypography.theme,
          home: const ReportsScreen(),
        ),
      ),
    );

    for (var i = 0; i < 100; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump(const Duration(milliseconds: 16));
      if (i >= 2 && find.byType(CircularProgressIndicator).evaluate().isEmpty) {
        return;
      }
    }
    fail('ReportsScreen never finished loading');
  }

  testWidgets('shows EmptyStateView when there are no invoices', (
    tester,
  ) async {
    await pumpReports(tester);

    expect(find.text('Reports'), findsOneWidget);
    expect(find.byType(EmptyStateView), findsOneWidget);
    expect(find.text('No reports yet'), findsOneWidget);
  });

  testWidgets(
    'renders stats, chart, breakdown, top clients & items, and action buttons',
    (tester) async {
      final now = DateTime.now();
      final inv = InvoiceModel(
        id: 'inv-1',
        invoiceNumber: 'INV00001',
        clientName: 'Acme Studio',
        invoiceDate: now,
        dueDate: now.add(const Duration(days: 7)),
        subtotal: 1000,
        sgstRate: 9,
        cgstRate: 9,
        taxAmount: 180,
        grandTotal: 1180,
        paidAmount: 0,
        status: InvoiceStatus.unpaid,
        currency: 'INR',
        createdAt: now,
        updatedAt: now,
        lineItems: [
          LineItemModel.create(
            id: 'li-1',
            invoiceId: 'inv-1',
            description: 'Brand Identity',
            quantity: 1,
            unitPrice: 1000,
          ),
        ],
      );
      await tester.runAsync(() async {
        await DbProvider.saveInvoice(inv);
        await DbProvider.addPayment(
          PaymentModel(
            id: 'pay-1',
            invoiceId: 'inv-1',
            amount: 500,
            paidOn: now,
            method: 'UPI',
            createdAt: now,
          ),
        );
      });

      await pumpReports(tester);

      expect(find.byType(EmptyStateView), findsNothing);
      expect(find.text('BILLED'), findsOneWidget);
      expect(find.text('COLLECTED'), findsOneWidget);
      expect(find.text('OUTSTANDING'), findsOneWidget);
      expect(find.text('OVERDUE'), findsOneWidget);
      expect(find.text('TAX COLLECTED'), findsOneWidget);
      expect(find.text('AVG. INVOICE'), findsOneWidget);
      expect(find.text('Billed vs Collected'), findsOneWidget);
      expect(find.text('Status Breakdown'), findsOneWidget);

      final verticalScrollable = find.byWidgetPredicate(
        (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
      );
      await tester.scrollUntilVisible(
        find.text('Top Clients'),
        200,
        scrollable: verticalScrollable,
      );
      expect(find.text('Top Clients'), findsOneWidget);
      expect(find.text('Acme Studio'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Top Items'),
        200,
        scrollable: verticalScrollable,
      );
      expect(find.text('Top Items'), findsOneWidget);
      expect(find.text('Brand Identity'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Export to CSV / Excel'),
        200,
        scrollable: verticalScrollable,
      );
      expect(find.text('Export to CSV / Excel'), findsOneWidget);
      expect(find.text('Share summary'), findsOneWidget);

      // Scroll back to the top so the date chips are fully clear of the AppBar.
      await tester.drag(verticalScrollable, const Offset(0, 800));
      await tester.pump();
      await tester.ensureVisible(find.text('Today'));
      await tester.tap(find.text('Today'));
      await tester.pump();
      expect(find.text('BILLED'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Acme Studio'),
        200,
        scrollable: verticalScrollable,
      );
      expect(find.text('Acme Studio'), findsOneWidget);
    },
  );

  testWidgets('renders in dark mode without exceptions', (tester) async {
    final now = DateTime.now();
    await tester.runAsync(() async {
      await DbProvider.saveInvoice(
        InvoiceModel(
          id: 'inv-dark',
          invoiceNumber: 'INV00002',
          clientName: 'Night Client',
          invoiceDate: now,
          subtotal: 500,
          grandTotal: 500,
          currency: 'INR',
          createdAt: now,
          updatedAt: now,
          lineItems: [
            LineItemModel.create(
              id: 'li-dark',
              invoiceId: 'inv-dark',
              description: 'Retainer',
              quantity: 1,
              unitPrice: 500,
            ),
          ],
        ),
      );
    });

    await pumpReports(tester, dark: true);

    expect(find.text('BILLED'), findsOneWidget);
    final verticalScrollable = find.byWidgetPredicate(
      (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
    );
    await tester.scrollUntilVisible(
      find.text('Night Client'),
      200,
      scrollable: verticalScrollable,
    );
    expect(find.text('Night Client'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Retainer'),
      200,
      scrollable: verticalScrollable,
    );
    expect(find.text('Retainer'), findsOneWidget);
  });
}
