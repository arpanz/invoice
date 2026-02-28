import 'package:intl/intl.dart';

class CurrencyFormatter {
  CurrencyFormatter._();

  static String format(double amount, {String currencySymbol = '₹'}) {
    final formatter = NumberFormat('#,##,##0.00', 'en_IN');
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

  static String getCurrencySymbol(String currency) {
    switch (currency) {
      case 'INR':
        return '₹';
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      case 'AED':
        return 'AED ';
      default:
        return '₹';
    }
  }

  static double parseAmount(String value) {
    final cleaned = value.replaceAll(RegExp(r'[^\d.]'), '');
    return double.tryParse(cleaned) ?? 0.0;
  }
}
