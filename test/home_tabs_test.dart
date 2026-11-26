import 'package:invoice/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:invoice/core/billing/billing_service.dart';
import 'package:invoice/core/database/db_provider.dart';
import 'package:invoice/core/providers/currency_provider.dart';
import 'package:invoice/core/localization/locale_controller.dart';
import 'package:invoice/core/theme/theme_controller.dart';
import 'package:invoice/features/onboarding/screens/onboarding_screen.dart';
import 'package:invoice/features/reports/screens/reports_screen.dart';
import 'package:invoice/features/settings/screens/settings_screen.dart';
import 'package:invoice/features/dashboard/screens/dashboard_screen.dart';
import 'package:invoice/features/estimates/screens/estimate_list_screen.dart';
import 'package:invoice/main.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// The home tabs and the shell's dock search, on a phone-sized screen.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  // A fresh, empty database for every test, so "first run" really is one.
  late Database db;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
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
  tearDown(() async => db.close());

  Future<void> pumpPhone(
    WidgetTester tester,
    Widget child, {
    Locale locale = const Locale('en'),
  }) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => CurrencyProvider()),
          ChangeNotifierProvider(create: (_) => BillingService()),
          ChangeNotifierProvider(create: (_) => ThemeController()),
          ChangeNotifierProvider(create: (_) => LocaleController()),
        ],
        child: MaterialApp(
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: child,
        ),
      ),
    );
    // Let the real (ffi) database answer: real time for the I/O, then a
    // frame, until the first-load spinner is gone (capped at ~5 s).
    for (var i = 0; i < 100; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pump(const Duration(milliseconds: 16));
      if (i >= 2 && find.byType(CircularProgressIndicator).evaluate().isEmpty) return;
    }
    fail('The screen never finished loading');
  }

  testWidgets('Invoices tab on a first run: the summary and a blank first slip', (tester) async {
    await pumpPhone(tester, const DashboardScreen());

    expect(find.text('Invoices'), findsOneWidget);
    expect(find.text('TO COLLECT'), findsOneWidget);
    expect(find.text('Collected '), findsOneWidget);
    expect(find.text('Your first invoice'), findsOneWidget);
    expect(find.text('NEW'), findsOneWidget);
    // Filters appear once there is something to filter.
    expect(find.text('Overdue'), findsNothing);
  });

  testWidgets('Estimates tab shows an empty state before the first estimate', (tester) async {
    await pumpPhone(tester, const EstimateListScreen());

    expect(find.text('Estimates'), findsOneWidget);
    expect(find.text('No Estimates Yet'), findsOneWidget);
    // No empty stats or filters before there is anything to filter.
    expect(find.text('All'), findsNothing);
  });

  testWidgets('Search lives in the dock: it opens, and the close button shuts it', (tester) async {
    await pumpPhone(tester, const MainNavigationShell());

    expect(find.byType(TextField), findsNothing);
    await tester.tap(find.byTooltip('Search'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(TextField), findsOneWidget);

    await tester.tap(find.byTooltip('Close search'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(TextField), findsNothing);
    expect(find.text('Estimates'), findsOneWidget);
  });

  testWidgets('Hindi builds the main tabs and settings screens', (tester) async {
    const hindi = Locale('hi');
    await pumpPhone(tester, const MainNavigationShell(), locale: hindi);

    for (final (tab, emptyState) in [
      ('इनवॉइस', 'आपका पहला इनवॉइस'),
      ('एस्टीमेट', 'अभी कोई एस्टीमेट नहीं है'),
      ('ग्राहक', 'अभी कोई ग्राहक नहीं है'),
      ('आइटम', 'अभी कोई आइटम नहीं है'),
    ]) {
      final dockLabel = find.descendant(
        of: find.byKey(const ValueKey('tabs')),
        matching: find.text(tab),
      );
      await tester.tap(dockLabel);
      await tester.pumpAndSettle();
      expect(find.text(emptyState), findsOneWidget);
      expect(tester.takeException(), isNull);
    }

    await pumpPhone(tester, const SettingsScreen(), locale: hindi);
    expect(find.text('सेटिंग्स'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await pumpPhone(tester, const ReportsScreen(), locale: hindi);
    expect(find.text('रिपोर्ट'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Welcome picker switches the running app to Hindi', (tester) async {
    final locale = LocaleController();
    addTearDown(locale.dispose);
    tester.binding.platformDispatcher.localesTestValue = [const Locale('en')];
    addTearDown(tester.binding.platformDispatcher.clearLocalesTestValue);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => CurrencyProvider()),
          ChangeNotifierProvider(create: (_) => BillingService()),
          ChangeNotifierProvider<LocaleController>.value(value: locale),
        ],
        child: const InvoiceMakerProApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(OnboardingScreen), findsOneWidget);

    await tester.tap(find.text('Language'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('हिन्दी'));
    await tester.pumpAndSettle();

    expect(locale.language, AppLanguage.hi);
    expect(find.text('शुरू करें'), findsOneWidget);

    await tester.tap(find.text('भाषा'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('डिवाइस की भाषा'));
    await tester.pumpAndSettle();

    expect(locale.language, AppLanguage.system);
    expect(find.text('Get started'), findsOneWidget);

    tester.binding.platformDispatcher.localesTestValue = [const Locale('hi', 'IN')];
    await tester.pumpAndSettle();
    expect(find.text('शुरू करें'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

}
