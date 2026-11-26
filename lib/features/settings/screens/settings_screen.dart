import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../../core/utils/number_text.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/localization/catalog_localization.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/localization/language_picker.dart';
import '../../../core/localization/locale_controller.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../core/app/app_review_service.dart';
import '../../../core/backup/backup_service.dart';
import '../../../core/billing/billing_service.dart';
import '../../../core/export/csv_export_service.dart';
import '../../../core/models/currency_model.dart';
import '../../../core/notifications/reminder_settings_screen.dart';
import '../../../core/providers/currency_provider.dart';
import '../../../core/security/app_lock_settings_screen.dart';
import '../../../core/security/app_lock_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared_widgets/app_dialog.dart';
import '../../../shared_widgets/paper.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../shared_widgets/currency_picker_sheet.dart';
import '../../invoices/models/invoice_customization_config.dart';
import '../../invoices/models/pdf_theme.dart';
import '../../invoices/widgets/invoice_customizer_studio_sheet.dart';
import '../../onboarding/screens/onboarding_screen.dart';
import '../../paywall/paywall_screen.dart';
import '../../reports/screens/reports_screen.dart';
import 'business_profile_screen.dart';
import 'document_settings_screen.dart';
import '../../../core/theme/app_icons.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  PdfTheme _defaultTheme = PdfTheme.defaultTheme;
  bool _busy = false;
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
    final appLock = context.watch<AppLockService?>();

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
        title: Text(context.l10n.settings),
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

          _buildSectionHeader(context.l10n.workspace),
          _buildCardGroup([
            _buildGroupedTile(
              icon: AppIcons.business,
              iconBg: AppColors.surfaceCard,
              iconColor: AppColors.ink,
              title: context.l10n.businessProfile,
              subtitle: context.l10n.nameAddressBankDetailsLogo,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const BusinessProfileScreen(),
                ),
              ),
            ),
            Divider(height: 1, indent: 56, color: AppColors.hairline),
            _buildGroupedTile(
              icon: AppIcons.pieChart,
              iconBg: AppColors.surfaceCard,
              iconColor: AppColors.ink,
              title: context.l10n.reports,
              subtitle: context.l10n.revenueCollectionsTopClientsItems,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ReportsScreen()),
              ),
            ),
            Divider(height: 1, indent: 56, color: AppColors.hairline),
            _buildGroupedTile(
              icon: AppIcons.schedule,
              iconBg: AppColors.surfaceCard,
              iconColor: AppColors.ink,
              title: context.l10n.paymentReminders,
              subtitle: context.l10n.notificationsForUnpaidInvoices,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ReminderSettingsScreen(),
                ),
              ),
            ),
            Divider(height: 1, indent: 56, color: AppColors.hairline),
            _buildGroupedTile(
              icon: AppIcons.numbers,
              iconBg: AppColors.surfaceCard,
              iconColor: AppColors.ink,
              title: context.l10n.documentNumbering,
              subtitle: context.l10n.prefixesDigitsAndFinancialYear,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const DocumentSettingsScreen(),
                ),
              ),
            ),
          ]),
          const SizedBox(height: 20),

          if (appLock != null) ...[
            _buildSectionHeader(context.l10n.security),
            _buildCardGroup([
              _buildGroupedTile(
                icon: AppIcons.pin,
                iconBg: AppColors.surfaceCard,
                iconColor: AppColors.ink,
                title: context.l10n.appLock,
                subtitle: appLock.enabled
                    ? context.l10n.on(appLock.timeout.label(context.l10n))
                    : context.l10n.off,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AppLockSettingsScreen(service: appLock),
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 20),
          ],

          _buildSectionHeader(context.l10n.yourData),
          _buildCardGroup([
            _buildGroupedTile(
              icon: AppIcons.cloudDownload,
              iconBg: AppColors.surfaceCard,
              iconColor: AppColors.ink,
              title: context.l10n.exportDataJson,
              subtitle: context.l10n.aFullBackupOfYourRecordsProfileAnd,
              onTap: _busy ? null : _exportBackupJson,
              trailing: Icon(
                AppIcons.share,
                size: 18,
                color: AppColors.ink,
              ),
            ),
            Divider(height: 1, indent: 56, color: AppColors.hairline),
            _buildGroupedTile(
              icon: AppIcons.viewColumn,
              iconBg: AppColors.surfaceCard,
              iconColor: AppColors.ink,
              title: context.l10n.exportToCsvExcel,
              subtitle: context.l10n.spreadsheetsForInvoicesLineItemsPaymentsClientsItems,
              onTap: _busy ? null : _exportCsv,
              trailing: Icon(
                AppIcons.share,
                size: 18,
                color: AppColors.ink,
              ),
            ),
            Divider(height: 1, indent: 56, color: AppColors.hairline),
            _buildGroupedTile(
              icon: AppIcons.history,
              iconBg: AppColors.surfaceCard,
              iconColor: AppColors.ink,
              title: context.l10n.restoreFromBackup,
              subtitle: context.l10n.replaceEverythingHereWithAnExportedFile,
              onTap: _busy ? null : _restoreBackup,
              trailing: _busy
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.ink),
                    )
                  : null,
            ),
          ]),
          const SizedBox(height: 20),

          _buildSectionHeader(context.l10n.preferences),
          _buildCardGroup([
            _buildCurrencyTile(currencyProvider.selectedCurrency),
            Divider(height: 1, indent: 56, color: AppColors.hairline),
            _buildTaxRateTile(currencyProvider),
            Divider(height: 1, indent: 56, color: AppColors.hairline),
            _buildPdfThemeTile(),
            Divider(height: 1, indent: 56, color: AppColors.hairline),
            _buildAppearanceTile(),
            if (context.watch<LocaleController?>() case final locale?) ...[
              Divider(height: 1, indent: 56, color: AppColors.hairline),
              _buildGroupedTile(
                icon: AppIcons.globe,
                iconBg: AppColors.squircleCyan,
                iconColor: AppColors.squircleCyanIcon,
                title: context.l10n.language,
                subtitle: languageLabel(context, locale.language),
                onTap: () => showLanguagePicker(context),
              ),
            ],
          ]),
          const SizedBox(height: 20),

          _buildSectionHeader(context.l10n.aboutSupport),
          _buildCardGroup([
            _buildGroupedTile(
              icon: AppIcons.star,
              iconBg: AppColors.surfaceCard,
              iconColor: AppColors.ink,
              title: context.l10n.rateUsOnPlayStore,
              subtitle: context.l10n.leaveARatingForInvoiceMakerPro,
              onTap: () => AppReviewService.instance.openRatingFlow(),
            ),
            Divider(height: 1, indent: 56, color: AppColors.hairline),
            _buildGroupedTile(
              icon: AppIcons.help,
              iconBg: AppColors.surfaceCard,
              iconColor: AppColors.ink,
              title: context.l10n.helpGuide,
              subtitle: context.l10n.quickTipsAndWalkthrough,
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
                Text(context.l10n.upgradeToPro, style: AppTypography.serif(fontSize: 19, color: AppColors.ink)),
                const SizedBox(height: 2),
                Text(
                  context.l10n.unlimitedInvoicesClientsNoWatermark,
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
            child: Text(context.l10n.goPro, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
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
                  context.l10n.proWorkspaceActive,
                  style: GoogleFonts.inter(
                    color: AppColors.statusPaid,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  context.l10n.unlimitedInvoicesCleanPdfNoWatermark,
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

  Map<ThemeMode, String> get _themeModeLabels => {
    ThemeMode.system: context.l10n.sameAsDevice,
    ThemeMode.light: context.l10n.light,
    ThemeMode.dark: context.l10n.dark,
  };

  Widget _buildAppearanceTile() {
    final mode = context.watch<ThemeController>().mode;
    return _buildGroupedTile(
      icon: AppColors.isDark ? AppIcons.darkMode : AppIcons.lightMode,
      iconBg: AppColors.squirclePurple,
      iconColor: AppColors.squirclePurpleIcon,
      title: context.l10n.appearance,
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
                  context.l10n.appearance,
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
          context.l10n.defaultCurrency,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
            letterSpacing: -0.2,
          ),
        ),
        subtitle: Text(
          '${selectedCurrency.symbol} ${selectedCurrency.code} • ${context.l10n.catalogLabel(selectedCurrency.name)}',
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
          context.l10n.defaultDesignTypography,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
            letterSpacing: -0.2,
          ),
        ),
        subtitle: Text(
          '${context.l10n.catalogLabel(_defaultTheme.name)} • ${context.l10n.catalogLabel(_defaultConfig.fontFamily.displayName)} • ${context.l10n.catalogLabel(_defaultConfig.density.displayName)}',
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
            title: context.l10n.defaultInvoiceDesign,
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
        ? context.l10n.customRate(context.l10n.catalogLabel(defaultTax.shortName))
        : context.l10n.catalogLabel(defaultTax.name);

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
          context.l10n.defaultRate(context.l10n.catalogLabel(defaultTax.shortName)),
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
                context.l10n.editRate(context.l10n.catalogLabel(currencyProvider.defaultTax.shortName)),
                style: AppTypography.serif(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: AppColors.ink,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                context.l10n.setTheDefaultTaxRateUsedWhenYou,
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
                              context.l10n.namedTaxRatePercent(context.l10n.catalogLabel(currencyProvider.defaultTax.shortName)),
                          hintText: context.l10n.exampleValue(currencyProvider.defaultTax.rate.toString()),
                        ),
                        validator: (value) {
                          final parsed = double.tryParse((value ?? '').trim());
                          if (parsed == null) return context.l10n.enterAValidNumber;
                          if (parsed < 0 || parsed > 100) {
                            return context.l10n.useAValueBetween0And100;
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
                        child: Text(context.l10n.reset),
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
                      child: Text(context.l10n.cancel),
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
                      child: Text(context.l10n.save),
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

  Future<void> _exportCsv() async {
    try {
      HapticFeedback.mediumImpact();
      await CsvExportService.exportAndShare();
    } catch (e) {
      debugPrint('CSV export failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.couldNotExportCsvFilesPleaseTryAgain)),
        );
      }
    }
  }

  Future<void> _exportBackupJson() async {
    final l10n = context.l10n;
    try {
      HapticFeedback.mediumImpact();
      final file = await BackupService.writeExport(await getTemporaryDirectory());
      final dateStr = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text: l10n.invoiceMakerProDataExport(dateStr),
        ),
      );
    } catch (e) {
      debugPrint('Settings action failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.couldNotExportYourDataPleaseTryAgain)),
        );
      }
    }
  }

  /// Pick, check, confirm, then replace. The file is read and checked in
  /// full before anything changes, and the service saves a copy of the
  /// current data first. [_busy] is held from the picker on, so a second tap
  /// cannot open another picker while this one runs.
  Future<void> _restoreBackup() async {
    final l10n = context.l10n;
    if (_busy) return;
    Haptics.tap();
    final messenger = ScaffoldMessenger.of(context);
    void say(String text, {SnackBarAction? action}) => messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(text),
          action: action,
          // An action would otherwise keep it on screen until dismissed.
          persist: false,
          duration: Duration(seconds: action == null ? 4 : 10),
        ),
      );

    setState(() => _busy = true);
    try {
      final BackupContents backup;
      try {
        // Any file type: Android's JSON filter misses many files, so the
        // contents decide instead.
        final picked = await FilePicker.pickFiles(type: FileType.any);
        if (picked == null) return;
        final path = picked.files.single.path;
        if (path == null) {
          say(l10n.couldNotOpenThatFilePleaseTryAgain);
          return;
        }
        try {
          final file = File(path);
          if (await file.length() > BackupService.maxFileBytes) {
            say(l10n.thisFileIsNotAnInvoiceMakerPro);
            return;
          }
          final text = await file.readAsString();
          backup = await BackupService.parseForThisApp(text);
        } finally {
          // The picker keeps its own copy of the file (up to 50 MB).
          FilePicker.clearTemporaryFiles().catchError((_) => null);
        }
      } on BackupFormatException catch (e) {
        say(e.localizedMessage(l10n));
        return;
      } catch (e) {
        debugPrint('Restore read failed: $e');
        say(l10n.couldNotOpenThatFilePleaseTryAgain);
        return;
      }

      if (!mounted) return;
      final date = backup.exportedAt == null
          ? ''
          : l10n.backupDateContext(DateFormat('d MMM yyyy', context.localeName).format(backup.exportedAt!));
      final confirmed = await AppDialog.showConfirmation(
        context: context,
        title: l10n.replaceAllData,
        message: l10n.thisBackupHasRestoringReplacesAllInvoicesEstimates(date, backup.localizedSummary(l10n)),
        variant: AppDialogVariant.danger,
        icon: AppIcons.warning,
        confirmLabel: l10n.replace,
        isDestructive: true,
      );
      if (confirmed != true || !mounted) return;

      Haptics.confirm();
      final currency = context.read<CurrencyProvider>();
      final navigator = Navigator.of(context);
      var message = l10n.backupRestored;
      final File safety;
      try {
        safety = await BackupService.restore(backup);
      } on BackupIncompleteException catch (e) {
        debugPrint('Restore incomplete: $e');
        message = l10n.recordsRestoredButSomeSettingsWereNotCheck;
        await _finishRestore(l10n, currency, navigator, say, message, await BackupService.latestSafetyExport());
        return;
      } catch (e) {
        debugPrint('Restore failed: $e');
        say(l10n.couldNotRestoreThisBackupNothingWasChanged);
        return;
      }
      await _finishRestore(l10n, currency, navigator, say, message, safety);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Refreshes the app after a restore and offers the copy of the old data,
  /// which on Android sits in a private folder the user cannot browse.
  Future<void> _finishRestore(
    AppLocalizations l10n,
    CurrencyProvider currency,
    NavigatorState navigator,
    void Function(String, {SnackBarAction? action}) say,
    String message,
    File? safety,
  ) async {
    try {
      await BackupService.syncCurrencyProvider(currency);
    } catch (e) {
      debugPrint('Currency sync after restore failed: $e');
    }
    Haptics.stamp();
    // The dashboard reloads when Settings closes and the other tabs reload
    // when opened, so going back to the root shows the restored data.
    navigator.popUntil((route) => route.isFirst);
    say(
      message,
      action: safety == null
          ? null
          : SnackBarAction(
              label: l10n.shareOldData,
              onPressed: () => SharePlus.instance
                  .share(ShareParams(
                    files: [XFile(safety.path)],
                    text: l10n.invoiceMakerProDataSavedBeforeRestore,
                  ))
                  .catchError((Object e) {
                debugPrint('Share safety copy failed: $e');
                return const ShareResult('', ShareResultStatus.unavailable);
              }),
            ),
    );
  }
}
