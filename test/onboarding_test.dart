import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:invoice/core/providers/currency_provider.dart';
import 'package:invoice/features/onboarding/screens/onboarding_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    OnboardingScreen.openCreateInvoiceOnStart = false;
  });

  Future<CurrencyProvider> pumpOnboarding(WidgetTester tester, {bool replay = false}) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);
    final provider = CurrencyProvider();
    await tester.pumpWidget(
      ChangeNotifierProvider<CurrencyProvider>.value(
        value: provider,
        child: MaterialApp(
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

  test('currency follows the country', () {
    expect(OnboardingScreen.currencyForCountry('IN'), 'INR');
    expect(OnboardingScreen.currencyForCountry('de'), 'EUR');
    expect(OnboardingScreen.currencyForCountry('GB'), 'GBP');
    expect(OnboardingScreen.currencyForCountry(null), 'USD');
    expect(OnboardingScreen.currencyForCountry('ZZ'), 'USD');
  });

  testWidgets('first run walks four steps and saves only at the end', (tester) async {
    final provider = await pumpOnboarding(tester);

    expect(find.text('Get paid,\nbeautifully.'), findsOneWidget);
    expect(find.text('PAID'), findsOneWidget);
    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();

    // Your business, with a live letterhead.
    expect(find.text('Your business'), findsOneWidget);
    expect(find.text('Your Business'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextField, 'Business or your name'), 'Blue Pine Studio');
    await tester.pump();
    expect(find.text('Blue Pine Studio'), findsWidgets);

    // Nothing is saved part-way through.
    var prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('biz_name'), isNull);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    // How you bill.
    expect(find.text('How you bill'), findsOneWidget);
    await tester.tap(find.text('Net 30'));
    await tester.tap(find.text('No tax'));
    await tester.pump();
    await tester.tap(find.text('Continue').last);
    await tester.pumpAndSettle();

    expect(find.text('You\'re all set,\nBlue.'), findsOneWidget);
    await tester.tap(find.text('I\'ll look around first'));
    await tester.pumpAndSettle();

    prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('biz_name'), 'Blue Pine Studio');
    expect(prefs.getString('default_payment_terms'), 'Net 30');
    expect(provider.customTaxRate, 0);
    expect(provider.onboardingComplete, isTrue);
    expect(OnboardingScreen.openCreateInvoiceOnStart, isFalse);
  });

  testWidgets('Skip goes to the last step, and its button opens the editor next', (tester) async {
    final provider = await pumpOnboarding(tester);
    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();

    expect(find.text('You\'re all set.'), findsOneWidget);
    await tester.tap(find.text('Create my first invoice'));
    await tester.pumpAndSettle();

    expect(provider.onboardingComplete, isTrue);
    expect(OnboardingScreen.openCreateInvoiceOnStart, isTrue);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('biz_name'), isNull);
  });

  testWidgets('the tour from Settings changes nothing', (tester) async {
    final provider = await pumpOnboarding(tester, replay: true);
    await tester.tap(find.text('open tour'));
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Start the tour'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();
    expect(find.text('That\'s the tour. Nothing was changed.'), findsOneWidget);

    await tester.tap(find.text('Back to settings'));
    await tester.pumpAndSettle();

    expect(find.text('open tour'), findsOneWidget);
    expect(provider.onboardingComplete, isFalse);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getKeys(), isEmpty);
  });
}
