import '../../../shared_widgets/document_pages.dart';
import 'package:flutter/material.dart';
import '../services/estimate_actions.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/localization/catalog_localization.dart';
import '../../../core/localization/l10n.dart';

import '../../../core/billing/billing_service.dart';
import '../../../core/database/db_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../invoices/models/invoice_customization_config.dart';
import '../../invoices/models/line_item_model.dart';
import '../../invoices/models/pdf_theme.dart';
import '../../invoices/screens/invoice_preview_screen.dart';
import '../../invoices/services/pdf_generator_service.dart';
import '../../invoices/widgets/invoice_customizer_studio_sheet.dart';
import '../models/estimate_model.dart';
import 'create_estimate_screen.dart';
import '../../../core/theme/app_icons.dart';

class EstimatePreviewScreen extends StatefulWidget {
  final EstimateModel estimate;

  const EstimatePreviewScreen({super.key, required this.estimate});

  @override
  State<EstimatePreviewScreen> createState() => _EstimatePreviewScreenState();
}

class _EstimatePreviewScreenState extends State<EstimatePreviewScreen> {
  late EstimateModel _estimate;
  Uint8List? _pdfBytes;
  List<MemoryImage>? _rasterPages;
  bool _isLoading = true;
  PdfTheme _currentTheme = PdfTheme.defaultTheme;
  InvoiceCustomizationConfig _customConfig = InvoiceCustomizationConfig.defaultConfig;

  @override
  void initState() {
    super.initState();
    _estimate = widget.estimate;
    _loadThemeAndRender();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<BusinessProfile> _getBusinessProfile() => EstimateActions.profileFor(_estimate);

  Future<void> _loadThemeAndRender() async {
    _customConfig = await EstimateActions.designForEstimate(_estimate.id);
    _currentTheme = _customConfig.toPdfTheme();
    await _generateAndRasterizePdf();
  }

  Future<void> _generateAndRasterizePdf() async {
    setState(() => _isLoading = true);
    try {
      final bytes = await EstimateActions.render(
        _estimate,
        isPro: context.read<BillingService>().isPro,
        design: _customConfig,
      );

      final images = <MemoryImage>[];
      await for (final page in Printing.raster(bytes, dpi: 150)) {
        final pngBytes = await page.toPng();
        images.add(MemoryImage(pngBytes));
      }

      if (mounted) {
        setState(() {
          _pdfBytes = bytes;
          _rasterPages = images;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Render estimate failed: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.couldNotShowThePreviewPleaseTryAgain)),
        );
      }
    }
  }

