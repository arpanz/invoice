import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:invoice/core/providers/currency_provider.dart';
import 'package:invoice/core/utils/currency_formatter.dart';
import 'package:invoice/features/invoices/services/dummy_invoice_data.dart';
import 'package:invoice/shared_widgets/custom_text_field.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('CurrencyFormatter Consistency Tests', () {
    test('Correctly retrieves currency symbols for various supported codes', () {
      expect(CurrencyFormatter.getCurrencySymbol('USD'), equals('\$'));
      expect(CurrencyFormatter.getCurrencySymbol('INR'), equals('₹'));
      expect(CurrencyFormatter.getCurrencySymbol('EUR'), equals('€'));
      expect(CurrencyFormatter.getCurrencySymbol('GBP'), equals('£'));
      expect(CurrencyFormatter.getCurrencySymbol('JPY'), equals('¥'));
      expect(CurrencyFormatter.getCurrencySymbol('AED'), equals('د.إ'));
      expect(CurrencyFormatter.getCurrencySymbol('CAD'), equals('C\$'));
      expect(CurrencyFormatter.getCurrencySymbol('AUD'), equals('A\$'));
    });

    test('Formats amount with currency-specific decimal places', () {
      // Standard 2 decimal places (USD)
      expect(CurrencyFormatter.format(1234.56, currencyCode: 'USD'), equals('\$1,234.56'));
      // Zero decimal places (JPY)
      expect(CurrencyFormatter.format(1234.56, currencyCode: 'JPY'), equals('¥1,235'));
      // 3 decimal places (KWD)
      expect(CurrencyFormatter.format(1234.5, currencyCode: 'KWD'), equals('د.ك1,234.500'));
      // Indian Rupee formatting
      expect(CurrencyFormatter.format(123456.78, currencyCode: 'INR'), equals('₹1,23,456.78'));
      // Euro formatting
      expect(CurrencyFormatter.format(2500.0, currencyCode: 'EUR'), equals('€2,500.00'));
    });

    test('formatCompact formats large numbers consistently', () {
      expect(CurrencyFormatter.formatCompact(1500, currencyCode: 'USD'), equals('\$1.5K'));
      expect(CurrencyFormatter.formatCompact(2500000, currencyCode: 'EUR'), equals('€2.50M'));
      expect(CurrencyFormatter.formatCompact(1000000000, currencyCode: 'GBP'), equals('£1.00B'));
      expect(CurrencyFormatter.formatCompact(500, currencyCode: 'USD'), equals('\$500.00'));
    });
  });

  group('CurrencyProvider Integration Tests', () {
    test('CurrencyProvider dynamically formats amounts using selected currency', () async {
      final provider = CurrencyProvider();
      await provider.setCurrencyByCode('EUR');

      expect(provider.currencyCode, equals('EUR'));
      expect(provider.currencySymbol, equals('€'));
      expect(provider.formatAmount(5000), equals('€5,000.00'));
      expect(provider.formatAmountCompact(50000), equals('€50.0K'));

      await provider.setCurrencyByCode('INR');
      expect(provider.currencyCode, equals('INR'));
      expect(provider.currencySymbol, equals('₹'));
      expect(provider.formatAmount(100000), equals('₹1,00,000.00'));
    });
  });

  group('DummyInvoiceData Dynamic Currency Tests', () {
    test('getSampleInvoice and getSampleProfile adopt specified currency', () {
      final invEur = DummyInvoiceData.getSampleInvoice('EUR');
      expect(invEur.currency, equals('EUR'));

      final profGbp = DummyInvoiceData.getSampleProfile('GBP');
      expect(profGbp.currency, equals('GBP'));
      expect(profGbp.currencyConfig?.symbol, equals('£'));
    });
  });

  group('Widget Multi-Currency Tests', () {
    testWidgets('AmountTextField automatically uses CurrencyProvider symbol when not explicitly given', (tester) async {
      final provider = CurrencyProvider();
      await provider.setCurrencyByCode('GBP');

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: provider),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: AmountTextField(
                label: 'Test Amount',
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('£ '), findsOneWidget);
    });

    testWidgets('AmountTextField honors explicitly passed currency symbol override', (tester) async {
      final provider = CurrencyProvider();
      await provider.setCurrencyByCode('USD');

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: provider),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: AmountTextField(
                label: 'Test Amount',
                currencySymbol: '€',
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('€ '), findsOneWidget);
    });
  });
}
