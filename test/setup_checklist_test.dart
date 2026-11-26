import 'package:invoice/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:invoice/core/billing/billing_service.dart';
import 'package:invoice/core/database/db_provider.dart';
import 'package:invoice/core/providers/currency_provider.dart';
import 'package:invoice/features/dashboard/screens/dashboard_screen.dart';
import 'package:invoice/features/dashboard/widgets/setup_checklist_card.dart';
import 'package:invoice/features/invoices/models/invoice_customization_config.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// The "Finish setting up" card: which items show, when it hides, and that
/// closing it sticks.
void main() {
  const fullProfile = {
    'biz_logo_path': '/logo.png',
    'biz_address': '1 Market St',
    'biz_gstin': '29ABCDE1234F1Z5',
    'biz_upi': 'me@upi',
    'biz_signature_path': '/sig.png',
  };

  SetupChecklist compute({
    Map<String, String> prefs = const {},
    InvoiceCustomizationConfig design = const InvoiceCustomizationConfig(),
    int invoiceCount = 0,
    double taxRate = 18,
    bool dismissed = false,
  }) => SetupChecklist.compute(
    pref: (k) => prefs[k],
    design: design,
    invoiceCount: invoiceCount,
    taxRate: taxRate,
    taxIdLabel: 'GSTIN',
    dismissed: dismissed,
  );

  List<SetupStep> steps(SetupChecklist c) => c.items.map((i) => i.step).toList();

  test('a fresh install lists every item, none done', () {
    final c = compute();
    expect(steps(c), SetupStep.values);
    expect(c.doneCount, 0);
    expect(c.isVisible, isTrue);
    expect(c.items.firstWhere((i) => i.step == SetupStep.taxId).label, 'Add your GSTIN');
  });

  test('the tax ID is only asked for when tax is charged', () {
    expect(steps(compute(taxRate: 0)), isNot(contains(SetupStep.taxId)));
    expect(steps(compute(taxRate: 5)), contains(SetupStep.taxId));
  });

  test('signature and payment details follow the default design', () {
    const hidden = InvoiceCustomizationConfig(showSignature: false, showUpiDetails: false, showBankDetails: false);
    expect(steps(compute(design: hidden)), isNot(anyOf(contains(SetupStep.signature), contains(SetupStep.payment))));
    // Either payment block on the PDF is enough to ask for details.
    expect(
      steps(compute(design: const InvoiceCustomizationConfig(showUpiDetails: false))),
      contains(SetupStep.payment),
    );
  });

  test('a bank account counts as payment details too', () {
    final c = compute(prefs: {'biz_account': '12345678'});
    expect(c.items.firstWhere((i) => i.step == SetupStep.payment).done, isTrue);
  });

  test('blank values do not count as done', () {
    final c = compute(prefs: {'biz_address': '   '});
    expect(c.items.firstWhere((i) => i.step == SetupStep.address).done, isFalse);
  });

  test('hides once everything is done', () {
    final c = compute(prefs: fullProfile, invoiceCount: 1);
    expect(c.allDone, isTrue);
    expect(c.isVisible, isFalse);
    expect(compute(prefs: fullProfile).isVisible, isTrue);
  });

  test('with only the first invoice left, the first-run card has nothing to show', () {
    final profileDone = compute(prefs: fullProfile);
    expect(profileDone.isVisibleWithout(SetupStep.firstInvoice), isFalse);
    expect(compute().isVisibleWithout(SetupStep.firstInvoice), isTrue);
  });

  test('hides for good once dismissed', () {
    expect(compute(dismissed: true).isVisible, isFalse);
  });

  test('reads the saved default design and the dismissal from prefs', () async {
    SharedPreferences.setMockInitialValues({
      'default_invoice_customization': '{"show_signature": false}',
      SetupChecklist.dismissedKey: true,
    });
    final prefs = await SharedPreferences.getInstance();
    final c = SetupChecklist.fromPrefs(prefs, invoiceCount: 0, taxRate: 0, taxIdLabel: 'Tax ID');
    expect(steps(c), isNot(contains(SetupStep.signature)));
    expect(c.dismissed, isTrue);
  });

  testWidgets('the card shows what is left and closing it is saved', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final c = compute(prefs: {'biz_logo_path': '/logo.png'});
    final opened = <SetupStep>[];
    var dismissed = false;

    await tester.pumpWidget(
      MaterialApp(
        locale: Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SetupChecklistCard(checklist: c, onOpen: opened.add, onDismissed: () => dismissed = true),
        ),
      ),
    );

    expect(find.text('Finish setting up'), findsOneWidget);
    expect(find.text('1 of 6 done'), findsOneWidget);
    // Done items drop off the list.
    expect(find.text('Add your logo'), findsNothing);
    expect(find.text('Add your address'), findsOneWidget);

    await tester.tap(find.text('Make your first invoice'));
    expect(opened, [SetupStep.firstInvoice]);

    await tester.tap(find.byTooltip('Hide'));
    await tester.pumpAndSettle();
    expect(dismissed, isTrue);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(SetupChecklist.dismissedKey), isTrue);
  });

  testWidgets('a long tax ID name wraps instead of being cut off', (tester) async {
    final c = SetupChecklist.compute(
      pref: (_) => null,
      design: const InvoiceCustomizationConfig(),
      invoiceCount: 0,
      taxRate: 13,
      taxIdLabel: 'Unified Social Credit Code',
    );
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        locale: Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: SetupChecklistCard(checklist: c, onOpen: (_) {}, onDismissed: () {}),
          ),
        ),
      ),
    );

    final label = tester.renderObject<RenderParagraph>(find.text('Add your Unified Social Credit Code'));
    expect(label.didExceedMaxLines, isFalse);
  });

  group('on the dashboard', () {
    setUpAll(() {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    });

    late Database db;
    setUp(() async {
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

    Future<void> pumpDashboard(WidgetTester tester, {Size size = const Size(1080, 2400), double dpr = 2.625}) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = dpr;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => CurrencyProvider()),
            ChangeNotifierProvider(create: (_) => BillingService()),
          ],
          child: const MaterialApp(
            locale: Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: DashboardScreen(),
          ),
        ),
      );
      for (var i = 0; i < 100; i++) {
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
        await tester.pump(const Duration(milliseconds: 16));
        if (i >= 2 && find.byType(CircularProgressIndicator).evaluate().isEmpty) break;
      }
      await tester.pumpAndSettle();
    }

    testWidgets('a first run shows the card without pushing the create button off screen', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await pumpDashboard(tester);

      expect(find.text('Finish setting up'), findsOneWidget);
      final button = tester.getRect(find.text('Create Invoice'));
      expect(button.bottom, lessThan(tester.view.physicalSize.height / tester.view.devicePixelRatio));
    });

    testWidgets('on a short phone the create button stays on screen', (tester) async {
      SharedPreferences.setMockInitialValues({});
      // 360x640dp, a small Android phone.
      await pumpDashboard(tester, size: const Size(1080, 1920), dpr: 3);

      expect(find.text('Finish setting up'), findsOneWidget);
      final button = tester.getRect(find.widgetWithText(ElevatedButton, 'Create Invoice'));
      expect(button.bottom, lessThanOrEqualTo(640));
      // The card sits under the button, which already covers the first invoice.
      expect(tester.getRect(find.text('Finish setting up')).top, greaterThan(button.bottom));
      expect(find.text('Make your first invoice'), findsNothing);
    });

    testWidgets('a dismissed card stays away', (tester) async {
      SharedPreferences.setMockInitialValues({SetupChecklist.dismissedKey: true});
      await pumpDashboard(tester);

      expect(find.text('Finish setting up'), findsNothing);
      expect(find.text('Your first invoice'), findsOneWidget);
    });
  });
}
