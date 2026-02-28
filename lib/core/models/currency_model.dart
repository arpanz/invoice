/// Currency model with various properties including tax information
class Currency {
  final String code;
  final String name;
  final String symbol;
  final String flag;
  final TaxInfo defaultTax;
  final int decimalPlaces;
  final String thousandSeparator;
  final String decimalSeparator;

  const Currency({
    required this.code,
    required this.name,
    required this.symbol,
    required this.flag,
    required this.defaultTax,
    this.decimalPlaces = 2,
    this.thousandSeparator = ',',
    this.decimalSeparator = '.',
  });

  Map<String, dynamic> toJson() => {
        'code': code,
        'name': name,
        'symbol': symbol,
        'flag': flag,
        'defaultTax': defaultTax.toJson(),
        'decimalPlaces': decimalPlaces,
        'thousandSeparator': thousandSeparator,
        'decimalSeparator': decimalSeparator,
      };

  factory Currency.fromJson(Map<String, dynamic> json) => Currency(
        code: json['code'] as String,
        name: json['name'] as String,
        symbol: json['symbol'] as String,
        flag: json['flag'] as String,
        defaultTax: TaxInfo.fromJson(json['defaultTax'] as Map<String, dynamic>),
        decimalPlaces: json['decimalPlaces'] as int? ?? 2,
        thousandSeparator: json['thousandSeparator'] as String? ?? ',',
        decimalSeparator: json['decimalSeparator'] as String? ?? '.',
      );
}

/// Tax information for a currency
class TaxInfo {
  final String name;
  final String shortName;
  final double rate; // Percentage
  final String? description;

  const TaxInfo({
    required this.name,
    required this.shortName,
    required this.rate,
    this.description,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'shortName': shortName,
        'rate': rate,
        'description': description,
      };

  factory TaxInfo.fromJson(Map<String, dynamic> json) => TaxInfo(
        name: json['name'] as String,
        shortName: json['shortName'] as String,
        rate: (json['rate'] as num).toDouble(),
        description: json['description'] as String?,
      );
}

/// List of supported currencies with their properties
class SupportedCurrencies {
  SupportedCurrencies._();

