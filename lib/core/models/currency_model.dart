/// Tax information and localization configuration for a country/currency
class TaxInfo {
  final String name;
  final String shortName;
  final double rate; // Percentage
  final String? description;
  final List<double> presetRates;
  final String taxIdLabel;
  final String taxIdHint;
  final bool isDualTax;
  final String invoiceTitle;
  final String bankRoutingLabel;
  final String bankAccountLabel;

  const TaxInfo({
    required this.name,
    required this.shortName,
    required this.rate,
    this.description,
    this.presetRates = const [0.0, 5.0, 10.0, 18.0, 20.0],
    this.taxIdLabel = 'Tax ID',
    this.taxIdHint = 'e.g. 12-3456789',
    this.isDualTax = false,
    this.invoiceTitle = 'INVOICE',
    this.bankRoutingLabel = 'Routing / IFSC Code',
    this.bankAccountLabel = 'Account Number',
  });

  TaxInfo copyWith({
    String? name,
    String? shortName,
    double? rate,
    String? description,
    List<double>? presetRates,
    String? taxIdLabel,
    String? taxIdHint,
    bool? isDualTax,
    String? invoiceTitle,
    String? bankRoutingLabel,
    String? bankAccountLabel,
  }) {
    return TaxInfo(
      name: name ?? this.name,
      shortName: shortName ?? this.shortName,
      rate: rate ?? this.rate,
      description: description ?? this.description,
      presetRates: presetRates ?? this.presetRates,
      taxIdLabel: taxIdLabel ?? this.taxIdLabel,
      taxIdHint: taxIdHint ?? this.taxIdHint,
      isDualTax: isDualTax ?? this.isDualTax,
      invoiceTitle: invoiceTitle ?? this.invoiceTitle,
      bankRoutingLabel: bankRoutingLabel ?? this.bankRoutingLabel,
      bankAccountLabel: bankAccountLabel ?? this.bankAccountLabel,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'shortName': shortName,
        'rate': rate,
        'description': description,
        'presetRates': presetRates,
        'taxIdLabel': taxIdLabel,
        'taxIdHint': taxIdHint,
        'isDualTax': isDualTax,
        'invoiceTitle': invoiceTitle,
        'bankRoutingLabel': bankRoutingLabel,
        'bankAccountLabel': bankAccountLabel,
      };

  factory TaxInfo.fromJson(Map<String, dynamic> json) => TaxInfo(
        name: json['name'] as String? ?? 'Tax',
        shortName: json['shortName'] as String? ?? 'Tax',
        rate: (json['rate'] as num?)?.toDouble() ?? 0.0,
        description: json['description'] as String?,
        presetRates: (json['presetRates'] as List<dynamic>?)
                ?.map((e) => (e as num).toDouble())
                .toList() ??
            const [0.0, 5.0, 10.0, 18.0, 20.0],
        taxIdLabel: json['taxIdLabel'] as String? ?? 'Tax ID',
        taxIdHint: json['taxIdHint'] as String? ?? 'e.g. 12-3456789',
        isDualTax: json['isDualTax'] as bool? ?? false,
        invoiceTitle: json['invoiceTitle'] as String? ?? 'INVOICE',
        bankRoutingLabel:
            json['bankRoutingLabel'] as String? ?? 'Routing / IFSC Code',
        bankAccountLabel:
            json['bankAccountLabel'] as String? ?? 'Account Number',
      );
}

/// Currency model with country, tax, and regional properties
class Currency {
  final String code;
  final String name;
  final String symbol;
  final String flag;
  final String countryName;
  final TaxInfo defaultTax;
  final int decimalPlaces;
  final String thousandSeparator;
  final String decimalSeparator;

