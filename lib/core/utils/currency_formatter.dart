import 'package:intl/intl.dart';
import '../models/currency_model.dart';

class CurrencyFormatter {
  CurrencyFormatter._();

  /// Formats [amount] with the given [currencySymbol].
  /// Uses Indian number grouping (e.g. ₹1,00,000) for INR and
  /// standard grouping (e.g. $1,000,000) for all other currencies.
  static String format(double amount, {String currencySymbol = '₹'}) {
    final locale = currencySymbol == '₹' ? 'en_IN' : 'en_US';
    final formatter = NumberFormat.decimalPatternDigits(
      locale: locale,
      decimalDigits: 2,
    );
    return '$currencySymbol${formatter.format(amount)}';
  }

  static String formatCompact(double amount, {String currencySymbol = '₹'}) {
    if (amount >= 10000000) {
      return '$currencySymbol${(amount / 10000000).toStringAsFixed(2)}Cr';
    } else if (amount >= 100000) {
      return '$currencySymbol${(amount / 100000).toStringAsFixed(2)}L';
    } else if (amount >= 1000) {
      return '$currencySymbol${(amount / 1000).toStringAsFixed(1)}K';
    }
    return format(amount, currencySymbol: currencySymbol);
  }

  /// Returns the currency symbol for a given ISO currency [code].
  /// Uses [SupportedCurrencies] as the source of truth so all 30+
  /// currencies are covered. Falls back to the code itself if unknown.
  static String getCurrencySymbol(String code) {
    final currency = SupportedCurrencies.getByCode(code);
    return currency?.symbol ?? code;
  }

  static double parseAmount(String value) {
    final cleaned = value.replaceAll(RegExp(r'[^\d.]'), '');
    return double.tryParse(cleaned) ?? 0.0;
  }
}
