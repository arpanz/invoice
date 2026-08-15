import 'dart:async';

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
import '../../../core/providers/currency_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_animations.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/pdf_helper.dart';
import '../../../shared_widgets/empty_state_view.dart';
import '../models/invoice_model.dart';
import '../models/line_item_model.dart';
import '../services/pdf_generator_service.dart';
import 'create_invoice_screen.dart';
import 'invoice_preview_screen.dart';
import '../../paywall/paywall_screen.dart';

class InvoiceHistoryScreen extends StatefulWidget {
  const InvoiceHistoryScreen({super.key});

  @override
  State<InvoiceHistoryScreen> createState() => InvoiceHistoryScreenState();
}

class InvoiceHistoryScreenState extends State<InvoiceHistoryScreen> {
  List<InvoiceModel> _invoices = [];
  bool _isLoading = true;
  String _filterStatus = 'all';

  @override
  void initState() {
    super.initState();
    _loadInvoices();
  }

  /// Public entry-point so the nav shell can trigger a refresh via GlobalKey.
  void reload() => _loadInvoices();

  Future<void> _loadInvoices() async {
    setState(() => _isLoading = true);
    final rows = await DbProvider.query(
      DbProvider.tableInvoices,
      orderBy: 'created_at DESC',
    );
    final invoices = <InvoiceModel>[];
    for (final row in rows) {
      final itemRows = await DbProvider.query(
        DbProvider.tableLineItems,
        where: 'invoice_id = ?',
        whereArgs: [row['id']],
        orderBy: 'sort_order ASC',
      );
      final items = itemRows.map(LineItemModel.fromMap).toList();
      invoices.add(InvoiceModel.fromMap(row, items: items));
    }
    setState(() {
      _invoices = invoices;
      _isLoading = false;
    });
  }

  List<InvoiceModel> get _filteredInvoices {
    if (_filterStatus == 'all') return _invoices;
    return _invoices.where((i) => i.status.value == _filterStatus).toList();
  }

