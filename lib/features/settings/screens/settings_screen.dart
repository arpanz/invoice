import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/ads/ad_manager.dart';
import '../../../core/ads/banner_ad_widget.dart';
import '../../../core/app/app_review_service.dart';
import '../../../core/billing/billing_service.dart';
import '../../../core/models/currency_model.dart';
import '../../../core/providers/currency_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../paywall/paywall_screen.dart';
import 'business_profile_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final billing = context.watch<BillingService>();
    final currencyProvider = context.watch<CurrencyProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (!billing.isPro) ...[
            _buildProUpsellCard(context),
            const SizedBox(height: 16),
          ] else ...[
            _buildProBadgeCard(),
            const SizedBox(height: 16),
          ],
          _buildSectionHeader('Workspace'),
          _buildListTile(
            icon: Icons.business_outlined,
            title: 'Business Profile',
            subtitle: 'Name, address, bank details, logo',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BusinessProfileScreen()),
            ),
          ),
          const SizedBox(height: 16),
          _buildSectionHeader('Preferences'),
          _buildCurrencyTile(currencyProvider.selectedCurrency),
          const Divider(height: 1, indent: 56),
          _buildTaxRateTile(currencyProvider),
          const SizedBox(height: 16),
          _buildSectionHeader('Support'),
          _buildListTile(
            icon: Icons.star_outline,
            title: 'Rate Us on Play Store',
            subtitle: 'Leave a rating for com.livinlabs.invoice',
            onTap: _showRateDialog,
            trailing: const Icon(
              Icons.open_in_new,
              size: 16,
              color: AppColors.slate400,
            ),
          ),
          const Divider(height: 1, indent: 56),
          _buildListTile(
            icon: Icons.mail_outline,
            title: 'Contact Developer',
            subtitle: 'support@invoicemakerpro.app',
            onTap: () {},
          ),
          const SizedBox(height: 16),
          _buildSectionHeader('About'),
          _buildListTile(
            icon: Icons.info_outline,
            title: 'Invoice Maker Pro',
            subtitle: 'Version 1.0.0 | 100% Offline & Private',
            onTap: null,
          ),
          const SizedBox(height: 12),
          const BannerAdWidget(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _openPaywall() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PaywallScreen()),
    );
  }

  Widget _buildProUpsellCard(BuildContext context) {
    final lifetimeProduct = AdManager.instance.products
        .where((p) => p.id == AdManager.productId)
        .firstOrNull;
    final priceLabel = lifetimeProduct?.price ?? 'PRO';

    return GestureDetector(
      onTap: _openPaywall,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1E293B), Color(0xFF334155)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.proGold,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.workspace_premium,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Unlock Pro Workspace',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Remove watermarks and ads. Add your logo.',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.proGold,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                priceLabel,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProBadgeCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.statusPaidBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.statusPaid.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified, color: AppColors.statusPaid, size: 28),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pro Workspace Active',
                  style: TextStyle(
                    color: AppColors.statusPaid,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Watermarks removed | Ads disabled | Logo enabled',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: AppColors.slate600, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
    Widget? trailing,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: ListTile(
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.slate100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: AppColors.slate600),
        ),
        title: Text(
          title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        trailing:
            trailing ??
            (onTap != null
                ? const Icon(Icons.chevron_right, color: AppColors.slate400)
                : null),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildCurrencyTile(Currency selectedCurrency) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: ListTile(
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.slate100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.currency_exchange,
            size: 18,
            color: AppColors.slate600,
          ),
        ),
        title: const Text(
          'Default Currency',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${selectedCurrency.symbol} ${selectedCurrency.code}',
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        trailing: const Icon(Icons.chevron_right, color: AppColors.slate400),
        onTap: () => _showCurrencyPicker(context),
      ),
    );
  }

  void _showCurrencyPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CurrencyPickerSheet(
        onCurrencySelected: (currency) {
          context.read<CurrencyProvider>().setCurrency(currency);
          Navigator.pop(ctx);
        },
      ),
    );
  }

  Widget _buildTaxRateTile(CurrencyProvider currencyProvider) {
    final defaultTax = currencyProvider.defaultTax;
    final sourceLabel = currencyProvider.hasCustomTaxRate
        ? 'Custom ${defaultTax.shortName} rate'
        : defaultTax.name;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: ListTile(
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.slate100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.percent, size: 18, color: AppColors.slate600),
        ),
        title: Text(
          'Default ${defaultTax.shortName} Rate',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${defaultTax.rate}% | $sourceLabel',
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        trailing: Text(
          '${defaultTax.rate}%',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
        onTap: _showTaxRateEditor,
      ),
    );
  }

  Future<void> _showTaxRateEditor() async {
    final currencyProvider = context.read<CurrencyProvider>();
    final currentRate = currencyProvider.defaultTax.rate;
    final controller = TextEditingController(text: currentRate.toString());
    final formKey = GlobalKey<FormState>();

    final action = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
        child: _SettingsActionSheet(
          icon: Icons.percent_rounded,
          iconColor: AppColors.primary,
          iconBackground: AppColors.primaryLight.withOpacity(0.12),
          title: 'Edit ${currencyProvider.defaultTax.shortName} rate',
          subtitle: 'Set the default tax rate used when you create invoices.',
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Tax Rate (%)',
                hintText: 'e.g. 8.875',
              ),
              validator: (value) {
                final parsed = double.tryParse((value ?? '').trim());
                if (parsed == null) return 'Enter a valid number';
                if (parsed < 0 || parsed > 100) {
                  return 'Use a value between 0 and 100';
                }
                return null;
              },
            ),
          ),
          footer: Row(
            children: [
              if (currencyProvider.hasCustomTaxRate)
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx, 'reset'),
                    child: const Text('Reset'),
                  ),
                ),
              if (currencyProvider.hasCustomTaxRate) const SizedBox(width: 12),
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      Navigator.pop(ctx, 'save');
                    }
                  },
                  child: const Text('Save'),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (action == 'reset') {
      await currencyProvider.clearCustomTaxRate();
      return;
    }

    if (action == 'save') {
      final parsed = double.tryParse(controller.text.trim());
      if (parsed != null) {
        await currencyProvider.setCustomTaxRate(parsed);
      }
    }
  }

  Future<void> _showRateDialog() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _SettingsActionSheet(
        icon: Icons.favorite_outline,
        iconColor: AppColors.proGold,
        iconBackground: AppColors.proGoldLight,
        title: 'Rate us on Play Store',
        subtitle: 'Open the Play Store listing for com.livinlabs.invoice.',
        content: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.slate50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: const Text(
            'Your rating helps other business owners discover the app and gives us a clear signal about what is working well.',
            style: TextStyle(
              fontSize: 13,
              height: 1.45,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        footer: Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Maybe later'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  final opened = await AppReviewService.instance
                      .openPlayStoreListing();
                  if (!mounted) return;
                  _showStatusSnackBar(
                    opened
                        ? 'Opening Play Store...'
                        : 'Play Store rating is not available on this device yet.',
                  );
                },
                child: const Text('Open Play Store'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showStatusSnackBar(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }
}

class _SettingsActionSheet extends StatelessWidget {
  const _SettingsActionSheet({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.title,
    required this.subtitle,
    required this.content,
    required this.footer,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String title;
  final String subtitle;
  final Widget content;
  final Widget footer;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
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
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.slate300,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: iconColor, size: 26),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.45,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 20),
              content,
              const SizedBox(height: 20),
              footer,
            ],
          ),
        ),
      ),
    );
  }
}

