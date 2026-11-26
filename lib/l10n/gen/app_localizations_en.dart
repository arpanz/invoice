// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String invoiceCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString invoices',
      one: '1 invoice',
    );
    return '$_temp0';
  }

  @override
  String estimateCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString quotes',
      one: '1 quote',
    );
    return '$_temp0';
  }

  @override
  String clientCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString clients',
      one: '1 client',
    );
    return '$_temp0';
  }

  @override
  String savedItemCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString saved items',
      one: '1 saved item',
    );
    return '$_temp0';
  }

  @override
  String addedItemCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString items added',
      one: '1 item added',
    );
    return '$_temp0';
  }

  @override
  String addSelectedItems(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Add $countString Items',
      one: 'Add 1 Item',
    );
    return '$_temp0';
  }

  @override
  String selectedCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString selected',
      one: '1 selected',
    );
    return '$_temp0';
  }

  @override
  String daysCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String daysOverdue(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString days overdue',
      one: '1 day overdue',
    );
    return '$_temp0';
  }

  @override
  String dueInDays(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Due in $countString days',
      one: 'Due in 1 day',
    );
    return '$_temp0';
  }

  @override
  String acrossInvoices(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Across $countString invoices',
      one: 'Across 1 invoice',
    );
    return '$_temp0';
  }

  @override
  String overdueInvoices(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString invoices overdue',
      one: '1 invoice overdue',
    );
    return '$_temp0';
  }

  @override
  String stepOfTotal(int step, int total) {
    final intl.NumberFormat stepNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String stepString = stepNumberFormat.format(step);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    return 'Step $stepString of $totalString';
  }

  @override
  String photoCount(int count, int maximum) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);
    final intl.NumberFormat maximumNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String maximumString = maximumNumberFormat.format(maximum);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString of $maximumString photos',
      one: '1 of $maximumString photos',
    );
    return '$_temp0';
  }

  @override
  String templateCount(int count, int total) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString of $totalString templates',
      one: '1 of $totalString templates',
    );
    return '$_temp0';
  }

  @override
  String reportItemQuantity(String quantity, String invoices) {
    return 'Qty $quantity · $invoices';
  }

  @override
  String deleteRecordedPayments(int count, String invoiceNumber) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'This deletes the $countString payments recorded for $invoiceNumber.',
      one: 'This deletes the 1 payment recorded for $invoiceNumber.',
    );
    return '$_temp0';
  }

  @override
  String numberedAttachment(int number) {
    final intl.NumberFormat numberNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String numberString = numberNumberFormat.format(number);

    return 'Attachment $numberString';
  }

  @override
  String viewNumberedAttachment(int number) {
    final intl.NumberFormat numberNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String numberString = numberNumberFormat.format(number);

    return 'View attachment $numberString';
  }

  @override
  String removeNumberedAttachment(int number) {
    final intl.NumberFormat numberNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String numberString = numberNumberFormat.format(number);

    return 'Remove attachment $numberString';
  }

  @override
  String setupProgress(int done, int total) {
    final intl.NumberFormat doneNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String doneString = doneNumberFormat.format(done);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    return '$doneString of $totalString done';
  }

  @override
  String countInCurrency(int count, String currency) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString in $currency';
  }

  @override
  String get noUnpaidInvoices => 'No unpaid invoices';

  @override
  String get noPartPaidInvoices => 'No part-paid invoices';

  @override
  String get noOverdueInvoices => 'No overdue invoices';

  @override
  String get noPaidInvoices => 'No paid invoices';

  @override
  String get language => 'Language';

  @override
  String get systemDefault => 'System default';

  @override
  String get english => 'English';

  @override
  String get hindi => 'हिन्दी';

  @override
  String get confirm => 'Confirm';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get downloads => 'Downloads';

  @override
  String get filesOnMyIphoneInvoiceMakerPro =>
      'Files › On My iPhone › Invoice Maker Pro';

  @override
  String get monthlyInvoiceLimitReached => 'Monthly invoice limit reached';

  @override
  String get monthlyEstimateLimitReached => 'Monthly estimate limit reached';

  @override
  String get savedClientLimitReached => 'Saved client limit reached';

  @override
  String get notNow => 'Not now';

  @override
  String get seePro => 'See Pro';

  @override
  String monthlyInvoiceLimitDetails(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'The free plan includes $countString new invoices each calendar month. You can still open, edit, share and get paid on every invoice you already have. Upgrade to Pro for unlimited invoices.';
  }

  @override
  String monthlyEstimateLimitDetails(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'The free plan includes $countString new estimates each calendar month. Upgrade to Pro for unlimited estimates.';
  }

  @override
  String savedClientLimitDetails(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'The free plan saves up to $countString clients. You can still type any client\'s details straight into an invoice. Upgrade to Pro to save unlimited clients.';
  }

  @override
  String get reportFinancial => 'Financial Report';

  @override
  String get reportTopClientsHeading => 'Top Clients:';

  @override
  String get reportTopItemsHeading => 'Top Items:';

  @override
  String get playStoreUnavailable =>
      'The Play Store is not available right now. Please try again later.';

  @override
  String get planUnavailable =>
      'This plan is not available right now. Please try again later.';

  @override
  String get purchaseStartFailed =>
      'The purchase could not be started. Please try again.';

  @override
  String get restorePurchasesFailed =>
      'Could not reach the Play Store to restore purchases.';

  @override
  String get purchaseFailed =>
      'The purchase did not go through. You have not been charged. Please check your connection and Google Play payment method, then try again.';

  @override
  String get backupFromNewerVersion =>
      'This backup was made by a newer version of the app. Update the app, then try again.';

  @override
  String get backupTooOld => 'This backup is too old to restore.';

  @override
  String get backupDamaged =>
      'This backup file is damaged and can\'t be restored.';

  @override
  String reportFinancialFor(String business) {
    return '$business — Financial Report';
  }

  @override
  String reportPeriod(String period) {
    return 'Period: $period';
  }

  @override
  String reportBilledAmount(String amount, String invoices) {
    return 'Billed: $amount ($invoices)';
  }

  @override
  String reportCollectedAmount(String amount) {
    return 'Collected: $amount';
  }

  @override
  String reportOutstandingAmount(String amount) {
    return 'Outstanding: $amount';
  }

  @override
  String reportOverdueAmount(String amount, int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'Overdue: $amount ($countString)';
  }

  @override
  String reportTaxAmount(String amount) {
    return 'Tax: $amount';
  }

  @override
  String reportAverageInvoice(String amount) {
    return 'Average Invoice: $amount';
  }

  @override
  String backupEstimateCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString estimates',
      one: '1 estimate',
    );
    return '$_temp0';
  }

  @override
  String backupPaymentCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString payments',
      one: '1 payment',
    );
    return '$_temp0';
  }

  @override
  String backupAttachmentCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString attachment photos',
      one: '1 attachment photo',
    );
    return '$_temp0';
  }

  @override
  String get catalogProfessional => 'Professional';

  @override
  String get catalogSimple => 'Simple';

  @override
  String get catalogBold => 'Bold';

  @override
  String get catalogCreative => 'Creative';

  @override
  String get catalogRetailGst => 'Retail & GST';

  @override
  String get catalogClassicCorporate => 'Classic Corporate';

  @override
  String get catalogModernMinimal => 'Modern Minimal';

  @override
  String get catalogEmeraldExecutive => 'Emerald Executive';

  @override
  String get catalogSlateElegance => 'Slate Elegance';

  @override
  String get catalogWarmCorporate => 'Warm Corporate';

  @override
  String get catalogNordicFrame => 'Nordic Frame';

  @override
  String get catalogLeftAccentRibbon => 'Left Accent Ribbon';

  @override
  String get catalogGeometricBanner => 'Geometric Banner';

  @override
  String get catalogSecurityGrid => 'Security Grid';

  @override
  String get catalogTwoToneSplit => 'Two-Tone Split';

  @override
  String get catalogCharcoalLetterhead => 'Charcoal Letterhead';

  @override
  String get catalogNavyLetterhead => 'Navy Letterhead';

  @override
  String get catalogForestSeal => 'Forest Seal';

  @override
  String get catalogLinenRule => 'Linen Rule';

  @override
  String get catalogMistLine => 'Mist Line';

  @override
  String get catalogOliveFrame => 'Olive Frame';

  @override
  String get catalogCrimsonSlash => 'Crimson Slash';

  @override
  String get catalogIndigoSlash => 'Indigo Slash';

  @override
  String get catalogCopperBanner => 'Copper Banner';

  @override
  String get catalogTealWave => 'Teal Wave';

  @override
  String get catalogOrchidWave => 'Orchid Wave';

  @override
  String get catalogClayRibbon => 'Clay Ribbon';

  @override
  String get catalogMulberrySplit => 'Mulberry Split';

  @override
  String get catalogSaffronLedger => 'Saffron Ledger';

  @override
  String get catalogPeacockLedger => 'Peacock Ledger';

  @override
  String get catalogGraphiteReceipt => 'Graphite Receipt';

  @override
  String get catalogRoseReceipt => 'Rose Receipt';

  @override
  String get catalogOxbloodSeal => 'Oxblood Seal';

  @override
  String get catalogCleanSans => 'Clean Sans';

  @override
  String get catalogEditorialSerif => 'Editorial Serif';

  @override
  String get catalogGeometric => 'Geometric';

  @override
  String get catalogTechMono => 'Tech Mono';

  @override
  String get catalogModernClearHighlyLegibleInterNoto =>
      'Modern, clear & highly legible (Inter / Noto)';

  @override
  String get catalogFormalPremiumClassicLoraMerriweather =>
      'Formal, premium & classic (Lora / Merriweather)';

  @override
  String get catalogSharpSleekContemporaryMontserratPoppins =>
      'Sharp, sleek & contemporary (Montserrat / Poppins)';

  @override
  String get catalogTechnicalPreciseBalancedSpaceMono =>
      'Technical, precise & balanced (Space Mono)';

  @override
  String get catalogCompact => 'Compact';

  @override
  String get catalogRegular => 'Regular';

  @override
  String get catalogSpacious => 'Spacious';

  @override
  String get catalogLeftLogo => 'Left Logo';

  @override
  String get catalogRightLogo => 'Right Logo';

  @override
  String get catalogCentered => 'Centered';

  @override
  String get catalogBanner => 'Banner';

  @override
  String get catalogBusinessLogoOnLeftInvoiceDetailsOnRight =>
      'Business & logo on left, invoice details on right';

  @override
  String get catalogInvoiceTitleMetaOnLeftLogoOnRight =>
      'Invoice title & meta on left, logo on right';

  @override
  String get catalogCenteredBrandingWithBalancedMetadataPills =>
      'Centered branding with balanced metadata pills';

  @override
  String get catalogFullWidthSolidColorAccentHeader =>
      'Full-width solid color accent header';

  @override
  String get catalogSideBySide => 'Side by Side';

  @override
  String get catalogInverted => 'Inverted';

  @override
  String get catalogStacked => 'Stacked';

  @override
  String get catalogFromBusinessOnLeftBillToClientOnRight =>
      'From (Business) on left · Bill To (Client) on right';

  @override
  String get catalogBillToClientOnLeftFromBusinessOnRight =>
      'Bill To (Client) on left · From (Business) on right';

  @override
  String get catalogFullWidthFromCardAboveBillToCard =>
      'Full-width From card above Bill To card';

  @override
  String get catalogRoyalBlue => 'Royal Blue';

  @override
  String get catalogEmeraldForest => 'Emerald Forest';

  @override
  String get catalogSlateGraphite => 'Slate Graphite';

  @override
  String get catalogObsidianBlack => 'Obsidian Black';

  @override
  String get catalogWarmAmber => 'Warm Amber';

  @override
  String get catalogNordicTeal => 'Nordic Teal';

  @override
  String get catalogIndigoViolet => 'Indigo Violet';

  @override
  String get catalogCrimsonExecutive => 'Crimson Executive';

  @override
  String get catalogSent => 'SENT';

  @override
  String get catalogAccepted => 'ACCEPTED';

  @override
  String get catalogDeclined => 'DECLINED';

  @override
  String get catalogInvoiced => 'INVOICED';

  @override
  String get catalogNet15 => 'Net 15';

  @override
  String get catalogNet30 => 'Net 30';

  @override
  String get catalogNet60 => 'Net 60';

  @override
  String get catalogUsDollar => 'US Dollar';

  @override
  String get catalogIndianRupee => 'Indian Rupee';

  @override
  String get catalogBritishPound => 'British Pound';

  @override
  String get catalogEuro => 'Euro';

  @override
  String get catalogCanadianDollar => 'Canadian Dollar';

  @override
  String get catalogAustralianDollar => 'Australian Dollar';

  @override
  String get catalogUaeDirham => 'UAE Dirham';

  @override
  String get catalogSaudiRiyal => 'Saudi Riyal';

  @override
  String get catalogSingaporeDollar => 'Singapore Dollar';

  @override
  String get catalogJapaneseYen => 'Japanese Yen';

  @override
  String get catalogNewZealandDollar => 'New Zealand Dollar';

  @override
  String get catalogSwissFranc => 'Swiss Franc';

  @override
  String get catalogMalaysianRinggit => 'Malaysian Ringgit';

  @override
  String get catalogSouthAfricanRand => 'South African Rand';

  @override
  String get catalogMexicanPeso => 'Mexican Peso';

  @override
  String get catalogBrazilianReal => 'Brazilian Real';

  @override
  String get catalogHongKongDollar => 'Hong Kong Dollar';

  @override
  String get catalogThaiBaht => 'Thai Baht';

  @override
  String get catalogPhilippinePeso => 'Philippine Peso';

  @override
  String get catalogIndonesianRupiah => 'Indonesian Rupiah';

  @override
  String get catalogVietnameseDong => 'Vietnamese Dong';

  @override
  String get catalogSouthKoreanWon => 'South Korean Won';

  @override
  String get catalogChineseYuan => 'Chinese Yuan';

  @override
  String get catalogNigerianNaira => 'Nigerian Naira';

  @override
  String get catalogKenyanShilling => 'Kenyan Shilling';

  @override
  String get catalogPakistaniRupee => 'Pakistani Rupee';

  @override
  String get catalogBangladeshiTaka => 'Bangladeshi Taka';

  @override
  String get catalogPolishZloty => 'Polish Zloty';

  @override
  String get catalogSwedishKrona => 'Swedish Krona';

  @override
  String get catalogNorwegianKrone => 'Norwegian Krone';

  @override
  String get catalogDanishKrone => 'Danish Krone';

  @override
  String get catalogQatariRiyal => 'Qatari Riyal';

  @override
  String get catalogKuwaitiDinar => 'Kuwaiti Dinar';

  @override
  String get catalogBahrainiDinar => 'Bahraini Dinar';

  @override
  String get catalogTaiwanDollar => 'Taiwan Dollar';

  @override
  String get catalogUnitedStates => 'United States';

  @override
  String get catalogIndia => 'India';

  @override
  String get catalogUnitedKingdom => 'United Kingdom';

  @override
  String get catalogEuropeanUnion => 'European Union';

  @override
  String get catalogCanada => 'Canada';

  @override
  String get catalogAustralia => 'Australia';

  @override
  String get catalogUnitedArabEmirates => 'United Arab Emirates';

  @override
  String get catalogSaudiArabia => 'Saudi Arabia';

  @override
  String get catalogSingapore => 'Singapore';

  @override
  String get catalogJapan => 'Japan';

  @override
  String get catalogNewZealand => 'New Zealand';

  @override
  String get catalogSwitzerland => 'Switzerland';

  @override
  String get catalogMalaysia => 'Malaysia';

  @override
  String get catalogSouthAfrica => 'South Africa';

  @override
  String get catalogMexico => 'Mexico';

  @override
  String get catalogBrazil => 'Brazil';

  @override
  String get catalogHongKong => 'Hong Kong';

  @override
  String get catalogThailand => 'Thailand';

  @override
  String get catalogPhilippines => 'Philippines';

  @override
  String get catalogIndonesia => 'Indonesia';

  @override
  String get catalogVietnam => 'Vietnam';

  @override
  String get catalogSouthKorea => 'South Korea';

  @override
  String get catalogChina => 'China';

  @override
  String get catalogNigeria => 'Nigeria';

  @override
  String get catalogKenya => 'Kenya';

  @override
  String get catalogPakistan => 'Pakistan';

  @override
  String get catalogBangladesh => 'Bangladesh';

  @override
  String get catalogPoland => 'Poland';

  @override
  String get catalogSweden => 'Sweden';

  @override
  String get catalogNorway => 'Norway';

  @override
  String get catalogDenmark => 'Denmark';

  @override
  String get catalogQatar => 'Qatar';

  @override
  String get catalogKuwait => 'Kuwait';

  @override
  String get catalogBahrain => 'Bahrain';

  @override
  String get catalogTaiwan => 'Taiwan';

  @override
  String get catalogSalesTax => 'Sales Tax';

  @override
  String get catalogGoodsAndServicesTax => 'Goods and Services Tax';

  @override
  String get catalogValueAddedTax => 'Value Added Tax';

  @override
  String get catalogConsumptionTax => 'Consumption Tax';

  @override
  String get catalogSalesAndServicesTax => 'Sales and Services Tax';

  @override
  String get catalogImpuestoAlValorAgregado => 'Impuesto al Valor Agregado';

  @override
  String get catalogImpostosIcmsIss => 'Impostos (ICMS / ISS)';

  @override
  String get catalogNoGeneralSalesTax => 'No General Sales Tax';

  @override
  String get catalogPajakPertambahanNilai => 'Pajak Pertambahan Nilai';

  @override
  String get catalogValueAddedTaxMushak => 'Value Added Tax (Mushak)';

  @override
  String get catalogPodatekOdTowarWIUsUg => 'Podatek od Towarów i Usług';

  @override
  String get catalogMervRdesskattMoms => 'Mervärdesskatt (Moms)';

  @override
  String get catalogMerverdiavgiftMva => 'Merverdiavgift (MVA)';

  @override
  String get catalogMervRdiafgiftMoms => 'Merværdiafgift (Moms)';

  @override
  String get catalogTaxFree => 'Tax Free';

  @override
  String get catalogTaxIdEin => 'Tax ID / EIN';

  @override
  String get catalogVatRegNo => 'VAT Reg No.';

  @override
  String get catalogBusinessNumberBn => 'Business Number (BN)';

  @override
  String get catalogAbnBusinessNo => 'ABN (Business No.)';

  @override
  String get catalogTrnTaxRegNo => 'TRN (Tax Reg No.)';

  @override
  String get catalogVatRegNoTrn => 'VAT Reg No. / TRN';

  @override
  String get catalogUenGstRegNo => 'UEN / GST Reg No.';

  @override
  String get catalogInvoiceRegNo => 'Invoice Reg No.';

  @override
  String get catalogGstIrdNumber => 'GST / IRD Number';

  @override
  String get catalogSstRegNo => 'SST Reg No.';

  @override
  String get catalogVatNumber => 'VAT Number';

  @override
  String get catalogRfcTaxId => 'RFC (Tax ID)';

  @override
  String get catalogCnpjCompanyId => 'CNPJ (Company ID)';

  @override
  String get catalogBusinessRegNoBrn => 'Business Reg No. (BRN)';

  @override
  String get catalogTaxId13Digits => 'Tax ID (13 digits)';

  @override
  String get catalogTinTaxIdNo => 'TIN (Tax ID No.)';

  @override
  String get catalogNpwpTaxId => 'NPWP (Tax ID)';

  @override
  String get catalogMSThuTaxCode => 'Mã số thuế (Tax Code)';

  @override
  String get catalogUnifiedSocialCreditCode => 'Unified Social Credit Code';

  @override
  String get catalogBinVatRegNo => 'BIN / VAT Reg No.';

  @override
  String get catalogNipTaxId => 'NIP (Tax ID)';

  @override
  String get catalogTaxCardTin => 'Tax Card / TIN';

  @override
  String get catalogCivilCommercialRegNo => 'Civil / Commercial Reg No.';

  @override
  String get catalogVatAccountNo => 'VAT Account No.';

  @override
  String get catalogUnifiedBusinessNoUbn => 'Unified Business No. (UBN)';

  @override
  String get catalogAccountNumber => 'Account Number';

  @override
  String get catalogNMeroDeCuenta => 'Número de Cuenta';

  @override
  String get catalogContaCorrente => 'Conta Corrente';

  @override
  String get catalogNomorRekening => 'Nomor Rekening';

  @override
  String get catalogSTIKhoN => 'Số tài khoản';

  @override
  String get catalogAccountNumberNuban => 'Account Number (NUBAN)';

  @override
  String get catalogAccountNumberIban => 'Account Number (IBAN)';

  @override
  String get catalogNumerKontaIban => 'Numer Konta (IBAN)';

  @override
  String get catalogKontonummer => 'Kontonummer';

  @override
  String get catalogRoutingIfscCode => 'Routing / IFSC Code';

  @override
  String get catalogRoutingNumberAba => 'Routing Number (ABA)';

  @override
  String get catalogIfscCode => 'IFSC Code';

  @override
  String get catalogSortCode => 'Sort Code';

  @override
  String get catalogBicSwiftCode => 'BIC / SWIFT Code';

  @override
  String get catalogTransitInstitutionNo => 'Transit & Institution No.';

  @override
  String get catalogBsbCode => 'BSB Code';

  @override
  String get catalogBankBranchCode => 'Bank & Branch Code';

  @override
  String get catalogBranchCodeName => 'Branch Code & Name';

  @override
  String get catalogBankCodeSwift => 'Bank Code / SWIFT';

  @override
  String get catalogBranchCode => 'Branch Code';

  @override
  String get catalogClabe18Digits => 'CLABE (18 digits)';

  @override
  String get catalogAgNciaCDigoDoBanco => 'Agência & Código do Banco';

  @override
  String get catalogBankCodeBranch => 'Bank Code & Branch';

  @override
  String get catalogBankCodeBrstn => 'Bank Code / BRSTN';

  @override
  String get catalogKodeBank => 'Kode Bank';

  @override
  String get catalogChiNhNhMNgNHNg => 'Chi nhánh / Mã Ngân hàng';

  @override
  String get catalogBankCode => 'Bank Code';

  @override
  String get catalogBankCodeCnaps => 'Bank Code (CNAPS)';

  @override
  String get catalogSortCodeBankCode => 'Sort Code / Bank Code';

  @override
  String get catalogBankCodeBranch2 => 'Bank Code / Branch';

  @override
  String get catalogBankBranchCode2 => 'Bank Branch Code';

  @override
  String get catalogRoutingNumber9Digits => 'Routing Number (9 digits)';

  @override
  String get catalogRegNr4Digits => 'Reg.nr (4 digits)';

  @override
  String get catalogBankCode3Digits => 'Bank Code (3 digits)';

  @override
  String get catalogUpiPaymentHandle => 'UPI / Payment Handle';

  @override
  String get catalogUpiIdVpa => 'UPI ID / VPA';

  @override
  String get catalogOnlinePaymentLinkHandle => 'Online Payment Link / Handle';

  @override
  String get catalogPaynowUenMobile => 'PayNow (UEN / Mobile)';

  @override
  String get catalogDuitnowIdBusinessReg => 'DuitNow (ID / Business Reg)';

  @override
  String get catalogChavePixCnpjEmailTelefone =>
      'Chave Pix (CNPJ / Email / Telefone)';

  @override
  String get catalogFpsIdFasterPaymentSystem =>
      'FPS ID (Faster Payment System)';

  @override
  String get catalogPromptpayTaxIdMobile => 'PromptPay (Tax ID / Mobile)';

  @override
  String get catalogPaymentHandlePaystack => 'Payment Handle / Paystack';

  @override
  String get catalogMPesaPaybillTillNumber => 'M-Pesa Paybill / Till Number';

  @override
  String get catalogBkashNagadMerchantNumber => 'bKash / Nagad Merchant Number';

  @override
  String get catalogSwishNummerFRetag => 'Swish Nummer (Företag)';

  @override
  String get catalogVippsNummerBedrift => 'Vipps Nummer (Bedrift)';

  @override
  String get catalogMobilepayNummer => 'MobilePay Nummer';

  @override
  String get catalogWafeyKnetLink => 'Wafey / KNET Link';

  @override
  String get catalogBenefitpayIbanMobile => 'BenefitPay (IBAN / Mobile)';

  @override
  String get myBusinessPlaceholder => 'My Business';

  @override
  String get catalogBankTransferNeft => 'Bank Transfer / NEFT';

  @override
  String get catalogCash => 'Cash';

  @override
  String get catalogCreditDebitCard => 'Credit / Debit Card';

  @override
  String get catalogCheque => 'Cheque';

  @override
  String get catalogBankTransfer => 'Bank transfer';

  @override
  String get catalogCard => 'Card';

  @override
  String get catalogEG123456789 => 'e.g. 12-3456789';

  @override
  String get catalogEGChaseBankBarclaysHdfc =>
      'e.g. Chase Bank / Barclays / HDFC';

  @override
  String get catalogEG1234567890 => 'e.g. 1234567890';

  @override
  String get catalogEG021000021Sbin0001234 => 'e.g. 021000021 / SBIN0001234';

  @override
  String get catalogEGBusinessUpiOrPaypalMeHandle =>
      'e.g. business@upi or paypal.me/handle';

  @override
  String get catalogEGJpmorganChaseWellsFargoBankOfAmerica =>
      'e.g. JPMorgan Chase / Wells Fargo / Bank of America';

  @override
  String get catalogEG0210000219DigitAba => 'e.g. 021000021 (9-digit ABA)';

  @override
  String get catalogZelleVenmoPaypalHandle => 'Zelle / Venmo / PayPal Handle';

  @override
  String get catalogEGPaymentsCompanyComOrUsername =>
      'e.g. payments@company.com or @username';

  @override
  String get catalogEGStateBankOfIndiaHdfcBankIcici =>
      'e.g. State Bank of India / HDFC Bank / ICICI';

  @override
  String get catalogEG50100234567890 => 'e.g. 50100234567890';

  @override
  String get catalogEGHdfc0000123Sbin0001234 =>
      'e.g. HDFC0000123 / SBIN0001234';

  @override
  String get catalogEGCompanyOkhdfcbankOr9876543210Upi =>
      'e.g. company@okhdfcbank or 9876543210@upi';

  @override
  String get catalogEGBarclaysHsbcUkLloydsBank =>
      'e.g. Barclays / HSBC UK / Lloyds Bank';

  @override
  String get catalogEG123456788Digits => 'e.g. 12345678 (8 digits)';

  @override
  String get catalogEG2000006Digits => 'e.g. 20-00-00 (6 digits)';

  @override
  String get catalogPaymFasterPaymentsId => 'Paym / Faster Payments ID';

  @override
  String get catalogEGPaymentsCompanyCoUk => 'e.g. payments@company.co.uk';

  @override
  String get catalogVatIdUstIdnr => 'VAT ID / USt-IdNr.';

  @override
  String get catalogEGDeutscheBankBnpParibasSantander =>
      'e.g. Deutsche Bank / BNP Paribas / Santander';

  @override
  String get catalogEGDe89370400440532013000 =>
      'e.g. DE89 3704 0044 0532 0130 00';

  @override
  String get catalogEGDbkdeffxxx811Characters =>
      'e.g. DBKDEFFXXX (8-11 characters)';

  @override
  String get catalogSepaPaypalBizumHandle => 'SEPA / PayPal / Bizum Handle';

  @override
  String get catalogEGPaypalMeCompanyOrSepaId =>
      'e.g. paypal.me/company or SEPA ID';

  @override
  String get catalogEGRbcRoyalBankTdCanadaTrustBmo =>
      'e.g. RBC Royal Bank / TD Canada Trust / BMO';

  @override
  String get catalogEG1234567 => 'e.g. 1234567';

  @override
  String get catalogEG12345001TransitInst => 'e.g. 12345-001 (Transit-Inst)';

  @override
  String get catalogInteracETransferHandle => 'Interac e-Transfer Handle';

  @override
  String get catalogEGPaymentsCompanyCa => 'e.g. payments@company.ca';

  @override
  String get catalogEGCommonwealthBankAnzWestpacNab =>
      'e.g. Commonwealth Bank / ANZ / Westpac / NAB';

  @override
  String get catalogEG12345678 => 'e.g. 1234 5678';

  @override
  String get catalogEG0620006Digits => 'e.g. 062-000 (6 digits)';

  @override
  String get catalogPayidOskoHandle => 'PayID / Osko Handle';

  @override
  String get catalogEGPaymentsCompanyComAuOr0400123456 =>
      'e.g. payments@company.com.au or 0400123456';

  @override
  String get catalogEGEmiratesNbdFirstAbuDhabiBankFab =>
      'e.g. Emirates NBD / First Abu Dhabi Bank (FAB)';

  @override
  String get catalogEGAe07033123456789012345 =>
      'e.g. AE07 0331 2345 6789 0123 45';

  @override
  String get catalogEGEbilaeadxxx => 'e.g. EBILAEADXXX';

  @override
  String get catalogAaniInstantPayHandle => 'Aani / Instant Pay Handle';

  @override
  String get catalogEG0501234567OrCompany => 'e.g. 0501234567 or @company';

  @override
  String get catalogEGAlRajhiBankSaudiNationalBankSnb =>
      'e.g. Al Rajhi Bank / Saudi National Bank (SNB)';

  @override
  String get catalogEGSa0380000000608010167519 =>
      'e.g. SA03 8000 0000 6080 1016 7519';

  @override
  String get catalogEGRjhisa22Xxx => 'e.g. RJHISA22XXX';

  @override
  String get catalogSarieStcPayHandle => 'Sarie / STC Pay Handle';

  @override
  String get catalogEG0501234567OrPaymentsCompanySa =>
      'e.g. 0501234567 or payments@company.sa';

  @override
  String get catalogEGDbsBankOcbcUob => 'e.g. DBS Bank / OCBC / UOB';

  @override
  String get catalogEG1234567892 => 'e.g. 123-45678-9';

  @override
  String get catalogEG7171001Dbs => 'e.g. 7171-001 (DBS)';

  @override
  String get catalogEG201234567AOr6591234567 =>
      'e.g. 201234567A or +6591234567';

  @override
  String get catalogEGMitsubishiUfjMufgSmbcMizuho =>
      'e.g. Mitsubishi UFJ (MUFG) / SMBC / Mizuho';

  @override
  String get catalogEG1234567Futsu => 'e.g. 1234567 (Futsu)';

  @override
  String get catalogEG001ShinjukuBranch => 'e.g. 001 (Shinjuku Branch)';

  @override
  String get catalogPaypayLinePayHandle => 'PayPay / Line Pay Handle';

  @override
  String get catalogEGPaymentsCompanyJp => 'e.g. payments@company.jp';

  @override
  String get catalogEGAnzNewZealandAsbBankBnz =>
      'e.g. ANZ New Zealand / ASB Bank / BNZ';

  @override
  String get catalogEG010123012345600 => 'e.g. 01-0123-0123456-00';

  @override
  String get catalogEG0101236Digits => 'e.g. 01-0123 (6 digits)';

  @override
  String get catalogEGPaymentsCompanyCoNz => 'e.g. payments@company.co.nz';

  @override
  String get catalogEGUbsCreditSuisseZkb => 'e.g. UBS / Credit Suisse / ZKB';

  @override
  String get catalogEGCh9300762011623852957 =>
      'e.g. CH93 0076 2011 6238 5295 7';

  @override
  String get catalogEGUbswchzhxxx => 'e.g. UBSWCHZHXXX';

  @override
  String get catalogTwintQrBillHandle => 'TWINT / QR-Bill Handle';

  @override
  String get catalogEG41791234567OrCompany =>
      'e.g. +41 79 123 45 67 or @company';

  @override
  String get catalogEGMaybankCimbBankPublicBank =>
      'e.g. Maybank / CIMB Bank / Public Bank';

  @override
  String get catalogEG514012345678 => 'e.g. 5140 1234 5678';

  @override
  String get catalogEGMbbemykl => 'e.g. MBBEMYKL';

  @override
  String get catalogEG201234567AOr0123456789 => 'e.g. 201234567A or 0123456789';

  @override
  String get catalogEGStandardBankFnbAbsaNedbank =>
      'e.g. Standard Bank / FNB / Absa / Nedbank';

  @override
  String get catalogEG1234567893 => 'e.g. 123456789';

  @override
  String get catalogEG051001FnbUniversal => 'e.g. 051001 (FNB Universal)';

  @override
  String get catalogEG0821234567OrShapid => 'e.g. 0821234567 or @shapid';

  @override
  String get catalogEGBbvaMXicoBanorteSantanderMXico =>
      'e.g. BBVA México / Banorte / Santander México';

  @override
  String get catalogEG012180001234567890 => 'e.g. 012 180 00123456789 0';

  @override
  String get catalogCodiDimoSpeiHandle => 'CoDi / Dimo / SPEI Handle';

  @override
  String get catalogEG5512345678OrRfcEmpresaCom =>
      'e.g. 5512345678 or rfc@empresa.com';

  @override
  String get catalogEGItaUnibancoBradescoBancoDoBrasil =>
      'e.g. Itaú Unibanco / Bradesco / Banco do Brasil';

  @override
  String get catalogEG123456 => 'e.g. 12345-6';

  @override
  String get catalogEG0341ItaAg1234 => 'e.g. 0341 (Itaú) / Ag. 1234';

  @override
  String get catalogEG00000000000100OuPixEmpresaComBr =>
      'e.g. 00.000.000/0001-00 ou pix@empresa.com.br';

  @override
  String get catalogEGHsbcStandardCharteredHangSengBank =>
      'e.g. HSBC / Standard Chartered / Hang Seng Bank';

  @override
  String get catalogEG123456789001 => 'e.g. 123-456789-001';

  @override
  String get catalogEG004123Hsbc => 'e.g. 004-123 (HSBC)';

  @override
  String get catalogEG1234567OrPaymentsCompanyHk =>
      'e.g. 1234567 or payments@company.hk';

  @override
  String get catalogEGBangkokBankKasikornbankKbankScb =>
      'e.g. Bangkok Bank / Kasikornbank (KBank) / SCB';

  @override
  String get catalogEG12345678902 => 'e.g. 123-4-56789-0';

  @override
  String get catalogEG0001 => 'e.g. 0001';

  @override
  String get catalogEG0105551234567Or0812345678 =>
      'e.g. 0105551234567 or 0812345678';

  @override
  String get catalogEGBdoUnibankBpiMetrobank =>
      'e.g. BDO Unibank / BPI / Metrobank';

  @override
  String get catalogEG123456789012 => 'e.g. 1234 5678 9012';

  @override
  String get catalogEG010530667 => 'e.g. 010530667';

  @override
  String get catalogEG09171234567OrCompany => 'e.g. 09171234567 or @company';

  @override
  String get catalogEGBankCentralAsiaBcaMandiriBri =>
      'e.g. Bank Central Asia (BCA) / Mandiri / BRI';

  @override
  String get catalogEG014Bca => 'e.g. 014 (BCA)';

  @override
  String get catalogQrisGopayOvoHandle => 'QRIS / GoPay / OVO Handle';

  @override
  String get catalogEG081234567890OrPaymentsCompanyId =>
      'e.g. 081234567890 or payments@company.id';

  @override
  String get catalogEGVietcombankTechcombankBidv =>
      'e.g. Vietcombank / Techcombank / BIDV';

  @override
  String get catalogEG0011001234567 => 'e.g. 0011001234567';

  @override
  String get catalogEGChiNhNhBaNh => 'e.g. Chi nhánh Ba Đình';

  @override
  String get catalogVietqrMomoZalopayHandle => 'VietQR / MoMo / ZaloPay Handle';

  @override
  String get catalogEG0912345678OrCompany => 'e.g. 0912345678 or @company';

  @override
  String get catalogEGKbKookminBankShinhanHanaBank =>
      'e.g. KB Kookmin Bank / Shinhan / Hana Bank';

  @override
  String get catalogEG1234567890122 => 'e.g. 123-456-789012';

  @override
  String get catalogEG004Kb => 'e.g. 004 (KB)';

  @override
  String get catalogKakaopayTossHandle => 'KakaoPay / Toss Handle';

  @override
  String get catalogEG01012345678 => 'e.g. 010-1234-5678';

  @override
  String get catalogEGIcbcChinaConstructionBankBankOfChina =>
      'e.g. ICBC / China Construction Bank / Bank of China';

  @override
  String get catalogEG6222021234567890 => 'e.g. 6222 0212 3456 7890';

  @override
  String get catalogEG102100000010 => 'e.g. 102100000010';

  @override
  String get catalogAlipayWechatPayHandle => 'Alipay / WeChat Pay Handle';

  @override
  String get catalogEGPaymentsCompanyCnOr13800138000 =>
      'e.g. payments@company.cn or 13800138000';

  @override
  String get catalogEGAccessBankZenithBankGtbank =>
      'e.g. Access Bank / Zenith Bank / GTBank';

  @override
  String get catalogEG012345678910Digits => 'e.g. 0123456789 (10 digits)';

  @override
  String get catalogEG058152010 => 'e.g. 058152010';

  @override
  String get catalogEGPaystackComPayMycompany =>
      'e.g. paystack.com/pay/mycompany';

  @override
  String get catalogEGKcbBankEquityBankNcba =>
      'e.g. KCB Bank / Equity Bank / NCBA';

  @override
  String get catalogEG01100 => 'e.g. 01100';

  @override
  String get catalogEGPaybill247247Acc123456 =>
      'e.g. Paybill: 247247, Acc: 123456';

  @override
  String get catalogEGHabibBankHblMcbMeezanBank =>
      'e.g. Habib Bank (HBL) / MCB / Meezan Bank';

  @override
  String get catalogEGPk36Mezn0001234567890123 =>
      'e.g. PK36MEZN0001234567890123';

  @override
  String get catalogEG0123 => 'e.g. 0123';

  @override
  String get catalogRaastIdJazzcashEasypaisa =>
      'Raast ID / JazzCash / Easypaisa';

  @override
  String get catalogEG03001234567 => 'e.g. 03001234567';

  @override
  String get catalogEGSonaliBankBracBankDutchBangla =>
      'e.g. Sonali Bank / BRAC Bank / Dutch-Bangla';

  @override
  String get catalogEG1011234567890 => 'e.g. 1011234567890';

  @override
  String get catalogEG060271234 => 'e.g. 060271234';

  @override
  String get catalogEG01712345678PersonalMerchant =>
      'e.g. 01712345678 (Personal / Merchant)';

  @override
  String get catalogEGPkoBankPolskiSantanderPolskaMbank =>
      'e.g. PKO Bank Polski / Santander Polska / mBank';

  @override
  String get catalogEGPl12102010260000123456789012 =>
      'e.g. PL 12 1020 1026 0000 1234 5678 9012';

  @override
  String get catalogEGPkopplpw => 'e.g. PKOPPLPW';

  @override
  String get catalogBlikPrzelewy24Handle => 'BLIK / Przelewy24 Handle';

  @override
  String get catalogEG48500123456LubEmail => 'e.g. +48 500 123 456 lub email';

  @override
  String get catalogEGSwedbankSebHandelsbanken =>
      'e.g. Swedbank / SEB / Handelsbanken';

  @override
  String get catalogEG12345678901 => 'e.g. 1234 567 890-1';

  @override
  String get catalogEGBg1234567EllerClearing81059 =>
      'e.g. Bg 123-4567 eller Clearing 8105-9';

  @override
  String get catalogEG1231234567 => 'e.g. 123 123 45 67';

  @override
  String get catalogEGDnbNordeaNorgeSparebank1 =>
      'e.g. DNB / Nordea Norge / SpareBank 1';

  @override
  String get catalogEG123456789013 => 'e.g. 1234.56.78901';

  @override
  String get catalogEGDnbanokk => 'e.g. DNBANOKK';

  @override
  String get catalogEGVippsNr12345 => 'e.g. Vipps-nr: 12345';

  @override
  String get catalogEGDanskeBankNordeaDanmarkJyskeBank =>
      'e.g. Danske Bank / Nordea Danmark / Jyske Bank';

  @override
  String get catalogEG1234 => 'e.g. 1234';

  @override
  String get catalogEG1234562 => 'e.g. 12 34 56';

  @override
  String get catalogEGQatarNationalBankQnbQiib =>
      'e.g. Qatar National Bank (QNB) / QIIB';

  @override
  String get catalogEGQa53Qnba000000001234567890123 =>
      'e.g. QA53 QNBA 0000 0000 1234 5678 9012 3';

  @override
  String get catalogEGQnbaqaqa => 'e.g. QNBAQAQA';

  @override
  String get catalogFawranInstantPayHandle => 'Fawran / Instant Pay Handle';

  @override
  String get catalogEG55123456OrCompany => 'e.g. 55123456 or @company';

  @override
  String get catalogEGNationalBankOfKuwaitNbkKfh =>
      'e.g. National Bank of Kuwait (NBK) / KFH';

  @override
  String get catalogEGKw12Nbok0000000012345678901234 =>
      'e.g. KW12 NBOK 0000 0000 1234 5678 9012 34';

  @override
  String get catalogEGNbokkwkw => 'e.g. NBOKKWKW';

  @override
  String get catalogEGPaymentsCompanyKw => 'e.g. payments@company.kw';

  @override
  String get catalogEGNationalBankOfBahrainNbbBbk =>
      'e.g. National Bank of Bahrain (NBB) / BBK';

  @override
  String get catalogEGBh02Nbob00000000123456 =>
      'e.g. BH02 NBOB 0000 0000 1234 56';

  @override
  String get catalogEGNbobbhbm => 'e.g. NBOBBHBM';

  @override
  String get catalogEG39123456OrCompany => 'e.g. 39123456 or @company';

  @override
  String get catalogEGBankOfTaiwanCtbcBankMegaBank =>
      'e.g. Bank of Taiwan / CTBC Bank / Mega Bank';

  @override
  String get catalogEG0123456789012 => 'e.g. 0123-456-789012';

  @override
  String get catalogEG004BankOfTaiwan => 'e.g. 004 (Bank of Taiwan)';

  @override
  String get catalogTaiwanPayLinePayHandle => 'Taiwan Pay / Line Pay Handle';

  @override
  String get partPaidStamp => 'PART PAID';

  @override
  String get goProStamp => 'GO PRO';

  @override
  String get immediately => 'Immediately';

  @override
  String get ensureScreenLock =>
      'Set up a screen lock or enroll biometrics in your device settings to use App lock.';

  @override
  String get authenticateToEnableAppLock =>
      'Confirm your identity to enable App lock';

  @override
  String get cannotSaveAppLock =>
      'Could not save the App lock setting. Try again.';

  @override
  String get cannotSaveLockTimeout =>
      'Could not save the lock timeout. Try again.';

  @override
  String get unlockApp => 'Unlock Invoice Maker Pro';

  @override
  String get appLockOperationFailed =>
      'Could not complete the App lock request. Try again.';

  @override
  String get authenticationIncomplete => 'Authentication was not completed.';

  @override
  String get authenticationTemporarilyLocked =>
      'Authentication is temporarily locked. Unlock your device and try again.';

  @override
  String get authenticationUnavailable =>
      'Device authentication is unavailable. Try again.';

  @override
  String get reminderChannelDescription =>
      'Reminders about outstanding invoice balances';

  @override
  String get remindersWorking =>
      'Payment reminders are working on this device.';

  @override
  String get reminderTomorrow => 'tomorrow';

  @override
  String get reminderToday => 'today';

  @override
  String get clientGreeting => 'Hi,';

  @override
  String get clientReminderThanks => 'Thanks,';

  @override
  String get clientReminderAlreadyPaid =>
      'If you’ve already paid, thank you. Please let us know if you have any questions.';

  @override
  String minutesCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString minutes',
      one: '1 minute',
    );
    return '$_temp0';
  }

  @override
  String everyDays(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Every $countString days',
      one: 'Every 1 day',
    );
    return '$_temp0';
  }

  @override
  String reminderInDays(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'in $countString days',
      one: 'in 1 day',
    );
    return '$_temp0';
  }

  @override
  String reminderDaysOverdue(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '· $countString days overdue',
      one: '· 1 day overdue',
    );
    return '$_temp0';
  }

  @override
  String reminderBalance(String amount) {
    return '$amount due';
  }

  @override
  String reminderBalanceFromClient(String amount, String client) {
    return '$amount due from $client';
  }

  @override
  String reminderNotificationBody(
    String invoiceNumber,
    String balance,
    String timing,
  ) {
    return '$invoiceNumber · $balance $timing';
  }

  @override
  String clientGreetingByName(String client) {
    return 'Hi $client,';
  }

  @override
  String clientReminderOutstanding(
    String balance,
    String invoiceNumber,
    String timing,
  ) {
    return 'A friendly reminder that $balance is outstanding on invoice $invoiceNumber.$timing';
  }

  @override
  String clientReminderUpi(String upi) {
    return 'You can pay via UPI to $upi.';
  }

  @override
  String clientReminderOverdue(String date, String days) {
    return ' It was due on $date ($days overdue).';
  }

  @override
  String clientReminderDueToday(String date) {
    return ' It is due today ($date).';
  }

  @override
  String clientReminderDueOn(String date) {
    return ' It is due on $date.';
  }

  @override
  String get addYourLogo => 'Add your logo';

  @override
  String get addYourAddress => 'Add your address';

  @override
  String addYourTaxId(String taxId) {
    return 'Add your $taxId';
  }

  @override
  String get addHowClientsPayYou => 'Add how clients pay you';

  @override
  String get addYourSignature => 'Add your signature';

  @override
  String get makeYourFirstInvoice => 'Make your first invoice';

  @override
  String get taxId => 'Tax ID';

  @override
  String get couldNotShowThePreviewPleaseTryAgain =>
      'Could not show the preview. Please try again.';

  @override
  String get selectCountryCurrency => 'Select Country & Currency';

  @override
  String get taxSystemPaymentFieldsSymbolWillAdapt =>
      'Tax system, payment fields & symbol will adapt';

  @override
  String get searchByCountryCurrencyOrCode =>
      'Search by country, currency or code...';

  @override
  String get upgradeToPro => 'Upgrade to Pro';

  @override
  String get paidStamp => 'PAID';

  @override
  String get overdueStamp => 'OVERDUE';

  @override
  String get due => 'DUE';

  @override
  String get dismissDialog => 'Dismiss Dialog';

  @override
  String get convertToInvoiceQuestion => 'Convert to Invoice?';

  @override
  String thisWillGenerateAnActiveInvoiceFromFor(
    String estimateNumber,
    String clientName,
  ) {
    return 'This will generate an active invoice from $estimateNumber for $clientName and mark this estimate as Converted.';
  }

  @override
  String get convertToInvoiceAction => 'Convert to Invoice';

  @override
  String get invoiceMakerProIsLocked => 'Invoice Maker Pro is locked';

  @override
  String get useYourDeviceScreenLockOrBiometricsTo =>
      'Use your device screen lock or biometrics to continue.';

  @override
  String get unlock => 'Unlock';

  @override
  String get back => 'Back';

  @override
  String get appLock => 'App lock';

  @override
  String get requireAuthentication => 'Require authentication';

  @override
  String get useYourScreenLockOrBiometrics =>
      'Use your screen lock or biometrics';

  @override
  String get lockAfter => 'Lock after';

  @override
  String get timeSpentAwayFromTheApp => 'Time spent away from the app';

  @override
  String get couldNotLoadReminderSettings =>
      'Could not load reminder settings.';

  @override
  String get couldNotUpdatePaymentRemindersPleaseTryAgain =>
      'Could not update payment reminders. Please try again.';

  @override
  String get paymentReminders => 'Payment reminders';

  @override
  String get paymentRemindersAreAvailableOnAndroidAndIos =>
      'Payment reminders are available on Android and iOS.';

  @override
  String get enableReminders => 'Enable reminders';

  @override
  String get notifyMeAboutUnpaidBalances => 'Notify me about unpaid balances';

  @override
  String get allowNotificationsInYourDeviceSettingsToTurn =>
      'Allow notifications in your device settings to turn on reminders.';

  @override
  String get beforeTheDueDate => 'Before the due date';

  @override
  String get whenOverdue => 'When overdue';

  @override
  String get off => 'Off';

  @override
  String get remindersAreScheduledFor9AmOnThe =>
      'Reminders are scheduled for 9 AM on the due date and up to three times after it.';

  @override
  String get sendTestNotification => 'Send test notification';

  @override
  String get testNotificationSent => 'Test notification sent.';

  @override
  String get enterAMessageToSend => 'Enter a message to send.';

  @override
  String get couldNotOpenSharingTryAgain =>
      'Could not open sharing. Try again.';

  @override
  String get sendReminder => 'Send reminder';

  @override
  String get close => 'Close';

  @override
  String get message => 'Message';

  @override
  String get openWhatsapp => 'Open WhatsApp';

  @override
  String get shareSms => 'Share / SMS';

  @override
  String get couldNotShareTheReceipt => 'Could not share the receipt.';

  @override
  String get couldNotOpenPrinting => 'Could not open printing.';

  @override
  String get paymentReceipt => 'Payment Receipt';

  @override
  String get shareReceipt => 'Share receipt';

  @override
  String get printReceipt => 'Print receipt';

  @override
  String get couldNotShowTheReceiptPreview =>
      'Could not show the receipt preview.';

  @override
  String get addNewClient => 'Add New Client';

  @override
  String get editClient => 'Edit Client';

  @override
  String get saveDetailsForFastInvoicing => 'Save details for fast invoicing';

  @override
  String get updateClientInformation => 'Update client information';

  @override
  String get clientName => 'Client Name *';

  @override
  String get johnDoeAcmeCorp => 'John Doe / Acme Corp';

  @override
  String get required => 'Required';

  @override
  String get email => 'Email';

  @override
  String get phone => 'Phone';

  @override
  String get address => 'Address';

  @override
  String get label123MainStCity => '123 Main St, City';

  @override
  String get addClient => 'Add Client';

  @override
  String get saveChanges => 'Save Changes';

  @override
  String get couldNotSaveTheClientPleaseTryAgain =>
      'Could not save the client. Please try again.';

  @override
  String get deleteClient => 'Delete Client?';

  @override
  String deleteTheirInvoicesAndEstimatesKeepTheClient(String clientName) {
    return 'Delete \"$clientName\"? Their invoices and estimates keep the client details. This cannot be undone.';
  }

  @override
  String get clients => 'Clients';

  @override
  String get whoYouBill => 'Who you bill';

  @override
  String get noClientsYet => 'No Clients Yet';

  @override
  String get noResults => 'No Results';

  @override
  String get saveAClientOnceAndFillTheirDetails =>
      'Save a client once and fill their details into every invoice';

  @override
  String get tryADifferentSearchTerm => 'Try a different search term';

  @override
  String get tapForHistoryHoldToEdit => 'Tap for history · hold to edit';

  @override
  String get selectClient => 'Select Client';

  @override
  String get searchClientsHint => 'Search clients...';

  @override
  String get addYourFirstClientToStartSendingInvoices =>
      'Add your first client to start sending invoices';

  @override
  String get invoicesBalance => 'Invoices & balance';

  @override
  String get editClientMenu => 'Edit client';

  @override
  String get deleteClientMenu => 'Delete client';

  @override
  String get totalInvoiced => 'Total Invoiced';

  @override
  String get paid => 'Paid';

  @override
  String get dueBalance => 'Due Balance';

  @override
  String totalsAreForInvoicesOnlyInOtherCurrencies(
    String currencyCode,
    int count,
  ) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'Totals are for $currencyCode invoices only; $countString in other currencies are not included.';
  }

  @override
  String invoiceHistoryCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'Invoices ($countString)';
  }

  @override
  String get newInvoice => 'New Invoice';

  @override
  String get noInvoicesCreatedForThisClientYet =>
      'No invoices created for this client yet';

  @override
  String get settings => 'Settings';

  @override
  String get workspace => 'Workspace';

  @override
  String get businessProfile => 'Business Profile';

  @override
  String get nameAddressBankDetailsLogo => 'Name, address, bank details, logo';

  @override
  String get reports => 'Reports';

  @override
  String get revenueCollectionsTopClientsItems =>
      'Revenue, collections, top clients & items';

  @override
  String get notificationsForUnpaidInvoices =>
      'Notifications for unpaid invoices';

  @override
  String get documentNumbering => 'Document numbering';

  @override
  String get prefixesDigitsAndFinancialYear =>
      'Prefixes, digits and financial year';

  @override
  String get security => 'Security';

  @override
  String on(String label) {
    return 'On · $label';
  }

  @override
  String get yourData => 'Your Data';

  @override
  String get exportDataJson => 'Export Data (JSON)';

  @override
  String get aFullBackupOfYourRecordsProfileAnd =>
      'A full backup of your records, profile and settings. Keep it somewhere safe.';

  @override
  String get exportToCsvExcel => 'Export to CSV / Excel';

  @override
  String get spreadsheetsForInvoicesLineItemsPaymentsClientsItems =>
      'Spreadsheets for invoices, line items, payments, clients & items';

  @override
  String get restoreFromBackup => 'Restore from backup';

  @override
  String get replaceEverythingHereWithAnExportedFile =>
      'Replace everything here with an exported file';

  @override
  String get preferences => 'Preferences';

  @override
  String get aboutSupport => 'About & Support';

  @override
  String get rateUsOnPlayStore => 'Rate Us on Play Store';

  @override
  String get leaveARatingForInvoiceMakerPro =>
      'Leave a rating for Invoice Maker Pro';

  @override
  String get helpGuide => 'Help & Guide';

  @override
  String get quickTipsAndWalkthrough => 'Quick tips and walkthrough';

  @override
  String get unlimitedInvoicesClientsNoWatermark =>
      'Unlimited invoices & clients, no watermark';

  @override
  String get goPro => 'Go Pro';

  @override
  String get proWorkspaceActive => 'Pro Workspace Active';

  @override
  String get unlimitedInvoicesCleanPdfNoWatermark =>
      'Unlimited Invoices • Clean PDF (No Watermark)';

  @override
  String get sameAsDevice => 'Same as device';

  @override
  String get light => 'Light';

  @override
  String get dark => 'Dark';

  @override
  String get appearance => 'Appearance';

  @override
  String get defaultCurrency => 'Default Currency';

  @override
  String get defaultDesignTypography => 'Default Design & Typography';

  @override
  String get defaultInvoiceDesign => 'Default invoice design';

  @override
  String customRate(String taxName) {
    return 'Custom $taxName rate';
  }

  @override
  String defaultRate(String taxName) {
    return 'Default $taxName Rate';
  }

  @override
  String editRate(String taxName) {
    return 'Edit $taxName Rate';
  }

  @override
  String get setTheDefaultTaxRateUsedWhenYou =>
      'Set the default tax rate used when you create invoices.';

  @override
  String namedTaxRatePercent(String taxName) {
    return '$taxName Rate (%)';
  }

  @override
  String exampleValue(String rate) {
    return 'e.g. $rate';
  }

  @override
  String get enterAValidNumber => 'Enter a valid number';

  @override
  String get useAValueBetween0And100 => 'Use a value between 0 and 100';

  @override
  String get reset => 'Reset';

  @override
  String get save => 'Save';

  @override
  String get couldNotExportCsvFilesPleaseTryAgain =>
      'Could not export CSV files. Please try again.';

  @override
  String invoiceMakerProDataExport(String date) {
    return 'Invoice Maker Pro data export ($date)';
  }

  @override
  String get couldNotExportYourDataPleaseTryAgain =>
      'Could not export your data. Please try again.';

  @override
  String get couldNotOpenThatFilePleaseTryAgain =>
      'Could not open that file. Please try again.';

  @override
  String get thisFileIsNotAnInvoiceMakerPro =>
      'This file is not an Invoice Maker Pro backup.';

  @override
  String backupDateContext(String date) {
    return ' from $date';
  }

  @override
  String get replaceAllData => 'Replace all data?';

  @override
  String thisBackupHasRestoringReplacesAllInvoicesEstimates(
    String date,
    String secondValue,
  ) {
    return 'This backup$date has $secondValue.\n\nRestoring replaces all invoices, estimates, clients, items and your business profile on this phone. A copy of your current data is saved first, and you can share it right after.';
  }

  @override
  String get replace => 'Replace';

  @override
  String get backupRestored => 'Backup restored.';

  @override
  String get recordsRestoredButSomeSettingsWereNotCheck =>
      'Records restored, but some settings were not. Check your business profile.';

  @override
  String get couldNotRestoreThisBackupNothingWasChanged =>
      'Could not restore this backup. Nothing was changed.';

  @override
  String get shareOldData => 'Share old data';

  @override
  String get invoiceMakerProDataSavedBeforeRestore =>
      'Invoice Maker Pro data saved before restore';

  @override
  String get discardChanges => 'Discard changes?';

  @override
  String get youHaveUnsavedChangesToYourBusinessProfile =>
      'You have unsaved changes to your business profile. Leave without saving them?';

  @override
  String get discard => 'Discard';

  @override
  String get keepEditing => 'Keep editing';

  @override
  String get pleaseFillAllRequiredFields => 'Please fill all required fields';

  @override
  String get businessProfileSavedSuccessfully =>
      'Business profile saved successfully!';

  @override
  String get couldNotOpenThatImageTryAnotherOne =>
      'Could not open that image. Try another one.';

  @override
  String get businessLogo => 'Business Logo';

  @override
  String get chooseFromGallery => 'Choose from Gallery';

  @override
  String get selectAnExistingPngOrJpegImage =>
      'Select an existing PNG or JPEG image';

  @override
  String get takePhoto => 'Take Photo';

  @override
  String get captureCompanyLogoUsingCamera =>
      'Capture company logo using camera';

  @override
  String get removeLogo => 'Remove Logo';

  @override
  String get clearCurrentLogoImage => 'Clear current logo image';

  @override
  String get couldNotOpenThatSignatureImageTryAnother =>
      'Could not open that signature image. Try another one.';

  @override
  String get authorizedSignature => 'Authorized Signature';

  @override
  String get drawSignatureOnScreen => 'Draw Signature on Screen';

  @override
  String get signSmoothlyWithYourFingerOrStylus =>
      'Sign smoothly with your finger or stylus';

  @override
  String get uploadImageFromGallery => 'Upload Image from Gallery';

  @override
  String get pngWithTransparentBackgroundRecommended =>
      'PNG with transparent background recommended';

  @override
  String get removeSignature => 'Remove Signature';

  @override
  String get clearCurrentSignature => 'Clear current signature';

  @override
  String get brandingIdentity => 'Branding & Identity';

  @override
  String get companyLogo => 'Company Logo';

  @override
  String get tapToChange => 'Tap to change';

  @override
  String get uploadLogo => 'Upload logo';

  @override
  String get drawOrUpload => 'Draw or upload';

  @override
  String get businessCompanyName => 'Business / Company Name *';

  @override
  String get eGAcmeInnovationsLlc => 'e.g. Acme Innovations LLC';

  @override
  String get businessNameIsRequired => 'Business name is required';

  @override
  String get taglineOrIndustryOptional => 'Tagline or Industry (Optional)';

  @override
  String get eGCreativeStudioDigitalAgency =>
      'e.g. Creative Studio & Digital Agency';

  @override
  String get contactLocation => 'Contact & Location';

  @override
  String get businessEmail => 'Business Email';

  @override
  String get phoneNumber => 'Phone Number';

  @override
  String get websitePortfolio => 'Website / Portfolio';

  @override
  String get registeredBusinessAddress => 'Registered Business Address';

  @override
  String get suite400100MainStreetCityStateZip =>
      'Suite 400, 100 Main Street, City, State, ZIP';

  @override
  String get taxLegalRegistration => 'Tax & Legal Registration';

  @override
  String thisWillBeDisplayedOnAllGeneratedPdfs(
    String taxIdLabel,
    String country,
  ) {
    return 'This $taxIdLabel will be displayed on all generated PDFs and estimates for $country.';
  }

  @override
  String get bankPaymentDetails => 'Bank & Payment Details';

  @override
  String paymentFieldsRoutingFormatMatchStandards(
    String country,
    String secondValue,
  ) {
    return 'Payment fields & routing format match $country ($secondValue) standards.';
  }

  @override
  String get bankName => 'Bank Name';

  @override
  String optionalFieldTitle(String digitalPaymentLabel) {
    return '$digitalPaymentLabel (Optional)';
  }

  @override
  String get defaultPaymentNotesTerms => 'Default Payment Notes & Terms';

  @override
  String get eGNet15PaymentIsDueWithin =>
      'e.g. Net 15. Payment is due within 15 days of invoice date.';

  @override
  String get saveBusinessProfile => 'Save Business Profile';

  @override
  String get yourBusinessName => 'Your Business Name';

  @override
  String get setYourBusinessIdentity => 'Set your business identity';

  @override
  String get signed => 'Signed';

  @override
  String get profileReadiness => 'Profile Readiness';

  @override
  String get useLettersDigitsHyphensOrSlashes =>
      'Use letters, digits, hyphens or slashes.';

  @override
  String get enterANumberFrom3To8 => 'Enter a number from 3 to 8.';

  @override
  String get enterAPositiveWholeNumber => 'Enter a positive whole number.';

  @override
  String get couldNotSaveDocumentSettingsPleaseTryAgain =>
      'Could not save document settings. Please try again.';

  @override
  String get couldNotLoadDocumentSettings =>
      'Could not load document settings.';

  @override
  String get invoicePrefix => 'Invoice prefix';

  @override
  String get estimatePrefix => 'Estimate prefix';

  @override
  String get numberOfDigits => 'Number of digits';

  @override
  String get startInvoiceNumbersFrom => 'Start invoice numbers from';

  @override
  String get startEstimateNumbersFrom => 'Start estimate numbers from';

  @override
  String get numbersContinueAfterTheHighestNumberInThe =>
      'Numbers continue after the highest number in the series.';

  @override
  String get addFinancialYear => 'Add financial year';

  @override
  String get theIndianFinancialYearStartsOn1April =>
      'The Indian financial year starts on 1 April.';

  @override
  String get couldNotLoadTheNextDocumentNumbers =>
      'Could not load the next document numbers.';

  @override
  String nextInvoice(String value) {
    return 'Next invoice: $value';
  }

  @override
  String nextEstimate(String value) {
    return 'Next estimate: $value';
  }

  @override
  String get drawYourSignatureAboveThenSave =>
      'Draw your signature above, then save.';

  @override
  String get thatLooksTooSmallSignAcrossThePad =>
      'That looks too small. Sign across the pad, then save.';

  @override
  String get couldNotSaveTheSignaturePleaseTryAgain =>
      'Could not save the signature. Please try again.';

  @override
  String get drawSignature => 'Draw Signature';

  @override
  String get signWithYourFingerOrStylus => 'Sign with your finger or stylus';

  @override
  String get drawInsideThisBox => 'Draw inside this box';

  @override
  String get authorizedSignatory => 'Authorized Signatory';

  @override
  String get undoStroke => 'Undo stroke';

  @override
  String get clearCanvas => 'Clear canvas';

  @override
  String get useSignature => 'Use Signature';

  @override
  String get invoiceDesignStudio => 'Invoice Design Studio';

  @override
  String get changeInvoiceStatus => 'Change Invoice Status';

  @override
  String invoiceWithNumber(String invoiceNumber) {
    return 'Invoice $invoiceNumber';
  }

  @override
  String get unpaid => 'Unpaid';

  @override
  String get deletesRecordedPayments => 'Deletes recorded payments';

  @override
  String get recordAPayment => 'Record a payment';

  @override
  String get addADepositOrPartPayment => 'Add a deposit or part payment';

  @override
  String get paidInFull => 'Paid in Full';

  @override
  String get paymentReceivedSuccessfully => 'Payment received successfully';

  @override
  String get couldNotOpenTheReceipt => 'Could not open the receipt.';

  @override
  String get moreActions => 'More Actions';

  @override
  String get changeDesign => 'Change Design';

  @override
  String designThemeSummary(String value) {
    return '$value · typography, colours & layout';
  }

  @override
  String get duplicateInvoice => 'Duplicate Invoice';

  @override
  String get createANewCopyWithSameItems => 'Create a new copy with same items';

  @override
  String get markAsUnpaid => 'Mark as Unpaid';

  @override
  String get markAsPaid => 'Mark as Paid';

  @override
  String get deletesTheRecordedPayments => 'Deletes the recorded payments';

  @override
  String get recordsAPaymentForTheBalance =>
      'Records a payment for the balance';

  @override
  String get payments => 'Payments';

  @override
  String get seeRecordOrDeletePayments => 'See, record or delete payments';

  @override
  String get editAndShareAPaymentReminderWithYour =>
      'Edit and share a payment reminder with your client';

  @override
  String get receipt => 'Receipt';

  @override
  String get previewAReceiptForAllRecordedPayments =>
      'Preview a receipt for all recorded payments';

  @override
  String get deleteInvoice => 'Delete Invoice';

  @override
  String get permanentlyRemoveThisInvoice => 'Permanently remove this invoice';

  @override
  String duplicatedAsDatedTodayAndUnpaid(String invoiceNumber) {
    return 'Duplicated as $invoiceNumber, dated today and unpaid';
  }

  @override
  String get couldNotDuplicateTheInvoicePleaseTryAgain =>
      'Could not duplicate the invoice. Please try again.';

  @override
  String get design => 'Design';

  @override
  String dueDateAndClient(String date, String clientName) {
    return 'Due $date • $clientName';
  }

  @override
  String get sendInvoice => 'Send Invoice';

  @override
  String get expandDetails => 'Expand details';

  @override
  String clientAndDueDate(String clientName, String date) {
    return '$clientName  ·  Due $date';
  }

  @override
  String get tapToMarkAsNotSent => 'Tap to mark as not sent';

  @override
  String get tapToMarkAsSent => 'Tap to mark as sent';

  @override
  String get sent => 'Sent';

  @override
  String get notSent => 'Not sent';

  @override
  String paidAmountLabel(String amount) {
    return 'Paid: $amount';
  }

  @override
  String balanceDue(String amount) {
    return 'Balance Due: $amount';
  }

  @override
  String get download => 'Download';

  @override
  String get print => 'Print';

  @override
  String get edit => 'Edit';

  @override
  String get more => 'More';

  @override
  String get camera => 'Camera';

  @override
  String get gallery => 'Gallery';

  @override
  String get couldNotAddThePhotoPleaseTryAgain =>
      'Could not add the photo. Please try again.';

  @override
  String get photoUnavailable => 'Photo unavailable';

  @override
  String get attachments => 'Attachments';

  @override
  String get addAttachment => 'Add attachment';

  @override
  String get pleaseAddAClientNameBillTo =>
      'Please add a client name (Bill To).';

  @override
  String get pleaseAddAtLeastOneLineItem =>
      'Please add at least one line item.';

  @override
  String invoiceNumberIsAlreadyUsedPickAnotherNumber(String value) {
    return 'Invoice number $value is already used. Pick another number.';
  }

  @override
  String get couldNotSaveTheInvoicePleaseTryAgain =>
      'Could not save the invoice. Please try again.';

  @override
  String get invoiceDetailsDates => 'Invoice Details & Dates';

  @override
  String get invoiceNumber => 'Invoice Number';

  @override
  String get eGInv00001 => 'e.g. INV00001';

  @override
  String get invoiceIssueDate => 'Invoice Issue Date';

  @override
  String get paymentTermsDueDate => 'Payment Terms & Due Date';

  @override
  String get optionalCreditPeriodForPayment =>
      'Optional credit period for payment';

  @override
  String get noDueDate => 'No Due Date';

  @override
  String get dueOnReceipt => 'Due on Receipt';

  @override
  String get label7Days => '+7 Days';

  @override
  String get label15Days => '+15 Days';

  @override
  String get label30Days => '+30 Days';

  @override
  String get customDate => 'Custom Date...';

  @override
  String get applyChanges => 'Apply Changes';

  @override
  String get billFromYourBusiness => 'Bill From (Your Business)';

  @override
  String get businessName => 'Business Name *';

  @override
  String get saveBusinessInfo => 'Save Business Info';

  @override
  String get editItem => 'Edit Item';

  @override
  String get addItem => 'Add Item';

  @override
  String get description => 'Description *';

  @override
  String get eGConsultingDesignProduct => 'e.g. Consulting, Design, Product';

  @override
  String get quantity => 'Quantity';

  @override
  String get unitPrice => 'Unit Price';

  @override
  String get hideItemDiscountTax => 'Hide Item Discount & Tax';

  @override
  String get addItemDiscountTax => '+ Add Item Discount & Tax';

  @override
  String get discountRequiredAmountLabel => 'Discount (%)';

  @override
  String get taxRate => 'Tax Rate (%)';

  @override
  String get invoiceRate => 'Invoice rate';

  @override
  String get baseAmount => 'Base Amount:';

  @override
  String discountPercentLabel(String rate) {
    return 'Discount ($rate%):';
  }

  @override
  String taxAtAddedInTotals(String rate) {
    return 'Tax at $rate% (added in totals):';
  }

  @override
  String get lineAmountBeforeTax => 'Line amount (before tax):';

  @override
  String get pleaseEnterAnItemDescription => 'Please enter an item description';

  @override
  String get quantityMustBeMoreThan0 => 'Quantity must be more than 0';

  @override
  String get updateItem => 'Update Item';

  @override
  String get addToInvoice => 'Add to Invoice';

  @override
  String get addDiscount => 'Add Discount';

  @override
  String get percentage => 'Percentage (%)';

  @override
  String flatAmount(String currencySymbol) {
    return 'Flat Amount ($currencySymbol)';
  }

  @override
  String get discountPercentage => 'Discount Percentage (%)';

  @override
  String get discountAmount => 'Discount Amount';

  @override
  String get applyDiscount => 'Apply Discount';

  @override
  String configureNamedTax(String taxName) {
    return '$taxName Configuration';
  }

  @override
  String get chooseCgstSgstIntraStateOrIgstInter =>
      'Choose CGST + SGST (intra-state) or IGST (inter-state)';

  @override
  String setPercentageToApplyToThisInvoice(String taxName) {
    return 'Set $taxName percentage to apply to this invoice.';
  }

  @override
  String get noTax0 => 'No Tax (0%)';

  @override
  String get igstSingle => 'IGST (Single)';

  @override
  String get igstRate => 'IGST Rate (%)';

  @override
  String get removeTax => 'Remove Tax';

  @override
  String get applyTax => 'Apply Tax';

  @override
  String get shippingCharges => 'Shipping Charges';

  @override
  String shippingFee(String currencySymbol) {
    return 'Shipping Fee ($currencySymbol)';
  }

  @override
  String get saveShippingFee => 'Save Shipping Fee';

  @override
  String get amountAlreadyReceived => 'Amount already received';

  @override
  String amountPaid(String currencySymbol) {
    return 'Amount Paid ($currencySymbol)';
  }

  @override
  String get selectPaymentMethod => 'Select Payment Method';

  @override
  String get termsNotes => 'Terms & Notes';

  @override
  String get termsSlashNotes => 'Terms / Notes';

  @override
  String get eGThanksForYourBusiness => 'e.g. Thanks for your business.';

  @override
  String get saveNotes => 'Save Notes';

  @override
  String get markInvoiceAs => 'Mark Invoice As';

  @override
  String get deleteInvoiceQuestion => 'Delete Invoice?';

  @override
  String get areYouSureYouWantToDeleteThis =>
      'Are you sure you want to delete this invoice? This action cannot be undone.';

  @override
  String get youHaveUnsavedChangesLeaveWithoutSavingThem =>
      'You have unsaved changes. Leave without saving them?';

  @override
  String get addClients => 'Add Clients';

  @override
  String get editInvoice => 'Edit Invoice';

  @override
  String get createInvoice => 'Create Invoice';

  @override
  String get clearItems => 'Clear Items';

  @override
  String get resetHelpfulTips => 'Reset Helpful Tips';

  @override
  String get invoiceHeading => 'INVOICE';

  @override
  String dueDateLabel(String date) {
    return 'Due $date';
  }

  @override
  String get templates => 'Templates';

  @override
  String get chooseStylePaperDesign => 'Choose style & paper design';

  @override
  String get billFrom => 'Bill From';

  @override
  String get addBusiness => 'Add Business';

  @override
  String get billTo => 'Bill To';

  @override
  String get addYourClientOrCustomer => 'Add your client or customer';

  @override
  String get selectAnExistingClientOrCreateANew =>
      'Select an existing client or create a new one to bill';

  @override
  String get items => 'Items';

  @override
  String get addItems => 'Add Items';

  @override
  String get createYourItemOrService => 'Create your item or service';

  @override
  String get addNamePriceQuantityAndDetails =>
      'Add name, price, quantity and details';

  @override
  String get discount => 'Discount';

  @override
  String get shipping => 'Shipping';

  @override
  String get total => 'Total';

  @override
  String get configureDiscountTaxOrShipping =>
      'Configure discount, tax or shipping';

  @override
  String applyRatesDiscountsOrShippingCharges(String taxName) {
    return 'Apply $taxName rates, discounts or shipping charges';
  }

  @override
  String get balanceDueHeading => 'Balance Due';

  @override
  String get currency => 'Currency';

  @override
  String get paymentMethod => 'Payment Method';

  @override
  String get signature => 'Signature';

  @override
  String get signatureAttached => 'Signature Attached';

  @override
  String get addSignature => 'Add Signature';

  @override
  String get termsOrNotes => 'Terms or notes';

  @override
  String get thanksForYourBusiness => 'Thanks for your business.';

  @override
  String get setPaymentMethodSignature => 'Set payment method & signature';

  @override
  String get addUpiBankDetailsNotesOrYourSignature =>
      'Add UPI, bank details, notes or your signature';

  @override
  String get markAs => 'Mark as';

  @override
  String get preview => 'Preview';

  @override
  String invoiceFor(String invoiceNumber, String clientName) {
    return 'Invoice $invoiceNumber for $clientName';
  }

  @override
  String get markAsSent => 'Mark as sent?';

  @override
  String didYouSendTo(String invoiceNumber, String clientName) {
    return 'Did you send $invoiceNumber to $clientName?';
  }

  @override
  String get notYet => 'Not yet';

  @override
  String get markAsSentAction => 'Mark as sent';

  @override
  String get couldNotShareTheInvoicePleaseTryAgain =>
      'Could not share the invoice. Please try again.';

  @override
  String savedTo(String name, String secondValue) {
    return 'Saved $name to $secondValue';
  }

  @override
  String get view => 'View';

  @override
  String get noAppFoundToOpenPdfsInstallA =>
      'No app found to open PDFs. Install a PDF viewer to open it.';

  @override
  String get couldNotSaveThePdfPleaseTryAgain =>
      'Could not save the PDF. Please try again.';

  @override
  String get markUnpaidQuestion => 'Mark as unpaid?';

  @override
  String get deletePayments => 'Delete payments';

  @override
  String get couldNotUpdateThePaymentPleaseTryAgain =>
      'Could not update the payment. Please try again.';

  @override
  String get couldNotOpenPrintingPleaseTryAgain =>
      'Could not open printing. Please try again.';

  @override
  String deleteThisCannotBeUndone(String invoiceNumber) {
    return 'Delete $invoiceNumber? This cannot be undone.';
  }

  @override
  String get couldNotDeleteTheInvoicePleaseTryAgain =>
      'Could not delete the invoice. Please try again.';

  @override
  String get paymentRecorded => 'Payment recorded';

  @override
  String get sendReceipt => 'Send receipt';

  @override
  String get deletePayment => 'Delete payment?';

  @override
  String deleteThePaymentFrom(String amount, String date) {
    return 'Delete the $amount payment from $date?';
  }

  @override
  String invoiceTotal(String invoiceNumber, String amount) {
    return 'Invoice $invoiceNumber · Total $amount';
  }

  @override
  String get received => 'Received';

  @override
  String get overpaidBy => 'Overpaid by';

  @override
  String get balanceDueLabel => 'Balance due';

  @override
  String get noPaymentsRecordedYet => 'No payments recorded yet.';

  @override
  String get deletePayment2 => 'Delete payment';

  @override
  String get recordPayment => 'Record payment';

  @override
  String get amountReceived => 'Amount received';

  @override
  String get enterAnAmountAbove0 => 'Enter an amount above 0';

  @override
  String remainingAmountLabel(String amount) {
    return 'Balance due: $amount';
  }

  @override
  String get dateReceived => 'Date received';

  @override
  String get noteOptional => 'Note (optional)';

  @override
  String get savePayment => 'Save payment';

  @override
  String get livePreviewUpdatesInstantly => 'Live preview updates instantly';

  @override
  String get updating => 'Updating...';

  @override
  String get quickLook => 'Quick Look';

  @override
  String get fit => 'Fit';

  @override
  String get style => 'Style';

  @override
  String get typo => 'Typo';

  @override
  String get layout => 'Layout';

  @override
  String get sections => 'Sections';

  @override
  String get setAsDefaultStyleForFutureDocuments =>
      'Set as default style for future documents';

  @override
  String get applySaveStyle => 'Apply & Save Style';

  @override
  String get paperDesignTemplate => 'Paper Design Template';

  @override
  String get colorPalettePresets => 'Color Palette Presets';

  @override
  String get fontFamily => 'Font Family';

  @override
  String get documentDensitySizing => 'Document Density & Sizing';

  @override
  String get label85Scale => '85% Scale';

  @override
  String get label100Normal => '100% Normal';

  @override
  String get label115Large => '115% Large';

  @override
  String get headerAlignmentPosition => 'Header Alignment & Position';

  @override
  String get addressBlockArrangement => 'Address Block Arrangement';

  @override
  String get documentSectionsVisibility => 'Document Sections Visibility';

  @override
  String get bankPaymentDetails2 => 'Bank Payment Details';

  @override
  String get bankNameAccountNumberRoutingCode =>
      'Bank name, account number & routing code';

  @override
  String get digitalUpiPaymentId => 'Digital UPI / Payment ID';

  @override
  String get upiIdAndFastPaymentHandle => 'UPI ID and fast payment handle';

  @override
  String get signatureSignOff => 'Signature & Sign-Off';

  @override
  String get authorizedSignatureBoxInFooter =>
      'Authorized signature box in footer';

  @override
  String get notesTerms => 'Notes & Terms';

  @override
  String get customerNotesContainer => 'Customer notes container';

  @override
  String get tableColumns => 'Table Columns';

  @override
  String get quantityQtyColumn => 'Quantity (QTY) Column';

  @override
  String get numberOfUnitsOrHours => 'Number of units or hours';

  @override
  String get unitPriceColumn => 'Unit Price Column';

  @override
  String get individualItemRate => 'Individual item rate';

  @override
  String get customFooterClosingMessage => 'Custom Footer Closing Message';

  @override
  String get eGThankYouForYourBusiness => 'e.g. Thank you for your business!';

  @override
  String get photosOnAppendixPages => 'Photos on appendix pages';

  @override
  String get statusStampPaidOverdue => 'Status stamp (Paid / Overdue)';

  @override
  String get paymentStatusInTheInvoiceHeader =>
      'Payment status in the invoice header';

  @override
  String get quickLookPreview => 'Quick Look Preview';

  @override
  String get renderingHighDpi300Dpi => 'Rendering High-DPI (300 DPI)...';

  @override
  String get doubleTapToResetView => 'Double-tap to reset view';

  @override
  String get pinchOrDoubleTapToZoomIn => 'Pinch or double-tap to zoom in';

  @override
  String get all => 'All';

  @override
  String get defaultInvoiceFields => 'Default invoice fields';

  @override
  String get customFields => 'Custom fields';

  @override
  String get theseLabelsAppearOnNewInvoicesWithEmpty =>
      'These labels appear on new invoices with empty values.';

  @override
  String get label => 'Label';

  @override
  String get value => 'Value';

  @override
  String get removeField => 'Remove field';

  @override
  String get addField => 'Add field';

  @override
  String get chooseInvoiceStyle => 'Choose Invoice Style';

  @override
  String get customizeDesignTypography => 'Customize Design & Typography';

  @override
  String get changeFontFamilySizingScaleElementLayout =>
      'Change font family, sizing scale & element layout';

  @override
  String get alwaysUseThisStyleAsDefault => 'Always use this style as default';

  @override
  String get applySelectedStyle => 'Apply Selected Style';

  @override
  String get aConvertedEstimateKeepsItsStatusDeleteIts =>
      'A converted estimate keeps its status. Delete its invoice to change it.';

  @override
  String convertedToInvoice(String invoiceNumber) {
    return 'Converted to Invoice $invoiceNumber';
  }

  @override
  String get viewActionUppercase => 'VIEW';

  @override
  String estimateFor(String estimateNumber, String clientName) {
    return 'Estimate $estimateNumber for $clientName';
  }

  @override
  String get couldNotShareTheEstimatePleaseTryAgain =>
      'Could not share the estimate. Please try again.';

  @override
  String get estimates => 'Estimates';

  @override
  String get quotesProposals => 'Quotes & proposals';

  @override
  String get pending => 'Pending';

  @override
  String get accepted => 'Accepted';

  @override
  String get estimated => 'Estimated';

  @override
  String get converted => 'Converted';

  @override
  String get declined => 'Declined';

  @override
  String get noEstimatesYet => 'No Estimates Yet';

  @override
  String get noResultsFound => 'No Results Found';

  @override
  String get sendAPriceBeforeYouBillAcceptedQuotes =>
      'Send a price before you bill. Accepted quotes turn into invoices in one tap.';

  @override
  String get tryAnotherSearchOrFilter => 'Try another search or filter';

  @override
  String get createEstimate => 'Create Estimate';

  @override
  String get swipeRightToConvertHoldForMore =>
      'Swipe right to convert · hold for more';

  @override
  String get viewDetails => 'View details';

  @override
  String get sharePdf => 'Share PDF';

  @override
  String get markAccepted => 'Mark accepted';

  @override
  String get markDeclined => 'Mark declined';

  @override
  String get markPending => 'Mark pending';

  @override
  String get deleteEstimate => 'Delete estimate';

  @override
  String get noClient => 'No client';

  @override
  String get convert => 'Convert';

  @override
  String get share => 'Share';

  @override
  String get estimateDesignStudio => 'Estimate Design Studio';

  @override
  String estimateMarkedAs(String label) {
    return 'Estimate marked as $label';
  }

  @override
  String get updateStatus => 'Update Status';

  @override
  String estimate(String estimateNumber) {
    return 'Estimate $estimateNumber';
  }

  @override
  String get waitingForClientApproval => 'Waiting for client approval';

  @override
  String get clientHasApprovedThisEstimate =>
      'Client has approved this estimate';

  @override
  String get estimateWasNotAccepted => 'Estimate was not accepted';

  @override
  String valid(String date) {
    return 'Valid: $date';
  }

  @override
  String get pleaseEnterOrSelectAClientName =>
      'Please enter or select a client name';

  @override
  String get addLineItemValidation => 'Please add at least one line item';

  @override
  String estimateNumberIsAlreadyUsedPickAnotherNumber(String value) {
    return 'Estimate number $value is already used. Pick another number.';
  }

  @override
  String get couldNotSaveTheEstimatePleaseTryAgain =>
      'Could not save the estimate. Please try again.';

  @override
  String get addItemService => 'Add Item / Service';

  @override
  String get enterDescriptionQuantityRate =>
      'Enter description, quantity & rate';

  @override
  String get descriptionItemName => 'Description / Item Name *';

  @override
  String get eGWebsiteDesignConsultationParts =>
      'e.g. Website Design, Consultation, Parts';

  @override
  String get requiredQuantity => 'Quantity *';

  @override
  String get invalid => 'Invalid';

  @override
  String get requiredUnitPrice => 'Unit Price *';

  @override
  String get addToEstimate => 'Add to Estimate';

  @override
  String get editEstimate => 'Edit Estimate';

  @override
  String get pdfTemplates => 'PDF Templates';

  @override
  String get estimateNumber => 'Estimate Number *';

  @override
  String get estimateDate => 'Estimate Date';

  @override
  String get validUntilExpiry => 'Valid Until / Expiry';

  @override
  String get noExpiry => 'No Expiry';

  @override
  String get quickValidity => 'Quick Validity: ';

  @override
  String get validForSevenDays => '7 Days';

  @override
  String get validForFourteenDays => '14 Days';

  @override
  String get validForThirtyDays => '30 Days';

  @override
  String get pdfTheme => 'PDF Theme';

  @override
  String get billToClient => 'Bill To (Client) *';

  @override
  String get selectAddClient => 'Select / Add Client';

  @override
  String get johnDoeApexCorp => 'John Doe / Apex Corp';

  @override
  String get itemsServices => 'Items & Services';

  @override
  String get catalog => 'Catalog';

  @override
  String get noItemsAddedYet => 'No items added yet';

  @override
  String get subtotal => 'Subtotal';

  @override
  String get tax => 'Tax';

  @override
  String get taxAmount => 'Tax Amount';

  @override
  String get totalEstimated => 'Total Estimated';

  @override
  String get eGEstimateValidFor30DaysPayment =>
      'e.g. Estimate valid for 30 days. Payment terms...';

  @override
  String get previewPdf => 'Preview PDF';

  @override
  String get saveEstimate => 'Save Estimate';

  @override
  String get thisEstimateIsAlreadyConvertedToAnInvoice =>
      'This estimate is already converted to an invoice.';

  @override
  String get couldNotConvertTheEstimatePleaseTryAgain =>
      'Could not convert the estimate. Please try again.';

  @override
  String get deleteEstimateQuestion => 'Delete Estimate?';

  @override
  String get couldNotDeleteTheEstimatePleaseTryAgain =>
      'Could not delete the estimate. Please try again.';

  @override
  String get couldNotRefreshInvoicesPullDownToTry =>
      'Could not refresh invoices. Pull down to try again.';

  @override
  String get dueToday => 'Due today';

  @override
  String get dueTomorrow => 'Due tomorrow';

  @override
  String nothingIsLeftToPayOn(String invoiceNumber) {
    return 'Nothing is left to pay on $invoiceNumber.';
  }

  @override
  String invoiceMarkedPaid(String invoiceNumber) {
    return '$invoiceNumber marked paid';
  }

  @override
  String get undo => 'Undo';

  @override
  String get couldNotUndoRemoveThePaymentFromThe =>
      'Could not undo. Remove the payment from the invoice instead.';

  @override
  String get payment => 'Payment';

  @override
  String get recordsTheBalanceAsReceivedToday =>
      'Records the balance as received today';

  @override
  String get part => 'PART';

  @override
  String get editInvoiceMenu => 'Edit invoice';

  @override
  String get paymentStatus => 'Payment status';

  @override
  String get savePdf => 'Save PDF';

  @override
  String get deleteInvoiceMenu => 'Delete invoice';

  @override
  String get swipeRightToMarkPaidHoldForMore =>
      'Swipe right to mark paid · hold for more';

  @override
  String get invoices => 'Invoices';

  @override
  String get profileIncomplete => 'Profile incomplete';

  @override
  String get toCollect => 'TO COLLECT';

  @override
  String get collected => 'Collected ';

  @override
  String totalsAreForInvoicesOnlyNotIncluded(
    String currencyCode,
    String excludedCurrencies,
  ) {
    return 'Totals are for $currencyCode invoices only. Not included: $excludedCurrencies.';
  }

  @override
  String get needsYou => 'Needs you';

  @override
  String get markPaid => 'Mark paid';

  @override
  String get overdue => 'Overdue';

  @override
  String get partiallyPaid => 'Partially Paid';

  @override
  String get nothingHere => 'Nothing here';

  @override
  String noInvoicesMatch(String searchQuery) {
    return 'No invoices match \"$searchQuery\"';
  }

  @override
  String get showAll => 'Show all';

  @override
  String get newStamp => 'NEW';

  @override
  String get yourFirstInvoice => 'Your first invoice';

  @override
  String get makeOneInUnderAMinuteTapBelow =>
      'Make one in under a minute. Tap + below any time.';

  @override
  String get changePaymentStatus => 'Change payment status';

  @override
  String get finishSettingUp => 'Finish setting up';

  @override
  String get hide => 'Hide';

  @override
  String get pickFromCatalog => 'Pick from Catalog';

  @override
  String get newAction => 'New';

  @override
  String get searchItemsHint => 'Search items...';

  @override
  String plusTaxPercent(String rate) {
    return '+$rate% Tax';
  }

  @override
  String noItemsMatch(String searchQuery) {
    return 'No items match \"$searchQuery\"';
  }

  @override
  String get noSavedItemsYet => 'No saved items yet';

  @override
  String get createItemsInYourCatalogToQuicklyAdd =>
      'Create items in your catalog to quickly add them here';

  @override
  String get createNewItem => 'Create New Item';

  @override
  String get pieces => 'Pieces';

  @override
  String get hours => 'Hours';

  @override
  String get days => 'Days';

  @override
  String get kilograms => 'Kilograms';

  @override
  String get grams => 'Grams';

  @override
  String get litres => 'Litres';

  @override
  String get millilitres => 'Millilitres';

  @override
  String get feet => 'Feet';

  @override
  String get metres => 'Metres';

  @override
  String get sqFeet => 'Sq. Feet';

  @override
  String get sqMetres => 'Sq. Metres';

  @override
  String get boxes => 'Boxes';

  @override
  String get units => 'Units';

  @override
  String get lots => 'Lots';

  @override
  String get label0To100 => '0 to 100';

  @override
  String get newItem => 'New Item';

  @override
  String get itemName => 'Item Name *';

  @override
  String get eGWebDesignConsultingTShirt =>
      'e.g. Web Design, Consulting, T-Shirt';

  @override
  String get itemNameIsRequired => 'Item name is required';

  @override
  String get itemDescription => 'Description';

  @override
  String get optionalDetailsAboutThisItemOrService =>
      'Optional details about this item or service';

  @override
  String get mustBe0OrMore => 'Must be 0 or more';

  @override
  String get defaultQty => 'Default Qty';

  @override
  String get moreThan0 => 'More than 0';

  @override
  String get unitOfMeasurement => 'Unit of Measurement';

  @override
  String get category => 'Category';

  @override
  String get eGDesignDevelopmentProducts =>
      'e.g. Design, Development, Products';

  @override
  String get hsnSacCode => 'HSN / SAC Code';

  @override
  String get eG998311 => 'e.g. 998311';

  @override
  String get itemDiscount => 'Item Discount';

  @override
  String get setADefaultPercentageDiscountForThisItem =>
      'Set a default percentage discount for this item';

  @override
  String get none0 => 'None (0%)';

  @override
  String get taxConfiguration => 'Tax Configuration';

  @override
  String get specifyWhetherTaxAppliesAndTheItemTax =>
      'Specify whether tax applies and the item tax rate';

  @override
  String get applyTaxToThisItem => 'Apply Tax to this Item';

  @override
  String get eG18 => 'e.g. 18';

  @override
  String get label0Exempt => '0% (Exempt)';

  @override
  String get estimatedItemTotal => 'Estimated Item Total';

  @override
  String base(String rate, String amount) {
    return 'Base ($rate × $amount)';
  }

  @override
  String itemDiscountPercent(String rate) {
    return 'Item Discount ($rate%)';
  }

  @override
  String taxPercent(String rate) {
    return 'Tax ($rate%)';
  }

  @override
  String get netItemTotal => 'Net Item Total:';

  @override
  String get saveItem => 'Save Item';

  @override
  String duplicated(String value) {
    return 'Duplicated \"$value\"';
  }

  @override
  String get deleteItem => 'Delete Item?';

  @override
  String deleteThisWonTAffectExistingInvoices(String value) {
    return 'Delete \"$value\"? This won\'t affect existing invoices.';
  }

  @override
  String get productsServices => 'Products & services';

  @override
  String get uncategorized => 'Uncategorized';

  @override
  String get tapToEditHoldForMore => 'Tap to edit · hold for more';

  @override
  String get noItemsYet => 'No Items Yet';

  @override
  String get saveYourProductsServicesHereToQuicklyAdd =>
      'Save your products & services here to quickly add them to invoices';

  @override
  String get noItemsInThisCategory => 'No items in this category';

  @override
  String get addYourFirstItem => 'Add Your First Item';

  @override
  String get editItemMenu => 'Edit item';

  @override
  String get duplicate => 'Duplicate';

  @override
  String get deleteItemMenu => 'Delete item';

  @override
  String itemTaxPercent(String rate) {
    return 'Tax $rate%';
  }

  @override
  String get taxExempt => 'Tax exempt';

  @override
  String percentOff(String rate) {
    return '$rate% off';
  }

  @override
  String perUnit(String value) {
    return 'per $value';
  }

  @override
  String get proIsActiveThankYou => 'Pro is active. Thank you!';

  @override
  String get noProPurchaseWasFoundForThisGoogle =>
      'No Pro purchase was found for this Google account.';

  @override
  String get googlePlayPurchasesAreNotAvailableRightNow =>
      'Google Play purchases are not available right now. Check your connection and try again.';

  @override
  String get upgrade => 'UPGRADE';

  @override
  String get billWithoutLimits => 'Bill without\nlimits.';

  @override
  String get oneUpgradeUnlocksEveryInvoiceEveryClientAnd =>
      'One upgrade unlocks every invoice, every client, and clean PDFs with only your brand on them.';

  @override
  String get whatSIncluded => 'WHAT\'S INCLUDED';

  @override
  String get unlimitedInvoicesEstimates => 'Unlimited Invoices & Estimates';

  @override
  String paywallMonthlyDocumentLimit(int value) {
    final intl.NumberFormat valueNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String valueString = valueNumberFormat.format(value);

    return 'The free plan includes $valueString of each per calendar month.';
  }

  @override
  String get unlimitedClients => 'Unlimited Clients';

  @override
  String paywallSavedClientLimit(int value) {
    final intl.NumberFormat valueNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String valueString = valueNumberFormat.format(value);

    return 'The free plan saves up to $valueString clients.';
  }

  @override
  String get noWatermark => 'No Watermark';

  @override
  String get removesGeneratedByInvoiceMakerProFromYour =>
      'Removes \"Generated by Invoice Maker Pro\" from your PDFs.';

  @override
  String get totalHeading => 'TOTAL';

  @override
  String monthlyPrice(String amount) {
    return '$amount / month';
  }

  @override
  String get lifetime => 'Lifetime';

  @override
  String get payOnceKeepProForGood => 'Pay once, keep Pro for good';

  @override
  String get oneTime => 'one-time';

  @override
  String get bestValue => 'BEST VALUE';

  @override
  String get monthly => 'Monthly';

  @override
  String get cancelAnyTimeInGooglePlay => 'Cancel any time in Google Play';

  @override
  String get unlockLifetimeAccess => 'Unlock Lifetime Access';

  @override
  String subscribeFor(String value) {
    return 'Subscribe for $value';
  }

  @override
  String get onePaymentProStaysActiveOnThisGoogle =>
      'One payment. Pro stays active on this Google account for good.';

  @override
  String get renewsEveryMonthAtThePriceAboveUntil =>
      'Renews every month at the price above until you cancel. Cancel anytime in Google Play > Payments & subscriptions.';

  @override
  String get restorePurchase => 'Restore purchase';

  @override
  String get couldNotSaveYourDetailsPleaseTryAgain =>
      'Could not save your details. Please try again.';

  @override
  String get skip => 'Skip';

  @override
  String get getPaidBeautifully => 'Get paid,\nbeautifully.';

  @override
  String get makeAnInvoiceInUnderAMinuteStamp =>
      'Make an invoice in under a minute. Stamp it paid when the money lands.';

  @override
  String get startTheTour => 'Start the tour';

  @override
  String get getStarted => 'Get started';

  @override
  String get takesAboutAMinute => 'Takes about a minute';

  @override
  String get invoiceLabel => 'Invoice';

  @override
  String get billToStudioNorth => 'Bill to  ·  Studio North';

  @override
  String get logoDesign => 'Logo design';

  @override
  String get brandGuide => 'Brand guide';

  @override
  String get yourBusiness => 'Your business';

  @override
  String get thisSitsAtTheTopOfEveryInvoice =>
      'This sits at the top of every invoice. You can change it any time.';

  @override
  String get businessOrYourName => 'Business or your name';

  @override
  String get addressOptional => 'Address (optional)';

  @override
  String get emailOptional => 'Email (optional)';

  @override
  String get phoneOptional => 'Phone (optional)';

  @override
  String get continueAction => 'Continue';

  @override
  String get addLogo => 'Add logo';

  @override
  String get changeLogo => 'Change logo';

  @override
  String get logo => 'Logo';

  @override
  String get yourBusinessPlaceholder => 'Your Business';

  @override
  String get emailPhone => 'email  ·  phone';

  @override
  String aGstinIs15CharactersLike(String value) {
    return 'A GSTIN is 15 characters, like $value.';
  }

  @override
  String get aUpiIdLooksLikeNameBank => 'A UPI ID looks like name@bank.';

  @override
  String get howYouBill => 'How you bill';

  @override
  String get newInvoicesStartWithTheseEachInvoiceCan =>
      'New invoices start with these. Each invoice can still change them.';

  @override
  String get currencyHeading => 'CURRENCY';

  @override
  String get moreChoices => 'More…';

  @override
  String get taxHeading => 'TAX';

  @override
  String namedTaxHeading(String taxName) {
    return 'TAX · $taxName';
  }

  @override
  String get noTax => 'No tax';

  @override
  String optionalField(String taxIdLabel) {
    return '$taxIdLabel (optional)';
  }

  @override
  String get paymentDue => 'PAYMENT DUE';

  @override
  String get gettingPaid => 'Getting paid';

  @override
  String get printedOnEveryInvoiceSoClientsKnowHow =>
      'Printed on every invoice so clients know how to pay you. All optional.';

  @override
  String get bankTransfer => 'BANK TRANSFER';

  @override
  String get bankNameSentenceCase => 'Bank name';

  @override
  String get skipForNow => 'Skip for now';

  @override
  String get ready => 'READY';

  @override
  String get youReAllSet => 'You\'re all set.';

  @override
  String setupCompleteFor(String firstName) {
    return 'You\'re all set,\n$firstName.';
  }

  @override
  String get thatSTheTourNothingWasChanged =>
      'That\'s the tour. Nothing was changed.';

  @override
  String get yourFirstInvoiceIsOneTapAwayTap =>
      'Your first invoice is one tap away. Tap + at the bottom any time to make another.';

  @override
  String onboardingFreePlanLimit(int value) {
    final intl.NumberFormat valueNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String valueString = valueNumberFormat.format(value);

    return 'Free plan: $valueString invoices a month. Upgrade any time in Settings.';
  }

  @override
  String get seeASampleWithYourDetails => 'See a sample with your details';

  @override
  String get createMyFirstInvoice => 'Create my first invoice';

  @override
  String get backToSettings => 'Back to settings';

  @override
  String get iLlLookAroundFirst => 'I\'ll look around first';

  @override
  String get sampleInvoice => 'Sample invoice';

  @override
  String get yourDetailsOnAMadeUpInvoiceNothing =>
      'Your details on a made-up invoice. Nothing is saved.';

  @override
  String get couldNotLoadReportsPullDownToTry =>
      'Could not load reports. Pull down to try again.';

  @override
  String get couldNotShareSummaryPleaseTryAgain =>
      'Could not share summary. Please try again.';

  @override
  String get shareSummary => 'Share summary';

  @override
  String get noReportsYet => 'No reports yet';

  @override
  String get nothingInThisRange => 'Nothing in this range';

  @override
  String get createAnInvoiceToTrackBilledRevenueCollections =>
      'Create an invoice to track billed revenue, collections, taxes, and top clients.';

  @override
  String noInvoicesMatchInvoicesInOtherCurrencies(
    String currencyCode,
    String label,
    String excludedCurrencies,
  ) {
    return 'No $currencyCode invoices match $label. Invoices in other currencies: $excludedCurrencies.';
  }

  @override
  String noInvoicesOrPaymentsMatchTryAnotherDate(String label) {
    return 'No invoices or payments match $label. Try another date range or pull down to refresh.';
  }

  @override
  String get custom => 'Custom';

  @override
  String get today => 'Today';

  @override
  String get thisWeek => 'This week';

  @override
  String get thisMonth => 'This month';

  @override
  String get thisYear => 'This year';

  @override
  String get allTime => 'All time';

  @override
  String percentOfBilled(int value) {
    final intl.NumberFormat valueNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String valueString = valueNumberFormat.format(value);

    return '$valueString% of billed';
  }

  @override
  String get paymentsReceived => 'Payments received';

  @override
  String get billed => 'BILLED';

  @override
  String get collectedHeading => 'COLLECTED';

  @override
  String get outstanding => 'OUTSTANDING';

  @override
  String get balanceRemaining => 'Balance remaining';

  @override
  String get taxCollected => 'TAX COLLECTED';

  @override
  String get avgInvoice => 'AVG. INVOICE';

  @override
  String get preparingCsvFiles => 'Preparing CSV files...';

  @override
  String get statusBreakdown => 'Status Breakdown';

  @override
  String get topClients => 'Top Clients';

  @override
  String get topItems => 'Top Items';

  @override
  String get billedVsCollected => 'Billed vs Collected';

  @override
  String get billedLabel => 'Billed';

  @override
  String get collectedLabel => 'Collected';

  @override
  String billedAmount(String value) {
    return 'Billed $value';
  }

  @override
  String collectedAmount(String value) {
    return 'Collected $value';
  }

  @override
  String get tapAMonthForDetails => 'Tap a month for details';

  @override
  String get noActivityInTheseMonths => 'No activity in these months';

  @override
  String get updateFlowStartedFollowTheSystemPromptTo =>
      'Update flow started. Follow the system prompt to finish.';

  @override
  String get updateCancelledYouCanInstallItLaterWhen =>
      'Update cancelled. You can install it later when prompted again.';

  @override
  String get thisUpdateIsNotReadyToInstallYet =>
      'This update is not ready to install yet.';

  @override
  String get inAppUpdatesAreOnlySupportedOnAndroid =>
      'In-app updates are only supported on Android.';

  @override
  String get theUpdateCouldNotBeStartedPleaseTry =>
      'The update could not be started. Please try again later.';

  @override
  String get updateDownloadedRestartToFinishInstalling =>
      'Update downloaded. Restart to finish installing.';

  @override
  String get restart => 'Restart';

  @override
  String get searchInvoices => 'Search invoices';

  @override
  String get searchEstimates => 'Search estimates';

  @override
  String get searchClients => 'Search clients';

  @override
  String get searchItems => 'Search items';

  @override
  String get search => 'Search';

  @override
  String get closeSearch => 'Close search';

  @override
  String get create => 'Create';

  @override
  String get createNewDocument => 'Create New Document';

  @override
  String get billAClientForWorkOrItems => 'Bill a client for work or items';

  @override
  String get newEstimateQuote => 'New Estimate / Quote';

  @override
  String get sendAPriceBeforeYouBill => 'Send a price before you bill';

  @override
  String get client => 'Client';

  @override
  String get item => 'Item';

  @override
  String newEntity(String title) {
    return 'New $title';
  }

  @override
  String get updateAvailable => 'Update available';

  @override
  String get aNewerVersionOfInvoiceMakerProIs =>
      'A newer version of Invoice Maker Pro is ready with the latest fixes and improvements.';

  @override
  String get later => 'Later';

  @override
  String get updateNow => 'Update now';
}