  const Currency({
    required this.code,
    required this.name,
    required this.symbol,
    required this.flag,
    this.countryName = '',
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
        'countryName': countryName,
        'defaultTax': defaultTax.toJson(),
        'decimalPlaces': decimalPlaces,
        'thousandSeparator': thousandSeparator,
        'decimalSeparator': decimalSeparator,
      };

  factory Currency.fromJson(Map<String, dynamic> json) => Currency(
        code: json['code'] as String? ?? 'USD',
        name: json['name'] as String? ?? 'US Dollar',
        symbol: json['symbol'] as String? ?? '\$',
        flag: json['flag'] as String? ?? '🇺🇸',
        countryName: json['countryName'] as String? ?? '',
        defaultTax: json['defaultTax'] != null
            ? TaxInfo.fromJson(json['defaultTax'] as Map<String, dynamic>)
            : const TaxInfo(
                name: 'Sales Tax',
                shortName: 'Tax',
                rate: 0.0,
              ),
        decimalPlaces: json['decimalPlaces'] as int? ?? 2,
        thousandSeparator: json['thousandSeparator'] as String? ?? ',',
        decimalSeparator: json['decimalSeparator'] as String? ?? '.',
      );
}

/// Currencies with comprehensive, country-accurate tax & banking configurations
class SupportedCurrencies {
  SupportedCurrencies._();

