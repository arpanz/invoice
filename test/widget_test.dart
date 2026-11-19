import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:invoice/core/billing/billing_service.dart';
import 'package:invoice/core/providers/currency_provider.dart';
import 'package:invoice/core/theme/app_colors.dart';
import 'package:invoice/core/theme/theme_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
          ChangeNotifierProvider(create: (_) => ThemeController()),
        ],
        child: const MaterialApp(home: SettingsScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('WORKSPACE'), findsOneWidget);
    expect(find.text('Default Design & Typography'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Rate Us on Play Store'), 100);
    expect(find.text('Rate Us on Play Store'), findsOneWidget);
  });

  testWidgets('Appearance switches to dark and back, and remembers it', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    addTearDown(() => AppColors.isDark = false);
    final controller = ThemeController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => CurrencyProvider()),
          ChangeNotifierProvider(create: (_) => BillingService()),
          ChangeNotifierProvider.value(value: controller),
        ],
        child: const MaterialApp(home: SettingsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Appearance'), 100);
    expect(find.text('Same as device'), findsOneWidget);
    await tester.ensureVisible(find.text('Same as device'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Same as device'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();

    expect(AppColors.isDark, isTrue);
    expect(controller.mode, ThemeMode.dark);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(ThemeController.prefKey), 'dark');
    // Colours already on screen were rebuilt from the dark palette.
    final title = tester.widget<Text>(find.text('Appearance'));
    expect(title.style?.color, AppColors.textPrimary);

    final reloaded = ThemeController();
    addTearDown(reloaded.dispose);
    AppColors.isDark = false;
    await reloaded.load();
    expect(reloaded.mode, ThemeMode.dark);
    expect(AppColors.isDark, isTrue);

    await controller.setMode(ThemeMode.light);
    expect(AppColors.isDark, isFalse);
  });

  testWidgets('tapping the settings icon on the dashboard opens settings', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => CurrencyProvider()),
          ChangeNotifierProvider(create: (_) => BillingService()),
          ChangeNotifierProvider(create: (_) => ThemeController()),
        ],
        child: const MaterialApp(home: DashboardScreen()),
      ),
    );

    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Invoices'), findsOneWidget);
    final menuButton = find.byIcon(Icons.settings_outlined);
    expect(menuButton, findsOneWidget);

    await tester.tap(menuButton);
    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('WORKSPACE'), findsOneWidget);

    // Tap back button to return to dashboard
    final backButton = find.byIcon(Icons.arrow_back_rounded);
    expect(backButton, findsOneWidget);
    await tester.tap(backButton);
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Invoices'), findsOneWidget);
  });
}

