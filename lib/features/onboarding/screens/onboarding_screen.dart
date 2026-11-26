import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/localization/catalog_localization.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/localization/language_picker.dart';
import '../../../core/localization/locale_controller.dart';

import '../../../core/billing/billing_service.dart';
import '../../../core/billing/free_limits.dart';
import '../../../core/models/currency_model.dart';
import '../../../core/providers/currency_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/image_store.dart';
import '../../../core/utils/number_text.dart';
import '../../../shared_widgets/currency_picker_sheet.dart';
import '../../../shared_widgets/document_pages.dart';
import '../../../shared_widgets/paper.dart';
import '../../invoices/models/invoice_model.dart';
import '../../invoices/screens/create_invoice_screen.dart';
import '../../invoices/services/dummy_invoice_data.dart';
import '../../invoices/services/invoice_render_service.dart';
import '../../invoices/services/pdf_generator_service.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_animations.dart';

/// First run: welcome, your business, how you bill, getting paid, done.
///
/// Nothing is saved until the last step, so backing out part-way leaves no
/// half-set profile. As a replay from Settings it saves nothing at all.
class OnboardingScreen extends StatefulWidget {
  /// True when opened from Settings › Help & Guide: a walkthrough only. It
  /// changes no settings and returns to Settings when done.
  final bool isReplay;

  const OnboardingScreen({super.key, this.isReplay = false});

  /// Set by onboarding just before it completes, so the app shell opens the
  /// invoice editor on top of itself (Back then returns to the dashboard).
  static bool openCreateInvoiceOnStart = false;

  /// The currency most people in [countryCode] invoice in.
  @visibleForTesting
  static String currencyForCountry(String? countryCode) {
    const euro = {
      'DE',
      'FR',
      'ES',
      'IT',
      'NL',
      'IE',
      'PT',
      'BE',
      'AT',
      'FI',
      'GR',
      'LU',
      'SK',
      'SI',
      'EE',
      'LV',
      'LT',
      'CY',
      'MT',
      'HR',
    };
    final cc = countryCode?.toUpperCase();
    if (cc == null) return 'USD';
    if (euro.contains(cc)) return 'EUR';
    return const {
          'IN': 'INR',
          'US': 'USD',
          'GB': 'GBP',
          'CA': 'CAD',
          'AU': 'AUD',
          'AE': 'AED',
          'SG': 'SGD',
          'NZ': 'NZD',
          'JP': 'JPY',
          'CH': 'CHF',
          'ZA': 'ZAR',
          'MY': 'MYR',
          'PH': 'PHP',
          'ID': 'IDR',
          'SA': 'SAR',
          'NG': 'NGN',
          'KE': 'KES',
          'BR': 'BRL',
          'MX': 'MXN',
          'PK': 'PKR',
          'BD': 'BDT',
          'LK': 'LKR',
          'NP': 'NPR',
          'HK': 'HKD',
          'SE': 'SEK',
          'NO': 'NOK',
          'DK': 'DKK',
          'PL': 'PLN',
        }[cc] ??
        'USD';
  }

  static const paymentTerms = ['Due on Receipt', 'Net 15', 'Net 30', 'Net 60'];

  /// India's 15-character GSTIN: state code, PAN, entity number, Z, check.
  static final gstinPattern = RegExp(r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z][1-9A-Z]Z[0-9A-Z]$');

  /// A UPI ID is name@handle, where the handle is the bank or app's letters.
  static final upiPattern = RegExp(r'^[A-Za-z0-9._-]{2,}@[A-Za-z]{2,}$');

  /// The issuer details the sample preview draws, from what was typed so
  /// far. Blank fields are left out, as on a real invoice, and the tax ID only
  /// prints when the person charges tax.
  @visibleForTesting
  static BusinessProfile previewProfile({
    required String currencyCode,
    required double taxRate,
    String name = '',
    String address = '',
    String email = '',
    String phone = '',
    String taxId = '',
    String upi = '',
    String bankName = '',
    String account = '',
    String routing = '',
    String? logoPath,
  }) {
    String? opt(String v) => v.trim().isEmpty ? null : v.trim();
    return BusinessProfile(
      businessName: opt(name) ?? 'Your Business',
      address: opt(address),
      email: opt(email),
      phone: opt(phone),
      gstin: taxRate == 0 ? null : opt(taxId.toUpperCase()),
      upiId: opt(upi),
      bankName: opt(bankName),
      accountNumber: opt(account),
      ifscCode: opt(routing),
      logoPath: logoPath,
      currency: currencyCode,
    );
  }

