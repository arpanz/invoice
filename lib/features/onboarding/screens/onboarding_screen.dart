import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/billing/billing_service.dart';
import '../../../core/models/currency_model.dart';
import '../../../core/providers/currency_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared_widgets/primary_button.dart';
import '../../../shared_widgets/custom_text_field.dart';
import '../../invoices/screens/create_invoice_screen.dart';
import '../../settings/widgets/paywall_bottom_sheet.dart';

enum BusinessType { freelancer, smallBusiness, agency, products, other }

enum OnboardingGoal {
  sendFaster,
  trackUnpaid,
  lookProfessional,
  understandRevenue,
  recurringClients,
}

/// Duolingo-Style Guided Business Journey Onboarding Screen
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final int _totalSteps = 7;

  // Flow State
  BusinessType? _selectedBusinessType;
  OnboardingGoal? _selectedGoal;
  String? _goalFeedback;

  final TextEditingController _bizNameCtrl = TextEditingController();
  final TextEditingController _bizEmailCtrl = TextEditingController();
  final TextEditingController _bizPhoneCtrl = TextEditingController();
  String? _logoPath;

  Currency _selectedCurrency = SupportedCurrencies.popular.first;
  double _taxRate = 8.875;
  String _taxName = 'Sales Tax';
  String _selectedTerms = 'Due on Receipt';

  // Animation controller for Step 1 building invoice
  late AnimationController _animCtrl;
  int _invoiceBuildStep = 0;

  @override
  void initState() {
    super.initState();
    _selectedCurrency = SupportedCurrencies.popular.first;
    _taxRate = _selectedCurrency.defaultTax.rate;
    _taxName = _selectedCurrency.defaultTax.shortName;

    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );

    _runInvoiceBuildAnimation();

    _bizNameCtrl.addListener(() => setState(() {}));
    _bizEmailCtrl.addListener(() => setState(() {}));
    _bizPhoneCtrl.addListener(() => setState(() {}));
  }

  void _runInvoiceBuildAnimation() async {
    for (int i = 1; i <= 5; i++) {
      await Future.delayed(const Duration(milliseconds: 450));
      if (mounted) {
        setState(() => _invoiceBuildStep = i);
        if (i == 5) {
          HapticFeedback.mediumImpact();
        } else {
          HapticFeedback.selectionClick();
        }
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animCtrl.dispose();
    _bizNameCtrl.dispose();
    _bizEmailCtrl.dispose();
    _bizPhoneCtrl.dispose();
    super.dispose();
  }

  void _nextPage() {
    HapticFeedback.lightImpact();
    if (_currentPage < _totalSteps - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _goToStep(int step) {
    HapticFeedback.lightImpact();
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _pickLogo() async {
    final isPro = context.read<BillingService>().isPro;
    if (!isPro) {
      PaywallBottomSheet.show(context);
      return;
    }

    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked != null) {
      setState(() => _logoPath = picked.path);
    }
  }

  Future<void> _saveBusinessProfile() async {
    final prefs = await SharedPreferences.getInstance();
    if (_bizNameCtrl.text.isNotEmpty) {
      await prefs.setString('biz_name', _bizNameCtrl.text.trim());
    }
    if (_bizEmailCtrl.text.isNotEmpty) {
      await prefs.setString('biz_email', _bizEmailCtrl.text.trim());
    }
    if (_bizPhoneCtrl.text.isNotEmpty) {
      await prefs.setString('biz_phone', _bizPhoneCtrl.text.trim());
    }
    if (_logoPath != null) {
      await prefs.setString('biz_logo_path', _logoPath!);
    }
    if (_selectedBusinessType != null) {
      await prefs.setString('business_type', _selectedBusinessType!.name);
    }
    if (_selectedGoal != null) {
      await prefs.setString('onboarding_goal', _selectedGoal!.name);
    }
  }

  Future<void> _finishOnboarding({bool openCreateInvoice = false}) async {
    await _saveBusinessProfile();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('default_payment_terms', _selectedTerms);

    if (!mounted) return;
    final currencyProvider = context.read<CurrencyProvider>();
    await currencyProvider.setCurrency(_selectedCurrency);
    if (_taxRate > 0) {
      await currencyProvider.setCustomTaxRate(_taxRate);
    }
    await currencyProvider.completeOnboarding();

    if (!mounted) return;
    if (openCreateInvoice) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const CreateInvoiceScreen()),
      );
    } else {
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top Navigation & Step Indicator Bar
            if (_currentPage > 0 && _currentPage < _totalSteps - 1)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        color: AppColors.textPrimary,
                      ),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutCubic,
                        );
                      },
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryMuted,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'STEP $_currentPage OF ${_totalSteps - 2}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primary,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => _goToStep(_totalSteps - 1),
                      child: const Text(
                        'Skip',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Top Linear Progress Tracker
            if (_currentPage > 0 && _currentPage < _totalSteps - 1)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _currentPage / (_totalSteps - 2),
                    backgroundColor: AppColors.slate200,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.primary,
                    ),
                    minHeight: 5,
                  ),
                ),
              ),

            // Main Interactive Page Content
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (index) => setState(() => _currentPage = index),
                children: [
                  _buildWelcomePage(),
                  _buildBusinessTypePage(),
                  _buildGoalPage(),
                  _buildBusinessProfilePage(),
                  _buildCurrencyPage(),
                  _buildPaymentTermsPage(),
                  _buildCelebrationPage(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // STEP 1: WELCOME WITH LIVE BUILDING INVOICE ANiMATION
  // ---------------------------------------------------------------------------
  Widget _buildWelcomePage() {
    return Column(
      children: [
        // Top Hero Stage Canvas
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Stripe/Linear-Style High Contrast Document Card Stage
                GestureDetector(
                  onTap: () {
                    setState(() => _invoiceBuildStep = 0);
                    _runInvoiceBuildAnimation();
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.25),
                        width: 1.5,
                      ),
                      boxShadow: AppColors.heroShadow,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Document Header Bar
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    gradient: AppColors.primaryGradient,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primary.withValues(
                                          alpha: 0.3,
                                        ),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.receipt_long_rounded,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _invoiceBuildStep >= 1
                                          ? 'Acme Studio'
                                          : 'Your Business Name',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w900,
                                        color: _invoiceBuildStep >= 1
                                            ? AppColors.textPrimary
                                            : AppColors.slate400,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    const Text(
                                      '#INV-2026-001',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textSecondary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: _invoiceBuildStep >= 2
                                    ? AppColors.primaryMuted
                                    : AppColors.slate100,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: _invoiceBuildStep >= 2
                                      ? AppColors.primary.withValues(alpha: 0.2)
                                      : AppColors.slate200,
                                ),
                              ),
                              child: Text(
                                _invoiceBuildStep >= 2
                                    ? 'Starlight Inc'
                                    : '+ Client Name',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: _invoiceBuildStep >= 2
                                      ? AppColors.primary
                                      : AppColors.slate500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),

                        // Itemized Table Rows
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.slate50,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.slate200),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _invoiceBuildStep >= 3
                                        ? 'Brand Strategy & App UI'
                                        : '+ Add Line Item',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: _invoiceBuildStep >= 3
                                          ? AppColors.textPrimary
                                          : AppColors.slate400,
                                    ),
                                  ),
                                  Text(
                                    _invoiceBuildStep >= 3
                                        ? '${_selectedCurrency.symbol}1,800.00'
                                        : '${_selectedCurrency.symbol}0.00',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w900,
                                      color: _invoiceBuildStep >= 3
                                          ? AppColors.textPrimary
                                          : AppColors.slate400,
                                    ),
                                  ),
                                ],
                              ),
                              if (_invoiceBuildStep >= 3) ...[
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '$_taxName (${_taxRate.toStringAsFixed(_taxRate % 1 == 0 ? 0 : 1)}%)',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textSecondary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      '${_selectedCurrency.symbol}${(1800.0 * _taxRate / 100).toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textSecondary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Grand Total & Emerald Status Tag
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'GRAND TOTAL',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.textSecondary,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                                Text(
                                  _invoiceBuildStep >= 4
                                      ? '${_selectedCurrency.symbol}2,450.00'
                                      : '${_selectedCurrency.symbol}0.00',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.primary,
                                    letterSpacing: -0.6,
                                  ),
                                ),
                              ],
                            ),
                            AnimatedScale(
                              scale: _invoiceBuildStep >= 5 ? 1.0 : 0.0,
                              duration: const Duration(milliseconds: 350),
                              curve: Curves.elasticOut,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 7,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.statusPaidBg,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: AppColors.statusPaid.withValues(
                                      alpha: 0.4,
                                    ),
                                  ),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color.fromRGBO(16, 185, 129, 0.25),
                                      blurRadius: 12,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: const [
                                    Icon(
                                      Icons.check_circle_rounded,
                                      color: AppColors.statusPaid,
                                      size: 16,
                                    ),
                                    SizedBox(width: 6),
                                    Text(
                                      'PAID & SENT',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w900,
                                        color: AppColors.statusPaid,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // Headlines
                const Text(
                  'Invoicing made\neffortless & fast.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                    letterSpacing: -1.0,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Create your first professional invoice in under 60 seconds.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Pinned Bottom Action Dock (Always visible & fixed at bottom)
        Container(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
          decoration: BoxDecoration(
            color: AppColors.background,
            border: Border(
              top: BorderSide(
                color: AppColors.cardBorder.withValues(alpha: 0.5),
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              PrimaryButton(
                label: 'Create my first invoice',
                onPressed: _nextPage,
                icon: Icons.arrow_forward_rounded,
                height: 54,
                fontSize: 16,
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => _goToStep(1),
                child: const Text(
                  'I’m just exploring',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // STEP 2: BUSINESS TYPE SELECTION
  // ---------------------------------------------------------------------------
  Widget _buildBusinessTypePage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          const Text(
            'What are you invoicing for?',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Select your primary business type to customize templates.',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),

          _GoalCard(
            icon: Icons.person_rounded,
            title: 'Freelance & Consulting',
            subtitle: 'Services, contracting, and independent work',
            selected: _selectedBusinessType == BusinessType.freelancer,
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() => _selectedBusinessType = BusinessType.freelancer);
              Future.delayed(const Duration(milliseconds: 180), _nextPage);
            },
          ),
          const SizedBox(height: 12),

          _GoalCard(
            icon: Icons.store_rounded,
            title: 'Small Business & Local Services',
            subtitle: 'Local shops, trades, agencies & services',
            selected: _selectedBusinessType == BusinessType.smallBusiness,
            onTap: () {
              HapticFeedback.lightImpact();
              setState(
                () => _selectedBusinessType = BusinessType.smallBusiness,
              );
              Future.delayed(const Duration(milliseconds: 180), _nextPage);
            },
          ),
          const SizedBox(height: 12),

          _GoalCard(
            icon: Icons.palette_rounded,
            title: 'Agency & Creative Services',
            subtitle: 'Design, software development & marketing',
            selected: _selectedBusinessType == BusinessType.agency,
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() => _selectedBusinessType = BusinessType.agency);
              Future.delayed(const Duration(milliseconds: 180), _nextPage);
            },
          ),
          const SizedBox(height: 12),

          _GoalCard(
            icon: Icons.shopping_bag_rounded,
            title: 'Products & Retail',
            subtitle: 'E-commerce, wholesale, or physical goods',
            selected: _selectedBusinessType == BusinessType.products,
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() => _selectedBusinessType = BusinessType.products);
              Future.delayed(const Duration(milliseconds: 180), _nextPage);
            },
          ),
          const SizedBox(height: 12),

          _GoalCard(
            icon: Icons.auto_awesome_rounded,
            title: 'Something else',
            subtitle: 'Custom business setup',
            selected: _selectedBusinessType == BusinessType.other,
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() => _selectedBusinessType = BusinessType.other);
              Future.delayed(const Duration(milliseconds: 180), _nextPage);
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // STEP 3: GOAL SELECTION WITH INSTANT PERSONALIZED FEEDBACK
  // ---------------------------------------------------------------------------
  Widget _buildGoalPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          const Text(
            'What do you want to\nstay on top of?',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
              letterSpacing: -0.8,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'We’ll tailor your workspace features to match your main focus.',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),

          if (_goalFeedback != null)
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.statusPaidBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.statusPaid.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.stars_rounded,
                    color: AppColors.statusPaid,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _goalFeedback!,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.statusPaid,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (_goalFeedback != null) const SizedBox(height: 20),

          _GoalCard(
            icon: Icons.bolt_rounded,
            title: 'Send invoices faster',
            subtitle: 'Instant PDF generation and sharing',
            selected: _selectedGoal == OnboardingGoal.sendFaster,
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() {
                _selectedGoal = OnboardingGoal.sendFaster;
                _goalFeedback =
                    'Perfect! We’ll help you send invoices in under 60 seconds.';
              });
              Future.delayed(const Duration(milliseconds: 350), _nextPage);
            },
          ),
          const SizedBox(height: 12),

          _GoalCard(
            icon: Icons.access_time_filled_rounded,
            title: 'Track unpaid invoices',
            subtitle: 'Overdue alerts and payment status',
            selected: _selectedGoal == OnboardingGoal.trackUnpaid,
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() {
                _selectedGoal = OnboardingGoal.trackUnpaid;
                _goalFeedback =
                    'Awesome. You will get instant alerts on overdue payments.';
              });
              Future.delayed(const Duration(milliseconds: 350), _nextPage);
            },
          ),
          const SizedBox(height: 12),

          _GoalCard(
            icon: Icons.workspace_premium_rounded,
            title: 'Look more professional',
            subtitle: 'Polished layouts, logos, and custom colors',
            selected: _selectedGoal == OnboardingGoal.lookProfessional,
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() {
                _selectedGoal = OnboardingGoal.lookProfessional;
                _goalFeedback =
                    'Great choice. Your clients will receive high-end PDF invoices.';
              });
              Future.delayed(const Duration(milliseconds: 350), _nextPage);
            },
          ),
          const SizedBox(height: 12),

          _GoalCard(
            icon: Icons.bar_chart_rounded,
            title: 'Understand my revenue',
            subtitle: 'Monthly growth charts and analytics',
            selected: _selectedGoal == OnboardingGoal.understandRevenue,
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() {
                _selectedGoal = OnboardingGoal.understandRevenue;
                _goalFeedback =
                    'Got it! Your dashboard will highlight sales trends.';
              });
              Future.delayed(const Duration(milliseconds: 350), _nextPage);
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // STEP 4: INTERACTIVE BUSINESS PROFILE WITH LIVE PREVIEW HEADER
  // ---------------------------------------------------------------------------
  Widget _buildBusinessProfilePage() {
    final nameText = _bizNameCtrl.text.trim().isEmpty
        ? 'YOUR BUSINESS NAME'
        : _bizNameCtrl.text.trim();
    final emailText = _bizEmailCtrl.text.trim();
    final phoneText = _bizPhoneCtrl.text.trim();
    final initials = nameText.length >= 2
        ? nameText.substring(0, 2).toUpperCase()
        : 'YS';

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),

          // Real Live Mini Invoice Preview Document Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.3),
                width: 1.5,
              ),
              boxShadow: AppColors.heroShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          _logoPath != null && File(_logoPath!).existsSync()
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.file(
                                    File(_logoPath!),
                                    width: 44,
                                    height: 44,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    gradient: AppColors.primaryGradient,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Center(
                                    child: Text(
                                      initials,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  nameText,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (emailText.isNotEmpty)
                                  Text(
                                    emailText,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                if (phoneText.isNotEmpty)
                                  Text(
                                    phoneText,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: AppColors.textSecondary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryMuted,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'LIVE PREVIEW',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.slate50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.slate200),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Sample Service Item',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        '${_selectedCurrency.symbol}1,200.00',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          const Text(
            'Business Profile',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'As you type, your invoice header updates above.',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.cardBorder),
              boxShadow: AppColors.cardShadow,
            ),
            child: Column(
              children: [
                GestureDetector(
                  onTap: _pickLogo,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primaryMuted,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.add_photo_alternate_rounded,
                          color: AppColors.primary,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Add Company Logo (Optional)',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (_logoPath != null)
                          const Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.statusPaid,
                            size: 20,
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                CustomTextField(
                  label: 'Business Name',
                  hint: 'e.g. Acme Studio',
                  controller: _bizNameCtrl,
                  textCapitalization: TextCapitalization.words,
                  prefixIcon: const Icon(
                    Icons.business_rounded,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 14),

                CustomTextField(
                  label: 'Email Address (Optional)',
                  hint: 'contact@acme.com',
                  controller: _bizEmailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: const Icon(
                    Icons.email_rounded,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 14),

                CustomTextField(
                  label: 'Phone Number (Optional)',
                  hint: '+1 234 567 8900',
                  controller: _bizPhoneCtrl,
                  keyboardType: TextInputType.phone,
                  prefixIcon: const Icon(
                    Icons.phone_rounded,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          PrimaryButton(
            onPressed: () {
              _saveBusinessProfile();
              _nextPage();
            },
            label: 'Continue',
            height: 54,
            fontSize: 16,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // STEP 5: CURRENCY & INLINE TAX SELECTION
  // ---------------------------------------------------------------------------
  Widget _buildCurrencyPage() {
    final popularList = SupportedCurrencies.popular;
    final defaultTax = _selectedCurrency.defaultTax;
    final presetRates = defaultTax.presetRates;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          const Text(
            'Which currency do you invoice in?',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Invoices and taxes will adapt automatically to your country.',
            style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),

          // Visual Currency Selector Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: popularList.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 2.3,
            ),
            itemBuilder: (context, index) {
              final currency = popularList[index];
              final isSelected = _selectedCurrency.code == currency.code;

              return GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() {
                    _selectedCurrency = currency;
                    _taxRate = currency.defaultTax.rate;
                    _taxName = currency.defaultTax.shortName;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primaryMuted : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.cardBorder,
                      width: isSelected ? 2.5 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.15),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : AppColors.cardShadow,
                  ),
                  child: Row(
                    children: [
                      Text(currency.flag, style: const TextStyle(fontSize: 22)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              currency.code,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              '${currency.symbol} • ${currency.countryName.isNotEmpty ? currency.countryName : currency.name}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        const Icon(
                          Icons.check_circle_rounded,
                          color: AppColors.primary,
                          size: 18,
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),

          // Button to pick any of the 35+ countries
          Center(
            child: TextButton.icon(
              onPressed: _showAllCurrenciesPicker,
              icon: const Icon(Icons.public, size: 18, color: AppColors.primary),
              label: const Text(
                'More Countries & Currencies (35+)',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Dynamic Tax Selector Section
          Text(
            defaultTax.rate == 0
                ? 'Tax Rate (${_selectedCurrency.countryName})'
                : 'Default ${defaultTax.shortName} for ${_selectedCurrency.countryName}',
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            defaultTax.description ?? 'Standard rate for ${_selectedCurrency.name}',
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),

          // Dynamic preset chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: presetRates.map((rate) {
              final label = rate == 0.0
                  ? 'No Tax (0%)'
                  : '${defaultTax.shortName} ${rate.toStringAsFixed(rate % 1 == 0 ? 0 : 1)}%';
              return _buildTaxChip(label, rate, defaultTax.shortName);
            }).toList(),
          ),
          const SizedBox(height: 28),

          PrimaryButton(
            onPressed: _nextPage,
            label:
                'Continue with ${_selectedCurrency.code} (${_selectedCurrency.symbol})',
            height: 54,
            fontSize: 16,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _showAllCurrenciesPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        String searchQuery = '';
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final filtered = SupportedCurrencies.search(searchQuery);
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: SizedBox(
                height: MediaQuery.of(ctx).size.height * 0.7,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.slate300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Select Country / Currency',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      autofocus: false,
                      decoration: InputDecoration(
                        hintText: 'Search by country, code or name...',
                        prefixIcon: const Icon(Icons.search, size: 20),
                        filled: true,
                        fillColor: AppColors.slate50,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.slate200),
                        ),
                      ),
                      onChanged: (val) => setModalState(() => searchQuery = val),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (context, index) => const Divider(height: 1),
                        itemBuilder: (ctx, idx) {
                          final c = filtered[idx];
                          final isSelected = c.code == _selectedCurrency.code;
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            leading: Text(c.flag, style: const TextStyle(fontSize: 24)),
                            title: Text(
                              '${c.countryName.isNotEmpty ? c.countryName : c.name} (${c.code})',
                              style: TextStyle(
                                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                color: isSelected ? AppColors.primary : AppColors.textPrimary,
                              ),
                            ),
                            subtitle: Text(
                              '${c.symbol} • ${c.defaultTax.shortName} (${c.defaultTax.rate}%)',
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                            trailing: isSelected
                                ? const Icon(Icons.check_circle, color: AppColors.primary)
                                : null,
                            onTap: () {
                              setState(() {
                                _selectedCurrency = c;
                                _taxRate = c.defaultTax.rate;
                                _taxName = c.defaultTax.shortName;
                              });
                              Navigator.pop(ctx);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTaxChip(String label, double rate, String taxName) {
    final isSelected = _taxRate == rate;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() {
          _taxRate = rate;
          _taxName = taxName;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.cardBorder,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.18),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : AppColors.cardShadow,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: isSelected ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // STEP 6: PAYMENT TERMS SELECTION
  // ---------------------------------------------------------------------------
  Widget _buildPaymentTermsPage() {
    final termsList = ['Due on Receipt', 'Net 15', 'Net 30', 'Net 60'];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          const Text(
            'When are your invoices\nusually due?',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
              letterSpacing: -0.8,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Pre-fills the due date whenever you create a new invoice.',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),

          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: termsList.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final term = termsList[index];
              final isSelected = _selectedTerms == term;

              return GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() => _selectedTerms = term);
                  Future.delayed(const Duration(milliseconds: 200), _nextPage);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 18,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primaryMuted : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.cardBorder,
                      width: isSelected ? 2.5 : 1,
                    ),
                    boxShadow: AppColors.cardShadow,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected
                              ? AppColors.primary
                              : Colors.transparent,
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.slate300,
                            width: isSelected ? 0 : 2,
                          ),
                        ),
                        child: isSelected
                            ? const Icon(
                                Icons.check_rounded,
                                color: Colors.white,
                                size: 18,
                              )
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Text(
                        term,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: isSelected
                              ? FontWeight.w900
                              : FontWeight.w700,
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 28),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // STEP 7: CELEBRATION & FIRST SUCCESS MOMENT
  // ---------------------------------------------------------------------------
  Widget _buildCelebrationPage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          // Celebration Icon Badge
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: AppColors.heroGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 28,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.auto_awesome_rounded,
                color: Colors.white,
                size: 48,
              ),
            ),
          ),
          const SizedBox(height: 28),

          const Text(
            'Your workspace is ready!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Everything is pre-configured to create clean PDF invoices.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 28),

          // Completion Checklist Box
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.cardBorder),
              boxShadow: AppColors.cardShadow,
            ),
            child: Column(
              children: [
                _buildCheckItem(
                  'Business profile configured',
                  _bizNameCtrl.text.trim().isEmpty
                      ? 'Acme Studio'
                      : _bizNameCtrl.text.trim(),
                ),
                const Divider(height: 24),
                _buildCheckItem(
                  'Currency & Tax set',
                  '${_selectedCurrency.code} (${_selectedCurrency.symbol}) | ${_taxRate > 0 ? "$_taxName $_taxRate%" : "No Tax"}',
                ),
                const Divider(height: 24),
                _buildCheckItem('Default due date', _selectedTerms),
                const Divider(height: 24),
                _buildCheckItem(
                  'Invoice PDF template',
                  'Clean Professional Style',
                ),
              ],
            ),
          ),
          const Spacer(),

          PrimaryButton(
            label: 'Create my first invoice',
            onPressed: () => _finishOnboarding(openCreateInvoice: true),
            icon: Icons.add_rounded,
            height: 54,
            fontSize: 16,
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => _finishOnboarding(openCreateInvoice: false),
            child: const Text(
              'Explore the dashboard',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildCheckItem(String title, String subtitle) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: const BoxDecoration(
            color: AppColors.statusPaidBg,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_rounded,
            color: AppColors.statusPaid,
            size: 16,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Custom Goal Selectable Card Widget
class _GoalCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _GoalCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.08)
              : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.cardBorder,
            width: selected ? 2.5 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.16),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ]
              : AppColors.cardShadow,
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : AppColors.primaryMuted,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(
                icon,
                color: selected ? Colors.white : AppColors.primary,
                size: 25,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: selected
                          ? AppColors.primary
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedScale(
              scale: selected ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 180),
              child: const Icon(
                Icons.check_circle_rounded,
                color: AppColors.primary,
                size: 22,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
