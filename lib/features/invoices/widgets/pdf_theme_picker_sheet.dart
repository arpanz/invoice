import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_colors.dart';
import '../models/invoice_customization_config.dart';
import '../models/pdf_theme.dart';
import '../services/dummy_invoice_data.dart';
import '../services/pdf_generator_service.dart';
import 'invoice_customizer_studio_sheet.dart';

class PdfThemePickerSheet extends StatefulWidget {
  final PdfTheme currentTheme;
  final Function(PdfTheme theme, bool setAsDefault) onThemeSelected;
  final bool showSetAsDefault;

  const PdfThemePickerSheet({
    super.key,
    required this.currentTheme,
    required this.onThemeSelected,
    this.showSetAsDefault = true,
  });

  static Future<PdfTheme?> show(
    BuildContext context, {
    required PdfTheme currentTheme,
    bool showSetAsDefault = true,
  }) async {
    return showModalBottomSheet<PdfTheme>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PdfThemePickerSheet(
        currentTheme: currentTheme,
        showSetAsDefault: showSetAsDefault,
        onThemeSelected: (selectedTheme, setAsDefault) async {
          if (setAsDefault) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('default_pdf_theme', selectedTheme.id.value);
          }
          if (ctx.mounted) {
            Navigator.pop(ctx, selectedTheme);
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
  bool _setAsDefault = false;

  // Cache of live rasterized thumbnails for all 10 themes
  static final Map<PdfThemeId, Uint8List> _thumbnailCache = {};

  @override
  void initState() {
    super.initState();
    _selectedTheme = widget.currentTheme;
    _warmUpThumbnails();
  }

  Future<void> _warmUpThumbnails() async {
    for (final theme in PdfTheme.all) {
      if (_thumbnailCache.containsKey(theme.id)) continue;
      try {
        final pdfBytes = await PdfGeneratorService.generateInvoicePdf(
          invoice: DummyInvoiceData.sampleInvoice,
          businessProfile: DummyInvoiceData.sampleProfile,
          isPro: true,
          theme: theme,
          isSamplePreview: true,
        );

        await for (final page in Printing.raster(pdfBytes, pages: [0], dpi: 90)) {
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
    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.slate300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Choose Invoice Style',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.3,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Tap any template to select',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.slate500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.slate400),
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
                    widget.onThemeSelected(saved.toPdfTheme(), _setAsDefault);
                  }
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.auto_fix_high_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Customize Design & Typography',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                            Text(
                              'Change font family, sizing scale & element layout',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.slate600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        size: 20,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Divider(height: 1, color: AppColors.cardBorder),

            // 2-Column Live Preview Only Grid (No text labels)
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                itemCount: PdfTheme.all.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.707,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                ),
                itemBuilder: (ctx, index) {
                  final theme = PdfTheme.all[index];
                  final isSelected = _selectedTheme.id == theme.id;
                  final thumbnailBytes = _thumbnailCache[theme.id];

                  return _buildLiveThemeCard(theme, isSelected, thumbnailBytes);
                },
              ),
            ),

            const Divider(height: 1, color: AppColors.cardBorder),

            // Footer Actions
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
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
                            height: 22,
                            width: 22,
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
                          const Text(
                            'Set as default style for future invoices',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppColors.slate700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        widget.onThemeSelected(_selectedTheme, _setAsDefault);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Apply Selected Style',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
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
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? theme.previewPrimary : AppColors.cardBorder,
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
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Live Rendered Document Page Preview
              Container(
                color: const Color(0xFFF8FAFC),
                child: Center(
                  child: thumbnailBytes != null
                      ? Image.memory(
                          thumbnailBytes,
                          fit: BoxFit.contain,
                        )
                      : _buildFallbackMiniMockup(theme),
                ),
              ),

              // Top Right Checkmark Badge when selected
              if (isSelected)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: theme.previewPrimary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.check,
                      size: 14,
                      color: Colors.white,
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