  static const List<Currency> all = [
    // Asian Currencies
    Currency(
      code: 'INR',
      name: 'Indian Rupee',
      symbol: '₹',
      flag: '🇮🇳',
      defaultTax: TaxInfo(
        name: 'Goods and Services Tax',
        shortName: 'GST',
        rate: 18.0,
        description: 'Standard GST rate in India',
      ),
    ),
    Currency(
      code: 'USD',
      name: 'US Dollar',
      symbol: '\$',
      flag: '🇺🇸',
      defaultTax: TaxInfo(
        name: 'Sales Tax',
        shortName: 'Sales',
        rate: 8.875,
        description: 'NYC combined sales tax rate',
      ),
    ),
    Currency(
      code: 'GBP',
      name: 'British Pound',
      symbol: '£',
      flag: '🇬🇧',
      defaultTax: TaxInfo(
        name: 'Value Added Tax',
        shortName: 'VAT',
        rate: 20.0,
        description: 'Standard UK VAT rate',
      ),
    ),
    Currency(
      code: 'EUR',
      name: 'Euro',
      symbol: '€',
      flag: '🇪🇺',
      defaultTax: TaxInfo(
        name: 'Value Added Tax',
        shortName: 'VAT',
        rate: 21.0,
        description: 'Standard EU VAT rate',
      ),
    ),
    Currency(
      code: 'AED',
      name: 'UAE Dirham',
      symbol: 'د.إ',
      flag: '🇦🇪',
      defaultTax: TaxInfo(
        name: 'Value Added Tax',
        shortName: 'VAT',
        rate: 5.0,
        description: 'UAE VAT rate',
      ),
    ),
    Currency(
      code: 'SAR',
      name: 'Saudi Riyal',
      symbol: '﷼',
      flag: '🇸🇦',
      defaultTax: TaxInfo(
        name: 'Value Added Tax',
        shortName: 'VAT',
        rate: 15.0,
        description: 'Saudi Arabia VAT rate',
      ),
    ),
    Currency(
      code: 'SGD',
      name: 'Singapore Dollar',
      symbol: 'S\$',
      flag: '🇸🇬',
      defaultTax: TaxInfo(
        name: 'Goods and Services Tax',
        shortName: 'GST',
        rate: 9.0,
        description: 'Singapore GST rate',
      ),
    ),
    Currency(
      code: 'MYR',
      name: 'Malaysian Ringgit',
      symbol: 'RM',
      flag: '🇲🇾',
      defaultTax: TaxInfo(
        name: 'Sales and Services Tax',
        shortName: 'SST',
        rate: 6.0,
        description: 'Malaysia SST rate',
      ),
    ),
    Currency(
      code: 'THB',
      name: 'Thai Baht',
      symbol: '฿',
      flag: '🇹🇭',
      defaultTax: TaxInfo(
        name: 'Value Added Tax',
        shortName: 'VAT',
        rate: 7.0,
        description: 'Thailand VAT rate',
      ),
    ),
    Currency(
      code: 'JPY',
      name: 'Japanese Yen',
      symbol: '¥',
      flag: '🇯🇵',
      defaultTax: TaxInfo(
        name: 'Consumption Tax',
        shortName: 'CT',
        rate: 10.0,
        description: 'Japan consumption tax',
      ),
      decimalPlaces: 0,
    ),
    Currency(
      code: 'CNY',
      name: 'Chinese Yuan',
      symbol: '¥',
      flag: '🇨🇳',
      defaultTax: TaxInfo(
        name: 'Value Added Tax',
        shortName: 'VAT',
        rate: 13.0,
        description: 'China VAT rate',
      ),
    ),
    Currency(
      code: 'KRW',
      name: 'South Korean Won',
      symbol: '₩',
      flag: '🇰🇷',
      defaultTax: TaxInfo(
        name: 'Value Added Tax',
        shortName: 'VAT',
        rate: 10.0,
        description: 'South Korea VAT rate',
      ),
      decimalPlaces: 0,
    ),
    // European Currencies
    Currency(
      code: 'CHF',
      name: 'Swiss Franc',
      symbol: 'CHF',
      flag: '🇨🇭',
      defaultTax: TaxInfo(
        name: 'Value Added Tax',
        shortName: 'VAT',
        rate: 7.7,
        description: 'Switzerland VAT rate',
      ),
    ),
    Currency(
      code: 'SEK',
      name: 'Swedish Krona',
      symbol: 'kr',
      flag: '🇸🇪',
      defaultTax: TaxInfo(
        name: 'Value Added Tax',
        shortName: 'VAT',
        rate: 25.0,
        description: 'Sweden VAT rate',
      ),
    ),
    Currency(
      code: 'NOK',
      name: 'Norwegian Krone',
      symbol: 'kr',
      flag: '🇳🇴',
      defaultTax: TaxInfo(
        name: 'Value Added Tax',
        shortName: 'VAT',
        rate: 25.0,
        description: 'Norway VAT rate',
      ),
    ),
    Currency(
      code: 'DKK',
      name: 'Danish Krone',
      symbol: 'kr',
      flag: '🇩🇰',
      defaultTax: TaxInfo(
        name: 'Value Added Tax',
        shortName: 'VAT',
        rate: 25.0,
        description: 'Denmark VAT rate',
      ),
    ),
    // North American Currencies
    Currency(
      code: 'CAD',
      name: 'Canadian Dollar',
      symbol: 'C\$',
      flag: '🇨🇦',
      defaultTax: TaxInfo(
        name: 'Goods and Services Tax',
        shortName: 'GST',
        rate: 5.0,
        description: 'Canada federal GST',
      ),
    ),
    Currency(
      code: 'MXN',
      name: 'Mexican Peso',
      symbol: '\$',
      flag: '🇲🇽',
      defaultTax: TaxInfo(
        name: 'Impuesto al Valor Agregado',
        shortName: 'IVA',
        rate: 16.0,
        description: 'Mexico VAT rate',
      ),
    ),
    // Australian Currencies
    Currency(
      code: 'AUD',
      name: 'Australian Dollar',
      symbol: 'A\$',
      flag: '🇦🇺',
      defaultTax: TaxInfo(
        name: 'Goods and Services Tax',
        shortName: 'GST',
        rate: 10.0,
        description: 'Australia GST rate',
      ),
    ),
    Currency(
      code: 'NZD',
      name: 'New Zealand Dollar',
      symbol: 'NZ\$',
      flag: '🇳🇿',
      defaultTax: TaxInfo(
        name: 'Goods and Services Tax',
        shortName: 'GST',
        rate: 15.0,
        description: 'New Zealand GST rate',
      ),
    ),
    // Middle East
    Currency(
      code: 'QAR',
      name: 'Qatari Riyal',
      symbol: '﷼',
      flag: '🇶🇦',
      defaultTax: TaxInfo(
        name: 'Value Added Tax',
        shortName: 'VAT',
        rate: 5.0,
        description: 'Qatar VAT rate',
      ),
    ),
    Currency(
      code: 'KWD',
      name: 'Kuwaiti Dinar',
      symbol: 'د.ك',
      flag: '🇰🇼',
      defaultTax: TaxInfo(
        name: 'Value Added Tax',
        shortName: 'VAT',
        rate: 0.0,
        description: 'Kuwait has no VAT',
      ),
      decimalPlaces: 3,
    ),
    Currency(
      code: 'BHD',
      name: 'Bahraini Dinar',
      symbol: '.د.ب',
      flag: '🇧🇭',
      defaultTax: TaxInfo(
        name: 'Value Added Tax',
        shortName: 'VAT',
        rate: 0.0,
        description: 'Bahrain has no VAT',
      ),
      decimalPlaces: 3,
    ),
    // South Asian
    Currency(
      code: 'BDT',
      name: 'Bangladeshi Taka',
      symbol: '৳',
      flag: '🇧🇩',
      defaultTax: TaxInfo(
        name: 'Value Added Tax',
        shortName: 'VAT',
        rate: 15.0,
        description: 'Bangladesh VAT rate',
      ),
    ),
    Currency(
      code: 'PKR',
      name: 'Pakistani Rupee',
      symbol: '₨',
      flag: '🇵🇰',
      defaultTax: TaxInfo(
        name: 'Sales Tax',
        shortName: 'ST',
        rate: 18.0,
        description: 'Pakistan sales tax',
      ),
    ),
    // African Currencies
    Currency(
      code: 'ZAR',
      name: 'South African Rand',
      symbol: 'R',
      flag: '🇿🇦',
      defaultTax: TaxInfo(
        name: 'Value Added Tax',
        shortName: 'VAT',
        rate: 15.0,
        description: 'South Africa VAT rate',
      ),
    ),
    Currency(
      code: 'NGN',
      name: 'Nigerian Naira',
      symbol: '₦',
      flag: '🇳🇬',
      defaultTax: TaxInfo(
        name: 'Value Added Tax',
        shortName: 'VAT',
        rate: 7.5,
        description: 'Nigeria VAT rate',
      ),
    ),
    Currency(
      code: 'KES',
      name: 'Kenyan Shilling',
      symbol: 'KSh',
      flag: '🇰🇪',
      defaultTax: TaxInfo(
        name: 'Value Added Tax',
        shortName: 'VAT',
        rate: 16.0,
        description: 'Kenya VAT rate',
      ),
    ),
    // Other Popular
    Currency(
      code: 'HKD',
      name: 'Hong Kong Dollar',
      symbol: 'HK\$',
      flag: '🇭🇰',
      defaultTax: TaxInfo(
        name: 'Goods and Services Tax',
        shortName: 'GST',
        rate: 0.0,
        description: 'Hong Kong has no GST',
      ),
    ),
    Currency(
      code: 'TWD',
      name: 'Taiwan Dollar',
      symbol: 'NT\$',
      flag: '🇹🇼',
      defaultTax: TaxInfo(
        name: 'Value Added Tax',
        shortName: 'VAT',
        rate: 5.0,
        description: 'Taiwan VAT rate',
      ),
    ),
    Currency(
      code: 'PHP',
      name: 'Philippine Peso',
      symbol: '₱',
      flag: '🇵🇭',
      defaultTax: TaxInfo(
        name: 'Value Added Tax',
        shortName: 'VAT',
        rate: 12.0,
        description: 'Philippines VAT rate',
      ),
    ),
    Currency(
      code: 'IDR',
      name: 'Indonesian Rupiah',
      symbol: 'Rp',
      flag: '🇮🇩',
      defaultTax: TaxInfo(
        name: 'Value Added Tax',
        shortName: 'VAT',
        rate: 11.0,
        description: 'Indonesia VAT rate',
      ),
      decimalPlaces: 0,
    ),
    Currency(
      code: 'VND',
      name: 'Vietnamese Dong',
      symbol: '₫',
      flag: '🇻🇳',
      defaultTax: TaxInfo(
        name: 'Value Added Tax',
        shortName: 'VAT',
        rate: 10.0,
        description: 'Vietnam VAT rate',
      ),
      decimalPlaces: 0,
    ),
    Currency(
      code: 'PLN',
      name: 'Polish Zloty',
      symbol: 'zł',
      flag: '🇵🇱',
      defaultTax: TaxInfo(
        name: 'Value Added Tax',
        shortName: 'VAT',
        rate: 23.0,
        description: 'Poland VAT rate',
      ),
    ),
    Currency(
      code: 'BRL',
      name: 'Brazilian Real',
      symbol: 'R\$',
      flag: '🇧🇷',
      defaultTax: TaxInfo(
        name: 'Imposto sobre Circulação de Mercadorias',
        shortName: 'ICMS',
        rate: 18.0,
        description: 'Brazil ICMS average rate',
      ),
    ),
  ];

  /// Get currency by code
  static Currency? getByCode(String code) {
    try {
      return all.firstWhere((c) => c.code == code);
    } catch (_) {
      return null;
    }
  }

  /// Get popular currencies (first 8)
  static List<Currency> get popular => all.take(8).toList();

  /// Search currencies by name or code
  static List<Currency> search(String query) {
    final lowerQuery = query.toLowerCase();
    return all
        .where((c) =>
            c.name.toLowerCase().contains(lowerQuery) ||
            c.code.toLowerCase().contains(lowerQuery))
        .toList();
  }
}
