import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/localization/catalog_localization.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/providers/currency_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../models/invoice_customization_config.dart';
import '../models/pdf_theme.dart';
import '../services/dummy_invoice_data.dart';
import '../services/pdf_generator_service.dart';
import 'invoice_customizer_studio_sheet.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_animations.dart';

/// What the picker returns: a template, or a fully customised design.
class PdfThemeChoice {
  final PdfTheme theme;

  /// The full design (fonts, density, layout, toggles, footer, colours) when
  /// the user customised it in the studio; null for a plain template.
  final InvoiceCustomizationConfig? customConfig;

  const PdfThemeChoice(this.theme, [this.customConfig]);
}

class PdfThemePickerSheet extends StatefulWidget {
  final PdfTheme currentTheme;
  final Function(PdfThemeChoice choice, bool setAsDefault) onThemeSelected;
  final bool showSetAsDefault;

  const PdfThemePickerSheet({
    super.key,
    required this.currentTheme,
    required this.onThemeSelected,
    this.showSetAsDefault = true,
  });

  static Future<PdfThemeChoice?> show(
    BuildContext context, {
    required PdfTheme currentTheme,
    bool showSetAsDefault = true,
  }) async {
    return showModalBottomSheet<PdfThemeChoice>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PdfThemePickerSheet(
        currentTheme: currentTheme,
        showSetAsDefault: showSetAsDefault,
        onThemeSelected: (choice, setAsDefault) async {
          if (setAsDefault) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('default_pdf_theme', choice.theme.id.value);
            if (choice.customConfig == null) {
              // A plain template as the default replaces a custom default.
              await prefs.remove('default_invoice_customization');
            }
          }
          if (ctx.mounted) {
            Navigator.pop(ctx, choice);
          }
        },
      ),
    );
  }

  @override
  State<PdfThemePickerSheet> createState() => _PdfThemePickerSheetState();
}

class _PdfThemePickerSheetState extends State<PdfThemePickerSheet> {
  late PdfTheme _selectedTheme;
  PdfThemeCategory? _category;
  bool _setAsDefault = false;
  final Map<PdfThemeId, Uint8List> _thumbnailCache = {};

  @override
  void initState() {
    super.initState();
    _selectedTheme = widget.currentTheme;
    _warmUpThumbnails();
  }

  Future<void> _warmUpThumbnails() async {
    String? currencyCode;
    try {
      currencyCode = context.read<CurrencyProvider>().currencyCode;
    } catch (_) {}

    final sampleInv = DummyInvoiceData.getSampleInvoice(currencyCode);
    final sampleProf = DummyInvoiceData.getSampleProfile(currencyCode);

    final pending = PdfTheme.all.toList();
    while (mounted && pending.isNotEmpty) {
      final categoryIndex = pending.indexWhere((theme) => theme.category == _category);
      final theme = pending.removeAt(categoryIndex < 0 ? 0 : categoryIndex);
      try {
        final pdfBytes = await PdfGeneratorService.generateInvoicePdf(
          invoice: sampleInv,
          businessProfile: sampleProf,
          isPro: true,
          theme: theme,
          isSamplePreview: true,
        );
        if (!mounted) return;

        await for (final page in Printing.raster(pdfBytes, pages: [0], dpi: 90)) {
          if (!mounted) return;
          final png = await page.toPng();
          if (mounted) {
            setState(() {
              _thumbnailCache[theme.id] = png;
            });
          }
          break;
        }
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final templates = PdfTheme.all
        .where((theme) => _category == null || theme.category == _category)
        .toList();
    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: BoxDecoration(
        color: AppColors.canvas,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            // Drag handle
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
            const SizedBox(height: 14),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.l10n.chooseInvoiceStyle,
                          style: AppTypography.serif(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: AppColors.ink,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          context.l10n.templateCount(templates.length, PdfTheme.all.length),
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(AppIcons.close, color: AppColors.muted, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),
            // Customizer Studio Banner
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: InkWell(
                onTap: () async {
                  final config = InvoiceCustomizationConfig.fromTheme(_selectedTheme);
                  final saved = await InvoiceCustomizerStudioSheet.show(
                    context,
                    initialConfig: config,
                    showSetAsDefault: widget.showSetAsDefault,
                  );
                  if (saved != null && context.mounted) {
                    widget.onThemeSelected(PdfThemeChoice(saved.toPdfTheme(), saved), _setAsDefault);
                  }
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.hairline),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceDark,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          AppIcons.magic,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.l10n.customizeDesignTypography,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.ink,
                              ),
                            ),
                            Text(
                              context.l10n.changeFontFamilySizingScaleElementLayout,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: AppColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        AppIcons.chevronRight,
                        size: 20,
                        color: AppColors.muted,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            PdfThemeCategoryChips(
              category: _category,
              onChanged: (category) => setState(() => _category = category),
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            Divider(height: 1, thickness: 1, color: AppColors.hairline),

            // Grid of live theme mockups
            Expanded(
              child: GridView.builder(
                key: ValueKey(_category),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.72,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: templates.length,
                itemBuilder: (context, index) {
                  final theme = templates[index];
                  final isSelected = theme.id == _selectedTheme.id;
                  final thumbBytes = _thumbnailCache[theme.id];

                  return _buildLiveThemeCard(theme, isSelected, thumbBytes);
                },
              ),
            ),

            // Bottom action & default checkbox
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              decoration: BoxDecoration(
                color: AppColors.canvas,
                border: Border(
                  top: BorderSide(color: AppColors.hairline),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.showSetAsDefault) ...[
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _setAsDefault = !_setAsDefault;
                        });
                      },
                      behavior: HitTestBehavior.opaque,
                      child: Row(
                        children: [
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: Checkbox(
                              value: _setAsDefault,
                              onChanged: (val) {
                                setState(() {
                                  _setAsDefault = val ?? false;
                                });
                              },
                              activeColor: AppColors.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            context.l10n.alwaysUseThisStyleAsDefault,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppColors.ink,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        widget.onThemeSelected(PdfThemeChoice(_selectedTheme), _setAsDefault);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.onPrimary,
                        elevation: 0,
                        shape: const StadiumBorder(),
                      ),
                      child: Text(
                        context.l10n.applySelectedStyle,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
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

  Widget _buildLiveThemeCard(
    PdfTheme theme,
    bool isSelected,
    Uint8List? thumbnailBytes,
  ) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTheme = theme;
        });
      },
      child: AnimatedContainer(
        duration: AppAnimations.fast,
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.ink : AppColors.cardBorder,
            width: isSelected ? 2.5 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: theme.previewPrimary.withValues(alpha: 0.25),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  const BoxShadow(
                    color: Color.fromRGBO(0, 0, 0, 0.05),
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ColoredBox(
                      color: theme.previewBg,
                      child: thumbnailBytes != null
                          ? Image.memory(thumbnailBytes, fit: BoxFit.contain)
                          : _buildFallbackMiniMockup(theme),
                    ),
                    if (isSelected)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            AppIcons.check,
                            size: 14,
                            color: AppColors.onPrimary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                child: Text(
                  context.l10n.catalogLabel(theme.name),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackMiniMockup(PdfTheme theme) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: theme.previewBg,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 28,
                height: 7,
                decoration: BoxDecoration(
                  color: theme.previewPrimary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Container(
                width: 22,
                height: 5,
                color: theme.previewSecondary.withValues(alpha: 0.5),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 18,
            decoration: BoxDecoration(
              color: theme.previewPrimary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: theme.previewPrimary.withValues(alpha: 0.2),
                ),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