  Future<void> _markAs(InvoiceModel invoice, InvoiceStatus status) async {
    await DbProvider.update(
      DbProvider.tableInvoices,
      {
        'status': status.value,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      'id = ?',
      [invoice.id],
    );
    await _loadInvoices();
  }

  Future<void> _deleteInvoice(InvoiceModel invoice) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Invoice?'),
        content: Text(
          'Delete ${invoice.invoiceNumber}? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.accentRed),
            ),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await DbProvider.delete(DbProvider.tableInvoices, 'id = ?', [invoice.id]);
      await PdfHelper.deletePdf(invoice.invoiceNumber);
      await _loadInvoices();
    }
  }

  Future<Uint8List> _buildInvoicePdf(InvoiceModel invoice) async {
    final isPro = context.read<BillingService>().isPro;
    final profile = await _getBusinessProfile();
    return PdfGeneratorService.generateInvoicePdf(
      invoice: invoice,
      businessProfile: profile,
      isPro: isPro,
    );
  }

  Future<void> _showInvoicePreview(InvoiceModel invoice) async {
    final updated = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => InvoicePreviewScreen(invoice: invoice),
      ),
    );
    if (updated == true || mounted) {
      await _loadInvoices();
    }
  }

  Future<void> _printPdf(InvoiceModel invoice) async {
    final pdfBytes = await _buildInvoicePdf(invoice);
    if (mounted) await Printing.layoutPdf(onLayout: (_) async => pdfBytes);
  }

  Future<void> _sharePdf(InvoiceModel invoice) async {
    final pdfBytes = await _buildInvoicePdf(invoice);
    final path = await PdfGeneratorService.saveAndGetPath(
      pdfBytes,
      invoice.invoiceNumber,
    );
    await Share.shareXFiles([
      XFile(path),
    ], text: 'Invoice ${invoice.invoiceNumber}');
    await AppReviewService.instance.registerSignificantAction();
  }

  Future<void> _savePdf(InvoiceModel invoice) async {
    final pdfBytes = await _buildInvoicePdf(invoice);
    final path = await PdfGeneratorService.saveAndGetPath(
      pdfBytes,
      invoice.invoiceNumber,
    );
    await AppReviewService.instance.registerSignificantAction();
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Invoice saved at $path')));
  }

  Future<void> _runWithInterstitial(Future<void> Function() action) async {
    await action();
  }

  Future<void> _handleInvoiceMenuAction(
    String action,
    InvoiceModel invoice,
  ) async {
    if (action == 'paid') {
      await _markAs(invoice, InvoiceStatus.paid);
      return;
    }
    if (action == 'unpaid') {
      await _markAs(invoice, InvoiceStatus.unpaid);
      return;
    }
    if (action == 'edit') {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CreateInvoiceScreen(existingInvoice: invoice),
        ),
      );
      if (mounted) await _loadInvoices();
      return;
    }
    if (action == 'save') {
      await _runWithInterstitial(() => _savePdf(invoice));
      return;
    }
    if (action == 'delete') {
      await _deleteInvoice(invoice);
      return;
    }
    if (action == 'print') {
      await _runWithInterstitial(() => _printPdf(invoice));
      return;
    }
    if (action == 'share') {
      await _runWithInterstitial(() => _sharePdf(invoice));
      return;
    }
  }

  Future<BusinessProfile> _getBusinessProfile() async {
    final currencyProvider = context.read<CurrencyProvider>();
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
      currency: currencyProvider.currencyCode,
    );
  }

  @override
  Widget build(BuildContext context) {
    final billing = context.watch<BillingService>();
    final filtered = _filteredInvoices;

    // Cap list at 5 for free users; pro users see everything
    const int freeLimit = 5;
    final visibleInvoices = (!billing.isPro && filtered.length > freeLimit)
        ? filtered.sublist(0, freeLimit)
        : filtered;
    final isLimited = !billing.isPro && filtered.length > freeLimit;

    List<Widget> listItems = [];
    for (int i = 0; i < visibleInvoices.length; i++) {
      listItems.add(
        StaggeredEntrance(
          index: i,
          child: _buildInvoiceCard(visibleInvoices[i]),
        ),
      );
    }

    if (isLimited) {
      listItems.add(
        StaggeredEntrance(
          index: visibleInvoices.length,
          child: _buildProUpsellCard(context, filtered.length - freeLimit),
        ),
      );
    }

    return Column(
      children: [
        // Filter chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
          child: Row(
            children: [
              _buildFilterChip('All', 'all'),
              const SizedBox(width: 8),
              _buildFilterChip('Unpaid', 'unpaid'),
              const SizedBox(width: 8),
              _buildFilterChip('Paid', 'paid'),
              const SizedBox(width: 8),
              _buildFilterChip('Overdue', 'overdue'),
            ],
          ),
        ),

        // Invoice list
        Expanded(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                )
              : filtered.isEmpty
              ? EmptyStateView(
                  icon: Icons.receipt_long_rounded,
                  title: 'No Invoices',
                  subtitle: _filterStatus == 'all'
                      ? 'Create your first invoice to get started'
                      : 'No $_filterStatus invoices found',
                  isDarkBackground: false,
                )
              : RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: _loadInvoices,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                    itemCount: listItems.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (_, index) => listItems[index],
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filterStatus == value;
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _filterStatus = value);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(50),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.cardBorder,
            width: 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : const [
                  BoxShadow(
                    color: Color.fromRGBO(0, 0, 0, 0.02),
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildProUpsellCard(BuildContext context, int hiddenCount) {
    return Container(
      margin: const EdgeInsets.only(top: 4, bottom: 8),
      decoration: BoxDecoration(
        gradient: AppColors.proGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.floatingShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.proGold,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.lock_rounded,
                color: Colors.white,
                size: 26,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '$hiddenCount more invoice${hiddenCount > 1 ? 's' : ''} hidden',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Upgrade to Pro to access your full invoice history and unlock clean PDFs without watermarks.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.white70,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PaywallScreen()),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.proGold,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Unlock Full History — Go Pro',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvoiceCard(InvoiceModel invoice) {
    final dateFormat = DateFormat('dd MMM yyyy');
    final currencySymbol = CurrencyFormatter.getCurrencySymbol(
      invoice.currency,
    );

    return Dismissible(
      key: Key(invoice.id),
      background: _buildSwipeBackground(
        color: AppColors.statusPaid,
        icon: Icons.check_circle_outline,
        label: 'Mark Paid',
        alignment: Alignment.centerLeft,
      ),
      secondaryBackground: _buildSwipeBackground(
        color: AppColors.accentRed,
        icon: Icons.delete_outline,
        label: 'Delete',
        alignment: Alignment.centerRight,
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          if (invoice.status != InvoiceStatus.paid) {
            await _markAs(invoice, InvoiceStatus.paid);
          }
          return false;
        } else {
          await _deleteInvoice(invoice);
          return false;
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder),
          boxShadow: AppColors.cardShadow,
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showInvoicePreview(invoice),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            invoice.invoiceNumber,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            invoice.clientName,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          CurrencyFormatter.format(
                            invoice.grandTotal,
                            currencySymbol: currencySymbol,
                          ),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        _buildStatusBadge(invoice.status),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.calendar_today_outlined,
                                size: 12,
                                color: AppColors.slate400,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                dateFormat.format(invoice.invoiceDate),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          if (invoice.dueDate != null)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.schedule_outlined,
                                  size: 12,
                                  color: AppColors.slate400,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Due ${dateFormat.format(invoice.dueDate!)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: invoice.isOverdue
                                        ? AppColors.statusOverdue
                                        : AppColors.textSecondary,
                                    fontWeight: invoice.isOverdue
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(
                        Icons.more_vert,
                        color: AppColors.slate500,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      color: Colors.white,
                      elevation: 4,
                      onSelected: (value) =>
                          _handleInvoiceMenuAction(value, invoice),
                      itemBuilder: (_) => [
                        if (invoice.status != InvoiceStatus.paid)
                          PopupMenuItem(
                            value: 'paid',
                            child: Row(
                              children: const [
                                Icon(
                                  Icons.check_circle_outline,
                                  size: 20,
                                  color: AppColors.statusPaid,
                                ),
                                SizedBox(width: 12),
                                Text('Mark as Paid'),
                              ],
                            ),
                          ),
                        if (invoice.status == InvoiceStatus.paid)
                          PopupMenuItem(
                            value: 'unpaid',
                            child: Row(
                              children: const [
                                Icon(
                                  Icons.radio_button_unchecked,
                                  size: 20,
                                  color: AppColors.statusUnpaid,
                                ),
                                SizedBox(width: 12),
                                Text('Mark as Unpaid'),
                              ],
                            ),
                          ),
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: const [
                              Icon(
                                Icons.edit_outlined,
                                size: 20,
                                color: AppColors.slate600,
                              ),
                              SizedBox(width: 12),
                              Text('Edit'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'save',
                          child: Row(
                            children: const [
                              Icon(
                                Icons.download_outlined,
                                size: 20,
                                color: AppColors.slate600,
                              ),
                              SizedBox(width: 12),
                              Text('Save PDF'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'print',
                          child: Row(
                            children: const [
                              Icon(
                                Icons.print_outlined,
                                size: 20,
                                color: AppColors.slate600,
                              ),
                              SizedBox(width: 12),
                              Text('Print'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'share',
                          child: Row(
                            children: const [
                              Icon(
                                Icons.share_outlined,
                                size: 20,
                                color: AppColors.slate600,
                              ),
                              SizedBox(width: 12),
                              Text('Share'),
                            ],
                          ),
                        ),
                        const PopupMenuDivider(),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: const [
                              Icon(
                                Icons.delete_outline,
                                size: 20,
                                color: AppColors.accentRed,
                              ),
                              SizedBox(width: 12),
                              Text(
                                'Delete',
                                style: TextStyle(color: AppColors.accentRed),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSwipeBackground({
    required Color color,
    required IconData icon,
    required String label,
    required Alignment alignment,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(InvoiceStatus status) {
    Color bg, text;
    String label;
    switch (status) {
      case InvoiceStatus.paid:
        bg = AppColors.statusPaidBg;
        text = AppColors.statusPaid;
        label = 'Paid';
        break;
      case InvoiceStatus.overdue:
        bg = AppColors.statusOverdueBg;
        text = AppColors.statusOverdue;
        label = 'Overdue';
        break;
      default:
        bg = AppColors.statusUnpaidBg;
        text = AppColors.statusUnpaid;
        label = 'Unpaid';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: text,
        ),
      ),
    );
  }
}

class _PdfRasterViewer extends StatefulWidget {
  final Uint8List pdfBytes;
  const _PdfRasterViewer({required this.pdfBytes});

  @override
  State<_PdfRasterViewer> createState() => _PdfRasterViewerState();
}

class _PdfRasterViewerState extends State<_PdfRasterViewer> {
  List<MemoryImage>? _pages;
  int _currentPage = 0;
  final _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _rasterize();
  }

  Future<void> _rasterize() async {
    final images = <MemoryImage>[];
    await for (final page in Printing.raster(widget.pdfBytes, dpi: 200)) {
      final png = await page.toPng();
      images.add(MemoryImage(png));
    }
    if (mounted) setState(() => _pages = images);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_pages == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }
    return Stack(
      children: [
        PageView.builder(
          controller: _pageController,
          onPageChanged: (p) => setState(() => _currentPage = p),
          itemCount: _pages!.length,
          itemBuilder: (_, i) => InteractiveViewer(
            minScale: 0.8,
            maxScale: 5.0,
            child: Center(
              child: Image(image: _pages![i], fit: BoxFit.contain),
            ),
          ),
        ),
        if (_pages!.length > 1)
          Positioned(
            bottom: 8,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_currentPage + 1} / ${_pages!.length}',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
