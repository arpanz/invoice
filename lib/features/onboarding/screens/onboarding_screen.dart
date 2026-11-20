import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/models/currency_model.dart';
import '../../../core/providers/currency_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/image_store.dart';
import '../../../core/utils/number_text.dart';
import '../../../shared_widgets/currency_picker_sheet.dart';
import '../../../shared_widgets/paper.dart';
import '../../invoices/screens/create_invoice_screen.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_animations.dart';

/// First run: welcome, your business, how you bill, done.
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

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const _pages = 4;
  final _pageController = PageController();
  int _page = 0;
  bool _finishing = false;

  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  String? _logoPath;

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
    for (final c in [_nameCtrl, _emailCtrl, _phoneCtrl]) {
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
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _goTo(int page) {
    FocusScope.of(context).unfocus();
    Haptics.tap();
    _pageController.animateToPage(page, duration: AppAnimations.slow, curve: AppAnimations.defaultCurve);
  }

  void _setCurrency(Currency c) {
    Haptics.tap();
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
          const SnackBar(content: Text('Could not save your details. Please try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final showBar = _page == 1 || _page == 2;
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
                  children: [_buildWelcome(), _buildBusiness(), _buildDefaults(), _buildDone()],
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
            tooltip: 'Back',
            onPressed: () => _goTo(_page - 1),
            icon: Icon(AppIcons.arrowBack, color: AppColors.ink),
          ),
          const Spacer(),
          // Two steps, two dashes.
          for (var i = 1; i <= 2; i++)
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
            child: Text('Skip', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
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
          Text('INVOICE MAKER PRO', style: _caption),
          Expanded(
            child: Center(
              child: FittedBox(fit: BoxFit.scaleDown, child: _sampleInvoice()),
            ),
          ),
          Text(
            'Get paid,\nbeautifully.',
            style: AppTypography.serif(fontSize: 40, color: AppColors.ink, letterSpacing: -1.3, height: 1.05),
          ),
          const SizedBox(height: 10),
          Text(
            'Make an invoice in under a minute. Stamp it paid when the money lands.',
            style: GoogleFonts.inter(fontSize: 15, color: AppColors.muted, height: 1.45),
          ),
          const SizedBox(height: 28),
          _primaryButton(widget.isReplay ? 'Start the tour' : 'Get started', () => _goTo(1)),
          const SizedBox(height: 10),
          Center(
            child: Text('Takes about 30 seconds', style: GoogleFonts.inter(fontSize: 12.5, color: AppColors.mutedSoft)),
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
                      Text('Invoice', style: AppTypography.serif(fontSize: 22, color: AppColors.ink)),
                      const Spacer(),
                      Text('#0001', style: small),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                line(2, Text('Bill to  ·  Studio North', style: small)),
                const SizedBox(height: 14),
                line(3, Column(children: [item('Logo design', 1200), item('Brand guide', 600)])),
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
                            'Total',
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
              child: StampMark(label: 'PAID', color: AppColors.statusPaid, fontSize: 22, animate: true),
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
              _stepTitle('Your business', 'This sits at the top of every invoice. You can change it any time.'),
              const SizedBox(height: 20),
              _letterheadPreview(),
              const SizedBox(height: 20),
              _field(
                _nameCtrl,
                'Business or your name',
                TextInputType.name,
                TextInputAction.next,
                capitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 12),
              _field(_emailCtrl, 'Email (optional)', TextInputType.emailAddress, TextInputAction.next),
              const SizedBox(height: 12),
              _field(_phoneCtrl, 'Phone (optional)', TextInputType.phone, TextInputAction.done),
            ],
          ),
        ),
        Padding(padding: const EdgeInsets.fromLTRB(24, 8, 24, 20), child: _primaryButton('Continue', () => _goTo(2))),
      ],
    );
  }

  /// How the top of their invoices will look, updated as they type.
  Widget _letterheadPreview() {
    final contact = [_emailCtrl.text.trim(), _phoneCtrl.text.trim()].where((s) => s.isNotEmpty).join('  ·  ');
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
            label: _logoPath == null ? 'Add logo' : 'Change logo',
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
                          Text('Logo', style: GoogleFonts.inter(fontSize: 10.5, color: AppColors.muted)),
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
                  _bizName.isEmpty ? 'Your Business' : _bizName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.serif(
                    fontSize: 20,
                    color: _bizName.isEmpty ? AppColors.mutedSoft : AppColors.ink,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  contact.isEmpty ? 'email  ·  phone' : contact,
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
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: type,
      textInputAction: action,
      textCapitalization: capitalization,
      readOnly: widget.isReplay,
      style: GoogleFonts.inter(fontSize: 15.5, color: AppColors.ink),
      decoration: InputDecoration(labelText: label),
    );
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
              _stepTitle('How you bill', 'New invoices start with these. Each invoice can still change them.'),
              const SizedBox(height: 24),
              Text('CURRENCY', style: _caption),
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
                    label: 'More…',
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
                '${_currency.name} · ${_currency.symbol}',
                style: GoogleFonts.inter(fontSize: 12.5, color: AppColors.muted),
              ),
              const SizedBox(height: 26),
              Text(tax.shortName.isEmpty ? 'TAX' : 'TAX · ${tax.shortName.toUpperCase()}', style: _caption),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final r in rates)
                    _choice(
                      label: r == 0 ? 'No tax' : '${NumberText.trim(r)}%',
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
              const SizedBox(height: 26),
              Text('PAYMENT DUE', style: _caption),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final t in OnboardingScreen.paymentTerms)
                    _choice(
                      label: t,
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
        Padding(padding: const EdgeInsets.fromLTRB(24, 8, 24, 20), child: _primaryButton('Continue', () => _goTo(3))),
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

  // ── 4. Done ────────────────────────────────────────────────────────────────

  Widget _buildDone() {
    final active = _page == 3;
    final firstName = _bizName.split(RegExp(r'\s+')).first;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
      child: Column(
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
                                _bizName.isEmpty ? 'Your Business' : _bizName,
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
                                  Text(_terms, style: GoogleFonts.inter(fontSize: 12.5, color: AppColors.muted)),
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
                          child: StampMark(label: 'READY', color: AppColors.brandAccent, fontSize: 20, animate: true),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Text(
            firstName.isEmpty ? 'You\'re all set.' : 'You\'re all set,\n$firstName.',
            style: AppTypography.serif(fontSize: 36, color: AppColors.ink, letterSpacing: -1.1, height: 1.08),
          ),
          const SizedBox(height: 10),
          Text(
            widget.isReplay
                ? 'That\'s the tour. Nothing was changed.'
                : 'Your first invoice is one tap away. Tap + at the bottom any time to make another.',
            style: GoogleFonts.inter(fontSize: 15, color: AppColors.muted, height: 1.45),
          ),
          const SizedBox(height: 28),
          _primaryButton('Create my first invoice', () => _finishOnboarding(openCreateInvoice: true)),
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: TextButton(
              onPressed: () => _finishOnboarding(),
              style: TextButton.styleFrom(foregroundColor: AppColors.ink),
              child: Text(
                widget.isReplay ? 'Back to settings' : 'I\'ll look around first',
                style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
