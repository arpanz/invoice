import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/app/app_review_service.dart';
import '../../../core/billing/billing_service.dart';
import '../../../core/database/db_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/pdf_helper.dart';
import '../../paywall/paywall_screen.dart';
import '../models/invoice_customization_config.dart';
import '../models/invoice_model.dart';
import '../models/line_item_model.dart';
import '../models/pdf_theme.dart';
import '../services/pdf_generator_service.dart';
import '../widgets/invoice_customizer_studio_sheet.dart';
import 'create_invoice_screen.dart';
import '../../../shared_widgets/app_dialog.dart';

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
  bool _isSent = false;
  final TransformationController _zoomController = TransformationController();
  bool _isZoomed = false;
  TapDownDetails? _doubleTapDetails;
  PdfTheme _currentTheme = PdfTheme.defaultTheme;
  InvoiceCustomizationConfig _customConfig = InvoiceCustomizationConfig.defaultConfig;

  @override
  void initState() {
    super.initState();
    _invoice = widget.invoice;
    _checkSentStatus();
    _loadThemeAndRender();
  }

  @override
  void dispose() {
    _zoomController.dispose();
    super.dispose();
  }

  Future<void> _checkSentStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final sent = prefs.getBool('invoice_sent_${_invoice.id}') ?? false;
    if (mounted) {
      setState(() => _isSent = sent);
    }
  }

  Future<void> _markSentStatus(bool sent) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('invoice_sent_${_invoice.id}', sent);
    if (mounted) {
      setState(() => _isSent = sent);
    }
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
      currency: _invoice.currency,
    );
  }

  Future<void> _loadThemeAndRender() async {
    final prefs = await SharedPreferences.getInstance();
    final savedConfigJson = prefs.getString('invoice_customization_${_invoice.id}') ??
        prefs.getString('default_invoice_customization');
    if (savedConfigJson != null) {
      final parsed = InvoiceCustomizationConfig.tryFromJsonString(savedConfigJson);
      if (parsed != null) {
        _customConfig = parsed;
        _currentTheme = parsed.toPdfTheme();
      }
    } else {
      final savedThemeId = prefs.getString('invoice_theme_${_invoice.id}') ??
          prefs.getString('default_pdf_theme');
      if (savedThemeId != null) {
        _currentTheme = PdfTheme.fromId(savedThemeId);
        _customConfig = InvoiceCustomizationConfig.fromTheme(_currentTheme);
      }
    }
    await _generateAndRasterizePdf();
  }

  Future<void> _openThemePicker() async {
    final profile = await _getBusinessProfile();
    final updated = await InvoiceCustomizerStudioSheet.show(
      context,
      initialConfig: _customConfig,
      invoice: _invoice,
      businessProfile: profile,
      showSetAsDefault: true,
      title: 'Invoice Design Studio',
    );
    if (updated != null && mounted) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('invoice_customization_${_invoice.id}', updated.toJsonString());
      await prefs.setString('invoice_theme_${_invoice.id}', updated.themeId.value);
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
      final profile = await _getBusinessProfile();
      final bytes = await PdfGeneratorService.generateInvoicePdf(
        invoice: _invoice,
        businessProfile: profile,
        isPro: isPro,
        customizationConfig: _customConfig,
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
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error rendering preview: $e')),
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

  Future<void> _updateStatus(
    InvoiceStatus newStatus, {
    double? paidAmount,
  }) async {
    final updateData = <String, dynamic>{
      'status': newStatus.value,
      'updated_at': DateTime.now().millisecondsSinceEpoch,
    };
    double finalPaidAmount = _invoice.paidAmount;
    if (paidAmount != null) {
      finalPaidAmount = paidAmount;
      updateData['paid_amount'] = paidAmount;
    } else if (newStatus == InvoiceStatus.paid) {
      finalPaidAmount = _invoice.grandTotal;
      updateData['paid_amount'] = _invoice.grandTotal;
    } else if (newStatus == InvoiceStatus.unpaid) {
      finalPaidAmount = 0.0;
      updateData['paid_amount'] = 0.0;
    }

    await DbProvider.update(
      DbProvider.tableInvoices,
      updateData,
      'id = ?',
      [_invoice.id],
    );
    _invoice = _invoice.copyWith(
      status: newStatus,
      paidAmount: finalPaidAmount,
      updatedAt: DateTime.now(),
    );
    setState(() {});
    await _generateAndRasterizePdf();
  }

  Future<void> _promptPartialPayment() async {
    final currencySymbol = CurrencyFormatter.getCurrencySymbol(_invoice.currency);
    final amount = await AppDialog.showPartialPayment(
      context: context,
      documentNumber: _invoice.invoiceNumber,
      grandTotal: _invoice.grandTotal,
      currencySymbol: currencySymbol,
      currentPaidAmount: _invoice.paidAmount,
    );

    if (amount == null) return;

    if (amount >= _invoice.grandTotal && _invoice.grandTotal > 0) {
      _updateStatus(
        InvoiceStatus.paid,
        paidAmount: _invoice.grandTotal,
      );
    } else if (amount <= 0) {
      _updateStatus(
        InvoiceStatus.unpaid,
        paidAmount: 0.0,
      );
    } else {
      _updateStatus(
        InvoiceStatus.partiallyPaid,
        paidAmount: amount,
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
                        'Change Invoice Status',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Invoice ${_invoice.invoiceNumber}',
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
              _buildStatusOption(
                InvoiceStatus.unpaid,
                'Unpaid',
                'Awaiting payment from client',
                Icons.pending_actions_rounded,
                AppColors.statusUnpaid,
                AppColors.statusUnpaidBg,
              ),
              const SizedBox(height: 8),
              _buildStatusOption(
                InvoiceStatus.partiallyPaid,
                'Partially Paid',
                'Record a deposit or partial amount',
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
              const SizedBox(height: 8),
              _buildStatusOption(
                InvoiceStatus.overdue,
                'Overdue',
                'Past payment due date',
                Icons.alarm_off_rounded,
                AppColors.statusOverdue,
                AppColors.statusOverdueBg,
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
        if (status == InvoiceStatus.partiallyPaid) {
          _promptPartialPayment();
        } else {
          _updateStatus(status);
        }
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

  Future<void> _sendInvoice() async {
    if (_pdfBytes == null) return;
    try {
      final path = await PdfGeneratorService.saveAndGetPath(
        _pdfBytes!,
        _invoice.invoiceNumber,
      );
      await Share.shareXFiles(
        [XFile(path)],
        text: 'Invoice ${_invoice.invoiceNumber} for ${_invoice.clientName}',
      );
      await _markSentStatus(true);
      await AppReviewService.instance.registerSignificantAction();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send invoice: $e')),
        );
      }
    }
  }

  Future<void> _downloadPdf() async {
    if (_pdfBytes == null) return;
    try {
      final path = await PdfGeneratorService.saveAndGetPath(
        _pdfBytes!,
        _invoice.invoiceNumber,
      );
      await AppReviewService.instance.registerSignificantAction();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.slate900,
          behavior: SnackBarBehavior.floating,
          content: Text('Invoice saved successfully to $path'),
          action: SnackBarAction(
            label: 'View',
            textColor: AppColors.electricAccent,
            onPressed: () {},
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save invoice: $e')),
        );
      }
    }
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
                  const Text(
                    'More Actions',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.slate400),
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
                subtitle: 'Customize typography, colors & layout',
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _currentTheme.previewBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _currentTheme.previewPrimary.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    _currentTheme.name,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _currentTheme.previewPrimary,
                    ),
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
                subtitle: 'Toggle current payment state',
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
                bgColor: const Color(0xFFFEE2E2),
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
                      fontWeight: FontWeight.w700,
                      color: isDestructive ? AppColors.accentRed : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppColors.slate500,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }

  Future<void> _duplicateInvoice() async {
    final newInvNumber = 'INV${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    final duplicate = _invoice.copyWith(
      id: 'inv-${DateTime.now().millisecondsSinceEpoch}',
      invoiceNumber: newInvNumber,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      status: InvoiceStatus.unpaid,
    );

    await DbProvider.insert(DbProvider.tableInvoices, duplicate.toMap());
    for (final item in duplicate.lineItems) {
      await DbProvider.insert(DbProvider.tableLineItems, {
        'id': 'li-${DateTime.now().microsecondsSinceEpoch}',
        'invoice_id': duplicate.id,
        'description': item.description,
        'quantity': item.quantity,
        'unit_price': item.unitPrice,
        'total': item.total,
        'sort_order': item.sortOrder,
      });
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Duplicated as $newInvNumber')),
    );
    Navigator.pop(context, true);
  }

  Future<void> _confirmDelete() async {
    final confirm = await AppDialog.showDelete(
      context: context,
      title: 'Delete Invoice?',
      message: 'Are you sure you want to delete ${_invoice.invoiceNumber}? This action cannot be undone.',
    );

    if (confirm == true) {
      await DbProvider.delete(DbProvider.tableInvoices, 'id = ?', [_invoice.id]);
      await PdfHelper.deletePdf(_invoice.invoiceNumber);
      if (mounted) {
        Navigator.pop(context, true);
      }
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
          _zoomController.value = Matrix4.diagonal3Values(zoomScale, zoomScale, 1.0);
        }
        _isZoomed = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isPro = context.watch<BillingService>().isPro;
    final currencySymbol = CurrencyFormatter.getCurrencySymbol(_invoice.currency);
    final dueDateFormatted = _invoice.dueDate != null
        ? DateFormat('dd/MM/yyyy').format(_invoice.dueDate!)
        : DateFormat('dd/MM/yyyy').format(_invoice.invoiceDate);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context, true),
        ),
        title: Text(
          _invoice.invoiceNumber,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.palette_outlined, color: AppColors.textPrimary),
            tooltip: 'PDF Theme',
            onPressed: _openThemePicker,
          ),
          if (!isPro)
            IconButton(
              icon: const Icon(Icons.workspace_premium_rounded, color: AppColors.proGold),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PaywallScreen()),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.share_outlined, color: AppColors.textPrimary),
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
                  color: const Color(0xFFF1F5F9),
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(color: AppColors.primary),
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
                                      final scale = _zoomController.value.getMaxScaleOnAxis();
                                      final zoomed = scale > 1.05;
                                      if (zoomed != _isZoomed) {
                                        setState(() => _isZoomed = zoomed);
                                      }
                                    },
                                    child: SizedBox(
                                      width: constraints.maxWidth,
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                        child: Column(
                                          children: _rasterPages!.map((img) {
                                            return Container(
                                              margin: const EdgeInsets.only(bottom: 16),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius: BorderRadius.circular(8),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black.withValues(alpha: 0.08),
                                                    blurRadius: 16,
                                                    offset: const Offset(0, 4),
                                                  ),
                                                ],
                                              ),
                                              child: ClipRRect(
                                                borderRadius: BorderRadius.circular(8),
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
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: _currentTheme.previewPrimary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'Style',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 2),
                          const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: AppColors.slate500),
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
                      color: Colors.white.withValues(alpha: 0.9),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: Icon(
                        _isZoomed ? Icons.zoom_out_rounded : Icons.zoom_in_rounded,
                        color: AppColors.textPrimary,
                        size: 22,
                      ),
                      onPressed: _toggleZoom,
                      tooltip: _isZoomed ? 'Zoom Out' : 'Zoom In',
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bottom Floating Details & Action Panel matching Screenshot 6
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row 1: Due Date + Status Dropdown Pill
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Due on $dueDateFormatted',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.slate500,
                        ),
                      ),
                      GestureDetector(
                        onTap: _showStatusPicker,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _invoice.status == InvoiceStatus.paid
                                ? AppColors.statusPaidBg
                                : _invoice.status == InvoiceStatus.partiallyPaid
                                    ? AppColors.statusPartiallyPaidBg
                                    : _invoice.status == InvoiceStatus.overdue
                                        ? AppColors.statusOverdueBg
                                        : AppColors.primaryMuted,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _invoice.status == InvoiceStatus.paid
                                  ? AppColors.statusPaid.withValues(alpha: 0.2)
                                  : _invoice.status == InvoiceStatus.partiallyPaid
                                      ? AppColors.statusPartiallyPaid.withValues(alpha: 0.2)
                                      : _invoice.status == InvoiceStatus.overdue
                                          ? AppColors.statusOverdue.withValues(alpha: 0.2)
                                          : AppColors.primary.withValues(alpha: 0.2),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _invoice.status.label,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: _invoice.status == InvoiceStatus.paid
                                      ? AppColors.statusPaid
                                      : _invoice.status == InvoiceStatus.partiallyPaid
                                          ? AppColors.statusPartiallyPaid
                                          : _invoice.status == InvoiceStatus.overdue
                                              ? AppColors.statusOverdue
                                              : AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.keyboard_arrow_down_rounded,
                                size: 16,
                                color: _invoice.status == InvoiceStatus.paid
                                    ? AppColors.statusPaid
                                    : _invoice.status == InvoiceStatus.partiallyPaid
                                        ? AppColors.statusPartiallyPaid
                                        : _invoice.status == InvoiceStatus.overdue
                                            ? AppColors.statusOverdue
                                            : AppColors.primary,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Row 2: Grand Total + Sent Status Badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        '$currencySymbol${_invoice.grandTotal.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _isSent ? AppColors.statusPaidBg : AppColors.slate100,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _isSent ? 'Sent' : 'Not sent',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _isSent ? AppColors.statusPaid : AppColors.slate500,
                          ),
                        ),
                      ),
                    ],
                  ),

                  if (_invoice.status == InvoiceStatus.partiallyPaid || _invoice.paidAmount > 0) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          'Paid: $currencySymbol${_invoice.paidAmount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.statusPaid,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Balance Due: $currencySymbol${_invoice.balanceDue.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.statusPartiallyPaid,
                          ),
                        ),
                      ],
                    ),
                  ],

                  // Row 3: Client Name
                  Text(
                    _invoice.clientName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Row 4: Primary Send Invoice Button (Full Width Blue)
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _sendInvoice,
                      icon: const Icon(Icons.send_rounded, size: 20, color: Colors.white),
                      label: const Text(
                        'Send Invoice',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.2,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

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
                        hasBadge: true,
                        onTap: _showMoreActions,
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
                width: 46,
                height: 46,
                decoration: const BoxDecoration(
                  color: AppColors.slate100,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 22, color: AppColors.slate700),
              ),
              if (hasBadge)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.accentRed,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.slate600,
            ),
          ),
        ],
      ),
    );
  }
}