  /// The demo invoice in [currencyCode], taxed at [taxRate] the way a new
  /// invoice would be (split in two for dual-tax countries such as India).
  @visibleForTesting
  static InvoiceModel previewInvoice({
    required String currencyCode,
    required double taxRate,
    String? terms,
    DateTime? now,
  }) {
    final dual = SupportedCurrencies.getByCode(currencyCode)?.defaultTax.isDualTax ?? false;
    final sample = DummyInvoiceData.getSampleInvoice(currencyCode);
    final days = {'Net 15': 15, 'Net 30': 30, 'Net 60': 60}[terms] ?? 0;
    // Dated today and unpaid, so a brand-new account's sample is never
    // stamped overdue by the stock sample's fixed date.
    final n = now ?? DateTime.now();
    final today = DateTime(n.year, n.month, n.day);
    return sample.copyWith(
      sgstRate: dual ? taxRate / 2 : 0,
      cgstRate: dual ? taxRate / 2 : 0,
      igstRate: dual ? 0 : taxRate,
      invoiceDate: today,
      dueDate: today.add(Duration(days: days)),
      status: InvoiceStatus.unpaid,
    );
  }

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const _pages = 5;
  final _pageController = PageController();
  int _page = 0;
  bool _finishing = false;

  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _taxIdCtrl = TextEditingController();
  final _upiCtrl = TextEditingController();
  final _bankNameCtrl = TextEditingController();
  final _accountCtrl = TextEditingController();
  final _routingCtrl = TextEditingController();
  String? _logoPath;

  /// Every text field, so listeners and disposal cover all of them.
  late final _controllers = [
    _nameCtrl,
    _emailCtrl,
    _phoneCtrl,
    _addressCtrl,
    _taxIdCtrl,
    _upiCtrl,
    _bankNameCtrl,
    _accountCtrl,
    _routingCtrl,
  ];

  late Currency _currency;
  late double _taxRate;
  String _terms = OnboardingScreen.paymentTerms.first;

  /// How far the sample invoice on the welcome page has written itself.
  int _buildStep = 0;
  Timer? _buildTimer;

  @override
  void initState() {
    super.initState();
    final provider = context.read<CurrencyProvider>();
    if (widget.isReplay) {
      _currency = provider.selectedCurrency;
      _taxRate = provider.customTaxRate ?? _currency.defaultTax.rate;
      _loadSavedProfile();
    } else {
      final code = OnboardingScreen.currencyForCountry(ui.PlatformDispatcher.instance.locale.countryCode);
      _currency = SupportedCurrencies.getByCode(code) ?? SupportedCurrencies.popular.first;
      _taxRate = _currency.defaultTax.rate;
    }
    for (final c in _controllers) {
      c.addListener(() => setState(() {}));
    }
    _buildTimer = Timer.periodic(const Duration(milliseconds: 380), (t) {
      if (!mounted || _buildStep >= 5) {
        t.cancel();
        return;
      }
      setState(() => _buildStep++);
      if (_buildStep == 5) {
        // The PAID stamp lands a beat after it appears.
        Future.delayed(const Duration(milliseconds: 250), () {
          if (mounted) Haptics.stamp();
        });
      }
    });
  }

