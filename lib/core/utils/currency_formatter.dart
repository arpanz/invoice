import 'package:intl/intl.dart';
import '../models/currency_model.dart';

class CurrencyFormatter {
  CurrencyFormatter._();

  /// Formats [amount] with the given [currencyCode] or [currencySymbol].
  /// Accurately applies decimal digits (e.g. 0 for JPY, 3 for KWD, 2 for others)
  /// and localized number patterns.
  static String format(
    double amount, {
    String? currencyCode,
    String? currencySymbol,
    int? decimalDigits,
  }) {
    final currency = currencyCode != null
        ? SupportedCurrencies.getByCode(currencyCode.trim())
        : null;

    final symbol = currencySymbol ??
        currency?.symbol ??
        (currencyCode != null ? getCurrencySymbol(currencyCode) : '\$');
    final decimals = decimalDigits ?? currency?.decimalPlaces ?? 2;
    final isINR = (currencyCode?.toUpperCase().trim() == 'INR') || (symbol == '₹');
    final locale = isINR ? 'en_IN' : 'en_US';

    final formatter = NumberFormat.decimalPatternDigits(
      locale: locale,
      decimalDigits: decimals,
    );

    if (amount < 0) {
      return '-$symbol${formatter.format(amount.abs())}';
    }
    return '$symbol${formatter.format(amount)}';
  }

  /// Formats [amount] compactly:
  /// Uses Lakhs (L) and Crores (Cr) for Indian Rupee (INR).
  /// Uses Thousands (K), Millions (M), Billions (B) for all international currencies.
  static String formatCompact(
    double amount, {
    String? currencyCode,
    String? currencySymbol,
  }) {
    final currency = currencyCode != null
        ? SupportedCurrencies.getByCode(currencyCode.trim())
        : null;
    final symbol = currencySymbol ??
        currency?.symbol ??
        (currencyCode != null ? getCurrencySymbol(currencyCode) : '\$');
    final isINR = (currencyCode?.toUpperCase().trim() == 'INR') || (symbol == '₹');
    final isNegative = amount < 0;
    final absAmount = amount.abs();
    final prefix = isNegative ? '-$symbol' : symbol;

    if (isINR) {
      if (absAmount >= 10000000) {
        return '$prefix${(absAmount / 10000000).toStringAsFixed(2)}Cr';
      } else if (absAmount >= 100000) {
        return '$prefix${(absAmount / 100000).toStringAsFixed(2)}L';
      } else if (absAmount >= 1000) {
        return '$prefix${(absAmount / 1000).toStringAsFixed(1)}K';
      }
    } else {
      if (absAmount >= 1000000000) {
        return '$prefix${(absAmount / 1000000000).toStringAsFixed(2)}B';
      } else if (absAmount >= 1000000) {
        return '$prefix${(absAmount / 1000000).toStringAsFixed(2)}M';
      } else if (absAmount >= 1000) {
        return '$prefix${(absAmount / 1000).toStringAsFixed(1)}K';
      }
    }
    return format(amount, currencyCode: currencyCode, currencySymbol: symbol);
  }

  /// Returns the currency symbol for a given ISO currency [code].
  /// Uses [SupportedCurrencies] as the source of truth so all 35+
  /// currencies are covered. Falls back to the code itself if unknown.
  static String getCurrencySymbol(String? code) {
    if (code == null || code.trim().isEmpty) return '\$';
    final currency = SupportedCurrencies.getByCode(code.trim());
    return currency?.symbol ?? code.trim();
  }

  static double parseAmount(String value) {
    final cleaned = value.replaceAll(RegExp(r'[^\d.]'), '');
    return double.tryParse(cleaned) ?? 0.0;
  }
}
