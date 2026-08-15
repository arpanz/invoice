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

/// Provider to manage currency, country, tax, and regional state throughout the app
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

  // Convenient country & tax getters
  String get currencySymbol => _selectedCurrency.symbol;
  String get currencyCode => _selectedCurrency.code;
  String get countryName => _selectedCurrency.countryName;
  String get flag => _selectedCurrency.flag;
  int get decimalPlaces => _selectedCurrency.decimalPlaces;
  bool get isDualTax => _selectedCurrency.defaultTax.isDualTax;
  String get taxIdLabel => _selectedCurrency.defaultTax.taxIdLabel;
  String get taxIdHint => _selectedCurrency.defaultTax.taxIdHint;
  String get invoiceTitle => _selectedCurrency.defaultTax.invoiceTitle;
  String get bankRoutingLabel => _selectedCurrency.defaultTax.bankRoutingLabel;
  String get bankAccountLabel => _selectedCurrency.defaultTax.bankAccountLabel;
  List<double> get presetTaxRates => _selectedCurrency.defaultTax.presetRates;

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
          final parsed = Currency.fromJson(currencyData);
          // Look up latest country metadata definition for the currency code if available
          final full = SupportedCurrencies.getByCode(parsed.code);
          _selectedCurrency = full ?? parsed;
        } catch (_) {
          _selectedCurrency = SupportedCurrencies.all.first;
        }
      } else {
        _selectedCurrency = SupportedCurrencies.all.first;
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
    // Ensure we have the full static definition with rich tax properties
    final full = SupportedCurrencies.getByCode(currency.code) ?? currency;
    _selectedCurrency = full;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        CurrencyPreferences._currencyKey,
        jsonEncode(full.toJson()),
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

  /// Get default tax info with custom override if present
  TaxInfo get defaultTax {
    final base = _selectedCurrency.defaultTax;
    return base.copyWith(
      rate: _customTaxRate ?? base.rate,
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

  /// Format amount with compact notation (L/Cr for INR, K/M/B for international)
  String formatAmountCompact(double amount) {
    final isINR = _selectedCurrency.code == 'INR';
    final symbol = _selectedCurrency.symbol;

    if (isINR) {
      if (amount >= 10000000) {
        return '$symbol${(amount / 10000000).toStringAsFixed(2)}Cr';
      } else if (amount >= 100000) {
        return '$symbol${(amount / 100000).toStringAsFixed(2)}L';
      } else if (amount >= 1000) {
        return '$symbol${(amount / 1000).toStringAsFixed(1)}K';
      }
    } else {
      if (amount >= 1000000000) {
        return '$symbol${(amount / 1000000000).toStringAsFixed(2)}B';
      } else if (amount >= 1000000) {
        return '$symbol${(amount / 1000000).toStringAsFixed(2)}M';
      } else if (amount >= 1000) {
        return '$symbol${(amount / 1000).toStringAsFixed(1)}K';
      }
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
      case 'NZD':
      case 'PHP':
      case 'MYR':
      case 'ZAR':
      case 'NGN':
      case 'KES':
        return 'en_US';
      case 'EUR':
        return 'de_DE';
      case 'JPY':
        return 'ja_JP';
      case 'CNY':
        return 'zh_CN';
      case 'KRW':
        return 'ko_KR';
      case 'BRL':
        return 'pt_BR';
      case 'MXN':
        return 'es_MX';
      case 'THB':
        return 'th_TH';
      case 'IDR':
        return 'id_ID';
      case 'VND':
        return 'vi_VN';
      case 'PLN':
        return 'pl_PL';
      case 'SEK':
        return 'sv_SE';
      case 'NOK':
        return 'nb_NO';
      case 'DKK':
        return 'da_DK';
      case 'CHF':
        return 'de_CH';
      case 'AED':
      case 'SAR':
      case 'QAR':
      case 'KWD':
      case 'BHD':
        return 'en_US';
      default:
        return 'en_US';
    }
  }
}
