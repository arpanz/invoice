import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/app/app_review_service.dart';
import '../../../core/billing/billing_service.dart';
import '../../../core/models/currency_model.dart';
import '../../../core/providers/currency_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../invoices/models/pdf_theme.dart';
import '../../invoices/widgets/pdf_theme_picker_sheet.dart';
import '../../onboarding/screens/onboarding_screen.dart';
import '../../paywall/paywall_screen.dart';
import 'business_profile_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  PdfTheme _defaultTheme = PdfTheme.defaultTheme;

  @override
  void initState() {
    super.initState();
    _loadDefaultTheme();
  }

  Future<void> _loadDefaultTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final savedThemeId = prefs.getString('default_pdf_theme');
    if (savedThemeId != null && mounted) {
      setState(() {
        _defaultTheme = PdfTheme.fromId(savedThemeId);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final billing = context.watch<BillingService>();
    final currencyProvider = context.watch<CurrencyProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Settings',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 20,
            letterSpacing: -0.4,
            color: Colors.white,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          if (!billing.isPro) ...[
            _buildProUpsellCard(context),
            const SizedBox(height: 20),
          ] else ...[
            _buildProBadgeCard(),
            const SizedBox(height: 20),
          ],

          _buildSectionHeader('Workspace'),
          _buildCardGroup([
            _buildGroupedTile(
              icon: Icons.business_rounded,
              iconBg: AppColors.squirclePurple,
              iconColor: AppColors.squirclePurpleIcon,
              title: 'Business Profile',
              subtitle: 'Name, address, bank details, logo',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const BusinessProfileScreen(),
                ),
              ),
            ),
          ]),
          const SizedBox(height: 20),

          _buildSectionHeader('Preferences'),
          _buildCardGroup([
            _buildCurrencyTile(currencyProvider.selectedCurrency),
            const Divider(height: 1, indent: 56, color: AppColors.cardBorder),
            _buildTaxRateTile(currencyProvider),
            const Divider(height: 1, indent: 56, color: AppColors.cardBorder),
            _buildPdfThemeTile(),
          ]),
          const SizedBox(height: 20),

          _buildSectionHeader('Support & Legal'),
          _buildCardGroup([
            _buildGroupedTile(
              icon: Icons.star_rounded,
              iconBg: AppColors.squircleOrange,
              iconColor: AppColors.squircleOrangeIcon,
              title: 'Rate Us on Play Store',
              subtitle: 'Leave a rating for Invoice Maker Pro',
              onTap: _showRateDialog,
              trailing: const Icon(
                Icons.open_in_new_rounded,
                size: 16,
                color: AppColors.slate400,
              ),
            ),
            const Divider(height: 1, indent: 56, color: AppColors.cardBorder),
            _buildGroupedTile(
              icon: Icons.mail_rounded,
              iconBg: AppColors.squircleCyan,
              iconColor: AppColors.squircleCyanIcon,
              title: 'Contact Developer',
              subtitle: 'connect.livinlabs@gmail.com',
              onTap: () {},
            ),
          ]),
          const SizedBox(height: 20),

          _buildSectionHeader('About'),
          _buildCardGroup([
            _buildGroupedTile(
              icon: Icons.info_outline_rounded,
              iconBg: AppColors.squircleGreen,
              iconColor: AppColors.squircleGreenIcon,
              title: 'Invoice Maker Pro',
              subtitle: '100% Offline & Private',
              onTap: null,
            ),
            const Divider(height: 1, indent: 56, color: AppColors.cardBorder),
            _buildGroupedTile(
              icon: Icons.explore_outlined,
              iconBg: AppColors.squircleTeal,
              iconColor: AppColors.squircleTealIcon,
              title: 'View Onboarding Tour',
              subtitle: 'Replay the setup journey',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const OnboardingScreen()),
                );
              },
            ),
          ]),
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

  Widget _buildCardGroup(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.02),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(mainAxisSize: MainAxisSize.min, children: children),
      ),
    );
  }

  Widget _buildProUpsellCard(BuildContext context) {
    return GestureDetector(
      onTap: _openPaywall,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.accentCyan.withValues(alpha: 0.5),
            width: 1.5,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color.fromRGBO(0, 191, 165, 0.08),
              blurRadius: 16,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primaryMuted,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.workspace_premium_rounded,
                color: AppColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Upgrade plan',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Unlock unlimited invoices, custom logo & clean PDF',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.slate400,
              size: 24,
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
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.statusPaid.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.verified_rounded,
            color: AppColors.statusPaid,
            size: 26,
          ),
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
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'Unlimited Invoices | Unlimited Clients | Clean PDF (No Watermark)',
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
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  Widget _buildGroupedTile({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
    Widget? trailing,
  }) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 20, color: iconColor),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: -0.2,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        trailing:
            trailing ??
            (onTap != null
                ? const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.slate400,
                  )
                : null),
        onTap: onTap,
      ),
    );
  }

  Widget _buildCurrencyTile(Currency selectedCurrency) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.squircleGreen,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.currency_exchange_rounded,
            size: 20,
            color: AppColors.squircleGreenIcon,
          ),
        ),
        title: const Text(
          'Default Currency',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: -0.2,
          ),
        ),
        subtitle: Text(
          '${selectedCurrency.symbol} ${selectedCurrency.code} • ${selectedCurrency.name}',
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        trailing: const Icon(
          Icons.chevron_right_rounded,
          color: AppColors.slate400,
        ),
        onTap: () => _showCurrencyPicker(context),
      ),
    );
  }

  Widget _buildPdfThemeTile() {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: _defaultTheme.previewBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _defaultTheme.previewPrimary.withValues(alpha: 0.3),
            ),
          ),
          child: Icon(
            Icons.palette_outlined,
            size: 20,
            color: _defaultTheme.previewPrimary,
          ),
        ),
        title: const Text(
          'Default PDF Theme',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: -0.2,
          ),
        ),
        subtitle: Text(
          '${_defaultTheme.name} • ${_defaultTheme.description}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _defaultTheme.previewBg,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: _defaultTheme.previewPrimary.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _defaultTheme.name,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _defaultTheme.previewPrimary,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.chevron_right_rounded,
                size: 16,
                color: AppColors.slate400,
              ),
            ],
          ),
        ),
        onTap: () async {
          final selected = await PdfThemePickerSheet.show(
            context,
            currentTheme: _defaultTheme,
            showSetAsDefault: false,
          );
          if (selected != null) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('default_pdf_theme', selected.id.value);
            if (mounted) {
              setState(() {
                _defaultTheme = selected;
              });
            }
          }
        },
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
      child: Material(
        color: Colors.transparent,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
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
              Icons.percent,
              size: 18,
              color: AppColors.slate600,
            ),
          ),
          title: Text(
            'Default ${defaultTax.shortName} Rate',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            '${defaultTax.rate}% | $sourceLabel',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
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
          iconBackground: AppColors.primaryLight.withValues(alpha: 0.12),
          title: 'Edit ${currencyProvider.defaultTax.shortName} rate',
          subtitle: 'Set the default tax rate used when you create invoices.',
          content: StatefulBuilder(
            builder: (ctx, setSheetState) => Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (currencyProvider.presetTaxRates.isNotEmpty) ...[
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: currencyProvider.presetTaxRates.map((rate) {
                        final isSel =
                            (double.tryParse(controller.text) ?? -1) == rate;
                        return ActionChip(
                          label: Text(
                            rate == 0
                                ? '0%'
                                : '${rate.toStringAsFixed(rate % 1 == 0 ? 0 : 1)}%',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isSel
                                  ? Colors.white
                                  : AppColors.textPrimary,
                            ),
                          ),
                          backgroundColor: isSel
                              ? AppColors.primary
                              : AppColors.slate100,
                          side: BorderSide.none,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          onPressed: () {
                            setSheetState(() {
                              controller.text = rate.toStringAsFixed(
                                rate % 1 == 0 ? 0 : 1,
                              );
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                  ],
                  TextFormField(
                    controller: controller,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText:
                          '${currencyProvider.defaultTax.shortName} Rate (%)',
                      hintText: 'e.g. ${currencyProvider.defaultTax.rate}',
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
                ],
              ),
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
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final currency = _filteredCurrencies[index];
                final isSelected = currency.code == selectedCurrency.code;

                return Material(
                  color: isSelected
                      ? AppColors.primaryLight.withValues(alpha: 0.1)
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
                                  '${currency.countryName} - ${currency.name}',
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
                                      ? AppColors.primaryLight.withValues(
                                          alpha: 0.1,
                                        )
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
