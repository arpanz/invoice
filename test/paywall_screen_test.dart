import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:invoice/core/billing/billing_service.dart';
import 'package:invoice/core/providers/currency_provider.dart';
import 'package:invoice/features/paywall/paywall_screen.dart';
import 'package:provider/provider.dart';
import 'package:invoice/core/theme/app_icons.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget wrapWithProviders(Widget child) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CurrencyProvider()),
        ChangeNotifierProvider(create: (_) => BillingService()),
      ],
      child: MaterialApp(home: child),
    );
  }

  testWidgets('PaywallScreen renders header, features, and pricing', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(wrapWithProviders(const PaywallScreen()));
    await tester.pump(const Duration(milliseconds: 200));

    // Headline, and the receipt of what Pro includes with its stamp
    expect(find.text('Bill without\nlimits.'), findsOneWidget);
    expect(find.text('Invoice Maker Pro'), findsOneWidget);
    expect(find.text('PRO'), findsOneWidget);

    // Verify section label and feature items
    expect(find.text('WHAT\'S INCLUDED'), findsOneWidget);
    // Only what Pro actually unlocks, with the free limits stated.
    expect(find.text('Unlimited Invoices & Estimates'), findsOneWidget);
    expect(find.text('Unlimited Clients'), findsOneWidget);
    expect(find.text('No Watermark'), findsOneWidget);
    expect(find.text('The free plan includes 10 of each per calendar month.'), findsOneWidget);
    expect(find.text('The free plan saves up to 10 clients.'), findsOneWidget);

    // Verify Pricing boxes and CTA
    expect(find.text('Monthly'), findsOneWidget);
    expect(find.text('Lifetime'), findsOneWidget);
    expect(find.text('BEST VALUE'), findsOneWidget);
    expect(find.text('Unlock Lifetime Access'), findsOneWidget);

    // Verify Close and Restore buttons
    expect(find.byIcon(AppIcons.close), findsOneWidget);
    expect(find.text('Restore purchase'), findsOneWidget);
  });

  testWidgets('PaywallScreen toggles pricing selection between Monthly and Lifetime', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(wrapWithProviders(const PaywallScreen()));
    await tester.pump(const Duration(milliseconds: 200));

    // Initially Lifetime is selected
    expect(find.text('Unlock Lifetime Access'), findsOneWidget);

    // Tap on Monthly pricing box
    await tester.tap(find.text('Monthly'));
    await tester.pump(const Duration(milliseconds: 250));

    // CTA button updates
    expect(find.textContaining('Subscribe for'), findsOneWidget);

    // Tap back to Lifetime
    await tester.tap(find.text('Lifetime'));
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('Unlock Lifetime Access'), findsOneWidget);
  });

  testWidgets('PaywallScreen close button pops the page', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => CurrencyProvider()),
          ChangeNotifierProvider(create: (_) => BillingService()),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PaywallScreen())),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Restore purchase'), findsOneWidget);

    await tester.tap(find.byIcon(AppIcons.close));
    await tester.pumpAndSettle();
    expect(find.text('Restore purchase'), findsNothing);
    expect(find.text('open'), findsOneWidget);
  });
}
