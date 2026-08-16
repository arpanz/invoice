import 'package:flutter_test/flutter_test.dart';
import 'package:invoice/core/models/currency_model.dart';
import 'package:invoice/core/utils/currency_formatter.dart';

void main() {
  group('Global Country Tax System & Model Tests', () {
    test('SupportedCurrencies contains at least 35 countries', () {
      expect(SupportedCurrencies.all.length, greaterThanOrEqualTo(35));
    });

    test('India is the ONLY country with isDualTax = true', () {
      final dualTaxCurrencies = SupportedCurrencies.all
          .where((c) => c.defaultTax.isDualTax)
          .toList();
      expect(dualTaxCurrencies.length, 1);
      expect(dualTaxCurrencies.first.code, 'INR');
      expect(dualTaxCurrencies.first.defaultTax.shortName, 'GST');
    });

    test('All non-India countries have isDualTax = false', () {
      final international = SupportedCurrencies.all
          .where((c) => c.code != 'INR')
          .toList();
      for (final currency in international) {
        expect(
          currency.defaultTax.isDualTax,
          isFalse,
          reason: '${currency.countryName} (${currency.code}) should NOT use dual tax split',
        );
      }
    });

    test('United States has appropriate tax and banking configuration', () {
      final usd = SupportedCurrencies.getByCode('USD');
      expect(usd, isNotNull);
      expect(usd!.countryName, 'United States');
      expect(usd.symbol, '\$');
      expect(usd.defaultTax.shortName, 'Sales Tax');
      expect(usd.defaultTax.taxIdLabel, 'Tax ID / EIN');
      expect(usd.defaultTax.bankRoutingLabel, 'Routing Number (ABA)');
      expect(usd.defaultTax.bankAccountLabel, 'Account Number');
      expect(usd.defaultTax.digitalPaymentLabel, contains('Zelle'));
      expect(usd.defaultTax.bankNameHint, contains('Chase'));
      expect(usd.defaultTax.presetRates, containsAll([0.0, 5.0, 7.0, 8.875, 10.0]));
      expect(usd.decimalPlaces, 2);
    });

    test('India has UPI and IFSC configuration', () {
      final inr = SupportedCurrencies.getByCode('INR');
      expect(inr, isNotNull);
      expect(inr!.defaultTax.bankRoutingLabel, 'IFSC Code');
      expect(inr.defaultTax.digitalPaymentLabel, 'UPI ID / VPA');
      expect(inr.defaultTax.digitalPaymentHint, contains('upi'));
    });

    test('United Kingdom has appropriate VAT and Sort Code configuration', () {
      final gbp = SupportedCurrencies.getByCode('GBP');
      expect(gbp, isNotNull);
      expect(gbp!.countryName, 'United Kingdom');
      expect(gbp.symbol, '£');
      expect(gbp.defaultTax.shortName, 'VAT');
      expect(gbp.defaultTax.rate, 20.0);
      expect(gbp.defaultTax.taxIdLabel, 'VAT Reg No.');
      expect(gbp.defaultTax.bankRoutingLabel, 'Sort Code');
      expect(gbp.defaultTax.digitalPaymentLabel, contains('Paym'));
      expect(gbp.defaultTax.presetRates, containsAll([0.0, 5.0, 20.0]));
    });

    test('Australia has appropriate GST, BSB Code and PayID configuration', () {
      final aud = SupportedCurrencies.getByCode('AUD');
      expect(aud, isNotNull);
      expect(aud!.countryName, 'Australia');
      expect(aud.symbol, 'A\$');
      expect(aud.defaultTax.shortName, 'GST');
      expect(aud.defaultTax.rate, 10.0);
      expect(aud.defaultTax.taxIdLabel, 'ABN (Business No.)');
      expect(aud.defaultTax.bankRoutingLabel, 'BSB Code');
      expect(aud.defaultTax.digitalPaymentLabel, contains('PayID'));
      expect(aud.defaultTax.presetRates, containsAll([0.0, 10.0]));
    });

    test('Brazil has Pix and Agência configuration', () {
      final brl = SupportedCurrencies.getByCode('BRL');
      expect(brl, isNotNull);
      expect(brl!.defaultTax.digitalPaymentLabel, contains('Pix'));
      expect(brl.defaultTax.bankRoutingLabel, contains('Agência'));
    });

    test('UAE has appropriate VAT and TRN configuration', () {
      final aed = SupportedCurrencies.getByCode('AED');
      expect(aed, isNotNull);
      expect(aed!.countryName, 'United Arab Emirates');
      expect(aed.defaultTax.shortName, 'VAT');
      expect(aed.defaultTax.rate, 5.0);
      expect(aed.defaultTax.taxIdLabel, 'TRN (Tax Reg No.)');
      expect(aed.defaultTax.bankRoutingLabel, 'SWIFT / BIC');
    });

    test('0% tax jurisdictions are configured without tax overhead', () {
      final hkd = SupportedCurrencies.getByCode('HKD');
      expect(hkd, isNotNull);
      expect(hkd!.defaultTax.rate, 0.0);
      expect(hkd.defaultTax.shortName, 'Tax Free');

      final kwd = SupportedCurrencies.getByCode('KWD');
      expect(kwd, isNotNull);
      expect(kwd!.defaultTax.rate, 0.0);
    });

    test('Zero decimal currencies (JPY, KRW, VND)', () {
      final jpy = SupportedCurrencies.getByCode('JPY');
      expect(jpy!.decimalPlaces, 0);

      final krw = SupportedCurrencies.getByCode('KRW');
      expect(krw!.decimalPlaces, 0);

      final vnd = SupportedCurrencies.getByCode('VND');
      expect(vnd!.decimalPlaces, 0);
    });

    test('Three decimal currencies (KWD, BHD, OMR)', () {
      final kwd = SupportedCurrencies.getByCode('KWD');
      expect(kwd!.decimalPlaces, 3);

      final bhd = SupportedCurrencies.getByCode('BHD');
      expect(bhd!.decimalPlaces, 3);
    });
  });

  group('Currency Formatter & Internationalization Tests', () {
    test('Formats Indian amounts in Lakhs and Crores with ₹ symbol', () {
      expect(CurrencyFormatter.format(150000, currencyCode: 'INR'), '₹1,50,000.00');
      expect(CurrencyFormatter.formatCompact(150000, currencyCode: 'INR'), '₹1.50L');
      expect(CurrencyFormatter.formatCompact(25000000, currencyCode: 'INR'), '₹2.50Cr');
    });

    test('Formats International amounts in Thousands and Millions with country symbol', () {
      expect(CurrencyFormatter.format(150000, currencyCode: 'USD'), '\$150,000.00');
      expect(CurrencyFormatter.formatCompact(150000, currencyCode: 'USD'), '\$150.0K');
      expect(CurrencyFormatter.formatCompact(2500000, currencyCode: 'USD'), '\$2.50M');
      expect(CurrencyFormatter.formatCompact(1500000000, currencyCode: 'USD'), '\$1.50B');
    });

    test('Respects decimal places in formatting', () {
      expect(CurrencyFormatter.format(12500, currencyCode: 'JPY'), '¥12,500');
      expect(CurrencyFormatter.format(125.456, currencyCode: 'KWD'), 'د.ك125.456');
    });
  });
}
