import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('hi'),
  ];

  /// Number of invoices
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 invoice} other{{count} invoices}}'**
  String invoiceCount(int count);

  /// Number of quotes
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 quote} other{{count} quotes}}'**
  String estimateCount(int count);

  /// Number of clients
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 client} other{{count} clients}}'**
  String clientCount(int count);

  /// Number of catalog items
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 saved item} other{{count} saved items}}'**
  String savedItemCount(int count);

  /// Number of line items in the editor
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 item added} other{{count} items added}}'**
  String addedItemCount(int count);

  /// Action to add the selected catalog items
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Add 1 Item} other{Add {count} Items}}'**
  String addSelectedItems(int count);

  /// Selection count in the catalog
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 selected} other{{count} selected}}'**
  String selectedCount(int count);

  /// Number of days
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day} other{{count} days}}'**
  String daysCount(int count);

  /// How late payment is
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day overdue} other{{count} days overdue}}'**
  String daysOverdue(int count);

  /// Days until payment is due
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Due in 1 day} other{Due in {count} days}}'**
  String dueInDays(int count);

  /// Report caption for total invoices
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Across 1 invoice} other{Across {count} invoices}}'**
  String acrossInvoices(int count);

  /// Number of overdue invoices
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 invoice overdue} other{{count} invoices overdue}}'**
  String overdueInvoices(int count);

  /// Coachmark step number
  ///
  /// In en, this message translates to:
  /// **'Step {step} of {total}'**
  String stepOfTotal(int step, int total);

  /// Attachment count and photo limit
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 of {maximum} photos} other{{count} of {maximum} photos}}'**
  String photoCount(int count, int maximum);

  /// Number of visible design templates
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 of {total} templates} other{{count} of {total} templates}}'**
  String templateCount(int count, int total);

  /// Item quantity and localized invoice count
  ///
  /// In en, this message translates to:
  /// **'Qty {quantity} · {invoices}'**
  String reportItemQuantity(String quantity, String invoices);

  /// Confirmation before all recorded payments for an invoice are removed
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{This deletes the 1 payment recorded for {invoiceNumber}.} other{This deletes the {count} payments recorded for {invoiceNumber}.}}'**
  String deleteRecordedPayments(int count, String invoiceNumber);

  /// Title of one invoice photo
  ///
  /// In en, this message translates to:
  /// **'Attachment {number}'**
  String numberedAttachment(int number);

  /// Accessibility label to open an invoice photo
  ///
  /// In en, this message translates to:
  /// **'View attachment {number}'**
  String viewNumberedAttachment(int number);

  /// Accessibility label to remove an invoice photo
  ///
  /// In en, this message translates to:
  /// **'Remove attachment {number}'**
  String removeNumberedAttachment(int number);

  /// Number of completed and total setup tasks
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} done'**
  String setupProgress(int done, int total);

  /// Number of documents in an ISO currency
  ///
  /// In en, this message translates to:
  /// **'{count} in {currency}'**
  String countInCurrency(int count, String currency);

  /// UI text: No unpaid invoices
  ///
  /// In en, this message translates to:
  /// **'No unpaid invoices'**
  String get noUnpaidInvoices;

  /// UI text: No part-paid invoices
  ///
  /// In en, this message translates to:
  /// **'No part-paid invoices'**
  String get noPartPaidInvoices;

  /// UI text: No overdue invoices
  ///
  /// In en, this message translates to:
  /// **'No overdue invoices'**
  String get noOverdueInvoices;

  /// UI text: No paid invoices
  ///
  /// In en, this message translates to:
  /// **'No paid invoices'**
  String get noPaidInvoices;

  /// UI text: Language
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// UI text: System default
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get systemDefault;

  /// UI text: English
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// UI text: हिन्दी
  ///
  /// In en, this message translates to:
  /// **'हिन्दी'**
  String get hindi;

  /// UI text: Confirm
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// UI text: Cancel
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// UI text: Delete
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// UI text: Downloads
  ///
  /// In en, this message translates to:
  /// **'Downloads'**
  String get downloads;

  /// UI text: Files › On My iPhone › Invoice Maker Pro
  ///
  /// In en, this message translates to:
  /// **'Files › On My iPhone › Invoice Maker Pro'**
  String get filesOnMyIphoneInvoiceMakerPro;

  /// UI text: Monthly invoice limit reached
  ///
  /// In en, this message translates to:
  /// **'Monthly invoice limit reached'**
  String get monthlyInvoiceLimitReached;

  /// UI text: Monthly estimate limit reached
  ///
  /// In en, this message translates to:
  /// **'Monthly estimate limit reached'**
  String get monthlyEstimateLimitReached;

  /// UI text: Saved client limit reached
  ///
  /// In en, this message translates to:
  /// **'Saved client limit reached'**
  String get savedClientLimitReached;

  /// UI text: Not now
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get notNow;

  /// UI text: See Pro
  ///
  /// In en, this message translates to:
  /// **'See Pro'**
  String get seePro;

  /// UI text: The free plan includes {count} new invoices each calendar month. You can still open, edit, share and get paid on every invoice you already have. Upgrade to Pro for unlimited invoices.
  ///
  /// In en, this message translates to:
  /// **'The free plan includes {count} new invoices each calendar month. You can still open, edit, share and get paid on every invoice you already have. Upgrade to Pro for unlimited invoices.'**
  String monthlyInvoiceLimitDetails(int count);

  /// UI text: The free plan includes {count} new estimates each calendar month. Upgrade to Pro for unlimited estimates.
  ///
  /// In en, this message translates to:
  /// **'The free plan includes {count} new estimates each calendar month. Upgrade to Pro for unlimited estimates.'**
  String monthlyEstimateLimitDetails(int count);

  /// UI text: The free plan saves up to {count} clients. You can still type any client's details straight into an invoice. Upgrade to Pro to save unlimited clients.
  ///
  /// In en, this message translates to:
  /// **'The free plan saves up to {count} clients. You can still type any client\'s details straight into an invoice. Upgrade to Pro to save unlimited clients.'**
  String savedClientLimitDetails(int count);

  /// UI text: Financial Report
  ///
  /// In en, this message translates to:
  /// **'Financial Report'**
  String get reportFinancial;

  /// UI text: Top Clients:
  ///
  /// In en, this message translates to:
  /// **'Top Clients:'**
  String get reportTopClientsHeading;

  /// UI text: Top Items:
  ///
  /// In en, this message translates to:
  /// **'Top Items:'**
  String get reportTopItemsHeading;

  /// UI text: The Play Store is not available right now. Please try again later.
  ///
  /// In en, this message translates to:
  /// **'The Play Store is not available right now. Please try again later.'**
  String get playStoreUnavailable;

  /// UI text: This plan is not available right now. Please try again later.
  ///
  /// In en, this message translates to:
  /// **'This plan is not available right now. Please try again later.'**
  String get planUnavailable;

  /// UI text: The purchase could not be started. Please try again.
  ///
  /// In en, this message translates to:
  /// **'The purchase could not be started. Please try again.'**
  String get purchaseStartFailed;

  /// UI text: Could not reach the Play Store to restore purchases.
  ///
  /// In en, this message translates to:
  /// **'Could not reach the Play Store to restore purchases.'**
  String get restorePurchasesFailed;

  /// UI text: The purchase did not go through. You have not been charged. Please check your connection and Google Play payment method, then try again.
  ///
  /// In en, this message translates to:
  /// **'The purchase did not go through. You have not been charged. Please check your connection and Google Play payment method, then try again.'**
  String get purchaseFailed;

  /// UI text: This backup was made by a newer version of the app. Update the app, then try again.
  ///
  /// In en, this message translates to:
  /// **'This backup was made by a newer version of the app. Update the app, then try again.'**
  String get backupFromNewerVersion;

  /// UI text: This backup is too old to restore.
  ///
  /// In en, this message translates to:
  /// **'This backup is too old to restore.'**
  String get backupTooOld;

  /// UI text: This backup file is damaged and can't be restored.
  ///
  /// In en, this message translates to:
  /// **'This backup file is damaged and can\'t be restored.'**
  String get backupDamaged;

  /// UI text: {business} — Financial Report
  ///
  /// In en, this message translates to:
  /// **'{business} — Financial Report'**
  String reportFinancialFor(String business);

  /// UI text: Period: {period}
  ///
  /// In en, this message translates to:
  /// **'Period: {period}'**
  String reportPeriod(String period);

  /// UI text: Billed: {amount} ({invoices})
  ///
  /// In en, this message translates to:
  /// **'Billed: {amount} ({invoices})'**
  String reportBilledAmount(String amount, String invoices);

  /// UI text: Collected: {amount}
  ///
  /// In en, this message translates to:
  /// **'Collected: {amount}'**
  String reportCollectedAmount(String amount);

  /// UI text: Outstanding: {amount}
  ///
  /// In en, this message translates to:
  /// **'Outstanding: {amount}'**
  String reportOutstandingAmount(String amount);

  /// UI text: Overdue: {amount} ({count})
  ///
  /// In en, this message translates to:
  /// **'Overdue: {amount} ({count})'**
  String reportOverdueAmount(String amount, int count);

  /// UI text: Tax: {amount}
  ///
  /// In en, this message translates to:
  /// **'Tax: {amount}'**
  String reportTaxAmount(String amount);

  /// UI text: Average Invoice: {amount}
  ///
  /// In en, this message translates to:
  /// **'Average Invoice: {amount}'**
  String reportAverageInvoice(String amount);

  /// Number of estimates in a backup
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 estimate} other{{count} estimates}}'**
  String backupEstimateCount(int count);

  /// Number of payments in a backup
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 payment} other{{count} payments}}'**
  String backupPaymentCount(int count);

  /// Number of invoice photos in a backup
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 attachment photo} other{{count} attachment photos}}'**
  String backupAttachmentCount(int count);

  /// Display label in the built-in catalog: Professional
  ///
  /// In en, this message translates to:
  /// **'Professional'**
  String get catalogProfessional;

  /// Display label in the built-in catalog: Simple
  ///
  /// In en, this message translates to:
  /// **'Simple'**
  String get catalogSimple;

  /// Display label in the built-in catalog: Bold
  ///
  /// In en, this message translates to:
  /// **'Bold'**
  String get catalogBold;

  /// Display label in the built-in catalog: Creative
  ///
  /// In en, this message translates to:
  /// **'Creative'**
  String get catalogCreative;

  /// Display label in the built-in catalog: Retail & GST
  ///
  /// In en, this message translates to:
  /// **'Retail & GST'**
  String get catalogRetailGst;

  /// Display label in the built-in catalog: Classic Corporate
  ///
  /// In en, this message translates to:
  /// **'Classic Corporate'**
  String get catalogClassicCorporate;

  /// Display label in the built-in catalog: Modern Minimal
  ///
  /// In en, this message translates to:
  /// **'Modern Minimal'**
  String get catalogModernMinimal;

  /// Display label in the built-in catalog: Emerald Executive
  ///
  /// In en, this message translates to:
  /// **'Emerald Executive'**
  String get catalogEmeraldExecutive;

  /// Display label in the built-in catalog: Slate Elegance
  ///
  /// In en, this message translates to:
  /// **'Slate Elegance'**
  String get catalogSlateElegance;

  /// Display label in the built-in catalog: Warm Corporate
  ///
  /// In en, this message translates to:
  /// **'Warm Corporate'**
  String get catalogWarmCorporate;

  /// Display label in the built-in catalog: Nordic Frame
  ///
  /// In en, this message translates to:
  /// **'Nordic Frame'**
  String get catalogNordicFrame;

  /// Display label in the built-in catalog: Left Accent Ribbon
  ///
  /// In en, this message translates to:
  /// **'Left Accent Ribbon'**
  String get catalogLeftAccentRibbon;

  /// Display label in the built-in catalog: Geometric Banner
  ///
  /// In en, this message translates to:
  /// **'Geometric Banner'**
  String get catalogGeometricBanner;

  /// Display label in the built-in catalog: Security Grid
  ///
  /// In en, this message translates to:
  /// **'Security Grid'**
  String get catalogSecurityGrid;

  /// Display label in the built-in catalog: Two-Tone Split
  ///
  /// In en, this message translates to:
  /// **'Two-Tone Split'**
  String get catalogTwoToneSplit;

  /// Display label in the built-in catalog: Charcoal Letterhead
  ///
  /// In en, this message translates to:
  /// **'Charcoal Letterhead'**
  String get catalogCharcoalLetterhead;

  /// Display label in the built-in catalog: Navy Letterhead
  ///
  /// In en, this message translates to:
  /// **'Navy Letterhead'**
  String get catalogNavyLetterhead;

  /// Display label in the built-in catalog: Forest Seal
  ///
  /// In en, this message translates to:
  /// **'Forest Seal'**
  String get catalogForestSeal;

  /// Display label in the built-in catalog: Linen Rule
  ///
  /// In en, this message translates to:
  /// **'Linen Rule'**
  String get catalogLinenRule;

  /// Display label in the built-in catalog: Mist Line
  ///
  /// In en, this message translates to:
  /// **'Mist Line'**
  String get catalogMistLine;

  /// Display label in the built-in catalog: Olive Frame
  ///
  /// In en, this message translates to:
  /// **'Olive Frame'**
  String get catalogOliveFrame;

  /// Display label in the built-in catalog: Crimson Slash
  ///
  /// In en, this message translates to:
  /// **'Crimson Slash'**
  String get catalogCrimsonSlash;

  /// Display label in the built-in catalog: Indigo Slash
  ///
  /// In en, this message translates to:
  /// **'Indigo Slash'**
  String get catalogIndigoSlash;

  /// Display label in the built-in catalog: Copper Banner
  ///
  /// In en, this message translates to:
  /// **'Copper Banner'**
  String get catalogCopperBanner;

  /// Display label in the built-in catalog: Teal Wave
  ///
  /// In en, this message translates to:
  /// **'Teal Wave'**
  String get catalogTealWave;

  /// Display label in the built-in catalog: Orchid Wave
  ///
  /// In en, this message translates to:
  /// **'Orchid Wave'**
  String get catalogOrchidWave;

  /// Display label in the built-in catalog: Clay Ribbon
  ///
  /// In en, this message translates to:
  /// **'Clay Ribbon'**
  String get catalogClayRibbon;

  /// Display label in the built-in catalog: Mulberry Split
  ///
  /// In en, this message translates to:
  /// **'Mulberry Split'**
  String get catalogMulberrySplit;

  /// Display label in the built-in catalog: Saffron Ledger
  ///
  /// In en, this message translates to:
  /// **'Saffron Ledger'**
  String get catalogSaffronLedger;

  /// Display label in the built-in catalog: Peacock Ledger
  ///
  /// In en, this message translates to:
  /// **'Peacock Ledger'**
  String get catalogPeacockLedger;

  /// Display label in the built-in catalog: Graphite Receipt
  ///
  /// In en, this message translates to:
  /// **'Graphite Receipt'**
  String get catalogGraphiteReceipt;

  /// Display label in the built-in catalog: Rose Receipt
  ///
  /// In en, this message translates to:
  /// **'Rose Receipt'**
  String get catalogRoseReceipt;

  /// Display label in the built-in catalog: Oxblood Seal
  ///
  /// In en, this message translates to:
  /// **'Oxblood Seal'**
  String get catalogOxbloodSeal;

  /// Display label in the built-in catalog: Clean Sans
  ///
  /// In en, this message translates to:
  /// **'Clean Sans'**
  String get catalogCleanSans;

  /// Display label in the built-in catalog: Editorial Serif
  ///
  /// In en, this message translates to:
  /// **'Editorial Serif'**
  String get catalogEditorialSerif;

  /// Display label in the built-in catalog: Geometric
  ///
  /// In en, this message translates to:
  /// **'Geometric'**
  String get catalogGeometric;

  /// Display label in the built-in catalog: Tech Mono
  ///
  /// In en, this message translates to:
  /// **'Tech Mono'**
  String get catalogTechMono;

  /// Display label in the built-in catalog: Modern, clear & highly legible (Inter / Noto)
  ///
  /// In en, this message translates to:
  /// **'Modern, clear & highly legible (Inter / Noto)'**
  String get catalogModernClearHighlyLegibleInterNoto;

  /// Display label in the built-in catalog: Formal, premium & classic (Lora / Merriweather)
  ///
  /// In en, this message translates to:
  /// **'Formal, premium & classic (Lora / Merriweather)'**
  String get catalogFormalPremiumClassicLoraMerriweather;

  /// Display label in the built-in catalog: Sharp, sleek & contemporary (Montserrat / Poppins)
  ///
  /// In en, this message translates to:
  /// **'Sharp, sleek & contemporary (Montserrat / Poppins)'**
  String get catalogSharpSleekContemporaryMontserratPoppins;

  /// Display label in the built-in catalog: Technical, precise & balanced (Space Mono)
  ///
  /// In en, this message translates to:
  /// **'Technical, precise & balanced (Space Mono)'**
  String get catalogTechnicalPreciseBalancedSpaceMono;

  /// Display label in the built-in catalog: Compact
  ///
  /// In en, this message translates to:
  /// **'Compact'**
  String get catalogCompact;

  /// Display label in the built-in catalog: Regular
  ///
  /// In en, this message translates to:
  /// **'Regular'**
  String get catalogRegular;

  /// Display label in the built-in catalog: Spacious
  ///
  /// In en, this message translates to:
  /// **'Spacious'**
  String get catalogSpacious;

  /// Display label in the built-in catalog: Left Logo
  ///
  /// In en, this message translates to:
  /// **'Left Logo'**
  String get catalogLeftLogo;

  /// Display label in the built-in catalog: Right Logo
  ///
  /// In en, this message translates to:
  /// **'Right Logo'**
  String get catalogRightLogo;

  /// Display label in the built-in catalog: Centered
  ///
  /// In en, this message translates to:
  /// **'Centered'**
  String get catalogCentered;

  /// Display label in the built-in catalog: Banner
  ///
  /// In en, this message translates to:
  /// **'Banner'**
  String get catalogBanner;

  /// Display label in the built-in catalog: Business & logo on left, invoice details on right
  ///
  /// In en, this message translates to:
  /// **'Business & logo on left, invoice details on right'**
  String get catalogBusinessLogoOnLeftInvoiceDetailsOnRight;

  /// Display label in the built-in catalog: Invoice title & meta on left, logo on right
  ///
  /// In en, this message translates to:
  /// **'Invoice title & meta on left, logo on right'**
  String get catalogInvoiceTitleMetaOnLeftLogoOnRight;

  /// Display label in the built-in catalog: Centered branding with balanced metadata pills
  ///
  /// In en, this message translates to:
  /// **'Centered branding with balanced metadata pills'**
  String get catalogCenteredBrandingWithBalancedMetadataPills;

  /// Display label in the built-in catalog: Full-width solid color accent header
  ///
  /// In en, this message translates to:
  /// **'Full-width solid color accent header'**
  String get catalogFullWidthSolidColorAccentHeader;

  /// Display label in the built-in catalog: Side by Side
  ///
  /// In en, this message translates to:
  /// **'Side by Side'**
  String get catalogSideBySide;

  /// Display label in the built-in catalog: Inverted
  ///
  /// In en, this message translates to:
  /// **'Inverted'**
  String get catalogInverted;

  /// Display label in the built-in catalog: Stacked
  ///
  /// In en, this message translates to:
  /// **'Stacked'**
  String get catalogStacked;

  /// Display label in the built-in catalog: From (Business) on left · Bill To (Client) on right
  ///
  /// In en, this message translates to:
  /// **'From (Business) on left · Bill To (Client) on right'**
  String get catalogFromBusinessOnLeftBillToClientOnRight;

  /// Display label in the built-in catalog: Bill To (Client) on left · From (Business) on right
  ///
  /// In en, this message translates to:
  /// **'Bill To (Client) on left · From (Business) on right'**
  String get catalogBillToClientOnLeftFromBusinessOnRight;

  /// Display label in the built-in catalog: Full-width From card above Bill To card
  ///
  /// In en, this message translates to:
  /// **'Full-width From card above Bill To card'**
  String get catalogFullWidthFromCardAboveBillToCard;

  /// Display label in the built-in catalog: Royal Blue
  ///
  /// In en, this message translates to:
  /// **'Royal Blue'**
  String get catalogRoyalBlue;

  /// Display label in the built-in catalog: Emerald Forest
  ///
  /// In en, this message translates to:
  /// **'Emerald Forest'**
  String get catalogEmeraldForest;

  /// Display label in the built-in catalog: Slate Graphite
  ///
  /// In en, this message translates to:
  /// **'Slate Graphite'**
  String get catalogSlateGraphite;

  /// Display label in the built-in catalog: Obsidian Black
  ///
  /// In en, this message translates to:
  /// **'Obsidian Black'**
  String get catalogObsidianBlack;

  /// Display label in the built-in catalog: Warm Amber
  ///
  /// In en, this message translates to:
  /// **'Warm Amber'**
  String get catalogWarmAmber;

  /// Display label in the built-in catalog: Nordic Teal
  ///
  /// In en, this message translates to:
  /// **'Nordic Teal'**
  String get catalogNordicTeal;

  /// Display label in the built-in catalog: Indigo Violet
  ///
  /// In en, this message translates to:
  /// **'Indigo Violet'**
  String get catalogIndigoViolet;

  /// Display label in the built-in catalog: Crimson Executive
  ///
  /// In en, this message translates to:
  /// **'Crimson Executive'**
  String get catalogCrimsonExecutive;

  /// Display label in the built-in catalog: SENT
  ///
  /// In en, this message translates to:
  /// **'SENT'**
  String get catalogSent;

  /// Display label in the built-in catalog: ACCEPTED
  ///
  /// In en, this message translates to:
  /// **'ACCEPTED'**
  String get catalogAccepted;

  /// Display label in the built-in catalog: DECLINED
  ///
  /// In en, this message translates to:
  /// **'DECLINED'**
  String get catalogDeclined;

  /// Display label in the built-in catalog: INVOICED
  ///
  /// In en, this message translates to:
  /// **'INVOICED'**
  String get catalogInvoiced;

  /// Display label in the built-in catalog: Net 15
  ///
  /// In en, this message translates to:
  /// **'Net 15'**
  String get catalogNet15;

  /// Display label in the built-in catalog: Net 30
  ///
  /// In en, this message translates to:
  /// **'Net 30'**
  String get catalogNet30;

  /// Display label in the built-in catalog: Net 60
  ///
  /// In en, this message translates to:
  /// **'Net 60'**
  String get catalogNet60;

  /// Display label in the built-in catalog: US Dollar
  ///
  /// In en, this message translates to:
  /// **'US Dollar'**
  String get catalogUsDollar;

  /// Display label in the built-in catalog: Indian Rupee
  ///
  /// In en, this message translates to:
  /// **'Indian Rupee'**
  String get catalogIndianRupee;

  /// Display label in the built-in catalog: British Pound
  ///
  /// In en, this message translates to:
  /// **'British Pound'**
  String get catalogBritishPound;

  /// Display label in the built-in catalog: Euro
  ///
  /// In en, this message translates to:
  /// **'Euro'**
  String get catalogEuro;

  /// Display label in the built-in catalog: Canadian Dollar
  ///
  /// In en, this message translates to:
  /// **'Canadian Dollar'**
  String get catalogCanadianDollar;

  /// Display label in the built-in catalog: Australian Dollar
  ///
  /// In en, this message translates to:
  /// **'Australian Dollar'**
  String get catalogAustralianDollar;

  /// Display label in the built-in catalog: UAE Dirham
  ///
  /// In en, this message translates to:
  /// **'UAE Dirham'**
  String get catalogUaeDirham;

  /// Display label in the built-in catalog: Saudi Riyal
  ///
  /// In en, this message translates to:
  /// **'Saudi Riyal'**
  String get catalogSaudiRiyal;

  /// Display label in the built-in catalog: Singapore Dollar
  ///
  /// In en, this message translates to:
  /// **'Singapore Dollar'**
  String get catalogSingaporeDollar;

  /// Display label in the built-in catalog: Japanese Yen
  ///
  /// In en, this message translates to:
  /// **'Japanese Yen'**
  String get catalogJapaneseYen;

  /// Display label in the built-in catalog: New Zealand Dollar
  ///
  /// In en, this message translates to:
  /// **'New Zealand Dollar'**
  String get catalogNewZealandDollar;

  /// Display label in the built-in catalog: Swiss Franc
  ///
  /// In en, this message translates to:
  /// **'Swiss Franc'**
  String get catalogSwissFranc;

  /// Display label in the built-in catalog: Malaysian Ringgit
  ///
  /// In en, this message translates to:
  /// **'Malaysian Ringgit'**
  String get catalogMalaysianRinggit;

  /// Display label in the built-in catalog: South African Rand
  ///
  /// In en, this message translates to:
  /// **'South African Rand'**
  String get catalogSouthAfricanRand;

  /// Display label in the built-in catalog: Mexican Peso
  ///
  /// In en, this message translates to:
  /// **'Mexican Peso'**
  String get catalogMexicanPeso;

  /// Display label in the built-in catalog: Brazilian Real
  ///
  /// In en, this message translates to:
  /// **'Brazilian Real'**
  String get catalogBrazilianReal;

  /// Display label in the built-in catalog: Hong Kong Dollar
  ///
  /// In en, this message translates to:
  /// **'Hong Kong Dollar'**
  String get catalogHongKongDollar;

  /// Display label in the built-in catalog: Thai Baht
  ///
  /// In en, this message translates to:
  /// **'Thai Baht'**
  String get catalogThaiBaht;

  /// Display label in the built-in catalog: Philippine Peso
  ///
  /// In en, this message translates to:
  /// **'Philippine Peso'**
  String get catalogPhilippinePeso;

  /// Display label in the built-in catalog: Indonesian Rupiah
  ///
  /// In en, this message translates to:
  /// **'Indonesian Rupiah'**
  String get catalogIndonesianRupiah;

  /// Display label in the built-in catalog: Vietnamese Dong
  ///
  /// In en, this message translates to:
  /// **'Vietnamese Dong'**
  String get catalogVietnameseDong;

  /// Display label in the built-in catalog: South Korean Won
  ///
  /// In en, this message translates to:
  /// **'South Korean Won'**
  String get catalogSouthKoreanWon;

  /// Display label in the built-in catalog: Chinese Yuan
  ///
  /// In en, this message translates to:
  /// **'Chinese Yuan'**
  String get catalogChineseYuan;

  /// Display label in the built-in catalog: Nigerian Naira
  ///
  /// In en, this message translates to:
  /// **'Nigerian Naira'**
  String get catalogNigerianNaira;

  /// Display label in the built-in catalog: Kenyan Shilling
  ///
  /// In en, this message translates to:
  /// **'Kenyan Shilling'**
  String get catalogKenyanShilling;

  /// Display label in the built-in catalog: Pakistani Rupee
  ///
  /// In en, this message translates to:
  /// **'Pakistani Rupee'**
  String get catalogPakistaniRupee;

  /// Display label in the built-in catalog: Bangladeshi Taka
  ///
  /// In en, this message translates to:
  /// **'Bangladeshi Taka'**
  String get catalogBangladeshiTaka;

  /// Display label in the built-in catalog: Polish Zloty
  ///
  /// In en, this message translates to:
  /// **'Polish Zloty'**
  String get catalogPolishZloty;

  /// Display label in the built-in catalog: Swedish Krona
  ///
  /// In en, this message translates to:
  /// **'Swedish Krona'**
  String get catalogSwedishKrona;

  /// Display label in the built-in catalog: Norwegian Krone
  ///
  /// In en, this message translates to:
  /// **'Norwegian Krone'**
  String get catalogNorwegianKrone;

  /// Display label in the built-in catalog: Danish Krone
  ///
  /// In en, this message translates to:
  /// **'Danish Krone'**
  String get catalogDanishKrone;

  /// Display label in the built-in catalog: Qatari Riyal
  ///
  /// In en, this message translates to:
  /// **'Qatari Riyal'**
  String get catalogQatariRiyal;

  /// Display label in the built-in catalog: Kuwaiti Dinar
  ///
  /// In en, this message translates to:
  /// **'Kuwaiti Dinar'**
  String get catalogKuwaitiDinar;

  /// Display label in the built-in catalog: Bahraini Dinar
  ///
  /// In en, this message translates to:
  /// **'Bahraini Dinar'**
  String get catalogBahrainiDinar;

  /// Display label in the built-in catalog: Taiwan Dollar
  ///
  /// In en, this message translates to:
  /// **'Taiwan Dollar'**
  String get catalogTaiwanDollar;

  /// Display label in the built-in catalog: United States
  ///
  /// In en, this message translates to:
  /// **'United States'**
  String get catalogUnitedStates;

  /// Display label in the built-in catalog: India
  ///
  /// In en, this message translates to:
  /// **'India'**
  String get catalogIndia;

  /// Display label in the built-in catalog: United Kingdom
  ///
  /// In en, this message translates to:
  /// **'United Kingdom'**
  String get catalogUnitedKingdom;

  /// Display label in the built-in catalog: European Union
  ///
  /// In en, this message translates to:
  /// **'European Union'**
  String get catalogEuropeanUnion;

  /// Display label in the built-in catalog: Canada
  ///
  /// In en, this message translates to:
  /// **'Canada'**
  String get catalogCanada;

  /// Display label in the built-in catalog: Australia
  ///
  /// In en, this message translates to:
  /// **'Australia'**
  String get catalogAustralia;

  /// Display label in the built-in catalog: United Arab Emirates
  ///
  /// In en, this message translates to:
  /// **'United Arab Emirates'**
  String get catalogUnitedArabEmirates;

  /// Display label in the built-in catalog: Saudi Arabia
  ///
  /// In en, this message translates to:
  /// **'Saudi Arabia'**
  String get catalogSaudiArabia;

  /// Display label in the built-in catalog: Singapore
  ///
  /// In en, this message translates to:
  /// **'Singapore'**
  String get catalogSingapore;

  /// Display label in the built-in catalog: Japan
  ///
  /// In en, this message translates to:
  /// **'Japan'**
  String get catalogJapan;

  /// Display label in the built-in catalog: New Zealand
  ///
  /// In en, this message translates to:
  /// **'New Zealand'**
  String get catalogNewZealand;

  /// Display label in the built-in catalog: Switzerland
  ///
  /// In en, this message translates to:
  /// **'Switzerland'**
  String get catalogSwitzerland;

  /// Display label in the built-in catalog: Malaysia
  ///
  /// In en, this message translates to:
  /// **'Malaysia'**
  String get catalogMalaysia;

  /// Display label in the built-in catalog: South Africa
  ///
  /// In en, this message translates to:
  /// **'South Africa'**
  String get catalogSouthAfrica;

  /// Display label in the built-in catalog: Mexico
  ///
  /// In en, this message translates to:
  /// **'Mexico'**
  String get catalogMexico;

  /// Display label in the built-in catalog: Brazil
  ///
  /// In en, this message translates to:
  /// **'Brazil'**
  String get catalogBrazil;

  /// Display label in the built-in catalog: Hong Kong
  ///
  /// In en, this message translates to:
  /// **'Hong Kong'**
  String get catalogHongKong;

  /// Display label in the built-in catalog: Thailand
  ///
  /// In en, this message translates to:
  /// **'Thailand'**
  String get catalogThailand;

  /// Display label in the built-in catalog: Philippines
  ///
  /// In en, this message translates to:
  /// **'Philippines'**
  String get catalogPhilippines;

  /// Display label in the built-in catalog: Indonesia
  ///
  /// In en, this message translates to:
  /// **'Indonesia'**
  String get catalogIndonesia;

  /// Display label in the built-in catalog: Vietnam
  ///
  /// In en, this message translates to:
  /// **'Vietnam'**
  String get catalogVietnam;

  /// Display label in the built-in catalog: South Korea
  ///
  /// In en, this message translates to:
  /// **'South Korea'**
  String get catalogSouthKorea;

  /// Display label in the built-in catalog: China
  ///
  /// In en, this message translates to:
  /// **'China'**
  String get catalogChina;

  /// Display label in the built-in catalog: Nigeria
  ///
  /// In en, this message translates to:
  /// **'Nigeria'**
  String get catalogNigeria;

  /// Display label in the built-in catalog: Kenya
  ///
  /// In en, this message translates to:
  /// **'Kenya'**
  String get catalogKenya;

  /// Display label in the built-in catalog: Pakistan
  ///
  /// In en, this message translates to:
  /// **'Pakistan'**
  String get catalogPakistan;

  /// Display label in the built-in catalog: Bangladesh
  ///
  /// In en, this message translates to:
  /// **'Bangladesh'**
  String get catalogBangladesh;

  /// Display label in the built-in catalog: Poland
  ///
  /// In en, this message translates to:
  /// **'Poland'**
  String get catalogPoland;

  /// Display label in the built-in catalog: Sweden
  ///
  /// In en, this message translates to:
  /// **'Sweden'**
  String get catalogSweden;

  /// Display label in the built-in catalog: Norway
  ///
  /// In en, this message translates to:
  /// **'Norway'**
  String get catalogNorway;

  /// Display label in the built-in catalog: Denmark
  ///
  /// In en, this message translates to:
  /// **'Denmark'**
  String get catalogDenmark;

  /// Display label in the built-in catalog: Qatar
  ///
  /// In en, this message translates to:
  /// **'Qatar'**
  String get catalogQatar;

  /// Display label in the built-in catalog: Kuwait
  ///
  /// In en, this message translates to:
  /// **'Kuwait'**
  String get catalogKuwait;

  /// Display label in the built-in catalog: Bahrain
  ///
  /// In en, this message translates to:
  /// **'Bahrain'**
  String get catalogBahrain;

  /// Display label in the built-in catalog: Taiwan
  ///
  /// In en, this message translates to:
  /// **'Taiwan'**
  String get catalogTaiwan;

  /// Display label in the built-in catalog: Sales Tax
  ///
  /// In en, this message translates to:
  /// **'Sales Tax'**
  String get catalogSalesTax;

  /// Display label in the built-in catalog: Goods and Services Tax
  ///
  /// In en, this message translates to:
  /// **'Goods and Services Tax'**
  String get catalogGoodsAndServicesTax;

  /// Display label in the built-in catalog: Value Added Tax
  ///
  /// In en, this message translates to:
  /// **'Value Added Tax'**
  String get catalogValueAddedTax;

  /// Display label in the built-in catalog: Consumption Tax
  ///
  /// In en, this message translates to:
  /// **'Consumption Tax'**
  String get catalogConsumptionTax;

  /// Display label in the built-in catalog: Sales and Services Tax
  ///
  /// In en, this message translates to:
  /// **'Sales and Services Tax'**
  String get catalogSalesAndServicesTax;

  /// Display label in the built-in catalog: Impuesto al Valor Agregado
  ///
  /// In en, this message translates to:
  /// **'Impuesto al Valor Agregado'**
  String get catalogImpuestoAlValorAgregado;

  /// Display label in the built-in catalog: Impostos (ICMS / ISS)
  ///
  /// In en, this message translates to:
  /// **'Impostos (ICMS / ISS)'**
  String get catalogImpostosIcmsIss;

  /// Display label in the built-in catalog: No General Sales Tax
  ///
  /// In en, this message translates to:
  /// **'No General Sales Tax'**
  String get catalogNoGeneralSalesTax;

  /// Display label in the built-in catalog: Pajak Pertambahan Nilai
  ///
  /// In en, this message translates to:
  /// **'Pajak Pertambahan Nilai'**
  String get catalogPajakPertambahanNilai;

  /// Display label in the built-in catalog: Value Added Tax (Mushak)
  ///
  /// In en, this message translates to:
  /// **'Value Added Tax (Mushak)'**
  String get catalogValueAddedTaxMushak;

  /// Display label in the built-in catalog: Podatek od Towarów i Usług
  ///
  /// In en, this message translates to:
  /// **'Podatek od Towarów i Usług'**
  String get catalogPodatekOdTowarWIUsUg;

  /// Display label in the built-in catalog: Mervärdesskatt (Moms)
  ///
  /// In en, this message translates to:
  /// **'Mervärdesskatt (Moms)'**
  String get catalogMervRdesskattMoms;

  /// Display label in the built-in catalog: Merverdiavgift (MVA)
  ///
  /// In en, this message translates to:
  /// **'Merverdiavgift (MVA)'**
  String get catalogMerverdiavgiftMva;

  /// Display label in the built-in catalog: Merværdiafgift (Moms)
  ///
  /// In en, this message translates to:
  /// **'Merværdiafgift (Moms)'**
  String get catalogMervRdiafgiftMoms;

  /// Display label in the built-in catalog: Tax Free
  ///
  /// In en, this message translates to:
  /// **'Tax Free'**
  String get catalogTaxFree;

  /// Display label in the built-in catalog: Tax ID / EIN
  ///
  /// In en, this message translates to:
  /// **'Tax ID / EIN'**
  String get catalogTaxIdEin;

  /// Display label in the built-in catalog: VAT Reg No.
  ///
  /// In en, this message translates to:
  /// **'VAT Reg No.'**
  String get catalogVatRegNo;

  /// Display label in the built-in catalog: Business Number (BN)
  ///
  /// In en, this message translates to:
  /// **'Business Number (BN)'**
  String get catalogBusinessNumberBn;

  /// Display label in the built-in catalog: ABN (Business No.)
  ///
  /// In en, this message translates to:
  /// **'ABN (Business No.)'**
  String get catalogAbnBusinessNo;

  /// Display label in the built-in catalog: TRN (Tax Reg No.)
  ///
  /// In en, this message translates to:
  /// **'TRN (Tax Reg No.)'**
  String get catalogTrnTaxRegNo;

  /// Display label in the built-in catalog: VAT Reg No. / TRN
  ///
  /// In en, this message translates to:
  /// **'VAT Reg No. / TRN'**
  String get catalogVatRegNoTrn;

  /// Display label in the built-in catalog: UEN / GST Reg No.
  ///
  /// In en, this message translates to:
  /// **'UEN / GST Reg No.'**
  String get catalogUenGstRegNo;

  /// Display label in the built-in catalog: Invoice Reg No.
  ///
  /// In en, this message translates to:
  /// **'Invoice Reg No.'**
  String get catalogInvoiceRegNo;

  /// Display label in the built-in catalog: GST / IRD Number
  ///
  /// In en, this message translates to:
  /// **'GST / IRD Number'**
  String get catalogGstIrdNumber;

  /// Display label in the built-in catalog: SST Reg No.
  ///
  /// In en, this message translates to:
  /// **'SST Reg No.'**
  String get catalogSstRegNo;

  /// Display label in the built-in catalog: VAT Number
  ///
  /// In en, this message translates to:
  /// **'VAT Number'**
  String get catalogVatNumber;

  /// Display label in the built-in catalog: RFC (Tax ID)
  ///
  /// In en, this message translates to:
  /// **'RFC (Tax ID)'**
  String get catalogRfcTaxId;

  /// Display label in the built-in catalog: CNPJ (Company ID)
  ///
  /// In en, this message translates to:
  /// **'CNPJ (Company ID)'**
  String get catalogCnpjCompanyId;

  /// Display label in the built-in catalog: Business Reg No. (BRN)
  ///
  /// In en, this message translates to:
  /// **'Business Reg No. (BRN)'**
  String get catalogBusinessRegNoBrn;

  /// Display label in the built-in catalog: Tax ID (13 digits)
  ///
  /// In en, this message translates to:
  /// **'Tax ID (13 digits)'**
  String get catalogTaxId13Digits;

  /// Display label in the built-in catalog: TIN (Tax ID No.)
  ///
  /// In en, this message translates to:
  /// **'TIN (Tax ID No.)'**
  String get catalogTinTaxIdNo;

  /// Display label in the built-in catalog: NPWP (Tax ID)
  ///
  /// In en, this message translates to:
  /// **'NPWP (Tax ID)'**
  String get catalogNpwpTaxId;

  /// Display label in the built-in catalog: Mã số thuế (Tax Code)
  ///
  /// In en, this message translates to:
  /// **'Mã số thuế (Tax Code)'**
  String get catalogMSThuTaxCode;

  /// Display label in the built-in catalog: Unified Social Credit Code
  ///
  /// In en, this message translates to:
  /// **'Unified Social Credit Code'**
  String get catalogUnifiedSocialCreditCode;

  /// Display label in the built-in catalog: BIN / VAT Reg No.
  ///
  /// In en, this message translates to:
  /// **'BIN / VAT Reg No.'**
  String get catalogBinVatRegNo;

  /// Display label in the built-in catalog: NIP (Tax ID)
  ///
  /// In en, this message translates to:
  /// **'NIP (Tax ID)'**
  String get catalogNipTaxId;

  /// Display label in the built-in catalog: Tax Card / TIN
  ///
  /// In en, this message translates to:
  /// **'Tax Card / TIN'**
  String get catalogTaxCardTin;

  /// Display label in the built-in catalog: Civil / Commercial Reg No.
  ///
  /// In en, this message translates to:
  /// **'Civil / Commercial Reg No.'**
  String get catalogCivilCommercialRegNo;

  /// Display label in the built-in catalog: VAT Account No.
  ///
  /// In en, this message translates to:
  /// **'VAT Account No.'**
  String get catalogVatAccountNo;

  /// Display label in the built-in catalog: Unified Business No. (UBN)
  ///
  /// In en, this message translates to:
  /// **'Unified Business No. (UBN)'**
  String get catalogUnifiedBusinessNoUbn;

  /// Display label in the built-in catalog: Account Number
  ///
  /// In en, this message translates to:
  /// **'Account Number'**
  String get catalogAccountNumber;

  /// Display label in the built-in catalog: Número de Cuenta
  ///
  /// In en, this message translates to:
  /// **'Número de Cuenta'**
  String get catalogNMeroDeCuenta;

  /// Display label in the built-in catalog: Conta Corrente
  ///
  /// In en, this message translates to:
  /// **'Conta Corrente'**
  String get catalogContaCorrente;

  /// Display label in the built-in catalog: Nomor Rekening
  ///
  /// In en, this message translates to:
  /// **'Nomor Rekening'**
  String get catalogNomorRekening;

  /// Display label in the built-in catalog: Số tài khoản
  ///
  /// In en, this message translates to:
  /// **'Số tài khoản'**
  String get catalogSTIKhoN;

  /// Display label in the built-in catalog: Account Number (NUBAN)
  ///
  /// In en, this message translates to:
  /// **'Account Number (NUBAN)'**
  String get catalogAccountNumberNuban;

  /// Display label in the built-in catalog: Account Number (IBAN)
  ///
  /// In en, this message translates to:
  /// **'Account Number (IBAN)'**
  String get catalogAccountNumberIban;

  /// Display label in the built-in catalog: Numer Konta (IBAN)
  ///
  /// In en, this message translates to:
  /// **'Numer Konta (IBAN)'**
  String get catalogNumerKontaIban;

  /// Display label in the built-in catalog: Kontonummer
  ///
  /// In en, this message translates to:
  /// **'Kontonummer'**
  String get catalogKontonummer;

  /// Display label in the built-in catalog: Routing / IFSC Code
  ///
  /// In en, this message translates to:
  /// **'Routing / IFSC Code'**
  String get catalogRoutingIfscCode;

  /// Display label in the built-in catalog: Routing Number (ABA)
  ///
  /// In en, this message translates to:
  /// **'Routing Number (ABA)'**
  String get catalogRoutingNumberAba;

  /// Display label in the built-in catalog: IFSC Code
  ///
  /// In en, this message translates to:
  /// **'IFSC Code'**
  String get catalogIfscCode;

  /// Display label in the built-in catalog: Sort Code
  ///
  /// In en, this message translates to:
  /// **'Sort Code'**
  String get catalogSortCode;

  /// Display label in the built-in catalog: BIC / SWIFT Code
  ///
  /// In en, this message translates to:
  /// **'BIC / SWIFT Code'**
  String get catalogBicSwiftCode;

  /// Display label in the built-in catalog: Transit & Institution No.
  ///
  /// In en, this message translates to:
  /// **'Transit & Institution No.'**
  String get catalogTransitInstitutionNo;

  /// Display label in the built-in catalog: BSB Code
  ///
  /// In en, this message translates to:
  /// **'BSB Code'**
  String get catalogBsbCode;

  /// Display label in the built-in catalog: Bank & Branch Code
  ///
  /// In en, this message translates to:
  /// **'Bank & Branch Code'**
  String get catalogBankBranchCode;

  /// Display label in the built-in catalog: Branch Code & Name
  ///
  /// In en, this message translates to:
  /// **'Branch Code & Name'**
  String get catalogBranchCodeName;

  /// Display label in the built-in catalog: Bank Code / SWIFT
  ///
  /// In en, this message translates to:
  /// **'Bank Code / SWIFT'**
  String get catalogBankCodeSwift;

  /// Display label in the built-in catalog: Branch Code
  ///
  /// In en, this message translates to:
  /// **'Branch Code'**
  String get catalogBranchCode;

  /// Display label in the built-in catalog: CLABE (18 digits)
  ///
  /// In en, this message translates to:
  /// **'CLABE (18 digits)'**
  String get catalogClabe18Digits;

  /// Display label in the built-in catalog: Agência & Código do Banco
  ///
  /// In en, this message translates to:
  /// **'Agência & Código do Banco'**
  String get catalogAgNciaCDigoDoBanco;

  /// Display label in the built-in catalog: Bank Code & Branch
  ///
  /// In en, this message translates to:
  /// **'Bank Code & Branch'**
  String get catalogBankCodeBranch;

  /// Display label in the built-in catalog: Bank Code / BRSTN
  ///
  /// In en, this message translates to:
  /// **'Bank Code / BRSTN'**
  String get catalogBankCodeBrstn;

  /// Display label in the built-in catalog: Kode Bank
  ///
  /// In en, this message translates to:
  /// **'Kode Bank'**
  String get catalogKodeBank;

  /// Display label in the built-in catalog: Chi nhánh / Mã Ngân hàng
  ///
  /// In en, this message translates to:
  /// **'Chi nhánh / Mã Ngân hàng'**
  String get catalogChiNhNhMNgNHNg;

  /// Display label in the built-in catalog: Bank Code
  ///
  /// In en, this message translates to:
  /// **'Bank Code'**
  String get catalogBankCode;

  /// Display label in the built-in catalog: Bank Code (CNAPS)
  ///
  /// In en, this message translates to:
  /// **'Bank Code (CNAPS)'**
  String get catalogBankCodeCnaps;

  /// Display label in the built-in catalog: Sort Code / Bank Code
  ///
  /// In en, this message translates to:
  /// **'Sort Code / Bank Code'**
  String get catalogSortCodeBankCode;

  /// Display label in the built-in catalog: Bank Code / Branch
  ///
  /// In en, this message translates to:
  /// **'Bank Code / Branch'**
  String get catalogBankCodeBranch2;

  /// Display label in the built-in catalog: Bank Branch Code
  ///
  /// In en, this message translates to:
  /// **'Bank Branch Code'**
  String get catalogBankBranchCode2;

  /// Display label in the built-in catalog: Routing Number (9 digits)
  ///
  /// In en, this message translates to:
  /// **'Routing Number (9 digits)'**
  String get catalogRoutingNumber9Digits;

  /// Display label in the built-in catalog: Reg.nr (4 digits)
  ///
  /// In en, this message translates to:
  /// **'Reg.nr (4 digits)'**
  String get catalogRegNr4Digits;

  /// Display label in the built-in catalog: Bank Code (3 digits)
  ///
  /// In en, this message translates to:
  /// **'Bank Code (3 digits)'**
  String get catalogBankCode3Digits;

  /// Display label in the built-in catalog: UPI / Payment Handle
  ///
  /// In en, this message translates to:
  /// **'UPI / Payment Handle'**
  String get catalogUpiPaymentHandle;

  /// Display label in the built-in catalog: UPI ID / VPA
  ///
  /// In en, this message translates to:
  /// **'UPI ID / VPA'**
  String get catalogUpiIdVpa;

  /// Display label in the built-in catalog: Online Payment Link / Handle
  ///
  /// In en, this message translates to:
  /// **'Online Payment Link / Handle'**
  String get catalogOnlinePaymentLinkHandle;

  /// Display label in the built-in catalog: PayNow (UEN / Mobile)
  ///
  /// In en, this message translates to:
  /// **'PayNow (UEN / Mobile)'**
  String get catalogPaynowUenMobile;

  /// Display label in the built-in catalog: DuitNow (ID / Business Reg)
  ///
  /// In en, this message translates to:
  /// **'DuitNow (ID / Business Reg)'**
  String get catalogDuitnowIdBusinessReg;

  /// Display label in the built-in catalog: Chave Pix (CNPJ / Email / Telefone)
  ///
  /// In en, this message translates to:
  /// **'Chave Pix (CNPJ / Email / Telefone)'**
  String get catalogChavePixCnpjEmailTelefone;

  /// Display label in the built-in catalog: FPS ID (Faster Payment System)
  ///
  /// In en, this message translates to:
  /// **'FPS ID (Faster Payment System)'**
  String get catalogFpsIdFasterPaymentSystem;

  /// Display label in the built-in catalog: PromptPay (Tax ID / Mobile)
  ///
  /// In en, this message translates to:
  /// **'PromptPay (Tax ID / Mobile)'**
  String get catalogPromptpayTaxIdMobile;

  /// Display label in the built-in catalog: Payment Handle / Paystack
  ///
  /// In en, this message translates to:
  /// **'Payment Handle / Paystack'**
  String get catalogPaymentHandlePaystack;

  /// Display label in the built-in catalog: M-Pesa Paybill / Till Number
  ///
  /// In en, this message translates to:
  /// **'M-Pesa Paybill / Till Number'**
  String get catalogMPesaPaybillTillNumber;

  /// Display label in the built-in catalog: bKash / Nagad Merchant Number
  ///
  /// In en, this message translates to:
  /// **'bKash / Nagad Merchant Number'**
  String get catalogBkashNagadMerchantNumber;

  /// Display label in the built-in catalog: Swish Nummer (Företag)
  ///
  /// In en, this message translates to:
  /// **'Swish Nummer (Företag)'**
  String get catalogSwishNummerFRetag;

  /// Display label in the built-in catalog: Vipps Nummer (Bedrift)
  ///
  /// In en, this message translates to:
  /// **'Vipps Nummer (Bedrift)'**
  String get catalogVippsNummerBedrift;

  /// Display label in the built-in catalog: MobilePay Nummer
  ///
  /// In en, this message translates to:
  /// **'MobilePay Nummer'**
  String get catalogMobilepayNummer;

  /// Display label in the built-in catalog: Wafey / KNET Link
  ///
  /// In en, this message translates to:
  /// **'Wafey / KNET Link'**
  String get catalogWafeyKnetLink;

  /// Display label in the built-in catalog: BenefitPay (IBAN / Mobile)
  ///
  /// In en, this message translates to:
  /// **'BenefitPay (IBAN / Mobile)'**
  String get catalogBenefitpayIbanMobile;

  /// Display label in the built-in catalog: My Business
  ///
  /// In en, this message translates to:
  /// **'My Business'**
  String get myBusinessPlaceholder;

  /// Display label in the built-in catalog: Bank Transfer / NEFT
  ///
  /// In en, this message translates to:
  /// **'Bank Transfer / NEFT'**
  String get catalogBankTransferNeft;

  /// Display label in the built-in catalog: Cash
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get catalogCash;

  /// Display label in the built-in catalog: Credit / Debit Card
  ///
  /// In en, this message translates to:
  /// **'Credit / Debit Card'**
  String get catalogCreditDebitCard;

  /// Display label in the built-in catalog: Cheque
  ///
  /// In en, this message translates to:
  /// **'Cheque'**
  String get catalogCheque;

  /// Display label in the built-in catalog: Bank transfer
  ///
  /// In en, this message translates to:
  /// **'Bank transfer'**
  String get catalogBankTransfer;

  /// Display label in the built-in catalog: Card
  ///
  /// In en, this message translates to:
  /// **'Card'**
  String get catalogCard;

  /// Display label in the built-in catalog: e.g. 12-3456789
  ///
  /// In en, this message translates to:
  /// **'e.g. 12-3456789'**
  String get catalogEG123456789;

  /// Display label in the built-in catalog: e.g. Chase Bank / Barclays / HDFC
  ///
  /// In en, this message translates to:
  /// **'e.g. Chase Bank / Barclays / HDFC'**
  String get catalogEGChaseBankBarclaysHdfc;

  /// Display label in the built-in catalog: e.g. 1234567890
  ///
  /// In en, this message translates to:
  /// **'e.g. 1234567890'**
  String get catalogEG1234567890;

  /// Display label in the built-in catalog: e.g. 021000021 / SBIN0001234
  ///
  /// In en, this message translates to:
  /// **'e.g. 021000021 / SBIN0001234'**
  String get catalogEG021000021Sbin0001234;

  /// Display label in the built-in catalog: e.g. business@upi or paypal.me/handle
  ///
  /// In en, this message translates to:
  /// **'e.g. business@upi or paypal.me/handle'**
  String get catalogEGBusinessUpiOrPaypalMeHandle;

  /// Display label in the built-in catalog: e.g. JPMorgan Chase / Wells Fargo / Bank of America
  ///
  /// In en, this message translates to:
  /// **'e.g. JPMorgan Chase / Wells Fargo / Bank of America'**
  String get catalogEGJpmorganChaseWellsFargoBankOfAmerica;

  /// Display label in the built-in catalog: e.g. 021000021 (9-digit ABA)
  ///
  /// In en, this message translates to:
  /// **'e.g. 021000021 (9-digit ABA)'**
  String get catalogEG0210000219DigitAba;

  /// Display label in the built-in catalog: Zelle / Venmo / PayPal Handle
  ///
  /// In en, this message translates to:
  /// **'Zelle / Venmo / PayPal Handle'**
  String get catalogZelleVenmoPaypalHandle;

  /// Display label in the built-in catalog: e.g. payments@company.com or @username
  ///
  /// In en, this message translates to:
  /// **'e.g. payments@company.com or @username'**
  String get catalogEGPaymentsCompanyComOrUsername;

  /// Display label in the built-in catalog: e.g. State Bank of India / HDFC Bank / ICICI
  ///
  /// In en, this message translates to:
  /// **'e.g. State Bank of India / HDFC Bank / ICICI'**
  String get catalogEGStateBankOfIndiaHdfcBankIcici;

  /// Display label in the built-in catalog: e.g. 50100234567890
  ///
  /// In en, this message translates to:
  /// **'e.g. 50100234567890'**
  String get catalogEG50100234567890;

  /// Display label in the built-in catalog: e.g. HDFC0000123 / SBIN0001234
  ///
  /// In en, this message translates to:
  /// **'e.g. HDFC0000123 / SBIN0001234'**
  String get catalogEGHdfc0000123Sbin0001234;

  /// Display label in the built-in catalog: e.g. company@okhdfcbank or 9876543210@upi
  ///
  /// In en, this message translates to:
  /// **'e.g. company@okhdfcbank or 9876543210@upi'**
  String get catalogEGCompanyOkhdfcbankOr9876543210Upi;

  /// Display label in the built-in catalog: e.g. Barclays / HSBC UK / Lloyds Bank
  ///
  /// In en, this message translates to:
  /// **'e.g. Barclays / HSBC UK / Lloyds Bank'**
  String get catalogEGBarclaysHsbcUkLloydsBank;

  /// Display label in the built-in catalog: e.g. 12345678 (8 digits)
  ///
  /// In en, this message translates to:
  /// **'e.g. 12345678 (8 digits)'**
  String get catalogEG123456788Digits;

  /// Display label in the built-in catalog: e.g. 20-00-00 (6 digits)
  ///
  /// In en, this message translates to:
  /// **'e.g. 20-00-00 (6 digits)'**
  String get catalogEG2000006Digits;

  /// Display label in the built-in catalog: Paym / Faster Payments ID
  ///
  /// In en, this message translates to:
  /// **'Paym / Faster Payments ID'**
  String get catalogPaymFasterPaymentsId;

  /// Display label in the built-in catalog: e.g. payments@company.co.uk
  ///
  /// In en, this message translates to:
  /// **'e.g. payments@company.co.uk'**
  String get catalogEGPaymentsCompanyCoUk;

  /// Display label in the built-in catalog: VAT ID / USt-IdNr.
  ///
  /// In en, this message translates to:
  /// **'VAT ID / USt-IdNr.'**
  String get catalogVatIdUstIdnr;

  /// Display label in the built-in catalog: e.g. Deutsche Bank / BNP Paribas / Santander
  ///
  /// In en, this message translates to:
  /// **'e.g. Deutsche Bank / BNP Paribas / Santander'**
  String get catalogEGDeutscheBankBnpParibasSantander;

  /// Display label in the built-in catalog: e.g. DE89 3704 0044 0532 0130 00
  ///
  /// In en, this message translates to:
  /// **'e.g. DE89 3704 0044 0532 0130 00'**
  String get catalogEGDe89370400440532013000;

  /// Display label in the built-in catalog: e.g. DBKDEFFXXX (8-11 characters)
  ///
  /// In en, this message translates to:
  /// **'e.g. DBKDEFFXXX (8-11 characters)'**
  String get catalogEGDbkdeffxxx811Characters;

  /// Display label in the built-in catalog: SEPA / PayPal / Bizum Handle
  ///
  /// In en, this message translates to:
  /// **'SEPA / PayPal / Bizum Handle'**
  String get catalogSepaPaypalBizumHandle;

  /// Display label in the built-in catalog: e.g. paypal.me/company or SEPA ID
  ///
  /// In en, this message translates to:
  /// **'e.g. paypal.me/company or SEPA ID'**
  String get catalogEGPaypalMeCompanyOrSepaId;

  /// Display label in the built-in catalog: e.g. RBC Royal Bank / TD Canada Trust / BMO
  ///
  /// In en, this message translates to:
  /// **'e.g. RBC Royal Bank / TD Canada Trust / BMO'**
  String get catalogEGRbcRoyalBankTdCanadaTrustBmo;

  /// Display label in the built-in catalog: e.g. 1234567
  ///
  /// In en, this message translates to:
  /// **'e.g. 1234567'**
  String get catalogEG1234567;

  /// Display label in the built-in catalog: e.g. 12345-001 (Transit-Inst)
  ///
  /// In en, this message translates to:
  /// **'e.g. 12345-001 (Transit-Inst)'**
  String get catalogEG12345001TransitInst;

  /// Display label in the built-in catalog: Interac e-Transfer Handle
  ///
  /// In en, this message translates to:
  /// **'Interac e-Transfer Handle'**
  String get catalogInteracETransferHandle;

  /// Display label in the built-in catalog: e.g. payments@company.ca
  ///
  /// In en, this message translates to:
  /// **'e.g. payments@company.ca'**
  String get catalogEGPaymentsCompanyCa;

  /// Display label in the built-in catalog: e.g. Commonwealth Bank / ANZ / Westpac / NAB
  ///
  /// In en, this message translates to:
  /// **'e.g. Commonwealth Bank / ANZ / Westpac / NAB'**
  String get catalogEGCommonwealthBankAnzWestpacNab;

  /// Display label in the built-in catalog: e.g. 1234 5678
  ///
  /// In en, this message translates to:
  /// **'e.g. 1234 5678'**
  String get catalogEG12345678;

  /// Display label in the built-in catalog: e.g. 062-000 (6 digits)
  ///
  /// In en, this message translates to:
  /// **'e.g. 062-000 (6 digits)'**
  String get catalogEG0620006Digits;

  /// Display label in the built-in catalog: PayID / Osko Handle
  ///
  /// In en, this message translates to:
  /// **'PayID / Osko Handle'**
  String get catalogPayidOskoHandle;

  /// Display label in the built-in catalog: e.g. payments@company.com.au or 0400123456
  ///
  /// In en, this message translates to:
  /// **'e.g. payments@company.com.au or 0400123456'**
  String get catalogEGPaymentsCompanyComAuOr0400123456;

  /// Display label in the built-in catalog: e.g. Emirates NBD / First Abu Dhabi Bank (FAB)
  ///
  /// In en, this message translates to:
  /// **'e.g. Emirates NBD / First Abu Dhabi Bank (FAB)'**
  String get catalogEGEmiratesNbdFirstAbuDhabiBankFab;

  /// Display label in the built-in catalog: e.g. AE07 0331 2345 6789 0123 45
  ///
  /// In en, this message translates to:
  /// **'e.g. AE07 0331 2345 6789 0123 45'**
  String get catalogEGAe07033123456789012345;

  /// Display label in the built-in catalog: e.g. EBILAEADXXX
  ///
  /// In en, this message translates to:
  /// **'e.g. EBILAEADXXX'**
  String get catalogEGEbilaeadxxx;

  /// Display label in the built-in catalog: Aani / Instant Pay Handle
  ///
  /// In en, this message translates to:
  /// **'Aani / Instant Pay Handle'**
  String get catalogAaniInstantPayHandle;

  /// Display label in the built-in catalog: e.g. 0501234567 or @company
  ///
  /// In en, this message translates to:
  /// **'e.g. 0501234567 or @company'**
  String get catalogEG0501234567OrCompany;

  /// Display label in the built-in catalog: e.g. Al Rajhi Bank / Saudi National Bank (SNB)
  ///
  /// In en, this message translates to:
  /// **'e.g. Al Rajhi Bank / Saudi National Bank (SNB)'**
  String get catalogEGAlRajhiBankSaudiNationalBankSnb;

  /// Display label in the built-in catalog: e.g. SA03 8000 0000 6080 1016 7519
  ///
  /// In en, this message translates to:
  /// **'e.g. SA03 8000 0000 6080 1016 7519'**
  String get catalogEGSa0380000000608010167519;

  /// Display label in the built-in catalog: e.g. RJHISA22XXX
  ///
  /// In en, this message translates to:
  /// **'e.g. RJHISA22XXX'**
  String get catalogEGRjhisa22Xxx;

  /// Display label in the built-in catalog: Sarie / STC Pay Handle
  ///
  /// In en, this message translates to:
  /// **'Sarie / STC Pay Handle'**
  String get catalogSarieStcPayHandle;

  /// Display label in the built-in catalog: e.g. 0501234567 or payments@company.sa
  ///
  /// In en, this message translates to:
  /// **'e.g. 0501234567 or payments@company.sa'**
  String get catalogEG0501234567OrPaymentsCompanySa;

  /// Display label in the built-in catalog: e.g. DBS Bank / OCBC / UOB
  ///
  /// In en, this message translates to:
  /// **'e.g. DBS Bank / OCBC / UOB'**
  String get catalogEGDbsBankOcbcUob;

  /// Display label in the built-in catalog: e.g. 123-45678-9
  ///
  /// In en, this message translates to:
  /// **'e.g. 123-45678-9'**
  String get catalogEG1234567892;

  /// Display label in the built-in catalog: e.g. 7171-001 (DBS)
  ///
  /// In en, this message translates to:
  /// **'e.g. 7171-001 (DBS)'**
  String get catalogEG7171001Dbs;

  /// Display label in the built-in catalog: e.g. 201234567A or +6591234567
  ///
  /// In en, this message translates to:
  /// **'e.g. 201234567A or +6591234567'**
  String get catalogEG201234567AOr6591234567;

  /// Display label in the built-in catalog: e.g. Mitsubishi UFJ (MUFG) / SMBC / Mizuho
  ///
  /// In en, this message translates to:
  /// **'e.g. Mitsubishi UFJ (MUFG) / SMBC / Mizuho'**
  String get catalogEGMitsubishiUfjMufgSmbcMizuho;

  /// Display label in the built-in catalog: e.g. 1234567 (Futsu)
  ///
  /// In en, this message translates to:
  /// **'e.g. 1234567 (Futsu)'**
  String get catalogEG1234567Futsu;

  /// Display label in the built-in catalog: e.g. 001 (Shinjuku Branch)
  ///
  /// In en, this message translates to:
  /// **'e.g. 001 (Shinjuku Branch)'**
  String get catalogEG001ShinjukuBranch;

  /// Display label in the built-in catalog: PayPay / Line Pay Handle
  ///
  /// In en, this message translates to:
  /// **'PayPay / Line Pay Handle'**
  String get catalogPaypayLinePayHandle;

  /// Display label in the built-in catalog: e.g. payments@company.jp
  ///
  /// In en, this message translates to:
  /// **'e.g. payments@company.jp'**
  String get catalogEGPaymentsCompanyJp;

  /// Display label in the built-in catalog: e.g. ANZ New Zealand / ASB Bank / BNZ
  ///
  /// In en, this message translates to:
  /// **'e.g. ANZ New Zealand / ASB Bank / BNZ'**
  String get catalogEGAnzNewZealandAsbBankBnz;

  /// Display label in the built-in catalog: e.g. 01-0123-0123456-00
  ///
  /// In en, this message translates to:
  /// **'e.g. 01-0123-0123456-00'**
  String get catalogEG010123012345600;

  /// Display label in the built-in catalog: e.g. 01-0123 (6 digits)
  ///
  /// In en, this message translates to:
  /// **'e.g. 01-0123 (6 digits)'**
  String get catalogEG0101236Digits;

  /// Display label in the built-in catalog: e.g. payments@company.co.nz
  ///
  /// In en, this message translates to:
  /// **'e.g. payments@company.co.nz'**
  String get catalogEGPaymentsCompanyCoNz;

  /// Display label in the built-in catalog: e.g. UBS / Credit Suisse / ZKB
  ///
  /// In en, this message translates to:
  /// **'e.g. UBS / Credit Suisse / ZKB'**
  String get catalogEGUbsCreditSuisseZkb;

  /// Display label in the built-in catalog: e.g. CH93 0076 2011 6238 5295 7
  ///
  /// In en, this message translates to:
  /// **'e.g. CH93 0076 2011 6238 5295 7'**
  String get catalogEGCh9300762011623852957;

  /// Display label in the built-in catalog: e.g. UBSWCHZHXXX
  ///
  /// In en, this message translates to:
  /// **'e.g. UBSWCHZHXXX'**
  String get catalogEGUbswchzhxxx;

  /// Display label in the built-in catalog: TWINT / QR-Bill Handle
  ///
  /// In en, this message translates to:
  /// **'TWINT / QR-Bill Handle'**
  String get catalogTwintQrBillHandle;

  /// Display label in the built-in catalog: e.g. +41 79 123 45 67 or @company
  ///
  /// In en, this message translates to:
  /// **'e.g. +41 79 123 45 67 or @company'**
  String get catalogEG41791234567OrCompany;

  /// Display label in the built-in catalog: e.g. Maybank / CIMB Bank / Public Bank
  ///
  /// In en, this message translates to:
  /// **'e.g. Maybank / CIMB Bank / Public Bank'**
  String get catalogEGMaybankCimbBankPublicBank;

  /// Display label in the built-in catalog: e.g. 5140 1234 5678
  ///
  /// In en, this message translates to:
  /// **'e.g. 5140 1234 5678'**
  String get catalogEG514012345678;

  /// Display label in the built-in catalog: e.g. MBBEMYKL
  ///
  /// In en, this message translates to:
  /// **'e.g. MBBEMYKL'**
  String get catalogEGMbbemykl;

  /// Display label in the built-in catalog: e.g. 201234567A or 0123456789
  ///
  /// In en, this message translates to:
  /// **'e.g. 201234567A or 0123456789'**
  String get catalogEG201234567AOr0123456789;

  /// Display label in the built-in catalog: e.g. Standard Bank / FNB / Absa / Nedbank
  ///
  /// In en, this message translates to:
  /// **'e.g. Standard Bank / FNB / Absa / Nedbank'**
  String get catalogEGStandardBankFnbAbsaNedbank;

  /// Display label in the built-in catalog: e.g. 123456789
  ///
  /// In en, this message translates to:
  /// **'e.g. 123456789'**
  String get catalogEG1234567893;

  /// Display label in the built-in catalog: e.g. 051001 (FNB Universal)
  ///
  /// In en, this message translates to:
  /// **'e.g. 051001 (FNB Universal)'**
  String get catalogEG051001FnbUniversal;

  /// Display label in the built-in catalog: e.g. 0821234567 or @shapid
  ///
  /// In en, this message translates to:
  /// **'e.g. 0821234567 or @shapid'**
  String get catalogEG0821234567OrShapid;

  /// Display label in the built-in catalog: e.g. BBVA México / Banorte / Santander México
  ///
  /// In en, this message translates to:
  /// **'e.g. BBVA México / Banorte / Santander México'**
  String get catalogEGBbvaMXicoBanorteSantanderMXico;

  /// Display label in the built-in catalog: e.g. 012 180 00123456789 0
  ///
  /// In en, this message translates to:
  /// **'e.g. 012 180 00123456789 0'**
  String get catalogEG012180001234567890;

  /// Display label in the built-in catalog: CoDi / Dimo / SPEI Handle
  ///
  /// In en, this message translates to:
  /// **'CoDi / Dimo / SPEI Handle'**
  String get catalogCodiDimoSpeiHandle;

  /// Display label in the built-in catalog: e.g. 5512345678 or rfc@empresa.com
  ///
  /// In en, this message translates to:
  /// **'e.g. 5512345678 or rfc@empresa.com'**
  String get catalogEG5512345678OrRfcEmpresaCom;

  /// Display label in the built-in catalog: e.g. Itaú Unibanco / Bradesco / Banco do Brasil
  ///
  /// In en, this message translates to:
  /// **'e.g. Itaú Unibanco / Bradesco / Banco do Brasil'**
  String get catalogEGItaUnibancoBradescoBancoDoBrasil;

  /// Display label in the built-in catalog: e.g. 12345-6
  ///
  /// In en, this message translates to:
  /// **'e.g. 12345-6'**
  String get catalogEG123456;

  /// Display label in the built-in catalog: e.g. 0341 (Itaú) / Ag. 1234
  ///
  /// In en, this message translates to:
  /// **'e.g. 0341 (Itaú) / Ag. 1234'**
  String get catalogEG0341ItaAg1234;

  /// Display label in the built-in catalog: e.g. 00.000.000/0001-00 ou pix@empresa.com.br
  ///
  /// In en, this message translates to:
  /// **'e.g. 00.000.000/0001-00 ou pix@empresa.com.br'**
  String get catalogEG00000000000100OuPixEmpresaComBr;

  /// Display label in the built-in catalog: e.g. HSBC / Standard Chartered / Hang Seng Bank
  ///
  /// In en, this message translates to:
  /// **'e.g. HSBC / Standard Chartered / Hang Seng Bank'**
  String get catalogEGHsbcStandardCharteredHangSengBank;

  /// Display label in the built-in catalog: e.g. 123-456789-001
  ///
  /// In en, this message translates to:
  /// **'e.g. 123-456789-001'**
  String get catalogEG123456789001;

  /// Display label in the built-in catalog: e.g. 004-123 (HSBC)
  ///
  /// In en, this message translates to:
  /// **'e.g. 004-123 (HSBC)'**
  String get catalogEG004123Hsbc;

  /// Display label in the built-in catalog: e.g. 1234567 or payments@company.hk
  ///
  /// In en, this message translates to:
  /// **'e.g. 1234567 or payments@company.hk'**
  String get catalogEG1234567OrPaymentsCompanyHk;

  /// Display label in the built-in catalog: e.g. Bangkok Bank / Kasikornbank (KBank) / SCB
  ///
  /// In en, this message translates to:
  /// **'e.g. Bangkok Bank / Kasikornbank (KBank) / SCB'**
  String get catalogEGBangkokBankKasikornbankKbankScb;

  /// Display label in the built-in catalog: e.g. 123-4-56789-0
  ///
  /// In en, this message translates to:
  /// **'e.g. 123-4-56789-0'**
  String get catalogEG12345678902;

  /// Display label in the built-in catalog: e.g. 0001
  ///
  /// In en, this message translates to:
  /// **'e.g. 0001'**
  String get catalogEG0001;

  /// Display label in the built-in catalog: e.g. 0105551234567 or 0812345678
  ///
  /// In en, this message translates to:
  /// **'e.g. 0105551234567 or 0812345678'**
  String get catalogEG0105551234567Or0812345678;

  /// Display label in the built-in catalog: e.g. BDO Unibank / BPI / Metrobank
  ///
  /// In en, this message translates to:
  /// **'e.g. BDO Unibank / BPI / Metrobank'**
  String get catalogEGBdoUnibankBpiMetrobank;

  /// Display label in the built-in catalog: e.g. 1234 5678 9012
  ///
  /// In en, this message translates to:
  /// **'e.g. 1234 5678 9012'**
  String get catalogEG123456789012;

  /// Display label in the built-in catalog: e.g. 010530667
  ///
  /// In en, this message translates to:
  /// **'e.g. 010530667'**
  String get catalogEG010530667;

  /// Display label in the built-in catalog: e.g. 09171234567 or @company
  ///
  /// In en, this message translates to:
  /// **'e.g. 09171234567 or @company'**
  String get catalogEG09171234567OrCompany;

  /// Display label in the built-in catalog: e.g. Bank Central Asia (BCA) / Mandiri / BRI
  ///
  /// In en, this message translates to:
  /// **'e.g. Bank Central Asia (BCA) / Mandiri / BRI'**
  String get catalogEGBankCentralAsiaBcaMandiriBri;

  /// Display label in the built-in catalog: e.g. 014 (BCA)
  ///
  /// In en, this message translates to:
  /// **'e.g. 014 (BCA)'**
  String get catalogEG014Bca;

  /// Display label in the built-in catalog: QRIS / GoPay / OVO Handle
  ///
  /// In en, this message translates to:
  /// **'QRIS / GoPay / OVO Handle'**
  String get catalogQrisGopayOvoHandle;

  /// Display label in the built-in catalog: e.g. 081234567890 or payments@company.id
  ///
  /// In en, this message translates to:
  /// **'e.g. 081234567890 or payments@company.id'**
  String get catalogEG081234567890OrPaymentsCompanyId;

  /// Display label in the built-in catalog: e.g. Vietcombank / Techcombank / BIDV
  ///
  /// In en, this message translates to:
  /// **'e.g. Vietcombank / Techcombank / BIDV'**
  String get catalogEGVietcombankTechcombankBidv;

  /// Display label in the built-in catalog: e.g. 0011001234567
  ///
  /// In en, this message translates to:
  /// **'e.g. 0011001234567'**
  String get catalogEG0011001234567;

  /// Display label in the built-in catalog: e.g. Chi nhánh Ba Đình
  ///
  /// In en, this message translates to:
  /// **'e.g. Chi nhánh Ba Đình'**
  String get catalogEGChiNhNhBaNh;

  /// Display label in the built-in catalog: VietQR / MoMo / ZaloPay Handle
  ///
  /// In en, this message translates to:
  /// **'VietQR / MoMo / ZaloPay Handle'**
  String get catalogVietqrMomoZalopayHandle;

  /// Display label in the built-in catalog: e.g. 0912345678 or @company
  ///
  /// In en, this message translates to:
  /// **'e.g. 0912345678 or @company'**
  String get catalogEG0912345678OrCompany;

  /// Display label in the built-in catalog: e.g. KB Kookmin Bank / Shinhan / Hana Bank
  ///
  /// In en, this message translates to:
  /// **'e.g. KB Kookmin Bank / Shinhan / Hana Bank'**
  String get catalogEGKbKookminBankShinhanHanaBank;

  /// Display label in the built-in catalog: e.g. 123-456-789012
  ///
  /// In en, this message translates to:
  /// **'e.g. 123-456-789012'**
  String get catalogEG1234567890122;

  /// Display label in the built-in catalog: e.g. 004 (KB)
  ///
  /// In en, this message translates to:
  /// **'e.g. 004 (KB)'**
  String get catalogEG004Kb;

  /// Display label in the built-in catalog: KakaoPay / Toss Handle
  ///
  /// In en, this message translates to:
  /// **'KakaoPay / Toss Handle'**
  String get catalogKakaopayTossHandle;

  /// Display label in the built-in catalog: e.g. 010-1234-5678
  ///
  /// In en, this message translates to:
  /// **'e.g. 010-1234-5678'**
  String get catalogEG01012345678;

  /// Display label in the built-in catalog: e.g. ICBC / China Construction Bank / Bank of China
  ///
  /// In en, this message translates to:
  /// **'e.g. ICBC / China Construction Bank / Bank of China'**
  String get catalogEGIcbcChinaConstructionBankBankOfChina;

  /// Display label in the built-in catalog: e.g. 6222 0212 3456 7890
  ///
  /// In en, this message translates to:
  /// **'e.g. 6222 0212 3456 7890'**
  String get catalogEG6222021234567890;

  /// Display label in the built-in catalog: e.g. 102100000010
  ///
  /// In en, this message translates to:
  /// **'e.g. 102100000010'**
  String get catalogEG102100000010;

  /// Display label in the built-in catalog: Alipay / WeChat Pay Handle
  ///
  /// In en, this message translates to:
  /// **'Alipay / WeChat Pay Handle'**
  String get catalogAlipayWechatPayHandle;

  /// Display label in the built-in catalog: e.g. payments@company.cn or 13800138000
  ///
  /// In en, this message translates to:
  /// **'e.g. payments@company.cn or 13800138000'**
  String get catalogEGPaymentsCompanyCnOr13800138000;

  /// Display label in the built-in catalog: e.g. Access Bank / Zenith Bank / GTBank
  ///
  /// In en, this message translates to:
  /// **'e.g. Access Bank / Zenith Bank / GTBank'**
  String get catalogEGAccessBankZenithBankGtbank;

  /// Display label in the built-in catalog: e.g. 0123456789 (10 digits)
  ///
  /// In en, this message translates to:
  /// **'e.g. 0123456789 (10 digits)'**
  String get catalogEG012345678910Digits;

  /// Display label in the built-in catalog: e.g. 058152010
  ///
  /// In en, this message translates to:
  /// **'e.g. 058152010'**
  String get catalogEG058152010;

  /// Display label in the built-in catalog: e.g. paystack.com/pay/mycompany
  ///
  /// In en, this message translates to:
  /// **'e.g. paystack.com/pay/mycompany'**
  String get catalogEGPaystackComPayMycompany;

  /// Display label in the built-in catalog: e.g. KCB Bank / Equity Bank / NCBA
  ///
  /// In en, this message translates to:
  /// **'e.g. KCB Bank / Equity Bank / NCBA'**
  String get catalogEGKcbBankEquityBankNcba;

  /// Display label in the built-in catalog: e.g. 01100
  ///
  /// In en, this message translates to:
  /// **'e.g. 01100'**
  String get catalogEG01100;

  /// Display label in the built-in catalog: e.g. Paybill: 247247, Acc: 123456
  ///
  /// In en, this message translates to:
  /// **'e.g. Paybill: 247247, Acc: 123456'**
  String get catalogEGPaybill247247Acc123456;

  /// Display label in the built-in catalog: e.g. Habib Bank (HBL) / MCB / Meezan Bank
  ///
  /// In en, this message translates to:
  /// **'e.g. Habib Bank (HBL) / MCB / Meezan Bank'**
  String get catalogEGHabibBankHblMcbMeezanBank;

  /// Display label in the built-in catalog: e.g. PK36MEZN0001234567890123
  ///
  /// In en, this message translates to:
  /// **'e.g. PK36MEZN0001234567890123'**
  String get catalogEGPk36Mezn0001234567890123;

  /// Display label in the built-in catalog: e.g. 0123
  ///
  /// In en, this message translates to:
  /// **'e.g. 0123'**
  String get catalogEG0123;

  /// Display label in the built-in catalog: Raast ID / JazzCash / Easypaisa
  ///
  /// In en, this message translates to:
  /// **'Raast ID / JazzCash / Easypaisa'**
  String get catalogRaastIdJazzcashEasypaisa;

  /// Display label in the built-in catalog: e.g. 03001234567
  ///
  /// In en, this message translates to:
  /// **'e.g. 03001234567'**
  String get catalogEG03001234567;

  /// Display label in the built-in catalog: e.g. Sonali Bank / BRAC Bank / Dutch-Bangla
  ///
  /// In en, this message translates to:
  /// **'e.g. Sonali Bank / BRAC Bank / Dutch-Bangla'**
  String get catalogEGSonaliBankBracBankDutchBangla;

  /// Display label in the built-in catalog: e.g. 1011234567890
  ///
  /// In en, this message translates to:
  /// **'e.g. 1011234567890'**
  String get catalogEG1011234567890;

  /// Display label in the built-in catalog: e.g. 060271234
  ///
  /// In en, this message translates to:
  /// **'e.g. 060271234'**
  String get catalogEG060271234;

  /// Display label in the built-in catalog: e.g. 01712345678 (Personal / Merchant)
  ///
  /// In en, this message translates to:
  /// **'e.g. 01712345678 (Personal / Merchant)'**
  String get catalogEG01712345678PersonalMerchant;

  /// Display label in the built-in catalog: e.g. PKO Bank Polski / Santander Polska / mBank
  ///
  /// In en, this message translates to:
  /// **'e.g. PKO Bank Polski / Santander Polska / mBank'**
  String get catalogEGPkoBankPolskiSantanderPolskaMbank;

  /// Display label in the built-in catalog: e.g. PL 12 1020 1026 0000 1234 5678 9012
  ///
  /// In en, this message translates to:
  /// **'e.g. PL 12 1020 1026 0000 1234 5678 9012'**
  String get catalogEGPl12102010260000123456789012;

  /// Display label in the built-in catalog: e.g. PKOPPLPW
  ///
  /// In en, this message translates to:
  /// **'e.g. PKOPPLPW'**
  String get catalogEGPkopplpw;

  /// Display label in the built-in catalog: BLIK / Przelewy24 Handle
  ///
  /// In en, this message translates to:
  /// **'BLIK / Przelewy24 Handle'**
  String get catalogBlikPrzelewy24Handle;

  /// Display label in the built-in catalog: e.g. +48 500 123 456 lub email
  ///
  /// In en, this message translates to:
  /// **'e.g. +48 500 123 456 lub email'**
  String get catalogEG48500123456LubEmail;

  /// Display label in the built-in catalog: e.g. Swedbank / SEB / Handelsbanken
  ///
  /// In en, this message translates to:
  /// **'e.g. Swedbank / SEB / Handelsbanken'**
  String get catalogEGSwedbankSebHandelsbanken;

  /// Display label in the built-in catalog: e.g. 1234 567 890-1
  ///
  /// In en, this message translates to:
  /// **'e.g. 1234 567 890-1'**
  String get catalogEG12345678901;

  /// Display label in the built-in catalog: e.g. Bg 123-4567 eller Clearing 8105-9
  ///
  /// In en, this message translates to:
  /// **'e.g. Bg 123-4567 eller Clearing 8105-9'**
  String get catalogEGBg1234567EllerClearing81059;

  /// Display label in the built-in catalog: e.g. 123 123 45 67
  ///
  /// In en, this message translates to:
  /// **'e.g. 123 123 45 67'**
  String get catalogEG1231234567;

  /// Display label in the built-in catalog: e.g. DNB / Nordea Norge / SpareBank 1
  ///
  /// In en, this message translates to:
  /// **'e.g. DNB / Nordea Norge / SpareBank 1'**
  String get catalogEGDnbNordeaNorgeSparebank1;

  /// Display label in the built-in catalog: e.g. 1234.56.78901
  ///
  /// In en, this message translates to:
  /// **'e.g. 1234.56.78901'**
  String get catalogEG123456789013;

  /// Display label in the built-in catalog: e.g. DNBANOKK
  ///
  /// In en, this message translates to:
  /// **'e.g. DNBANOKK'**
  String get catalogEGDnbanokk;

  /// Display label in the built-in catalog: e.g. Vipps-nr: 12345
  ///
  /// In en, this message translates to:
  /// **'e.g. Vipps-nr: 12345'**
  String get catalogEGVippsNr12345;

  /// Display label in the built-in catalog: e.g. Danske Bank / Nordea Danmark / Jyske Bank
  ///
  /// In en, this message translates to:
  /// **'e.g. Danske Bank / Nordea Danmark / Jyske Bank'**
  String get catalogEGDanskeBankNordeaDanmarkJyskeBank;

  /// Display label in the built-in catalog: e.g. 1234
  ///
  /// In en, this message translates to:
  /// **'e.g. 1234'**
  String get catalogEG1234;

  /// Display label in the built-in catalog: e.g. 12 34 56
  ///
  /// In en, this message translates to:
  /// **'e.g. 12 34 56'**
  String get catalogEG1234562;

  /// Display label in the built-in catalog: e.g. Qatar National Bank (QNB) / QIIB
  ///
  /// In en, this message translates to:
  /// **'e.g. Qatar National Bank (QNB) / QIIB'**
  String get catalogEGQatarNationalBankQnbQiib;

  /// Display label in the built-in catalog: e.g. QA53 QNBA 0000 0000 1234 5678 9012 3
  ///
  /// In en, this message translates to:
  /// **'e.g. QA53 QNBA 0000 0000 1234 5678 9012 3'**
  String get catalogEGQa53Qnba000000001234567890123;

  /// Display label in the built-in catalog: e.g. QNBAQAQA
  ///
  /// In en, this message translates to:
  /// **'e.g. QNBAQAQA'**
  String get catalogEGQnbaqaqa;

  /// Display label in the built-in catalog: Fawran / Instant Pay Handle
  ///
  /// In en, this message translates to:
  /// **'Fawran / Instant Pay Handle'**
  String get catalogFawranInstantPayHandle;

  /// Display label in the built-in catalog: e.g. 55123456 or @company
  ///
  /// In en, this message translates to:
  /// **'e.g. 55123456 or @company'**
  String get catalogEG55123456OrCompany;

  /// Display label in the built-in catalog: e.g. National Bank of Kuwait (NBK) / KFH
  ///
  /// In en, this message translates to:
  /// **'e.g. National Bank of Kuwait (NBK) / KFH'**
  String get catalogEGNationalBankOfKuwaitNbkKfh;

  /// Display label in the built-in catalog: e.g. KW12 NBOK 0000 0000 1234 5678 9012 34
  ///
  /// In en, this message translates to:
  /// **'e.g. KW12 NBOK 0000 0000 1234 5678 9012 34'**
  String get catalogEGKw12Nbok0000000012345678901234;

  /// Display label in the built-in catalog: e.g. NBOKKWKW
  ///
  /// In en, this message translates to:
  /// **'e.g. NBOKKWKW'**
  String get catalogEGNbokkwkw;

  /// Display label in the built-in catalog: e.g. payments@company.kw
  ///
  /// In en, this message translates to:
  /// **'e.g. payments@company.kw'**
  String get catalogEGPaymentsCompanyKw;

  /// Display label in the built-in catalog: e.g. National Bank of Bahrain (NBB) / BBK
  ///
  /// In en, this message translates to:
  /// **'e.g. National Bank of Bahrain (NBB) / BBK'**
  String get catalogEGNationalBankOfBahrainNbbBbk;

  /// Display label in the built-in catalog: e.g. BH02 NBOB 0000 0000 1234 56
  ///
  /// In en, this message translates to:
  /// **'e.g. BH02 NBOB 0000 0000 1234 56'**
  String get catalogEGBh02Nbob00000000123456;

  /// Display label in the built-in catalog: e.g. NBOBBHBM
  ///
  /// In en, this message translates to:
  /// **'e.g. NBOBBHBM'**
  String get catalogEGNbobbhbm;

  /// Display label in the built-in catalog: e.g. 39123456 or @company
  ///
  /// In en, this message translates to:
  /// **'e.g. 39123456 or @company'**
  String get catalogEG39123456OrCompany;

  /// Display label in the built-in catalog: e.g. Bank of Taiwan / CTBC Bank / Mega Bank
  ///
  /// In en, this message translates to:
  /// **'e.g. Bank of Taiwan / CTBC Bank / Mega Bank'**
  String get catalogEGBankOfTaiwanCtbcBankMegaBank;

  /// Display label in the built-in catalog: e.g. 0123-456-789012
  ///
  /// In en, this message translates to:
  /// **'e.g. 0123-456-789012'**
  String get catalogEG0123456789012;

  /// Display label in the built-in catalog: e.g. 004 (Bank of Taiwan)
  ///
  /// In en, this message translates to:
  /// **'e.g. 004 (Bank of Taiwan)'**
  String get catalogEG004BankOfTaiwan;

  /// Display label in the built-in catalog: Taiwan Pay / Line Pay Handle
  ///
  /// In en, this message translates to:
  /// **'Taiwan Pay / Line Pay Handle'**
  String get catalogTaiwanPayLinePayHandle;

  /// UI text: PART PAID
  ///
  /// In en, this message translates to:
  /// **'PART PAID'**
  String get partPaidStamp;

  /// UI text: GO PRO
  ///
  /// In en, this message translates to:
  /// **'GO PRO'**
  String get goProStamp;

  /// UI text: Immediately
  ///
  /// In en, this message translates to:
  /// **'Immediately'**
  String get immediately;

  /// UI text: Set up a screen lock or enroll biometrics in your device settings to use App lock.
  ///
  /// In en, this message translates to:
  /// **'Set up a screen lock or enroll biometrics in your device settings to use App lock.'**
  String get ensureScreenLock;

  /// UI text: Confirm your identity to enable App lock
  ///
  /// In en, this message translates to:
  /// **'Confirm your identity to enable App lock'**
  String get authenticateToEnableAppLock;

  /// UI text: Could not save the App lock setting. Try again.
  ///
  /// In en, this message translates to:
  /// **'Could not save the App lock setting. Try again.'**
  String get cannotSaveAppLock;

  /// UI text: Could not save the lock timeout. Try again.
  ///
  /// In en, this message translates to:
  /// **'Could not save the lock timeout. Try again.'**
  String get cannotSaveLockTimeout;

  /// UI text: Unlock Invoice Maker Pro
  ///
  /// In en, this message translates to:
  /// **'Unlock Invoice Maker Pro'**
  String get unlockApp;

  /// UI text: Could not complete the App lock request. Try again.
  ///
  /// In en, this message translates to:
  /// **'Could not complete the App lock request. Try again.'**
  String get appLockOperationFailed;

  /// UI text: Authentication was not completed.
  ///
  /// In en, this message translates to:
  /// **'Authentication was not completed.'**
  String get authenticationIncomplete;

  /// UI text: Authentication is temporarily locked. Unlock your device and try again.
  ///
  /// In en, this message translates to:
  /// **'Authentication is temporarily locked. Unlock your device and try again.'**
  String get authenticationTemporarilyLocked;

  /// UI text: Device authentication is unavailable. Try again.
  ///
  /// In en, this message translates to:
  /// **'Device authentication is unavailable. Try again.'**
  String get authenticationUnavailable;

  /// UI text: Reminders about outstanding invoice balances
  ///
  /// In en, this message translates to:
  /// **'Reminders about outstanding invoice balances'**
  String get reminderChannelDescription;

  /// UI text: Payment reminders are working on this device.
  ///
  /// In en, this message translates to:
  /// **'Payment reminders are working on this device.'**
  String get remindersWorking;

  /// UI text: tomorrow
  ///
  /// In en, this message translates to:
  /// **'tomorrow'**
  String get reminderTomorrow;

  /// UI text: today
  ///
  /// In en, this message translates to:
  /// **'today'**
  String get reminderToday;

  /// UI text: Hi,
  ///
  /// In en, this message translates to:
  /// **'Hi,'**
  String get clientGreeting;

  /// UI text: Thanks,
  ///
  /// In en, this message translates to:
  /// **'Thanks,'**
  String get clientReminderThanks;

  /// UI text: If you’ve already paid, thank you. Please let us know if you have any questions.
  ///
  /// In en, this message translates to:
  /// **'If you’ve already paid, thank you. Please let us know if you have any questions.'**
  String get clientReminderAlreadyPaid;

  /// App lock delay in minutes
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 minute} other{{count} minutes}}'**
  String minutesCount(int count);

  /// How often to send an overdue reminder
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Every 1 day} other{Every {count} days}}'**
  String everyDays(int count);

  /// Days before an invoice is due
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{in 1 day} other{in {count} days}}'**
  String reminderInDays(int count);

  /// Days after an invoice was due
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{· 1 day overdue} other{· {count} days overdue}}'**
  String reminderDaysOverdue(int count);

  /// UI text: {amount} due
  ///
  /// In en, this message translates to:
  /// **'{amount} due'**
  String reminderBalance(String amount);

  /// UI text: {amount} due from {client}
  ///
  /// In en, this message translates to:
  /// **'{amount} due from {client}'**
  String reminderBalanceFromClient(String amount, String client);

  /// UI text: {invoiceNumber} · {balance} {timing}
  ///
  /// In en, this message translates to:
  /// **'{invoiceNumber} · {balance} {timing}'**
  String reminderNotificationBody(
    String invoiceNumber,
    String balance,
    String timing,
  );

  /// UI text: Hi {client},
  ///
  /// In en, this message translates to:
  /// **'Hi {client},'**
  String clientGreetingByName(String client);

  /// UI text: A friendly reminder that {balance} is outstanding on invoice {invoiceNumber}.{timing}
  ///
  /// In en, this message translates to:
  /// **'A friendly reminder that {balance} is outstanding on invoice {invoiceNumber}.{timing}'**
  String clientReminderOutstanding(
    String balance,
    String invoiceNumber,
    String timing,
  );

  /// UI text: You can pay via UPI to {upi}.
  ///
  /// In en, this message translates to:
  /// **'You can pay via UPI to {upi}.'**
  String clientReminderUpi(String upi);

  /// UI text:  It was due on {date} ({days} overdue).
  ///
  /// In en, this message translates to:
  /// **' It was due on {date} ({days} overdue).'**
  String clientReminderOverdue(String date, String days);

  /// UI text:  It is due today ({date}).
  ///
  /// In en, this message translates to:
  /// **' It is due today ({date}).'**
  String clientReminderDueToday(String date);

  /// UI text:  It is due on {date}.
  ///
  /// In en, this message translates to:
  /// **' It is due on {date}.'**
  String clientReminderDueOn(String date);

  /// UI text: Add your logo
  ///
  /// In en, this message translates to:
  /// **'Add your logo'**
  String get addYourLogo;

  /// UI text: Add your address
  ///
  /// In en, this message translates to:
  /// **'Add your address'**
  String get addYourAddress;

  /// UI text: Add your {taxId}
  ///
  /// In en, this message translates to:
  /// **'Add your {taxId}'**
  String addYourTaxId(String taxId);

  /// UI text: Add how clients pay you
  ///
  /// In en, this message translates to:
  /// **'Add how clients pay you'**
  String get addHowClientsPayYou;

  /// UI text: Add your signature
  ///
  /// In en, this message translates to:
  /// **'Add your signature'**
  String get addYourSignature;

  /// UI text: Make your first invoice
  ///
  /// In en, this message translates to:
  /// **'Make your first invoice'**
  String get makeYourFirstInvoice;

  /// UI text: Tax ID
  ///
  /// In en, this message translates to:
  /// **'Tax ID'**
  String get taxId;

  /// UI text: Could not show the preview. Please try again.
  ///
  /// In en, this message translates to:
  /// **'Could not show the preview. Please try again.'**
  String get couldNotShowThePreviewPleaseTryAgain;

  /// UI text: Select Country & Currency
  ///
  /// In en, this message translates to:
  /// **'Select Country & Currency'**
  String get selectCountryCurrency;

  /// UI text: Tax system, payment fields & symbol will adapt
  ///
  /// In en, this message translates to:
  /// **'Tax system, payment fields & symbol will adapt'**
  String get taxSystemPaymentFieldsSymbolWillAdapt;

  /// UI text: Search by country, currency or code...
  ///
  /// In en, this message translates to:
  /// **'Search by country, currency or code...'**
  String get searchByCountryCurrencyOrCode;

  /// UI text: Upgrade to Pro
  ///
  /// In en, this message translates to:
  /// **'Upgrade to Pro'**
  String get upgradeToPro;

  /// UI text: PAID
  ///
  /// In en, this message translates to:
  /// **'PAID'**
  String get paidStamp;

  /// UI text: OVERDUE
  ///
  /// In en, this message translates to:
  /// **'OVERDUE'**
  String get overdueStamp;

  /// UI text: DUE
  ///
  /// In en, this message translates to:
  /// **'DUE'**
  String get due;

  /// UI text: Dismiss Dialog
  ///
  /// In en, this message translates to:
  /// **'Dismiss Dialog'**
  String get dismissDialog;

  /// UI text: Convert to Invoice?
  ///
  /// In en, this message translates to:
  /// **'Convert to Invoice?'**
  String get convertToInvoiceQuestion;

  /// UI text: This will generate an active invoice from {estimateNumber} for {clientName} and mark this estimate as Converted.
  ///
  /// In en, this message translates to:
  /// **'This will generate an active invoice from {estimateNumber} for {clientName} and mark this estimate as Converted.'**
  String thisWillGenerateAnActiveInvoiceFromFor(
    String estimateNumber,
    String clientName,
  );

  /// UI text: Convert to Invoice
  ///
  /// In en, this message translates to:
  /// **'Convert to Invoice'**
  String get convertToInvoiceAction;

  /// UI text: Invoice Maker Pro is locked
  ///
  /// In en, this message translates to:
  /// **'Invoice Maker Pro is locked'**
  String get invoiceMakerProIsLocked;

  /// UI text: Use your device screen lock or biometrics to continue.
  ///
  /// In en, this message translates to:
  /// **'Use your device screen lock or biometrics to continue.'**
  String get useYourDeviceScreenLockOrBiometricsTo;

  /// UI text: Unlock
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get unlock;

  /// UI text: Back
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// UI text: App lock
  ///
  /// In en, this message translates to:
  /// **'App lock'**
  String get appLock;

  /// UI text: Require authentication
  ///
  /// In en, this message translates to:
  /// **'Require authentication'**
  String get requireAuthentication;

  /// UI text: Use your screen lock or biometrics
  ///
  /// In en, this message translates to:
  /// **'Use your screen lock or biometrics'**
  String get useYourScreenLockOrBiometrics;

  /// UI text: Lock after
  ///
  /// In en, this message translates to:
  /// **'Lock after'**
  String get lockAfter;

  /// UI text: Time spent away from the app
  ///
  /// In en, this message translates to:
  /// **'Time spent away from the app'**
  String get timeSpentAwayFromTheApp;

  /// UI text: Could not load reminder settings.
  ///
  /// In en, this message translates to:
  /// **'Could not load reminder settings.'**
  String get couldNotLoadReminderSettings;

  /// UI text: Could not update payment reminders. Please try again.
  ///
  /// In en, this message translates to:
  /// **'Could not update payment reminders. Please try again.'**
  String get couldNotUpdatePaymentRemindersPleaseTryAgain;

  /// UI text: Payment reminders
  ///
  /// In en, this message translates to:
  /// **'Payment reminders'**
  String get paymentReminders;

  /// UI text: Payment reminders are available on Android and iOS.
  ///
  /// In en, this message translates to:
  /// **'Payment reminders are available on Android and iOS.'**
  String get paymentRemindersAreAvailableOnAndroidAndIos;

  /// UI text: Enable reminders
  ///
  /// In en, this message translates to:
  /// **'Enable reminders'**
  String get enableReminders;

  /// UI text: Notify me about unpaid balances
  ///
  /// In en, this message translates to:
  /// **'Notify me about unpaid balances'**
  String get notifyMeAboutUnpaidBalances;

  /// UI text: Allow notifications in your device settings to turn on reminders.
  ///
  /// In en, this message translates to:
  /// **'Allow notifications in your device settings to turn on reminders.'**
  String get allowNotificationsInYourDeviceSettingsToTurn;

  /// UI text: Before the due date
  ///
  /// In en, this message translates to:
  /// **'Before the due date'**
  String get beforeTheDueDate;

  /// UI text: When overdue
  ///
  /// In en, this message translates to:
  /// **'When overdue'**
  String get whenOverdue;

  /// UI text: Off
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get off;

  /// UI text: Reminders are scheduled for 9 AM on the due date and up to three times after it.
  ///
  /// In en, this message translates to:
  /// **'Reminders are scheduled for 9 AM on the due date and up to three times after it.'**
  String get remindersAreScheduledFor9AmOnThe;

  /// UI text: Send test notification
  ///
  /// In en, this message translates to:
  /// **'Send test notification'**
  String get sendTestNotification;

  /// UI text: Test notification sent.
  ///
  /// In en, this message translates to:
  /// **'Test notification sent.'**
  String get testNotificationSent;

  /// UI text: Enter a message to send.
  ///
  /// In en, this message translates to:
  /// **'Enter a message to send.'**
  String get enterAMessageToSend;

  /// UI text: Could not open sharing. Try again.
  ///
  /// In en, this message translates to:
  /// **'Could not open sharing. Try again.'**
  String get couldNotOpenSharingTryAgain;

  /// UI text: Send reminder
  ///
  /// In en, this message translates to:
  /// **'Send reminder'**
  String get sendReminder;

  /// UI text: Close
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// UI text: Message
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get message;

  /// UI text: Open WhatsApp
  ///
  /// In en, this message translates to:
  /// **'Open WhatsApp'**
  String get openWhatsapp;

  /// UI text: Share / SMS
  ///
  /// In en, this message translates to:
  /// **'Share / SMS'**
  String get shareSms;

  /// UI text: Could not share the receipt.
  ///
  /// In en, this message translates to:
  /// **'Could not share the receipt.'**
  String get couldNotShareTheReceipt;

  /// UI text: Could not open printing.
  ///
  /// In en, this message translates to:
  /// **'Could not open printing.'**
  String get couldNotOpenPrinting;

  /// UI text: Payment Receipt
  ///
  /// In en, this message translates to:
  /// **'Payment Receipt'**
  String get paymentReceipt;

  /// UI text: Share receipt
  ///
  /// In en, this message translates to:
  /// **'Share receipt'**
  String get shareReceipt;

  /// UI text: Print receipt
  ///
  /// In en, this message translates to:
  /// **'Print receipt'**
  String get printReceipt;

  /// UI text: Could not show the receipt preview.
  ///
  /// In en, this message translates to:
  /// **'Could not show the receipt preview.'**
  String get couldNotShowTheReceiptPreview;

  /// UI text: Add New Client
  ///
  /// In en, this message translates to:
  /// **'Add New Client'**
  String get addNewClient;

  /// UI text: Edit Client
  ///
  /// In en, this message translates to:
  /// **'Edit Client'**
  String get editClient;

  /// UI text: Save details for fast invoicing
  ///
  /// In en, this message translates to:
  /// **'Save details for fast invoicing'**
  String get saveDetailsForFastInvoicing;

  /// UI text: Update client information
  ///
  /// In en, this message translates to:
  /// **'Update client information'**
  String get updateClientInformation;

  /// UI text: Client Name *
  ///
  /// In en, this message translates to:
  /// **'Client Name *'**
  String get clientName;

  /// UI text: John Doe / Acme Corp
  ///
  /// In en, this message translates to:
  /// **'John Doe / Acme Corp'**
  String get johnDoeAcmeCorp;

  /// UI text: Required
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get required;

  /// UI text: Email
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// UI text: Phone
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// UI text: Address
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// UI text: 123 Main St, City
  ///
  /// In en, this message translates to:
  /// **'123 Main St, City'**
  String get label123MainStCity;

  /// UI text: Add Client
  ///
  /// In en, this message translates to:
  /// **'Add Client'**
  String get addClient;

  /// UI text: Save Changes
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// UI text: Could not save the client. Please try again.
  ///
  /// In en, this message translates to:
  /// **'Could not save the client. Please try again.'**
  String get couldNotSaveTheClientPleaseTryAgain;

  /// UI text: Delete Client?
  ///
  /// In en, this message translates to:
  /// **'Delete Client?'**
  String get deleteClient;

  /// UI text: Delete "{clientName}"? Their invoices and estimates keep the client details. This cannot be undone.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{clientName}\"? Their invoices and estimates keep the client details. This cannot be undone.'**
  String deleteTheirInvoicesAndEstimatesKeepTheClient(String clientName);

  /// UI text: Clients
  ///
  /// In en, this message translates to:
  /// **'Clients'**
  String get clients;

  /// UI text: Who you bill
  ///
  /// In en, this message translates to:
  /// **'Who you bill'**
  String get whoYouBill;

  /// UI text: No Clients Yet
  ///
  /// In en, this message translates to:
  /// **'No Clients Yet'**
  String get noClientsYet;

  /// UI text: No Results
  ///
  /// In en, this message translates to:
  /// **'No Results'**
  String get noResults;

  /// UI text: Save a client once and fill their details into every invoice
  ///
  /// In en, this message translates to:
  /// **'Save a client once and fill their details into every invoice'**
  String get saveAClientOnceAndFillTheirDetails;

  /// UI text: Try a different search term
  ///
  /// In en, this message translates to:
  /// **'Try a different search term'**
  String get tryADifferentSearchTerm;

  /// UI text: Tap for history · hold to edit
  ///
  /// In en, this message translates to:
  /// **'Tap for history · hold to edit'**
  String get tapForHistoryHoldToEdit;

  /// UI text: Select Client
  ///
  /// In en, this message translates to:
  /// **'Select Client'**
  String get selectClient;

  /// UI text: Search clients...
  ///
  /// In en, this message translates to:
  /// **'Search clients...'**
  String get searchClientsHint;

  /// UI text: Add your first client to start sending invoices
  ///
  /// In en, this message translates to:
  /// **'Add your first client to start sending invoices'**
  String get addYourFirstClientToStartSendingInvoices;

  /// UI text: Invoices & balance
  ///
  /// In en, this message translates to:
  /// **'Invoices & balance'**
  String get invoicesBalance;

  /// UI text: Edit client
  ///
  /// In en, this message translates to:
  /// **'Edit client'**
  String get editClientMenu;

  /// UI text: Delete client
  ///
  /// In en, this message translates to:
  /// **'Delete client'**
  String get deleteClientMenu;

  /// UI text: Total Invoiced
  ///
  /// In en, this message translates to:
  /// **'Total Invoiced'**
  String get totalInvoiced;

  /// UI text: Paid
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get paid;

  /// UI text: Due Balance
  ///
  /// In en, this message translates to:
  /// **'Due Balance'**
  String get dueBalance;

  /// UI text: Totals are for {currencyCode} invoices only; {count} in other currencies are not included.
  ///
  /// In en, this message translates to:
  /// **'Totals are for {currencyCode} invoices only; {count} in other currencies are not included.'**
  String totalsAreForInvoicesOnlyInOtherCurrencies(
    String currencyCode,
    int count,
  );

  /// UI text: Invoices ({count})
  ///
  /// In en, this message translates to:
  /// **'Invoices ({count})'**
  String invoiceHistoryCount(int count);

  /// UI text: New Invoice
  ///
  /// In en, this message translates to:
  /// **'New Invoice'**
  String get newInvoice;

  /// UI text: No invoices created for this client yet
  ///
  /// In en, this message translates to:
  /// **'No invoices created for this client yet'**
  String get noInvoicesCreatedForThisClientYet;

  /// UI text: Settings
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// UI text: Workspace
  ///
  /// In en, this message translates to:
  /// **'Workspace'**
  String get workspace;

  /// UI text: Business Profile
  ///
  /// In en, this message translates to:
  /// **'Business Profile'**
  String get businessProfile;

  /// UI text: Name, address, bank details, logo
  ///
  /// In en, this message translates to:
  /// **'Name, address, bank details, logo'**
  String get nameAddressBankDetailsLogo;

  /// UI text: Reports
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reports;

  /// UI text: Revenue, collections, top clients & items
  ///
  /// In en, this message translates to:
  /// **'Revenue, collections, top clients & items'**
  String get revenueCollectionsTopClientsItems;

  /// UI text: Notifications for unpaid invoices
  ///
  /// In en, this message translates to:
  /// **'Notifications for unpaid invoices'**
  String get notificationsForUnpaidInvoices;

  /// UI text: Document numbering
  ///
  /// In en, this message translates to:
  /// **'Document numbering'**
  String get documentNumbering;

  /// UI text: Prefixes, digits and financial year
  ///
  /// In en, this message translates to:
  /// **'Prefixes, digits and financial year'**
  String get prefixesDigitsAndFinancialYear;

  /// UI text: Security
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get security;

  /// UI text: On · {label}
  ///
  /// In en, this message translates to:
  /// **'On · {label}'**
  String on(String label);

  /// UI text: Your Data
  ///
  /// In en, this message translates to:
  /// **'Your Data'**
  String get yourData;

  /// UI text: Export Data (JSON)
  ///
  /// In en, this message translates to:
  /// **'Export Data (JSON)'**
  String get exportDataJson;

  /// UI text: A full backup of your records, profile and settings. Keep it somewhere safe.
  ///
  /// In en, this message translates to:
  /// **'A full backup of your records, profile and settings. Keep it somewhere safe.'**
  String get aFullBackupOfYourRecordsProfileAnd;

  /// UI text: Export to CSV / Excel
  ///
  /// In en, this message translates to:
  /// **'Export to CSV / Excel'**
  String get exportToCsvExcel;

  /// UI text: Spreadsheets for invoices, line items, payments, clients & items
  ///
  /// In en, this message translates to:
  /// **'Spreadsheets for invoices, line items, payments, clients & items'**
  String get spreadsheetsForInvoicesLineItemsPaymentsClientsItems;

  /// UI text: Restore from backup
  ///
  /// In en, this message translates to:
  /// **'Restore from backup'**
  String get restoreFromBackup;

  /// UI text: Replace everything here with an exported file
  ///
  /// In en, this message translates to:
  /// **'Replace everything here with an exported file'**
  String get replaceEverythingHereWithAnExportedFile;

  /// UI text: Preferences
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferences;

  /// UI text: About & Support
  ///
  /// In en, this message translates to:
  /// **'About & Support'**
  String get aboutSupport;

  /// UI text: Rate Us on Play Store
  ///
  /// In en, this message translates to:
  /// **'Rate Us on Play Store'**
  String get rateUsOnPlayStore;

  /// UI text: Leave a rating for Invoice Maker Pro
  ///
  /// In en, this message translates to:
  /// **'Leave a rating for Invoice Maker Pro'**
  String get leaveARatingForInvoiceMakerPro;

  /// UI text: Help & Guide
  ///
  /// In en, this message translates to:
  /// **'Help & Guide'**
  String get helpGuide;

  /// UI text: Quick tips and walkthrough
  ///
  /// In en, this message translates to:
  /// **'Quick tips and walkthrough'**
  String get quickTipsAndWalkthrough;

  /// UI text: Unlimited invoices & clients, no watermark
  ///
  /// In en, this message translates to:
  /// **'Unlimited invoices & clients, no watermark'**
  String get unlimitedInvoicesClientsNoWatermark;

  /// UI text: Go Pro
  ///
  /// In en, this message translates to:
  /// **'Go Pro'**
  String get goPro;

  /// UI text: Pro Workspace Active
  ///
  /// In en, this message translates to:
  /// **'Pro Workspace Active'**
  String get proWorkspaceActive;

  /// UI text: Unlimited Invoices • Clean PDF (No Watermark)
  ///
  /// In en, this message translates to:
  /// **'Unlimited Invoices • Clean PDF (No Watermark)'**
  String get unlimitedInvoicesCleanPdfNoWatermark;

  /// UI text: Same as device
  ///
  /// In en, this message translates to:
  /// **'Same as device'**
  String get sameAsDevice;

  /// UI text: Light
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get light;

  /// UI text: Dark
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get dark;

  /// UI text: Appearance
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// UI text: Default Currency
  ///
  /// In en, this message translates to:
  /// **'Default Currency'**
  String get defaultCurrency;

  /// UI text: Default Design & Typography
  ///
  /// In en, this message translates to:
  /// **'Default Design & Typography'**
  String get defaultDesignTypography;

  /// UI text: Default invoice design
  ///
  /// In en, this message translates to:
  /// **'Default invoice design'**
  String get defaultInvoiceDesign;

  /// UI text: Custom {taxName} rate
  ///
  /// In en, this message translates to:
  /// **'Custom {taxName} rate'**
  String customRate(String taxName);

  /// UI text: Default {taxName} Rate
  ///
  /// In en, this message translates to:
  /// **'Default {taxName} Rate'**
  String defaultRate(String taxName);

  /// UI text: Edit {taxName} Rate
  ///
  /// In en, this message translates to:
  /// **'Edit {taxName} Rate'**
  String editRate(String taxName);

  /// UI text: Set the default tax rate used when you create invoices.
  ///
  /// In en, this message translates to:
  /// **'Set the default tax rate used when you create invoices.'**
  String get setTheDefaultTaxRateUsedWhenYou;

  /// UI text: {taxName} Rate (%)
  ///
  /// In en, this message translates to:
  /// **'{taxName} Rate (%)'**
  String namedTaxRatePercent(String taxName);

  /// UI text: e.g. {rate}
  ///
  /// In en, this message translates to:
  /// **'e.g. {rate}'**
  String exampleValue(String rate);

  /// UI text: Enter a valid number
  ///
  /// In en, this message translates to:
  /// **'Enter a valid number'**
  String get enterAValidNumber;

  /// UI text: Use a value between 0 and 100
  ///
  /// In en, this message translates to:
  /// **'Use a value between 0 and 100'**
  String get useAValueBetween0And100;

  /// UI text: Reset
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// UI text: Save
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// UI text: Could not export CSV files. Please try again.
  ///
  /// In en, this message translates to:
  /// **'Could not export CSV files. Please try again.'**
  String get couldNotExportCsvFilesPleaseTryAgain;

  /// UI text: Invoice Maker Pro data export ({date})
  ///
  /// In en, this message translates to:
  /// **'Invoice Maker Pro data export ({date})'**
  String invoiceMakerProDataExport(String date);

  /// UI text: Could not export your data. Please try again.
  ///
  /// In en, this message translates to:
  /// **'Could not export your data. Please try again.'**
  String get couldNotExportYourDataPleaseTryAgain;

  /// UI text: Could not open that file. Please try again.
  ///
  /// In en, this message translates to:
  /// **'Could not open that file. Please try again.'**
  String get couldNotOpenThatFilePleaseTryAgain;

  /// UI text: This file is not an Invoice Maker Pro backup.
  ///
  /// In en, this message translates to:
  /// **'This file is not an Invoice Maker Pro backup.'**
  String get thisFileIsNotAnInvoiceMakerPro;

  /// UI text:  from {date}
  ///
  /// In en, this message translates to:
  /// **' from {date}'**
  String backupDateContext(String date);

  /// UI text: Replace all data?
  ///
  /// In en, this message translates to:
  /// **'Replace all data?'**
  String get replaceAllData;

  /// UI text: This backup{date} has {secondValue}.
  ///
  /// In en, this message translates to:
  /// **'This backup{date} has {secondValue}.\n\nRestoring replaces all invoices, estimates, clients, items and your business profile on this phone. A copy of your current data is saved first, and you can share it right after.'**
  String thisBackupHasRestoringReplacesAllInvoicesEstimates(
    String date,
    String secondValue,
  );

  /// UI text: Replace
  ///
  /// In en, this message translates to:
  /// **'Replace'**
  String get replace;

  /// UI text: Backup restored.
  ///
  /// In en, this message translates to:
  /// **'Backup restored.'**
  String get backupRestored;

  /// UI text: Records restored, but some settings were not. Check your business profile.
  ///
  /// In en, this message translates to:
  /// **'Records restored, but some settings were not. Check your business profile.'**
  String get recordsRestoredButSomeSettingsWereNotCheck;

  /// UI text: Could not restore this backup. Nothing was changed.
  ///
  /// In en, this message translates to:
  /// **'Could not restore this backup. Nothing was changed.'**
  String get couldNotRestoreThisBackupNothingWasChanged;

  /// UI text: Share old data
  ///
  /// In en, this message translates to:
  /// **'Share old data'**
  String get shareOldData;

  /// UI text: Invoice Maker Pro data saved before restore
  ///
  /// In en, this message translates to:
  /// **'Invoice Maker Pro data saved before restore'**
  String get invoiceMakerProDataSavedBeforeRestore;

  /// UI text: Discard changes?
  ///
  /// In en, this message translates to:
  /// **'Discard changes?'**
  String get discardChanges;

  /// UI text: You have unsaved changes to your business profile. Leave without saving them?
  ///
  /// In en, this message translates to:
  /// **'You have unsaved changes to your business profile. Leave without saving them?'**
  String get youHaveUnsavedChangesToYourBusinessProfile;

  /// UI text: Discard
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get discard;

  /// UI text: Keep editing
  ///
  /// In en, this message translates to:
  /// **'Keep editing'**
  String get keepEditing;

  /// UI text: Please fill all required fields
  ///
  /// In en, this message translates to:
  /// **'Please fill all required fields'**
  String get pleaseFillAllRequiredFields;

  /// UI text: Business profile saved successfully!
  ///
  /// In en, this message translates to:
  /// **'Business profile saved successfully!'**
  String get businessProfileSavedSuccessfully;

  /// UI text: Could not open that image. Try another one.
  ///
  /// In en, this message translates to:
  /// **'Could not open that image. Try another one.'**
  String get couldNotOpenThatImageTryAnotherOne;

  /// UI text: Business Logo
  ///
  /// In en, this message translates to:
  /// **'Business Logo'**
  String get businessLogo;

  /// UI text: Choose from Gallery
  ///
  /// In en, this message translates to:
  /// **'Choose from Gallery'**
  String get chooseFromGallery;

  /// UI text: Select an existing PNG or JPEG image
  ///
  /// In en, this message translates to:
  /// **'Select an existing PNG or JPEG image'**
  String get selectAnExistingPngOrJpegImage;

  /// UI text: Take Photo
  ///
  /// In en, this message translates to:
  /// **'Take Photo'**
  String get takePhoto;

  /// UI text: Capture company logo using camera
  ///
  /// In en, this message translates to:
  /// **'Capture company logo using camera'**
  String get captureCompanyLogoUsingCamera;

  /// UI text: Remove Logo
  ///
  /// In en, this message translates to:
  /// **'Remove Logo'**
  String get removeLogo;

  /// UI text: Clear current logo image
  ///
  /// In en, this message translates to:
  /// **'Clear current logo image'**
  String get clearCurrentLogoImage;

  /// UI text: Could not open that signature image. Try another one.
  ///
  /// In en, this message translates to:
  /// **'Could not open that signature image. Try another one.'**
  String get couldNotOpenThatSignatureImageTryAnother;

  /// UI text: Authorized Signature
  ///
  /// In en, this message translates to:
  /// **'Authorized Signature'**
  String get authorizedSignature;

  /// UI text: Draw Signature on Screen
  ///
  /// In en, this message translates to:
  /// **'Draw Signature on Screen'**
  String get drawSignatureOnScreen;

  /// UI text: Sign smoothly with your finger or stylus
  ///
  /// In en, this message translates to:
  /// **'Sign smoothly with your finger or stylus'**
  String get signSmoothlyWithYourFingerOrStylus;

  /// UI text: Upload Image from Gallery
  ///
  /// In en, this message translates to:
  /// **'Upload Image from Gallery'**
  String get uploadImageFromGallery;

  /// UI text: PNG with transparent background recommended
  ///
  /// In en, this message translates to:
  /// **'PNG with transparent background recommended'**
  String get pngWithTransparentBackgroundRecommended;

  /// UI text: Remove Signature
  ///
  /// In en, this message translates to:
  /// **'Remove Signature'**
  String get removeSignature;

  /// UI text: Clear current signature
  ///
  /// In en, this message translates to:
  /// **'Clear current signature'**
  String get clearCurrentSignature;

  /// UI text: Branding & Identity
  ///
  /// In en, this message translates to:
  /// **'Branding & Identity'**
  String get brandingIdentity;

  /// UI text: Company Logo
  ///
  /// In en, this message translates to:
  /// **'Company Logo'**
  String get companyLogo;

  /// UI text: Tap to change
  ///
  /// In en, this message translates to:
  /// **'Tap to change'**
  String get tapToChange;

  /// UI text: Upload logo
  ///
  /// In en, this message translates to:
  /// **'Upload logo'**
  String get uploadLogo;

  /// UI text: Draw or upload
  ///
  /// In en, this message translates to:
  /// **'Draw or upload'**
  String get drawOrUpload;

  /// UI text: Business / Company Name *
  ///
  /// In en, this message translates to:
  /// **'Business / Company Name *'**
  String get businessCompanyName;

  /// UI text: e.g. Acme Innovations LLC
  ///
  /// In en, this message translates to:
  /// **'e.g. Acme Innovations LLC'**
  String get eGAcmeInnovationsLlc;

  /// UI text: Business name is required
  ///
  /// In en, this message translates to:
  /// **'Business name is required'**
  String get businessNameIsRequired;

  /// UI text: Tagline or Industry (Optional)
  ///
  /// In en, this message translates to:
  /// **'Tagline or Industry (Optional)'**
  String get taglineOrIndustryOptional;

  /// UI text: e.g. Creative Studio & Digital Agency
  ///
  /// In en, this message translates to:
  /// **'e.g. Creative Studio & Digital Agency'**
  String get eGCreativeStudioDigitalAgency;

  /// UI text: Contact & Location
  ///
  /// In en, this message translates to:
  /// **'Contact & Location'**
  String get contactLocation;

  /// UI text: Business Email
  ///
  /// In en, this message translates to:
  /// **'Business Email'**
  String get businessEmail;

  /// UI text: Phone Number
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// UI text: Website / Portfolio
  ///
  /// In en, this message translates to:
  /// **'Website / Portfolio'**
  String get websitePortfolio;

  /// UI text: Registered Business Address
  ///
  /// In en, this message translates to:
  /// **'Registered Business Address'**
  String get registeredBusinessAddress;

  /// UI text: Suite 400, 100 Main Street, City, State, ZIP
  ///
  /// In en, this message translates to:
  /// **'Suite 400, 100 Main Street, City, State, ZIP'**
  String get suite400100MainStreetCityStateZip;

  /// UI text: Tax & Legal Registration
  ///
  /// In en, this message translates to:
  /// **'Tax & Legal Registration'**
  String get taxLegalRegistration;

  /// UI text: This {taxIdLabel} will be displayed on all generated PDFs and estimates for {country}.
  ///
  /// In en, this message translates to:
  /// **'This {taxIdLabel} will be displayed on all generated PDFs and estimates for {country}.'**
  String thisWillBeDisplayedOnAllGeneratedPdfs(
    String taxIdLabel,
    String country,
  );

  /// UI text: Bank & Payment Details
  ///
  /// In en, this message translates to:
  /// **'Bank & Payment Details'**
  String get bankPaymentDetails;

  /// UI text: Payment fields & routing format match {country} ({secondValue}) standards.
  ///
  /// In en, this message translates to:
  /// **'Payment fields & routing format match {country} ({secondValue}) standards.'**
  String paymentFieldsRoutingFormatMatchStandards(
    String country,
    String secondValue,
  );

  /// UI text: Bank Name
  ///
  /// In en, this message translates to:
  /// **'Bank Name'**
  String get bankName;

  /// UI text: {digitalPaymentLabel} (Optional)
  ///
  /// In en, this message translates to:
  /// **'{digitalPaymentLabel} (Optional)'**
  String optionalFieldTitle(String digitalPaymentLabel);

  /// UI text: Default Payment Notes & Terms
  ///
  /// In en, this message translates to:
  /// **'Default Payment Notes & Terms'**
  String get defaultPaymentNotesTerms;

  /// UI text: e.g. Net 15. Payment is due within 15 days of invoice date.
  ///
  /// In en, this message translates to:
  /// **'e.g. Net 15. Payment is due within 15 days of invoice date.'**
  String get eGNet15PaymentIsDueWithin;

  /// UI text: Save Business Profile
  ///
  /// In en, this message translates to:
  /// **'Save Business Profile'**
  String get saveBusinessProfile;

  /// UI text: Your Business Name
  ///
  /// In en, this message translates to:
  /// **'Your Business Name'**
  String get yourBusinessName;

  /// UI text: Set your business identity
  ///
  /// In en, this message translates to:
  /// **'Set your business identity'**
  String get setYourBusinessIdentity;

  /// UI text: Signed
  ///
  /// In en, this message translates to:
  /// **'Signed'**
  String get signed;

  /// UI text: Profile Readiness
  ///
  /// In en, this message translates to:
  /// **'Profile Readiness'**
  String get profileReadiness;

  /// UI text: Use letters, digits, hyphens or slashes.
  ///
  /// In en, this message translates to:
  /// **'Use letters, digits, hyphens or slashes.'**
  String get useLettersDigitsHyphensOrSlashes;

  /// UI text: Enter a number from 3 to 8.
  ///
  /// In en, this message translates to:
  /// **'Enter a number from 3 to 8.'**
  String get enterANumberFrom3To8;

  /// UI text: Enter a positive whole number.
  ///
  /// In en, this message translates to:
  /// **'Enter a positive whole number.'**
  String get enterAPositiveWholeNumber;

  /// UI text: Could not save document settings. Please try again.
  ///
  /// In en, this message translates to:
  /// **'Could not save document settings. Please try again.'**
  String get couldNotSaveDocumentSettingsPleaseTryAgain;

  /// UI text: Could not load document settings.
  ///
  /// In en, this message translates to:
  /// **'Could not load document settings.'**
  String get couldNotLoadDocumentSettings;

  /// UI text: Invoice prefix
  ///
  /// In en, this message translates to:
  /// **'Invoice prefix'**
  String get invoicePrefix;

  /// UI text: Estimate prefix
  ///
  /// In en, this message translates to:
  /// **'Estimate prefix'**
  String get estimatePrefix;

  /// UI text: Number of digits
  ///
  /// In en, this message translates to:
  /// **'Number of digits'**
  String get numberOfDigits;

  /// UI text: Start invoice numbers from
  ///
  /// In en, this message translates to:
  /// **'Start invoice numbers from'**
  String get startInvoiceNumbersFrom;

  /// UI text: Start estimate numbers from
  ///
  /// In en, this message translates to:
  /// **'Start estimate numbers from'**
  String get startEstimateNumbersFrom;

  /// UI text: Numbers continue after the highest number in the series.
  ///
  /// In en, this message translates to:
  /// **'Numbers continue after the highest number in the series.'**
  String get numbersContinueAfterTheHighestNumberInThe;

  /// UI text: Add financial year
  ///
  /// In en, this message translates to:
  /// **'Add financial year'**
  String get addFinancialYear;

  /// UI text: The Indian financial year starts on 1 April.
  ///
  /// In en, this message translates to:
  /// **'The Indian financial year starts on 1 April.'**
  String get theIndianFinancialYearStartsOn1April;

  /// UI text: Could not load the next document numbers.
  ///
  /// In en, this message translates to:
  /// **'Could not load the next document numbers.'**
  String get couldNotLoadTheNextDocumentNumbers;

  /// UI text: Next invoice: {value}
  ///
  /// In en, this message translates to:
  /// **'Next invoice: {value}'**
  String nextInvoice(String value);

  /// UI text: Next estimate: {value}
  ///
  /// In en, this message translates to:
  /// **'Next estimate: {value}'**
  String nextEstimate(String value);

  /// UI text: Draw your signature above, then save.
  ///
  /// In en, this message translates to:
  /// **'Draw your signature above, then save.'**
  String get drawYourSignatureAboveThenSave;

  /// UI text: That looks too small. Sign across the pad, then save.
  ///
  /// In en, this message translates to:
  /// **'That looks too small. Sign across the pad, then save.'**
  String get thatLooksTooSmallSignAcrossThePad;

  /// UI text: Could not save the signature. Please try again.
  ///
  /// In en, this message translates to:
  /// **'Could not save the signature. Please try again.'**
  String get couldNotSaveTheSignaturePleaseTryAgain;

  /// UI text: Draw Signature
  ///
  /// In en, this message translates to:
  /// **'Draw Signature'**
  String get drawSignature;

  /// UI text: Sign with your finger or stylus
  ///
  /// In en, this message translates to:
  /// **'Sign with your finger or stylus'**
  String get signWithYourFingerOrStylus;

  /// UI text: Draw inside this box
  ///
  /// In en, this message translates to:
  /// **'Draw inside this box'**
  String get drawInsideThisBox;

  /// UI text: Authorized Signatory
  ///
  /// In en, this message translates to:
  /// **'Authorized Signatory'**
  String get authorizedSignatory;

  /// UI text: Undo stroke
  ///
  /// In en, this message translates to:
  /// **'Undo stroke'**
  String get undoStroke;

  /// UI text: Clear canvas
  ///
  /// In en, this message translates to:
  /// **'Clear canvas'**
  String get clearCanvas;

  /// UI text: Use Signature
  ///
  /// In en, this message translates to:
  /// **'Use Signature'**
  String get useSignature;

  /// UI text: Invoice Design Studio
  ///
  /// In en, this message translates to:
  /// **'Invoice Design Studio'**
  String get invoiceDesignStudio;

  /// UI text: Change Invoice Status
  ///
  /// In en, this message translates to:
  /// **'Change Invoice Status'**
  String get changeInvoiceStatus;

  /// UI text: Invoice {invoiceNumber}
  ///
  /// In en, this message translates to:
  /// **'Invoice {invoiceNumber}'**
  String invoiceWithNumber(String invoiceNumber);

  /// UI text: Unpaid
  ///
  /// In en, this message translates to:
  /// **'Unpaid'**
  String get unpaid;

  /// UI text: Deletes recorded payments
  ///
  /// In en, this message translates to:
  /// **'Deletes recorded payments'**
  String get deletesRecordedPayments;

  /// UI text: Record a payment
  ///
  /// In en, this message translates to:
  /// **'Record a payment'**
  String get recordAPayment;

  /// UI text: Add a deposit or part payment
  ///
  /// In en, this message translates to:
  /// **'Add a deposit or part payment'**
  String get addADepositOrPartPayment;

  /// UI text: Paid in Full
  ///
  /// In en, this message translates to:
  /// **'Paid in Full'**
  String get paidInFull;

  /// UI text: Payment received successfully
  ///
  /// In en, this message translates to:
  /// **'Payment received successfully'**
  String get paymentReceivedSuccessfully;

  /// UI text: Could not open the receipt.
  ///
  /// In en, this message translates to:
  /// **'Could not open the receipt.'**
  String get couldNotOpenTheReceipt;

  /// UI text: More Actions
  ///
  /// In en, this message translates to:
  /// **'More Actions'**
  String get moreActions;

  /// UI text: Change Design
  ///
  /// In en, this message translates to:
  /// **'Change Design'**
  String get changeDesign;

  /// UI text: {value} · typography, colours & layout
  ///
  /// In en, this message translates to:
  /// **'{value} · typography, colours & layout'**
  String designThemeSummary(String value);

  /// UI text: Duplicate Invoice
  ///
  /// In en, this message translates to:
  /// **'Duplicate Invoice'**
  String get duplicateInvoice;

  /// UI text: Create a new copy with same items
  ///
  /// In en, this message translates to:
  /// **'Create a new copy with same items'**
  String get createANewCopyWithSameItems;

  /// UI text: Mark as Unpaid
  ///
  /// In en, this message translates to:
  /// **'Mark as Unpaid'**
  String get markAsUnpaid;

  /// UI text: Mark as Paid
  ///
  /// In en, this message translates to:
  /// **'Mark as Paid'**
  String get markAsPaid;

  /// UI text: Deletes the recorded payments
  ///
  /// In en, this message translates to:
  /// **'Deletes the recorded payments'**
  String get deletesTheRecordedPayments;

  /// UI text: Records a payment for the balance
  ///
  /// In en, this message translates to:
  /// **'Records a payment for the balance'**
  String get recordsAPaymentForTheBalance;

  /// UI text: Payments
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get payments;

  /// UI text: See, record or delete payments
  ///
  /// In en, this message translates to:
  /// **'See, record or delete payments'**
  String get seeRecordOrDeletePayments;

  /// UI text: Edit and share a payment reminder with your client
  ///
  /// In en, this message translates to:
  /// **'Edit and share a payment reminder with your client'**
  String get editAndShareAPaymentReminderWithYour;

  /// UI text: Receipt
  ///
  /// In en, this message translates to:
  /// **'Receipt'**
  String get receipt;

  /// UI text: Preview a receipt for all recorded payments
  ///
  /// In en, this message translates to:
  /// **'Preview a receipt for all recorded payments'**
  String get previewAReceiptForAllRecordedPayments;

  /// UI text: Delete Invoice
  ///
  /// In en, this message translates to:
  /// **'Delete Invoice'**
  String get deleteInvoice;

  /// UI text: Permanently remove this invoice
  ///
  /// In en, this message translates to:
  /// **'Permanently remove this invoice'**
  String get permanentlyRemoveThisInvoice;

  /// UI text: Duplicated as {invoiceNumber}, dated today and unpaid
  ///
  /// In en, this message translates to:
  /// **'Duplicated as {invoiceNumber}, dated today and unpaid'**
  String duplicatedAsDatedTodayAndUnpaid(String invoiceNumber);

  /// UI text: Could not duplicate the invoice. Please try again.
  ///
  /// In en, this message translates to:
  /// **'Could not duplicate the invoice. Please try again.'**
  String get couldNotDuplicateTheInvoicePleaseTryAgain;

  /// UI text: Design
  ///
  /// In en, this message translates to:
  /// **'Design'**
  String get design;

  /// UI text: Due {date} • {clientName}
  ///
  /// In en, this message translates to:
  /// **'Due {date} • {clientName}'**
  String dueDateAndClient(String date, String clientName);

  /// UI text: Send Invoice
  ///
  /// In en, this message translates to:
  /// **'Send Invoice'**
  String get sendInvoice;

  /// UI text: Expand details
  ///
  /// In en, this message translates to:
  /// **'Expand details'**
  String get expandDetails;

  /// UI text: {clientName}  ·  Due {date}
  ///
  /// In en, this message translates to:
  /// **'{clientName}  ·  Due {date}'**
  String clientAndDueDate(String clientName, String date);

  /// UI text: Tap to mark as not sent
  ///
  /// In en, this message translates to:
  /// **'Tap to mark as not sent'**
  String get tapToMarkAsNotSent;

  /// UI text: Tap to mark as sent
  ///
  /// In en, this message translates to:
  /// **'Tap to mark as sent'**
  String get tapToMarkAsSent;

  /// UI text: Sent
  ///
  /// In en, this message translates to:
  /// **'Sent'**
  String get sent;

  /// UI text: Not sent
  ///
  /// In en, this message translates to:
  /// **'Not sent'**
  String get notSent;

  /// UI text: Paid: {amount}
  ///
  /// In en, this message translates to:
  /// **'Paid: {amount}'**
  String paidAmountLabel(String amount);

  /// UI text: Balance Due: {amount}
  ///
  /// In en, this message translates to:
  /// **'Balance Due: {amount}'**
  String balanceDue(String amount);

  /// UI text: Download
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get download;

  /// UI text: Print
  ///
  /// In en, this message translates to:
  /// **'Print'**
  String get print;

  /// UI text: Edit
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// UI text: More
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get more;

  /// UI text: Camera
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get camera;

  /// UI text: Gallery
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get gallery;

  /// UI text: Could not add the photo. Please try again.
  ///
  /// In en, this message translates to:
  /// **'Could not add the photo. Please try again.'**
  String get couldNotAddThePhotoPleaseTryAgain;

  /// UI text: Photo unavailable
  ///
  /// In en, this message translates to:
  /// **'Photo unavailable'**
  String get photoUnavailable;

  /// UI text: Attachments
  ///
  /// In en, this message translates to:
  /// **'Attachments'**
  String get attachments;

  /// UI text: Add attachment
  ///
  /// In en, this message translates to:
  /// **'Add attachment'**
  String get addAttachment;

  /// UI text: Please add a client name (Bill To).
  ///
  /// In en, this message translates to:
  /// **'Please add a client name (Bill To).'**
  String get pleaseAddAClientNameBillTo;

  /// UI text: Please add at least one line item.
  ///
  /// In en, this message translates to:
  /// **'Please add at least one line item.'**
  String get pleaseAddAtLeastOneLineItem;

  /// UI text: Invoice number {value} is already used. Pick another number.
  ///
  /// In en, this message translates to:
  /// **'Invoice number {value} is already used. Pick another number.'**
  String invoiceNumberIsAlreadyUsedPickAnotherNumber(String value);

  /// UI text: Could not save the invoice. Please try again.
  ///
  /// In en, this message translates to:
  /// **'Could not save the invoice. Please try again.'**
  String get couldNotSaveTheInvoicePleaseTryAgain;

  /// UI text: Invoice Details & Dates
  ///
  /// In en, this message translates to:
  /// **'Invoice Details & Dates'**
  String get invoiceDetailsDates;

  /// UI text: Invoice Number
  ///
  /// In en, this message translates to:
  /// **'Invoice Number'**
  String get invoiceNumber;

  /// UI text: e.g. INV00001
  ///
  /// In en, this message translates to:
  /// **'e.g. INV00001'**
  String get eGInv00001;

  /// UI text: Invoice Issue Date
  ///
  /// In en, this message translates to:
  /// **'Invoice Issue Date'**
  String get invoiceIssueDate;

  /// UI text: Payment Terms & Due Date
  ///
  /// In en, this message translates to:
  /// **'Payment Terms & Due Date'**
  String get paymentTermsDueDate;

  /// UI text: Optional credit period for payment
  ///
  /// In en, this message translates to:
  /// **'Optional credit period for payment'**
  String get optionalCreditPeriodForPayment;

  /// UI text: No Due Date
  ///
  /// In en, this message translates to:
  /// **'No Due Date'**
  String get noDueDate;

  /// UI text: Due on Receipt
  ///
  /// In en, this message translates to:
  /// **'Due on Receipt'**
  String get dueOnReceipt;

  /// UI text: +7 Days
  ///
  /// In en, this message translates to:
  /// **'+7 Days'**
  String get label7Days;

  /// UI text: +15 Days
  ///
  /// In en, this message translates to:
  /// **'+15 Days'**
  String get label15Days;

  /// UI text: +30 Days
  ///
  /// In en, this message translates to:
  /// **'+30 Days'**
  String get label30Days;

  /// UI text: Custom Date...
  ///
  /// In en, this message translates to:
  /// **'Custom Date...'**
  String get customDate;

  /// UI text: Apply Changes
  ///
  /// In en, this message translates to:
  /// **'Apply Changes'**
  String get applyChanges;

  /// UI text: Bill From (Your Business)
  ///
  /// In en, this message translates to:
  /// **'Bill From (Your Business)'**
  String get billFromYourBusiness;

  /// UI text: Business Name *
  ///
  /// In en, this message translates to:
  /// **'Business Name *'**
  String get businessName;

  /// UI text: Save Business Info
  ///
  /// In en, this message translates to:
  /// **'Save Business Info'**
  String get saveBusinessInfo;

  /// UI text: Edit Item
  ///
  /// In en, this message translates to:
  /// **'Edit Item'**
  String get editItem;

  /// UI text: Add Item
  ///
  /// In en, this message translates to:
  /// **'Add Item'**
  String get addItem;

  /// UI text: Description *
  ///
  /// In en, this message translates to:
  /// **'Description *'**
  String get description;

  /// UI text: e.g. Consulting, Design, Product
  ///
  /// In en, this message translates to:
  /// **'e.g. Consulting, Design, Product'**
  String get eGConsultingDesignProduct;

  /// UI text: Quantity
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get quantity;

  /// UI text: Unit Price
  ///
  /// In en, this message translates to:
  /// **'Unit Price'**
  String get unitPrice;

  /// UI text: Hide Item Discount & Tax
  ///
  /// In en, this message translates to:
  /// **'Hide Item Discount & Tax'**
  String get hideItemDiscountTax;

  /// UI text: + Add Item Discount & Tax
  ///
  /// In en, this message translates to:
  /// **'+ Add Item Discount & Tax'**
  String get addItemDiscountTax;

  /// UI text: Discount (%)
  ///
  /// In en, this message translates to:
  /// **'Discount (%)'**
  String get discountRequiredAmountLabel;

  /// UI text: Tax Rate (%)
  ///
  /// In en, this message translates to:
  /// **'Tax Rate (%)'**
  String get taxRate;

  /// UI text: Invoice rate
  ///
  /// In en, this message translates to:
  /// **'Invoice rate'**
  String get invoiceRate;

  /// UI text: Base Amount:
  ///
  /// In en, this message translates to:
  /// **'Base Amount:'**
  String get baseAmount;

  /// UI text: Discount ({rate}%):
  ///
  /// In en, this message translates to:
  /// **'Discount ({rate}%):'**
  String discountPercentLabel(String rate);

  /// UI text: Tax at {rate}% (added in totals):
  ///
  /// In en, this message translates to:
  /// **'Tax at {rate}% (added in totals):'**
  String taxAtAddedInTotals(String rate);

  /// UI text: Line amount (before tax):
  ///
  /// In en, this message translates to:
  /// **'Line amount (before tax):'**
  String get lineAmountBeforeTax;

  /// UI text: Please enter an item description
  ///
  /// In en, this message translates to:
  /// **'Please enter an item description'**
  String get pleaseEnterAnItemDescription;

  /// UI text: Quantity must be more than 0
  ///
  /// In en, this message translates to:
  /// **'Quantity must be more than 0'**
  String get quantityMustBeMoreThan0;

  /// UI text: Update Item
  ///
  /// In en, this message translates to:
  /// **'Update Item'**
  String get updateItem;

  /// UI text: Add to Invoice
  ///
  /// In en, this message translates to:
  /// **'Add to Invoice'**
  String get addToInvoice;

  /// UI text: Add Discount
  ///
  /// In en, this message translates to:
  /// **'Add Discount'**
  String get addDiscount;

  /// UI text: Percentage (%)
  ///
  /// In en, this message translates to:
  /// **'Percentage (%)'**
  String get percentage;

  /// UI text: Flat Amount ({currencySymbol})
  ///
  /// In en, this message translates to:
  /// **'Flat Amount ({currencySymbol})'**
  String flatAmount(String currencySymbol);

  /// UI text: Discount Percentage (%)
  ///
  /// In en, this message translates to:
  /// **'Discount Percentage (%)'**
  String get discountPercentage;

  /// UI text: Discount Amount
  ///
  /// In en, this message translates to:
  /// **'Discount Amount'**
  String get discountAmount;

  /// UI text: Apply Discount
  ///
  /// In en, this message translates to:
  /// **'Apply Discount'**
  String get applyDiscount;

  /// UI text: {taxName} Configuration
  ///
  /// In en, this message translates to:
  /// **'{taxName} Configuration'**
  String configureNamedTax(String taxName);

  /// UI text: Choose CGST + SGST (intra-state) or IGST (inter-state)
  ///
  /// In en, this message translates to:
  /// **'Choose CGST + SGST (intra-state) or IGST (inter-state)'**
  String get chooseCgstSgstIntraStateOrIgstInter;

  /// UI text: Set {taxName} percentage to apply to this invoice.
  ///
  /// In en, this message translates to:
  /// **'Set {taxName} percentage to apply to this invoice.'**
  String setPercentageToApplyToThisInvoice(String taxName);

  /// UI text: No Tax (0%)
  ///
  /// In en, this message translates to:
  /// **'No Tax (0%)'**
  String get noTax0;

  /// UI text: IGST (Single)
  ///
  /// In en, this message translates to:
  /// **'IGST (Single)'**
  String get igstSingle;

  /// UI text: IGST Rate (%)
  ///
  /// In en, this message translates to:
  /// **'IGST Rate (%)'**
  String get igstRate;

  /// UI text: Remove Tax
  ///
  /// In en, this message translates to:
  /// **'Remove Tax'**
  String get removeTax;

  /// UI text: Apply Tax
  ///
  /// In en, this message translates to:
  /// **'Apply Tax'**
  String get applyTax;

  /// UI text: Shipping Charges
  ///
  /// In en, this message translates to:
  /// **'Shipping Charges'**
  String get shippingCharges;

  /// UI text: Shipping Fee ({currencySymbol})
  ///
  /// In en, this message translates to:
  /// **'Shipping Fee ({currencySymbol})'**
  String shippingFee(String currencySymbol);

  /// UI text: Save Shipping Fee
  ///
  /// In en, this message translates to:
  /// **'Save Shipping Fee'**
  String get saveShippingFee;

  /// UI text: Amount already received
  ///
  /// In en, this message translates to:
  /// **'Amount already received'**
  String get amountAlreadyReceived;

  /// UI text: Amount Paid ({currencySymbol})
  ///
  /// In en, this message translates to:
  /// **'Amount Paid ({currencySymbol})'**
  String amountPaid(String currencySymbol);

  /// UI text: Select Payment Method
  ///
  /// In en, this message translates to:
  /// **'Select Payment Method'**
  String get selectPaymentMethod;

  /// UI text: Terms & Notes
  ///
  /// In en, this message translates to:
  /// **'Terms & Notes'**
  String get termsNotes;

  /// UI text: Terms / Notes
  ///
  /// In en, this message translates to:
  /// **'Terms / Notes'**
  String get termsSlashNotes;

  /// UI text: e.g. Thanks for your business.
  ///
  /// In en, this message translates to:
  /// **'e.g. Thanks for your business.'**
  String get eGThanksForYourBusiness;

  /// UI text: Save Notes
  ///
  /// In en, this message translates to:
  /// **'Save Notes'**
  String get saveNotes;

  /// UI text: Mark Invoice As
  ///
  /// In en, this message translates to:
  /// **'Mark Invoice As'**
  String get markInvoiceAs;

  /// UI text: Delete Invoice?
  ///
  /// In en, this message translates to:
  /// **'Delete Invoice?'**
  String get deleteInvoiceQuestion;

  /// UI text: Are you sure you want to delete this invoice? This action cannot be undone.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this invoice? This action cannot be undone.'**
  String get areYouSureYouWantToDeleteThis;

  /// UI text: You have unsaved changes. Leave without saving them?
  ///
  /// In en, this message translates to:
  /// **'You have unsaved changes. Leave without saving them?'**
  String get youHaveUnsavedChangesLeaveWithoutSavingThem;

  /// UI text: Add Clients
  ///
  /// In en, this message translates to:
  /// **'Add Clients'**
  String get addClients;

  /// UI text: Edit Invoice
  ///
  /// In en, this message translates to:
  /// **'Edit Invoice'**
  String get editInvoice;

  /// UI text: Create Invoice
  ///
  /// In en, this message translates to:
  /// **'Create Invoice'**
  String get createInvoice;

  /// UI text: Clear Items
  ///
  /// In en, this message translates to:
  /// **'Clear Items'**
  String get clearItems;

  /// UI text: Reset Helpful Tips
  ///
  /// In en, this message translates to:
  /// **'Reset Helpful Tips'**
  String get resetHelpfulTips;

  /// UI text: INVOICE
  ///
  /// In en, this message translates to:
  /// **'INVOICE'**
  String get invoiceHeading;

  /// UI text: Due {date}
  ///
  /// In en, this message translates to:
  /// **'Due {date}'**
  String dueDateLabel(String date);

  /// UI text: Templates
  ///
  /// In en, this message translates to:
  /// **'Templates'**
  String get templates;

  /// UI text: Choose style & paper design
  ///
  /// In en, this message translates to:
  /// **'Choose style & paper design'**
  String get chooseStylePaperDesign;

  /// UI text: Bill From
  ///
  /// In en, this message translates to:
  /// **'Bill From'**
  String get billFrom;

  /// UI text: Add Business
  ///
  /// In en, this message translates to:
  /// **'Add Business'**
  String get addBusiness;

  /// UI text: Bill To
  ///
  /// In en, this message translates to:
  /// **'Bill To'**
  String get billTo;

  /// UI text: Add your client or customer
  ///
  /// In en, this message translates to:
  /// **'Add your client or customer'**
  String get addYourClientOrCustomer;

  /// UI text: Select an existing client or create a new one to bill
  ///
  /// In en, this message translates to:
  /// **'Select an existing client or create a new one to bill'**
  String get selectAnExistingClientOrCreateANew;

  /// UI text: Items
  ///
  /// In en, this message translates to:
  /// **'Items'**
  String get items;

  /// UI text: Add Items
  ///
  /// In en, this message translates to:
  /// **'Add Items'**
  String get addItems;

  /// UI text: Create your item or service
  ///
  /// In en, this message translates to:
  /// **'Create your item or service'**
  String get createYourItemOrService;

  /// UI text: Add name, price, quantity and details
  ///
  /// In en, this message translates to:
  /// **'Add name, price, quantity and details'**
  String get addNamePriceQuantityAndDetails;

  /// UI text: Discount
  ///
  /// In en, this message translates to:
  /// **'Discount'**
  String get discount;

  /// UI text: Shipping
  ///
  /// In en, this message translates to:
  /// **'Shipping'**
  String get shipping;

  /// UI text: Total
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// UI text: Configure discount, tax or shipping
  ///
  /// In en, this message translates to:
  /// **'Configure discount, tax or shipping'**
  String get configureDiscountTaxOrShipping;

  /// UI text: Apply {taxName} rates, discounts or shipping charges
  ///
  /// In en, this message translates to:
  /// **'Apply {taxName} rates, discounts or shipping charges'**
  String applyRatesDiscountsOrShippingCharges(String taxName);

  /// UI text: Balance Due
  ///
  /// In en, this message translates to:
  /// **'Balance Due'**
  String get balanceDueHeading;

  /// UI text: Currency
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get currency;

  /// UI text: Payment Method
  ///
  /// In en, this message translates to:
  /// **'Payment Method'**
  String get paymentMethod;

  /// UI text: Signature
  ///
  /// In en, this message translates to:
  /// **'Signature'**
  String get signature;

  /// UI text: Signature Attached
  ///
  /// In en, this message translates to:
  /// **'Signature Attached'**
  String get signatureAttached;

  /// UI text: Add Signature
  ///
  /// In en, this message translates to:
  /// **'Add Signature'**
  String get addSignature;

  /// UI text: Terms Or Notes
  ///
  /// In en, this message translates to:
  /// **'Terms or notes'**
  String get termsOrNotes;

  /// UI text: Thanks for your business.
  ///
  /// In en, this message translates to:
  /// **'Thanks for your business.'**
  String get thanksForYourBusiness;

  /// UI text: Set payment method & signature
  ///
  /// In en, this message translates to:
  /// **'Set payment method & signature'**
  String get setPaymentMethodSignature;

  /// UI text: Add UPI, bank details, notes or your signature
  ///
  /// In en, this message translates to:
  /// **'Add UPI, bank details, notes or your signature'**
  String get addUpiBankDetailsNotesOrYourSignature;

  /// UI text: Mark as
  ///
  /// In en, this message translates to:
  /// **'Mark as'**
  String get markAs;

  /// UI text: Preview
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get preview;

  /// UI text: Invoice {invoiceNumber} for {clientName}
  ///
  /// In en, this message translates to:
  /// **'Invoice {invoiceNumber} for {clientName}'**
  String invoiceFor(String invoiceNumber, String clientName);

  /// UI text: Mark as sent?
  ///
  /// In en, this message translates to:
  /// **'Mark as sent?'**
  String get markAsSent;

  /// UI text: Did you send {invoiceNumber} to {clientName}?
  ///
  /// In en, this message translates to:
  /// **'Did you send {invoiceNumber} to {clientName}?'**
  String didYouSendTo(String invoiceNumber, String clientName);

  /// UI text: Not yet
  ///
  /// In en, this message translates to:
  /// **'Not yet'**
  String get notYet;

  /// UI text: Mark as sent
  ///
  /// In en, this message translates to:
  /// **'Mark as sent'**
  String get markAsSentAction;

  /// UI text: Could not share the invoice. Please try again.
  ///
  /// In en, this message translates to:
  /// **'Could not share the invoice. Please try again.'**
  String get couldNotShareTheInvoicePleaseTryAgain;

  /// UI text: Saved {name} to {secondValue}
  ///
  /// In en, this message translates to:
  /// **'Saved {name} to {secondValue}'**
  String savedTo(String name, String secondValue);

  /// UI text: View
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get view;

  /// UI text: No app found to open PDFs. Install a PDF viewer to open it.
  ///
  /// In en, this message translates to:
  /// **'No app found to open PDFs. Install a PDF viewer to open it.'**
  String get noAppFoundToOpenPdfsInstallA;

  /// UI text: Could not save the PDF. Please try again.
  ///
  /// In en, this message translates to:
  /// **'Could not save the PDF. Please try again.'**
  String get couldNotSaveThePdfPleaseTryAgain;

  /// UI text: Mark as unpaid?
  ///
  /// In en, this message translates to:
  /// **'Mark as unpaid?'**
  String get markUnpaidQuestion;

  /// UI text: Delete payments
  ///
  /// In en, this message translates to:
  /// **'Delete payments'**
  String get deletePayments;

  /// UI text: Could not update the payment. Please try again.
  ///
  /// In en, this message translates to:
  /// **'Could not update the payment. Please try again.'**
  String get couldNotUpdateThePaymentPleaseTryAgain;

  /// UI text: Could not open printing. Please try again.
  ///
  /// In en, this message translates to:
  /// **'Could not open printing. Please try again.'**
  String get couldNotOpenPrintingPleaseTryAgain;

  /// UI text: Delete {invoiceNumber}? This cannot be undone.
  ///
  /// In en, this message translates to:
  /// **'Delete {invoiceNumber}? This cannot be undone.'**
  String deleteThisCannotBeUndone(String invoiceNumber);

  /// UI text: Could not delete the invoice. Please try again.
  ///
  /// In en, this message translates to:
  /// **'Could not delete the invoice. Please try again.'**
  String get couldNotDeleteTheInvoicePleaseTryAgain;

  /// UI text: Payment recorded
  ///
  /// In en, this message translates to:
  /// **'Payment recorded'**
  String get paymentRecorded;

  /// UI text: Send receipt
  ///
  /// In en, this message translates to:
  /// **'Send receipt'**
  String get sendReceipt;

  /// UI text: Delete payment?
  ///
  /// In en, this message translates to:
  /// **'Delete payment?'**
  String get deletePayment;

  /// UI text: Delete the {amount} payment from {date}?
  ///
  /// In en, this message translates to:
  /// **'Delete the {amount} payment from {date}?'**
  String deleteThePaymentFrom(String amount, String date);

  /// UI text: Invoice {invoiceNumber} · Total {amount}
  ///
  /// In en, this message translates to:
  /// **'Invoice {invoiceNumber} · Total {amount}'**
  String invoiceTotal(String invoiceNumber, String amount);

  /// UI text: Received
  ///
  /// In en, this message translates to:
  /// **'Received'**
  String get received;

  /// UI text: Overpaid by
  ///
  /// In en, this message translates to:
  /// **'Overpaid by'**
  String get overpaidBy;

  /// UI text: Balance due
  ///
  /// In en, this message translates to:
  /// **'Balance due'**
  String get balanceDueLabel;

  /// UI text: No payments recorded yet.
  ///
  /// In en, this message translates to:
  /// **'No payments recorded yet.'**
  String get noPaymentsRecordedYet;

  /// UI text: Delete payment
  ///
  /// In en, this message translates to:
  /// **'Delete payment'**
  String get deletePayment2;

  /// UI text: Record payment
  ///
  /// In en, this message translates to:
  /// **'Record payment'**
  String get recordPayment;

  /// UI text: Amount received
  ///
  /// In en, this message translates to:
  /// **'Amount received'**
  String get amountReceived;

  /// UI text: Enter an amount above 0
  ///
  /// In en, this message translates to:
  /// **'Enter an amount above 0'**
  String get enterAnAmountAbove0;

  /// UI text: Balance due: {amount}
  ///
  /// In en, this message translates to:
  /// **'Balance due: {amount}'**
  String remainingAmountLabel(String amount);

  /// UI text: Date received
  ///
  /// In en, this message translates to:
  /// **'Date received'**
  String get dateReceived;

  /// UI text: Note (optional)
  ///
  /// In en, this message translates to:
  /// **'Note (optional)'**
  String get noteOptional;

  /// UI text: Save payment
  ///
  /// In en, this message translates to:
  /// **'Save payment'**
  String get savePayment;

  /// UI text: Live preview updates instantly
  ///
  /// In en, this message translates to:
  /// **'Live preview updates instantly'**
  String get livePreviewUpdatesInstantly;

  /// UI text: Updating...
  ///
  /// In en, this message translates to:
  /// **'Updating...'**
  String get updating;

  /// UI text: Quick Look
  ///
  /// In en, this message translates to:
  /// **'Quick Look'**
  String get quickLook;

  /// UI text: Fit
  ///
  /// In en, this message translates to:
  /// **'Fit'**
  String get fit;

  /// UI text: Style
  ///
  /// In en, this message translates to:
  /// **'Style'**
  String get style;

  /// UI text: Typo
  ///
  /// In en, this message translates to:
  /// **'Typo'**
  String get typo;

  /// UI text: Layout
  ///
  /// In en, this message translates to:
  /// **'Layout'**
  String get layout;

  /// UI text: Sections
  ///
  /// In en, this message translates to:
  /// **'Sections'**
  String get sections;

  /// UI text: Set as default style for future documents
  ///
  /// In en, this message translates to:
  /// **'Set as default style for future documents'**
  String get setAsDefaultStyleForFutureDocuments;

  /// UI text: Apply & Save Style
  ///
  /// In en, this message translates to:
  /// **'Apply & Save Style'**
  String get applySaveStyle;

  /// UI text: Paper Design Template
  ///
  /// In en, this message translates to:
  /// **'Paper Design Template'**
  String get paperDesignTemplate;

  /// UI text: Color Palette Presets
  ///
  /// In en, this message translates to:
  /// **'Color Palette Presets'**
  String get colorPalettePresets;

  /// UI text: Font Family
  ///
  /// In en, this message translates to:
  /// **'Font Family'**
  String get fontFamily;

  /// UI text: Document Density & Sizing
  ///
  /// In en, this message translates to:
  /// **'Document Density & Sizing'**
  String get documentDensitySizing;

  /// UI text: 85% Scale
  ///
  /// In en, this message translates to:
  /// **'85% Scale'**
  String get label85Scale;

  /// UI text: 100% Normal
  ///
  /// In en, this message translates to:
  /// **'100% Normal'**
  String get label100Normal;

  /// UI text: 115% Large
  ///
  /// In en, this message translates to:
  /// **'115% Large'**
  String get label115Large;

  /// UI text: Header Alignment & Position
  ///
  /// In en, this message translates to:
  /// **'Header Alignment & Position'**
  String get headerAlignmentPosition;

  /// UI text: Address Block Arrangement
  ///
  /// In en, this message translates to:
  /// **'Address Block Arrangement'**
  String get addressBlockArrangement;

  /// UI text: Document Sections Visibility
  ///
  /// In en, this message translates to:
  /// **'Document Sections Visibility'**
  String get documentSectionsVisibility;

  /// UI text: Bank Payment Details
  ///
  /// In en, this message translates to:
  /// **'Bank Payment Details'**
  String get bankPaymentDetails2;

  /// UI text: Bank name, account number & routing code
  ///
  /// In en, this message translates to:
  /// **'Bank name, account number & routing code'**
  String get bankNameAccountNumberRoutingCode;

  /// UI text: Digital UPI / Payment ID
  ///
  /// In en, this message translates to:
  /// **'Digital UPI / Payment ID'**
  String get digitalUpiPaymentId;

  /// UI text: UPI ID and fast payment handle
  ///
  /// In en, this message translates to:
  /// **'UPI ID and fast payment handle'**
  String get upiIdAndFastPaymentHandle;

  /// UI text: Signature & Sign-Off
  ///
  /// In en, this message translates to:
  /// **'Signature & Sign-Off'**
  String get signatureSignOff;

  /// UI text: Authorized signature box in footer
  ///
  /// In en, this message translates to:
  /// **'Authorized signature box in footer'**
  String get authorizedSignatureBoxInFooter;

  /// UI text: Notes & Terms
  ///
  /// In en, this message translates to:
  /// **'Notes & Terms'**
  String get notesTerms;

  /// UI text: Customer notes container
  ///
  /// In en, this message translates to:
  /// **'Customer notes container'**
  String get customerNotesContainer;

  /// UI text: Table Columns
  ///
  /// In en, this message translates to:
  /// **'Table Columns'**
  String get tableColumns;

  /// UI text: Quantity (QTY) Column
  ///
  /// In en, this message translates to:
  /// **'Quantity (QTY) Column'**
  String get quantityQtyColumn;

  /// UI text: Number of units or hours
  ///
  /// In en, this message translates to:
  /// **'Number of units or hours'**
  String get numberOfUnitsOrHours;

  /// UI text: Unit Price Column
  ///
  /// In en, this message translates to:
  /// **'Unit Price Column'**
  String get unitPriceColumn;

  /// UI text: Individual item rate
  ///
  /// In en, this message translates to:
  /// **'Individual item rate'**
  String get individualItemRate;

  /// UI text: Custom Footer Closing Message
  ///
  /// In en, this message translates to:
  /// **'Custom Footer Closing Message'**
  String get customFooterClosingMessage;

  /// UI text: e.g. Thank you for your business!
  ///
  /// In en, this message translates to:
  /// **'e.g. Thank you for your business!'**
  String get eGThankYouForYourBusiness;

  /// UI text: Photos on appendix pages
  ///
  /// In en, this message translates to:
  /// **'Photos on appendix pages'**
  String get photosOnAppendixPages;

  /// UI text: Status stamp (Paid / Overdue)
  ///
  /// In en, this message translates to:
  /// **'Status stamp (Paid / Overdue)'**
  String get statusStampPaidOverdue;

  /// UI text: Payment status in the invoice header
  ///
  /// In en, this message translates to:
  /// **'Payment status in the invoice header'**
  String get paymentStatusInTheInvoiceHeader;

  /// UI text: Quick Look Preview
  ///
  /// In en, this message translates to:
  /// **'Quick Look Preview'**
  String get quickLookPreview;

  /// UI text: Rendering High-DPI (300 DPI)...
  ///
  /// In en, this message translates to:
  /// **'Rendering High-DPI (300 DPI)...'**
  String get renderingHighDpi300Dpi;

  /// UI text: Double-tap to reset view
  ///
  /// In en, this message translates to:
  /// **'Double-tap to reset view'**
  String get doubleTapToResetView;

  /// UI text: Pinch or double-tap to zoom in
  ///
  /// In en, this message translates to:
  /// **'Pinch or double-tap to zoom in'**
  String get pinchOrDoubleTapToZoomIn;

  /// UI text: All
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// UI text: Default invoice fields
  ///
  /// In en, this message translates to:
  /// **'Default invoice fields'**
  String get defaultInvoiceFields;

  /// UI text: Custom fields
  ///
  /// In en, this message translates to:
  /// **'Custom fields'**
  String get customFields;

  /// UI text: These labels appear on new invoices with empty values.
  ///
  /// In en, this message translates to:
  /// **'These labels appear on new invoices with empty values.'**
  String get theseLabelsAppearOnNewInvoicesWithEmpty;

  /// UI text: Label
  ///
  /// In en, this message translates to:
  /// **'Label'**
  String get label;

  /// UI text: Value
  ///
  /// In en, this message translates to:
  /// **'Value'**
  String get value;

  /// UI text: Remove field
  ///
  /// In en, this message translates to:
  /// **'Remove field'**
  String get removeField;

  /// UI text: Add field
  ///
  /// In en, this message translates to:
  /// **'Add field'**
  String get addField;

  /// UI text: Choose Invoice Style
  ///
  /// In en, this message translates to:
  /// **'Choose Invoice Style'**
  String get chooseInvoiceStyle;

  /// UI text: Customize Design & Typography
  ///
  /// In en, this message translates to:
  /// **'Customize Design & Typography'**
  String get customizeDesignTypography;

  /// UI text: Change font family, sizing scale & element layout
  ///
  /// In en, this message translates to:
  /// **'Change font family, sizing scale & element layout'**
  String get changeFontFamilySizingScaleElementLayout;

  /// UI text: Always use this style as default
  ///
  /// In en, this message translates to:
  /// **'Always use this style as default'**
  String get alwaysUseThisStyleAsDefault;

  /// UI text: Apply Selected Style
  ///
  /// In en, this message translates to:
  /// **'Apply Selected Style'**
  String get applySelectedStyle;

  /// UI text: A converted estimate keeps its status. Delete its invoice to change it.
  ///
  /// In en, this message translates to:
  /// **'A converted estimate keeps its status. Delete its invoice to change it.'**
  String get aConvertedEstimateKeepsItsStatusDeleteIts;

  /// UI text: Converted to Invoice {invoiceNumber}
  ///
  /// In en, this message translates to:
  /// **'Converted to Invoice {invoiceNumber}'**
  String convertedToInvoice(String invoiceNumber);

  /// UI text: VIEW
  ///
  /// In en, this message translates to:
  /// **'VIEW'**
  String get viewActionUppercase;

  /// UI text: Estimate {estimateNumber} for {clientName}
  ///
  /// In en, this message translates to:
  /// **'Estimate {estimateNumber} for {clientName}'**
  String estimateFor(String estimateNumber, String clientName);

  /// UI text: Could not share the estimate. Please try again.
  ///
  /// In en, this message translates to:
  /// **'Could not share the estimate. Please try again.'**
  String get couldNotShareTheEstimatePleaseTryAgain;

  /// UI text: Estimates
  ///
  /// In en, this message translates to:
  /// **'Estimates'**
  String get estimates;

  /// UI text: Quotes & proposals
  ///
  /// In en, this message translates to:
  /// **'Quotes & proposals'**
  String get quotesProposals;

  /// UI text: Pending
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// UI text: Accepted
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get accepted;

  /// UI text: Estimated
  ///
  /// In en, this message translates to:
  /// **'Estimated'**
  String get estimated;

  /// UI text: Converted
  ///
  /// In en, this message translates to:
  /// **'Converted'**
  String get converted;

  /// UI text: Declined
  ///
  /// In en, this message translates to:
  /// **'Declined'**
  String get declined;

  /// UI text: No Estimates Yet
  ///
  /// In en, this message translates to:
  /// **'No Estimates Yet'**
  String get noEstimatesYet;

  /// UI text: No Results Found
  ///
  /// In en, this message translates to:
  /// **'No Results Found'**
  String get noResultsFound;

  /// UI text: Send a price before you bill. Accepted quotes turn into invoices in one tap.
  ///
  /// In en, this message translates to:
  /// **'Send a price before you bill. Accepted quotes turn into invoices in one tap.'**
  String get sendAPriceBeforeYouBillAcceptedQuotes;

  /// UI text: Try another search or filter
  ///
  /// In en, this message translates to:
  /// **'Try another search or filter'**
  String get tryAnotherSearchOrFilter;

  /// UI text: Create Estimate
  ///
  /// In en, this message translates to:
  /// **'Create Estimate'**
  String get createEstimate;

  /// UI text: Swipe right to convert · hold for more
  ///
  /// In en, this message translates to:
  /// **'Swipe right to convert · hold for more'**
  String get swipeRightToConvertHoldForMore;

  /// UI text: View details
  ///
  /// In en, this message translates to:
  /// **'View details'**
  String get viewDetails;

  /// UI text: Share PDF
  ///
  /// In en, this message translates to:
  /// **'Share PDF'**
  String get sharePdf;

  /// UI text: Mark accepted
  ///
  /// In en, this message translates to:
  /// **'Mark accepted'**
  String get markAccepted;

  /// UI text: Mark declined
  ///
  /// In en, this message translates to:
  /// **'Mark declined'**
  String get markDeclined;

  /// UI text: Mark pending
  ///
  /// In en, this message translates to:
  /// **'Mark pending'**
  String get markPending;

  /// UI text: Delete estimate
  ///
  /// In en, this message translates to:
  /// **'Delete estimate'**
  String get deleteEstimate;

  /// UI text: No client
  ///
  /// In en, this message translates to:
  /// **'No client'**
  String get noClient;

  /// UI text: Convert
  ///
  /// In en, this message translates to:
  /// **'Convert'**
  String get convert;

  /// UI text: Share
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// UI text: Estimate Design Studio
  ///
  /// In en, this message translates to:
  /// **'Estimate Design Studio'**
  String get estimateDesignStudio;

  /// UI text: Estimate marked as {label}
  ///
  /// In en, this message translates to:
  /// **'Estimate marked as {label}'**
  String estimateMarkedAs(String label);

  /// UI text: Update Status
  ///
  /// In en, this message translates to:
  /// **'Update Status'**
  String get updateStatus;

  /// UI text: Estimate {estimateNumber}
  ///
  /// In en, this message translates to:
  /// **'Estimate {estimateNumber}'**
  String estimate(String estimateNumber);

  /// UI text: Waiting for client approval
  ///
  /// In en, this message translates to:
  /// **'Waiting for client approval'**
  String get waitingForClientApproval;

  /// UI text: Client has approved this estimate
  ///
  /// In en, this message translates to:
  /// **'Client has approved this estimate'**
  String get clientHasApprovedThisEstimate;

  /// UI text: Estimate was not accepted
  ///
  /// In en, this message translates to:
  /// **'Estimate was not accepted'**
  String get estimateWasNotAccepted;

  /// UI text: Valid: {date}
  ///
  /// In en, this message translates to:
  /// **'Valid: {date}'**
  String valid(String date);

  /// UI text: Please enter or select a client name
  ///
  /// In en, this message translates to:
  /// **'Please enter or select a client name'**
  String get pleaseEnterOrSelectAClientName;

  /// UI text: Please add at least one line item
  ///
  /// In en, this message translates to:
  /// **'Please add at least one line item'**
  String get addLineItemValidation;

  /// UI text: Estimate number {value} is already used. Pick another number.
  ///
  /// In en, this message translates to:
  /// **'Estimate number {value} is already used. Pick another number.'**
  String estimateNumberIsAlreadyUsedPickAnotherNumber(String value);

  /// UI text: Could not save the estimate. Please try again.
  ///
  /// In en, this message translates to:
  /// **'Could not save the estimate. Please try again.'**
  String get couldNotSaveTheEstimatePleaseTryAgain;

  /// UI text: Add Item / Service
  ///
  /// In en, this message translates to:
  /// **'Add Item / Service'**
  String get addItemService;

  /// UI text: Enter description, quantity & rate
  ///
  /// In en, this message translates to:
  /// **'Enter description, quantity & rate'**
  String get enterDescriptionQuantityRate;

  /// UI text: Description / Item Name *
  ///
  /// In en, this message translates to:
  /// **'Description / Item Name *'**
  String get descriptionItemName;

  /// UI text: e.g. Website Design, Consultation, Parts
  ///
  /// In en, this message translates to:
  /// **'e.g. Website Design, Consultation, Parts'**
  String get eGWebsiteDesignConsultationParts;

  /// UI text: Quantity *
  ///
  /// In en, this message translates to:
  /// **'Quantity *'**
  String get requiredQuantity;

  /// UI text: Invalid
  ///
  /// In en, this message translates to:
  /// **'Invalid'**
  String get invalid;

  /// UI text: Unit Price *
  ///
  /// In en, this message translates to:
  /// **'Unit Price *'**
  String get requiredUnitPrice;

  /// UI text: Add to Estimate
  ///
  /// In en, this message translates to:
  /// **'Add to Estimate'**
  String get addToEstimate;

  /// UI text: Edit Estimate
  ///
  /// In en, this message translates to:
  /// **'Edit Estimate'**
  String get editEstimate;

  /// UI text: PDF Templates
  ///
  /// In en, this message translates to:
  /// **'PDF Templates'**
  String get pdfTemplates;

  /// UI text: Estimate Number *
  ///
  /// In en, this message translates to:
  /// **'Estimate Number *'**
  String get estimateNumber;

  /// UI text: Estimate Date
  ///
  /// In en, this message translates to:
  /// **'Estimate Date'**
  String get estimateDate;

  /// UI text: Valid Until / Expiry
  ///
  /// In en, this message translates to:
  /// **'Valid Until / Expiry'**
  String get validUntilExpiry;

  /// UI text: No Expiry
  ///
  /// In en, this message translates to:
  /// **'No Expiry'**
  String get noExpiry;

  /// UI text: Quick Validity:
  ///
  /// In en, this message translates to:
  /// **'Quick Validity: '**
  String get quickValidity;

  /// UI text: 7 Days
  ///
  /// In en, this message translates to:
  /// **'7 Days'**
  String get validForSevenDays;

  /// UI text: 14 Days
  ///
  /// In en, this message translates to:
  /// **'14 Days'**
  String get validForFourteenDays;

  /// UI text: 30 Days
  ///
  /// In en, this message translates to:
  /// **'30 Days'**
  String get validForThirtyDays;

  /// UI text: PDF Theme
  ///
  /// In en, this message translates to:
  /// **'PDF Theme'**
  String get pdfTheme;

  /// UI text: Bill To (Client) *
  ///
  /// In en, this message translates to:
  /// **'Bill To (Client) *'**
  String get billToClient;

  /// UI text: Select / Add Client
  ///
  /// In en, this message translates to:
  /// **'Select / Add Client'**
  String get selectAddClient;

  /// UI text: John Doe / Apex Corp
  ///
  /// In en, this message translates to:
  /// **'John Doe / Apex Corp'**
  String get johnDoeApexCorp;

  /// UI text: Items & Services
  ///
  /// In en, this message translates to:
  /// **'Items & Services'**
  String get itemsServices;

  /// UI text: Catalog
  ///
  /// In en, this message translates to:
  /// **'Catalog'**
  String get catalog;

  /// UI text: No items added yet
  ///
  /// In en, this message translates to:
  /// **'No items added yet'**
  String get noItemsAddedYet;

  /// UI text: Subtotal
  ///
  /// In en, this message translates to:
  /// **'Subtotal'**
  String get subtotal;

  /// UI text: Tax
  ///
  /// In en, this message translates to:
  /// **'Tax'**
  String get tax;

  /// UI text: Tax Amount
  ///
  /// In en, this message translates to:
  /// **'Tax Amount'**
  String get taxAmount;

  /// UI text: Total Estimated
  ///
  /// In en, this message translates to:
  /// **'Total Estimated'**
  String get totalEstimated;

  /// UI text: e.g. Estimate valid for 30 days. Payment terms...
  ///
  /// In en, this message translates to:
  /// **'e.g. Estimate valid for 30 days. Payment terms...'**
  String get eGEstimateValidFor30DaysPayment;

  /// UI text: Preview PDF
  ///
  /// In en, this message translates to:
  /// **'Preview PDF'**
  String get previewPdf;

  /// UI text: Save Estimate
  ///
  /// In en, this message translates to:
  /// **'Save Estimate'**
  String get saveEstimate;

  /// UI text: This estimate is already converted to an invoice.
  ///
  /// In en, this message translates to:
  /// **'This estimate is already converted to an invoice.'**
  String get thisEstimateIsAlreadyConvertedToAnInvoice;

  /// UI text: Could not convert the estimate. Please try again.
  ///
  /// In en, this message translates to:
  /// **'Could not convert the estimate. Please try again.'**
  String get couldNotConvertTheEstimatePleaseTryAgain;

  /// UI text: Delete Estimate?
  ///
  /// In en, this message translates to:
  /// **'Delete Estimate?'**
  String get deleteEstimateQuestion;

  /// UI text: Could not delete the estimate. Please try again.
  ///
  /// In en, this message translates to:
  /// **'Could not delete the estimate. Please try again.'**
  String get couldNotDeleteTheEstimatePleaseTryAgain;

  /// UI text: Could not refresh invoices. Pull down to try again.
  ///
  /// In en, this message translates to:
  /// **'Could not refresh invoices. Pull down to try again.'**
  String get couldNotRefreshInvoicesPullDownToTry;

  /// UI text: Due today
  ///
  /// In en, this message translates to:
  /// **'Due today'**
  String get dueToday;

  /// UI text: Due tomorrow
  ///
  /// In en, this message translates to:
  /// **'Due tomorrow'**
  String get dueTomorrow;

  /// UI text: Nothing is left to pay on {invoiceNumber}.
  ///
  /// In en, this message translates to:
  /// **'Nothing is left to pay on {invoiceNumber}.'**
  String nothingIsLeftToPayOn(String invoiceNumber);

  /// UI text: {invoiceNumber} marked paid
  ///
  /// In en, this message translates to:
  /// **'{invoiceNumber} marked paid'**
  String invoiceMarkedPaid(String invoiceNumber);

  /// UI text: Undo
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// UI text: Could not undo. Remove the payment from the invoice instead.
  ///
  /// In en, this message translates to:
  /// **'Could not undo. Remove the payment from the invoice instead.'**
  String get couldNotUndoRemoveThePaymentFromThe;

  /// UI text: Payment
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get payment;

  /// UI text: Records the balance as received today
  ///
  /// In en, this message translates to:
  /// **'Records the balance as received today'**
  String get recordsTheBalanceAsReceivedToday;

  /// UI text: PART
  ///
  /// In en, this message translates to:
  /// **'PART'**
  String get part;

  /// UI text: Edit invoice
  ///
  /// In en, this message translates to:
  /// **'Edit invoice'**
  String get editInvoiceMenu;

  /// UI text: Payment status
  ///
  /// In en, this message translates to:
  /// **'Payment status'**
  String get paymentStatus;

  /// UI text: Save PDF
  ///
  /// In en, this message translates to:
  /// **'Save PDF'**
  String get savePdf;

  /// UI text: Delete invoice
  ///
  /// In en, this message translates to:
  /// **'Delete invoice'**
  String get deleteInvoiceMenu;

  /// UI text: Swipe right to mark paid · hold for more
  ///
  /// In en, this message translates to:
  /// **'Swipe right to mark paid · hold for more'**
  String get swipeRightToMarkPaidHoldForMore;

  /// UI text: Invoices
  ///
  /// In en, this message translates to:
  /// **'Invoices'**
  String get invoices;

  /// UI text: Profile incomplete
  ///
  /// In en, this message translates to:
  /// **'Profile incomplete'**
  String get profileIncomplete;

  /// UI text: TO COLLECT
  ///
  /// In en, this message translates to:
  /// **'TO COLLECT'**
  String get toCollect;

  /// UI text: Collected
  ///
  /// In en, this message translates to:
  /// **'Collected '**
  String get collected;

  /// UI text: Totals are for {currencyCode} invoices only. Not included: {excludedCurrencies}.
  ///
  /// In en, this message translates to:
  /// **'Totals are for {currencyCode} invoices only. Not included: {excludedCurrencies}.'**
  String totalsAreForInvoicesOnlyNotIncluded(
    String currencyCode,
    String excludedCurrencies,
  );

  /// UI text: Needs you
  ///
  /// In en, this message translates to:
  /// **'Needs you'**
  String get needsYou;

  /// UI text: Mark paid
  ///
  /// In en, this message translates to:
  /// **'Mark paid'**
  String get markPaid;

  /// UI text: Overdue
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get overdue;

  /// UI text: Partially Paid
  ///
  /// In en, this message translates to:
  /// **'Partially Paid'**
  String get partiallyPaid;

  /// UI text: Nothing here
  ///
  /// In en, this message translates to:
  /// **'Nothing here'**
  String get nothingHere;

  /// UI text: No invoices match "{searchQuery}"
  ///
  /// In en, this message translates to:
  /// **'No invoices match \"{searchQuery}\"'**
  String noInvoicesMatch(String searchQuery);

  /// UI text: Show all
  ///
  /// In en, this message translates to:
  /// **'Show all'**
  String get showAll;

  /// UI text: NEW
  ///
  /// In en, this message translates to:
  /// **'NEW'**
  String get newStamp;

  /// UI text: Your first invoice
  ///
  /// In en, this message translates to:
  /// **'Your first invoice'**
  String get yourFirstInvoice;

  /// UI text: Make one in under a minute. Tap + below any time.
  ///
  /// In en, this message translates to:
  /// **'Make one in under a minute. Tap + below any time.'**
  String get makeOneInUnderAMinuteTapBelow;

  /// UI text: Change payment status
  ///
  /// In en, this message translates to:
  /// **'Change payment status'**
  String get changePaymentStatus;

  /// UI text: Finish setting up
  ///
  /// In en, this message translates to:
  /// **'Finish setting up'**
  String get finishSettingUp;

  /// UI text: Hide
  ///
  /// In en, this message translates to:
  /// **'Hide'**
  String get hide;

  /// UI text: Pick from Catalog
  ///
  /// In en, this message translates to:
  /// **'Pick from Catalog'**
  String get pickFromCatalog;

  /// UI text: New
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get newAction;

  /// UI text: Search items...
  ///
  /// In en, this message translates to:
  /// **'Search items...'**
  String get searchItemsHint;

  /// UI text: +{rate}% Tax
  ///
  /// In en, this message translates to:
  /// **'+{rate}% Tax'**
  String plusTaxPercent(String rate);

  /// UI text: No items match "{searchQuery}"
  ///
  /// In en, this message translates to:
  /// **'No items match \"{searchQuery}\"'**
  String noItemsMatch(String searchQuery);

  /// UI text: No saved items yet
  ///
  /// In en, this message translates to:
  /// **'No saved items yet'**
  String get noSavedItemsYet;

  /// UI text: Create items in your catalog to quickly add them here
  ///
  /// In en, this message translates to:
  /// **'Create items in your catalog to quickly add them here'**
  String get createItemsInYourCatalogToQuicklyAdd;

  /// UI text: Create New Item
  ///
  /// In en, this message translates to:
  /// **'Create New Item'**
  String get createNewItem;

  /// UI text: Pieces
  ///
  /// In en, this message translates to:
  /// **'Pieces'**
  String get pieces;

  /// UI text: Hours
  ///
  /// In en, this message translates to:
  /// **'Hours'**
  String get hours;

  /// UI text: Days
  ///
  /// In en, this message translates to:
  /// **'Days'**
  String get days;

  /// UI text: Kilograms
  ///
  /// In en, this message translates to:
  /// **'Kilograms'**
  String get kilograms;

  /// UI text: Grams
  ///
  /// In en, this message translates to:
  /// **'Grams'**
  String get grams;

  /// UI text: Litres
  ///
  /// In en, this message translates to:
  /// **'Litres'**
  String get litres;

  /// UI text: Millilitres
  ///
  /// In en, this message translates to:
  /// **'Millilitres'**
  String get millilitres;

  /// UI text: Feet
  ///
  /// In en, this message translates to:
  /// **'Feet'**
  String get feet;

  /// UI text: Metres
  ///
  /// In en, this message translates to:
  /// **'Metres'**
  String get metres;

  /// UI text: Sq. Feet
  ///
  /// In en, this message translates to:
  /// **'Sq. Feet'**
  String get sqFeet;

  /// UI text: Sq. Metres
  ///
  /// In en, this message translates to:
  /// **'Sq. Metres'**
  String get sqMetres;

  /// UI text: Boxes
  ///
  /// In en, this message translates to:
  /// **'Boxes'**
  String get boxes;

  /// UI text: Units
  ///
  /// In en, this message translates to:
  /// **'Units'**
  String get units;

  /// UI text: Lots
  ///
  /// In en, this message translates to:
  /// **'Lots'**
  String get lots;

  /// UI text: 0 to 100
  ///
  /// In en, this message translates to:
  /// **'0 to 100'**
  String get label0To100;

  /// UI text: New Item
  ///
  /// In en, this message translates to:
  /// **'New Item'**
  String get newItem;

  /// UI text: Item Name *
  ///
  /// In en, this message translates to:
  /// **'Item Name *'**
  String get itemName;

  /// UI text: e.g. Web Design, Consulting, T-Shirt
  ///
  /// In en, this message translates to:
  /// **'e.g. Web Design, Consulting, T-Shirt'**
  String get eGWebDesignConsultingTShirt;

  /// UI text: Item name is required
  ///
  /// In en, this message translates to:
  /// **'Item name is required'**
  String get itemNameIsRequired;

  /// UI text: Description
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get itemDescription;

  /// UI text: Optional details about this item or service
  ///
  /// In en, this message translates to:
  /// **'Optional details about this item or service'**
  String get optionalDetailsAboutThisItemOrService;

  /// UI text: Must be 0 or more
  ///
  /// In en, this message translates to:
  /// **'Must be 0 or more'**
  String get mustBe0OrMore;

  /// UI text: Default Qty
  ///
  /// In en, this message translates to:
  /// **'Default Qty'**
  String get defaultQty;

  /// UI text: More than 0
  ///
  /// In en, this message translates to:
  /// **'More than 0'**
  String get moreThan0;

  /// UI text: Unit of Measurement
  ///
  /// In en, this message translates to:
  /// **'Unit of Measurement'**
  String get unitOfMeasurement;

  /// UI text: Category
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// UI text: e.g. Design, Development, Products
  ///
  /// In en, this message translates to:
  /// **'e.g. Design, Development, Products'**
  String get eGDesignDevelopmentProducts;

  /// UI text: HSN / SAC Code
  ///
  /// In en, this message translates to:
  /// **'HSN / SAC Code'**
  String get hsnSacCode;

  /// UI text: e.g. 998311
  ///
  /// In en, this message translates to:
  /// **'e.g. 998311'**
  String get eG998311;

  /// UI text: Item Discount
  ///
  /// In en, this message translates to:
  /// **'Item Discount'**
  String get itemDiscount;

  /// UI text: Set a default percentage discount for this item
  ///
  /// In en, this message translates to:
  /// **'Set a default percentage discount for this item'**
  String get setADefaultPercentageDiscountForThisItem;

  /// UI text: None (0%)
  ///
  /// In en, this message translates to:
  /// **'None (0%)'**
  String get none0;

  /// UI text: Tax Configuration
  ///
  /// In en, this message translates to:
  /// **'Tax Configuration'**
  String get taxConfiguration;

  /// UI text: Specify whether tax applies and the item tax rate
  ///
  /// In en, this message translates to:
  /// **'Specify whether tax applies and the item tax rate'**
  String get specifyWhetherTaxAppliesAndTheItemTax;

  /// UI text: Apply Tax to this Item
  ///
  /// In en, this message translates to:
  /// **'Apply Tax to this Item'**
  String get applyTaxToThisItem;

  /// UI text: e.g. 18
  ///
  /// In en, this message translates to:
  /// **'e.g. 18'**
  String get eG18;

  /// UI text: 0% (Exempt)
  ///
  /// In en, this message translates to:
  /// **'0% (Exempt)'**
  String get label0Exempt;

  /// UI text: Estimated Item Total
  ///
  /// In en, this message translates to:
  /// **'Estimated Item Total'**
  String get estimatedItemTotal;

  /// UI text: Base ({rate} × {amount})
  ///
  /// In en, this message translates to:
  /// **'Base ({rate} × {amount})'**
  String base(String rate, String amount);

  /// UI text: Item Discount ({rate}%)
  ///
  /// In en, this message translates to:
  /// **'Item Discount ({rate}%)'**
  String itemDiscountPercent(String rate);

  /// UI text: Tax ({rate}%)
  ///
  /// In en, this message translates to:
  /// **'Tax ({rate}%)'**
  String taxPercent(String rate);

  /// UI text: Net Item Total:
  ///
  /// In en, this message translates to:
  /// **'Net Item Total:'**
  String get netItemTotal;

  /// UI text: Save Item
  ///
  /// In en, this message translates to:
  /// **'Save Item'**
  String get saveItem;

  /// UI text: Duplicated "{value}"
  ///
  /// In en, this message translates to:
  /// **'Duplicated \"{value}\"'**
  String duplicated(String value);

  /// UI text: Delete Item?
  ///
  /// In en, this message translates to:
  /// **'Delete Item?'**
  String get deleteItem;

  /// UI text: Delete "{value}"? This won't affect existing invoices.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{value}\"? This won\'t affect existing invoices.'**
  String deleteThisWonTAffectExistingInvoices(String value);

  /// UI text: Products & services
  ///
  /// In en, this message translates to:
  /// **'Products & services'**
  String get productsServices;

  /// UI text: Uncategorized
  ///
  /// In en, this message translates to:
  /// **'Uncategorized'**
  String get uncategorized;

  /// UI text: Tap to edit · hold for more
  ///
  /// In en, this message translates to:
  /// **'Tap to edit · hold for more'**
  String get tapToEditHoldForMore;

  /// UI text: No Items Yet
  ///
  /// In en, this message translates to:
  /// **'No Items Yet'**
  String get noItemsYet;

  /// UI text: Save your products & services here to quickly add them to invoices
  ///
  /// In en, this message translates to:
  /// **'Save your products & services here to quickly add them to invoices'**
  String get saveYourProductsServicesHereToQuicklyAdd;

  /// UI text: No items in this category
  ///
  /// In en, this message translates to:
  /// **'No items in this category'**
  String get noItemsInThisCategory;

  /// UI text: Add Your First Item
  ///
  /// In en, this message translates to:
  /// **'Add Your First Item'**
  String get addYourFirstItem;

  /// UI text: Edit item
  ///
  /// In en, this message translates to:
  /// **'Edit item'**
  String get editItemMenu;

  /// UI text: Duplicate
  ///
  /// In en, this message translates to:
  /// **'Duplicate'**
  String get duplicate;

  /// UI text: Delete item
  ///
  /// In en, this message translates to:
  /// **'Delete item'**
  String get deleteItemMenu;

  /// UI text: Tax {rate}%
  ///
  /// In en, this message translates to:
  /// **'Tax {rate}%'**
  String itemTaxPercent(String rate);

  /// UI text: Tax exempt
  ///
  /// In en, this message translates to:
  /// **'Tax exempt'**
  String get taxExempt;

  /// UI text: {rate}% off
  ///
  /// In en, this message translates to:
  /// **'{rate}% off'**
  String percentOff(String rate);

  /// UI text: per {value}
  ///
  /// In en, this message translates to:
  /// **'per {value}'**
  String perUnit(String value);

  /// UI text: Pro is active. Thank you!
  ///
  /// In en, this message translates to:
  /// **'Pro is active. Thank you!'**
  String get proIsActiveThankYou;

  /// UI text: No Pro purchase was found for this Google account.
  ///
  /// In en, this message translates to:
  /// **'No Pro purchase was found for this Google account.'**
  String get noProPurchaseWasFoundForThisGoogle;

  /// UI text: Google Play purchases are not available right now. Check your connection and try again.
  ///
  /// In en, this message translates to:
  /// **'Google Play purchases are not available right now. Check your connection and try again.'**
  String get googlePlayPurchasesAreNotAvailableRightNow;

  /// UI text: UPGRADE
  ///
  /// In en, this message translates to:
  /// **'UPGRADE'**
  String get upgrade;

  /// UI text: Bill without
  ///
  /// In en, this message translates to:
  /// **'Bill without\nlimits.'**
  String get billWithoutLimits;

  /// UI text: One upgrade unlocks every invoice, every client, and clean PDFs with only your brand on them.
  ///
  /// In en, this message translates to:
  /// **'One upgrade unlocks every invoice, every client, and clean PDFs with only your brand on them.'**
  String get oneUpgradeUnlocksEveryInvoiceEveryClientAnd;

  /// UI text: WHAT'S INCLUDED
  ///
  /// In en, this message translates to:
  /// **'WHAT\'S INCLUDED'**
  String get whatSIncluded;

  /// UI text: Unlimited Invoices & Estimates
  ///
  /// In en, this message translates to:
  /// **'Unlimited Invoices & Estimates'**
  String get unlimitedInvoicesEstimates;

  /// UI text: The free plan includes {value} of each per calendar month.
  ///
  /// In en, this message translates to:
  /// **'The free plan includes {value} of each per calendar month.'**
  String paywallMonthlyDocumentLimit(int value);

  /// UI text: Unlimited Clients
  ///
  /// In en, this message translates to:
  /// **'Unlimited Clients'**
  String get unlimitedClients;

  /// UI text: The free plan saves up to {value} clients.
  ///
  /// In en, this message translates to:
  /// **'The free plan saves up to {value} clients.'**
  String paywallSavedClientLimit(int value);

  /// UI text: No Watermark
  ///
  /// In en, this message translates to:
  /// **'No Watermark'**
  String get noWatermark;

  /// UI text: Removes "Generated by Invoice Maker Pro" from your PDFs.
  ///
  /// In en, this message translates to:
  /// **'Removes \"Generated by Invoice Maker Pro\" from your PDFs.'**
  String get removesGeneratedByInvoiceMakerProFromYour;

  /// UI text: TOTAL
  ///
  /// In en, this message translates to:
  /// **'TOTAL'**
  String get totalHeading;

  /// UI text: {amount} / month
  ///
  /// In en, this message translates to:
  /// **'{amount} / month'**
  String monthlyPrice(String amount);

  /// UI text: Lifetime
  ///
  /// In en, this message translates to:
  /// **'Lifetime'**
  String get lifetime;

  /// UI text: Pay once, keep Pro for good
  ///
  /// In en, this message translates to:
  /// **'Pay once, keep Pro for good'**
  String get payOnceKeepProForGood;

  /// UI text: one-time
  ///
  /// In en, this message translates to:
  /// **'one-time'**
  String get oneTime;

  /// UI text: BEST VALUE
  ///
  /// In en, this message translates to:
  /// **'BEST VALUE'**
  String get bestValue;

  /// UI text: Monthly
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get monthly;

  /// UI text: Cancel any time in Google Play
  ///
  /// In en, this message translates to:
  /// **'Cancel any time in Google Play'**
  String get cancelAnyTimeInGooglePlay;

  /// UI text: Unlock Lifetime Access
  ///
  /// In en, this message translates to:
  /// **'Unlock Lifetime Access'**
  String get unlockLifetimeAccess;

  /// UI text: Subscribe for {value}
  ///
  /// In en, this message translates to:
  /// **'Subscribe for {value}'**
  String subscribeFor(String value);

  /// UI text: One payment. Pro stays active on this Google account for good.
  ///
  /// In en, this message translates to:
  /// **'One payment. Pro stays active on this Google account for good.'**
  String get onePaymentProStaysActiveOnThisGoogle;

  /// UI text: Renews every month at the price above until you cancel. Cancel anytime in Google Play > Payments & subscriptions.
  ///
  /// In en, this message translates to:
  /// **'Renews every month at the price above until you cancel. Cancel anytime in Google Play > Payments & subscriptions.'**
  String get renewsEveryMonthAtThePriceAboveUntil;

  /// UI text: Restore purchase
  ///
  /// In en, this message translates to:
  /// **'Restore purchase'**
  String get restorePurchase;

  /// UI text: Could not save your details. Please try again.
  ///
  /// In en, this message translates to:
  /// **'Could not save your details. Please try again.'**
  String get couldNotSaveYourDetailsPleaseTryAgain;

  /// UI text: Skip
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// UI text: Get paid,
  ///
  /// In en, this message translates to:
  /// **'Get paid,\nbeautifully.'**
  String get getPaidBeautifully;

  /// UI text: Make an invoice in under a minute. Stamp it paid when the money lands.
  ///
  /// In en, this message translates to:
  /// **'Make an invoice in under a minute. Stamp it paid when the money lands.'**
  String get makeAnInvoiceInUnderAMinuteStamp;

  /// UI text: Start the tour
  ///
  /// In en, this message translates to:
  /// **'Start the tour'**
  String get startTheTour;

  /// UI text: Get started
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get getStarted;

  /// UI text: Takes about a minute
  ///
  /// In en, this message translates to:
  /// **'Takes about a minute'**
  String get takesAboutAMinute;

  /// UI text: Invoice
  ///
  /// In en, this message translates to:
  /// **'Invoice'**
  String get invoiceLabel;

  /// UI text: Bill to  ·  Studio North
  ///
  /// In en, this message translates to:
  /// **'Bill to  ·  Studio North'**
  String get billToStudioNorth;

  /// UI text: Logo design
  ///
  /// In en, this message translates to:
  /// **'Logo design'**
  String get logoDesign;

  /// UI text: Brand guide
  ///
  /// In en, this message translates to:
  /// **'Brand guide'**
  String get brandGuide;

  /// UI text: Your business
  ///
  /// In en, this message translates to:
  /// **'Your business'**
  String get yourBusiness;

  /// UI text: This sits at the top of every invoice. You can change it any time.
  ///
  /// In en, this message translates to:
  /// **'This sits at the top of every invoice. You can change it any time.'**
  String get thisSitsAtTheTopOfEveryInvoice;

  /// UI text: Business or your name
  ///
  /// In en, this message translates to:
  /// **'Business or your name'**
  String get businessOrYourName;

  /// UI text: Address (optional)
  ///
  /// In en, this message translates to:
  /// **'Address (optional)'**
  String get addressOptional;

  /// UI text: Email (optional)
  ///
  /// In en, this message translates to:
  /// **'Email (optional)'**
  String get emailOptional;

  /// UI text: Phone (optional)
  ///
  /// In en, this message translates to:
  /// **'Phone (optional)'**
  String get phoneOptional;

  /// UI text: Continue
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueAction;

  /// UI text: Add logo
  ///
  /// In en, this message translates to:
  /// **'Add logo'**
  String get addLogo;

  /// UI text: Change logo
  ///
  /// In en, this message translates to:
  /// **'Change logo'**
  String get changeLogo;

  /// UI text: Logo
  ///
  /// In en, this message translates to:
  /// **'Logo'**
  String get logo;

  /// UI text: Your Business
  ///
  /// In en, this message translates to:
  /// **'Your Business'**
  String get yourBusinessPlaceholder;

  /// UI text: email  ·  phone
  ///
  /// In en, this message translates to:
  /// **'email  ·  phone'**
  String get emailPhone;

  /// UI text: A GSTIN is 15 characters, like {value}.
  ///
  /// In en, this message translates to:
  /// **'A GSTIN is 15 characters, like {value}.'**
  String aGstinIs15CharactersLike(String value);

  /// UI text: A UPI ID looks like name@bank.
  ///
  /// In en, this message translates to:
  /// **'A UPI ID looks like name@bank.'**
  String get aUpiIdLooksLikeNameBank;

  /// UI text: How you bill
  ///
  /// In en, this message translates to:
  /// **'How you bill'**
  String get howYouBill;

  /// UI text: New invoices start with these. Each invoice can still change them.
  ///
  /// In en, this message translates to:
  /// **'New invoices start with these. Each invoice can still change them.'**
  String get newInvoicesStartWithTheseEachInvoiceCan;

  /// UI text: CURRENCY
  ///
  /// In en, this message translates to:
  /// **'CURRENCY'**
  String get currencyHeading;

  /// UI text: More…
  ///
  /// In en, this message translates to:
  /// **'More…'**
  String get moreChoices;

  /// UI text: TAX
  ///
  /// In en, this message translates to:
  /// **'TAX'**
  String get taxHeading;

  /// UI text: TAX · {taxName}
  ///
  /// In en, this message translates to:
  /// **'TAX · {taxName}'**
  String namedTaxHeading(String taxName);

  /// UI text: No tax
  ///
  /// In en, this message translates to:
  /// **'No tax'**
  String get noTax;

  /// UI text: {taxIdLabel} (optional)
  ///
  /// In en, this message translates to:
  /// **'{taxIdLabel} (optional)'**
  String optionalField(String taxIdLabel);

  /// UI text: PAYMENT DUE
  ///
  /// In en, this message translates to:
  /// **'PAYMENT DUE'**
  String get paymentDue;

  /// UI text: Getting paid
  ///
  /// In en, this message translates to:
  /// **'Getting paid'**
  String get gettingPaid;

  /// UI text: Printed on every invoice so clients know how to pay you. All optional.
  ///
  /// In en, this message translates to:
  /// **'Printed on every invoice so clients know how to pay you. All optional.'**
  String get printedOnEveryInvoiceSoClientsKnowHow;

  /// UI text: BANK TRANSFER
  ///
  /// In en, this message translates to:
  /// **'BANK TRANSFER'**
  String get bankTransfer;

  /// UI text: Bank name
  ///
  /// In en, this message translates to:
  /// **'Bank name'**
  String get bankNameSentenceCase;

  /// UI text: Skip for now
  ///
  /// In en, this message translates to:
  /// **'Skip for now'**
  String get skipForNow;

  /// UI text: READY
  ///
  /// In en, this message translates to:
  /// **'READY'**
  String get ready;

  /// UI text: You're all set.
  ///
  /// In en, this message translates to:
  /// **'You\'re all set.'**
  String get youReAllSet;

  /// UI text: You're all set,
  ///
  /// In en, this message translates to:
  /// **'You\'re all set,\n{firstName}.'**
  String setupCompleteFor(String firstName);

  /// UI text: That's the tour. Nothing was changed.
  ///
  /// In en, this message translates to:
  /// **'That\'s the tour. Nothing was changed.'**
  String get thatSTheTourNothingWasChanged;

  /// UI text: Your first invoice is one tap away. Tap + at the bottom any time to make another.
  ///
  /// In en, this message translates to:
  /// **'Your first invoice is one tap away. Tap + at the bottom any time to make another.'**
  String get yourFirstInvoiceIsOneTapAwayTap;

  /// UI text: Free plan: {value} invoices a month. Upgrade any time in Settings.
  ///
  /// In en, this message translates to:
  /// **'Free plan: {value} invoices a month. Upgrade any time in Settings.'**
  String onboardingFreePlanLimit(int value);

  /// UI text: See a sample with your details
  ///
  /// In en, this message translates to:
  /// **'See a sample with your details'**
  String get seeASampleWithYourDetails;

  /// UI text: Create my first invoice
  ///
  /// In en, this message translates to:
  /// **'Create my first invoice'**
  String get createMyFirstInvoice;

  /// UI text: Back to settings
  ///
  /// In en, this message translates to:
  /// **'Back to settings'**
  String get backToSettings;

  /// UI text: I'll look around first
  ///
  /// In en, this message translates to:
  /// **'I\'ll look around first'**
  String get iLlLookAroundFirst;

  /// UI text: Sample invoice
  ///
  /// In en, this message translates to:
  /// **'Sample invoice'**
  String get sampleInvoice;

  /// UI text: Your details on a made-up invoice. Nothing is saved.
  ///
  /// In en, this message translates to:
  /// **'Your details on a made-up invoice. Nothing is saved.'**
  String get yourDetailsOnAMadeUpInvoiceNothing;

  /// UI text: Could not load reports. Pull down to try again.
  ///
  /// In en, this message translates to:
  /// **'Could not load reports. Pull down to try again.'**
  String get couldNotLoadReportsPullDownToTry;

  /// UI text: Could not share summary. Please try again.
  ///
  /// In en, this message translates to:
  /// **'Could not share summary. Please try again.'**
  String get couldNotShareSummaryPleaseTryAgain;

  /// UI text: Share summary
  ///
  /// In en, this message translates to:
  /// **'Share summary'**
  String get shareSummary;

  /// UI text: No reports yet
  ///
  /// In en, this message translates to:
  /// **'No reports yet'**
  String get noReportsYet;

  /// UI text: Nothing in this range
  ///
  /// In en, this message translates to:
  /// **'Nothing in this range'**
  String get nothingInThisRange;

  /// UI text: Create an invoice to track billed revenue, collections, taxes, and top clients.
  ///
  /// In en, this message translates to:
  /// **'Create an invoice to track billed revenue, collections, taxes, and top clients.'**
  String get createAnInvoiceToTrackBilledRevenueCollections;

  /// UI text: No {currencyCode} invoices match {label}. Invoices in other currencies: {excludedCurrencies}.
  ///
  /// In en, this message translates to:
  /// **'No {currencyCode} invoices match {label}. Invoices in other currencies: {excludedCurrencies}.'**
  String noInvoicesMatchInvoicesInOtherCurrencies(
    String currencyCode,
    String label,
    String excludedCurrencies,
  );

  /// UI text: No invoices or payments match {label}. Try another date range or pull down to refresh.
  ///
  /// In en, this message translates to:
  /// **'No invoices or payments match {label}. Try another date range or pull down to refresh.'**
  String noInvoicesOrPaymentsMatchTryAnotherDate(String label);

  /// UI text: Custom
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get custom;

  /// UI text: Today
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// UI text: This week
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get thisWeek;

  /// UI text: This month
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get thisMonth;

  /// UI text: This year
  ///
  /// In en, this message translates to:
  /// **'This year'**
  String get thisYear;

  /// UI text: All time
  ///
  /// In en, this message translates to:
  /// **'All time'**
  String get allTime;

  /// UI text: {value}% of billed
  ///
  /// In en, this message translates to:
  /// **'{value}% of billed'**
  String percentOfBilled(int value);

  /// UI text: Payments received
  ///
  /// In en, this message translates to:
  /// **'Payments received'**
  String get paymentsReceived;

  /// UI text: BILLED
  ///
  /// In en, this message translates to:
  /// **'BILLED'**
  String get billed;

  /// UI text: COLLECTED
  ///
  /// In en, this message translates to:
  /// **'COLLECTED'**
  String get collectedHeading;

  /// UI text: OUTSTANDING
  ///
  /// In en, this message translates to:
  /// **'OUTSTANDING'**
  String get outstanding;

  /// UI text: Balance remaining
  ///
  /// In en, this message translates to:
  /// **'Balance remaining'**
  String get balanceRemaining;

  /// UI text: TAX COLLECTED
  ///
  /// In en, this message translates to:
  /// **'TAX COLLECTED'**
  String get taxCollected;

  /// UI text: AVG. INVOICE
  ///
  /// In en, this message translates to:
  /// **'AVG. INVOICE'**
  String get avgInvoice;

  /// UI text: Preparing CSV files...
  ///
  /// In en, this message translates to:
  /// **'Preparing CSV files...'**
  String get preparingCsvFiles;

  /// UI text: Status Breakdown
  ///
  /// In en, this message translates to:
  /// **'Status Breakdown'**
  String get statusBreakdown;

  /// UI text: Top Clients
  ///
  /// In en, this message translates to:
  /// **'Top Clients'**
  String get topClients;

  /// UI text: Top Items
  ///
  /// In en, this message translates to:
  /// **'Top Items'**
  String get topItems;

  /// UI text: Billed vs Collected
  ///
  /// In en, this message translates to:
  /// **'Billed vs Collected'**
  String get billedVsCollected;

  /// UI text: Billed
  ///
  /// In en, this message translates to:
  /// **'Billed'**
  String get billedLabel;

  /// UI text: Collected
  ///
  /// In en, this message translates to:
  /// **'Collected'**
  String get collectedLabel;

  /// UI text: Billed {value}
  ///
  /// In en, this message translates to:
  /// **'Billed {value}'**
  String billedAmount(String value);

  /// UI text: Collected {value}
  ///
  /// In en, this message translates to:
  /// **'Collected {value}'**
  String collectedAmount(String value);

  /// UI text: Tap a month for details
  ///
  /// In en, this message translates to:
  /// **'Tap a month for details'**
  String get tapAMonthForDetails;

  /// UI text: No activity in these months
  ///
  /// In en, this message translates to:
  /// **'No activity in these months'**
  String get noActivityInTheseMonths;

  /// UI text: Update flow started. Follow the system prompt to finish.
  ///
  /// In en, this message translates to:
  /// **'Update flow started. Follow the system prompt to finish.'**
  String get updateFlowStartedFollowTheSystemPromptTo;

  /// UI text: Update cancelled. You can install it later when prompted again.
  ///
  /// In en, this message translates to:
  /// **'Update cancelled. You can install it later when prompted again.'**
  String get updateCancelledYouCanInstallItLaterWhen;

  /// UI text: This update is not ready to install yet.
  ///
  /// In en, this message translates to:
  /// **'This update is not ready to install yet.'**
  String get thisUpdateIsNotReadyToInstallYet;

  /// UI text: In-app updates are only supported on Android.
  ///
  /// In en, this message translates to:
  /// **'In-app updates are only supported on Android.'**
  String get inAppUpdatesAreOnlySupportedOnAndroid;

  /// UI text: The update could not be started. Please try again later.
  ///
  /// In en, this message translates to:
  /// **'The update could not be started. Please try again later.'**
  String get theUpdateCouldNotBeStartedPleaseTry;

  /// UI text: Update downloaded. Restart to finish installing.
  ///
  /// In en, this message translates to:
  /// **'Update downloaded. Restart to finish installing.'**
  String get updateDownloadedRestartToFinishInstalling;

  /// UI text: Restart
  ///
  /// In en, this message translates to:
  /// **'Restart'**
  String get restart;

  /// UI text: Search invoices
  ///
  /// In en, this message translates to:
  /// **'Search invoices'**
  String get searchInvoices;

  /// UI text: Search estimates
  ///
  /// In en, this message translates to:
  /// **'Search estimates'**
  String get searchEstimates;

  /// UI text: Search clients
  ///
  /// In en, this message translates to:
  /// **'Search clients'**
  String get searchClients;

  /// UI text: Search items
  ///
  /// In en, this message translates to:
  /// **'Search items'**
  String get searchItems;

  /// UI text: Search
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// UI text: Close search
  ///
  /// In en, this message translates to:
  /// **'Close search'**
  String get closeSearch;

  /// UI text: Create
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// UI text: Create New Document
  ///
  /// In en, this message translates to:
  /// **'Create New Document'**
  String get createNewDocument;

  /// UI text: Bill a client for work or items
  ///
  /// In en, this message translates to:
  /// **'Bill a client for work or items'**
  String get billAClientForWorkOrItems;

  /// UI text: New Estimate / Quote
  ///
  /// In en, this message translates to:
  /// **'New Estimate / Quote'**
  String get newEstimateQuote;

  /// UI text: Send a price before you bill
  ///
  /// In en, this message translates to:
  /// **'Send a price before you bill'**
  String get sendAPriceBeforeYouBill;

  /// UI text: Client
  ///
  /// In en, this message translates to:
  /// **'Client'**
  String get client;

  /// UI text: Item
  ///
  /// In en, this message translates to:
  /// **'Item'**
  String get item;

  /// UI text: New {title}
  ///
  /// In en, this message translates to:
  /// **'New {title}'**
  String newEntity(String title);

  /// UI text: Update available
  ///
  /// In en, this message translates to:
  /// **'Update available'**
  String get updateAvailable;

  /// UI text: A newer version of Invoice Maker Pro is ready with the latest fixes and improvements.
  ///
  /// In en, this message translates to:
  /// **'A newer version of Invoice Maker Pro is ready with the latest fixes and improvements.'**
  String get aNewerVersionOfInvoiceMakerProIs;

  /// UI text: Later
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get later;

  /// UI text: Update now
  ///
  /// In en, this message translates to:
  /// **'Update now'**
  String get updateNow;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'hi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
