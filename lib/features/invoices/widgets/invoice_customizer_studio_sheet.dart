import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_colors.dart';
import '../models/invoice_customization_config.dart';
import '../models/invoice_model.dart';
import '../models/pdf_theme.dart';
import '../services/dummy_invoice_data.dart';
import '../services/pdf_generator_service.dart';

class InvoiceCustomizerStudioSheet extends StatefulWidget {
  final InvoiceCustomizationConfig initialConfig;
  final InvoiceModel? invoice;
  final BusinessProfile? businessProfile;
  final Function(InvoiceCustomizationConfig config, bool setAsDefault) onConfigSaved;
  final bool showSetAsDefault;
  final String title;

  const InvoiceCustomizerStudioSheet({
    super.key,
    required this.initialConfig,
    required this.onConfigSaved,
    this.invoice,
    this.businessProfile,
    this.showSetAsDefault = true,
    this.title = 'Invoice Design Studio',
  });

  static Future<InvoiceCustomizationConfig?> show(
    BuildContext context, {
    required InvoiceCustomizationConfig initialConfig,
    InvoiceModel? invoice,
    BusinessProfile? businessProfile,
    bool showSetAsDefault = true,
    String title = 'Invoice Design Studio',
  }) async {
    return showModalBottomSheet<InvoiceCustomizationConfig>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => InvoiceCustomizerStudioSheet(
        initialConfig: initialConfig,
        invoice: invoice,
        businessProfile: businessProfile,
        showSetAsDefault: showSetAsDefault,
        title: title,
        onConfigSaved: (savedConfig, setAsDefault) async {
          if (setAsDefault) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('default_invoice_customization', savedConfig.toJsonString());
            await prefs.setString('default_pdf_theme', savedConfig.themeId.value);
          }
          if (ctx.mounted) {
            Navigator.pop(ctx, savedConfig);
          }
        },
      ),
    );
  }

  @override
  State<InvoiceCustomizerStudioSheet> createState() => _InvoiceCustomizerStudioSheetState();
}

