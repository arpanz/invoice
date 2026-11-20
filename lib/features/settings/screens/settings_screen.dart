import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import '../../../core/utils/number_text.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/app/app_review_service.dart';
import '../../../core/billing/billing_service.dart';
import '../../../core/database/db_provider.dart';
import '../../../core/models/currency_model.dart';
import '../../../core/providers/currency_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared_widgets/paper.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../shared_widgets/currency_picker_sheet.dart';
import '../../invoices/models/invoice_customization_config.dart';
import '../../invoices/models/pdf_theme.dart';
import '../../invoices/widgets/invoice_customizer_studio_sheet.dart';
import '../../onboarding/screens/onboarding_screen.dart';
import '../../paywall/paywall_screen.dart';
import 'business_profile_screen.dart';
import '../../../core/theme/app_icons.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  PdfTheme _defaultTheme = PdfTheme.defaultTheme;
  InvoiceCustomizationConfig _defaultConfig =
      InvoiceCustomizationConfig.defaultConfig;

  @override
  void initState() {
    super.initState();
    _loadDefaultTheme();
  }

  Future<void> _loadDefaultTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final savedConfigJson = prefs.getString('default_invoice_customization');
    if (savedConfigJson != null && mounted) {
      final parsed = InvoiceCustomizationConfig.tryFromJsonString(
        savedConfigJson,
      );
      if (parsed != null) {
        setState(() {
          _defaultConfig = parsed;
          _defaultTheme = parsed.toPdfTheme();
        });
        return;
      }
    }
    final savedThemeId = prefs.getString('default_pdf_theme');
    if (savedThemeId != null && mounted) {
      setState(() {
        _defaultTheme = PdfTheme.fromId(savedThemeId);
        _defaultConfig = InvoiceCustomizationConfig.fromTheme(_defaultTheme);
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
        backgroundColor: AppColors.canvas,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: AppColors.hairline),
        ),
        leading: IconButton(
          icon: Icon(AppIcons.arrowBack, color: AppColors.ink),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Settings'),
        centerTitle: true,
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
              icon: AppIcons.business,
              iconBg: AppColors.surfaceCard,
              iconColor: AppColors.ink,
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

          _buildSectionHeader('Your Data'),
          _buildCardGroup([
            _buildGroupedTile(
              icon: AppIcons.cloudDownload,
              iconBg: AppColors.surfaceCard,
              iconColor: AppColors.ink,
              title: 'Export Data (JSON)',
              subtitle: 'A copy of your records to keep or open elsewhere. It can\'t be restored into the app yet.',
              onTap: _exportBackupJson,
              trailing: Icon(
                AppIcons.share,
                size: 18,
                color: AppColors.ink,
              ),
            ),
          ]),
          const SizedBox(height: 20),

          _buildSectionHeader('Preferences'),
          _buildCardGroup([
            _buildCurrencyTile(currencyProvider.selectedCurrency),
            Divider(height: 1, indent: 56, color: AppColors.hairline),
            _buildTaxRateTile(currencyProvider),
            Divider(height: 1, indent: 56, color: AppColors.hairline),
            _buildPdfThemeTile(),
            Divider(height: 1, indent: 56, color: AppColors.hairline),
            _buildAppearanceTile(),
          ]),
          const SizedBox(height: 20),

          _buildSectionHeader('About & Support'),
          _buildCardGroup([
            _buildGroupedTile(
              icon: AppIcons.star,
              iconBg: AppColors.surfaceCard,
              iconColor: AppColors.ink,
              title: 'Rate Us on Play Store',
              subtitle: 'Leave a rating for Invoice Maker Pro',
              onTap: () => AppReviewService.instance.openRatingFlow(),
            ),
            Divider(height: 1, indent: 56, color: AppColors.hairline),
            _buildGroupedTile(
              icon: AppIcons.help,
              iconBg: AppColors.surfaceCard,
              iconColor: AppColors.ink,
              title: 'Help & Guide',
              subtitle: 'Quick tips and walkthrough',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const OnboardingScreen(isReplay: true)),
              ),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildCardGroup(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.canvas,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.hairline),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildProUpsellCard(BuildContext context) {
    void open() {
      Haptics.tap();
      Navigator.push(context, MaterialPageRoute(builder: (_) => const PaywallScreen()));
    }

    return PaperSlip(
      onTap: open,
      padding: const EdgeInsets.fromLTRB(18, 16, 14, 16),
      child: Row(
        children: [
          ExcludeSemantics(child: StampMark(label: 'PRO', color: AppColors.brandAccent, fontSize: 14)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Upgrade to Pro', style: AppTypography.serif(fontSize: 19, color: AppColors.ink)),
                const SizedBox(height: 2),
                Text(
                  'Unlimited invoices & clients, no watermark',
                  style: GoogleFonts.inter(color: AppColors.muted, fontSize: 12.5),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: open,
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 38),
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            child: Text('Go Pro', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildProBadgeCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.statusPaidBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.statusPaid.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(
            AppIcons.verified,
            color: AppColors.statusPaid,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pro Workspace Active',
                  style: GoogleFonts.inter(
                    color: AppColors.statusPaid,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Unlimited Invoices • Clean PDF (No Watermark)',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(color: AppColors.muted, fontSize: 12),
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
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.mutedSoft,
          letterSpacing: 1.1,
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
          // One quiet tile style for every row; colour is kept for meaning.
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 20, color: AppColors.ink),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
            letterSpacing: -0.2,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        trailing:
            trailing ??
            (onTap != null
                ? Icon(
                    AppIcons.chevronRight,
                    color: AppColors.mutedSoft,
                  )
                : null),
        onTap: onTap,
      ),
    );
  }

  static const _themeModeLabels = {
    ThemeMode.system: 'Same as device',
    ThemeMode.light: 'Light',
    ThemeMode.dark: 'Dark',
  };

  Widget _buildAppearanceTile() {
    final mode = context.watch<ThemeController>().mode;
    return _buildGroupedTile(
      icon: AppColors.isDark ? AppIcons.darkMode : AppIcons.lightMode,
      iconBg: AppColors.squirclePurple,
      iconColor: AppColors.squirclePurpleIcon,
      title: 'Appearance',
      subtitle: _themeModeLabels[mode]!,
      onTap: _showAppearancePicker,
    );
  }

  void _showAppearancePicker() {
    final controller = context.read<ThemeController>();
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(
                  'Appearance',
                  style: AppTypography.serif(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: AppColors.ink,
                  ),
                ),
              ),
              RadioGroup<ThemeMode>(
                groupValue: controller.mode,
                onChanged: (m) {
                  if (m == null) return;
                  Navigator.pop(ctx);
                  controller.setMode(m);
                },
                child: Column(
                  children: [
                    for (final entry in _themeModeLabels.entries)
                      RadioListTile<ThemeMode>(
                        value: entry.key,
                        title: Text(
                          entry.value,
                          style: TextStyle(color: AppColors.ink),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
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
            color: AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            AppIcons.currencyExchange,
            size: 20,
            color: AppColors.ink,
          ),
        ),
        title: Text(
          'Default Currency',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
            letterSpacing: -0.2,
          ),
        ),
        subtitle: Text(
          '${selectedCurrency.symbol} ${selectedCurrency.code} • ${selectedCurrency.name}',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        trailing: Icon(
          AppIcons.chevronRight,
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
            color: AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            AppIcons.magic,
            size: 20,
            color: AppColors.ink,
          ),
        ),
        title: Text(
          'Default Design & Typography',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
            letterSpacing: -0.2,
          ),
        ),
        subtitle: Text(
          '${_defaultTheme.name} • ${_defaultConfig.fontFamily.displayName} • ${_defaultConfig.density.displayName}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        // The template's accent as a small swatch; text stays readable.
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: _defaultTheme.previewPrimary,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.hairline),
              ),
            ),
            const SizedBox(width: 4),
            Icon(AppIcons.chevronRight, color: AppColors.mutedSoft),
          ],
        ),
        onTap: () async {
          final updated = await InvoiceCustomizerStudioSheet.show(
            context,
            initialConfig: _defaultConfig,
            // Everything saved here is the default, so the checkbox would
            // only mislead.
            showSetAsDefault: false,
            title: 'Default invoice design',
          );
          if (updated != null && mounted) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString(
              'default_invoice_customization',
              updated.toJsonString(),
            );
            await prefs.setString('default_pdf_theme', updated.themeId.value);
            setState(() {
              _defaultConfig = updated;
              _defaultTheme = updated.toPdfTheme();
            });
          }
        },
      ),
    );
  }

  void _showCurrencyPicker(BuildContext context) {
    CurrencyPickerSheet.show(context);
  }

  Widget _buildTaxRateTile(CurrencyProvider currencyProvider) {
    final defaultTax = currencyProvider.defaultTax;
    final sourceLabel = currencyProvider.hasCustomTaxRate
        ? 'Custom ${defaultTax.shortName} rate'
        : defaultTax.name;

    return Material(
      color: Colors.transparent,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            AppIcons.percent,
            size: 18,
            color: AppColors.ink,
          ),
        ),
        title: Text(
          'Default ${defaultTax.shortName} Rate',
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
            letterSpacing: -0.2,
          ),
        ),
        subtitle: Text(
          '${defaultTax.rate}% • $sourceLabel',
          style: GoogleFonts.inter(fontSize: 12, color: AppColors.muted),
        ),
        trailing: Text(
          '${defaultTax.rate}%',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
          ),
        ),
        onTap: _showTaxRateEditor,
      ),
    );
  }

  Future<void> _showTaxRateEditor() async {
    final currencyProvider = context.read<CurrencyProvider>();
    final currentRate = currencyProvider.defaultTax.rate;
    final controller = TextEditingController(text: NumberText.trim(currentRate));
    final formKey = GlobalKey<FormState>();

    final action = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.canvas,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.hairline,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Edit ${currencyProvider.defaultTax.shortName} Rate',
                style: AppTypography.serif(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: AppColors.ink,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Set the default tax rate used when you create invoices.',
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  color: AppColors.muted,
                ),
              ),
              const SizedBox(height: 16),
              StatefulBuilder(
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
                                    : '${NumberText.trim(rate)}%',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isSel ? AppColors.onPrimary : AppColors.ink,
                                ),
                              ),
                              backgroundColor: isSel
                                  ? AppColors.primary
                                  : AppColors.surfaceCard,
                              side: BorderSide(
                                color: isSel ? AppColors.primary : AppColors.hairline,
                              ),
                              shape: const StadiumBorder(),
                              onPressed: () {
                                setSheetState(() {
                                  controller.text = NumberText.trim(rate);
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
              const SizedBox(height: 20),
              Row(
                children: [
                  if (currencyProvider.hasCustomTaxRate) ...[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx, 'reset'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: BorderSide(color: AppColors.hairline),
                          shape: const StadiumBorder(),
                        ),
                        child: const Text('Reset'),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.ink,
                        side: BorderSide(color: AppColors.hairline),
                        shape: const StadiumBorder(),
                      ),
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
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.onPrimary,
                        elevation: 0,
                        shape: const StadiumBorder(),
                      ),
                      child: const Text('Save'),
                    ),
                  ),
                ],
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

  Future<void> _exportBackupJson() async {
    try {
      HapticFeedback.mediumImpact();
      final invoices = await DbProvider.query(DbProvider.tableInvoices);
      final lineItems = await DbProvider.query(DbProvider.tableLineItems);
      final clients = await DbProvider.query(DbProvider.tableClients);
      final estimates = await DbProvider.query(DbProvider.tableEstimates);
      final estimateLines = await DbProvider.query(DbProvider.tableEstimateLineItems);
      final payments = await DbProvider.query(DbProvider.tablePayments);
      final items = await DbProvider.query(DbProvider.tableSavedItems);
      final prefs = await SharedPreferences.getInstance();
      final profile = {
        for (final key in prefs.getKeys().where((k) => k.startsWith('biz_') || k.startsWith('default_')))
          key: prefs.get(key),
      };

      final data = {
        'app': 'Invoice Maker Pro',
        'version': 3,
        'note': 'Logo and signature images are not included.',
        'business_profile': profile,
        'exported_at': DateTime.now().toIso8601String(),
        'invoices': invoices,
        'line_items': lineItems,
        'clients': clients,
        'estimates': estimates,
        'estimate_line_items': estimateLines,
        'payments': payments,
        'saved_items': items,
      };

      final jsonString = const JsonEncoder.withIndent('  ').convert(data);
      final tempDir = await getTemporaryDirectory();
      final dateStr = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
      final file = File('${tempDir.path}/invoice_maker_pro_export_$dateStr.json');
      await file.writeAsString(jsonString);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text: 'Invoice Maker Pro data export ($dateStr)',
        ),
      );
    } catch (e) {
      debugPrint('Settings action failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not export your data. Please try again.')),
        );
      }
    }
  }
}
