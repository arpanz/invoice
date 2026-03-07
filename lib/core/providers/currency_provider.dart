import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/currency_model.dart';

/// Keys for SharedPreferences
class CurrencyPreferences {
  static const String _currencyKey = 'user_currency';
  static const String _onboardingCompleteKey = 'onboarding_complete';
  static const String _customTaxRateKey = 'custom_default_tax_rate';
}

/// Provider to manage currency state throughout the app
class CurrencyProvider extends ChangeNotifier {
  Currency _selectedCurrency = SupportedCurrencies.all.first;
  bool _isLoading = true;
  bool _onboardingComplete = false;
  double? _customTaxRate;

  Currency get selectedCurrency => _selectedCurrency;
  bool get isLoading => _isLoading;
  bool get onboardingComplete => _onboardingComplete;
  double? get customTaxRate => _customTaxRate;
  bool get hasCustomTaxRate => _customTaxRate != null;

  CurrencyProvider() {
    _loadPreferences();
  }

  /// Load saved preferences
  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load currency
      final currencyJson = prefs.getString(CurrencyPreferences._currencyKey);
      if (currencyJson != null) {
        try {
          final currencyData = jsonDecode(currencyJson) as Map<String, dynamic>;
          _selectedCurrency = Currency.fromJson(currencyData);
        } catch (_) {
          // Use default if parsing fails
          _selectedCurrency = SupportedCurrencies.all.first;
        }
      }

      // Load onboarding status
      _onboardingComplete =
          prefs.getBool(CurrencyPreferences._onboardingCompleteKey) ?? false;

      // Load custom tax override (if any)
      _customTaxRate = prefs.getDouble(CurrencyPreferences._customTaxRateKey);
    } catch (e) {
      debugPrint('Error loading currency preferences: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Set the selected currency
  Future<void> setCurrency(Currency currency) async {
    _selectedCurrency = currency;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        CurrencyPreferences._currencyKey,
        jsonEncode(currency.toJson()),
      );
    } catch (e) {
      debugPrint('Error saving currency: $e');
    }
  }

  /// Mark onboarding as complete
  Future<void> completeOnboarding() async {
    _onboardingComplete = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(CurrencyPreferences._onboardingCompleteKey, true);
    } catch (e) {
      debugPrint('Error saving onboarding status: $e');
    }
  }

  /// Reset onboarding (for testing or settings)
  Future<void> resetOnboarding() async {
    _onboardingComplete = false;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(CurrencyPreferences._onboardingCompleteKey, false);
    } catch (e) {
      debugPrint('Error resetting onboarding: $e');
    }
  }

  /// Get currency symbol for display
  String get currencySymbol => _selectedCurrency.symbol;

  /// Get currency code for display
  String get currencyCode => _selectedCurrency.code;

  /// Get default tax info
  TaxInfo get defaultTax {
    final base = _selectedCurrency.defaultTax;
    return TaxInfo(
      name: base.name,
      shortName: base.shortName,
      rate: _customTaxRate ?? base.rate,
      description: base.description,
    );
  }

  /// Persist an editable default tax rate.
  Future<void> setCustomTaxRate(double rate) async {
    _customTaxRate = rate;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(CurrencyPreferences._customTaxRateKey, rate);
    } catch (e) {
      debugPrint('Error saving custom tax rate: $e');
    }
  }

  /// Remove custom tax override and return to currency default.
  Future<void> clearCustomTaxRate() async {
    _customTaxRate = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(CurrencyPreferences._customTaxRateKey);
    } catch (e) {
      debugPrint('Error clearing custom tax rate: $e');
    }
  }

  /// Format amount with selected currency
  String formatAmount(double amount) {
    final formatter = _getFormatter();
    final formatted = formatter.format(amount);
    return '${_selectedCurrency.symbol}$formatted';
  }

  /// Format amount with compact notation
  String formatAmountCompact(double amount) {
    if (amount >= 10000000) {
      return '${_selectedCurrency.symbol}${(amount / 10000000).toStringAsFixed(2)}Cr';
    } else if (amount >= 100000) {
      return '${_selectedCurrency.symbol}${(amount / 100000).toStringAsFixed(2)}L';
    } else if (amount >= 1000) {
      return '${_selectedCurrency.symbol}${(amount / 1000).toStringAsFixed(1)}K';
    }
    return formatAmount(amount);
  }

  NumberFormat _getFormatter() {
    final locale = _getLocaleForCurrency(_selectedCurrency.code);
    return NumberFormat.currency(
      symbol: '',
      decimalDigits: _selectedCurrency.decimalPlaces,
      locale: locale,
    );
  }

  String _getLocaleForCurrency(String code) {
    switch (code) {
      case 'INR':
        return 'en_IN';
      case 'USD':
      case 'GBP':
      case 'CAD':
      case 'AUD':
      case 'SGD':
      case 'HKD':
        return 'en_US';
      case 'EUR':
        return 'de_DE';
      case 'JPY':
      case 'CNY':
        return 'ja_JP';
      case 'KRW':
        return 'ko_KR';
      case 'BRL':
        return 'pt_BR';
      case 'RUB':
        return 'ru_RU';
      default:
        return 'en_US';
    }
  }
}
