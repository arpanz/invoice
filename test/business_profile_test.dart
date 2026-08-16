import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:invoice/core/models/currency_model.dart';
import 'package:invoice/core/providers/currency_provider.dart';
import 'package:invoice/features/settings/screens/business_profile_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'biz_name': 'Acme Global Corp',
      'biz_tagline': 'Creative Technology & Studio',
      'biz_email': 'hello@acme.com',
      'biz_phone': '+1 (555) 123-4567',
      'biz_address': '123 Innovation Way, Suite 100',
      'biz_gstin': '29ABCDE1234F1Z5',
      'biz_bank_name': 'Chase Bank',
      'biz_account': '9876543210',
      'biz_ifsc': '021000021',
      'biz_upi': 'acme@okhdfcbank',
      'biz_notes': 'Net 30. Thank you for your business.',
    });
  });

  Widget buildTestWidget({CurrencyProvider? customProvider}) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
            create: (_) => customProvider ?? CurrencyProvider()),
      ],
      child: const MaterialApp(
        home: BusinessProfileScreen(),
      ),
    );
  }

  testWidgets('BusinessProfileScreen renders all sections and loaded data', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    // Verify Title & AppBar
    expect(find.text('Business Profile'), findsOneWidget);
    expect(find.text('Save'), findsWidgets);

    // Verify Live Hero Card
    expect(find.text('Acme Global Corp'), findsWidgets);
    expect(find.text('Creative Technology & Studio'), findsWidgets);
    expect(find.text('Profile Readiness'), findsOneWidget);

    // Verify Sections
    expect(find.text('Branding & Identity'), findsOneWidget);
    expect(find.text('Company Logo'), findsOneWidget);
    expect(find.text('Authorized Signature'), findsOneWidget);

    // Drag to view lower sections
    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();

    expect(find.text('Contact & Location'), findsOneWidget);
    expect(find.text('hello@acme.com'), findsWidgets);

    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();

    expect(find.text('Tax & Legal Registration'), findsOneWidget);
    expect(find.text('Bank & Payment Details'), findsOneWidget);
    expect(find.text('Save Business Profile'), findsOneWidget);
  });

  testWidgets(
      'Payment details dynamically adapt according to chosen country/currency',
      (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final provider = CurrencyProvider();
    await tester.pumpWidget(buildTestWidget(customProvider: provider));
    await tester.pumpAndSettle();

    // Change currency to USD
    final usd = SupportedCurrencies.getByCode('USD')!;
    await provider.setCurrency(usd);
    await tester.pumpAndSettle();

    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await tester.pumpAndSettle();

    // USD specific payment fields
    expect(find.text('Routing Number (ABA)'), findsOneWidget);
    expect(
        find.text('Zelle / Venmo / PayPal Handle (Optional)'), findsOneWidget);
    expect(find.textContaining('United States (USD)'), findsWidgets);

    // Switch to GBP (United Kingdom)
    final gbp = SupportedCurrencies.getByCode('GBP')!;
    await provider.setCurrency(gbp);
    await tester.pumpAndSettle();

    // GBP specific payment fields
    expect(find.text('Sort Code'), findsOneWidget);
    expect(find.text('Paym / Faster Payments ID (Optional)'), findsOneWidget);
    expect(find.textContaining('United Kingdom (GBP)'), findsWidgets);

    // Switch to INR (India)
    final inr = SupportedCurrencies.getByCode('INR')!;
    await provider.setCurrency(inr);
    await tester.pumpAndSettle();

    // INR specific payment fields
    expect(find.text('IFSC Code'), findsOneWidget);
    expect(find.text('UPI ID / VPA (Optional)'), findsOneWidget);
    expect(find.textContaining('India (INR)'), findsWidgets);
  });

  testWidgets('Updating business name live-updates the hero preview card', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    final nameFields = find.widgetWithText(
      TextFormField,
      'Acme Global Corp',
    );
    expect(nameFields, findsOneWidget);

    await tester.enterText(nameFields, 'Zenith Apex Inc');
    await tester.pump();

    // The hero preview card should now display Zenith Apex Inc
    expect(find.text('Zenith Apex Inc'), findsWidgets);
  });

  testWidgets(
      'Validation prevents saving when required business name is empty', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    final nameField = find.widgetWithText(
      TextFormField,
      'Acme Global Corp',
    );
    await tester.enterText(nameField, '');
    await tester.pump();

    // Tap Save button in bottomSheet
    final saveButton = find.text('Save Business Profile');
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    // Validation error must be shown
    expect(find.text('Business name is required'), findsOneWidget);
  });
}
