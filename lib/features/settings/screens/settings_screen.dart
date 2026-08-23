import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
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
import '../../../shared_widgets/currency_picker_sheet.dart';
import '../../invoices/models/invoice_customization_config.dart';
import '../../invoices/models/pdf_theme.dart';
import '../../invoices/widgets/invoice_customizer_studio_sheet.dart';
import '../../onboarding/screens/onboarding_screen.dart';
import '../../paywall/paywall_screen.dart';
import '../../invoices/screens/invoice_history_screen.dart';
import 'business_profile_screen.dart';

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
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: AppColors.hairline),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.ink),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Settings',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            letterSpacing: -0.3,
            color: AppColors.ink,
          ),
        ),
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
              icon: Icons.business_rounded,
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
            const Divider(height: 1, indent: 56, color: AppColors.hairline),
            _buildGroupedTile(
              icon: Icons.history_rounded,
              iconBg: AppColors.surfaceCard,
              iconColor: AppColors.ink,
              title: 'Invoice History',
              subtitle: 'View all past invoices',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const InvoiceHistoryScreen(),
                ),
              ),
            ),
          ]),
          const SizedBox(height: 20),

          _buildSectionHeader('Data & Backup'),
          _buildCardGroup([
            _buildGroupedTile(
              icon: Icons.cloud_download_rounded,
              iconBg: AppColors.surfaceCard,
              iconColor: AppColors.ink,
              title: 'Export Workspace Backup',
              subtitle: 'Save complete JSON backup of invoices & data',
              onTap: _exportBackupJson,
              trailing: const Icon(
                Icons.share_outlined,
                size: 18,
                color: AppColors.ink,
              ),
            ),
          ]),
          const SizedBox(height: 20),

          _buildSectionHeader('Preferences'),
          _buildCardGroup([
            _buildCurrencyTile(currencyProvider.selectedCurrency),
            const Divider(height: 1, indent: 56, color: AppColors.hairline),
            _buildTaxRateTile(currencyProvider),
            const Divider(height: 1, indent: 56, color: AppColors.hairline),
            _buildPdfThemeTile(),
          ]),
          const SizedBox(height: 20),

          _buildSectionHeader('About & Support'),
          _buildCardGroup([
            _buildGroupedTile(
              icon: Icons.star_outline_rounded,
              iconBg: AppColors.surfaceCard,
              iconColor: AppColors.ink,
              title: 'Rate Us on Play Store',
              subtitle: 'Leave a rating for Invoice Maker Pro',
              onTap: () => AppReviewService.instance.openRatingFlow(),
            ),
            const Divider(height: 1, indent: 56, color: AppColors.hairline),
            _buildGroupedTile(
              icon: Icons.help_outline_rounded,
              iconBg: AppColors.surfaceCard,
              iconColor: AppColors.ink,
              title: 'Help & Guide',
              subtitle: 'Quick tips and walkthrough',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const OnboardingScreen()),
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
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF262626)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF222222),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.star_rounded,
                color: Color(0xFFFBBF24),
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Upgrade to Pro',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Unlimited invoices, custom logo & clean PDF',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF999999),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PaywallScreen()),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.ink,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text('Go Pro', style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600)),
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
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.statusPaid.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.verified_rounded,
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
        title,
        style: GoogleFonts.inter(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: AppColors.muted,
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
            Icons.auto_fix_high_rounded,
            size: 20,
            color: _defaultTheme.previewPrimary,
          ),
        ),
        title: const Text(
          'Default Design & Typography',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: -0.2,
          ),
        ),
        subtitle: Text(
          '${_defaultTheme.name} • ${_defaultConfig.fontFamily.displayName} • ${_defaultConfig.density.displayName}',
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
          final updated = await InvoiceCustomizerStudioSheet.show(
            context,
            initialConfig: _defaultConfig,
            showSetAsDefault: true,
            title: 'Default Invoice Design Studio',
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
          child: const Icon(
            Icons.percent_rounded,
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
    final controller = TextEditingController(text: currentRate.toString());
    final formKey = GlobalKey<FormState>();

    final action = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.canvas,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
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
                                    : '${rate.toStringAsFixed(rate % 1 == 0 ? 0 : 1)}%',
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
              const SizedBox(height: 20),
              Row(
                children: [
                  if (currencyProvider.hasCustomTaxRate) ...[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx, 'reset'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: const BorderSide(color: AppColors.hairline),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
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
                        side: const BorderSide(color: AppColors.hairline),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
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
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
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
      final items = await DbProvider.query(DbProvider.tableSavedItems);

      final data = {
        'app': 'Invoice Maker Pro',
        'version': 1,
        'exported_at': DateTime.now().toIso8601String(),
        'invoices': invoices,
        'line_items': lineItems,
        'clients': clients,
        'estimates': estimates,
        'saved_items': items,
      };

      final jsonString = const JsonEncoder.withIndent('  ').convert(data);
      final tempDir = await getTemporaryDirectory();
      final dateStr = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
      final file = File('${tempDir.path}/invoice_maker_pro_backup_$dateStr.json');
      await file.writeAsString(jsonString);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text: 'Invoice Maker Pro Data Backup ($dateStr)',
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to export backup: $e')),
        );
      }
    }
  }
}
