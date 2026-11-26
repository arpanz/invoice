import 'package:invoice/l10n/gen/app_localizations.dart';
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
import 'package:invoice/core/theme/app_icons.dart';

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
        child: const MaterialApp(
          locale: Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: SettingsScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('WORKSPACE'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Default Design & Typography'), 100);
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
        child: const MaterialApp(
          locale: Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: SettingsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Appearance'), 100);
    // Light until the person picks otherwise.
    expect(controller.mode, ThemeMode.light);
    expect(find.text('Light'), findsOneWidget);
    await tester.ensureVisible(find.text('Light'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Light'));
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

  test('a fresh install loads light, and "system" stays system', () async {
    addTearDown(() => AppColors.isDark = false);
    SharedPreferences.setMockInitialValues({});
    final fresh = ThemeController();
    addTearDown(fresh.dispose);
    await fresh.load();
    expect(fresh.mode, ThemeMode.light);
    expect(AppColors.isDark, isFalse);

    SharedPreferences.setMockInitialValues({ThemeController.prefKey: 'system'});
    final system = ThemeController();
    addTearDown(system.dispose);
    await system.load();
    expect(system.mode, ThemeMode.system);
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
        child: const MaterialApp(
          locale: Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: DashboardScreen(),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Invoices'), findsOneWidget);
    final menuButton = find.byIcon(AppIcons.settings);
    expect(menuButton, findsOneWidget);

    await tester.tap(menuButton);
    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('WORKSPACE'), findsOneWidget);

    // Tap back button to return to dashboard
    final backButton = find.byIcon(AppIcons.arrowBack);
    expect(backButton, findsOneWidget);
    await tester.tap(backButton);
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Invoices'), findsOneWidget);
  });
}

