import 'package:invoice/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:invoice/features/invoices/models/invoice_model.dart';
import 'package:invoice/core/billing/billing_service.dart';
import 'package:invoice/core/billing/free_limits.dart';
import 'package:invoice/core/models/currency_model.dart';
import 'package:invoice/core/providers/currency_provider.dart';
import 'package:invoice/features/onboarding/screens/onboarding_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final freeLine = 'Free plan: ${FreeLimits.invoicesPerMonth} invoices a month. Upgrade any time in Settings.';
  final inr = SupportedCurrencies.getByCode('INR')!.defaultTax;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    OnboardingScreen.openCreateInvoiceOnStart = false;
  });

  Future<CurrencyProvider> pumpOnboarding(
    WidgetTester tester, {
    bool replay = false,
    Size physicalSize = const Size(1080, 2400),
    double devicePixelRatio = 2.625,
  }) async {
    tester.view.physicalSize = physicalSize;
    tester.view.devicePixelRatio = devicePixelRatio;
    addTearDown(tester.view.reset);
    final provider = CurrencyProvider();
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<CurrencyProvider>.value(value: provider),
          ChangeNotifierProvider(create: (_) => BillingService()),
        ],
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: replay
              ? Builder(
                  builder: (context) => Scaffold(
                    body: TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const OnboardingScreen(isReplay: true)),
                      ),
                      child: const Text('open tour'),
                    ),
                  ),
                )
              : const OnboardingScreen(),
        ),
      ),
    );
    // Let the sample invoice finish writing itself and stamping.
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    return provider;
  }

  /// Taps the on-screen [label] button (other pages keep theirs off screen).
  Future<void> tapVisible(WidgetTester tester, String label) async {
    final finder = find.text(label).hitTestable();
    await tester.ensureVisible(finder.first);
    await tester.pumpAndSettle();
    await tester.tap(finder.first);
    await tester.pumpAndSettle();
  }

  Future<void> enter(WidgetTester tester, String label, String text) async {
    final field = find.widgetWithText(TextField, label);
    await tester.ensureVisible(field);
    await tester.pumpAndSettle();
    await tester.enterText(field, text);
    await tester.pump();
  }

  /// The number of progress dashes in the top bar.
  int dashCount(WidgetTester tester) => find
      .byWidgetPredicate((w) => w is AnimatedContainer && w.constraints?.maxHeight == 4)
      .evaluate()
      .length;

  test('currency follows the country', () {
    expect(OnboardingScreen.currencyForCountry('IN'), 'INR');
    expect(OnboardingScreen.currencyForCountry('de'), 'EUR');
    expect(OnboardingScreen.currencyForCountry('GB'), 'GBP');
    expect(OnboardingScreen.currencyForCountry(null), 'USD');
    expect(OnboardingScreen.currencyForCountry('ZZ'), 'USD');
  });

  test('GSTIN and UPI patterns', () {
    expect(OnboardingScreen.gstinPattern.hasMatch('22AAAAA0000A1Z5'), isTrue);
    expect(OnboardingScreen.gstinPattern.hasMatch('22AAAAA0000A1Z'), isFalse);
    expect(OnboardingScreen.upiPattern.hasMatch('studio@okhdfcbank'), isTrue);
    expect(OnboardingScreen.upiPattern.hasMatch('studio.okhdfcbank'), isFalse);
  });

  test('the sample profile uses only what was typed', () {
    final p = OnboardingScreen.previewProfile(
      currencyCode: 'INR',
      taxRate: 18,
      name: ' Blue Pine ',
      address: '12 MG Road\nPune',
      taxId: '22aaaaa0000a1z5',
      upi: '',
      bankName: 'HDFC Bank',
    );
    expect(p.businessName, 'Blue Pine');
    expect(p.address, '12 MG Road\nPune');
    expect(p.gstin, '22AAAAA0000A1Z5');
    expect(p.upiId, isNull);
    expect(p.bankName, 'HDFC Bank');
    expect(p.currency, 'INR');

    final noTax = OnboardingScreen.previewProfile(currencyCode: 'INR', taxRate: 0, taxId: '22AAAAA0000A1Z5');
    expect(noTax.businessName, 'Your Business');
    expect(noTax.gstin, isNull);

    final inv = OnboardingScreen.previewInvoice(currencyCode: 'INR', taxRate: 18, terms: 'Net 30');
    expect(inv.currency, 'INR');
    expect(inv.sgstRate + inv.cgstRate, 18);
    expect(inv.igstRate, 0);
    expect(inv.dueDate!.difference(inv.invoiceDate).inDays, 30);
    expect(OnboardingScreen.previewInvoice(currencyCode: 'USD', taxRate: 0).igstRate, 0);

    // Dated today and unpaid, never overdue on a new account.
    final fresh = OnboardingScreen.previewInvoice(
      currencyCode: 'INR',
      taxRate: 18,
      now: DateTime(2026, 11, 20, 15, 30),
    );
    expect(fresh.invoiceDate, DateTime(2026, 11, 20));
    expect(fresh.status, InvoiceStatus.unpaid);
    expect(OnboardingScreen.previewInvoice(currencyCode: 'INR', taxRate: 18).isOverdue, isFalse);
  });

  testWidgets('first run walks five steps and saves only at the end', (tester) async {
    final provider = await pumpOnboarding(tester);

    expect(find.text('Get paid,\nbeautifully.'), findsOneWidget);
    expect(find.text('Takes about a minute'), findsOneWidget);
    expect(find.text('PAID'), findsOneWidget);
    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();

    // Your business, with a live letterhead.
    expect(find.text('Your business'), findsOneWidget);
    expect(find.text('Your Business'), findsOneWidget);
    expect(dashCount(tester), 3);
    await enter(tester, 'Business or your name', 'Blue Pine Studio');
    expect(find.text('Blue Pine Studio'), findsWidgets);
    await enter(tester, 'Address (optional)', '12 MG Road\nPune');
    // One line in the letterhead.
    expect(find.text('12 MG Road, Pune'), findsOneWidget);

    // Nothing is saved part-way through.
    var prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('biz_name'), isNull);

    await tapVisible(tester, 'Continue');

    // How you bill.
    expect(find.text('How you bill'), findsOneWidget);
    await tapVisible(tester, 'Net 30');
    await tapVisible(tester, 'No tax');
    await tapVisible(tester, 'Continue');

    // Getting paid: left blank, Continue.
    expect(find.text('Getting paid'), findsOneWidget);
    await tapVisible(tester, 'Continue');

    expect(find.text('You\'re all set,\nBlue.'), findsOneWidget);
    await tester.tap(find.text('I\'ll look around first'));
    await tester.pumpAndSettle();

    prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('biz_name'), 'Blue Pine Studio');
    expect(prefs.getString('biz_address'), '12 MG Road\nPune');
    expect(prefs.getString('default_payment_terms'), 'Net 30');
    expect(prefs.getString('biz_upi'), isNull);
    expect(provider.customTaxRate, 0);
    expect(provider.onboardingComplete, isTrue);
    expect(OnboardingScreen.openCreateInvoiceOnStart, isFalse);
  });

  testWidgets('the tax ID shows only with tax, follows the currency and saves', (tester) async {
    await pumpOnboarding(tester);
    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();
    await tapVisible(tester, 'Continue');

    await tapVisible(tester, '🇮🇳  INR');
    final label = '${inr.taxIdLabel} (optional)';
    expect(find.widgetWithText(TextField, label), findsOneWidget);

    // A soft hint for a malformed GSTIN, which never blocks Continue.
    await enter(tester, label, '22aaaaa');
    expect(find.textContaining('A GSTIN is 15 characters'), findsOneWidget);
    await enter(tester, label, '22aaaaa0000a1z5');
    expect(find.textContaining('A GSTIN is 15 characters'), findsNothing);

    await tapVisible(tester, 'No tax');
    expect(find.widgetWithText(TextField, label), findsNothing);
    await tapVisible(tester, '18%');
    expect(find.widgetWithText(TextField, label), findsOneWidget);

    await tapVisible(tester, 'Continue');
    // Labels follow the chosen currency, not the saved one.
    expect(find.widgetWithText(TextField, inr.digitalPaymentLabel), findsOneWidget);
    expect(find.widgetWithText(TextField, inr.bankRoutingLabel), findsOneWidget);
    await tapVisible(tester, 'Continue');
    await tester.tap(find.text('I\'ll look around first'));
    await tester.pumpAndSettle();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('biz_gstin'), '22AAAAA0000A1Z5');
  });

  testWidgets('a GSTIN is cleared when the currency leaves INR', (tester) async {
    await pumpOnboarding(tester);
    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();
    await tapVisible(tester, 'Continue');

    await tapVisible(tester, '🇮🇳  INR');
    await enter(tester, '${inr.taxIdLabel} (optional)', '22AAAAA0000A1Z5');
    await tapVisible(tester, '🇺🇸  USD');
    final usd = SupportedCurrencies.getByCode('USD')!.defaultTax;
    expect(usd.rate, isNot(0));
    final field = tester.widget<TextField>(find.widgetWithText(TextField, '${usd.taxIdLabel} (optional)'));
    expect(field.controller!.text, isEmpty);
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('I\'ll look around first'));
    await tester.pumpAndSettle();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('biz_gstin'), isNull);
  });

  testWidgets('the last step fits a small phone with large text', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.6;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final provider = await pumpOnboarding(tester, physicalSize: const Size(1080, 1920), devicePixelRatio: 3);
    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text(freeLine), findsOneWidget);
    await tapVisible(tester, 'I\'ll look around first');
    expect(provider.onboardingComplete, isTrue);
  });

  testWidgets('a tax ID typed before choosing No tax is not saved', (tester) async {
    await pumpOnboarding(tester);
    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();
    await tapVisible(tester, 'Continue');

    await tapVisible(tester, '🇮🇳  INR');
    await enter(tester, '${inr.taxIdLabel} (optional)', '22AAAAA0000A1Z5');
    await tapVisible(tester, 'No tax');
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('I\'ll look around first'));
    await tester.pumpAndSettle();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('biz_gstin'), isNull);
  });

  testWidgets('getting paid saves the payment details', (tester) async {
    await pumpOnboarding(tester);
    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();
    await tapVisible(tester, 'Continue');
    await tapVisible(tester, '🇮🇳  INR');
    await tapVisible(tester, 'Continue');

    expect(find.text('Getting paid'), findsOneWidget);
    expect(find.text('Printed on every invoice so clients know how to pay you. All optional.'), findsOneWidget);
    expect(dashCount(tester), 3);

    await enter(tester, inr.digitalPaymentLabel, 'bluepine');
    expect(find.text('A UPI ID looks like name@bank.'), findsOneWidget);
    await enter(tester, inr.digitalPaymentLabel, 'bluepine@okhdfcbank');
    expect(find.text('A UPI ID looks like name@bank.'), findsNothing);
    await enter(tester, 'Bank name', 'HDFC Bank');
    await enter(tester, inr.bankAccountLabel, '50100234567890');
    await enter(tester, inr.bankRoutingLabel, 'HDFC0000123');

    prefs() => SharedPreferences.getInstance();
    expect((await prefs()).getString('biz_upi'), isNull);

    await tapVisible(tester, 'Continue');
    expect(find.text(freeLine), findsOneWidget);
    expect(find.text('See a sample with your details'), findsOneWidget);
    await tester.tap(find.text('Create my first invoice'));
    await tester.pumpAndSettle();

    final p = await prefs();
    expect(p.getString('biz_upi'), 'bluepine@okhdfcbank');
    expect(p.getString('biz_bank_name'), 'HDFC Bank');
    expect(p.getString('biz_account'), '50100234567890');
    expect(p.getString('biz_ifsc'), 'HDFC0000123');
  });

  testWidgets('Skip for now on getting paid goes to the last step', (tester) async {
    await pumpOnboarding(tester);
    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();
    await tapVisible(tester, 'Continue');
    await tapVisible(tester, 'Continue');
    expect(find.text('Getting paid'), findsOneWidget);

    await enter(tester, 'Bank name', 'Chase');
    await tapVisible(tester, 'Skip for now');
    expect(find.text('You\'re all set.'), findsOneWidget);
    await tester.tap(find.text('I\'ll look around first'));
    await tester.pumpAndSettle();

    // Typed details still save; skipping only moves on.
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('biz_bank_name'), 'Chase');
  });

  testWidgets('Skip goes to the last step, and its button opens the editor next', (tester) async {
    final provider = await pumpOnboarding(tester);
    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();

    expect(find.text('You\'re all set.'), findsOneWidget);
    expect(find.text(freeLine), findsOneWidget);
    await tester.tap(find.text('Create my first invoice'));
    await tester.pumpAndSettle();

    expect(provider.onboardingComplete, isTrue);
    expect(OnboardingScreen.openCreateInvoiceOnStart, isTrue);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('biz_name'), isNull);
  });

  testWidgets('the sample link opens a preview and saves nothing', (tester) async {
    await pumpOnboarding(tester);
    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();
    await enter(tester, 'Business or your name', 'Blue Pine Studio');
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('See a sample with your details'));
    // The PDF renders through platform plugins, so don't wait for it.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Sample invoice'), findsOneWidget);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getKeys(), isEmpty);
  });

  testWidgets('the tour from Settings shows saved details and changes nothing', (tester) async {
    final saved = {
      'biz_name': 'Blue Pine Studio',
      'biz_address': '12 MG Road',
      'biz_upi': 'bluepine@okhdfcbank',
      'biz_bank_name': 'HDFC Bank',
    };
    SharedPreferences.setMockInitialValues(saved);
    final provider = await pumpOnboarding(tester, replay: true);
    await tester.tap(find.text('open tour'));
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Start the tour'));
    await tester.pumpAndSettle();
    expect(find.text('12 MG Road'), findsWidgets);
    await tapVisible(tester, 'Continue');
    await tapVisible(tester, 'Continue');
    expect(find.text('bluepine@okhdfcbank'), findsOneWidget);
    expect(find.text('HDFC Bank'), findsOneWidget);

    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();
    expect(find.text('That\'s the tour. Nothing was changed.'), findsOneWidget);
    expect(find.text(freeLine), findsNothing);

    await tester.tap(find.text('Back to settings'));
    await tester.pumpAndSettle();

    expect(find.text('open tour'), findsOneWidget);
    expect(provider.onboardingComplete, isFalse);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getKeys(), saved.keys.toSet());
    for (final e in saved.entries) {
      expect(prefs.getString(e.key), e.value);
    }
  });
}
