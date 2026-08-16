import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:invoice/core/billing/billing_service.dart';
import 'package:invoice/core/providers/currency_provider.dart';
import 'package:invoice/features/paywall/paywall_screen.dart';
import 'package:provider/provider.dart';

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

    // Verify header content
    expect(find.byIcon(Icons.workspace_premium_rounded), findsOneWidget);
    expect(find.text('Invoice Maker Pro'), findsOneWidget);

    // Verify section label and feature items
    expect(find.text('WHAT\'S INCLUDED'), findsOneWidget);
    expect(find.text('Unlimited Invoices'), findsOneWidget);
    expect(find.text('Custom Branding & Logo'), findsOneWidget);
    expect(find.text('Client & Inventory Manager'), findsOneWidget);
    expect(find.text('Priority Support'), findsOneWidget);

    // Verify Pricing boxes and CTA
    expect(find.text('Monthly'), findsOneWidget);
    expect(find.text('Lifetime'), findsOneWidget);
    expect(find.text('BEST VALUE'), findsOneWidget);
    expect(find.text('Unlock Lifetime Access'), findsOneWidget);

    // Verify Close and Restore buttons
    expect(find.byIcon(Icons.close_rounded), findsOneWidget);
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
}