  /// The replay shows the person's own details, read-only.
  Future<void> _loadSavedProfile() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    _nameCtrl.text = prefs.getString('biz_name') ?? '';
    _emailCtrl.text = prefs.getString('biz_email') ?? '';
    _phoneCtrl.text = prefs.getString('biz_phone') ?? '';
    _addressCtrl.text = prefs.getString('biz_address') ?? '';
    _taxIdCtrl.text = prefs.getString('biz_gstin') ?? '';
    _upiCtrl.text = prefs.getString('biz_upi') ?? '';
    _bankNameCtrl.text = prefs.getString('biz_bank_name') ?? '';
    _accountCtrl.text = prefs.getString('biz_account') ?? '';
    _routingCtrl.text = prefs.getString('biz_ifsc') ?? '';
    final terms = prefs.getString('default_payment_terms');
    setState(() {
      _logoPath = prefs.getString('biz_logo_path');
      if (OnboardingScreen.paymentTerms.contains(terms)) _terms = terms!;
    });
  }

  @override
  void dispose() {
    _buildTimer?.cancel();
    _pageController.dispose();
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _goTo(int page) {
    FocusScope.of(context).unfocus();
    Haptics.tap();
    _pageController.animateToPage(page, duration: AppAnimations.slow, curve: AppAnimations.defaultCurve);
  }

  void _setCurrency(Currency c) {
    Haptics.tap();
    // A GSTIN means nothing outside India, so don't carry it to the new
    // country's tax ID field. Anything else stays: it is on screen to fix.
    final leavingIndia = _isIndia && c.code != 'INR';
    if (leavingIndia && OnboardingScreen.gstinPattern.hasMatch(_taxIdCtrl.text.trim().toUpperCase())) {
      _taxIdCtrl.clear();
    }
    setState(() {
      _currency = c;
      _taxRate = c.defaultTax.rate;
    });
  }

  Future<void> _pickLogo() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null) return;
    final kept = await ImageStore.keep(picked.path, 'logo');
    if (!mounted) return;
    setState(() => _logoPath = kept);
  }

  String _money(double v) =>
      CurrencyFormatter.format(v, currencyCode: _currency.code, currencySymbol: _currency.symbol);

  String get _bizName => _nameCtrl.text.trim();

  Future<void> _finishOnboarding({bool openCreateInvoice = false}) async {
    if (_finishing) return;
    _finishing = true;
    FocusScope.of(context).unfocus();

    if (widget.isReplay) {
      // A walkthrough from Settings changes nothing.
      final nav = Navigator.of(context);
      nav.pop();
      if (openCreateInvoice && nav.mounted && await CreateInvoiceScreen.canCreateNewInvoice(nav.context)) {
        await nav.push(MaterialPageRoute(builder: (_) => const CreateInvoiceScreen()));
      }
      return;
    }

    final currencyProvider = context.read<CurrencyProvider>();
    try {
      final prefs = await SharedPreferences.getInstance();
      Future<void> put(String key, String value) async {
        if (value.trim().isNotEmpty) await prefs.setString(key, value.trim());
      }

      await put('biz_name', _nameCtrl.text);
      await put('biz_email', _emailCtrl.text);
      await put('biz_phone', _phoneCtrl.text);
      await put('biz_address', _addressCtrl.text);
      // A tax ID only belongs on invoices that charge tax.
      if (_taxRate != 0) await put('biz_gstin', _taxIdCtrl.text.toUpperCase());
      await put('biz_upi', _upiCtrl.text);
      await put('biz_bank_name', _bankNameCtrl.text);
      await put('biz_account', _accountCtrl.text);
      await put('biz_ifsc', _routingCtrl.text);
      if (_logoPath != null) await prefs.setString('biz_logo_path', _logoPath!);
      await prefs.setString('default_payment_terms', _terms);

      await currencyProvider.setCurrency(_currency);
      // Save the chosen rate even when it is 0 ("No tax"), or new invoices
      // fall back to the currency's default rate.
      await currencyProvider.setCustomTaxRate(_taxRate);
      // Completing onboarding makes the app root swap this screen for the
      // app shell, so this is the last step: the shell opens the editor.
      OnboardingScreen.openCreateInvoiceOnStart = openCreateInvoice;
      await currencyProvider.completeOnboarding();
    } catch (e) {
      // Let the person try again instead of leaving the buttons dead.
      debugPrint('Could not finish onboarding: $e');
      _finishing = false;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.couldNotSaveYourDetailsPleaseTryAgain)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final showBar = _page >= 1 && _page < _pages - 1;
    return PopScope(
      canPop: _page == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _page > 0) _goTo(_page - 1);
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              AnimatedSize(
                duration: AppAnimations.medium,
                curve: AppAnimations.defaultCurve,
                child: showBar ? _buildTopBar() : const SizedBox(width: double.infinity),
              ),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (i) {
                    FocusManager.instance.primaryFocus?.unfocus();
                    setState(() => _page = i);
                  },
                  children: [_buildWelcome(), _buildBusiness(), _buildDefaults(), _buildPayment(), _buildDone()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 8, 4),
      child: Row(
        children: [
          IconButton(
            tooltip: context.l10n.back,
            onPressed: () => _goTo(_page - 1),
            icon: Icon(AppIcons.arrowBack, color: AppColors.ink),
          ),
          const Spacer(),
          // One dash per step between the welcome and done pages.
          for (var i = 1; i < _pages - 1; i++)
            AnimatedContainer(
              duration: AppAnimations.medium,
              width: i == _page ? 28 : 14,
              height: 4,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color: i <= _page ? AppColors.ink : AppColors.hairline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          const Spacer(),
          TextButton(
            onPressed: () => _goTo(_pages - 1),
            style: TextButton.styleFrom(foregroundColor: AppColors.muted),
            child: Text(context.l10n.skip, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  /// The bottom button every step shares, in the same place each time.
  Widget _primaryButton(String label, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9999)),
          textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        child: Text(label),
      ),
    );
  }

  Widget _stepTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTypography.serif(fontSize: 32, color: AppColors.ink, letterSpacing: -0.9, height: 1.1)),
        const SizedBox(height: 8),
        Text(subtitle, style: GoogleFonts.inter(fontSize: 14.5, color: AppColors.muted, height: 1.45)),
      ],
    );
  }

  static TextStyle get _caption =>
      GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.1, color: AppColors.mutedSoft);

  // ── 1. Welcome ─────────────────────────────────────────────────────────────

  Widget _buildWelcome() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text('INVOICE MAKER PRO', style: _caption)),
              if (context.watch<LocaleController?>() != null)
                TextButton.icon(
                  onPressed: () => showLanguagePicker(context),
                  icon: const Icon(AppIcons.globe, size: 16),
                  label: Text(context.l10n.language),
                  style: TextButton.styleFrom(foregroundColor: AppColors.ink),
                ),
            ],
          ),
          Expanded(
            child: Center(
              child: FittedBox(fit: BoxFit.scaleDown, child: _sampleInvoice()),
            ),
          ),
          Text(
            context.l10n.getPaidBeautifully,
            style: AppTypography.serif(fontSize: 40, color: AppColors.ink, letterSpacing: -1.3, height: 1.05),
          ),
          const SizedBox(height: 10),
          Text(
            context.l10n.makeAnInvoiceInUnderAMinuteStamp,
            style: GoogleFonts.inter(fontSize: 15, color: AppColors.muted, height: 1.45),
          ),
          const SizedBox(height: 28),
          _primaryButton(widget.isReplay ? context.l10n.startTheTour : context.l10n.getStarted, () => _goTo(1)),
          const SizedBox(height: 10),
          Center(
            child: Text(context.l10n.takesAboutAMinute, style: GoogleFonts.inter(fontSize: 12.5, color: AppColors.mutedSoft)),
          ),
        ],
      ),
    );
  }

  /// A paper invoice that writes itself line by line, then gets stamped.
  Widget _sampleInvoice() {
    const subtotal = 1800.0;
    Widget line(int step, Widget child) => AnimatedOpacity(
      opacity: _buildStep >= step ? 1 : 0,
      duration: AppAnimations.medium,
      child: AnimatedSlide(
        offset: _buildStep >= step ? Offset.zero : const Offset(0, 0.3),
        duration: AppAnimations.medium,
        curve: AppAnimations.defaultCurve,
        child: child,
      ),
    );
    final small = GoogleFonts.inter(fontSize: 12.5, color: AppColors.muted);
    final body = GoogleFonts.inter(fontSize: 13.5, color: AppColors.ink);

    Widget item(String name, double amount) => Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(child: Text(name, style: body)),
          Text(_money(amount), style: body),
        ],
      ),
    );

    return Transform.rotate(
      angle: -0.025,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 290,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
            decoration: BoxDecoration(
              color: AppColors.canvas,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.hairline),
              boxShadow: AppColors.isDark
                  ? null
                  : const [BoxShadow(color: Color.fromRGBO(60, 45, 20, 0.10), blurRadius: 28, offset: Offset(0, 12))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                line(
                  1,
                  Row(
                    children: [
                      Text(context.l10n.invoiceLabel, style: AppTypography.serif(fontSize: 22, color: AppColors.ink)),
                      const Spacer(),
                      Text('#0001', style: small),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                line(2, Text(context.l10n.billToStudioNorth, style: small)),
                const SizedBox(height: 14),
                line(3, Column(children: [item(context.l10n.logoDesign, 1200), item(context.l10n.brandGuide, 600)])),
                const SizedBox(height: 8),
                line(
                  4,
                  Column(
                    children: [
                      Divider(height: 1, color: AppColors.hairline),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Text(
                            context.l10n.total,
                            style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.ink),
                          ),
                          const Spacer(),
                          Text(_money(subtotal), style: AppTypography.money(fontSize: 20, color: AppColors.ink)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_buildStep >= 5)
            Positioned(
              right: 18,
              top: 56,
              child: StampMark(label: context.l10n.paidStamp, color: AppColors.statusPaid, fontSize: 22, animate: true),
            ),
        ],
      ),
    );
  }

  // ── 2. Your business ───────────────────────────────────────────────────────

  Widget _buildBusiness() {
    return Column(
      children: [
        Expanded(
          child: ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            children: [
              _stepTitle(context.l10n.yourBusiness, context.l10n.thisSitsAtTheTopOfEveryInvoice),
              const SizedBox(height: 20),
              _letterheadPreview(),
              const SizedBox(height: 20),
              _field(
                _nameCtrl,
                context.l10n.businessOrYourName,
                TextInputType.name,
                TextInputAction.next,
                capitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 12),
              _field(
                _addressCtrl,
                context.l10n.addressOptional,
                TextInputType.streetAddress,
                TextInputAction.newline,
                capitalization: TextCapitalization.words,
                minLines: 2,
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              _field(_emailCtrl, context.l10n.emailOptional, TextInputType.emailAddress, TextInputAction.next),
              const SizedBox(height: 12),
              _field(_phoneCtrl, context.l10n.phoneOptional, TextInputType.phone, TextInputAction.done),
            ],
          ),
        ),
        Padding(padding: const EdgeInsets.fromLTRB(24, 8, 24, 20), child: _primaryButton(context.l10n.continueAction, () => _goTo(2))),
      ],
    );
  }

  /// How the top of their invoices will look, updated as they type.
  Widget _letterheadPreview() {
    final contact = [_emailCtrl.text.trim(), _phoneCtrl.text.trim()].where((s) => s.isNotEmpty).join('  ·  ');
    // The address prints on one line here; the PDF gives it room.
    final address = _addressCtrl.text.trim().replaceAll(RegExp(r'\s*\n\s*'), ', ');
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.canvas,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.hairline),
      ),
      child: Row(
        children: [
          Semantics(
            button: true,
            label: _logoPath == null ? context.l10n.addLogo : context.l10n.changeLogo,
            child: GestureDetector(
              // The replay tour is read-only, so it does not copy a logo in.
              onTap: widget.isReplay ? null : _pickLogo,
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  // Logos are drawn on the white of the PDF.
                  color: _logoPath != null ? Colors.white : AppColors.surfaceSoft,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.hairline),
                ),
                clipBehavior: Clip.antiAlias,
                child: _logoPath != null
                    ? Image.file(File(_logoPath!), fit: BoxFit.contain)
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(AppIcons.addPhoto, color: AppColors.muted, size: 20),
                          const SizedBox(height: 2),
                          Text(context.l10n.logo, style: GoogleFonts.inter(fontSize: 10.5, color: AppColors.muted)),
                        ],
                      ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _bizName.isEmpty ? context.l10n.yourBusinessPlaceholder : _bizName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.serif(
                    fontSize: 20,
                    color: _bizName.isEmpty ? AppColors.mutedSoft : AppColors.ink,
                  ),
                ),
                if (address.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    address,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(fontSize: 12.5, color: AppColors.muted),
                  ),
                ],
                const SizedBox(height: 3),
                Text(
                  contact.isEmpty ? context.l10n.emailPhone : contact,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    color: contact.isEmpty ? AppColors.mutedSoft : AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String label,
    TextInputType type,
    TextInputAction action, {
    TextCapitalization capitalization = TextCapitalization.none,
    String? hint,
    String? softHint,
    int minLines = 1,
    int maxLines = 1,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: type,
      textInputAction: action,
      textCapitalization: capitalization,
      minLines: minLines,
      maxLines: maxLines,
      readOnly: widget.isReplay,
      style: GoogleFonts.inter(fontSize: 15.5, color: AppColors.ink),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        // A gentle nudge, never an error: odd-looking IDs still save.
        helperText: softHint,
        helperMaxLines: 2,
        helperStyle: GoogleFonts.inter(fontSize: 12, color: AppColors.muted),
      ),
    );
  }

  bool get _isIndia => _currency.code == 'INR';

  /// Shown under the tax ID when an Indian GSTIN doesn't look right.
  String? get _taxIdSoftHint {
    final v = _taxIdCtrl.text.trim().toUpperCase();
    if (!_isIndia || v.isEmpty || OnboardingScreen.gstinPattern.hasMatch(v)) return null;
    return context.l10n.aGstinIs15CharactersLike(_currency.defaultTax.taxIdHint);
  }

  /// Shown under the UPI ID when it isn't shaped like name@handle.
  String? get _upiSoftHint {
    final v = _upiCtrl.text.trim();
    if (!_isIndia || v.isEmpty || OnboardingScreen.upiPattern.hasMatch(v)) return null;
    return context.l10n.aUpiIdLooksLikeNameBank;
  }

  // ── 3. How you bill ────────────────────────────────────────────────────────

  Widget _buildDefaults() {
    final tax = _currency.defaultTax;
    final rates = {0.0, ...tax.presetRates, _taxRate}.toList()..sort();
    final quick = SupportedCurrencies.popular.take(6).toList();
    if (!quick.any((c) => c.code == _currency.code)) quick[quick.length - 1] = _currency;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            children: [
              _stepTitle(context.l10n.howYouBill, context.l10n.newInvoicesStartWithTheseEachInvoiceCan),
              const SizedBox(height: 24),
              Text(context.l10n.currencyHeading, style: _caption),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final c in quick)
                    _choice(
                      label: '${c.flag}  ${c.code}',
                      selected: c.code == _currency.code,
                      onTap: widget.isReplay ? null : () => _setCurrency(c),
                    ),
                  _choice(
                    label: context.l10n.moreChoices,
                    selected: false,
                    onTap: widget.isReplay
                        ? null
                        : () => CurrencyPickerSheet.show(
                            context,
                            selectedCode: _currency.code,
                            onCurrencySelected: (c) {
                              Navigator.pop(context);
                              _setCurrency(c);
                            },
                          ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '${context.l10n.catalogLabel(_currency.name)} · ${_currency.symbol}',
                style: GoogleFonts.inter(fontSize: 12.5, color: AppColors.muted),
              ),
              const SizedBox(height: 26),
              Text(tax.shortName.isEmpty ? context.l10n.taxHeading : context.l10n.namedTaxHeading(tax.shortName.toUpperCase()), style: _caption),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final r in rates)
                    _choice(
                      label: r == 0 ? context.l10n.noTax : '${NumberText.trim(r)}%',
                      selected: r == _taxRate,
                      onTap: widget.isReplay
                          ? null
                          : () {
                              Haptics.tap();
                              setState(() => _taxRate = r);
                            },
                    ),
                ],
              ),
              // Only someone who charges tax needs their tax ID on invoices.
              if (_taxRate != 0) ...[
                const SizedBox(height: 16),
                _field(
                  _taxIdCtrl,
                  context.l10n.optionalField(context.l10n.catalogLabel(tax.taxIdLabel)),
                  TextInputType.text,
                  TextInputAction.done,
                  capitalization: TextCapitalization.characters,
                  hint: context.l10n.catalogLabel(tax.taxIdHint),
                  softHint: _taxIdSoftHint,
                ),
              ],
              const SizedBox(height: 26),
              Text(context.l10n.paymentDue, style: _caption),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final t in OnboardingScreen.paymentTerms)
                    _choice(
                      label: context.l10n.catalogLabel(t),
                      selected: t == _terms,
                      onTap: widget.isReplay
                          ? null
                          : () {
                              Haptics.tap();
                              setState(() => _terms = t);
                            },
                    ),
                ],
              ),
            ],
          ),
        ),
        Padding(padding: const EdgeInsets.fromLTRB(24, 8, 24, 20), child: _primaryButton(context.l10n.continueAction, () => _goTo(3))),
      ],
    );
  }

  Widget _choice({required String label, required bool selected, VoidCallback? onTap}) {
    return Semantics(
      selected: selected,
      button: onTap != null,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppAnimations.fast,
          curve: AppAnimations.defaultCurve,
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : AppColors.canvas,
            borderRadius: BorderRadius.circular(9999),
            border: Border.all(color: selected ? AppColors.primary : AppColors.hairline),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: selected ? AppColors.onPrimary : AppColors.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── 4. Getting paid ────────────────────────────────────────────────────────

  Widget _buildPayment() {
    final tax = _currency.defaultTax;
    return Column(
      children: [
        Expanded(
          child: ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            children: [
              _stepTitle(
                context.l10n.gettingPaid,
                context.l10n.printedOnEveryInvoiceSoClientsKnowHow,
              ),
              const SizedBox(height: 24),
              _field(
                _upiCtrl,
                context.l10n.catalogLabel(tax.digitalPaymentLabel),
                TextInputType.emailAddress,
                TextInputAction.next,
                hint: context.l10n.catalogLabel(tax.digitalPaymentHint),
                softHint: _upiSoftHint,
              ),
              const SizedBox(height: 26),
              Text(context.l10n.bankTransfer, style: _caption),
              const SizedBox(height: 10),
              _field(
                _bankNameCtrl,
                context.l10n.bankNameSentenceCase,
                TextInputType.text,
                TextInputAction.next,
                capitalization: TextCapitalization.words,
                hint: context.l10n.catalogLabel(tax.bankNameHint),
              ),
              const SizedBox(height: 12),
              _field(
                _accountCtrl,
                context.l10n.catalogLabel(tax.bankAccountLabel),
                TextInputType.text,
                TextInputAction.next,
                hint: context.l10n.catalogLabel(tax.bankAccountHint),
              ),
              const SizedBox(height: 12),
              _field(
                _routingCtrl,
                context.l10n.catalogLabel(tax.bankRoutingLabel),
                TextInputType.text,
                TextInputAction.done,
                capitalization: TextCapitalization.characters,
                hint: context.l10n.catalogLabel(tax.bankRoutingHint),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
          child: Column(
            children: [
              _primaryButton(context.l10n.continueAction, () => _goTo(_pages - 1)),
              const SizedBox(height: 4),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: TextButton(
                  onPressed: () => _goTo(_pages - 1),
                  style: TextButton.styleFrom(foregroundColor: AppColors.muted),
                  child: Text(context.l10n.skipForNow, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Opens the sample document drawn with what was typed so far. Nothing is
  /// saved and no invoice is created, so it never counts toward a limit.
  void _openSamplePreview() {
    Haptics.tap();
    FocusScope.of(context).unfocus();
    final profile = OnboardingScreen.previewProfile(
      currencyCode: _currency.code,
      taxRate: _taxRate,
      name: _nameCtrl.text,
      address: _addressCtrl.text,
      email: _emailCtrl.text,
      phone: _phoneCtrl.text,
      taxId: _taxIdCtrl.text,
      upi: _upiCtrl.text,
      bankName: _bankNameCtrl.text,
      account: _accountCtrl.text,
      routing: _routingCtrl.text,
      logoPath: _logoPath,
    );
    final invoice = OnboardingScreen.previewInvoice(currencyCode: _currency.code, taxRate: _taxRate, terms: _terms);
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => _SamplePreviewScreen(invoice: invoice, profile: profile)),
    );
  }

  // ── 5. Done ────────────────────────────────────────────────────────────────

  Widget _buildDone() {
    final active = _page == _pages - 1;
    final isPro = context.watch<BillingService>().isPro;
    final firstName = _bizName.split(RegExp(r'\s+')).first;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
      child: LayoutBuilder(
        builder: (context, constraints) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Transform.rotate(
                          angle: 0.02,
                          child: Container(
                            width: 290,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppColors.canvas,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.hairline),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _bizName.isEmpty ? context.l10n.yourBusinessPlaceholder : _bizName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.serif(fontSize: 22, color: AppColors.ink),
                                ),
                                const SizedBox(height: 14),
                                for (final w in [0.8, 0.55, 0.7]) ...[
                                  FractionallySizedBox(
                                    widthFactor: w,
                                    child: Container(
                                      height: 7,
                                      decoration: BoxDecoration(
                                        color: AppColors.surfaceCard,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                ],
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Text(_currency.code, style: _caption),
                                    const Spacer(),
                                    Text(context.l10n.catalogLabel(_terms), style: GoogleFonts.inter(fontSize: 12.5, color: AppColors.muted)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Only stamped once the page is actually on screen.
                        if (active)
                          Positioned(
                            right: -6,
                            bottom: -16,
                            child: StampMark(label: context.l10n.ready, color: AppColors.brandAccent, fontSize: 20, animate: true),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // The illustration shrinks first; on a small phone with large text
            // the words and buttons scroll instead of running off the page.
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: constraints.maxHeight),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      firstName.isEmpty ? context.l10n.youReAllSet : context.l10n.setupCompleteFor(firstName),
                      style: AppTypography.serif(fontSize: 36, color: AppColors.ink, letterSpacing: -1.1, height: 1.08),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      widget.isReplay
                          ? context.l10n.thatSTheTourNothingWasChanged
                          : context.l10n.yourFirstInvoiceIsOneTapAwayTap,
                      style: GoogleFonts.inter(fontSize: 15, color: AppColors.muted, height: 1.45),
                    ),
                    if (!isPro && !widget.isReplay) ...[
                      const SizedBox(height: 8),
                      Text(
                        context.l10n.onboardingFreePlanLimit(FreeLimits.invoicesPerMonth),
                        style: GoogleFonts.inter(fontSize: 12.5, color: AppColors.mutedSoft, height: 1.4),
                      ),
                    ],
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: _openSamplePreview,
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.ink,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          minimumSize: const Size(0, 44),
                        ),
                        child: Text(
                          context.l10n.seeASampleWithYourDetails,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                            decorationColor: AppColors.hairline,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _primaryButton(context.l10n.createMyFirstInvoice, () => _finishOnboarding(openCreateInvoice: true)),
                    const SizedBox(height: 6),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: TextButton(
                        onPressed: () => _finishOnboarding(),
                        style: TextButton.styleFrom(foregroundColor: AppColors.ink),
                        child: Text(
                          widget.isReplay ? context.l10n.backToSettings : context.l10n.iLlLookAroundFirst,
                          style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The demo invoice drawn with the details typed during onboarding.
///
/// Rendered in memory only: no invoice row, no saved design, no limit used.
class _SamplePreviewScreen extends StatefulWidget {
  final InvoiceModel invoice;
  final BusinessProfile profile;

  const _SamplePreviewScreen({required this.invoice, required this.profile});

  @override
  State<_SamplePreviewScreen> createState() => _SamplePreviewScreenState();
}

class _SamplePreviewScreenState extends State<_SamplePreviewScreen> {
  List<MemoryImage>? _pages;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _render();
  }

  Future<void> _render() async {
    try {
      // Free users see the same watermark their real invoices will carry.
      final isPro = context.read<BillingService>().isPro;
      // The default design from Settings, if one is set; reading changes nothing.
      final design = await InvoiceRenderService.designForInvoice(null);
      final bytes = await PdfGeneratorService.generateInvoicePdf(
        invoice: widget.invoice,
        businessProfile: widget.profile,
        isPro: isPro,
        customizationConfig: design,
      );
      final images = <MemoryImage>[];
      await for (final page in Printing.raster(bytes, dpi: 150)) {
        images.add(MemoryImage(await page.toPng()));
      }
      if (mounted) {
        setState(() {
          _pages = images;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Sample preview failed: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(context.l10n.sampleInvoice, style: AppTypography.serif(fontSize: 20, color: AppColors.ink)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: AppColors.hairline),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
            child: Text(
              context.l10n.yourDetailsOnAMadeUpInvoiceNothing,
              style: GoogleFonts.inter(fontSize: 13, color: AppColors.muted),
            ),
          ),
          Expanded(child: DocumentPagesView(pages: _pages, loading: _loading)),
        ],
      ),
    );
  }
}