  static const List<Currency> all = [
    // 1. United States
    Currency(
      code: 'USD',
      name: 'US Dollar',
      symbol: '\$',
      flag: '🇺🇸',
      countryName: 'United States',
      defaultTax: TaxInfo(
        name: 'Sales Tax',
        shortName: 'Sales Tax',
        rate: 8.875,
        description: 'Standard state & local combined sales tax',
        presetRates: [0.0, 5.0, 7.0, 8.875, 10.0],
        taxIdLabel: 'Tax ID / EIN',
        taxIdHint: '12-3456789',
        isDualTax: false,
        invoiceTitle: 'INVOICE',
        bankRoutingLabel: 'Routing Number (ABA)',
        bankAccountLabel: 'Account Number',
      ),
    ),

    // 2. India
    Currency(
      code: 'INR',
      name: 'Indian Rupee',
      symbol: '₹',
      flag: '🇮🇳',
      countryName: 'India',
      defaultTax: TaxInfo(
        name: 'Goods and Services Tax',
        shortName: 'GST',
        rate: 18.0,
        description: 'Standard dual GST system in India',
        presetRates: [0.0, 5.0, 12.0, 18.0, 28.0],
        taxIdLabel: 'GSTIN',
        taxIdHint: '22AAAAA0000A1Z5',
        isDualTax: true,
        invoiceTitle: 'TAX INVOICE',
        bankRoutingLabel: 'IFSC Code',
        bankAccountLabel: 'Account Number',
      ),
    ),

    // 3. United Kingdom
    Currency(
      code: 'GBP',
      name: 'British Pound',
      symbol: '£',
      flag: '🇬🇧',
      countryName: 'United Kingdom',
      defaultTax: TaxInfo(
        name: 'Value Added Tax',
        shortName: 'VAT',
        rate: 20.0,
        description: 'Standard UK VAT rate',
        presetRates: [0.0, 5.0, 20.0],
        taxIdLabel: 'VAT Reg No.',
        taxIdHint: 'GB123456789',
        isDualTax: false,
        invoiceTitle: 'TAX INVOICE',
        bankRoutingLabel: 'Sort Code',
        bankAccountLabel: 'Account Number',
      ),
    ),

    // 4. European Union (Euro)
    Currency(
      code: 'EUR',
      name: 'Euro',
      symbol: '€',
      flag: '🇪🇺',
      countryName: 'European Union',
      defaultTax: TaxInfo(
        name: 'Value Added Tax',
        shortName: 'VAT',
        rate: 20.0,
        description: 'Standard European VAT (MwSt / TVA / IVA)',
        presetRates: [0.0, 7.0, 10.0, 19.0, 20.0, 21.0],
        taxIdLabel: 'VAT ID / USt-IdNr.',
        taxIdHint: 'DE123456789',
        isDualTax: false,
        invoiceTitle: 'TAX INVOICE',
        bankRoutingLabel: 'BIC / SWIFT Code',
        bankAccountLabel: 'IBAN',
      ),
    ),

    // 5. Canada
    Currency(
      code: 'CAD',
      name: 'Canadian Dollar',
      symbol: 'C\$',
      flag: '🇨🇦',
      countryName: 'Canada',
      defaultTax: TaxInfo(
        name: 'Goods and Services Tax',
        shortName: 'GST/HST',
        rate: 5.0,
        description: 'Federal GST & Harmonized Sales Tax',
        presetRates: [0.0, 5.0, 13.0, 15.0],
        taxIdLabel: 'Business Number (BN)',
        taxIdHint: '123456789RT0001',
        isDualTax: false,
        invoiceTitle: 'INVOICE',
        bankRoutingLabel: 'Transit / Institution No.',
        bankAccountLabel: 'Account Number',
      ),
    ),

    // 6. Australia
    Currency(
      code: 'AUD',
      name: 'Australian Dollar',
      symbol: 'A\$',
      flag: '🇦🇺',
      countryName: 'Australia',
      defaultTax: TaxInfo(
        name: 'Goods and Services Tax',
        shortName: 'GST',
        rate: 10.0,
        description: 'Standard Australian GST',
        presetRates: [0.0, 10.0],
        taxIdLabel: 'ABN (Business No.)',
        taxIdHint: '12 345 678 901',
        isDualTax: false,
        invoiceTitle: 'TAX INVOICE',
        bankRoutingLabel: 'BSB Code',
        bankAccountLabel: 'Account Number',
      ),
    ),

    // 7. United Arab Emirates
    Currency(
      code: 'AED',
      name: 'UAE Dirham',
      symbol: 'د.إ',
      flag: '🇦🇪',
      countryName: 'United Arab Emirates',
      defaultTax: TaxInfo(
        name: 'Value Added Tax',
        shortName: 'VAT',
        rate: 5.0,
        description: 'UAE Federal Tax Authority standard VAT',
        presetRates: [0.0, 5.0],
        taxIdLabel: 'TRN (Tax Reg No.)',
        taxIdHint: '100XXXXXXXXX003',
        isDualTax: false,
        invoiceTitle: 'TAX INVOICE',
        bankRoutingLabel: 'SWIFT / BIC',
        bankAccountLabel: 'IBAN',
      ),
    ),

    // 8. Saudi Arabia
    Currency(
      code: 'SAR',
      name: 'Saudi Riyal',
      symbol: '﷼',
      flag: '🇸🇦',
      countryName: 'Saudi Arabia',
      defaultTax: TaxInfo(
        name: 'Value Added Tax',
        shortName: 'VAT',
        rate: 15.0,
        description: 'ZATCA standard VAT in Saudi Arabia',
        presetRates: [0.0, 15.0],
        taxIdLabel: 'VAT Reg No. / TRN',
        taxIdHint: '300XXXXXXXXX003',
        isDualTax: false,
        invoiceTitle: 'TAX INVOICE',
        bankRoutingLabel: 'SWIFT / BIC',
        bankAccountLabel: 'IBAN',
      ),
    ),

    // 9. Singapore
    Currency(
      code: 'SGD',
      name: 'Singapore Dollar',
      symbol: 'S\$',
      flag: '🇸🇬',
      countryName: 'Singapore',
      defaultTax: TaxInfo(
        name: 'Goods and Services Tax',
        shortName: 'GST',
        rate: 9.0,
        description: 'IRAS standard GST in Singapore',
        presetRates: [0.0, 9.0],
        taxIdLabel: 'UEN / GST Reg No.',
        taxIdHint: '201234567A',
        isDualTax: false,
        invoiceTitle: 'TAX INVOICE',
        bankRoutingLabel: 'Bank & Branch Code',
        bankAccountLabel: 'Account Number',
      ),
    ),

    // 10. Japan
    Currency(
      code: 'JPY',
      name: 'Japanese Yen',
      symbol: '¥',
      flag: '🇯🇵',
      countryName: 'Japan',
      defaultTax: TaxInfo(
        name: 'Consumption Tax',
        shortName: 'CT',
        rate: 10.0,
        description: 'Japan Qualified Invoice Consumption Tax',
        presetRates: [0.0, 8.0, 10.0],
        taxIdLabel: 'Invoice Reg No.',
        taxIdHint: 'T1234567890123',
        isDualTax: false,
        invoiceTitle: 'TAX INVOICE',
        bankRoutingLabel: 'Branch Code',
        bankAccountLabel: 'Account Number',
      ),
      decimalPlaces: 0,
    ),

    // 11. New Zealand
    Currency(
      code: 'NZD',
      name: 'New Zealand Dollar',
      symbol: 'NZ\$',
      flag: '🇳🇿',
      countryName: 'New Zealand',
      defaultTax: TaxInfo(
        name: 'Goods and Services Tax',
        shortName: 'GST',
        rate: 15.0,
        description: 'Inland Revenue standard GST',
        presetRates: [0.0, 15.0],
        taxIdLabel: 'GST / IRD Number',
        taxIdHint: '123-456-789',
        isDualTax: false,
        invoiceTitle: 'TAX INVOICE',
        bankRoutingLabel: 'Bank & Branch Code',
        bankAccountLabel: 'Account Number',
      ),
    ),

    // 12. Switzerland
    Currency(
      code: 'CHF',
      name: 'Swiss Franc',
      symbol: 'CHF',
      flag: '🇨🇭',
      countryName: 'Switzerland',
      defaultTax: TaxInfo(
        name: 'Value Added Tax',
        shortName: 'MWST / TVA',
        rate: 8.1,
        description: 'Swiss Federal Tax Administration standard rate',
        presetRates: [0.0, 2.6, 3.8, 8.1],
        taxIdLabel: 'UID (MWST-Nr.)',
        taxIdHint: 'CHE-123.456.789',
        isDualTax: false,
        invoiceTitle: 'TAX INVOICE',
        bankRoutingLabel: 'BIC / SWIFT',
        bankAccountLabel: 'IBAN',
      ),
    ),

    // 13. Malaysia
    Currency(
      code: 'MYR',
      name: 'Malaysian Ringgit',
      symbol: 'RM',
      flag: '🇲🇾',
      countryName: 'Malaysia',
      defaultTax: TaxInfo(
        name: 'Sales and Services Tax',
        shortName: 'SST',
        rate: 8.0,
        description: 'Royal Malaysian Customs SST rate',
        presetRates: [0.0, 6.0, 8.0],
        taxIdLabel: 'SST Reg No.',
        taxIdHint: 'W10-1808-12345678',
        isDualTax: false,
        invoiceTitle: 'INVOICE',
        bankRoutingLabel: 'Bank Code',
        bankAccountLabel: 'Account Number',
      ),
    ),

    // 14. South Africa
    Currency(
      code: 'ZAR',
      name: 'South African Rand',
      symbol: 'R',
      flag: '🇿🇦',
      countryName: 'South Africa',
      defaultTax: TaxInfo(
        name: 'Value Added Tax',
        shortName: 'VAT',
        rate: 15.0,
        description: 'SARS standard VAT rate',
        presetRates: [0.0, 15.0],
        taxIdLabel: 'VAT Number',
        taxIdHint: '4012345678',
        isDualTax: false,
        invoiceTitle: 'TAX INVOICE',
        bankRoutingLabel: 'Branch Code',
        bankAccountLabel: 'Account Number',
      ),
    ),

    // 15. Mexico
    Currency(
      code: 'MXN',
      name: 'Mexican Peso',
      symbol: '\$',
      flag: '🇲🇽',
      countryName: 'Mexico',
      defaultTax: TaxInfo(
        name: 'Impuesto al Valor Agregado',
        shortName: 'IVA',
        rate: 16.0,
        description: 'SAT standard IVA rate in Mexico',
        presetRates: [0.0, 8.0, 16.0],
        taxIdLabel: 'RFC (Tax ID)',
        taxIdHint: 'ABC120315HD1',
        isDualTax: false,
        invoiceTitle: 'FACTURA',
        bankRoutingLabel: 'CLABE',
        bankAccountLabel: 'Account Number',
      ),
    ),

    // 16. Brazil
    Currency(
      code: 'BRL',
      name: 'Brazilian Real',
      symbol: 'R\$',
      flag: '🇧🇷',
      countryName: 'Brazil',
      defaultTax: TaxInfo(
        name: 'Impostos (ICMS / ISS)',
        shortName: 'ICMS',
        rate: 18.0,
        description: 'Brazilian state consumption tax',
        presetRates: [0.0, 12.0, 18.0],
        taxIdLabel: 'CNPJ (Company ID)',
        taxIdHint: '00.000.000/0001-00',
        isDualTax: false,
        invoiceTitle: 'NOTA FISCAL',
        bankRoutingLabel: 'Agência',
        bankAccountLabel: 'Conta Corrente',
      ),
    ),

    // 17. Hong Kong (Zero Sales Tax)
    Currency(
      code: 'HKD',
      name: 'Hong Kong Dollar',
      symbol: 'HK\$',
      flag: '🇭🇰',
      countryName: 'Hong Kong',
      defaultTax: TaxInfo(
        name: 'No General Sales Tax',
        shortName: 'Tax Free',
        rate: 0.0,
        description: 'Hong Kong levies no VAT or GST',
        presetRates: [0.0],
        taxIdLabel: 'Business Reg No. (BRN)',
        taxIdHint: '12345678-000',
        isDualTax: false,
        invoiceTitle: 'INVOICE',
        bankRoutingLabel: 'Bank Code',
        bankAccountLabel: 'Account Number',
      ),
    ),

    // 18. Thailand
    Currency(
      code: 'THB',
      name: 'Thai Baht',
      symbol: '฿',
      flag: '🇹🇭',
      countryName: 'Thailand',
      defaultTax: TaxInfo(
        name: 'Value Added Tax',
        shortName: 'VAT',
        rate: 7.0,
        description: 'Revenue Department standard VAT',
        presetRates: [0.0, 7.0],
        taxIdLabel: 'Tax ID (13 digits)',
        taxIdHint: '0105551234567',
        isDualTax: false,
        invoiceTitle: 'TAX INVOICE',
        bankRoutingLabel: 'Branch Code',
        bankAccountLabel: 'Account Number',
      ),
    ),

    // 19. Philippines
    Currency(
      code: 'PHP',
      name: 'Philippine Peso',
      symbol: '₱',
      flag: '🇵🇭',
      countryName: 'Philippines',
      defaultTax: TaxInfo(
        name: 'Value Added Tax',
        shortName: 'VAT',
        rate: 12.0,
        description: 'BIR standard VAT in the Philippines',
        presetRates: [0.0, 12.0],
        taxIdLabel: 'TIN (Tax ID No.)',
        taxIdHint: '123-456-789-000',
        isDualTax: false,
        invoiceTitle: 'TAX INVOICE',
        bankRoutingLabel: 'Bank Code',
        bankAccountLabel: 'Account Number',
      ),
    ),

    // 20. Indonesia
    Currency(
      code: 'IDR',
      name: 'Indonesian Rupiah',
      symbol: 'Rp',
      flag: '🇮🇩',
      countryName: 'Indonesia',
      defaultTax: TaxInfo(
        name: 'Pajak Pertambahan Nilai',
        shortName: 'PPN (VAT)',
        rate: 11.0,
        description: 'Standard Indonesian PPN rate',
        presetRates: [0.0, 11.0, 12.0],
        taxIdLabel: 'NPWP (Tax ID)',
        taxIdHint: '01.234.567.8-901.000',
        isDualTax: false,
        invoiceTitle: 'FAKTUR PAJAK',
        bankRoutingLabel: 'Kode Bank',
        bankAccountLabel: 'Nomor Rekening',
      ),
      decimalPlaces: 0,
    ),

    // 21. Vietnam
    Currency(
      code: 'VND',
      name: 'Vietnamese Dong',
      symbol: '₫',
      flag: '🇻🇳',
      countryName: 'Vietnam',
      defaultTax: TaxInfo(
        name: 'Value Added Tax',
        shortName: 'VAT',
        rate: 10.0,
        description: 'Standard Vietnamese VAT rate',
        presetRates: [0.0, 8.0, 10.0],
        taxIdLabel: 'Mã số thuế (Tax Code)',
        taxIdHint: '0101234567',
        isDualTax: false,
        invoiceTitle: 'HÓA ĐƠN GTGT',
        bankRoutingLabel: 'Chi nhánh',
        bankAccountLabel: 'Số tài khoản',
      ),
      decimalPlaces: 0,
    ),

    // 22. South Korea
    Currency(
      code: 'KRW',
      name: 'South Korean Won',
      symbol: '₩',
      flag: '🇰🇷',
      countryName: 'South Korea',
      defaultTax: TaxInfo(
        name: 'Value Added Tax',
        shortName: 'VAT',
        rate: 10.0,
        description: 'NTS standard VAT in South Korea',
        presetRates: [0.0, 10.0],
        taxIdLabel: 'Business Reg No. (BRN)',
        taxIdHint: '123-45-67890',
        isDualTax: false,
        invoiceTitle: 'TAX INVOICE',
        bankRoutingLabel: 'Bank Code',
        bankAccountLabel: 'Account Number',
      ),
      decimalPlaces: 0,
    ),

    // 23. China
    Currency(
      code: 'CNY',
      name: 'Chinese Yuan',
      symbol: '¥',
      flag: '🇨🇳',
      countryName: 'China',
      defaultTax: TaxInfo(
        name: 'Value Added Tax',
        shortName: 'VAT',
        rate: 13.0,
        description: 'Standard Chinese VAT rate',
        presetRates: [0.0, 6.0, 9.0, 13.0],
        taxIdLabel: 'Unified Social Credit Code',
        taxIdHint: '91110000123456789X',
        isDualTax: false,
        invoiceTitle: 'FA PIAO',
        bankRoutingLabel: 'Bank Code',
        bankAccountLabel: 'Account Number',
      ),
    ),

    // 24. Nigeria
    Currency(
      code: 'NGN',
      name: 'Nigerian Naira',
      symbol: '₦',
      flag: '🇳🇬',
      countryName: 'Nigeria',
      defaultTax: TaxInfo(
        name: 'Value Added Tax',
        shortName: 'VAT',
        rate: 7.5,
        description: 'FIRS standard VAT in Nigeria',
        presetRates: [0.0, 7.5],
        taxIdLabel: 'TIN (Tax ID No.)',
        taxIdHint: '12345678-0001',
        isDualTax: false,
        invoiceTitle: 'TAX INVOICE',
        bankRoutingLabel: 'Sort Code',
        bankAccountLabel: 'Account Number',
      ),
    ),

    // 25. Kenya
    Currency(
      code: 'KES',
      name: 'Kenyan Shilling',
      symbol: 'KSh',
      flag: '🇰🇪',
      countryName: 'Kenya',
      defaultTax: TaxInfo(
        name: 'Value Added Tax',
        shortName: 'VAT',
        rate: 16.0,
        description: 'KRA standard VAT in Kenya',
        presetRates: [0.0, 16.0],
        taxIdLabel: 'KRA PIN',
        taxIdHint: 'P051234567Z',
        isDualTax: false,
        invoiceTitle: 'TAX INVOICE',
        bankRoutingLabel: 'Bank Code',
        bankAccountLabel: 'Account Number',
      ),
    ),

    // 26. Pakistan
    Currency(
      code: 'PKR',
      name: 'Pakistani Rupee',
      symbol: '₨',
      flag: '🇵🇰',
      countryName: 'Pakistan',
      defaultTax: TaxInfo(
        name: 'Sales Tax',
        shortName: 'Sales Tax',
        rate: 18.0,
        description: 'FBR standard sales tax in Pakistan',
        presetRates: [0.0, 18.0],
        taxIdLabel: 'STRN / NTN',
        taxIdHint: '1234567-8',
        isDualTax: false,
        invoiceTitle: 'SALES TAX INVOICE',
        bankRoutingLabel: 'Bank Branch Code',
        bankAccountLabel: 'Account Number',
      ),
    ),

    // 27. Bangladesh
    Currency(
      code: 'BDT',
      name: 'Bangladeshi Taka',
      symbol: '৳',
      flag: '🇧🇩',
      countryName: 'Bangladesh',
      defaultTax: TaxInfo(
        name: 'Value Added Tax (Mushak)',
        shortName: 'VAT',
        rate: 15.0,
        description: 'NBR standard VAT in Bangladesh',
        presetRates: [0.0, 5.0, 10.0, 15.0],
        taxIdLabel: 'BIN / VAT Reg No.',
        taxIdHint: '001234567-0101',
        isDualTax: false,
        invoiceTitle: 'MUSHAK 6.3 INVOICE',
        bankRoutingLabel: 'Routing Number',
        bankAccountLabel: 'Account Number',
      ),
    ),

    // 28. Poland
    Currency(
      code: 'PLN',
      name: 'Polish Zloty',
      symbol: 'zł',
      flag: '🇵🇱',
      countryName: 'Poland',
      defaultTax: TaxInfo(
        name: 'Podatek od Towarów i Usług',
        shortName: 'VAT / PTU',
        rate: 23.0,
        description: 'Standard Polish VAT rate',
        presetRates: [0.0, 5.0, 8.0, 23.0],
        taxIdLabel: 'NIP (Tax ID)',
        taxIdHint: '1234567890',
        isDualTax: false,
        invoiceTitle: 'FAKTURA VAT',
        bankRoutingLabel: 'BIC / SWIFT',
        bankAccountLabel: 'Numer Konta (IBAN)',
      ),
    ),

    // 29. Sweden
    Currency(
      code: 'SEK',
      name: 'Swedish Krona',
      symbol: 'kr',
      flag: '🇸🇪',
      countryName: 'Sweden',
      defaultTax: TaxInfo(
        name: 'Mervärdesskatt (Moms)',
        shortName: 'Moms / VAT',
        rate: 25.0,
        description: 'Skatteverket standard Moms rate',
        presetRates: [0.0, 6.0, 12.0, 25.0],
        taxIdLabel: 'Org.nr / Momsnr',
        taxIdHint: 'SE123456789001',
        isDualTax: false,
        invoiceTitle: 'FAKTURA',
        bankRoutingLabel: 'Bankgiro / Plusgiro',
        bankAccountLabel: 'Kontonummer',
      ),
    ),

    // 30. Norway
    Currency(
      code: 'NOK',
      name: 'Norwegian Krone',
      symbol: 'kr',
      flag: '🇳🇴',
      countryName: 'Norway',
      defaultTax: TaxInfo(
        name: 'Merverdiavgift (MVA)',
        shortName: 'MVA',
        rate: 25.0,
        description: 'Skatteetaten standard MVA rate',
        presetRates: [0.0, 12.0, 15.0, 25.0],
        taxIdLabel: 'Org.nr MVA',
        taxIdHint: 'NO 123 456 789 MVA',
        isDualTax: false,
        invoiceTitle: 'FAKTURA',
        bankRoutingLabel: 'BIC / SWIFT',
        bankAccountLabel: 'Kontonummer',
      ),
    ),

    // 31. Denmark
    Currency(
      code: 'DKK',
      name: 'Danish Krone',
      symbol: 'kr',
      flag: '🇩🇰',
      countryName: 'Denmark',
      defaultTax: TaxInfo(
        name: 'Merværdiafgift (Moms)',
        shortName: 'Moms',
        rate: 25.0,
        description: 'Skattestyrelsen standard Moms rate',
        presetRates: [0.0, 25.0],
        taxIdLabel: 'CVR-nummer',
        taxIdHint: 'DK 12 34 56 78',
        isDualTax: false,
        invoiceTitle: 'FAKTURA',
        bankRoutingLabel: 'Reg.nr',
        bankAccountLabel: 'Kontonummer',
      ),
    ),

    // 32. Qatar
    Currency(
      code: 'QAR',
      name: 'Qatari Riyal',
      symbol: '﷼',
      flag: '🇶🇦',
      countryName: 'Qatar',
      defaultTax: TaxInfo(
        name: 'Value Added Tax',
        shortName: 'VAT',
        rate: 5.0,
        description: 'General Tax Authority VAT in Qatar',
        presetRates: [0.0, 5.0],
        taxIdLabel: 'Tax Card / TIN',
        taxIdHint: '1234567890',
        isDualTax: false,
        invoiceTitle: 'TAX INVOICE',
        bankRoutingLabel: 'SWIFT / BIC',
        bankAccountLabel: 'IBAN',
      ),
    ),

    // 33. Kuwait (Zero Tax)
    Currency(
      code: 'KWD',
      name: 'Kuwaiti Dinar',
      symbol: 'د.ك',
      flag: '🇰🇼',
      countryName: 'Kuwait',
      defaultTax: TaxInfo(
        name: 'No General Sales Tax',
        shortName: 'Tax Free',
        rate: 0.0,
        description: 'Kuwait levies no VAT or GST',
        presetRates: [0.0],
        taxIdLabel: 'Civil / Commercial Reg No.',
        taxIdHint: '12345678',
        isDualTax: false,
        invoiceTitle: 'INVOICE',
        bankRoutingLabel: 'SWIFT / BIC',
        bankAccountLabel: 'IBAN',
      ),
      decimalPlaces: 3,
    ),

    // 34. Bahrain
    Currency(
      code: 'BHD',
      name: 'Bahraini Dinar',
      symbol: '.د.ب',
      flag: '🇧🇭',
      countryName: 'Bahrain',
      defaultTax: TaxInfo(
        name: 'Value Added Tax',
        shortName: 'VAT',
        rate: 10.0,
        description: 'NBR standard VAT rate in Bahrain',
        presetRates: [0.0, 10.0],
        taxIdLabel: 'VAT Account No.',
        taxIdHint: '200001234500002',
        isDualTax: false,
        invoiceTitle: 'TAX INVOICE',
        bankRoutingLabel: 'SWIFT / BIC',
        bankAccountLabel: 'IBAN',
      ),
      decimalPlaces: 3,
    ),

    // 35. Taiwan
    Currency(
      code: 'TWD',
      name: 'Taiwan Dollar',
      symbol: 'NT\$',
      flag: '🇹🇼',
      countryName: 'Taiwan',
      defaultTax: TaxInfo(
        name: 'Value Added Tax',
        shortName: 'VAT',
        rate: 5.0,
        description: 'National Taxation Bureau standard VAT',
        presetRates: [0.0, 5.0],
        taxIdLabel: 'Unified Business No. (UBN)',
        taxIdHint: '12345678',
        isDualTax: false,
        invoiceTitle: 'UNIFORM INVOICE',
        bankRoutingLabel: 'Bank Code',
        bankAccountLabel: 'Account Number',
      ),
    ),
  ];

  /// Get currency by code
  static Currency? getByCode(String code) {
    try {
      return all.firstWhere((c) => c.code.toUpperCase() == code.toUpperCase());
    } catch (_) {
      return null;
    }
  }

  /// Get popular currencies (top 8)
  static List<Currency> get popular => [
        getByCode('USD')!,
        getByCode('INR')!,
        getByCode('GBP')!,
        getByCode('EUR')!,
        getByCode('CAD')!,
        getByCode('AUD')!,
        getByCode('AED')!,
        getByCode('SGD')!,
      ];

  /// Search currencies by country name, currency name, or currency code
  static List<Currency> search(String query) {
    final lowerQuery = query.toLowerCase().trim();
    if (lowerQuery.isEmpty) return all;
    return all
        .where((c) =>
            c.name.toLowerCase().contains(lowerQuery) ||
            c.code.toLowerCase().contains(lowerQuery) ||
            c.countryName.toLowerCase().contains(lowerQuery))
        .toList();
  }
}
