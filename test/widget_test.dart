import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:invoice/core/billing/billing_service.dart';
import 'package:invoice/core/providers/currency_provider.dart';
import 'package:invoice/features/settings/screens/settings_screen.dart';

void main() {
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
    expect(find.text('Default PDF Theme'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Rate Us on Play Store'), 100);
    expect(find.text('Rate Us on Play Store'), findsOneWidget);
  });
}