  Future<void> _openThemePicker() async {
    final profile = await _getBusinessProfile();
    if (!mounted) return;
    final updated = await InvoiceCustomizerStudioSheet.show(
      context,
      initialConfig: _customConfig,
      businessProfile: profile,
      showSetAsDefault: true,
      title: context.l10n.estimateDesignStudio,
    );
    if (updated != null && mounted) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('estimate_customization_${_estimate.id}', updated.toJsonString());
      await prefs.setString('estimate_theme_${_estimate.id}', updated.themeId.value);
      setState(() {
        _customConfig = updated;
        _currentTheme = updated.toPdfTheme();
      });
      await _generateAndRasterizePdf();
    }
  }

  Future<void> _sharePdf() async {
    final l10n = context.l10n;
    if (_pdfBytes == null) return;
    try {
      final path = await PdfGeneratorService.saveAndGetPath(
        _pdfBytes!,
        _estimate.estimateNumber,
      );
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(path)],
          text: l10n.estimateFor(_estimate.estimateNumber, _estimate.clientName),
        ),
      );
    } catch (e) {
      debugPrint('Share estimate failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.couldNotShareTheEstimatePleaseTryAgain)),
        );
      }
    }
  }

  Future<void> _printPdf() async {
    if (_pdfBytes == null) return;
    await Printing.layoutPdf(
      onLayout: (_) async => _pdfBytes!,
      name: 'Estimate_${_estimate.estimateNumber}.pdf',
    );
  }

  Future<void> _updateStatus(EstimateStatus status) async {
    if (EstimateActions.isLocked(_estimate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.aConvertedEstimateKeepsItsStatusDeleteIts)),
      );
      return;
    }
    final updated = _estimate.copyWith(status: status, updatedAt: DateTime.now());
    await DbProvider.update(
      DbProvider.tableEstimates,
      {'status': status.value, 'updated_at': updated.updatedAt.millisecondsSinceEpoch},
      'id = ?',
      [updated.id],
    );
    setState(() => _estimate = updated);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.estimateMarkedAs(context.l10n.catalogLabel(status.label)))),
      );
    }
  }

  void _showStatusPicker() {
    if (EstimateActions.isLocked(_estimate)) {
      _updateStatus(_estimate.status);
      return;
    }
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.slate300,
                  borderRadius: BorderRadius.circular(9999),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.updateStatus,
                        style: AppTypography.serif(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        context.l10n.estimate(_estimate.estimateNumber),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.slate500,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(AppIcons.close, color: AppColors.slate400),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildEstimateStatusTile(
                ctx: ctx,
                title: context.l10n.pending,
                subtitle: context.l10n.waitingForClientApproval,
                icon: EstimateStatus.pending.icon,
                iconColor: EstimateStatus.pending.color,
                bgColor: AppColors.squircleOrange,
                isSelected: _estimate.status == EstimateStatus.pending,
                onTap: () {
                  Navigator.pop(ctx);
                  _updateStatus(EstimateStatus.pending);
                },
              ),
              const SizedBox(height: 8),
              _buildEstimateStatusTile(
                ctx: ctx,
                title: context.l10n.accepted,
                subtitle: context.l10n.clientHasApprovedThisEstimate,
                icon: EstimateStatus.accepted.icon,
                iconColor: EstimateStatus.accepted.color,
                bgColor: AppColors.squircleGreen,
                isSelected: _estimate.status == EstimateStatus.accepted,
                onTap: () {
                  Navigator.pop(ctx);
                  _updateStatus(EstimateStatus.accepted);
                },
              ),
              const SizedBox(height: 8),
              _buildEstimateStatusTile(
                ctx: ctx,
                title: context.l10n.declined,
                subtitle: context.l10n.estimateWasNotAccepted,
                icon: EstimateStatus.declined.icon,
                iconColor: EstimateStatus.declined.color,
                bgColor: AppColors.statusOverdueBg,
                isSelected: _estimate.status == EstimateStatus.declined,
                onTap: () {
                  Navigator.pop(ctx);
                  _updateStatus(EstimateStatus.declined);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEstimateStatusTile({
    required BuildContext ctx,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryMuted : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primaryLight : AppColors.cardBorder,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? AppColors.primary : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.slate500,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(AppIcons.checkCircleFilled, color: AppColors.primary, size: 22),
          ],
        ),
      ),
    );
  }

  Future<void> _convertToInvoice() async {
    final invoice = await EstimateActions.convert(context, _estimate);
    if (invoice == null || !mounted) return;
    setState(() {
      _estimate = _estimate.copyWith(
        status: EstimateStatus.converted,
        convertedInvoiceId: invoice.id,
        updatedAt: DateTime.now(),
      );
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.convertedToInvoice(invoice.invoiceNumber))),
    );
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => InvoicePreviewScreen(invoice: invoice)),
    );
  }

  Future<void> _editEstimate() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateEstimateScreen(existingEstimate: _estimate),
      ),
    );

    if (result == true || mounted) {
      // Reload estimate from DB
      final rows = await DbProvider.query(
        DbProvider.tableEstimates,
        where: 'id = ?',
        whereArgs: [_estimate.id],
      );
      if (rows.isNotEmpty) {
        final itemRows = await DbProvider.query(
          DbProvider.tableEstimateLineItems,
          where: 'estimate_id = ?',
          whereArgs: [_estimate.id],
          orderBy: 'sort_order ASC',
        );
        final items = itemRows.map(LineItemModel.fromMap).toList();
        setState(() {
          _estimate = EstimateModel.fromMap(rows.first, items: items);
        });
        await _generateAndRasterizePdf();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencySymbol = CurrencyFormatter.getCurrencySymbol(_estimate.currency);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_estimate.estimateNumber),
        actions: [
          // Theme switch pill
          GestureDetector(
            onTap: _openThemePicker,
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.canvas,
                borderRadius: BorderRadius.circular(9999),
                border: Border.all(color: AppColors.hairline),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(AppIcons.palette, size: 14, color: AppColors.ink),
                  const SizedBox(width: 4),
                  Text(
                    context.l10n.catalogLabel(_currentTheme.name),
                    style: TextStyle(fontSize: 11.5, color: AppColors.ink, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            tooltip: context.l10n.edit,
            icon: Icon(AppIcons.edit, color: AppColors.ink),
            onPressed: _editEstimate,
          ),
        ],
      ),
      body: Column(
        children: [
          // Top Info Pill (Status, Valid Until, Grand Total)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.canvas,
              border: Border(bottom: BorderSide(color: AppColors.hairline)),
            ),
            child: Row(
              children: [
                // Status Chip
                GestureDetector(
                  onTap: _showStatusPicker,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _estimate.status.backgroundColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_estimate.status.icon, size: 13, color: _estimate.status.color),
                        const SizedBox(width: 4),
                        Text(
                          _estimate.status.label.toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _estimate.status.color,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Icon(AppIcons.caretDown, size: 16, color: _estimate.status.color),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                if (_estimate.expiryDate != null)
                  Expanded(
                    child: Text(
                      context.l10n.valid(DateFormat('dd MMM yyyy', context.localeName).format(_estimate.expiryDate!)),
                      style: TextStyle(
                        fontSize: 12,
                        color: _estimate.isExpired ? AppColors.statusOverdue : AppColors.muted,
                        fontWeight: _estimate.isExpired ? FontWeight.w600 : FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                Text(
                  CurrencyFormatter.format(
                    _estimate.grandTotal,
                    currencyCode: _estimate.currency,
                    currencySymbol: currencySymbol,
                  ),
                  style: AppTypography.money(fontSize: 18, color: AppColors.ink),
                ),
              ],
            ),
          ),

          // Main PDF Preview Canvas
          Expanded(
            child: DocumentPagesView(pages: _rasterPages, loading: _isLoading),
          ),

          // Bottom Action Bar
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            decoration: BoxDecoration(
              color: AppColors.canvas,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Convert to Invoice Primary Action
                  if (_estimate.canConvert)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.onPrimary,
                            shape: const StadiumBorder(),
                            elevation: 0,
                          ),
                          icon: const Icon(AppIcons.convert, size: 20),
                          label: Text(
                            context.l10n.convertToInvoiceAction,
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                          ),
                          onPressed: _convertToInvoice,
                        ),
                      ),
                    ),

                  // Actions row: Share, Print, Status
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: BorderSide(color: AppColors.primary),
                            shape: const StadiumBorder(),
                          ),
                          icon: Icon(AppIcons.share, size: 18, color: AppColors.primary),
                          label: Text(context.l10n.sharePdf, style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.primary)),
                          onPressed: _sharePdf,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: BorderSide(color: AppColors.slate300),
                            shape: const StadiumBorder(),
                          ),
                          icon: Icon(AppIcons.print, size: 18, color: AppColors.slate600),
                          label: Text(context.l10n.print, style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.slate700)),
                          onPressed: _printPdf,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
