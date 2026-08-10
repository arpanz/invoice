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
import '../../settings/widgets/paywall_bottom_sheet.dart';

/// Beautiful onboarding screen with currency selection and setup
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      title: 'Create Professional\nInvoices',
      description:
          'Generate beautiful, professional invoices in seconds. Impress your clients with stunning designs.',
      illustration: const _InvoiceIllustration(),
    ),
    OnboardingPage(
      title: 'Manage Your\nClients',
      description:
          'Keep all your client information organized. Never lose track of who owes you money.',
      illustration: const _ClientsIllustration(),
    ),
    OnboardingPage(
      title: 'Track Your\nRevenue',
      description:
          'Monitor your business performance with detailed analytics and insights.',
      illustration: const _ChartIllustration(),
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    HapticFeedback.lightImpact();
    if (_currentPage < _pages.length + 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  void _skipToCurrency() {
    HapticFeedback.lightImpact();
    _pageController.animateToPage(
      _pages.length + 1,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isFinalPage = _currentPage == _pages.length + 3;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            if (!isFinalPage && _currentPage < _pages.length + 1)
              Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  onPressed: _skipToCurrency,
                  child: const Text(
                    'Skip',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              )
            else
              const SizedBox(height: 48), // Spacer when skip is hidden
            // Page view
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics:
                    const NeverScrollableScrollPhysics(), // Disable swipe to force using buttons/forms
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemCount: _pages.length + 4,
                itemBuilder: (context, index) {
                  if (index < _pages.length) {
                    return _OnboardingPageWidget(
                      page: _pages[index],
                      index: index,
                      currentIndex: _currentPage,
                    );
                  } else if (index == _pages.length) {
                    return _BusinessSetupPage(onNext: _nextPage);
                  } else if (index == _pages.length + 1) {
                    return CurrencySelectionPage(onNext: _nextPage);
                  } else if (index == _pages.length + 2) {
                    return _PaymentDetailsPage(onNext: _nextPage);
                  } else {
                    return const _PaymentTermsPage();
                  }
                },
              ),
            ),

            // Bottom controls: Indicator and Next button (Only for feature slides)
            if (_currentPage < _pages.length)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 24,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Page indicator
                    Row(
                      children: List.generate(
                        _pages.length,
                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          height: 8,
                          width: _currentPage == index ? 24 : 8,
                          decoration: BoxDecoration(
                            color: _currentPage == index
                                ? AppColors.primary
                                : AppColors.slate300,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                    // Next / Continue button
                    InkWell(
                      onTap: _nextPage,
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Next',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(
                              Icons.arrow_forward_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Individual onboarding page widget (Feature Slides)
class _OnboardingPageWidget extends StatelessWidget {
  final OnboardingPage page;
  final int index;
  final int currentIndex;

  const _OnboardingPageWidget({
    required this.page,
    required this.index,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = index == currentIndex;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: TweenAnimationBuilder<double>(
        key: ValueKey(index),
        tween: Tween(begin: 0.0, end: isActive ? 1.0 : 0.0),
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, 20 * (1 - value)),
              child: child,
            ),
          );
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            page.illustration,
            const SizedBox(height: 48),
            // Title
            Text(
              page.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 16),
            // Description
            Text(
              page.description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}

/// Data class for onboarding pages
class OnboardingPage {
  final String title;
  final String description;
  final Widget illustration;

  OnboardingPage({
    required this.title,
    required this.description,
    required this.illustration,
  });
}

class _InvoiceIllustration extends StatelessWidget {
  const _InvoiceIllustration();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      height: 160,
      decoration: const BoxDecoration(
        color: AppColors.slate50,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Transform.rotate(
          angle: -0.05,
          child: Container(
            width: 100,
            height: 130,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    Container(
                      width: 30,
                      height: 6,
                      decoration: BoxDecoration(
                        color: AppColors.slate200,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  height: 6,
                  decoration: BoxDecoration(
                    color: AppColors.slate100,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 40,
                  height: 6,
                  decoration: BoxDecoration(
                    color: AppColors.slate100,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const Spacer(),
                Container(
                  width: double.infinity,
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Center(
                    child: Container(
                      width: 30,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ClientsIllustration extends StatelessWidget {
  const _ClientsIllustration();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      height: 160,
      decoration: const BoxDecoration(
        color: AppColors.slate50,
        shape: BoxShape.circle,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform.translate(
            offset: const Offset(-15, -15),
            child: _buildMiniClientCard(opacity: 0.6),
          ),
          Transform.translate(
            offset: const Offset(15, 15),
            child: _buildMiniClientCard(opacity: 1.0, hasBorder: true),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniClientCard({
    required double opacity,
    bool hasBorder = false,
  }) {
    return Container(
      width: 110,
      height: 60,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: opacity),
        borderRadius: BorderRadius.circular(12),
        border: hasBorder ? Border.all(color: AppColors.cardBorder) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04 * opacity),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 36,
                height: 6,
                decoration: BoxDecoration(
                  color: AppColors.slate300,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(height: 6),
              Container(
                width: 24,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.slate200,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChartIllustration extends StatelessWidget {
  const _ChartIllustration();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      height: 160,
      decoration: const BoxDecoration(
        color: AppColors.slate50,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Container(
          width: 110,
          height: 100,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildBar(height: 30, color: AppColors.slate200),
              _buildBar(height: 50, color: AppColors.slate200),
              _buildBar(
                height: 40,
                color: AppColors.accentOrange.withValues(alpha: 0.4),
              ),
              _buildBar(height: 60, color: AppColors.accentOrange),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBar({required double height, required Color color}) {
    return Container(
      width: 12,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// SETUP PAGES
// -----------------------------------------------------------------------------

class _BusinessSetupPage extends StatefulWidget {
  final VoidCallback onNext;
  const _BusinessSetupPage({required this.onNext});

  @override
  State<_BusinessSetupPage> createState() => _BusinessSetupPageState();
}

class _BusinessSetupPageState extends State<_BusinessSetupPage> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  String? _logoPath;

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

  Future<void> _saveAndNext() async {
    final prefs = await SharedPreferences.getInstance();
    if (_nameCtrl.text.isNotEmpty) {
      await prefs.setString('biz_name', _nameCtrl.text.trim());
    }
    if (_emailCtrl.text.isNotEmpty) {
      await prefs.setString('biz_email', _emailCtrl.text.trim());
    }
    if (_phoneCtrl.text.isNotEmpty) {
      await prefs.setString('biz_phone', _phoneCtrl.text.trim());
    }
    if (_logoPath != null) {
      await prefs.setString('biz_logo_path', _logoPath!);
    }
    widget.onNext();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPro = context.watch<BillingService>().isPro;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, 20 * (1 - value)),
              child: child,
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            const Text(
              'Business Details',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Set up your profile to look professional on your invoices.',
              style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 32),

            // Group fields in a nice card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.cardBorder),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Prominent Logo Picker
                  GestureDetector(
                    onTap: _pickLogo,
                    child: Container(
                      height: 140,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.slate50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.slate200, width: 2),
                      ),
                      child: _logoPath != null && File(_logoPath!).existsSync()
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Image.file(
                                File(_logoPath!),
                                fit: BoxFit.contain,
                              ),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.04,
                                        ),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    isPro
                                        ? Icons.add_photo_alternate_rounded
                                        : Icons.lock_outline_rounded,
                                    color: AppColors.primary,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  isPro
                                      ? 'Upload Company Logo'
                                      : 'Pro Feature: Add Logo',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                if (!isPro) ...[
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Tap to unlock',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  CustomTextField(
                    label: 'Business Name',
                    hint: 'e.g. Acme Corp',
                    controller: _nameCtrl,
                    textCapitalization: TextCapitalization.words,
                    prefixIcon: const Icon(
                      Icons.business_rounded,
                      color: AppColors.slate400,
                    ),
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    label: 'Email (Optional)',
                    hint: 'e.g. contact@acme.com',
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: const Icon(
                      Icons.email_rounded,
                      color: AppColors.slate400,
                    ),
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    label: 'Phone (Optional)',
                    hint: 'e.g. +1 234 567 8900',
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    prefixIcon: const Icon(
                      Icons.phone_rounded,
                      color: AppColors.slate400,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              child: PrimaryButton(onPressed: _saveAndNext, label: 'Continue'),
            ),
            const SizedBox(height: 16),
            Center(
              child: TextButton(
                onPressed: widget.onNext,
                child: const Text(
                  'Skip for now',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Currency selection page
class CurrencySelectionPage extends StatefulWidget {
  final VoidCallback onNext;
  const CurrencySelectionPage({super.key, required this.onNext});

  @override
  State<CurrencySelectionPage> createState() => _CurrencySelectionPageState();
}

class _CurrencySelectionPageState extends State<CurrencySelectionPage> {
  String _searchQuery = '';
  List<Currency> _filteredCurrencies = SupportedCurrencies.all;

  void _filterCurrencies(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredCurrencies = SupportedCurrencies.all;
      } else {
        _filteredCurrencies = SupportedCurrencies.search(query);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, 20 * (1 - value)),
              child: child,
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            // Header
            const Text(
              'Select Your Currency',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'This will be your default currency for invoices',
              style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            // Search bar
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cardBorder),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                onChanged: _filterCurrencies,
                decoration: const InputDecoration(
                  hintText: 'Search currency...',
                  hintStyle: TextStyle(color: AppColors.textHint),
                  prefixIcon: Icon(
                    Icons.search,
                    color: AppColors.textSecondary,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Popular currencies
            if (_searchQuery.isEmpty) ...[
              const Text(
                'Popular Currencies',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: SupportedCurrencies.popular
                    .map(
                      (currency) => _CurrencyChip(
                        currency: currency,
                        onTap: () {
                          HapticFeedback.lightImpact();
                          _selectCurrency(context, currency);
                        },
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 24),
            ],
            // All currencies
            Text(
              _searchQuery.isEmpty ? 'All Currencies' : 'Search Results',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            // Currency list
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _filteredCurrencies.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final currency = _filteredCurrencies[index];
                return _CurrencyListTile(
                  currency: currency,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    _selectCurrency(context, currency);
                  },
                );
              },
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _selectCurrency(BuildContext context, Currency currency) async {
    final currencyProvider = context.read<CurrencyProvider>();
    await currencyProvider.setCurrency(currency);

    if (!context.mounted) return;

    final currentRate = currency.defaultTax.rate;
    final controller = TextEditingController(text: currentRate.toString());
    final formKey = GlobalKey<FormState>();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: AppColors.cardBorder),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 28,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Confirm Tax Rate',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Set the default tax rate for ${currency.code}. You can always change this later in Settings.',
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.45,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Form(
                    key: formKey,
                    child: TextFormField(
                      controller: controller,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      autofocus: true,
                      decoration: InputDecoration(
                        labelText: '${currency.defaultTax.shortName} Rate (%)',
                        hintText: 'e.g. 8.875',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        final parsed = double.tryParse((value ?? '').trim());
                        if (parsed == null) return 'Enter a valid number';
                        if (parsed < 0 || parsed > 100) return 'Must be 0-100';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () async {
                        if (formKey.currentState!.validate()) {
                          final parsed = double.tryParse(
                            controller.text.trim(),
                          );
                          if (parsed != null && parsed != currentRate) {
                            await currencyProvider.setCustomTaxRate(parsed);
                          }
                          if (ctx.mounted) {
                            Navigator.of(ctx).pop();
                          }
                          widget.onNext();
                        }
                      },
                      child: const Text(
                        'Confirm & Continue',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PaymentDetailsPage extends StatefulWidget {
  final VoidCallback onNext;
  const _PaymentDetailsPage({required this.onNext});

  @override
  State<_PaymentDetailsPage> createState() => _PaymentDetailsPageState();
}

class _PaymentDetailsPageState extends State<_PaymentDetailsPage> {
  final _bankCtrl = TextEditingController();
  final _accCtrl = TextEditingController();
  final _ifscCtrl = TextEditingController();
  final _upiCtrl = TextEditingController();

  Future<void> _saveAndNext() async {
    final prefs = await SharedPreferences.getInstance();
    if (_bankCtrl.text.isNotEmpty) {
      await prefs.setString('biz_bank_name', _bankCtrl.text.trim());
    }
    if (_accCtrl.text.isNotEmpty) {
      await prefs.setString('biz_account', _accCtrl.text.trim());
    }
    if (_ifscCtrl.text.isNotEmpty) {
      await prefs.setString('biz_ifsc', _ifscCtrl.text.trim());
    }
    if (_upiCtrl.text.isNotEmpty) {
      await prefs.setString(
        'biz_upi',
        _upiCtrl.text.trim(),
      ); // using generic 'upi' key for payment instruction
    }
    widget.onNext();
  }

  @override
  void dispose() {
    _bankCtrl.dispose();
    _accCtrl.dispose();
    _ifscCtrl.dispose();
    _upiCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, 20 * (1 - value)),
              child: child,
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            const Text(
              'How to Pay You',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Enter your payment details so clients know how to pay. (Optional)',
              style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 32),

            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.cardBorder),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  CustomTextField(
                    label: 'Bank Name',
                    hint: 'e.g. Chase, SBI',
                    controller: _bankCtrl,
                    textCapitalization: TextCapitalization.words,
                    prefixIcon: const Icon(
                      Icons.account_balance_rounded,
                      color: AppColors.slate400,
                    ),
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    label: 'Account Number',
                    hint: 'e.g. 1234567890',
                    controller: _accCtrl,
                    keyboardType: TextInputType.number,
                    prefixIcon: const Icon(
                      Icons.numbers_rounded,
                      color: AppColors.slate400,
                    ),
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    label: 'Routing / IFSC Code',
                    hint: 'e.g. CHASUS33',
                    controller: _ifscCtrl,
                    textCapitalization: TextCapitalization.characters,
                    prefixIcon: const Icon(
                      Icons.account_tree_rounded,
                      color: AppColors.slate400,
                    ),
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    label: 'UPI / PayPal / Other',
                    hint: 'e.g. PayPal: user@email.com',
                    controller: _upiCtrl,
                    prefixIcon: const Icon(
                      Icons.payment_rounded,
                      color: AppColors.slate400,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              child: PrimaryButton(onPressed: _saveAndNext, label: 'Continue'),
            ),
            const SizedBox(height: 16),
            Center(
              child: TextButton(
                onPressed: widget.onNext,
                child: const Text(
                  'Skip for now',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentTermsPage extends StatefulWidget {
  const _PaymentTermsPage();

  @override
  State<_PaymentTermsPage> createState() => _PaymentTermsPageState();
}

class _PaymentTermsPageState extends State<_PaymentTermsPage> {
  final List<String> _termsOptions = [
    'Due on Receipt',
    'Net 15',
    'Net 30',
    'Net 45',
    'Net 60',
  ];
  String? _selectedTerms;

  Future<void> _finishOnboarding(BuildContext context) async {
    if (_selectedTerms != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('default_payment_terms', _selectedTerms!);
    }

    if (!context.mounted) return;

    final currencyProvider = context.read<CurrencyProvider>();
    await currencyProvider.completeOnboarding();

    if (context.mounted) {
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, 20 * (1 - value)),
              child: child,
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            const Text(
              'Default Payment Terms',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'When are your invoices usually due? This will be pre-filled on new invoices.',
              style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 32),

            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _termsOptions.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final term = _termsOptions[index];
                final isSelected = _selectedTerms == term;
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() => _selectedTerms = term);
                    // Add a tiny delay so the user sees the selection before navigating away
                    Future.delayed(const Duration(milliseconds: 150), () {
                      _finishOnboarding(context);
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withValues(alpha: 0.05)
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.cardBorder,
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: [
                        if (!isSelected)
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.slate300,
                              width: isSelected ? 7 : 2,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          term,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
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
            const SizedBox(height: 32),

            Center(
              child: TextButton(
                onPressed: () => _finishOnboarding(context),
                child: const Text(
                  'Skip for now',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Currency chip widget for popular currencies
class _CurrencyChip extends StatelessWidget {
  final Currency currency;
  final VoidCallback onTap;

  const _CurrencyChip({required this.currency, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(currency.flag, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text(
                currency.code,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                currency.symbol,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Currency list tile widget
class _CurrencyListTile extends StatelessWidget {
  final Currency currency;
  final VoidCallback onTap;

  const _CurrencyListTile({required this.currency, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Row(
            children: [
              // Flag
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.slate100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    currency.flag,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Currency info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          currency.code,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          currency.symbol,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      currency.name,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              // Tax info
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: currency.defaultTax.rate > 0
                          ? AppColors.primaryLight.withValues(alpha: 0.1)
                          : AppColors.accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      currency.defaultTax.rate > 0
                          ? '${currency.defaultTax.rate}% ${currency.defaultTax.shortName}'
                          : 'No Tax',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: currency.defaultTax.rate > 0
                            ? AppColors.primary
                            : AppColors.accent,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: AppColors.slate300),
            ],
          ),
        ),
      ),
    );
  }
}
