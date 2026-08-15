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
import '../models/invoice_model.dart';
import '../models/line_item_model.dart';
import '../models/pdf_theme.dart';
import '../services/pdf_generator_service.dart';
import '../widgets/pdf_theme_picker_sheet.dart';
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
  bool _isSent = false;
  final TransformationController _zoomController = TransformationController();
  bool _isZoomed = false;
  PdfTheme _currentTheme = PdfTheme.defaultTheme;

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
      logoPath: prefs.getString('biz_logo_path'),
      signaturePath: prefs.getString('biz_signature_path'),
      currency: _invoice.currency,
    );
  }

  Future<void> _loadThemeAndRender() async {
    final prefs = await SharedPreferences.getInstance();
    final savedThemeId = prefs.getString('invoice_theme_${_invoice.id}') ??
        prefs.getString('default_pdf_theme');
    if (savedThemeId != null) {
      _currentTheme = PdfTheme.fromId(savedThemeId);
    }
    await _generateAndRasterizePdf();
  }

  Future<void> _openThemePicker() async {
    final selected = await PdfThemePickerSheet.show(
      context,
      currentTheme: _currentTheme,
      showSetAsDefault: true,
    );
    if (selected != null && mounted) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('invoice_theme_${_invoice.id}', selected.id.value);
      setState(() {
        _currentTheme = selected;
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
        theme: _currentTheme,
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

  Future<void> _updateStatus(InvoiceStatus newStatus) async {
    await DbProvider.update(
      DbProvider.tableInvoices,
      {
        'status': newStatus.value,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      'id = ?',
      [_invoice.id],
    );
    _invoice = _invoice.copyWith(
      status: newStatus,
      updatedAt: DateTime.now(),
    );
    setState(() {});
    await _generateAndRasterizePdf();
  }

  void _showStatusPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.slate300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Change Invoice Status',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              _buildStatusOption(
                InvoiceStatus.unpaid,
                'Unpaid',
                AppColors.statusUnpaid,
                AppColors.statusUnpaidBg,
              ),
              _buildStatusOption(
                InvoiceStatus.paid,
                'Paid',
                AppColors.statusPaid,
                AppColors.statusPaidBg,
              ),
              _buildStatusOption(
                InvoiceStatus.overdue,
                'Overdue',
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
    Color color,
    Color bg,
  ) {
    final isSelected = _invoice.status == status;
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: bg,
          shape: BoxShape.circle,
        ),
        child: Icon(
          status == InvoiceStatus.paid
              ? Icons.check_circle_rounded
              : status == InvoiceStatus.overdue
                  ? Icons.error_rounded
                  : Icons.pending_rounded,
          color: color,
          size: 20,
        ),
      ),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected ? color : AppColors.textPrimary,
        ),
      ),
      trailing: isSelected
          ? Icon(Icons.check_rounded, color: color)
          : null,
      onTap: () {
        Navigator.pop(context);
        _updateStatus(status);
      },
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.slate300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.palette_outlined, color: AppColors.slate700),
                title: const Text('Change PDF Theme'),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _currentTheme.previewBg,
                    borderRadius: BorderRadius.circular(6),
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
              ListTile(
                leading: const Icon(Icons.copy_rounded, color: AppColors.slate700),
                title: const Text('Duplicate Invoice'),
                onTap: () async {
                  Navigator.pop(ctx);
                  await _duplicateInvoice();
                },
              ),
              ListTile(
                leading: Icon(
                  _invoice.status == InvoiceStatus.paid
                      ? Icons.pending_outlined
                      : Icons.check_circle_outline_rounded,
                  color: _invoice.status == InvoiceStatus.paid
                      ? AppColors.statusUnpaid
                      : AppColors.statusPaid,
                ),
                title: Text(
                  _invoice.status == InvoiceStatus.paid
                      ? 'Mark as Unpaid'
                      : 'Mark as Paid',
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _updateStatus(
                    _invoice.status == InvoiceStatus.paid
                        ? InvoiceStatus.unpaid
                        : InvoiceStatus.paid,
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.share_outlined, color: AppColors.slate700),
                title: const Text('Share Invoice Link / File'),
                onTap: () {
                  Navigator.pop(ctx);
                  _sendInvoice();
                },
              ),
              const Divider(height: 16),
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded, color: AppColors.accentRed),
                title: const Text(
                  'Delete Invoice',
                  style: TextStyle(color: AppColors.accentRed, fontWeight: FontWeight.w600),
                ),
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
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Delete Invoice?'),
        content: Text('Are you sure you want to delete ${_invoice.invoiceNumber}? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentRed,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
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
    setState(() {
      _isZoomed = !_isZoomed;
      if (_isZoomed) {
        _zoomController.value = Matrix4.diagonal3Values(1.7, 1.7, 1.0);
      } else {
        _zoomController.value = Matrix4.identity();
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
                          : InteractiveViewer(
                              transformationController: _zoomController,
                              minScale: 0.8,
                              maxScale: 4.0,
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                child: Center(
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
                                : _invoice.status == InvoiceStatus.overdue
                                    ? AppColors.statusOverdueBg
                                    : AppColors.primaryMuted,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _invoice.status == InvoiceStatus.paid
                                  ? AppColors.statusPaid.withValues(alpha: 0.2)
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
