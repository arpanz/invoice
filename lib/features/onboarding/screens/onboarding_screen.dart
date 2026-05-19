import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/currency_model.dart';
import '../../../core/providers/currency_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared_widgets/primary_button.dart';

/// Beautiful onboarding screen with currency selection
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
      description: 'Generate beautiful, professional invoices in seconds. Impress your clients with stunning designs.',
      illustration: const _InvoiceIllustration(),
    ),
    OnboardingPage(
      title: 'Manage Your\nClients',
      description: 'Keep all your client information organized. Never lose track of who owes you money.',
      illustration: const _ClientsIllustration(),
    ),
    OnboardingPage(
      title: 'Track Your\nRevenue',
      description: 'Monitor your business performance with detailed analytics and insights.',
      illustration: const _ChartIllustration(),
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _pages.length) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: () => _showCurrencySelection(context),
                child: const Text(
                  'Skip',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            // Page view
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemCount: _pages.length + 1, // +1 for currency selection
                itemBuilder: (context, index) {
                  if (index < _pages.length) {
                    return _OnboardingPageWidget(page: _pages[index]);
                  } else {
                    return const CurrencySelectionPage();
                  }
                },
              ),
            ),
            // Page indicator
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _pages.length + 1,
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
            ),
          ],
        ),
      ),
    );
  }

  void _showCurrencySelection(BuildContext context) {
    _pageController.animateToPage(
      _pages.length,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }
}

/// Individual onboarding page widget
class _OnboardingPageWidget extends StatelessWidget {
  final OnboardingPage page;

  const _OnboardingPageWidget({required this.page});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
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
                  color: Colors.black.withOpacity(0.05),
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
                        color: AppColors.primary.withOpacity(0.2),
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
                        color: Colors.white.withOpacity(0.5),
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

  Widget _buildMiniClientCard({required double opacity, bool hasBorder = false}) {
    return Container(
      width: 110,
      height: 60,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(opacity),
        borderRadius: BorderRadius.circular(12),
        border: hasBorder ? Border.all(color: AppColors.cardBorder) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04 * opacity),
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
              color: AppColors.accent.withOpacity(0.2),
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
                color: Colors.black.withOpacity(0.05),
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
              _buildBar(height: 40, color: AppColors.accentOrange.withOpacity(0.4)),
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

/// Currency selection page
class CurrencySelectionPage extends StatefulWidget {
  const CurrencySelectionPage({super.key});

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
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
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
                  color: Colors.black.withOpacity(0.04),
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
                prefixIcon: Icon(Icons.search, color: AppColors.textSecondary),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                  .map((currency) => _CurrencyChip(
                        currency: currency,
                        onTap: () => _selectCurrency(context, currency),
                      ))
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
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final currency = _filteredCurrencies[index];
              return _CurrencyListTile(
                currency: currency,
                onTap: () => _selectCurrency(context, currency),
              );
            },
          ),
          const SizedBox(height: 32),
        ],
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
      isDismissible: false,
      enableDrag: false,
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
                    color: Colors.black.withOpacity(0.08),
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
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
                          final parsed = double.tryParse(controller.text.trim());
                          if (parsed != null && parsed != currentRate) {
                            await currencyProvider.setCustomTaxRate(parsed);
                          }
                          await currencyProvider.completeOnboarding();
                          if (ctx.mounted) {
                            Navigator.of(ctx).pop();
                          }
                          if (context.mounted) {
                            Navigator.of(context).pushReplacementNamed('/home');
                          }
                        }
                      },
                      child: const Text(
                        'Confirm & Continue',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
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
              Text(
                currency.flag,
                style: const TextStyle(fontSize: 20),
              ),
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
                style: const TextStyle(
                  color: AppColors.textSecondary,
                ),
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
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: currency.defaultTax.rate > 0
                          ? AppColors.primaryLight.withOpacity(0.1)
                          : AppColors.accent.withOpacity(0.1),
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
              const Icon(
                Icons.chevron_right,
                color: AppColors.slate300,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
