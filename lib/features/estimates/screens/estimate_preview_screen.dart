import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../../core/billing/billing_service.dart';
import '../../../core/database/db_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../invoices/models/invoice_customization_config.dart';
import '../../invoices/models/line_item_model.dart';
import '../../invoices/models/pdf_theme.dart';
import '../../invoices/screens/invoice_preview_screen.dart';
import '../../invoices/services/pdf_generator_service.dart';
import '../../invoices/widgets/invoice_customizer_studio_sheet.dart';
import '../models/estimate_model.dart';
import 'create_estimate_screen.dart';
import '../../../shared_widgets/app_dialog.dart';

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
  final TransformationController _zoomController = TransformationController();
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
    _zoomController.dispose();
    super.dispose();
  }

  Future<BusinessProfile> _getBusinessProfile() async {
    final prefs = await SharedPreferences.getInstance();
    return BusinessProfile(
      businessName: prefs.getString('biz_name') ?? 'My Business',
      address: prefs.getString('biz_address'),
      phone: prefs.getString('biz_phone'),
      email: prefs.getString('biz_email'),
      gstin: prefs.getString('biz_gstin'),
      bankName: prefs.getString('biz_bank_name'),
      accountNumber: prefs.getString('biz_account'),
      ifscCode: prefs.getString('biz_ifsc'),
      upiId: prefs.getString('biz_upi'),
      logoPath: prefs.getString('biz_logo_path'),
      signaturePath: prefs.getString('biz_signature_path'),
      currency: _estimate.currency,
      invoiceTitleOverride: 'ESTIMATE',
    );
  }

  Future<void> _loadThemeAndRender() async {
    final prefs = await SharedPreferences.getInstance();
    final savedConfigJson = prefs.getString('estimate_customization_${_estimate.id}') ??
        prefs.getString('default_invoice_customization');
    if (savedConfigJson != null) {
      final parsed = InvoiceCustomizationConfig.tryFromJsonString(savedConfigJson);
      if (parsed != null) {
        _customConfig = parsed;
        _currentTheme = parsed.toPdfTheme();
      }
    } else {
      final savedThemeId = prefs.getString('estimate_theme_${_estimate.id}') ??
          prefs.getString('default_pdf_theme');
      if (savedThemeId != null) {
        _currentTheme = PdfTheme.fromId(savedThemeId);
        _customConfig = InvoiceCustomizationConfig.fromTheme(_currentTheme);
      }
    }
    await _generateAndRasterizePdf();
  }

  Future<void> _generateAndRasterizePdf() async {
    setState(() => _isLoading = true);
    try {
      final isPro = context.read<BillingService>().isPro;
      final profile = await _getBusinessProfile();

      final bytes = await PdfGeneratorService.generateEstimatePdf(
        estimate: _estimate,
        businessProfile: profile,
        isPro: isPro,
        customizationConfig: _customConfig,
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
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to render PDF preview: $e')),
        );
      }
    }
  }

  Future<void> _openThemePicker() async {
    final profile = await _getBusinessProfile();
    final updated = await InvoiceCustomizerStudioSheet.show(
      context,
      initialConfig: _customConfig,
      businessProfile: profile,
      showSetAsDefault: true,
      title: 'Estimate Design Studio',
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
    if (_pdfBytes == null) return;
    try {
      final path = await PdfGeneratorService.saveAndGetPath(
        _pdfBytes!,
        _estimate.estimateNumber,
      );
      await Share.shareXFiles(
        [XFile(path)],
        text: 'Estimate ${_estimate.estimateNumber} for ${_estimate.clientName}',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to share PDF: $e')),
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
    final updated = _estimate.copyWith(status: status, updatedAt: DateTime.now());
    await DbProvider.update(
      DbProvider.tableEstimates,
      updated.toMap(),
      'id = ?',
      [updated.id],
    );
    setState(() => _estimate = updated);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Estimate marked as ${status.label}')),
      );
    }
  }

  void _showStatusPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
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
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Update Status',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Estimate ${_estimate.estimateNumber}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.slate500,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.slate400),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildEstimateStatusTile(
                ctx: ctx,
                title: 'Pending',
                subtitle: 'Waiting for client approval',
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
                title: 'Accepted',
                subtitle: 'Client has approved this estimate',
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
                title: 'Declined',
                subtitle: 'Estimate was not accepted',
                icon: EstimateStatus.declined.icon,
                iconColor: EstimateStatus.declined.color,
                bgColor: const Color(0xFFFEE2E2),
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
                      fontWeight: FontWeight.w700,
                      color: isSelected ? AppColors.primary : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.slate500,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 22),
          ],
        ),
      ),
    );
  }

  Future<void> _convertToInvoice() async {
    final confirm = await AppDialog.showConvertEstimate(
      context: context,
      estimateNumber: _estimate.estimateNumber,
      clientName: _estimate.clientName,
    );

    if (confirm != true) return;

    try {
      final nextInvNumber = await DbProvider.getNextInvoiceNumber();
      final newInvoiceId = const Uuid().v4();

      final invoice = _estimate.toInvoiceModel(
        newInvoiceId: newInvoiceId,
        newInvoiceNumber: nextInvNumber,
      );

      // Save Invoice to DB
      await DbProvider.insert(DbProvider.tableInvoices, invoice.toMap());
      for (int i = 0; i < invoice.lineItems.length; i++) {
        final item = invoice.lineItems[i];
        await DbProvider.insert(DbProvider.tableLineItems, {
          'id': item.id,
          'invoice_id': invoice.id,
          'description': item.description,
          'quantity': item.quantity,
          'unit_price': item.unitPrice,
          'total': item.total,
          'sort_order': i,
        });
      }

      // Mark estimate as Converted
      final updatedEstimate = _estimate.copyWith(
        status: EstimateStatus.converted,
        convertedInvoiceId: newInvoiceId,
        updatedAt: DateTime.now(),
      );
      await DbProvider.update(
        DbProvider.tableEstimates,
        updatedEstimate.toMap(),
        'id = ?',
        [updatedEstimate.id],
      );

      setState(() => _estimate = updatedEstimate);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Converted to Invoice $nextInvNumber!'),
          action: SnackBarAction(
            label: 'VIEW INVOICE',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => InvoicePreviewScreen(invoice: invoice),
                ),
              );
            },
          ),
        ),
      );

      // Navigate to the newly created invoice preview
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => InvoicePreviewScreen(invoice: invoice),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to convert estimate: $e')),
        );
      }
    }
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
      backgroundColor: const Color(0xFF1E293B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          _estimate.estimateNumber,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        actions: [
          // Theme switch pill
          GestureDetector(
            onTap: _openThemePicker,
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white24),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.palette_rounded, size: 14, color: AppColors.primaryMuted),
                  const SizedBox(width: 4),
                  Text(
                    _currentTheme.name,
                    style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            tooltip: 'Edit',
            icon: const Icon(Icons.edit_rounded, color: Colors.white),
            onPressed: _editEstimate,
          ),
        ],
      ),
      body: Column(
        children: [
          // Top Info Pill (Status, Valid Until, Grand Total)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: const Color(0xFF0F172A),
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
                            fontWeight: FontWeight.w800,
                            color: _estimate.status.color,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Icon(Icons.arrow_drop_down_rounded, size: 16, color: _estimate.status.color),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                if (_estimate.expiryDate != null)
                  Expanded(
                    child: Text(
                      'Valid: ${DateFormat('dd MMM yyyy').format(_estimate.expiryDate!)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: _estimate.isExpired ? AppColors.accentRed : AppColors.slate300,
                        fontWeight: _estimate.isExpired ? FontWeight.w700 : FontWeight.w500,
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
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          // Main PDF Preview Canvas
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _rasterPages == null || _rasterPages!.isEmpty
                    ? const Center(child: Text('Could not render preview', style: TextStyle(color: Colors.white70)))
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          return InteractiveViewer(
                            transformationController: _zoomController,
                            constrained: false,
                            minScale: 0.8,
                            maxScale: 3.5,
                            boundaryMargin: const EdgeInsets.all(80),
                            child: SizedBox(
                              width: constraints.maxWidth,
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  children: _rasterPages!.map((pageImg) {
                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 16),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.4),
                                            blurRadius: 16,
                                            offset: const Offset(0, 6),
                                          ),
                                        ],
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image(image: pageImg),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),

          // Bottom Action Bar
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                            backgroundColor: const Color(0xFF10B981), // Emerald
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            elevation: 2,
                          ),
                          icon: const Icon(Icons.transform_rounded, size: 20),
                          label: const Text(
                            'Convert to Invoice',
                            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
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
                            side: const BorderSide(color: AppColors.primary),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.share_rounded, size: 18, color: AppColors.primary),
                          label: const Text('Share PDF', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary)),
                          onPressed: _sharePdf,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: const BorderSide(color: AppColors.slate300),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.print_rounded, size: 18, color: AppColors.slate600),
                          label: const Text('Print', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.slate700)),
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