class _InvoiceCustomizerStudioSheetState extends State<InvoiceCustomizerStudioSheet>
    with SingleTickerProviderStateMixin {
  late InvoiceCustomizationConfig _config;
  late TabController _tabController;
  late TextEditingController _footerMessageController;

  bool _setAsDefault = false;
  Uint8List? _previewImageBytes;
  bool _isRendering = false;
  Timer? _debounceTimer;
  final TransformationController _zoomController = TransformationController();

  @override
  void initState() {
    super.initState();
    _config = widget.initialConfig;
    _tabController = TabController(length: 4, vsync: this);
    _footerMessageController = TextEditingController(text: _config.customFooterMessage ?? '');
    _renderPreview();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _tabController.dispose();
    _footerMessageController.dispose();
    _zoomController.dispose();
    super.dispose();
  }

  void _onConfigModified(InvoiceCustomizationConfig newConfig) {
    setState(() {
      _config = newConfig;
    });
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 90), () {
      _renderPreview();
    });
  }

  Future<void> _renderPreview() async {
    if (!mounted) return;
    setState(() => _isRendering = true);
    try {
      final inv = widget.invoice ?? DummyInvoiceData.sampleInvoice;
      final profile = widget.businessProfile ?? DummyInvoiceData.sampleProfile;

      final pdfBytes = await PdfGeneratorService.generateInvoicePdf(
        invoice: inv,
        businessProfile: profile,
        isPro: true,
        customizationConfig: _config,
        isSamplePreview: widget.invoice == null,
      );

      await for (final page in Printing.raster(pdfBytes, pages: [0], dpi: 110)) {
        final png = await page.toPng();
        if (mounted) {
          setState(() {
            _previewImageBytes = png;
            _isRendering = false;
          });
        }
        break;
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isRendering = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final sheetHeight = MediaQuery.of(context).size.height * 0.94;

    return Container(
      height: sheetHeight,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            const SizedBox(height: 10),
            // Handle bar
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
            const SizedBox(height: 10),

            // Header bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Live preview updates instantly',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.slate500,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      TextButton.icon(
                        onPressed: () {
                          _onConfigModified(InvoiceCustomizationConfig.defaultConfig);
                          _footerMessageController.text = '';
                        },
                        icon: const Icon(Icons.refresh_rounded, size: 16, color: AppColors.slate600),
                        label: const Text(
                          'Reset',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.slate600,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: AppColors.slate400),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.cardBorder),

            // Top Half: Live Interactive Preview Card (32% height)
            Container(
              height: 220,
              width: double.infinity,
              color: const Color(0xFFF1F5F9),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (_previewImageBytes != null)
                    InteractiveViewer(
                      transformationController: _zoomController,
                      minScale: 0.8,
                      maxScale: 3.5,
                      child: Center(
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.12),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: AspectRatio(
                            aspectRatio: 0.707,
                            child: Image.memory(
                              _previewImageBytes!,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (_isRendering)
                    Positioned(
                      top: 10,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 10,
                              height: 10,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.8,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Updating...',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  // Reset zoom pill
                  Positioned(
                    bottom: 8,
                    right: 12,
                    child: GestureDetector(
                      onTap: () {
                        _zoomController.value = Matrix4.identity();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.fit_screen_rounded, size: 12, color: AppColors.slate600),
                            SizedBox(width: 4),
                            Text(
                              'Fit',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.slate700),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Tab Bar
            Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: AppColors.cardBorder)),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorColor: AppColors.primary,
                indicatorWeight: 3,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.slate500,
                labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                unselectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                tabs: const [
                  Tab(icon: Icon(Icons.palette_outlined, size: 18), text: 'Style'),
                  Tab(icon: Icon(Icons.text_fields_rounded, size: 18), text: 'Typography'),
                  Tab(icon: Icon(Icons.dashboard_customize_outlined, size: 18), text: 'Layout'),
                  Tab(icon: Icon(Icons.tune_rounded, size: 18), text: 'Sections'),
                ],
              ),
            ),

            // Tab Views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildTemplatesAndColorsTab(),
                  _buildTypographyAndSizingTab(),
                  _buildLayoutAndPositionsTab(),
                  _buildSectionsAndContentTab(),
                ],
              ),
            ),

            const Divider(height: 1, color: AppColors.cardBorder),

            // Footer
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.showSetAsDefault) ...[
                    GestureDetector(
                      onTap: () => setState(() => _setAsDefault = !_setAsDefault),
                      behavior: HitTestBehavior.opaque,
                      child: Row(
                        children: [
                          SizedBox(
                            height: 22,
                            width: 22,
                            child: Checkbox(
                              value: _setAsDefault,
                              onChanged: (val) => setState(() => _setAsDefault = val ?? false),
                              activeColor: AppColors.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Set as default style for future documents',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppColors.slate700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton(
                      onPressed: () {
                        widget.onConfigSaved(_config, _setAsDefault);
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
                        'Apply & Save Style',
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

  // -------------------------------------------------------------
  // TAB 1: TEMPLATES & COLORS
  // -------------------------------------------------------------
  Widget _buildTemplatesAndColorsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionTitle('Paper Design Template'),
        const SizedBox(height: 8),
        SizedBox(
          height: 94,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: PdfTheme.all.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (ctx, idx) {
              final theme = PdfTheme.all[idx];
              final isSelected = _config.themeId == theme.id;

              return GestureDetector(
                onTap: () {
                  _onConfigModified(
                    _config.copyWith(
                      themeId: theme.id,
                      primaryColor: theme.previewPrimary,
                      secondaryColor: theme.previewSecondary,
                      accentColor: theme.previewAccent,
                    ),
                  );
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 84,
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: isSelected ? theme.previewBg : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? theme.previewPrimary : AppColors.cardBorder,
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: theme.previewPrimary.withValues(alpha: 0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: theme.previewPrimary,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: theme.previewAccent,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        theme.name,
                        maxLines: 2,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? theme.previewPrimary : AppColors.textPrimary,
                          height: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 20),
        _buildSectionTitle('Color Palette Presets'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ColorPalettePreset.presets.map((preset) {
            final isMatch = _config.primaryColor.toARGB32() == preset.primary.toARGB32() &&
                _config.accentColor.toARGB32() == preset.accent.toARGB32();

            return GestureDetector(
              onTap: () {
                _onConfigModified(
                  _config.copyWith(
                    primaryColor: preset.primary,
                    secondaryColor: preset.secondary,
                    accentColor: preset.accent,
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: isMatch ? preset.primary.withValues(alpha: 0.08) : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isMatch ? preset.primary : AppColors.cardBorder,
                    width: isMatch ? 1.8 : 1.0,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: preset.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: preset.accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      preset.name,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isMatch ? FontWeight.w700 : FontWeight.w500,
                        color: isMatch ? preset.primary : AppColors.slate700,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // TAB 2: TYPOGRAPHY & SIZING
  // -------------------------------------------------------------
  Widget _buildTypographyAndSizingTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionTitle('Font Family'),
        const SizedBox(height: 8),
        ...InvoiceFontFamily.values.map((family) {
          final isSelected = _config.fontFamily == family;

          return GestureDetector(
            onTap: () => _onConfigModified(_config.copyWith(fontFamily: family)),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary.withValues(alpha: 0.05) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.cardBorder,
                  width: isSelected ? 1.8 : 1.0,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                    size: 18,
                    color: isSelected ? AppColors.primary : AppColors.slate400,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          family.displayName,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isSelected ? AppColors.primary : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          family.description,
                          style: const TextStyle(fontSize: 11.5, color: AppColors.slate500),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 18),
        _buildSectionTitle('Document Density & Sizing'),
        const SizedBox(height: 8),
        Row(
          children: InvoiceDensity.values.map((density) {
            final isSelected = _config.density == density;

            return Expanded(
              child: GestureDetector(
                onTap: () => _onConfigModified(_config.copyWith(density: density)),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary.withValues(alpha: 0.07) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.cardBorder,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        density.displayName,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? AppColors.primary : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        density == InvoiceDensity.compact
                            ? '85% Scale'
                            : (density == InvoiceDensity.regular ? '100% Normal' : '115% Large'),
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
                          color: isSelected ? AppColors.primary : AppColors.slate500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // TAB 3: LAYOUT & POSITIONS
  // -------------------------------------------------------------
  Widget _buildLayoutAndPositionsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionTitle('Header Alignment & Position'),
        const SizedBox(height: 8),
        ...HeaderPosition.values.map((pos) {
          final isSelected = _config.headerPosition == pos;

          return GestureDetector(
            onTap: () => _onConfigModified(_config.copyWith(headerPosition: pos)),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary.withValues(alpha: 0.05) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.cardBorder,
                  width: isSelected ? 1.8 : 1.0,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    pos == HeaderPosition.logoLeftDetailsRight
                        ? Icons.align_horizontal_left_rounded
                        : (pos == HeaderPosition.logoRightDetailsLeft
                            ? Icons.align_horizontal_right_rounded
                            : (pos == HeaderPosition.centeredLogo
                                ? Icons.align_horizontal_center_rounded
                                : Icons.view_headline_rounded)),
                    color: isSelected ? AppColors.primary : AppColors.slate600,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pos.displayName,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: isSelected ? AppColors.primary : AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          pos.description,
                          style: const TextStyle(fontSize: 11, color: AppColors.slate500),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    const Icon(Icons.check_circle_rounded, size: 18, color: AppColors.primary),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 18),
        _buildSectionTitle('Address Block Arrangement'),
        const SizedBox(height: 8),
        ...AddressLayout.values.map((layout) {
          final isSelected = _config.addressLayout == layout;

          return GestureDetector(
            onTap: () => _onConfigModified(_config.copyWith(addressLayout: layout)),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary.withValues(alpha: 0.05) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.cardBorder,
                  width: isSelected ? 1.8 : 1.0,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    layout == AddressLayout.stacked
                        ? Icons.view_agenda_outlined
                        : Icons.view_column_outlined,
                    color: isSelected ? AppColors.primary : AppColors.slate600,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          layout.displayName,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: isSelected ? AppColors.primary : AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          layout.description,
                          style: const TextStyle(fontSize: 11, color: AppColors.slate500),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    const Icon(Icons.check_circle_rounded, size: 18, color: AppColors.primary),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  // -------------------------------------------------------------
  // TAB 4: SECTIONS & CONTENT
  // -------------------------------------------------------------
  Widget _buildSectionsAndContentTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionTitle('Document Sections Visibility'),
        const SizedBox(height: 6),
        _buildSwitchTile(
          title: 'Bank Payment Details',
          subtitle: 'Bank name, account number & routing code',
          value: _config.showBankDetails,
          onChanged: (val) => _onConfigModified(_config.copyWith(showBankDetails: val)),
        ),
        _buildSwitchTile(
          title: 'Digital UPI / Payment ID',
          subtitle: 'UPI ID and fast payment handle',
          value: _config.showUpiDetails,
          onChanged: (val) => _onConfigModified(_config.copyWith(showUpiDetails: val)),
        ),
        _buildSwitchTile(
          title: 'Signature & Sign-Off',
          subtitle: 'Authorized signature box in footer',
          value: _config.showSignature,
          onChanged: (val) => _onConfigModified(_config.copyWith(showSignature: val)),
        ),
        _buildSwitchTile(
          title: 'Notes & Terms',
          subtitle: 'Customer notes container',
          value: _config.showNotes,
          onChanged: (val) => _onConfigModified(_config.copyWith(showNotes: val)),
        ),
        const SizedBox(height: 16),
        _buildSectionTitle('Table Columns'),
        const SizedBox(height: 6),
        _buildSwitchTile(
          title: 'Quantity (QTY) Column',
          subtitle: 'Number of units or hours',
          value: _config.showQuantity,
          onChanged: (val) => _onConfigModified(_config.copyWith(showQuantity: val)),
        ),
        _buildSwitchTile(
          title: 'Unit Price Column',
          subtitle: 'Individual item rate',
          value: _config.showUnitPrice,
          onChanged: (val) => _onConfigModified(_config.copyWith(showUnitPrice: val)),
        ),
        const SizedBox(height: 16),
        _buildSectionTitle('Custom Footer Closing Message'),
        const SizedBox(height: 6),
        TextField(
          controller: _footerMessageController,
          decoration: InputDecoration(
            hintText: 'e.g. Thank you for your business!',
            hintStyle: const TextStyle(fontSize: 13, color: AppColors.slate400),
            filled: true,
            fillColor: AppColors.slate50,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.cardBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.cardBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
          ),
          onChanged: (val) {
            _onConfigModified(_config.copyWith(customFooterMessage: val));
          },
        ),
      ],
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 11, color: AppColors.slate500),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            activeTrackColor: AppColors.primary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String text) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        color: AppColors.slate500,
        letterSpacing: 0.8,
      ),
    );
  }
}
