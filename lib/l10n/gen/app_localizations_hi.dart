// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String invoiceCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString इनवॉइस',
      one: '1 इनवॉइस',
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
      other: '$countString कोटेशन',
      one: '1 कोटेशन',
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
      other: '$countString ग्राहक',
      one: '1 ग्राहक',
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
      other: '$countString सेव किए गए आइटम',
      one: '1 सेव किया गया आइटम',
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
      other: '$countString आइटम जोड़े गए',
      one: '1 आइटम जोड़ा गया',
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
      other: '$countString आइटम जोड़ें',
      one: '1 आइटम जोड़ें',
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
      other: '$countString चुने गए',
      one: '1 चुना गया',
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
      other: '$countString दिन',
      one: '1 दिन',
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
      other: '$countString दिनों की देरी',
      one: '1 दिन की देरी',
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
      other: 'भुगतान $countString दिनों में करना है',
      one: 'भुगतान 1 दिन में करना है',
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
      other: '$countString इनवॉइस में',
      one: '1 इनवॉइस में',
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
      other: '$countString इनवॉइस की तारीख बीत गई',
      one: '1 इनवॉइस की तारीख बीत गई',
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

    return '$totalString में से चरण $stepString';
  }

  @override
  String photoCount(int count, int maximum) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);
    final intl.NumberFormat maximumNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String maximumString = maximumNumberFormat.format(maximum);

    return '$maximumString में से $countString फ़ोटो';
  }

  @override
  String templateCount(int count, int total) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    return '$totalString में से $countString टेम्पलेट';
  }

  @override
  String reportItemQuantity(String quantity, String invoices) {
    return 'मात्रा $quantity · $invoices';
  }

  @override
  String deleteRecordedPayments(int count, String invoiceNumber) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$invoiceNumber के लिए दर्ज $countString भुगतान हट जाएँगे।';
  }

  @override
  String numberedAttachment(int number) {
    final intl.NumberFormat numberNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String numberString = numberNumberFormat.format(number);

    return 'अटैचमेंट $numberString';
  }

  @override
  String viewNumberedAttachment(int number) {
    final intl.NumberFormat numberNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String numberString = numberNumberFormat.format(number);

    return 'अटैचमेंट $numberString देखें';
  }

  @override
  String removeNumberedAttachment(int number) {
    final intl.NumberFormat numberNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String numberString = numberNumberFormat.format(number);

    return 'अटैचमेंट $numberString हटाएँ';
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

    return '$totalString में से $doneString पूरे';
  }

  @override
  String countInCurrency(int count, String currency) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$currency में $countString';
  }

  @override
  String get noUnpaidInvoices => 'कोई बकाया इनवॉइस नहीं है';

  @override
  String get noPartPaidInvoices => 'कोई आंशिक भुगतान वाला इनवॉइस नहीं है';

  @override
  String get noOverdueInvoices => 'कोई इनवॉइस समय से बाकी नहीं है';

  @override
  String get noPaidInvoices => 'किसी इनवॉइस का भुगतान दर्ज नहीं है';

  @override
  String get language => 'भाषा';

  @override
  String get systemDefault => 'डिवाइस की भाषा';

  @override
  String get english => 'English';

  @override
  String get hindi => 'हिन्दी';

  @override
  String get confirm => 'पुष्टि करें';

  @override
  String get cancel => 'रद्द करें';

  @override
  String get delete => 'हटाएँ';

  @override
  String get downloads => 'डाउनलोड';

  @override
  String get filesOnMyIphoneInvoiceMakerPro =>
      'Files › On My iPhone › Invoice Maker Pro';

  @override
  String get monthlyInvoiceLimitReached => 'इस महीने की इनवॉइस सीमा पूरी हो गई';

  @override
  String get monthlyEstimateLimitReached =>
      'इस महीने की एस्टीमेट सीमा पूरी हो गई';

  @override
  String get savedClientLimitReached =>
      'सेव किए गए ग्राहकों की सीमा पूरी हो गई';

  @override
  String get notNow => 'अभी नहीं';

  @override
  String get seePro => 'Pro देखें';

  @override
  String monthlyInvoiceLimitDetails(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'मुफ़्त प्लान में हर महीने $countString नए इनवॉइस बना सकते हैं। आप अपने सभी मौजूदा इनवॉइस खोल सकते हैं, बदल सकते हैं, शेयर कर सकते हैं और उनका भुगतान ले सकते हैं। असीमित इनवॉइस के लिए Pro लें।';
  }

  @override
  String monthlyEstimateLimitDetails(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'मुफ़्त प्लान में हर महीने $countString नए एस्टीमेट बना सकते हैं। असीमित एस्टीमेट के लिए Pro लें।';
  }

  @override
  String savedClientLimitDetails(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'मुफ़्त प्लान में $countString तक ग्राहक सेव कर सकते हैं। किसी भी ग्राहक की जानकारी सीधे इनवॉइस में डाल सकते हैं। असीमित ग्राहक सेव करने के लिए Pro लें।';
  }

  @override
  String get reportFinancial => 'वित्तीय रिपोर्ट';

  @override
  String get reportTopClientsHeading => 'प्रमुख ग्राहक:';

  @override
  String get reportTopItemsHeading => 'सबसे ज़्यादा बिकने वाले आइटम:';

  @override
  String get playStoreUnavailable =>
      'Play Store अभी उपलब्ध नहीं है। बाद में फिर कोशिश करें।';

  @override
  String get planUnavailable =>
      'यह प्लान अभी उपलब्ध नहीं है। बाद में फिर कोशिश करें।';

  @override
  String get purchaseStartFailed => 'खरीदारी शुरू नहीं हो सकी। फिर कोशिश करें।';

  @override
  String get restorePurchasesFailed =>
      'खरीदारी बहाल करने के लिए Play Store से संपर्क नहीं हो सका।';

  @override
  String get purchaseFailed =>
      'खरीदारी पूरी नहीं हुई। कोई पैसा नहीं कटा है। इंटरनेट कनेक्शन और Google Play में भुगतान का तरीका जाँचकर फिर कोशिश करें।';

  @override
  String get backupFromNewerVersion =>
      'यह बैकअप ऐप के नए वर्शन से बना है। ऐप अपडेट करके फिर कोशिश करें।';

  @override
  String get backupTooOld => 'यह बैकअप वापस लाने के लिए बहुत पुराना है।';

  @override
  String get backupDamaged =>
      'बैकअप फ़ाइल खराब है, इसलिए इसे वापस नहीं लाया जा सकता।';

  @override
  String reportFinancialFor(String business) {
    return '$business — वित्तीय रिपोर्ट';
  }

  @override
  String reportPeriod(String period) {
    return 'समय अवधि: $period';
  }

  @override
  String reportBilledAmount(String amount, String invoices) {
    return 'बिल की रकम: $amount ($invoices)';
  }

  @override
  String reportCollectedAmount(String amount) {
    return 'मिली रकम: $amount';
  }

  @override
  String reportOutstandingAmount(String amount) {
    return 'बाकी रकम: $amount';
  }

  @override
  String reportOverdueAmount(String amount, int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'समय से बाकी रकम: $amount ($countString)';
  }

  @override
  String reportTaxAmount(String amount) {
    return 'टैक्स: $amount';
  }

  @override
  String reportAverageInvoice(String amount) {
    return 'इनवॉइस की औसत रकम: $amount';
  }

  @override
  String backupEstimateCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString एस्टीमेट',
      one: '1 एस्टीमेट',
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
      other: '$countString भुगतान',
      one: '1 भुगतान',
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
      other: '$countString अटैच की गई फ़ोटो',
      one: '1 अटैच की गई फ़ोटो',
    );
    return '$_temp0';
  }

  @override
  String get catalogProfessional => 'प्रोफ़ेशनल';

  @override
  String get catalogSimple => 'सादा';

  @override
  String get catalogBold => 'बोल्ड';

  @override
  String get catalogCreative => 'क्रिएटिव';

  @override
  String get catalogRetailGst => 'रिटेल और GST';

  @override
  String get catalogClassicCorporate => 'क्लासिक कॉर्पोरेट';

  @override
  String get catalogModernMinimal => 'मॉडर्न मिनिमल';

  @override
  String get catalogEmeraldExecutive => 'एमराल्ड एक्ज़ीक्यूटिव';

  @override
  String get catalogSlateElegance => 'स्लेट एलिगेंस';

  @override
  String get catalogWarmCorporate => 'वॉर्म कॉर्पोरेट';

  @override
  String get catalogNordicFrame => 'नॉर्डिक फ़्रेम';

  @override
  String get catalogLeftAccentRibbon => 'बाईं रंगीन पट्टी';

  @override
  String get catalogGeometricBanner => 'ज्योमेट्रिक बैनर';

  @override
  String get catalogSecurityGrid => 'सुरक्षा ग्रिड';

  @override
  String get catalogTwoToneSplit => 'दो रंगों वाला';

  @override
  String get catalogCharcoalLetterhead => 'चारकोल लेटरहेड';

  @override
  String get catalogNavyLetterhead => 'नेवी लेटरहेड';

  @override
  String get catalogForestSeal => 'फ़ॉरेस्ट सील';

  @override
  String get catalogLinenRule => 'लिनन लाइन';

  @override
  String get catalogMistLine => 'मिस्ट लाइन';

  @override
  String get catalogOliveFrame => 'ऑलिव फ़्रेम';

  @override
  String get catalogCrimsonSlash => 'लाल तिरछी पट्टी';

  @override
  String get catalogIndigoSlash => 'इंडिगो तिरछी पट्टी';

  @override
  String get catalogCopperBanner => 'तांबे के रंग का बैनर';

  @override
  String get catalogTealWave => 'टील वेव';

  @override
  String get catalogOrchidWave => 'ऑर्किड वेव';

  @override
  String get catalogClayRibbon => 'मिट्टी के रंग की पट्टी';

  @override
  String get catalogMulberrySplit => 'मलबरी स्प्लिट';

  @override
  String get catalogSaffronLedger => 'केसरिया लेजर';

  @override
  String get catalogPeacockLedger => 'मोर रंग का लेजर';

  @override
  String get catalogGraphiteReceipt => 'ग्रेफ़ाइट रसीद';

  @override
  String get catalogRoseReceipt => 'गुलाबी रसीद';

  @override
  String get catalogOxbloodSeal => 'गहरे लाल रंग की मुहर';

  @override
  String get catalogCleanSans => 'क्लीन सैन्स';

  @override
  String get catalogEditorialSerif => 'एडिटोरियल सेरिफ़';

  @override
  String get catalogGeometric => 'ज्योमेट्रिक';

  @override
  String get catalogTechMono => 'टेक मोनो';

  @override
  String get catalogModernClearHighlyLegibleInterNoto =>
      'आधुनिक, साफ़ और पढ़ने में आसान (Inter / Noto)';

  @override
  String get catalogFormalPremiumClassicLoraMerriweather =>
      'औपचारिक और क्लासिक (Lora / Merriweather)';

  @override
  String get catalogSharpSleekContemporaryMontserratPoppins =>
      'साफ़ और आधुनिक (Montserrat / Poppins)';

  @override
  String get catalogTechnicalPreciseBalancedSpaceMono =>
      'तकनीकी और संतुलित (Space Mono)';

  @override
  String get catalogCompact => 'कम जगह';

  @override
  String get catalogRegular => 'सामान्य';

  @override
  String get catalogSpacious => 'खुला लेआउट';

  @override
  String get catalogLeftLogo => 'बाईं ओर लोगो';

  @override
  String get catalogRightLogo => 'दाईं ओर लोगो';

  @override
  String get catalogCentered => 'बीच में';

  @override
  String get catalogBanner => 'बैनर';

  @override
  String get catalogBusinessLogoOnLeftInvoiceDetailsOnRight =>
      'बिज़नेस और लोगो बाईं ओर, इनवॉइस की जानकारी दाईं ओर';

  @override
  String get catalogInvoiceTitleMetaOnLeftLogoOnRight =>
      'इनवॉइस की जानकारी बाईं ओर, लोगो दाईं ओर';

  @override
  String get catalogCenteredBrandingWithBalancedMetadataPills =>
      'ब्रांड बीच में और जानकारी बराबर जगह में';

  @override
  String get catalogFullWidthSolidColorAccentHeader =>
      'पूरी चौड़ाई में एक रंग की पट्टी';

  @override
  String get catalogSideBySide => 'बगल-बगल';

  @override
  String get catalogInverted => 'उलटी जगह';

  @override
  String get catalogStacked => 'ऊपर-नीचे';

  @override
  String get catalogFromBusinessOnLeftBillToClientOnRight =>
      'बाईं ओर आपका बिज़नेस · दाईं ओर ग्राहक';

  @override
  String get catalogBillToClientOnLeftFromBusinessOnRight =>
      'बाईं ओर ग्राहक · दाईं ओर आपका बिज़नेस';

  @override
  String get catalogFullWidthFromCardAboveBillToCard =>
      'ग्राहक के ऊपर पूरी चौड़ाई में आपके बिज़नेस की जानकारी';

  @override
  String get catalogRoyalBlue => 'रॉयल ब्लू';

  @override
  String get catalogEmeraldForest => 'एमराल्ड हरा';

  @override
  String get catalogSlateGraphite => 'स्लेट ग्रेफ़ाइट';

  @override
  String get catalogObsidianBlack => 'गहरा काला';

  @override
  String get catalogWarmAmber => 'अंबर';

  @override
  String get catalogNordicTeal => 'नॉर्डिक टील';

  @override
  String get catalogIndigoViolet => 'इंडिगो वायलेट';

  @override
  String get catalogCrimsonExecutive => 'गहरा लाल';

  @override
  String get catalogSent => 'भेजा गया';

  @override
  String get catalogAccepted => 'स्वीकार हुआ';

  @override
  String get catalogDeclined => 'अस्वीकार हुआ';

  @override
  String get catalogInvoiced => 'इनवॉइस बना';

  @override
  String get catalogNet15 => '15 दिनों में भुगतान';

  @override
  String get catalogNet30 => '30 दिनों में भुगतान';

  @override
  String get catalogNet60 => '60 दिनों में भुगतान';

  @override
  String get catalogUsDollar => 'अमेरिकी डॉलर';

  @override
  String get catalogIndianRupee => 'भारतीय रुपया';

  @override
  String get catalogBritishPound => 'ब्रिटिश पाउंड';

  @override
  String get catalogEuro => 'यूरो';

  @override
  String get catalogCanadianDollar => 'कनाडाई डॉलर';

  @override
  String get catalogAustralianDollar => 'ऑस्ट्रेलियाई डॉलर';

  @override
  String get catalogUaeDirham => 'UAE दिरहम';

  @override
  String get catalogSaudiRiyal => 'सऊदी रियाल';

  @override
  String get catalogSingaporeDollar => 'सिंगापुर डॉलर';

  @override
  String get catalogJapaneseYen => 'जापानी येन';

  @override
  String get catalogNewZealandDollar => 'न्यूज़ीलैंड डॉलर';

  @override
  String get catalogSwissFranc => 'स्विस फ़्रैंक';

  @override
  String get catalogMalaysianRinggit => 'मलेशियाई रिंगिट';

  @override
  String get catalogSouthAfricanRand => 'दक्षिण अफ़्रीकी रैंड';

  @override
  String get catalogMexicanPeso => 'मेक्सिकन पेसो';

  @override
  String get catalogBrazilianReal => 'ब्राज़ीलियाई रियाल';

  @override
  String get catalogHongKongDollar => 'हांगकांग डॉलर';

  @override
  String get catalogThaiBaht => 'थाई बाह्ट';

  @override
  String get catalogPhilippinePeso => 'फ़िलीपीनी पेसो';

  @override
  String get catalogIndonesianRupiah => 'इंडोनेशियाई रुपिया';

  @override
  String get catalogVietnameseDong => 'वियतनामी डोंग';

  @override
  String get catalogSouthKoreanWon => 'दक्षिण कोरियाई वॉन';

  @override
  String get catalogChineseYuan => 'चीनी युआन';

  @override
  String get catalogNigerianNaira => 'नाइजीरियाई नायरा';

  @override
  String get catalogKenyanShilling => 'केन्याई शिलिंग';

  @override
  String get catalogPakistaniRupee => 'पाकिस्तानी रुपया';

  @override
  String get catalogBangladeshiTaka => 'बांग्लादेशी टका';

  @override
  String get catalogPolishZloty => 'पोलिश ज़्लॉटी';

  @override
  String get catalogSwedishKrona => 'स्वीडिश क्रोना';

  @override
  String get catalogNorwegianKrone => 'नॉर्वेजियन क्रोन';

  @override
  String get catalogDanishKrone => 'डेनिश क्रोन';

  @override
  String get catalogQatariRiyal => 'क़तरी रियाल';

  @override
  String get catalogKuwaitiDinar => 'कुवैती दीनार';

  @override
  String get catalogBahrainiDinar => 'बहरीनी दीनार';

  @override
  String get catalogTaiwanDollar => 'ताइवान डॉलर';

  @override
  String get catalogUnitedStates => 'अमेरिका';

  @override
  String get catalogIndia => 'भारत';

  @override
  String get catalogUnitedKingdom => 'यूनाइटेड किंगडम';

  @override
  String get catalogEuropeanUnion => 'यूरोपीय संघ';

  @override
  String get catalogCanada => 'कनाडा';

  @override
  String get catalogAustralia => 'ऑस्ट्रेलिया';

  @override
  String get catalogUnitedArabEmirates => 'संयुक्त अरब अमीरात';

  @override
  String get catalogSaudiArabia => 'सऊदी अरब';

  @override
  String get catalogSingapore => 'सिंगापुर';

  @override
  String get catalogJapan => 'जापान';

  @override
  String get catalogNewZealand => 'न्यूज़ीलैंड';

  @override
  String get catalogSwitzerland => 'स्विट्ज़रलैंड';

  @override
  String get catalogMalaysia => 'मलेशिया';

  @override
  String get catalogSouthAfrica => 'दक्षिण अफ़्रीका';

  @override
  String get catalogMexico => 'मेक्सिको';

  @override
  String get catalogBrazil => 'ब्राज़ील';

  @override
  String get catalogHongKong => 'हांगकांग';

  @override
  String get catalogThailand => 'थाईलैंड';

  @override
  String get catalogPhilippines => 'फ़िलीपींस';

  @override
  String get catalogIndonesia => 'इंडोनेशिया';

  @override
  String get catalogVietnam => 'वियतनाम';

  @override
  String get catalogSouthKorea => 'दक्षिण कोरिया';

  @override
  String get catalogChina => 'चीन';

  @override
  String get catalogNigeria => 'नाइजीरिया';

  @override
  String get catalogKenya => 'केन्या';

  @override
  String get catalogPakistan => 'पाकिस्तान';

  @override
  String get catalogBangladesh => 'बांग्लादेश';

  @override
  String get catalogPoland => 'पोलैंड';

  @override
  String get catalogSweden => 'स्वीडन';

  @override
  String get catalogNorway => 'नॉर्वे';

  @override
  String get catalogDenmark => 'डेनमार्क';

  @override
  String get catalogQatar => 'क़तर';

  @override
  String get catalogKuwait => 'कुवैत';

  @override
  String get catalogBahrain => 'बहरीन';

  @override
  String get catalogTaiwan => 'ताइवान';

  @override
  String get catalogSalesTax => 'बिक्री टैक्स';

  @override
  String get catalogGoodsAndServicesTax => 'वस्तु और सेवा कर (GST)';

  @override
  String get catalogValueAddedTax => 'मूल्य वर्धित कर (VAT)';

  @override
  String get catalogConsumptionTax => 'उपभोग कर';

  @override
  String get catalogSalesAndServicesTax => 'बिक्री और सेवा कर (SST)';

  @override
  String get catalogImpuestoAlValorAgregado => 'मूल्य वर्धित कर (IVA)';

  @override
  String get catalogImpostosIcmsIss => 'टैक्स (ICMS / ISS)';

  @override
  String get catalogNoGeneralSalesTax => 'सामान्य बिक्री टैक्स नहीं';

  @override
  String get catalogPajakPertambahanNilai => 'मूल्य वर्धित कर (PPN)';

  @override
  String get catalogValueAddedTaxMushak => 'मूल्य वर्धित कर (Mushak)';

  @override
  String get catalogPodatekOdTowarWIUsUg => 'वस्तु और सेवा कर (PTU)';

  @override
  String get catalogMervRdesskattMoms => 'मूल्य वर्धित कर (Moms)';

  @override
  String get catalogMerverdiavgiftMva => 'मूल्य वर्धित कर (MVA)';

  @override
  String get catalogMervRdiafgiftMoms => 'मूल्य वर्धित कर (Moms)';

  @override
  String get catalogTaxFree => 'टैक्स से छूट';

  @override
  String get catalogTaxIdEin => 'टैक्स आईडी / EIN';

  @override
  String get catalogVatRegNo => 'VAT रजिस्ट्रेशन नंबर';

  @override
  String get catalogBusinessNumberBn => 'बिज़नेस नंबर (BN)';

  @override
  String get catalogAbnBusinessNo => 'ABN (बिज़नेस नंबर)';

  @override
  String get catalogTrnTaxRegNo => 'TRN (टैक्स रजिस्ट्रेशन नंबर)';

  @override
  String get catalogVatRegNoTrn => 'VAT रजिस्ट्रेशन नंबर / TRN';

  @override
  String get catalogUenGstRegNo => 'UEN / GST रजिस्ट्रेशन नंबर';

  @override
  String get catalogInvoiceRegNo => 'इनवॉइस रजिस्ट्रेशन नंबर';

  @override
  String get catalogGstIrdNumber => 'GST / IRD नंबर';

  @override
  String get catalogSstRegNo => 'SST रजिस्ट्रेशन नंबर';

  @override
  String get catalogVatNumber => 'VAT नंबर';

  @override
  String get catalogRfcTaxId => 'RFC (टैक्स आईडी)';

  @override
  String get catalogCnpjCompanyId => 'CNPJ (कंपनी आईडी)';

  @override
  String get catalogBusinessRegNoBrn => 'बिज़नेस रजिस्ट्रेशन नंबर (BRN)';

  @override
  String get catalogTaxId13Digits => 'टैक्स आईडी (13 अंक)';

  @override
  String get catalogTinTaxIdNo => 'TIN (टैक्स आईडी)';

  @override
  String get catalogNpwpTaxId => 'NPWP (टैक्स आईडी)';

  @override
  String get catalogMSThuTaxCode => 'टैक्स कोड (Mã số thuế)';

  @override
  String get catalogUnifiedSocialCreditCode => 'यूनिफ़ाइड सोशल क्रेडिट कोड';

  @override
  String get catalogBinVatRegNo => 'BIN / VAT रजिस्ट्रेशन नंबर';

  @override
  String get catalogNipTaxId => 'NIP (टैक्स आईडी)';

  @override
  String get catalogTaxCardTin => 'टैक्स कार्ड / TIN';

  @override
  String get catalogCivilCommercialRegNo => 'सिविल / कमर्शियल रजिस्ट्रेशन नंबर';

  @override
  String get catalogVatAccountNo => 'VAT खाता नंबर';

  @override
  String get catalogUnifiedBusinessNoUbn => 'यूनिफ़ाइड बिज़नेस नंबर (UBN)';

  @override
  String get catalogAccountNumber => 'खाता नंबर';

  @override
  String get catalogNMeroDeCuenta => 'खाता नंबर';

  @override
  String get catalogContaCorrente => 'खाता नंबर';

  @override
  String get catalogNomorRekening => 'खाता नंबर';

  @override
  String get catalogSTIKhoN => 'खाता नंबर';

  @override
  String get catalogAccountNumberNuban => 'खाता नंबर (NUBAN)';

  @override
  String get catalogAccountNumberIban => 'खाता नंबर (IBAN)';

  @override
  String get catalogNumerKontaIban => 'खाता नंबर (IBAN)';

  @override
  String get catalogKontonummer => 'खाता नंबर';

  @override
  String get catalogRoutingIfscCode => 'रूटिंग / IFSC कोड';

  @override
  String get catalogRoutingNumberAba => 'रूटिंग नंबर (ABA)';

  @override
  String get catalogIfscCode => 'IFSC कोड';

  @override
  String get catalogSortCode => 'सॉर्ट कोड';

  @override
  String get catalogBicSwiftCode => 'BIC / SWIFT कोड';

  @override
  String get catalogTransitInstitutionNo => 'ट्रांज़िट और संस्था नंबर';

  @override
  String get catalogBsbCode => 'BSB कोड';

  @override
  String get catalogBankBranchCode => 'बैंक और शाखा कोड';

  @override
  String get catalogBranchCodeName => 'शाखा कोड और नाम';

  @override
  String get catalogBankCodeSwift => 'बैंक कोड / SWIFT';

  @override
  String get catalogBranchCode => 'शाखा कोड';

  @override
  String get catalogClabe18Digits => 'CLABE (18 अंक)';

  @override
  String get catalogAgNciaCDigoDoBanco => 'बैंक और शाखा कोड';

  @override
  String get catalogBankCodeBranch => 'बैंक कोड और शाखा';

  @override
  String get catalogBankCodeBrstn => 'बैंक कोड / BRSTN';

  @override
  String get catalogKodeBank => 'बैंक कोड';

  @override
  String get catalogChiNhNhMNgNHNg => 'शाखा / बैंक कोड';

  @override
  String get catalogBankCode => 'बैंक कोड';

  @override
  String get catalogBankCodeCnaps => 'बैंक कोड (CNAPS)';

  @override
  String get catalogSortCodeBankCode => 'सॉर्ट कोड / बैंक कोड';

  @override
  String get catalogBankCodeBranch2 => 'बैंक कोड / शाखा';

  @override
  String get catalogBankBranchCode2 => 'बैंक शाखा कोड';

  @override
  String get catalogRoutingNumber9Digits => 'रूटिंग नंबर (9 अंक)';

  @override
  String get catalogRegNr4Digits => 'रजिस्ट्रेशन नंबर (4 अंक)';

  @override
  String get catalogBankCode3Digits => 'बैंक कोड (3 अंक)';

  @override
  String get catalogUpiPaymentHandle => 'UPI / भुगतान आईडी';

  @override
  String get catalogUpiIdVpa => 'UPI आईडी / VPA';

  @override
  String get catalogOnlinePaymentLinkHandle => 'ऑनलाइन भुगतान लिंक / आईडी';

  @override
  String get catalogPaynowUenMobile => 'PayNow (UEN / मोबाइल)';

  @override
  String get catalogDuitnowIdBusinessReg =>
      'DuitNow (आईडी / बिज़नेस रजिस्ट्रेशन)';

  @override
  String get catalogChavePixCnpjEmailTelefone => 'Pix की (CNPJ / ईमेल / फ़ोन)';

  @override
  String get catalogFpsIdFasterPaymentSystem =>
      'FPS आईडी (फ़ास्टर पेमेंट सिस्टम)';

  @override
  String get catalogPromptpayTaxIdMobile => 'PromptPay (टैक्स आईडी / मोबाइल)';

  @override
  String get catalogPaymentHandlePaystack => 'भुगतान आईडी / Paystack';

  @override
  String get catalogMPesaPaybillTillNumber => 'M-Pesa Paybill / Till नंबर';

  @override
  String get catalogBkashNagadMerchantNumber => 'bKash / Nagad मर्चेंट नंबर';

  @override
  String get catalogSwishNummerFRetag => 'Swish नंबर (बिज़नेस)';

  @override
  String get catalogVippsNummerBedrift => 'Vipps नंबर (बिज़नेस)';

  @override
  String get catalogMobilepayNummer => 'MobilePay नंबर';

  @override
  String get catalogWafeyKnetLink => 'Wafey / KNET लिंक';

  @override
  String get catalogBenefitpayIbanMobile => 'BenefitPay (IBAN / मोबाइल)';

  @override
  String get myBusinessPlaceholder => 'मेरा बिज़नेस';

  @override
  String get catalogBankTransferNeft => 'बैंक ट्रांसफ़र / NEFT';

  @override
  String get catalogCash => 'नकद';

  @override
  String get catalogCreditDebitCard => 'क्रेडिट / डेबिट कार्ड';

  @override
  String get catalogCheque => 'चेक';

  @override
  String get catalogBankTransfer => 'बैंक ट्रांसफ़र';

  @override
  String get catalogCard => 'कार्ड';

  @override
  String get catalogEG123456789 => 'जैसे 12-3456789';

  @override
  String get catalogEGChaseBankBarclaysHdfc =>
      'जैसे Chase Bank / Barclays / HDFC';

  @override
  String get catalogEG1234567890 => 'जैसे 1234567890';

  @override
  String get catalogEG021000021Sbin0001234 => 'जैसे 021000021 / SBIN0001234';

  @override
  String get catalogEGBusinessUpiOrPaypalMeHandle =>
      'जैसे business@upi या paypal.me/handle';

  @override
  String get catalogEGJpmorganChaseWellsFargoBankOfAmerica =>
      'जैसे JPMorgan Chase / Wells Fargo / Bank of America';

  @override
  String get catalogEG0210000219DigitAba => 'जैसे 021000021 (9-अंक ABA)';

  @override
  String get catalogZelleVenmoPaypalHandle => 'Zelle / Venmo / PayPal आईडी';

  @override
  String get catalogEGPaymentsCompanyComOrUsername =>
      'जैसे payments@company.com या @username';

  @override
  String get catalogEGStateBankOfIndiaHdfcBankIcici =>
      'जैसे State Bank of India / HDFC Bank / ICICI';

  @override
  String get catalogEG50100234567890 => 'जैसे 50100234567890';

  @override
  String get catalogEGHdfc0000123Sbin0001234 =>
      'जैसे HDFC0000123 / SBIN0001234';

  @override
  String get catalogEGCompanyOkhdfcbankOr9876543210Upi =>
      'जैसे company@okhdfcbank या 9876543210@upi';

  @override
  String get catalogEGBarclaysHsbcUkLloydsBank =>
      'जैसे Barclays / HSBC UK / Lloyds Bank';

  @override
  String get catalogEG123456788Digits => 'जैसे 12345678 (8 अंक)';

  @override
  String get catalogEG2000006Digits => 'जैसे 20-00-00 (6 अंक)';

  @override
  String get catalogPaymFasterPaymentsId => 'Paym / Faster Payments आईडी';

  @override
  String get catalogEGPaymentsCompanyCoUk => 'जैसे payments@company.co.uk';

  @override
  String get catalogVatIdUstIdnr => 'VAT आईडी / USt-IdNr.';

  @override
  String get catalogEGDeutscheBankBnpParibasSantander =>
      'जैसे Deutsche Bank / BNP Paribas / Santander';

  @override
  String get catalogEGDe89370400440532013000 =>
      'जैसे DE89 3704 0044 0532 0130 00';

  @override
  String get catalogEGDbkdeffxxx811Characters => 'जैसे DBKDEFFXXX (8-11 अक्षर)';

  @override
  String get catalogSepaPaypalBizumHandle => 'SEPA / PayPal / Bizum आईडी';

  @override
  String get catalogEGPaypalMeCompanyOrSepaId =>
      'जैसे paypal.me/company या SEPA ID';

  @override
  String get catalogEGRbcRoyalBankTdCanadaTrustBmo =>
      'जैसे RBC Royal Bank / TD Canada Trust / BMO';

  @override
  String get catalogEG1234567 => 'जैसे 1234567';

  @override
  String get catalogEG12345001TransitInst => 'जैसे 12345-001 (Transit-Inst)';

  @override
  String get catalogInteracETransferHandle => 'Interac e-Transfer आईडी';

  @override
  String get catalogEGPaymentsCompanyCa => 'जैसे payments@company.ca';

  @override
  String get catalogEGCommonwealthBankAnzWestpacNab =>
      'जैसे Commonwealth Bank / ANZ / Westpac / NAB';

  @override
  String get catalogEG12345678 => 'जैसे 1234 5678';

  @override
  String get catalogEG0620006Digits => 'जैसे 062-000 (6 अंक)';

  @override
  String get catalogPayidOskoHandle => 'PayID / Osko आईडी';

  @override
  String get catalogEGPaymentsCompanyComAuOr0400123456 =>
      'जैसे payments@company.com.au या 0400123456';

  @override
  String get catalogEGEmiratesNbdFirstAbuDhabiBankFab =>
      'जैसे Emirates NBD / First Abu Dhabi Bank (FAB)';

  @override
  String get catalogEGAe07033123456789012345 =>
      'जैसे AE07 0331 2345 6789 0123 45';

  @override
  String get catalogEGEbilaeadxxx => 'जैसे EBILAEADXXX';

  @override
  String get catalogAaniInstantPayHandle => 'Aani / Instant Pay आईडी';

  @override
  String get catalogEG0501234567OrCompany => 'जैसे 0501234567 या @company';

  @override
  String get catalogEGAlRajhiBankSaudiNationalBankSnb =>
      'जैसे Al Rajhi Bank / Saudi National Bank (SNB)';

  @override
  String get catalogEGSa0380000000608010167519 =>
      'जैसे SA03 8000 0000 6080 1016 7519';

  @override
  String get catalogEGRjhisa22Xxx => 'जैसे RJHISA22XXX';

  @override
  String get catalogSarieStcPayHandle => 'Sarie / STC Pay आईडी';

  @override
  String get catalogEG0501234567OrPaymentsCompanySa =>
      'जैसे 0501234567 या payments@company.sa';

  @override
  String get catalogEGDbsBankOcbcUob => 'जैसे DBS Bank / OCBC / UOB';

  @override
  String get catalogEG1234567892 => 'जैसे 123-45678-9';

  @override
  String get catalogEG7171001Dbs => 'जैसे 7171-001 (DBS)';

  @override
  String get catalogEG201234567AOr6591234567 =>
      'जैसे 201234567A या +6591234567';

  @override
  String get catalogEGMitsubishiUfjMufgSmbcMizuho =>
      'जैसे Mitsubishi UFJ (MUFG) / SMBC / Mizuho';

  @override
  String get catalogEG1234567Futsu => 'जैसे 1234567 (Futsu)';

  @override
  String get catalogEG001ShinjukuBranch => 'जैसे 001 (Shinjuku शाखा)';

  @override
  String get catalogPaypayLinePayHandle => 'PayPay / Line Pay आईडी';

  @override
  String get catalogEGPaymentsCompanyJp => 'जैसे payments@company.jp';

  @override
  String get catalogEGAnzNewZealandAsbBankBnz =>
      'जैसे ANZ New Zealand / ASB Bank / BNZ';

  @override
  String get catalogEG010123012345600 => 'जैसे 01-0123-0123456-00';

  @override
  String get catalogEG0101236Digits => 'जैसे 01-0123 (6 अंक)';

  @override
  String get catalogEGPaymentsCompanyCoNz => 'जैसे payments@company.co.nz';

  @override
  String get catalogEGUbsCreditSuisseZkb => 'जैसे UBS / Credit Suisse / ZKB';

  @override
  String get catalogEGCh9300762011623852957 =>
      'जैसे CH93 0076 2011 6238 5295 7';

  @override
  String get catalogEGUbswchzhxxx => 'जैसे UBSWCHZHXXX';

  @override
  String get catalogTwintQrBillHandle => 'TWINT / QR-Bill आईडी';

  @override
  String get catalogEG41791234567OrCompany =>
      'जैसे +41 79 123 45 67 या @company';

  @override
  String get catalogEGMaybankCimbBankPublicBank =>
      'जैसे Maybank / CIMB Bank / Public Bank';

  @override
  String get catalogEG514012345678 => 'जैसे 5140 1234 5678';

  @override
  String get catalogEGMbbemykl => 'जैसे MBBEMYKL';

  @override
  String get catalogEG201234567AOr0123456789 => 'जैसे 201234567A या 0123456789';

  @override
  String get catalogEGStandardBankFnbAbsaNedbank =>
      'जैसे Standard Bank / FNB / Absa / Nedbank';

  @override
  String get catalogEG1234567893 => 'जैसे 123456789';

  @override
  String get catalogEG051001FnbUniversal => 'जैसे 051001 (FNB Universal)';

  @override
  String get catalogEG0821234567OrShapid => 'जैसे 0821234567 या @shapid';

  @override
  String get catalogEGBbvaMXicoBanorteSantanderMXico =>
      'जैसे BBVA México / Banorte / Santander México';

  @override
  String get catalogEG012180001234567890 => 'जैसे 012 180 00123456789 0';

  @override
  String get catalogCodiDimoSpeiHandle => 'CoDi / Dimo / SPEI आईडी';

  @override
  String get catalogEG5512345678OrRfcEmpresaCom =>
      'जैसे 5512345678 या rfc@empresa.com';

  @override
  String get catalogEGItaUnibancoBradescoBancoDoBrasil =>
      'जैसे Itaú Unibanco / Bradesco / Banco do Brasil';

  @override
  String get catalogEG123456 => 'जैसे 12345-6';

  @override
  String get catalogEG0341ItaAg1234 => 'जैसे 0341 (Itaú) / Ag. 1234';

  @override
  String get catalogEG00000000000100OuPixEmpresaComBr =>
      'जैसे 00.000.000/0001-00 ou pix@empresa.com.br';

  @override
  String get catalogEGHsbcStandardCharteredHangSengBank =>
      'जैसे HSBC / Standard Chartered / Hang Seng Bank';

  @override
  String get catalogEG123456789001 => 'जैसे 123-456789-001';

  @override
  String get catalogEG004123Hsbc => 'जैसे 004-123 (HSBC)';

  @override
  String get catalogEG1234567OrPaymentsCompanyHk =>
      'जैसे 1234567 या payments@company.hk';

  @override
  String get catalogEGBangkokBankKasikornbankKbankScb =>
      'जैसे Bangkok Bank / Kasikornbank (KBank) / SCB';

  @override
  String get catalogEG12345678902 => 'जैसे 123-4-56789-0';

  @override
  String get catalogEG0001 => 'जैसे 0001';

  @override
  String get catalogEG0105551234567Or0812345678 =>
      'जैसे 0105551234567 या 0812345678';

  @override
  String get catalogEGBdoUnibankBpiMetrobank =>
      'जैसे BDO Unibank / BPI / Metrobank';

  @override
  String get catalogEG123456789012 => 'जैसे 1234 5678 9012';

  @override
  String get catalogEG010530667 => 'जैसे 010530667';

  @override
  String get catalogEG09171234567OrCompany => 'जैसे 09171234567 या @company';

  @override
  String get catalogEGBankCentralAsiaBcaMandiriBri =>
      'जैसे Bank Central Asia (BCA) / Mandiri / BRI';

  @override
  String get catalogEG014Bca => 'जैसे 014 (BCA)';

  @override
  String get catalogQrisGopayOvoHandle => 'QRIS / GoPay / OVO आईडी';

  @override
  String get catalogEG081234567890OrPaymentsCompanyId =>
      'जैसे 081234567890 या payments@company.id';

  @override
  String get catalogEGVietcombankTechcombankBidv =>
      'जैसे Vietcombank / Techcombank / BIDV';

  @override
  String get catalogEG0011001234567 => 'जैसे 0011001234567';

  @override
  String get catalogEGChiNhNhBaNh => 'जैसे Chi nhánh Ba Đình';

  @override
  String get catalogVietqrMomoZalopayHandle => 'VietQR / MoMo / ZaloPay आईडी';

  @override
  String get catalogEG0912345678OrCompany => 'जैसे 0912345678 या @company';

  @override
  String get catalogEGKbKookminBankShinhanHanaBank =>
      'जैसे KB Kookmin Bank / Shinhan / Hana Bank';

  @override
  String get catalogEG1234567890122 => 'जैसे 123-456-789012';

  @override
  String get catalogEG004Kb => 'जैसे 004 (KB)';

  @override
  String get catalogKakaopayTossHandle => 'KakaoPay / Toss आईडी';

  @override
  String get catalogEG01012345678 => 'जैसे 010-1234-5678';

  @override
  String get catalogEGIcbcChinaConstructionBankBankOfChina =>
      'जैसे ICBC / China Construction Bank / Bank of China';

  @override
  String get catalogEG6222021234567890 => 'जैसे 6222 0212 3456 7890';

  @override
  String get catalogEG102100000010 => 'जैसे 102100000010';

  @override
  String get catalogAlipayWechatPayHandle => 'Alipay / WeChat Pay आईडी';

  @override
  String get catalogEGPaymentsCompanyCnOr13800138000 =>
      'जैसे payments@company.cn या 13800138000';

  @override
  String get catalogEGAccessBankZenithBankGtbank =>
      'जैसे Access Bank / Zenith Bank / GTBank';

  @override
  String get catalogEG012345678910Digits => 'जैसे 0123456789 (10 अंक)';

  @override
  String get catalogEG058152010 => 'जैसे 058152010';

  @override
  String get catalogEGPaystackComPayMycompany =>
      'जैसे paystack.com/pay/mycompany';

  @override
  String get catalogEGKcbBankEquityBankNcba =>
      'जैसे KCB Bank / Equity Bank / NCBA';

  @override
  String get catalogEG01100 => 'जैसे 01100';

  @override
  String get catalogEGPaybill247247Acc123456 =>
      'जैसे Paybill: 247247, Acc: 123456';

  @override
  String get catalogEGHabibBankHblMcbMeezanBank =>
      'जैसे Habib Bank (HBL) / MCB / Meezan Bank';

  @override
  String get catalogEGPk36Mezn0001234567890123 =>
      'जैसे PK36MEZN0001234567890123';

  @override
  String get catalogEG0123 => 'जैसे 0123';

  @override
  String get catalogRaastIdJazzcashEasypaisa =>
      'Raast आईडी / JazzCash / Easypaisa';

  @override
  String get catalogEG03001234567 => 'जैसे 03001234567';

  @override
  String get catalogEGSonaliBankBracBankDutchBangla =>
      'जैसे Sonali Bank / BRAC Bank / Dutch-Bangla';

  @override
  String get catalogEG1011234567890 => 'जैसे 1011234567890';

  @override
  String get catalogEG060271234 => 'जैसे 060271234';

  @override
  String get catalogEG01712345678PersonalMerchant =>
      'जैसे 01712345678 (Personal / Merchant)';

  @override
  String get catalogEGPkoBankPolskiSantanderPolskaMbank =>
      'जैसे PKO Bank Polski / Santander Polska / mBank';

  @override
  String get catalogEGPl12102010260000123456789012 =>
      'जैसे PL 12 1020 1026 0000 1234 5678 9012';

  @override
  String get catalogEGPkopplpw => 'जैसे PKOPPLPW';

  @override
  String get catalogBlikPrzelewy24Handle => 'BLIK / Przelewy24 आईडी';

  @override
  String get catalogEG48500123456LubEmail => 'जैसे +48 500 123 456 lub email';

  @override
  String get catalogEGSwedbankSebHandelsbanken =>
      'जैसे Swedbank / SEB / Handelsbanken';

  @override
  String get catalogEG12345678901 => 'जैसे 1234 567 890-1';

  @override
  String get catalogEGBg1234567EllerClearing81059 =>
      'जैसे Bg 123-4567 eller Clearing 8105-9';

  @override
  String get catalogEG1231234567 => 'जैसे 123 123 45 67';

  @override
  String get catalogEGDnbNordeaNorgeSparebank1 =>
      'जैसे DNB / Nordea Norge / SpareBank 1';

  @override
  String get catalogEG123456789013 => 'जैसे 1234.56.78901';

  @override
  String get catalogEGDnbanokk => 'जैसे DNBANOKK';

  @override
  String get catalogEGVippsNr12345 => 'जैसे Vipps-nr: 12345';

  @override
  String get catalogEGDanskeBankNordeaDanmarkJyskeBank =>
      'जैसे Danske Bank / Nordea Danmark / Jyske Bank';

  @override
  String get catalogEG1234 => 'जैसे 1234';

  @override
  String get catalogEG1234562 => 'जैसे 12 34 56';

  @override
  String get catalogEGQatarNationalBankQnbQiib =>
      'जैसे Qatar National Bank (QNB) / QIIB';

  @override
  String get catalogEGQa53Qnba000000001234567890123 =>
      'जैसे QA53 QNBA 0000 0000 1234 5678 9012 3';

  @override
  String get catalogEGQnbaqaqa => 'जैसे QNBAQAQA';

  @override
  String get catalogFawranInstantPayHandle => 'Fawran / Instant Pay आईडी';

  @override
  String get catalogEG55123456OrCompany => 'जैसे 55123456 या @company';

  @override
  String get catalogEGNationalBankOfKuwaitNbkKfh =>
      'जैसे National Bank of Kuwait (NBK) / KFH';

  @override
  String get catalogEGKw12Nbok0000000012345678901234 =>
      'जैसे KW12 NBOK 0000 0000 1234 5678 9012 34';

  @override
  String get catalogEGNbokkwkw => 'जैसे NBOKKWKW';

  @override
  String get catalogEGPaymentsCompanyKw => 'जैसे payments@company.kw';

  @override
  String get catalogEGNationalBankOfBahrainNbbBbk =>
      'जैसे National Bank of Bahrain (NBB) / BBK';

  @override
  String get catalogEGBh02Nbob00000000123456 =>
      'जैसे BH02 NBOB 0000 0000 1234 56';

  @override
  String get catalogEGNbobbhbm => 'जैसे NBOBBHBM';

  @override
  String get catalogEG39123456OrCompany => 'जैसे 39123456 या @company';

  @override
  String get catalogEGBankOfTaiwanCtbcBankMegaBank =>
      'जैसे Bank of Taiwan / CTBC Bank / Mega Bank';

  @override
  String get catalogEG0123456789012 => 'जैसे 0123-456-789012';

  @override
  String get catalogEG004BankOfTaiwan => 'जैसे 004 (Bank of Taiwan)';

  @override
  String get catalogTaiwanPayLinePayHandle => 'Taiwan Pay / Line Pay आईडी';

  @override
  String get partPaidStamp => 'आंशिक भुगतान';

  @override
  String get goProStamp => 'Pro लें';

  @override
  String get immediately => 'तुरंत';

  @override
  String get ensureScreenLock =>
      'ऐप लॉक के लिए डिवाइस की सेटिंग्स में स्क्रीन लॉक, फ़िंगरप्रिंट या फ़ेस अनलॉक सेट करें।';

  @override
  String get authenticateToEnableAppLock =>
      'ऐप लॉक चालू करने के लिए अपनी पहचान की पुष्टि करें';

  @override
  String get cannotSaveAppLock =>
      'ऐप लॉक की सेटिंग सेव नहीं हो सकी। फिर कोशिश करें।';

  @override
  String get cannotSaveLockTimeout =>
      'लॉक होने का समय सेव नहीं हो सका। फिर कोशिश करें।';

  @override
  String get unlockApp => 'Invoice Maker Pro अनलॉक करें';

  @override
  String get appLockOperationFailed =>
      'ऐप लॉक का अनुरोध पूरा नहीं हो सका। फिर कोशिश करें।';

  @override
  String get authenticationIncomplete => 'पहचान की पुष्टि पूरी नहीं हुई।';

  @override
  String get authenticationTemporarilyLocked =>
      'पहचान की पुष्टि कुछ समय के लिए बंद है। डिवाइस अनलॉक करके फिर कोशिश करें।';

  @override
  String get authenticationUnavailable =>
      'डिवाइस पर पहचान की पुष्टि उपलब्ध नहीं है। फिर कोशिश करें।';

  @override
  String get reminderChannelDescription => 'इनवॉइस की बकाया रकम के रिमाइंडर';

  @override
  String get remindersWorking => 'इस डिवाइस पर भुगतान के रिमाइंडर चालू हैं।';

  @override
  String get reminderTomorrow => 'कल';

  @override
  String get reminderToday => 'आज';

  @override
  String get clientGreeting => 'नमस्ते,';

  @override
  String get clientReminderThanks => 'धन्यवाद,';

  @override
  String get clientReminderAlreadyPaid =>
      'अगर आपने भुगतान कर दिया है, तो धन्यवाद। कोई सवाल हो तो हमें बताएँ।';

  @override
  String minutesCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString मिनट',
      one: '1 मिनट',
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
      other: 'हर $countString दिन',
      one: 'हर दिन',
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
      other: '$countString दिनों में',
      one: '1 दिन में',
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
      other: '· $countString दिनों की देरी',
      one: '· 1 दिन की देरी',
    );
    return '$_temp0';
  }

  @override
  String reminderBalance(String amount) {
    return '$amount बकाया';
  }

  @override
  String reminderBalanceFromClient(String amount, String client) {
    return '$client से $amount बकाया';
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
    return 'नमस्ते $client,';
  }

  @override
  String clientReminderOutstanding(
    String balance,
    String invoiceNumber,
    String timing,
  ) {
    return 'इनवॉइस $invoiceNumber पर $balance बाकी है।$timing';
  }

  @override
  String clientReminderUpi(String upi) {
    return 'आप $upi पर UPI से भुगतान कर सकते हैं।';
  }

  @override
  String clientReminderOverdue(String date, String days) {
    return ' भुगतान की तारीख $date थी ($days की देरी)।';
  }

  @override
  String clientReminderDueToday(String date) {
    return ' भुगतान आज ($date) करना है।';
  }

  @override
  String clientReminderDueOn(String date) {
    return ' भुगतान $date तक करना है।';
  }

  @override
  String get addYourLogo => 'अपना लोगो जोड़ें';

  @override
  String get addYourAddress => 'अपना पता जोड़ें';

  @override
  String addYourTaxId(String taxId) {
    return 'अपना $taxId जोड़ें';
  }

  @override
  String get addHowClientsPayYou => 'बताएँ कि ग्राहक पैसे कैसे भेजें';

  @override
  String get addYourSignature => 'अपने हस्ताक्षर जोड़ें';

  @override
  String get makeYourFirstInvoice => 'अपना पहला इनवॉइस बनाएँ';

  @override
  String get taxId => 'टैक्स आईडी';

  @override
  String get couldNotShowThePreviewPleaseTryAgain =>
      'झलक नहीं दिख सकी। फिर कोशिश करें।';

  @override
  String get selectCountryCurrency => 'देश और करेंसी चुनें';

  @override
  String get taxSystemPaymentFieldsSymbolWillAdapt =>
      'टैक्स के नियम, भुगतान फ़ील्ड और करेंसी का निशान उसी हिसाब से बदलेंगे';

  @override
  String get searchByCountryCurrencyOrCode => 'देश, करेंसी या कोड से खोजें…';

  @override
  String get upgradeToPro => 'Pro में अपग्रेड करें';

  @override
  String get paidStamp => 'भुगतान हुआ';

  @override
  String get overdueStamp => 'समय बीत गया';

  @override
  String get due => 'बकाया';

  @override
  String get dismissDialog => 'डायलॉग बंद करें';

  @override
  String get convertToInvoiceQuestion => 'इनवॉइस बनाएँ?';

  @override
  String thisWillGenerateAnActiveInvoiceFromFor(
    String estimateNumber,
    String clientName,
  ) {
    return 'इससे $clientName के लिए $estimateNumber का इनवॉइस बनेगा और एस्टीमेट को बदला हुआ दिखाया जाएगा।';
  }

  @override
  String get convertToInvoiceAction => 'इनवॉइस बनाएँ';

  @override
  String get invoiceMakerProIsLocked => 'Invoice Maker Pro लॉक है';

  @override
  String get useYourDeviceScreenLockOrBiometricsTo =>
      'आगे बढ़ने के लिए डिवाइस का स्क्रीन लॉक, फ़िंगरप्रिंट या फ़ेस अनलॉक इस्तेमाल करें।';

  @override
  String get unlock => 'अनलॉक करें';

  @override
  String get back => 'वापस';

  @override
  String get appLock => 'ऐप लॉक';

  @override
  String get requireAuthentication => 'पहचान की पुष्टि ज़रूरी करें';

  @override
  String get useYourScreenLockOrBiometrics =>
      'स्क्रीन लॉक, फ़िंगरप्रिंट या फ़ेस अनलॉक इस्तेमाल करें';

  @override
  String get lockAfter => 'इतनी देर बाद लॉक करें';

  @override
  String get timeSpentAwayFromTheApp => 'ऐप से बाहर रहने का समय';

  @override
  String get couldNotLoadReminderSettings =>
      'रिमाइंडर की सेटिंग्स लोड नहीं हो सकीं।';

  @override
  String get couldNotUpdatePaymentRemindersPleaseTryAgain =>
      'भुगतान के रिमाइंडर अपडेट नहीं हो सके। फिर कोशिश करें।';

  @override
  String get paymentReminders => 'भुगतान के रिमाइंडर';

  @override
  String get paymentRemindersAreAvailableOnAndroidAndIos =>
      'भुगतान के रिमाइंडर Android और iOS पर उपलब्ध हैं।';

  @override
  String get enableReminders => 'रिमाइंडर चालू करें';

  @override
  String get notifyMeAboutUnpaidBalances => 'बकाया रकम के नोटिफ़िकेशन दें';

  @override
  String get allowNotificationsInYourDeviceSettingsToTurn =>
      'रिमाइंडर चालू करने के लिए डिवाइस की सेटिंग्स में नोटिफ़िकेशन की अनुमति दें।';

  @override
  String get beforeTheDueDate => 'भुगतान की तारीख से पहले';

  @override
  String get whenOverdue => 'भुगतान की तारीख के बाद';

  @override
  String get off => 'बंद';

  @override
  String get remindersAreScheduledFor9AmOnThe =>
      'भुगतान की तारीख पर सुबह 9 बजे रिमाइंडर आएगा। इसके बाद तीन बार तक फिर याद दिलाया जाएगा।';

  @override
  String get sendTestNotification => 'टेस्ट नोटिफ़िकेशन भेजें';

  @override
  String get testNotificationSent => 'टेस्ट नोटिफ़िकेशन भेज दिया गया।';

  @override
  String get enterAMessageToSend => 'भेजने के लिए मैसेज लिखें।';

  @override
  String get couldNotOpenSharingTryAgain =>
      'शेयर करने का विकल्प नहीं खुल सका। फिर कोशिश करें।';

  @override
  String get sendReminder => 'रिमाइंडर भेजें';

  @override
  String get close => 'बंद करें';

  @override
  String get message => 'मैसेज';

  @override
  String get openWhatsapp => 'WhatsApp खोलें';

  @override
  String get shareSms => 'शेयर करें / SMS';

  @override
  String get couldNotShareTheReceipt => 'रसीद शेयर नहीं हो सकी।';

  @override
  String get couldNotOpenPrinting => 'प्रिंट का विकल्प नहीं खुल सका।';

  @override
  String get paymentReceipt => 'भुगतान की रसीद';

  @override
  String get shareReceipt => 'रसीद शेयर करें';

  @override
  String get printReceipt => 'रसीद प्रिंट करें';

  @override
  String get couldNotShowTheReceiptPreview => 'रसीद की झलक नहीं दिख सकी।';

  @override
  String get addNewClient => 'नया ग्राहक जोड़ें';

  @override
  String get editClient => 'ग्राहक की जानकारी बदलें';

  @override
  String get saveDetailsForFastInvoicing =>
      'जल्दी इनवॉइस बनाने के लिए जानकारी सेव करें';

  @override
  String get updateClientInformation => 'ग्राहक की जानकारी अपडेट करें';

  @override
  String get clientName => 'ग्राहक का नाम *';

  @override
  String get johnDoeAcmeCorp => 'रवि कुमार / Acme Corp';

  @override
  String get required => 'ज़रूरी है';

  @override
  String get email => 'ईमेल';

  @override
  String get phone => 'फ़ोन';

  @override
  String get address => 'पता';

  @override
  String get label123MainStCity => '123 मुख्य सड़क, शहर';

  @override
  String get addClient => 'ग्राहक जोड़ें';

  @override
  String get saveChanges => 'बदलाव सेव करें';

  @override
  String get couldNotSaveTheClientPleaseTryAgain =>
      'ग्राहक की जानकारी सेव नहीं हो सकी। फिर कोशिश करें।';

  @override
  String get deleteClient => 'ग्राहक हटाएँ?';

  @override
  String deleteTheirInvoicesAndEstimatesKeepTheClient(String clientName) {
    return '“$clientName” हटाएँ? उनके इनवॉइस और एस्टीमेट में उनकी जानकारी रहेगी। ग्राहक को वापस नहीं लाया जा सकता।';
  }

  @override
  String get clients => 'ग्राहक';

  @override
  String get whoYouBill => 'जिन्हें आप बिल भेजते हैं';

  @override
  String get noClientsYet => 'अभी कोई ग्राहक नहीं है';

  @override
  String get noResults => 'कोई नतीजा नहीं मिला';

  @override
  String get saveAClientOnceAndFillTheirDetails =>
      'ग्राहक की जानकारी एक बार सेव करें और हर इनवॉइस में इस्तेमाल करें';

  @override
  String get tryADifferentSearchTerm => 'कुछ और खोजें';

  @override
  String get tapForHistoryHoldToEdit =>
      'पुराने रिकॉर्ड के लिए टैप करें · बदलने के लिए दबाकर रखें';

  @override
  String get selectClient => 'ग्राहक चुनें';

  @override
  String get searchClientsHint => 'ग्राहक खोजें…';

  @override
  String get addYourFirstClientToStartSendingInvoices =>
      'इनवॉइस भेजने के लिए अपना पहला ग्राहक जोड़ें';

  @override
  String get invoicesBalance => 'इनवॉइस और बाकी रकम';

  @override
  String get editClientMenu => 'ग्राहक की जानकारी बदलें';

  @override
  String get deleteClientMenu => 'ग्राहक हटाएँ';

  @override
  String get totalInvoiced => 'बिल की कुल रकम';

  @override
  String get paid => 'भुगतान हुआ';

  @override
  String get dueBalance => 'बाकी रकम';

  @override
  String totalsAreForInvoicesOnlyInOtherCurrencies(
    String currencyCode,
    int count,
  ) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'कुल रकम सिर्फ़ $currencyCode वाले इनवॉइस की है। दूसरी करेंसी वाले $countString इसमें शामिल नहीं हैं।';
  }

  @override
  String invoiceHistoryCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'इनवॉइस ($countString)';
  }

  @override
  String get newInvoice => 'नया इनवॉइस';

  @override
  String get noInvoicesCreatedForThisClientYet =>
      'इस ग्राहक के लिए अभी कोई इनवॉइस नहीं बनाया गया है';

  @override
  String get settings => 'सेटिंग्स';

  @override
  String get workspace => 'वर्कस्पेस';

  @override
  String get businessProfile => 'बिज़नेस प्रोफ़ाइल';

  @override
  String get nameAddressBankDetailsLogo => 'नाम, पता, बैंक की जानकारी और लोगो';

  @override
  String get reports => 'रिपोर्ट';

  @override
  String get revenueCollectionsTopClientsItems =>
      'बिक्री, मिली रकम, प्रमुख ग्राहक और आइटम';

  @override
  String get notificationsForUnpaidInvoices => 'बकाया इनवॉइस के नोटिफ़िकेशन';

  @override
  String get documentNumbering => 'दस्तावेज़ की नंबरिंग';

  @override
  String get prefixesDigitsAndFinancialYear =>
      'प्रीफ़िक्स, अंकों की संख्या और वित्त वर्ष';

  @override
  String get security => 'सुरक्षा';

  @override
  String on(String label) {
    return 'चालू · $label';
  }

  @override
  String get yourData => 'आपका डेटा';

  @override
  String get exportDataJson => 'डेटा एक्सपोर्ट करें (JSON)';

  @override
  String get aFullBackupOfYourRecordsProfileAnd =>
      'आपके रिकॉर्ड, प्रोफ़ाइल और सेटिंग्स का पूरा बैकअप। इसे सुरक्षित जगह रखें।';

  @override
  String get exportToCsvExcel => 'CSV / Excel में एक्सपोर्ट करें';

  @override
  String get spreadsheetsForInvoicesLineItemsPaymentsClientsItems =>
      'इनवॉइस, उनकी एंट्री, भुगतान, ग्राहक और आइटम की स्प्रेडशीट';

  @override
  String get restoreFromBackup => 'बैकअप से वापस लाएँ';

  @override
  String get replaceEverythingHereWithAnExportedFile =>
      'मौजूदा डेटा को एक्सपोर्ट की गई फ़ाइल के डेटा से बदलें';

  @override
  String get preferences => 'पसंद की सेटिंग्स';

  @override
  String get aboutSupport => 'ऐप और सहायता';

  @override
  String get rateUsOnPlayStore => 'Play Store पर रेटिंग दें';

  @override
  String get leaveARatingForInvoiceMakerPro =>
      'Invoice Maker Pro को रेटिंग दें';

  @override
  String get helpGuide => 'मदद और गाइड';

  @override
  String get quickTipsAndWalkthrough =>
      'छोटे सुझाव और ऐप इस्तेमाल करने की गाइड';

  @override
  String get unlimitedInvoicesClientsNoWatermark =>
      'बिना रोक-टोक इनवॉइस और ग्राहक जोड़ें। कोई वॉटरमार्क नहीं।';

  @override
  String get goPro => 'Pro लें';

  @override
  String get proWorkspaceActive => 'Pro चालू है';

  @override
  String get unlimitedInvoicesCleanPdfNoWatermark =>
      'असीमित इनवॉइस • बिना वॉटरमार्क के PDF';

  @override
  String get sameAsDevice => 'डिवाइस की सेटिंग के अनुसार';

  @override
  String get light => 'लाइट';

  @override
  String get dark => 'डार्क';

  @override
  String get appearance => 'दिखावट';

  @override
  String get defaultCurrency => 'डिफ़ॉल्ट करेंसी';

  @override
  String get defaultDesignTypography => 'डिफ़ॉल्ट डिज़ाइन और फ़ॉन्ट';

  @override
  String get defaultInvoiceDesign => 'डिफ़ॉल्ट इनवॉइस डिज़ाइन';

  @override
  String customRate(String taxName) {
    return '$taxName की अपनी दर';
  }

  @override
  String defaultRate(String taxName) {
    return '$taxName की डिफ़ॉल्ट दर';
  }

  @override
  String editRate(String taxName) {
    return '$taxName की दर बदलें';
  }

  @override
  String get setTheDefaultTaxRateUsedWhenYou =>
      'नए इनवॉइस के लिए डिफ़ॉल्ट टैक्स दर सेट करें।';

  @override
  String namedTaxRatePercent(String taxName) {
    return '$taxName की दर (%)';
  }

  @override
  String exampleValue(String rate) {
    return 'जैसे $rate';
  }

  @override
  String get enterAValidNumber => 'सही संख्या डालें';

  @override
  String get useAValueBetween0And100 => '0 से 100 के बीच की संख्या डालें';

  @override
  String get reset => 'रीसेट करें';

  @override
  String get save => 'सेव करें';

  @override
  String get couldNotExportCsvFilesPleaseTryAgain =>
      'CSV फ़ाइलें एक्सपोर्ट नहीं हो सकीं। फिर कोशिश करें।';

  @override
  String invoiceMakerProDataExport(String date) {
    return 'Invoice Maker Pro का एक्सपोर्ट किया गया डेटा ($date)';
  }

  @override
  String get couldNotExportYourDataPleaseTryAgain =>
      'आपका डेटा एक्सपोर्ट नहीं हो सका। फिर कोशिश करें।';

  @override
  String get couldNotOpenThatFilePleaseTryAgain =>
      'फ़ाइल नहीं खुल सकी। फिर कोशिश करें।';

  @override
  String get thisFileIsNotAnInvoiceMakerPro =>
      'यह फ़ाइल Invoice Maker Pro का बैकअप नहीं है।';

  @override
  String backupDateContext(String date) {
    return ' ($date का)';
  }

  @override
  String get replaceAllData => 'सारा डेटा बदलें?';

  @override
  String thisBackupHasRestoringReplacesAllInvoicesEstimates(
    String date,
    String secondValue,
  ) {
    return 'इस बैकअप$date में $secondValue हैं।\n\nइसे वापस लाने पर इस फ़ोन के सभी इनवॉइस, एस्टीमेट, ग्राहक, आइटम और आपकी बिज़नेस प्रोफ़ाइल बदल जाएँगी। पहले आपके मौजूदा डेटा की कॉपी सेव होगी, जिसे आप बाद में शेयर कर सकते हैं।';
  }

  @override
  String get replace => 'बदलें';

  @override
  String get backupRestored => 'बैकअप वापस आ गया।';

  @override
  String get recordsRestoredButSomeSettingsWereNotCheck =>
      'रिकॉर्ड वापस आ गए, कुछ सेटिंग्स वापस नहीं आईं। अपनी बिज़नेस प्रोफ़ाइल जाँचें।';

  @override
  String get couldNotRestoreThisBackupNothingWasChanged =>
      'बैकअप वापस नहीं आ सका। कोई बदलाव नहीं हुआ।';

  @override
  String get shareOldData => 'पुराना डेटा शेयर करें';

  @override
  String get invoiceMakerProDataSavedBeforeRestore =>
      'बैकअप वापस लाने से पहले सेव किया गया Invoice Maker Pro का डेटा';

  @override
  String get discardChanges => 'बदलाव छोड़ें?';

  @override
  String get youHaveUnsavedChangesToYourBusinessProfile =>
      'बिज़नेस प्रोफ़ाइल में कुछ बदलाव सेव नहीं हुए हैं। बिना सेव किए बाहर जाएँ?';

  @override
  String get discard => 'बदलाव छोड़ें';

  @override
  String get keepEditing => 'एडिट करते रहें';

  @override
  String get pleaseFillAllRequiredFields => 'सभी ज़रूरी फ़ील्ड भरें';

  @override
  String get businessProfileSavedSuccessfully => 'बिज़नेस प्रोफ़ाइल सेव हो गई!';

  @override
  String get couldNotOpenThatImageTryAnotherOne =>
      'वह इमेज नहीं खुल सकी। दूसरी इमेज आज़माएँ।';

  @override
  String get businessLogo => 'बिज़नेस का लोगो';

  @override
  String get chooseFromGallery => 'गैलरी से चुनें';

  @override
  String get selectAnExistingPngOrJpegImage => 'मौजूदा PNG या JPEG इमेज चुनें';

  @override
  String get takePhoto => 'फ़ोटो लें';

  @override
  String get captureCompanyLogoUsingCamera =>
      'कैमरे से कंपनी के लोगो की फ़ोटो लें';

  @override
  String get removeLogo => 'लोगो हटाएँ';

  @override
  String get clearCurrentLogoImage => 'मौजूदा लोगो हटाएँ';

  @override
  String get couldNotOpenThatSignatureImageTryAnother =>
      'हस्ताक्षर की इमेज नहीं खुल सकी। दूसरी इमेज आज़माएँ।';

  @override
  String get authorizedSignature => 'अधिकृत हस्ताक्षर';

  @override
  String get drawSignatureOnScreen => 'स्क्रीन पर हस्ताक्षर करें';

  @override
  String get signSmoothlyWithYourFingerOrStylus =>
      'उँगली या स्टाइलस से हस्ताक्षर करें';

  @override
  String get uploadImageFromGallery => 'गैलरी से इमेज अपलोड करें';

  @override
  String get pngWithTransparentBackgroundRecommended =>
      'पारदर्शी बैकग्राउंड वाली PNG बेहतर रहेगी';

  @override
  String get removeSignature => 'हस्ताक्षर हटाएँ';

  @override
  String get clearCurrentSignature => 'मौजूदा हस्ताक्षर हटाएँ';

  @override
  String get brandingIdentity => 'ब्रांड और पहचान';

  @override
  String get companyLogo => 'कंपनी का लोगो';

  @override
  String get tapToChange => 'बदलने के लिए टैप करें';

  @override
  String get uploadLogo => 'लोगो अपलोड करें';

  @override
  String get drawOrUpload => 'बनाएँ या अपलोड करें';

  @override
  String get businessCompanyName => 'बिज़नेस / कंपनी का नाम *';

  @override
  String get eGAcmeInnovationsLlc => 'जैसे Acme Innovations LLC';

  @override
  String get businessNameIsRequired => 'बिज़नेस का नाम ज़रूरी है';

  @override
  String get taglineOrIndustryOptional =>
      'टैगलाइन या कारोबार का प्रकार (वैकल्पिक)';

  @override
  String get eGCreativeStudioDigitalAgency =>
      'जैसे क्रिएटिव स्टूडियो और डिजिटल एजेंसी';

  @override
  String get contactLocation => 'संपर्क और पता';

  @override
  String get businessEmail => 'बिज़नेस ईमेल';

  @override
  String get phoneNumber => 'फ़ोन नंबर';

  @override
  String get websitePortfolio => 'वेबसाइट / पोर्टफ़ोलियो';

  @override
  String get registeredBusinessAddress => 'बिज़नेस का रजिस्टर्ड पता';

  @override
  String get suite400100MainStreetCityStateZip =>
      'ऑफ़िस 400, 100 मुख्य सड़क, शहर, राज्य, पिन कोड';

  @override
  String get taxLegalRegistration => 'टैक्स और कानूनी रजिस्ट्रेशन';

  @override
  String thisWillBeDisplayedOnAllGeneratedPdfs(
    String taxIdLabel,
    String country,
  ) {
    return '$country के लिए बनाए गए सभी PDF और एस्टीमेट पर यह $taxIdLabel दिखेगा।';
  }

  @override
  String get bankPaymentDetails => 'बैंक और भुगतान की जानकारी';

  @override
  String paymentFieldsRoutingFormatMatchStandards(
    String country,
    String secondValue,
  ) {
    return 'भुगतान के फ़ील्ड और रूटिंग का फ़ॉर्मैट $country ($secondValue) के मानकों के अनुसार हैं।';
  }

  @override
  String get bankName => 'बैंक का नाम';

  @override
  String optionalFieldTitle(String digitalPaymentLabel) {
    return '$digitalPaymentLabel (वैकल्पिक)';
  }

  @override
  String get defaultPaymentNotesTerms => 'डिफ़ॉल्ट भुगतान नोट और शर्तें';

  @override
  String get eGNet15PaymentIsDueWithin =>
      'जैसे इनवॉइस की तारीख से 15 दिन के अंदर भुगतान करें।';

  @override
  String get saveBusinessProfile => 'बिज़नेस प्रोफ़ाइल सेव करें';

  @override
  String get yourBusinessName => 'आपके बिज़नेस का नाम';

  @override
  String get setYourBusinessIdentity => 'अपने बिज़नेस की पहचान सेट करें';

  @override
  String get signed => 'हस्ताक्षर हो गए';

  @override
  String get profileReadiness => 'प्रोफ़ाइल कितनी पूरी है';

  @override
  String get useLettersDigitsHyphensOrSlashes =>
      'अक्षर, अंक, हाइफ़न या स्लैश इस्तेमाल करें।';

  @override
  String get enterANumberFrom3To8 => '3 से 8 के बीच की संख्या डालें।';

  @override
  String get enterAPositiveWholeNumber => 'शून्य से बड़ी पूरी संख्या डालें।';

  @override
  String get couldNotSaveDocumentSettingsPleaseTryAgain =>
      'दस्तावेज़ की सेटिंग्स सेव नहीं हो सकीं। फिर कोशिश करें।';

  @override
  String get couldNotLoadDocumentSettings =>
      'दस्तावेज़ की सेटिंग्स लोड नहीं हो सकीं।';

  @override
  String get invoicePrefix => 'इनवॉइस नंबर का प्रीफ़िक्स';

  @override
  String get estimatePrefix => 'एस्टीमेट नंबर का प्रीफ़िक्स';

  @override
  String get numberOfDigits => 'अंकों की संख्या';

  @override
  String get startInvoiceNumbersFrom => 'इनवॉइस नंबर यहाँ से शुरू करें';

  @override
  String get startEstimateNumbersFrom => 'एस्टीमेट नंबर यहाँ से शुरू करें';

  @override
  String get numbersContinueAfterTheHighestNumberInThe =>
      'नंबर इस सीरीज़ की सबसे बड़ी संख्या के बाद से जारी होंगे।';

  @override
  String get addFinancialYear => 'वित्त वर्ष जोड़ें';

  @override
  String get theIndianFinancialYearStartsOn1April =>
      'भारत में वित्त वर्ष 1 अप्रैल से शुरू होता है।';

  @override
  String get couldNotLoadTheNextDocumentNumbers =>
      'दस्तावेज़ों के अगले नंबर लोड नहीं हो सके।';

  @override
  String nextInvoice(String value) {
    return 'अगला इनवॉइस: $value';
  }

  @override
  String nextEstimate(String value) {
    return 'अगला एस्टीमेट: $value';
  }

  @override
  String get drawYourSignatureAboveThenSave =>
      'ऊपर हस्ताक्षर करें, फिर सेव करें।';

  @override
  String get thatLooksTooSmallSignAcrossThePad =>
      'हस्ताक्षर बहुत छोटा है। बड़े आकार में हस्ताक्षर करके सेव करें।';

  @override
  String get couldNotSaveTheSignaturePleaseTryAgain =>
      'हस्ताक्षर सेव नहीं हो सका। फिर कोशिश करें।';

  @override
  String get drawSignature => 'हस्ताक्षर करें';

  @override
  String get signWithYourFingerOrStylus => 'उँगली या स्टाइलस से हस्ताक्षर करें';

  @override
  String get drawInsideThisBox => 'इस बॉक्स के अंदर हस्ताक्षर करें';

  @override
  String get authorizedSignatory => 'अधिकृत हस्ताक्षरकर्ता';

  @override
  String get undoStroke => 'आखिरी लाइन हटाएँ';

  @override
  String get clearCanvas => 'सब मिटाएँ';

  @override
  String get useSignature => 'हस्ताक्षर इस्तेमाल करें';

  @override
  String get invoiceDesignStudio => 'इनवॉइस डिज़ाइन स्टूडियो';

  @override
  String get changeInvoiceStatus => 'इनवॉइस की स्थिति बदलें';

  @override
  String invoiceWithNumber(String invoiceNumber) {
    return 'इनवॉइस $invoiceNumber';
  }

  @override
  String get unpaid => 'भुगतान बाकी';

  @override
  String get deletesRecordedPayments => 'दर्ज भुगतान हटाता है';

  @override
  String get recordAPayment => 'भुगतान दर्ज करें';

  @override
  String get addADepositOrPartPayment => 'एडवांस या आंशिक भुगतान जोड़ें';

  @override
  String get paidInFull => 'पूरा भुगतान हुआ';

  @override
  String get paymentReceivedSuccessfully => 'भुगतान मिल गया';

  @override
  String get couldNotOpenTheReceipt => 'रसीद नहीं खुल सकी।';

  @override
  String get moreActions => 'और विकल्प';

  @override
  String get changeDesign => 'डिज़ाइन बदलें';

  @override
  String designThemeSummary(String value) {
    return '$value · फ़ॉन्ट, रंग और लेआउट';
  }

  @override
  String get duplicateInvoice => 'इनवॉइस की कॉपी बनाएँ';

  @override
  String get createANewCopyWithSameItems => 'उन्हीं आइटम के साथ नई कॉपी बनाएँ';

  @override
  String get markAsUnpaid => 'भुगतान बाकी के रूप में दर्ज करें';

  @override
  String get markAsPaid => 'भुगतान हुआ के रूप में दर्ज करें';

  @override
  String get deletesTheRecordedPayments => 'दर्ज किए गए भुगतान हटाता है';

  @override
  String get recordsAPaymentForTheBalance => 'बाकी रकम का भुगतान दर्ज करता है';

  @override
  String get payments => 'भुगतान';

  @override
  String get seeRecordOrDeletePayments => 'भुगतान देखें, दर्ज करें या हटाएँ';

  @override
  String get editAndShareAPaymentReminderWithYour =>
      'भुगतान का रिमाइंडर बदलें और अपने ग्राहक को भेजें';

  @override
  String get receipt => 'रसीद';

  @override
  String get previewAReceiptForAllRecordedPayments =>
      'सभी दर्ज भुगतानों की रसीद देखें';

  @override
  String get deleteInvoice => 'इनवॉइस हटाएँ';

  @override
  String get permanentlyRemoveThisInvoice => 'यह इनवॉइस हमेशा के लिए हटाएँ';

  @override
  String duplicatedAsDatedTodayAndUnpaid(String invoiceNumber) {
    return 'आज की तारीख पर $invoiceNumber की कॉपी बनी। भुगतान बाकी है।';
  }

  @override
  String get couldNotDuplicateTheInvoicePleaseTryAgain =>
      'इनवॉइस की कॉपी नहीं बन सकी। फिर कोशिश करें।';

  @override
  String get design => 'डिज़ाइन';

  @override
  String dueDateAndClient(String date, String clientName) {
    return 'भुगतान की तारीख: $date • $clientName';
  }

  @override
  String get sendInvoice => 'इनवॉइस भेजें';

  @override
  String get expandDetails => 'पूरी जानकारी दिखाएँ';

  @override
  String clientAndDueDate(String clientName, String date) {
    return '$clientName  ·  भुगतान की तारीख: $date';
  }

  @override
  String get tapToMarkAsNotSent => 'भेजा नहीं गया दर्ज करने के लिए दबाएँ';

  @override
  String get tapToMarkAsSent => 'भेजा गया दर्ज करने के लिए दबाएँ';

  @override
  String get sent => 'भेजा गया';

  @override
  String get notSent => 'भेजा नहीं गया';

  @override
  String paidAmountLabel(String amount) {
    return 'मिला भुगतान: $amount';
  }

  @override
  String balanceDue(String amount) {
    return 'बाकी रकम: $amount';
  }

  @override
  String get download => 'डाउनलोड करें';

  @override
  String get print => 'प्रिंट करें';

  @override
  String get edit => 'बदलें';

  @override
  String get more => 'और';

  @override
  String get camera => 'कैमरा';

  @override
  String get gallery => 'गैलरी';

  @override
  String get couldNotAddThePhotoPleaseTryAgain =>
      'फ़ोटो नहीं जुड़ सकी। फिर कोशिश करें।';

  @override
  String get photoUnavailable => 'फ़ोटो उपलब्ध नहीं है';

  @override
  String get attachments => 'अटैचमेंट';

  @override
  String get addAttachment => 'अटैचमेंट जोड़ें';

  @override
  String get pleaseAddAClientNameBillTo =>
      'बिल पाने वाले ग्राहक का नाम जोड़ें।';

  @override
  String get pleaseAddAtLeastOneLineItem => 'कम से कम एक आइटम जोड़ें।';

  @override
  String invoiceNumberIsAlreadyUsedPickAnotherNumber(String value) {
    return 'इनवॉइस नंबर $value पहले से इस्तेमाल हो रहा है। दूसरा नंबर चुनें।';
  }

  @override
  String get couldNotSaveTheInvoicePleaseTryAgain =>
      'इनवॉइस सेव नहीं हो सका। फिर कोशिश करें।';

  @override
  String get invoiceDetailsDates => 'इनवॉइस की जानकारी और तारीखें';

  @override
  String get invoiceNumber => 'इनवॉइस नंबर';

  @override
  String get eGInv00001 => 'जैसे INV00001';

  @override
  String get invoiceIssueDate => 'इनवॉइस जारी करने की तारीख';

  @override
  String get paymentTermsDueDate => 'भुगतान की शर्तें और तारीख';

  @override
  String get optionalCreditPeriodForPayment =>
      'भुगतान के लिए अतिरिक्त समय (वैकल्पिक)';

  @override
  String get noDueDate => 'भुगतान की तारीख तय नहीं है';

  @override
  String get dueOnReceipt => 'बिल मिलते ही भुगतान';

  @override
  String get label7Days => '+7 दिन';

  @override
  String get label15Days => '+15 दिन';

  @override
  String get label30Days => '+30 दिन';

  @override
  String get customDate => 'तारीख चुनें…';

  @override
  String get applyChanges => 'बदलाव लागू करें';

  @override
  String get billFromYourBusiness => 'बिल भेजने वाला (आपका बिज़नेस)';

  @override
  String get businessName => 'बिज़नेस का नाम *';

  @override
  String get saveBusinessInfo => 'बिज़नेस की जानकारी सेव करें';

  @override
  String get editItem => 'आइटम बदलें';

  @override
  String get addItem => 'आइटम जोड़ें';

  @override
  String get description => 'विवरण *';

  @override
  String get eGConsultingDesignProduct => 'जैसे सलाह, डिज़ाइन, प्रोडक्ट';

  @override
  String get quantity => 'मात्रा';

  @override
  String get unitPrice => 'प्रति यूनिट कीमत';

  @override
  String get hideItemDiscountTax => 'आइटम की छूट और टैक्स छिपाएँ';

  @override
  String get addItemDiscountTax => '+ आइटम पर छूट और टैक्स जोड़ें';

  @override
  String get discountRequiredAmountLabel => 'छूट (%)';

  @override
  String get taxRate => 'टैक्स दर (%)';

  @override
  String get invoiceRate => 'इनवॉइस की दर';

  @override
  String get baseAmount => 'मूल रकम:';

  @override
  String discountPercentLabel(String rate) {
    return 'छूट ($rate%):';
  }

  @override
  String taxAtAddedInTotals(String rate) {
    return '$rate% टैक्स (कुल रकम में शामिल):';
  }

  @override
  String get lineAmountBeforeTax => 'आइटम की रकम (टैक्स से पहले):';

  @override
  String get pleaseEnterAnItemDescription => 'आइटम का विवरण डालें';

  @override
  String get quantityMustBeMoreThan0 => 'मात्रा 0 से ज़्यादा होनी चाहिए';

  @override
  String get updateItem => 'आइटम अपडेट करें';

  @override
  String get addToInvoice => 'इनवॉइस में जोड़ें';

  @override
  String get addDiscount => 'छूट जोड़ें';

  @override
  String get percentage => 'प्रतिशत (%)';

  @override
  String flatAmount(String currencySymbol) {
    return 'तय रकम ($currencySymbol)';
  }

  @override
  String get discountPercentage => 'छूट का प्रतिशत (%)';

  @override
  String get discountAmount => 'छूट की रकम';

  @override
  String get applyDiscount => 'छूट लागू करें';

  @override
  String configureNamedTax(String taxName) {
    return '$taxName की सेटिंग्स';
  }

  @override
  String get chooseCgstSgstIntraStateOrIgstInter =>
      'CGST + SGST (राज्य के अंदर) या IGST (राज्यों के बीच) चुनें';

  @override
  String setPercentageToApplyToThisInvoice(String taxName) {
    return 'इस इनवॉइस के लिए $taxName का प्रतिशत तय करें।';
  }

  @override
  String get noTax0 => 'बिना टैक्स (0%)';

  @override
  String get igstSingle => 'सिर्फ़ IGST';

  @override
  String get igstRate => 'IGST की दर (%)';

  @override
  String get removeTax => 'टैक्स हटाएँ';

  @override
  String get applyTax => 'टैक्स लागू करें';

  @override
  String get shippingCharges => 'डिलीवरी शुल्क';

  @override
  String shippingFee(String currencySymbol) {
    return 'डिलीवरी शुल्क ($currencySymbol)';
  }

  @override
  String get saveShippingFee => 'डिलीवरी शुल्क सेव करें';

  @override
  String get amountAlreadyReceived => 'पहले से मिली रकम';

  @override
  String amountPaid(String currencySymbol) {
    return 'मिला भुगतान ($currencySymbol)';
  }

  @override
  String get selectPaymentMethod => 'भुगतान का तरीका चुनें';

  @override
  String get termsNotes => 'शर्तें और नोट';

  @override
  String get termsSlashNotes => 'शर्तें / नोट';

  @override
  String get eGThanksForYourBusiness =>
      'जैसे हमारे साथ व्यापार करने के लिए धन्यवाद।';

  @override
  String get saveNotes => 'नोट सेव करें';

  @override
  String get markInvoiceAs => 'इनवॉइस की स्थिति चुनें';

  @override
  String get deleteInvoiceQuestion => 'इनवॉइस हटाएँ?';

  @override
  String get areYouSureYouWantToDeleteThis =>
      'क्या आप यह इनवॉइस हटाना चाहते हैं? इसे वापस नहीं लाया जा सकता।';

  @override
  String get youHaveUnsavedChangesLeaveWithoutSavingThem =>
      'कुछ बदलाव सेव नहीं हुए हैं। बिना सेव किए बाहर जाएँ?';

  @override
  String get addClients => 'ग्राहक जोड़ें';

  @override
  String get editInvoice => 'इनवॉइस बदलें';

  @override
  String get createInvoice => 'इनवॉइस बनाएँ';

  @override
  String get clearItems => 'सभी आइटम हटाएँ';

  @override
  String get resetHelpfulTips => 'सुझाव फिर से दिखाएँ';

  @override
  String get invoiceHeading => 'इनवॉइस';

  @override
  String dueDateLabel(String date) {
    return 'भुगतान की तारीख: $date';
  }

  @override
  String get templates => 'टेम्पलेट';

  @override
  String get chooseStylePaperDesign => 'स्टाइल और पेज डिज़ाइन चुनें';

  @override
  String get billFrom => 'बिल भेजने वाला';

  @override
  String get addBusiness => 'बिज़नेस जोड़ें';

  @override
  String get billTo => 'बिल पाने वाला';

  @override
  String get addYourClientOrCustomer => 'अपना ग्राहक जोड़ें';

  @override
  String get selectAnExistingClientOrCreateANew =>
      'बिल बनाने के लिए मौजूदा ग्राहक चुनें या नया ग्राहक जोड़ें';

  @override
  String get items => 'आइटम';

  @override
  String get addItems => 'आइटम जोड़ें';

  @override
  String get createYourItemOrService => 'अपना आइटम या सेवा बनाएँ';

  @override
  String get addNamePriceQuantityAndDetails =>
      'नाम, कीमत, मात्रा और विवरण जोड़ें';

  @override
  String get discount => 'छूट';

  @override
  String get shipping => 'डिलीवरी';

  @override
  String get total => 'कुल';

  @override
  String get configureDiscountTaxOrShipping => 'छूट, टैक्स या डिलीवरी सेट करें';

  @override
  String applyRatesDiscountsOrShippingCharges(String taxName) {
    return '$taxName की दर, छूट या डिलीवरी शुल्क लागू करें';
  }

  @override
  String get balanceDueHeading => 'बाकी रकम';

  @override
  String get currency => 'करेंसी';

  @override
  String get paymentMethod => 'भुगतान का तरीका';

  @override
  String get signature => 'हस्ताक्षर';

  @override
  String get signatureAttached => 'हस्ताक्षर जुड़ा है';

  @override
  String get addSignature => 'हस्ताक्षर जोड़ें';

  @override
  String get termsOrNotes => 'शर्तें या नोट';

  @override
  String get thanksForYourBusiness => 'हमारे साथ व्यापार करने के लिए धन्यवाद।';

  @override
  String get setPaymentMethodSignature =>
      'भुगतान का तरीका और हस्ताक्षर सेट करें';

  @override
  String get addUpiBankDetailsNotesOrYourSignature =>
      'UPI, बैंक की जानकारी, नोट या अपने हस्ताक्षर जोड़ें';

  @override
  String get markAs => 'स्थिति चुनें';

  @override
  String get preview => 'झलक';

  @override
  String invoiceFor(String invoiceNumber, String clientName) {
    return '$clientName के लिए इनवॉइस $invoiceNumber';
  }

  @override
  String get markAsSent => 'भेजा गया दर्ज करें?';

  @override
  String didYouSendTo(String invoiceNumber, String clientName) {
    return 'क्या आपने $clientName को $invoiceNumber भेज दिया है?';
  }

  @override
  String get notYet => 'अभी नहीं';

  @override
  String get markAsSentAction => 'भेजा गया दर्ज करें';

  @override
  String get couldNotShareTheInvoicePleaseTryAgain =>
      'इनवॉइस शेयर नहीं हो सका। फिर कोशिश करें।';

  @override
  String savedTo(String name, String secondValue) {
    return '$name को $secondValue में सेव किया गया';
  }

  @override
  String get view => 'देखें';

  @override
  String get noAppFoundToOpenPdfsInstallA =>
      'PDF खोलने वाला ऐप नहीं मिला। PDF देखने के लिए कोई ऐप इंस्टॉल करें।';

  @override
  String get couldNotSaveThePdfPleaseTryAgain =>
      'PDF सेव नहीं हो सका। फिर कोशिश करें।';

  @override
  String get markUnpaidQuestion => 'भुगतान बाकी के रूप में दर्ज करें?';

  @override
  String get deletePayments => 'भुगतान हटाएँ';

  @override
  String get couldNotUpdateThePaymentPleaseTryAgain =>
      'भुगतान अपडेट नहीं हो सका। फिर कोशिश करें।';

  @override
  String get couldNotOpenPrintingPleaseTryAgain =>
      'प्रिंट करने का विकल्प नहीं खुल सका। फिर कोशिश करें।';

  @override
  String deleteThisCannotBeUndone(String invoiceNumber) {
    return '$invoiceNumber हटाएँ? इसे वापस नहीं लाया जा सकता।';
  }

  @override
  String get couldNotDeleteTheInvoicePleaseTryAgain =>
      'इनवॉइस हटाया नहीं जा सका। फिर कोशिश करें।';

  @override
  String get paymentRecorded => 'भुगतान दर्ज हो गया';

  @override
  String get sendReceipt => 'रसीद भेजें';

  @override
  String get deletePayment => 'भुगतान हटाएँ?';

  @override
  String deleteThePaymentFrom(String amount, String date) {
    return '$date का $amount का भुगतान हटाएँ?';
  }

  @override
  String invoiceTotal(String invoiceNumber, String amount) {
    return 'इनवॉइस $invoiceNumber · कुल $amount';
  }

  @override
  String get received => 'मिली रकम';

  @override
  String get overpaidBy => 'इतनी ज़्यादा रकम मिली';

  @override
  String get balanceDueLabel => 'बाकी रकम';

  @override
  String get noPaymentsRecordedYet => 'अभी कोई भुगतान दर्ज नहीं है।';

  @override
  String get deletePayment2 => 'भुगतान हटाएँ';

  @override
  String get recordPayment => 'भुगतान दर्ज करें';

  @override
  String get amountReceived => 'मिली रकम';

  @override
  String get enterAnAmountAbove0 => '0 से बड़ी रकम डालें';

  @override
  String remainingAmountLabel(String amount) {
    return 'बाकी रकम: $amount';
  }

  @override
  String get dateReceived => 'भुगतान मिलने की तारीख';

  @override
  String get noteOptional => 'नोट (वैकल्पिक)';

  @override
  String get savePayment => 'भुगतान सेव करें';

  @override
  String get livePreviewUpdatesInstantly => 'झलक तुरंत अपडेट होती है';

  @override
  String get updating => 'अपडेट हो रहा है…';

  @override
  String get quickLook => 'झलक देखें';

  @override
  String get fit => 'स्क्रीन में फ़िट करें';

  @override
  String get style => 'स्टाइल';

  @override
  String get typo => 'फ़ॉन्ट';

  @override
  String get layout => 'लेआउट';

  @override
  String get sections => 'सेक्शन';

  @override
  String get setAsDefaultStyleForFutureDocuments =>
      'नए दस्तावेज़ों के लिए इसे डिफ़ॉल्ट स्टाइल बनाएँ';

  @override
  String get applySaveStyle => 'स्टाइल लागू करें और सेव करें';

  @override
  String get paperDesignTemplate => 'पेज डिज़ाइन का टेम्पलेट';

  @override
  String get colorPalettePresets => 'तैयार रंग संयोजन';

  @override
  String get fontFamily => 'फ़ॉन्ट';

  @override
  String get documentDensitySizing => 'दस्तावेज़ में जगह और आकार';

  @override
  String get label85Scale => '85% आकार';

  @override
  String get label100Normal => '100% सामान्य';

  @override
  String get label115Large => '115% बड़ा';

  @override
  String get headerAlignmentPosition => 'ऊपरी हिस्से की जगह और अलाइनमेंट';

  @override
  String get addressBlockArrangement => 'पतों का लेआउट';

  @override
  String get documentSectionsVisibility => 'दस्तावेज़ में दिखने वाले सेक्शन';

  @override
  String get bankPaymentDetails2 => 'बैंक से भुगतान की जानकारी';

  @override
  String get bankNameAccountNumberRoutingCode =>
      'बैंक का नाम, खाता नंबर और रूटिंग कोड';

  @override
  String get digitalUpiPaymentId => 'UPI / डिजिटल भुगतान आईडी';

  @override
  String get upiIdAndFastPaymentHandle => 'UPI ID और डिजिटल भुगतान का पता';

  @override
  String get signatureSignOff => 'हस्ताक्षर और मंज़ूरी';

  @override
  String get authorizedSignatureBoxInFooter => 'नीचे अधिकृत हस्ताक्षर की जगह';

  @override
  String get notesTerms => 'नोट और शर्तें';

  @override
  String get customerNotesContainer => 'ग्राहक के लिए नोट की जगह';

  @override
  String get tableColumns => 'टेबल के कॉलम';

  @override
  String get quantityQtyColumn => 'मात्रा (QTY) का कॉलम';

  @override
  String get numberOfUnitsOrHours => 'यूनिट या घंटों की संख्या';

  @override
  String get unitPriceColumn => 'प्रति यूनिट कीमत का कॉलम';

  @override
  String get individualItemRate => 'हर आइटम की दर';

  @override
  String get customFooterClosingMessage => 'नीचे दिखने वाला अपना संदेश';

  @override
  String get eGThankYouForYourBusiness =>
      'जैसे हमारे साथ व्यापार करने के लिए धन्यवाद!';

  @override
  String get photosOnAppendixPages => 'अतिरिक्त पेजों पर फ़ोटो';

  @override
  String get statusStampPaidOverdue =>
      'स्थिति की मुहर (भुगतान हुआ / समय बीत गया)';

  @override
  String get paymentStatusInTheInvoiceHeader =>
      'इनवॉइस के ऊपर भुगतान की स्थिति';

  @override
  String get quickLookPreview => 'दस्तावेज़ की झलक';

  @override
  String get renderingHighDpi300Dpi => 'साफ़ झलक बन रही है (300 DPI)…';

  @override
  String get doubleTapToResetView => 'पहले जैसा देखने के लिए दो बार टैप करें';

  @override
  String get pinchOrDoubleTapToZoomIn =>
      'बड़ा करके देखने के लिए दो उँगलियों से फैलाएँ या दो बार टैप करें';

  @override
  String get all => 'सभी';

  @override
  String get defaultInvoiceFields => 'डिफ़ॉल्ट इनवॉइस फ़ील्ड';

  @override
  String get customFields => 'कस्टम फ़ील्ड';

  @override
  String get theseLabelsAppearOnNewInvoicesWithEmpty =>
      'नए इनवॉइस में ये नाम दिखेंगे और उनके सामने फ़ील्ड खाली रहेंगे।';

  @override
  String get label => 'फ़ील्ड का नाम';

  @override
  String get value => 'फ़ील्ड में लिखी जानकारी';

  @override
  String get removeField => 'फ़ील्ड हटाएँ';

  @override
  String get addField => 'फ़ील्ड जोड़ें';

  @override
  String get chooseInvoiceStyle => 'इनवॉइस का स्टाइल चुनें';

  @override
  String get customizeDesignTypography => 'डिज़ाइन और फ़ॉन्ट बदलें';

  @override
  String get changeFontFamilySizingScaleElementLayout =>
      'फ़ॉन्ट, आकार और लेआउट बदलें';

  @override
  String get alwaysUseThisStyleAsDefault => 'इस स्टाइल को हमेशा डिफ़ॉल्ट रखें';

  @override
  String get applySelectedStyle => 'चुना हुआ स्टाइल लागू करें';

  @override
  String get aConvertedEstimateKeepsItsStatusDeleteIts =>
      'इनवॉइस में बदले एस्टीमेट की स्थिति बदलने के लिए उसका इनवॉइस हटाएँ।';

  @override
  String convertedToInvoice(String invoiceNumber) {
    return 'इनवॉइस $invoiceNumber में बदला गया';
  }

  @override
  String get viewActionUppercase => 'देखें';

  @override
  String estimateFor(String estimateNumber, String clientName) {
    return '$clientName के लिए एस्टीमेट $estimateNumber';
  }

  @override
  String get couldNotShareTheEstimatePleaseTryAgain =>
      'एस्टीमेट शेयर नहीं हो सका। फिर कोशिश करें।';

  @override
  String get estimates => 'एस्टीमेट';

  @override
  String get quotesProposals => 'कोटेशन और प्रस्ताव';

  @override
  String get pending => 'लंबित';

  @override
  String get accepted => 'स्वीकार हुआ';

  @override
  String get estimated => 'अनुमानित';

  @override
  String get converted => 'इनवॉइस बना';

  @override
  String get declined => 'अस्वीकार हुआ';

  @override
  String get noEstimatesYet => 'अभी कोई एस्टीमेट नहीं है';

  @override
  String get noResultsFound => 'कोई नतीजा नहीं मिला';

  @override
  String get sendAPriceBeforeYouBillAcceptedQuotes =>
      'बिल बनाने से पहले कीमत भेजें। स्वीकार किए गए कोटेशन एक टैप में इनवॉइस बन जाते हैं।';

  @override
  String get tryAnotherSearchOrFilter => 'कुछ और खोजें या फ़िल्टर बदलें';

  @override
  String get createEstimate => 'एस्टीमेट बनाएँ';

  @override
  String get swipeRightToConvertHoldForMore =>
      'इनवॉइस बनाने के लिए दाएँ स्वाइप करें · और विकल्पों के लिए दबाकर रखें';

  @override
  String get viewDetails => 'जानकारी देखें';

  @override
  String get sharePdf => 'PDF शेयर करें';

  @override
  String get markAccepted => 'स्वीकार हुआ के रूप में दर्ज करें';

  @override
  String get markDeclined => 'अस्वीकार हुआ के रूप में दर्ज करें';

  @override
  String get markPending => 'लंबित के रूप में दर्ज करें';

  @override
  String get deleteEstimate => 'एस्टीमेट हटाएँ';

  @override
  String get noClient => 'कोई ग्राहक नहीं';

  @override
  String get convert => 'बदलें';

  @override
  String get share => 'शेयर करें';

  @override
  String get estimateDesignStudio => 'एस्टीमेट डिज़ाइन स्टूडियो';

  @override
  String estimateMarkedAs(String label) {
    return 'एस्टीमेट की स्थिति: $label';
  }

  @override
  String get updateStatus => 'स्थिति बदलें';

  @override
  String estimate(String estimateNumber) {
    return 'एस्टीमेट $estimateNumber';
  }

  @override
  String get waitingForClientApproval => 'ग्राहक की मंज़ूरी का इंतज़ार है';

  @override
  String get clientHasApprovedThisEstimate =>
      'ग्राहक ने यह एस्टीमेट स्वीकार किया है';

  @override
  String get estimateWasNotAccepted => 'एस्टीमेट स्वीकार नहीं हुआ';

  @override
  String valid(String date) {
    return 'मान्य: $date';
  }

  @override
  String get pleaseEnterOrSelectAClientName => 'ग्राहक का नाम डालें या चुनें';

  @override
  String get addLineItemValidation => 'कम से कम एक आइटम जोड़ें';

  @override
  String estimateNumberIsAlreadyUsedPickAnotherNumber(String value) {
    return 'एस्टीमेट नंबर $value पहले से इस्तेमाल हो रहा है। दूसरा नंबर चुनें।';
  }

  @override
  String get couldNotSaveTheEstimatePleaseTryAgain =>
      'एस्टीमेट सेव नहीं हो सका। फिर कोशिश करें।';

  @override
  String get addItemService => 'आइटम / सेवा जोड़ें';

  @override
  String get enterDescriptionQuantityRate => 'विवरण, मात्रा और दर डालें';

  @override
  String get descriptionItemName => 'विवरण / आइटम का नाम *';

  @override
  String get eGWebsiteDesignConsultationParts =>
      'जैसे वेबसाइट डिज़ाइन, सलाह, पुर्ज़े';

  @override
  String get requiredQuantity => 'मात्रा *';

  @override
  String get invalid => 'सही जानकारी डालें';

  @override
  String get requiredUnitPrice => 'प्रति यूनिट कीमत *';

  @override
  String get addToEstimate => 'एस्टीमेट में जोड़ें';

  @override
  String get editEstimate => 'एस्टीमेट बदलें';

  @override
  String get pdfTemplates => 'PDF टेम्पलेट';

  @override
  String get estimateNumber => 'एस्टीमेट नंबर *';

  @override
  String get estimateDate => 'एस्टीमेट की तारीख';

  @override
  String get validUntilExpiry => 'इस तारीख तक मान्य';

  @override
  String get noExpiry => 'कोई आखिरी तारीख नहीं';

  @override
  String get quickValidity => 'समय सीमा चुनें: ';

  @override
  String get validForSevenDays => '7 दिन';

  @override
  String get validForFourteenDays => '14 दिन';

  @override
  String get validForThirtyDays => '30 दिन';

  @override
  String get pdfTheme => 'PDF थीम';

  @override
  String get billToClient => 'बिल पाने वाला (ग्राहक) *';

  @override
  String get selectAddClient => 'ग्राहक चुनें / जोड़ें';

  @override
  String get johnDoeApexCorp => 'रवि कुमार / Apex Corp';

  @override
  String get itemsServices => 'आइटम और सेवाएँ';

  @override
  String get catalog => 'कैटलॉग';

  @override
  String get noItemsAddedYet => 'अभी कोई आइटम नहीं जोड़ा गया';

  @override
  String get subtotal => 'उप-कुल';

  @override
  String get tax => 'टैक्स';

  @override
  String get taxAmount => 'टैक्स की रकम';

  @override
  String get totalEstimated => 'कुल अनुमानित रकम';

  @override
  String get eGEstimateValidFor30DaysPayment =>
      'जैसे एस्टीमेट 30 दिनों तक मान्य है। भुगतान की शर्तें…';

  @override
  String get previewPdf => 'PDF की झलक देखें';

  @override
  String get saveEstimate => 'एस्टीमेट सेव करें';

  @override
  String get thisEstimateIsAlreadyConvertedToAnInvoice =>
      'यह एस्टीमेट पहले ही इनवॉइस में बदल चुका है।';

  @override
  String get couldNotConvertTheEstimatePleaseTryAgain =>
      'एस्टीमेट इनवॉइस में नहीं बदल सका। फिर कोशिश करें।';

  @override
  String get deleteEstimateQuestion => 'एस्टीमेट हटाएँ?';

  @override
  String get couldNotDeleteTheEstimatePleaseTryAgain =>
      'एस्टीमेट हटाया नहीं जा सका। फिर कोशिश करें।';

  @override
  String get couldNotRefreshInvoicesPullDownToTry =>
      'इनवॉइस रिफ़्रेश नहीं हो सके। फिर कोशिश करने के लिए स्क्रीन नीचे खींचें।';

  @override
  String get dueToday => 'भुगतान आज करना है';

  @override
  String get dueTomorrow => 'भुगतान कल करना है';

  @override
  String nothingIsLeftToPayOn(String invoiceNumber) {
    return '$invoiceNumber पर कोई रकम बाकी नहीं है।';
  }

  @override
  String invoiceMarkedPaid(String invoiceNumber) {
    return '$invoiceNumber पर भुगतान दर्ज हुआ';
  }

  @override
  String get undo => 'पहले जैसा करें';

  @override
  String get couldNotUndoRemoveThePaymentFromThe =>
      'भुगतान वापस नहीं हट सका। इसे इनवॉइस से हटाएँ।';

  @override
  String get payment => 'भुगतान';

  @override
  String get recordsTheBalanceAsReceivedToday =>
      'बाकी रकम को आज मिले भुगतान के रूप में दर्ज करता है';

  @override
  String get part => 'आंशिक';

  @override
  String get editInvoiceMenu => 'इनवॉइस बदलें';

  @override
  String get paymentStatus => 'भुगतान की स्थिति';

  @override
  String get savePdf => 'PDF सेव करें';

  @override
  String get deleteInvoiceMenu => 'इनवॉइस हटाएँ';

  @override
  String get swipeRightToMarkPaidHoldForMore =>
      'भुगतान दर्ज करने के लिए दाएँ स्वाइप करें · और विकल्पों के लिए दबाकर रखें';

  @override
  String get invoices => 'इनवॉइस';

  @override
  String get profileIncomplete => 'प्रोफ़ाइल अधूरी है';

  @override
  String get toCollect => 'बाकी रकम';

  @override
  String get collected => 'मिली रकम ';

  @override
  String totalsAreForInvoicesOnlyNotIncluded(
    String currencyCode,
    String excludedCurrencies,
  ) {
    return 'कुल रकम सिर्फ़ $currencyCode वाले इनवॉइस की है। इनमें शामिल नहीं हैं: $excludedCurrencies।';
  }

  @override
  String get needsYou => 'ध्यान दें';

  @override
  String get markPaid => 'भुगतान दर्ज करें';

  @override
  String get overdue => 'समय बीत गया';

  @override
  String get partiallyPaid => 'आंशिक भुगतान';

  @override
  String get nothingHere => 'यहाँ कुछ नहीं है';

  @override
  String noInvoicesMatch(String searchQuery) {
    return '“$searchQuery” से मिलता कोई इनवॉइस नहीं मिला';
  }

  @override
  String get showAll => 'सभी दिखाएँ';

  @override
  String get newStamp => 'नया';

  @override
  String get yourFirstInvoice => 'आपका पहला इनवॉइस';

  @override
  String get makeOneInUnderAMinuteTapBelow =>
      'एक मिनट से कम में बनाएँ। जब चाहें नीचे + दबाएँ।';

  @override
  String get changePaymentStatus => 'भुगतान की स्थिति बदलें';

  @override
  String get finishSettingUp => 'सेटअप पूरा करें';

  @override
  String get hide => 'छिपाएँ';

  @override
  String get pickFromCatalog => 'कैटलॉग से चुनें';

  @override
  String get newAction => 'नया';

  @override
  String get searchItemsHint => 'आइटम खोजें…';

  @override
  String plusTaxPercent(String rate) {
    return '+$rate% टैक्स';
  }

  @override
  String noItemsMatch(String searchQuery) {
    return '“$searchQuery” से मिलता कोई आइटम नहीं मिला';
  }

  @override
  String get noSavedItemsYet => 'अभी कोई आइटम सेव नहीं है';

  @override
  String get createItemsInYourCatalogToQuicklyAdd =>
      'आइटम कैटलॉग में बनाएँ, ताकि उन्हें यहाँ जल्दी जोड़ सकें';

  @override
  String get createNewItem => 'नया आइटम बनाएँ';

  @override
  String get pieces => 'पीस';

  @override
  String get hours => 'घंटे';

  @override
  String get days => 'दिन';

  @override
  String get kilograms => 'किलोग्राम';

  @override
  String get grams => 'ग्राम';

  @override
  String get litres => 'लीटर';

  @override
  String get millilitres => 'मिलीलीटर';

  @override
  String get feet => 'फ़ीट';

  @override
  String get metres => 'मीटर';

  @override
  String get sqFeet => 'वर्ग फ़ीट';

  @override
  String get sqMetres => 'वर्ग मीटर';

  @override
  String get boxes => 'डिब्बे';

  @override
  String get units => 'यूनिट';

  @override
  String get lots => 'लॉट';

  @override
  String get label0To100 => '0 से 100';

  @override
  String get newItem => 'नया आइटम';

  @override
  String get itemName => 'आइटम का नाम *';

  @override
  String get eGWebDesignConsultingTShirt => 'जैसे वेब डिज़ाइन, सलाह, टी-शर्ट';

  @override
  String get itemNameIsRequired => 'आइटम का नाम ज़रूरी है';

  @override
  String get itemDescription => 'विवरण';

  @override
  String get optionalDetailsAboutThisItemOrService =>
      'इस आइटम या सेवा की जानकारी (वैकल्पिक)';

  @override
  String get mustBe0OrMore => '0 या उससे ज़्यादा होना चाहिए';

  @override
  String get defaultQty => 'डिफ़ॉल्ट मात्रा';

  @override
  String get moreThan0 => '0 से ज़्यादा';

  @override
  String get unitOfMeasurement => 'माप की यूनिट';

  @override
  String get category => 'कैटेगरी';

  @override
  String get eGDesignDevelopmentProducts => 'जैसे डिज़ाइन, डेवलपमेंट, प्रोडक्ट';

  @override
  String get hsnSacCode => 'HSN / SAC कोड';

  @override
  String get eG998311 => 'जैसे 998311';

  @override
  String get itemDiscount => 'आइटम पर छूट';

  @override
  String get setADefaultPercentageDiscountForThisItem =>
      'इस आइटम के लिए डिफ़ॉल्ट छूट का प्रतिशत तय करें';

  @override
  String get none0 => 'कोई नहीं (0%)';

  @override
  String get taxConfiguration => 'टैक्स की सेटिंग्स';

  @override
  String get specifyWhetherTaxAppliesAndTheItemTax =>
      'तय करें कि इस आइटम पर टैक्स लगेगा या नहीं और उसकी दर क्या होगी';

  @override
  String get applyTaxToThisItem => 'इस आइटम पर टैक्स लगाएँ';

  @override
  String get eG18 => 'जैसे 18';

  @override
  String get label0Exempt => '0% (टैक्स से छूट)';

  @override
  String get estimatedItemTotal => 'आइटम की कुल अनुमानित रकम';

  @override
  String base(String rate, String amount) {
    return 'मूल रकम ($rate × $amount)';
  }

  @override
  String itemDiscountPercent(String rate) {
    return 'आइटम पर छूट ($rate%)';
  }

  @override
  String taxPercent(String rate) {
    return 'टैक्स ($rate%)';
  }

  @override
  String get netItemTotal => 'आइटम की कुल रकम:';

  @override
  String get saveItem => 'आइटम सेव करें';

  @override
  String duplicated(String value) {
    return '“$value” की कॉपी बनाई गई';
  }

  @override
  String get deleteItem => 'आइटम हटाएँ?';

  @override
  String deleteThisWonTAffectExistingInvoices(String value) {
    return '“$value” हटाएँ? मौजूदा इनवॉइस पर कोई असर नहीं पड़ेगा।';
  }

  @override
  String get productsServices => 'प्रोडक्ट और सेवाएँ';

  @override
  String get uncategorized => 'बिना कैटेगरी';

  @override
  String get tapToEditHoldForMore =>
      'बदलने के लिए टैप करें · और विकल्पों के लिए दबाकर रखें';

  @override
  String get noItemsYet => 'अभी कोई आइटम नहीं है';

  @override
  String get saveYourProductsServicesHereToQuicklyAdd =>
      'अपने प्रोडक्ट और सेवाएँ यहाँ सेव करें, ताकि उन्हें इनवॉइस में जल्दी जोड़ सकें';

  @override
  String get noItemsInThisCategory => 'इस कैटेगरी में कोई आइटम नहीं है';

  @override
  String get addYourFirstItem => 'अपना पहला आइटम जोड़ें';

  @override
  String get editItemMenu => 'आइटम बदलें';

  @override
  String get duplicate => 'कॉपी बनाएँ';

  @override
  String get deleteItemMenu => 'आइटम हटाएँ';

  @override
  String itemTaxPercent(String rate) {
    return '$rate% टैक्स';
  }

  @override
  String get taxExempt => 'टैक्स से छूट';

  @override
  String percentOff(String rate) {
    return '$rate% की छूट';
  }

  @override
  String perUnit(String value) {
    return 'प्रति $value';
  }

  @override
  String get proIsActiveThankYou => 'Pro चालू है। धन्यवाद!';

  @override
  String get noProPurchaseWasFoundForThisGoogle =>
      'इस Google खाते में Pro की खरीदारी नहीं मिली।';

  @override
  String get googlePlayPurchasesAreNotAvailableRightNow =>
      'अभी Google Play से खरीदारी नहीं हो सकती। इंटरनेट कनेक्शन जाँचकर फिर कोशिश करें।';

  @override
  String get upgrade => 'अपग्रेड';

  @override
  String get billWithoutLimits => 'जितने चाहें,\nइनवॉइस बनाएँ।';

  @override
  String get oneUpgradeUnlocksEveryInvoiceEveryClientAnd =>
      'एक अपग्रेड से जितने चाहें इनवॉइस और ग्राहक जोड़ें, और सिर्फ़ अपने ब्रांड वाले PDF बनाएँ।';

  @override
  String get whatSIncluded => 'इसमें क्या मिलेगा';

  @override
  String get unlimitedInvoicesEstimates => 'असीमित इनवॉइस और एस्टीमेट';

  @override
  String paywallMonthlyDocumentLimit(int value) {
    final intl.NumberFormat valueNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String valueString = valueNumberFormat.format(value);

    return 'मुफ़्त प्लान में हर महीने दोनों में से हर एक के $valueString बना सकते हैं।';
  }

  @override
  String get unlimitedClients => 'असीमित ग्राहक';

  @override
  String paywallSavedClientLimit(int value) {
    final intl.NumberFormat valueNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String valueString = valueNumberFormat.format(value);

    return 'मुफ़्त प्लान में $valueString तक ग्राहक सेव कर सकते हैं।';
  }

  @override
  String get noWatermark => 'बिना वॉटरमार्क';

  @override
  String get removesGeneratedByInvoiceMakerProFromYour =>
      'आपके PDF से “Generated by Invoice Maker Pro” हट जाता है।';

  @override
  String get totalHeading => 'कुल';

  @override
  String monthlyPrice(String amount) {
    return '$amount / महीना';
  }

  @override
  String get lifetime => 'आजीवन';

  @override
  String get payOnceKeepProForGood =>
      'एक बार भुगतान करें और हमेशा Pro इस्तेमाल करें';

  @override
  String get oneTime => 'एक बार';

  @override
  String get bestValue => 'सबसे किफ़ायती';

  @override
  String get monthly => 'मासिक';

  @override
  String get cancelAnyTimeInGooglePlay => 'Google Play में कभी भी रद्द करें';

  @override
  String get unlockLifetimeAccess => 'आजीवन Pro लें';

  @override
  String subscribeFor(String value) {
    return '$value में सदस्यता लें';
  }

  @override
  String get onePaymentProStaysActiveOnThisGoogle =>
      'एक बार भुगतान करने पर इस Google खाते में Pro हमेशा चालू रहेगा।';

  @override
  String get renewsEveryMonthAtThePriceAboveUntil =>
      'रद्द करने तक ऊपर दी गई कीमत पर हर महीने रिन्यू होगा। Google Play में Payments & subscriptions से कभी भी रद्द करें।';

  @override
  String get restorePurchase => 'खरीदारी बहाल करें';

  @override
  String get couldNotSaveYourDetailsPleaseTryAgain =>
      'आपकी जानकारी सेव नहीं हो सकी। फिर कोशिश करें।';

  @override
  String get skip => 'छोड़ें';

  @override
  String get getPaidBeautifully => 'पैसे पाएँ,\nआसानी से।';

  @override
  String get makeAnInvoiceInUnderAMinuteStamp =>
      'एक मिनट से कम में इनवॉइस बनाएँ। पैसे मिलते ही उस पर भुगतान की मुहर लगाएँ।';

  @override
  String get startTheTour => 'गाइड शुरू करें';

  @override
  String get getStarted => 'शुरू करें';

  @override
  String get takesAboutAMinute => 'लगभग एक मिनट लगेगा';

  @override
  String get invoiceLabel => 'इनवॉइस';

  @override
  String get billToStudioNorth => 'ग्राहक  ·  Studio North';

  @override
  String get logoDesign => 'लोगो डिज़ाइन';

  @override
  String get brandGuide => 'ब्रांड गाइड';

  @override
  String get yourBusiness => 'आपका बिज़नेस';

  @override
  String get thisSitsAtTheTopOfEveryInvoice =>
      'यह हर इनवॉइस के ऊपर दिखता है। आप इसे कभी भी बदल सकते हैं।';

  @override
  String get businessOrYourName => 'बिज़नेस का या अपना नाम';

  @override
  String get addressOptional => 'पता (वैकल्पिक)';

  @override
  String get emailOptional => 'ईमेल (वैकल्पिक)';

  @override
  String get phoneOptional => 'फ़ोन (वैकल्पिक)';

  @override
  String get continueAction => 'आगे बढ़ें';

  @override
  String get addLogo => 'लोगो जोड़ें';

  @override
  String get changeLogo => 'लोगो बदलें';

  @override
  String get logo => 'लोगो';

  @override
  String get yourBusinessPlaceholder => 'आपका बिज़नेस';

  @override
  String get emailPhone => 'ईमेल  ·  फ़ोन';

  @override
  String aGstinIs15CharactersLike(String value) {
    return 'GSTIN में 15 अक्षर और अंक होते हैं, जैसे $value।';
  }

  @override
  String get aUpiIdLooksLikeNameBank =>
      'UPI ID इस तरह की होती है, जैसे name@bank।';

  @override
  String get howYouBill => 'बिल बनाने की सेटिंग्स';

  @override
  String get newInvoicesStartWithTheseEachInvoiceCan =>
      'नए इनवॉइस में ये सेटिंग्स लागू होंगी। हर इनवॉइस के लिए इन्हें बदल सकते हैं।';

  @override
  String get currencyHeading => 'करेंसी';

  @override
  String get moreChoices => 'और…';

  @override
  String get taxHeading => 'टैक्स';

  @override
  String namedTaxHeading(String taxName) {
    return 'टैक्स · $taxName';
  }

  @override
  String get noTax => 'बिना टैक्स';

  @override
  String optionalField(String taxIdLabel) {
    return '$taxIdLabel (वैकल्पिक)';
  }

  @override
  String get paymentDue => 'भुगतान की समय सीमा';

  @override
  String get gettingPaid => 'पैसे कैसे मिलेंगे';

  @override
  String get printedOnEveryInvoiceSoClientsKnowHow =>
      'यह जानकारी हर इनवॉइस पर दिखेगी, ताकि ग्राहक आपको पैसे भेज सकें। सभी फ़ील्ड वैकल्पिक हैं।';

  @override
  String get bankTransfer => 'बैंक ट्रांसफ़र';

  @override
  String get bankNameSentenceCase => 'बैंक का नाम';

  @override
  String get skipForNow => 'अभी छोड़ें';

  @override
  String get ready => 'तैयार';

  @override
  String get youReAllSet => 'सब तैयार है।';

  @override
  String setupCompleteFor(String firstName) {
    return '$firstName,\nसब तैयार है।';
  }

  @override
  String get thatSTheTourNothingWasChanged =>
      'गाइड पूरी हुई। आपकी सेटिंग्स में कोई बदलाव नहीं हुआ।';

  @override
  String get yourFirstInvoiceIsOneTapAwayTap =>
      'अपना पहला इनवॉइस बनाएँ। नया इनवॉइस बनाने के लिए कभी भी नीचे + दबाएँ।';

  @override
  String onboardingFreePlanLimit(int value) {
    final intl.NumberFormat valueNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String valueString = valueNumberFormat.format(value);

    return 'मुफ़्त प्लान में हर महीने $valueString इनवॉइस बना सकते हैं। सेटिंग्स में कभी भी अपग्रेड करें।';
  }

  @override
  String get seeASampleWithYourDetails => 'अपनी जानकारी के साथ नमूना देखें';

  @override
  String get createMyFirstInvoice => 'अपना पहला इनवॉइस बनाएँ';

  @override
  String get backToSettings => 'सेटिंग्स पर वापस जाएँ';

  @override
  String get iLlLookAroundFirst => 'पहले ऐप देखूँगा';

  @override
  String get sampleInvoice => 'नमूना इनवॉइस';

  @override
  String get yourDetailsOnAMadeUpInvoiceNothing =>
      'यह आपकी जानकारी वाला नमूना इनवॉइस है। इसे सेव नहीं किया जाता।';

  @override
  String get couldNotLoadReportsPullDownToTry =>
      'रिपोर्ट लोड नहीं हो सकीं। फिर कोशिश करने के लिए स्क्रीन नीचे खींचें।';

  @override
  String get couldNotShareSummaryPleaseTryAgain =>
      'सारांश शेयर नहीं हो सका। फिर कोशिश करें।';

  @override
  String get shareSummary => 'सारांश शेयर करें';

  @override
  String get noReportsYet => 'अभी कोई रिपोर्ट नहीं है';

  @override
  String get nothingInThisRange => 'इन तारीखों में कोई रिकॉर्ड नहीं है';

  @override
  String get createAnInvoiceToTrackBilledRevenueCollections =>
      'बिक्री, मिली रकम, टैक्स और प्रमुख ग्राहक देखने के लिए इनवॉइस बनाएँ।';

  @override
  String noInvoicesMatchInvoicesInOtherCurrencies(
    String currencyCode,
    String label,
    String excludedCurrencies,
  ) {
    return '$label में $currencyCode का कोई इनवॉइस नहीं मिला। दूसरी करेंसी वाले इनवॉइस: $excludedCurrencies।';
  }

  @override
  String noInvoicesOrPaymentsMatchTryAnotherDate(String label) {
    return '$label में कोई इनवॉइस या भुगतान नहीं मिला। दूसरी तारीखें चुनें या रिफ़्रेश करने के लिए स्क्रीन नीचे खींचें।';
  }

  @override
  String get custom => 'अपनी तारीखें';

  @override
  String get today => 'आज';

  @override
  String get thisWeek => 'इस हफ़्ते';

  @override
  String get thisMonth => 'इस महीने';

  @override
  String get thisYear => 'इस साल';

  @override
  String get allTime => 'अब तक';

  @override
  String percentOfBilled(int value) {
    final intl.NumberFormat valueNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String valueString = valueNumberFormat.format(value);

    return 'बिल की रकम का $valueString%';
  }

  @override
  String get paymentsReceived => 'मिले भुगतान';

  @override
  String get billed => 'बिल की रकम';

  @override
  String get collectedHeading => 'मिली रकम';

  @override
  String get outstanding => 'बाकी रकम';

  @override
  String get balanceRemaining => 'बाकी बची रकम';

  @override
  String get taxCollected => 'मिला टैक्स';

  @override
  String get avgInvoice => 'औसत इनवॉइस';

  @override
  String get preparingCsvFiles => 'CSV फ़ाइलें तैयार हो रही हैं…';

  @override
  String get statusBreakdown => 'स्थिति के अनुसार';

  @override
  String get topClients => 'प्रमुख ग्राहक';

  @override
  String get topItems => 'सबसे ज़्यादा बिकने वाले आइटम';

  @override
  String get billedVsCollected => 'बिल की रकम और मिली रकम';

  @override
  String get billedLabel => 'बिल की रकम';

  @override
  String get collectedLabel => 'मिली रकम';

  @override
  String billedAmount(String value) {
    return 'बिल की रकम $value';
  }

  @override
  String collectedAmount(String value) {
    return 'मिली रकम $value';
  }

  @override
  String get tapAMonthForDetails => 'जानकारी के लिए महीने पर टैप करें';

  @override
  String get noActivityInTheseMonths => 'इन महीनों में कोई लेन-देन नहीं हुआ';

  @override
  String get updateFlowStartedFollowTheSystemPromptTo =>
      'अपडेट शुरू हो गया है। पूरा करने के लिए स्क्रीन पर दिए निर्देश मानें।';

  @override
  String get updateCancelledYouCanInstallItLaterWhen =>
      'अपडेट रद्द हुआ। दोबारा पूछे जाने पर आप इसे इंस्टॉल कर सकते हैं।';

  @override
  String get thisUpdateIsNotReadyToInstallYet =>
      'यह अपडेट अभी इंस्टॉल करने के लिए तैयार नहीं है।';

  @override
  String get inAppUpdatesAreOnlySupportedOnAndroid =>
      'ऐप के अंदर से अपडेट सिर्फ़ Android पर कर सकते हैं।';

  @override
  String get theUpdateCouldNotBeStartedPleaseTry =>
      'अपडेट शुरू नहीं हो सका। बाद में फिर कोशिश करें।';

  @override
  String get updateDownloadedRestartToFinishInstalling =>
      'अपडेट डाउनलोड हो गया। इंस्टॉलेशन पूरा करने के लिए ऐप फिर से खोलें।';

  @override
  String get restart => 'फिर से खोलें';

  @override
  String get searchInvoices => 'इनवॉइस खोजें';

  @override
  String get searchEstimates => 'एस्टीमेट खोजें';

  @override
  String get searchClients => 'ग्राहक खोजें';

  @override
  String get searchItems => 'आइटम खोजें';

  @override
  String get search => 'खोजें';

  @override
  String get closeSearch => 'खोज बंद करें';

  @override
  String get create => 'बनाएँ';

  @override
  String get createNewDocument => 'नया दस्तावेज़ बनाएँ';

  @override
  String get billAClientForWorkOrItems => 'काम या सामान का बिल बनाएँ';

  @override
  String get newEstimateQuote => 'नया एस्टीमेट / कोटेशन';

  @override
  String get sendAPriceBeforeYouBill => 'बिल बनाने से पहले कीमत भेजें';

  @override
  String get client => 'ग्राहक';

  @override
  String get item => 'आइटम';

  @override
  String newEntity(String title) {
    return 'नया $title';
  }

  @override
  String get updateAvailable => 'अपडेट उपलब्ध है';

  @override
  String get aNewerVersionOfInvoiceMakerProIs =>
      'Invoice Maker Pro का नया वर्शन उपलब्ध है। इसमें सुधार और बग फ़िक्स हैं।';

  @override
  String get later => 'बाद में';

  @override
  String get updateNow => 'अभी अपडेट करें';
}
