import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import '../../../core/billing/billing_service.dart';
import '../../../core/database/db_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../paywall/paywall_screen.dart';
import '../models/invoice_customization_config.dart';
import '../models/invoice_model.dart';
import '../models/line_item_model.dart';
import '../models/pdf_theme.dart';
import '../services/invoice_actions.dart';
import '../widgets/payments_sheet.dart';
import '../services/invoice_render_service.dart';
import '../services/pdf_generator_service.dart';
import '../../../core/billing/free_limits.dart';
import 'package:uuid/uuid.dart';
import '../widgets/invoice_customizer_studio_sheet.dart';
import 'create_invoice_screen.dart';

class InvoicePreviewScreen extends StatefulWidget {
  final InvoiceModel invoice;

  const InvoicePreviewScreen({super.key, required this.invoice});

  @override
  State<InvoicePreviewScreen> createState() => _InvoicePreviewScreenState();
}

class _InvoicePreviewScreenState extends State<InvoicePreviewScreen> {
  late InvoiceModel _invoice;
  Uint8List? _pdfBytes;
  List<MemoryImage>? _rasterPages;
  bool _isLoading = true;
  bool get _isSent => _invoice.sentAt != null;
  final TransformationController _zoomController = TransformationController();
  bool _isZoomed = false;
  TapDownDetails? _doubleTapDetails;
  PdfTheme _currentTheme = PdfTheme.defaultTheme;
  InvoiceCustomizationConfig _customConfig =
      InvoiceCustomizationConfig.defaultConfig;
  bool _isBottomPanelCollapsed = false;

  @override
  void initState() {
    super.initState();
    _invoice = widget.invoice;
    _loadThemeAndRender();
  }

  @override
  void dispose() {
    _zoomController.dispose();
    super.dispose();
  }

  Future<void> _markSentStatus(bool sent) async {
    final sentAt = await InvoiceActions.setSent(_invoice.id, sent);
    if (mounted) {
      setState(() {
        _invoice = sentAt != null ? _invoice.copyWith(sentAt: sentAt) : _invoice.copyWith(clearSentAt: true);
      });
    }
  }

  Future<BusinessProfile> _getBusinessProfile() => InvoiceRenderService.profileFor(_invoice);

  Future<void> _loadThemeAndRender() async {
    _customConfig = await InvoiceRenderService.designForInvoice(_invoice.id);
    _currentTheme = _customConfig.toPdfTheme();
    await _generateAndRasterizePdf();
  }

  Future<void> _openThemePicker() async {
    final profile = await _getBusinessProfile();
    if (!mounted) return;
    final updated = await InvoiceCustomizerStudioSheet.show(
      context,
      initialConfig: _customConfig,
      invoice: _invoice,
      businessProfile: profile,
      showSetAsDefault: true,
      title: 'Invoice Design Studio',
    );
    if (updated != null && mounted) {
      await InvoiceRenderService.saveDesignForInvoice(_invoice.id, updated);
      if (!mounted) return;
      setState(() {
        _customConfig = updated;
        _currentTheme = updated.toPdfTheme();
      });
      await _generateAndRasterizePdf();
    }
  }

