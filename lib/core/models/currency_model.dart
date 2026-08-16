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
  final String bankNameHint;
  final String bankAccountHint;
  final String bankRoutingHint;
  final String digitalPaymentLabel;
  final String digitalPaymentHint;

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
    this.bankNameHint = 'e.g. Chase Bank / Barclays / HDFC',
    this.bankAccountHint = 'e.g. 1234567890',
    this.bankRoutingHint = 'e.g. 021000021 / SBIN0001234',
    this.digitalPaymentLabel = 'UPI / Payment Handle',
    this.digitalPaymentHint = 'e.g. business@upi or paypal.me/handle',
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
    String? bankNameHint,
    String? bankAccountHint,
    String? bankRoutingHint,
    String? digitalPaymentLabel,
    String? digitalPaymentHint,
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
      bankNameHint: bankNameHint ?? this.bankNameHint,
      bankAccountHint: bankAccountHint ?? this.bankAccountHint,
      bankRoutingHint: bankRoutingHint ?? this.bankRoutingHint,
      digitalPaymentLabel: digitalPaymentLabel ?? this.digitalPaymentLabel,
      digitalPaymentHint: digitalPaymentHint ?? this.digitalPaymentHint,
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
        'bankNameHint': bankNameHint,
        'bankAccountHint': bankAccountHint,
        'bankRoutingHint': bankRoutingHint,
        'digitalPaymentLabel': digitalPaymentLabel,
        'digitalPaymentHint': digitalPaymentHint,
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
        bankNameHint: json['bankNameHint'] as String? ??
            'e.g. Chase Bank / Barclays / HDFC',
        bankAccountHint:
            json['bankAccountHint'] as String? ?? 'e.g. 1234567890',
        bankRoutingHint: json['bankRoutingHint'] as String? ??
            'e.g. 021000021 / SBIN0001234',
        digitalPaymentLabel: json['digitalPaymentLabel'] as String? ??
            'UPI / Payment Handle',
        digitalPaymentHint: json['digitalPaymentHint'] as String? ??
            'e.g. business@upi or paypal.me/handle',
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
        bankNameHint: 'e.g. JPMorgan Chase / Wells Fargo / Bank of America',
        bankAccountHint: 'e.g. 1234567890',
        bankRoutingHint: 'e.g. 021000021 (9-digit ABA)',
        digitalPaymentLabel: 'Zelle / Venmo / PayPal Handle',
        digitalPaymentHint: 'e.g. payments@company.com or @username',
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
        bankNameHint: 'e.g. State Bank of India / HDFC Bank / ICICI',
        bankAccountHint: 'e.g. 50100234567890',
        bankRoutingHint: 'e.g. HDFC0000123 / SBIN0001234',
        digitalPaymentLabel: 'UPI ID / VPA',
        digitalPaymentHint: 'e.g. company@okhdfcbank or 9876543210@upi',
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
        bankNameHint: 'e.g. Barclays / HSBC UK / Lloyds Bank',
        bankAccountHint: 'e.g. 12345678 (8 digits)',
        bankRoutingHint: 'e.g. 20-00-00 (6 digits)',
        digitalPaymentLabel: 'Paym / Faster Payments ID',
        digitalPaymentHint: 'e.g. payments@company.co.uk',
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
        bankNameHint: 'e.g. Deutsche Bank / BNP Paribas / Santander',
        bankAccountHint: 'e.g. DE89 3704 0044 0532 0130 00',
        bankRoutingHint: 'e.g. DBKDEFFXXX (8-11 characters)',
        digitalPaymentLabel: 'SEPA / PayPal / Bizum Handle',
        digitalPaymentHint: 'e.g. paypal.me/company or SEPA ID',
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
        bankRoutingLabel: 'Transit & Institution No.',
        bankAccountLabel: 'Account Number',
        bankNameHint: 'e.g. RBC Royal Bank / TD Canada Trust / BMO',
        bankAccountHint: 'e.g. 1234567',
        bankRoutingHint: 'e.g. 12345-001 (Transit-Inst)',
        digitalPaymentLabel: 'Interac e-Transfer Handle',
        digitalPaymentHint: 'e.g. payments@company.ca',
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
        bankNameHint: 'e.g. Commonwealth Bank / ANZ / Westpac / NAB',
        bankAccountHint: 'e.g. 1234 5678',
        bankRoutingHint: 'e.g. 062-000 (6 digits)',
        digitalPaymentLabel: 'PayID / Osko Handle',
        digitalPaymentHint: 'e.g. payments@company.com.au or 0400123456',
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
        bankNameHint: 'e.g. Emirates NBD / First Abu Dhabi Bank (FAB)',
        bankAccountHint: 'e.g. AE07 0331 2345 6789 0123 45',
        bankRoutingHint: 'e.g. EBILAEADXXX',
        digitalPaymentLabel: 'Aani / Instant Pay Handle',
        digitalPaymentHint: 'e.g. 0501234567 or @company',
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
        bankNameHint: 'e.g. Al Rajhi Bank / Saudi National Bank (SNB)',
        bankAccountHint: 'e.g. SA03 8000 0000 6080 1016 7519',
        bankRoutingHint: 'e.g. RJHISA22XXX',
        digitalPaymentLabel: 'Sarie / STC Pay Handle',
        digitalPaymentHint: 'e.g. 0501234567 or payments@company.sa',
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
        bankNameHint: 'e.g. DBS Bank / OCBC / UOB',
        bankAccountHint: 'e.g. 123-45678-9',
        bankRoutingHint: 'e.g. 7171-001 (DBS)',
        digitalPaymentLabel: 'PayNow (UEN / Mobile)',
        digitalPaymentHint: 'e.g. 201234567A or +6591234567',
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
        bankRoutingLabel: 'Branch Code & Name',
        bankAccountLabel: 'Account Number',
        bankNameHint: 'e.g. Mitsubishi UFJ (MUFG) / SMBC / Mizuho',
        bankAccountHint: 'e.g. 1234567 (Futsu)',
        bankRoutingHint: 'e.g. 001 (Shinjuku Branch)',
        digitalPaymentLabel: 'PayPay / Line Pay Handle',
        digitalPaymentHint: 'e.g. payments@company.jp',
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
        bankNameHint: 'e.g. ANZ New Zealand / ASB Bank / BNZ',
        bankAccountHint: 'e.g. 01-0123-0123456-00',
        bankRoutingHint: 'e.g. 01-0123 (6 digits)',
        digitalPaymentLabel: 'Online Payment Link / Handle',
        digitalPaymentHint: 'e.g. payments@company.co.nz',
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
        bankAccountLabel: 'IBAN / QR-IBAN',
        bankNameHint: 'e.g. UBS / Credit Suisse / ZKB',
        bankAccountHint: 'e.g. CH93 0076 2011 6238 5295 7',
        bankRoutingHint: 'e.g. UBSWCHZHXXX',
        digitalPaymentLabel: 'TWINT / QR-Bill Handle',
        digitalPaymentHint: 'e.g. +41 79 123 45 67 or @company',
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
        bankRoutingLabel: 'Bank Code / SWIFT',
        bankAccountLabel: 'Account Number',
        bankNameHint: 'e.g. Maybank / CIMB Bank / Public Bank',
        bankAccountHint: 'e.g. 5140 1234 5678',
        bankRoutingHint: 'e.g. MBBEMYKL',
        digitalPaymentLabel: 'DuitNow (ID / Business Reg)',
        digitalPaymentHint: 'e.g. 201234567A or 0123456789',
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
        bankNameHint: 'e.g. Standard Bank / FNB / Absa / Nedbank',
        bankAccountHint: 'e.g. 123456789',
        bankRoutingHint: 'e.g. 051001 (FNB Universal)',
        digitalPaymentLabel: 'SnapScan / PayShap / Zapper',
        digitalPaymentHint: 'e.g. 0821234567 or @shapid',
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
        bankRoutingLabel: 'CLABE (18 digits)',
        bankAccountLabel: 'Número de Cuenta',
        bankNameHint: 'e.g. BBVA México / Banorte / Santander México',
        bankAccountHint: 'e.g. 1234567890',
        bankRoutingHint: 'e.g. 012 180 00123456789 0',
        digitalPaymentLabel: 'CoDi / Dimo / SPEI Handle',
        digitalPaymentHint: 'e.g. 5512345678 or rfc@empresa.com',
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
        bankRoutingLabel: 'Agência & Código do Banco',
        bankAccountLabel: 'Conta Corrente',
        bankNameHint: 'e.g. Itaú Unibanco / Bradesco / Banco do Brasil',
        bankAccountHint: 'e.g. 12345-6',
        bankRoutingHint: 'e.g. 0341 (Itaú) / Ag. 1234',
        digitalPaymentLabel: 'Chave Pix (CNPJ / Email / Telefone)',
        digitalPaymentHint:
            'e.g. 00.000.000/0001-00 ou pix@empresa.com.br',
      ),
    ),

    // 17. Hong Kong
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
        bankRoutingLabel: 'Bank Code & Branch',
        bankAccountLabel: 'Account Number',
        bankNameHint: 'e.g. HSBC / Standard Chartered / Hang Seng Bank',
        bankAccountHint: 'e.g. 123-456789-001',
        bankRoutingHint: 'e.g. 004-123 (HSBC)',
        digitalPaymentLabel: 'FPS ID (Faster Payment System)',
        digitalPaymentHint: 'e.g. 1234567 or payments@company.hk',
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
        bankNameHint: 'e.g. Bangkok Bank / Kasikornbank (KBank) / SCB',
        bankAccountHint: 'e.g. 123-4-56789-0',
        bankRoutingHint: 'e.g. 0001',
        digitalPaymentLabel: 'PromptPay (Tax ID / Mobile)',
        digitalPaymentHint: 'e.g. 0105551234567 or 0812345678',
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
        bankRoutingLabel: 'Bank Code / BRSTN',
        bankAccountLabel: 'Account Number',
        bankNameHint: 'e.g. BDO Unibank / BPI / Metrobank',
        bankAccountHint: 'e.g. 1234 5678 9012',
        bankRoutingHint: 'e.g. 010530667',
        digitalPaymentLabel: 'GCash / Maya QR / InstaPay',
        digitalPaymentHint: 'e.g. 09171234567 or @company',
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
        bankNameHint: 'e.g. Bank Central Asia (BCA) / Mandiri / BRI',
        bankAccountHint: 'e.g. 1234567890',
        bankRoutingHint: 'e.g. 014 (BCA)',
        digitalPaymentLabel: 'QRIS / GoPay / OVO Handle',
        digitalPaymentHint: 'e.g. 081234567890 or payments@company.id',
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
        bankRoutingLabel: 'Chi nhánh / Mã Ngân hàng',
        bankAccountLabel: 'Số tài khoản',
        bankNameHint: 'e.g. Vietcombank / Techcombank / BIDV',
        bankAccountHint: 'e.g. 0011001234567',
        bankRoutingHint: 'e.g. Chi nhánh Ba Đình',
        digitalPaymentLabel: 'VietQR / MoMo / ZaloPay Handle',
        digitalPaymentHint: 'e.g. 0912345678 or @company',
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
        bankNameHint: 'e.g. KB Kookmin Bank / Shinhan / Hana Bank',
        bankAccountHint: 'e.g. 123-456-789012',
        bankRoutingHint: 'e.g. 004 (KB)',
        digitalPaymentLabel: 'KakaoPay / Toss Handle',
        digitalPaymentHint: 'e.g. 010-1234-5678',
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
        bankRoutingLabel: 'Bank Code (CNAPS)',
        bankAccountLabel: 'Account Number',
        bankNameHint: 'e.g. ICBC / China Construction Bank / Bank of China',
        bankAccountHint: 'e.g. 6222 0212 3456 7890',
        bankRoutingHint: 'e.g. 102100000010',
        digitalPaymentLabel: 'Alipay / WeChat Pay Handle',
        digitalPaymentHint: 'e.g. payments@company.cn or 13800138000',
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
        bankRoutingLabel: 'Sort Code / Bank Code',
        bankAccountLabel: 'Account Number (NUBAN)',
        bankNameHint: 'e.g. Access Bank / Zenith Bank / GTBank',
        bankAccountHint: 'e.g. 0123456789 (10 digits)',
        bankRoutingHint: 'e.g. 058152010',
        digitalPaymentLabel: 'Payment Handle / Paystack',
        digitalPaymentHint: 'e.g. paystack.com/pay/mycompany',
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
        bankRoutingLabel: 'Bank Code / Branch',
        bankAccountLabel: 'Account Number',
        bankNameHint: 'e.g. KCB Bank / Equity Bank / NCBA',
        bankAccountHint: 'e.g. 1234567890',
        bankRoutingHint: 'e.g. 01100',
        digitalPaymentLabel: 'M-Pesa Paybill / Till Number',
        digitalPaymentHint: 'e.g. Paybill: 247247, Acc: 123456',
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
        bankAccountLabel: 'Account Number (IBAN)',
        bankNameHint: 'e.g. Habib Bank (HBL) / MCB / Meezan Bank',
        bankAccountHint: 'e.g. PK36MEZN0001234567890123',
        bankRoutingHint: 'e.g. 0123',
        digitalPaymentLabel: 'Raast ID / JazzCash / Easypaisa',
        digitalPaymentHint: 'e.g. 03001234567',
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
        bankRoutingLabel: 'Routing Number (9 digits)',
        bankAccountLabel: 'Account Number',
        bankNameHint: 'e.g. Sonali Bank / BRAC Bank / Dutch-Bangla',
        bankAccountHint: 'e.g. 1011234567890',
        bankRoutingHint: 'e.g. 060271234',
        digitalPaymentLabel: 'bKash / Nagad Merchant Number',
        digitalPaymentHint: 'e.g. 01712345678 (Personal / Merchant)',
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
        bankNameHint: 'e.g. PKO Bank Polski / Santander Polska / mBank',
        bankAccountHint: 'e.g. PL 12 1020 1026 0000 1234 5678 9012',
        bankRoutingHint: 'e.g. PKOPPLPW',
        digitalPaymentLabel: 'BLIK / Przelewy24 Handle',
        digitalPaymentHint: 'e.g. +48 500 123 456 lub email',
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
        bankRoutingLabel: 'Bankgiro / Plusgiro / Clearingnr',
        bankAccountLabel: 'Kontonummer',
        bankNameHint: 'e.g. Swedbank / SEB / Handelsbanken',
        bankAccountHint: 'e.g. 1234 567 890-1',
        bankRoutingHint: 'e.g. Bg 123-4567 eller Clearing 8105-9',
        digitalPaymentLabel: 'Swish Nummer (Företag)',
        digitalPaymentHint: 'e.g. 123 123 45 67',
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
        bankNameHint: 'e.g. DNB / Nordea Norge / SpareBank 1',
        bankAccountHint: 'e.g. 1234.56.78901',
        bankRoutingHint: 'e.g. DNBANOKK',
        digitalPaymentLabel: 'Vipps Nummer (Bedrift)',
        digitalPaymentHint: 'e.g. Vipps-nr: 12345',
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
        bankRoutingLabel: 'Reg.nr (4 digits)',
        bankAccountLabel: 'Kontonummer',
        bankNameHint: 'e.g. Danske Bank / Nordea Danmark / Jyske Bank',
        bankAccountHint: 'e.g. 1234567890',
        bankRoutingHint: 'e.g. 1234',
        digitalPaymentLabel: 'MobilePay Nummer',
        digitalPaymentHint: 'e.g. 12 34 56',
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
        bankNameHint: 'e.g. Qatar National Bank (QNB) / QIIB',
        bankAccountHint: 'e.g. QA53 QNBA 0000 0000 1234 5678 9012 3',
        bankRoutingHint: 'e.g. QNBAQAQA',
        digitalPaymentLabel: 'Fawran / Instant Pay Handle',
        digitalPaymentHint: 'e.g. 55123456 or @company',
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
        bankNameHint: 'e.g. National Bank of Kuwait (NBK) / KFH',
        bankAccountHint: 'e.g. KW12 NBOK 0000 0000 1234 5678 9012 34',
        bankRoutingHint: 'e.g. NBOKKWKW',
        digitalPaymentLabel: 'Wafey / KNET Link',
        digitalPaymentHint: 'e.g. payments@company.kw',
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
        bankNameHint: 'e.g. National Bank of Bahrain (NBB) / BBK',
        bankAccountHint: 'e.g. BH02 NBOB 0000 0000 1234 56',
        bankRoutingHint: 'e.g. NBOBBHBM',
        digitalPaymentLabel: 'BenefitPay (IBAN / Mobile)',
        digitalPaymentHint: 'e.g. 39123456 or @company',
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
        bankRoutingLabel: 'Bank Code (3 digits)',
        bankAccountLabel: 'Account Number',
        bankNameHint: 'e.g. Bank of Taiwan / CTBC Bank / Mega Bank',
        bankAccountHint: 'e.g. 0123-456-789012',
        bankRoutingHint: 'e.g. 004 (Bank of Taiwan)',
        digitalPaymentLabel: 'Taiwan Pay / Line Pay Handle',
        digitalPaymentHint: 'e.g. 0912345678 or @company',
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
