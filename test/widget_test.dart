import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:invoice/core/billing/billing_service.dart';
import 'package:invoice/core/providers/currency_provider.dart';
import 'package:invoice/features/settings/screens/settings_screen.dart';

import 'package:invoice/features/dashboard/screens/dashboard_screen.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });
  testWidgets('settings screen renders key sections', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => CurrencyProvider()),
          ChangeNotifierProvider(create: (_) => BillingService()),
        ],
        child: const MaterialApp(home: SettingsScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Workspace'), findsOneWidget);
    expect(find.text('Default Design & Typography'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Rate Us on Play Store'), 100);
    expect(find.text('Rate Us on Play Store'), findsOneWidget);
  });

  testWidgets('tapping 3-bar menu on dashboard opens settings screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => CurrencyProvider()),
          ChangeNotifierProvider(create: (_) => BillingService()),
        ],
        child: const MaterialApp(home: DashboardScreen()),
      ),
    );

    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Invoices'), findsOneWidget);
    final menuButton = find.byIcon(Icons.menu_rounded);
    expect(menuButton, findsOneWidget);

    await tester.tap(menuButton);
    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Workspace'), findsOneWidget);

    // Tap back button to return to dashboard
    final backButton = find.byIcon(Icons.arrow_back_rounded);
    expect(backButton, findsOneWidget);
    await tester.tap(backButton);
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Invoices'), findsOneWidget);
  });
}