class _CurrencyPickerSheet extends StatefulWidget {
  final Function(Currency) onCurrencySelected;
  const _CurrencyPickerSheet({required this.onCurrencySelected});

  @override
  State<_CurrencyPickerSheet> createState() => _CurrencyPickerSheetState();
}

class _CurrencyPickerSheetState extends State<_CurrencyPickerSheet> {
  List<Currency> _filteredCurrencies = SupportedCurrencies.all;

  void _filterCurrencies(String query) {
    setState(() {
      _filteredCurrencies = query.isEmpty
          ? SupportedCurrencies.all
          : SupportedCurrencies.search(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    final selectedCurrency = context.watch<CurrencyProvider>().selectedCurrency;

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.slate300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Select Currency',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.slate100,
                borderRadius: BorderRadius.circular(12),
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
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              itemCount: _filteredCurrencies.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final currency = _filteredCurrencies[index];
                final isSelected = currency.code == selectedCurrency.code;

                return Material(
                  color: isSelected
                      ? AppColors.primaryLight.withOpacity(0.1)
                      : AppColors.slate50,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: () => widget.onCurrencySelected(currency),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.cardBorder,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            currency.flag,
                            style: const TextStyle(fontSize: 24),
                          ),
                          const SizedBox(width: 16),
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
                                Text(
                                  currency.name,
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
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
                          if (isSelected) ...[
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.check_circle,
                              color: AppColors.primary,
                              size: 24,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