  Future<void> _generateAndRasterizePdf() async {
    setState(() => _isLoading = true);
    try {
      final isPro = context.read<BillingService>().isPro;
      final bytes = await InvoiceRenderService.renderInvoice(
        _invoice,
        isPro: isPro,
        design: _customConfig,
      );

      final images = <MemoryImage>[];
      await for (final page in Printing.raster(bytes, dpi: 220)) {
        final png = await page.toPng();
        images.add(MemoryImage(png));
      }

      if (mounted) {
        setState(() {
          _pdfBytes = bytes;
          _rasterPages = images;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Render preview failed: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not show the preview. Please try again.')),
        );
      }
    }
  }

  Future<void> _refreshInvoiceFromDb() async {
    final rows = await DbProvider.query(
      DbProvider.tableInvoices,
      where: 'id = ?',
      whereArgs: [_invoice.id],
    );
    if (rows.isNotEmpty) {
      final itemRows = await DbProvider.query(
        DbProvider.tableLineItems,
        where: 'invoice_id = ?',
        whereArgs: [_invoice.id],
        orderBy: 'sort_order ASC',
      );
      final items = itemRows.map(LineItemModel.fromMap).toList();
      final updated = InvoiceModel.fromMap(rows.first, items: items);
      setState(() => _invoice = updated);
      await _generateAndRasterizePdf();
    }
  }

  /// Changes the payment state through payments (see InvoiceActions).
  Future<void> _updateStatus(InvoiceStatus target) async {
    final changed = await InvoiceActions.changePaymentStatus(context, _invoice, target);
    if (changed && mounted) await _refreshInvoiceFromDb();
  }

  Future<void> _openPayments() async {
    final changed = await PaymentsSheet.show(context, _invoice);
    if (changed && mounted) await _refreshInvoiceFromDb();
  }

  void _showStatusPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
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
                        'Change Invoice Status',
                        style: AppTypography.serif(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Invoice ${_invoice.invoiceNumber}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.slate500,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      color: AppColors.slate400,
                    ),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildStatusOption(
                InvoiceStatus.unpaid,
                'Unpaid',
                'Deletes recorded payments',
                Icons.pending_actions_rounded,
                AppColors.statusUnpaid,
                AppColors.statusUnpaidBg,
              ),
              const SizedBox(height: 8),
              _buildStatusOption(
                InvoiceStatus.partiallyPaid,
                'Record a payment',
                'Add a deposit or part payment',
                Icons.pie_chart_outline_rounded,
                AppColors.statusPartiallyPaid,
                AppColors.statusPartiallyPaidBg,
              ),
              const SizedBox(height: 8),
              _buildStatusOption(
                InvoiceStatus.paid,
                'Paid in Full',
                'Payment received successfully',
                Icons.check_circle_rounded,
                AppColors.statusPaid,
                AppColors.statusPaidBg,
              ),

            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusOption(
    InvoiceStatus status,
    String label,
    String subtitle,
    IconData icon,
    Color color,
    Color bgColor,
  ) {
    final isSelected = _invoice.status == status;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        Navigator.pop(context);
        _updateStatus(status);
      },
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
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textPrimary,
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
              Icon(
                Icons.check_circle_rounded,
                color: AppColors.primary,
                size: 22,
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendInvoice() async {
    if (_pdfBytes == null) return;
    final updated = await InvoiceActions.share(context, _invoice, pdfBytes: _pdfBytes);
    if (updated != null && mounted) setState(() => _invoice = updated);
  }

  Future<void> _downloadPdf() async {
    if (_pdfBytes == null) return;
    await InvoiceActions.saveToDevice(context, _invoice, pdfBytes: _pdfBytes);
  }

  Future<void> _printPdf() async {
    if (_pdfBytes == null) return;
    await Printing.layoutPdf(
      onLayout: (_) async => _pdfBytes!,
      name: 'Invoice_${_invoice.invoiceNumber}',
    );
  }

  Future<void> _editInvoice() async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CreateInvoiceScreen(existingInvoice: _invoice),
      ),
    );
    if (updated == true || mounted) {
      await _refreshInvoiceFromDb();
    }
  }

  void _showMoreActions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
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
                  Text(
                    'More Actions',
                    style: AppTypography.serif(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      color: AppColors.slate400,
                    ),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _buildActionTile(
                icon: Icons.palette_outlined,
                iconColor: AppColors.squirclePurpleIcon,
                bgColor: AppColors.squirclePurple,
                title: 'Change PDF Theme',
                subtitle: '${_currentTheme.name} · typography, colours & layout',
                // The template's accent as a swatch; the text stays readable.
                trailing: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: _currentTheme.previewPrimary,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.hairline),
                  ),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _openThemePicker();
                },
              ),
              const SizedBox(height: 8),
              _buildActionTile(
                icon: Icons.copy_rounded,
                iconColor: AppColors.squircleCyanIcon,
                bgColor: AppColors.squircleCyan,
                title: 'Duplicate Invoice',
                subtitle: 'Create a new copy with same items',
                onTap: () async {
                  Navigator.pop(ctx);
                  await _duplicateInvoice();
                },
              ),
              const SizedBox(height: 8),
              _buildActionTile(
                icon: _invoice.status == InvoiceStatus.paid
                    ? Icons.pending_outlined
                    : Icons.check_circle_outline_rounded,
                iconColor: _invoice.status == InvoiceStatus.paid
                    ? AppColors.statusUnpaid
                    : AppColors.statusPaid,
                bgColor: _invoice.status == InvoiceStatus.paid
                    ? AppColors.statusUnpaidBg
                    : AppColors.statusPaidBg,
                title: _invoice.status == InvoiceStatus.paid
                    ? 'Mark as Unpaid'
                    : 'Mark as Paid',
                subtitle: _invoice.status == InvoiceStatus.paid
                    ? 'Deletes the recorded payments'
                    : 'Records a payment for the balance',
                onTap: () {
                  Navigator.pop(ctx);
                  _updateStatus(
                    _invoice.status == InvoiceStatus.paid
                        ? InvoiceStatus.unpaid
                        : InvoiceStatus.paid,
                  );
                },
              ),
              const SizedBox(height: 8),
              _buildActionTile(
                icon: Icons.payments_outlined,
                iconColor: AppColors.squircleGreenIcon,
                bgColor: AppColors.squircleGreen,
                title: 'Payments',
                subtitle: 'See, record or delete payments',
                onTap: () {
                  Navigator.pop(ctx);
                  _openPayments();
                },
              ),
              const SizedBox(height: 8),
              _buildActionTile(
                icon: Icons.share_outlined,
                iconColor: AppColors.primary,
                bgColor: AppColors.squircleBlue,
                title: 'Share Invoice Link / File',
                subtitle: 'Export or send PDF via email/apps',
                onTap: () {
                  Navigator.pop(ctx);
                  _sendInvoice();
                },
              ),
              const SizedBox(height: 8),
              _buildActionTile(
                icon: Icons.delete_outline_rounded,
                iconColor: AppColors.accentRed,
                bgColor: AppColors.statusOverdueBg,
                title: 'Delete Invoice',
                subtitle: 'Permanently remove this invoice',
                isDestructive: true,
                onTap: () async {
                  Navigator.pop(ctx);
                  await _confirmDelete();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Widget? trailing,
    bool isDestructive = false,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDestructive
                ? AppColors.accentRed.withValues(alpha: 0.2)
                : AppColors.cardBorder,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
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
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDestructive
                          ? AppColors.accentRed
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: AppColors.slate500,
                    ),
                  ),
                ],
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }

  Future<void> _duplicateInvoice() async {
    if (!await FreeLimits.canCreateInvoice(context)) return;
    try {
      final copy = await DbProvider.duplicateInvoice(
        _invoice,
        newInvoiceId: const Uuid().v4(),
        newLineId: () => const Uuid().v4(),
      );
      // The copy keeps this invoice's design.
      await InvoiceRenderService.saveDesignForInvoice(copy.id, _customConfig);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Duplicated as ${copy.invoiceNumber}, dated today and unpaid')),
      );
      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => InvoicePreviewScreen(invoice: copy)),
      );
    } catch (e) {
      debugPrint('Duplicate invoice failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not duplicate the invoice. Please try again.')),
        );
      }
    }
  }

  Future<void> _confirmDelete() async {
    if (await InvoiceActions.confirmAndDelete(context, _invoice) && mounted) {
      Navigator.pop(context, true);
    }
  }

  void _toggleZoom() {
    _handleDoubleTapZoom(null);
  }

  void _handleDoubleTapZoom(Offset? tapPosition) {
    setState(() {
      if (_isZoomed) {
        _zoomController.value = Matrix4.identity();
        _isZoomed = false;
      } else {
        const zoomScale = 2.5;
        if (tapPosition != null) {
          // Zoom into the tapped position
          final x = -tapPosition.dx * (zoomScale - 1);
          final y = -tapPosition.dy * (zoomScale - 1);
          _zoomController.value = Matrix4.identity()
            ..storage[12] = x
            ..storage[13] = y
            ..storage[0] = zoomScale
            ..storage[5] = zoomScale;
        } else {
          _zoomController.value = Matrix4.diagonal3Values(
            zoomScale,
            zoomScale,
            1.0,
          );
        }
        _isZoomed = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isPro = context.watch<BillingService>().isPro;
    final currencySymbol = CurrencyFormatter.getCurrencySymbol(
      _invoice.currency,
    );
    final dueDateFormatted = _invoice.dueDate != null
        ? DateFormat('dd MMM yyyy').format(_invoice.dueDate!)
        : DateFormat('dd MMM yyyy').format(_invoice.invoiceDate);

    return Scaffold(
      backgroundColor: AppColors.surfaceSoft,
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: AppColors.hairline),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
            color: AppColors.ink,
          ),
          onPressed: () => Navigator.pop(context, true),
        ),
        title: Text(
          _invoice.invoiceNumber,
          style: AppTypography.serif(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: AppColors.ink,
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              Icons.palette_outlined,
              color: AppColors.ink,
              size: 20,
            ),
            tooltip: 'PDF Theme',
            onPressed: _openThemePicker,
          ),
          if (!isPro)
            IconButton(
              icon: Icon(
                Icons.workspace_premium_rounded,
                color: AppColors.proGold,
                size: 20,
              ),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PaywallScreen()),
              ),
            ),
          IconButton(
            icon: Icon(
              Icons.share_outlined,
              color: AppColors.ink,
              size: 20,
            ),
            onPressed: _sendInvoice,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // PDF Document Viewer Area
          Expanded(
            child: Stack(
              children: [
                Container(
                  color: AppColors.surfaceSoft,
                  child: _isLoading
                      ? Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                        )
                      : (_rasterPages == null || _rasterPages!.isEmpty)
                      ? const Center(child: Text('Failed to render PDF'))
                      : LayoutBuilder(
                          builder: (context, constraints) {
                            return GestureDetector(
                              onDoubleTapDown: (details) {
                                _doubleTapDetails = details;
                              },
                              onDoubleTap: () {
                                _handleDoubleTapZoom(
                                  _doubleTapDetails?.localPosition,
                                );
                              },
                              child: InteractiveViewer(
                                transformationController: _zoomController,
                                constrained: false,
                                minScale: 1.0,
                                maxScale: 4.0,
                                boundaryMargin: const EdgeInsets.all(100),
                                onInteractionEnd: (_) {
                                  final scale = _zoomController.value
                                      .getMaxScaleOnAxis();
                                  final zoomed = scale > 1.05;
                                  if (zoomed != _isZoomed) {
                                    setState(() => _isZoomed = zoomed);
                                  }
                                },
                                child: SizedBox(
                                  width: constraints.maxWidth,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 16,
                                    ),
                                    child: Column(
                                      children: _rasterPages!.map((img) {
                                        return Container(
                                          margin: const EdgeInsets.only(
                                            bottom: 16,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            boxShadow: const [
                                              BoxShadow(
                                                color: Color.fromRGBO(0, 0, 0, 0.08),
                                                blurRadius: 16,
                                                offset: Offset(0, 4),
                                              ),
                                            ],
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            child: Image(
                                              image: img,
                                              fit: BoxFit.contain,
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
                // Quick Theme selector pill overlay in top left
                Positioned(
                  top: 12,
                  left: 16,
                  child: GestureDetector(
                    onTap: _openThemePicker,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.canvas,
                        borderRadius: BorderRadius.circular(9999), // pill
                        border: Border.all(color: AppColors.hairline),
                        boxShadow: const [
                          BoxShadow(
                            color: Color.fromRGBO(0, 0, 0, 0.06),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _currentTheme.previewPrimary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Style',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.ink,
                            ),
                          ),
                          const SizedBox(width: 2),
                          Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 14,
                            color: AppColors.muted,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Zoom Action Button overlay in top right
                Positioned(
                  top: 12,
                  right: 16,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.canvas,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.hairline),
                      boxShadow: const [
                        BoxShadow(
                          color: Color.fromRGBO(0, 0, 0, 0.06),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: Icon(
                        _isZoomed
                            ? Icons.zoom_out_rounded
                            : Icons.zoom_in_rounded,
                        color: AppColors.ink,
                        size: 20,
                      ),
                      onPressed: _toggleZoom,
                      tooltip: _isZoomed ? 'Zoom Out' : 'Zoom In',
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bottom Floating Details & Action Panel
          AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeInOutCubic,
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            decoration: BoxDecoration(
              color: AppColors.canvas,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              border: Border(top: BorderSide(color: AppColors.hairline)),
              boxShadow: [
                BoxShadow(
                  color: Color.fromRGBO(0, 0, 0, 0.08),
                  blurRadius: 20,
                  offset: Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Collapse / Expand Handle
                  Center(
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _isBottomPanelCollapsed = !_isBottomPanelCollapsed);
                      },
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 24),
                        child: Container(
                          width: 36,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.hairline,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),

                  if (_isBottomPanelCollapsed) ...[
                    // Compact collapsed single-row bar
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Due $dueDateFormatted • ${_invoice.clientName}',
                                style: GoogleFonts.inter(fontSize: 12, color: AppColors.muted),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                CurrencyFormatter.format(
                                  _invoice.grandTotal,
                                  currencyCode: _invoice.currency,
                                  currencySymbol: currencySymbol,
                                ),
                                style: AppTypography.serif(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.ink,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: _sendInvoice,
                          tooltip: 'Send Invoice',
                          icon: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.send_rounded, color: AppColors.onPrimary, size: 16),
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            HapticFeedback.selectionClick();
                            setState(() => _isBottomPanelCollapsed = false);
                          },
                          icon: Icon(Icons.keyboard_arrow_up_rounded, color: AppColors.muted),
                          tooltip: 'Expand details',
                        ),
                      ],
                    ),
                  ] else ...[
                    // Row 1: Due Date + Status Dropdown Pill
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Due on $dueDateFormatted',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.muted,
                          ),
                        ),
                        GestureDetector(
                          onTap: _showStatusPicker,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _invoice.effectiveStatus == InvoiceStatus.paid
                                  ? AppColors.statusPaidBg
                                  : _invoice.effectiveStatus == InvoiceStatus.partiallyPaid
                                  ? AppColors.statusPartiallyPaidBg
                                  : _invoice.effectiveStatus == InvoiceStatus.overdue
                                  ? AppColors.statusOverdueBg
                                  : AppColors.surfaceCard,
                              borderRadius: BorderRadius.circular(9999), // pill
                              border: Border.all(
                                color: _invoice.effectiveStatus == InvoiceStatus.paid
                                    ? AppColors.statusPaid.withValues(alpha: 0.2)
                                    : _invoice.effectiveStatus ==
                                          InvoiceStatus.partiallyPaid
                                    ? AppColors.statusPartiallyPaid.withValues(
                                        alpha: 0.2,
                                      )
                                    : _invoice.effectiveStatus == InvoiceStatus.overdue
                                    ? AppColors.statusOverdue.withValues(
                                        alpha: 0.2,
                                      )
                                    : AppColors.hairline,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _invoice.effectiveStatus.label,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: _invoice.effectiveStatus == InvoiceStatus.paid
                                        ? AppColors.statusPaid
                                        : _invoice.effectiveStatus ==
                                              InvoiceStatus.partiallyPaid
                                        ? AppColors.statusPartiallyPaid
                                        : _invoice.effectiveStatus == InvoiceStatus.overdue
                                        ? AppColors.statusOverdue
                                        : AppColors.ink,
                                  ),
                                ),
                                const SizedBox(width: 3),
                                Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  size: 14,
                                  color: _invoice.effectiveStatus == InvoiceStatus.paid
                                      ? AppColors.statusPaid
                                      : _invoice.effectiveStatus ==
                                            InvoiceStatus.partiallyPaid
                                      ? AppColors.statusPartiallyPaid
                                      : _invoice.effectiveStatus == InvoiceStatus.overdue
                                      ? AppColors.statusOverdue
                                      : AppColors.muted,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Row 2: Grand Total + Sent Status Badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          CurrencyFormatter.format(
                            _invoice.grandTotal,
                            currencyCode: _invoice.currency,
                            currencySymbol: currencySymbol,
                          ),
                          style: AppTypography.serif(
                            fontSize: 24,
                            fontWeight: FontWeight.w500,
                            color: AppColors.ink,
                            letterSpacing: -0.6,
                          ),
                        ),
                        Tooltip(
                          message: _isSent ? 'Tap to mark as not sent' : 'Tap to mark as sent',
                          child: InkWell(
                            borderRadius: BorderRadius.circular(9999),
                            onTap: () => _markSentStatus(!_isSent),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: _isSent
                                    ? AppColors.statusPaidBg
                                    : AppColors.surfaceCard,
                                borderRadius: BorderRadius.circular(9999), // pill
                                border: Border.all(color: AppColors.hairline),
                              ),
                              child: Text(
                                _isSent ? 'Sent' : 'Not sent',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: _isSent
                                      ? AppColors.statusPaid
                                      : AppColors.muted,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    if (_invoice.status == InvoiceStatus.partiallyPaid ||
                        _invoice.paidAmount > 0) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            'Paid: ${CurrencyFormatter.format(_invoice.paidAmount, currencyCode: _invoice.currency, currencySymbol: currencySymbol)}',
                            style: GoogleFonts.inter(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.statusPaid,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Balance Due: ${CurrencyFormatter.format(_invoice.balanceDue, currencyCode: _invoice.currency, currencySymbol: currencySymbol)}',
                            style: GoogleFonts.inter(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: _invoice.balanceDue > 0 ? AppColors.statusPartiallyPaid : AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ],

                    // Row 3: Client Name
                    const SizedBox(height: 2),
                    Text(
                      _invoice.clientName,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.muted,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Row 4: Primary Send Invoice Button (Cal.com Black CTA)
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: _sendInvoice,
                        icon: Icon(
                          Icons.send_rounded,
                          size: 18,
                          color: AppColors.onPrimary,
                        ),
                        label: Text(
                          'Send Invoice',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.onPrimary,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.onPrimary,
                          elevation: 0,
                          shape: const StadiumBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Row 5: Action Icons (Download, Print, Edit, More)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildActionButton(
                          icon: Icons.file_download_outlined,
                          label: 'Download',
                          onTap: _downloadPdf,
                        ),
                        _buildActionButton(
                          icon: Icons.print_outlined,
                          label: 'Print',
                          onTap: _printPdf,
                        ),
                        _buildActionButton(
                          icon: Icons.edit_outlined,
                          label: 'Edit',
                          onTap: _editInvoice,
                        ),
                        _buildActionButton(
                          icon: Icons.more_horiz_rounded,
                          label: 'More',
                          onTap: _showMoreActions,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool hasBadge = false,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.hairline),
                ),
                child: Icon(icon, size: 20, color: AppColors.ink),
              ),
              if (hasBadge)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: AppColors.body,
            ),
          ),
        ],
      ),
    );
  }
}

