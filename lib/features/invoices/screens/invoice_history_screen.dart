import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/ads/ad_manager.dart';
import '../../../core/ads/banner_ad_widget.dart';
import '../../../core/billing/billing_service.dart';
import '../../../core/database/db_provider.dart';
import '../../../core/providers/currency_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/pdf_helper.dart';
import '../../../shared_widgets/empty_state_view.dart';
import '../models/invoice_model.dart';
import '../models/line_item_model.dart';
import '../services/pdf_generator_service.dart';
import 'create_invoice_screen.dart';

class InvoiceHistoryScreen extends StatefulWidget {
  const InvoiceHistoryScreen({super.key});

  @override
  State<InvoiceHistoryScreen> createState() => _InvoiceHistoryScreenState();
}

class _InvoiceHistoryScreenState extends State<InvoiceHistoryScreen> {
  List<InvoiceModel> _invoices = [];
  bool _isLoading = true;
  String _filterStatus = 'all';

  @override
  void initState() {
    super.initState();
    _loadInvoices();
  }

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

  Future<void> _markAsPaid(InvoiceModel invoice) async {
    await DbProvider.update(
      DbProvider.tableInvoices,
      {
        'status': InvoiceStatus.paid.value,
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
        content: Text('Delete ${invoice.invoiceNumber}? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete',
                style: TextStyle(color: AppColors.accentRed)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await DbProvider.delete(
          DbProvider.tableInvoices, 'id = ?', [invoice.id]);
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
    final pdfBytes = await _buildInvoicePdf(invoice);
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.9,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Row(
                children: [
                  const Text('Invoice Preview',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w700)),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PdfPreview(
                build: (_) async => pdfBytes,
                allowPrinting: false,
                allowSharing: false,
                canChangePageFormat: false,
                canChangeOrientation: false,
                pdfFileName: 'Invoice_${invoice.invoiceNumber}.pdf',
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          _runWithInterstitial(() => _printPdf(invoice)),
                      icon: const Icon(Icons.print_outlined, size: 18),
                      label: const Text('Print'),
                      style: OutlinedButton.styleFrom(
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          _runWithInterstitial(() => _sharePdf(invoice)),
                      icon: const Icon(Icons.share_outlined, size: 18),
                      label: const Text('Share'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
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

  Future<void> _printPdf(InvoiceModel invoice) async {
    final pdfBytes = await _buildInvoicePdf(invoice);
    if (mounted) await Printing.layoutPdf(onLayout: (_) async => pdfBytes);
  }

  Future<void> _sharePdf(InvoiceModel invoice) async {
    final pdfBytes = await _buildInvoicePdf(invoice);
    final path = await PdfGeneratorService.saveAndGetPath(
        pdfBytes, invoice.invoiceNumber);
    await Share.shareXFiles([XFile(path)],
        text: 'Invoice ${invoice.invoiceNumber}');
  }

  Future<void> _savePdf(InvoiceModel invoice) async {
    final pdfBytes = await _buildInvoicePdf(invoice);
    final path = await PdfGeneratorService.saveAndGetPath(
        pdfBytes, invoice.invoiceNumber);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Invoice saved at $path')));
  }

  Future<void> _runWithInterstitial(Future<void> Function() action) async {
    final isPro = context.read<BillingService>().isPro;
    if (isPro) {
      await action();
      return;
    }
    final completer = Completer<void>();
    AdManager.instance.showInterstitial(
      context,
      onAdDismissed: () {
        if (!completer.isCompleted) completer.complete();
      },
    );
    await completer.future;
    if (!mounted) return;
    await action();
  }

  Future<void> _handleInvoiceMenuAction(
      String action, InvoiceModel invoice) async {
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
    final prefs = await SharedPreferences.getInstance();
    final currencyProvider = context.read<CurrencyProvider>();
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
      currency: currencyProvider.currencyCode,
    );
  }

  @override
  Widget build(BuildContext context) {
    final billing = context.watch<BillingService>();
    final filtered = _filteredInvoices;

    // Build a list that injects a NativeAdWidget every 5 invoices (free users only)
    List<Widget> listItems = [];
    for (int i = 0; i < filtered.length; i++) {
      listItems.add(_buildInvoiceCard(filtered[i]));
      // Insert native ad after every 5th invoice
      if (!billing.isPro && (i + 1) % 5 == 0 && i != filtered.length - 1) {
        listItems.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: NativeAdWidget(height: 80, borderRadius: 12),
          ),
        );
      }
    }

    return Column(
      children: [
        // Filter chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
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
              ? const Center(child: CircularProgressIndicator())
              : filtered.isEmpty
                  ? EmptyStateView(
                      icon: Icons.receipt_long_outlined,
                      title: 'No Invoices',
                      subtitle: _filterStatus == 'all'
                          ? 'Create your first invoice to get started'
                          : 'No ${_filterStatus} invoices found',
                    )
                  : RefreshIndicator(
                      onRefresh: _loadInvoices,
                      child: ListView.separated(
                        padding:
                            const EdgeInsets.fromLTRB(16, 0, 16, 100),
                        itemCount: listItems.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 8),
                        itemBuilder: (_, index) => listItems[index],
                      ),
                    ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(12, 0, 12, 8),
          child: BannerAdWidget(),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filterStatus == value;
    return GestureDetector(
      onTap: () => setState(() => _filterStatus = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color:
                isSelected ? AppColors.primary : AppColors.cardBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color:
                isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildInvoiceCard(InvoiceModel invoice) {
    final dateFormat = DateFormat('dd MMM yyyy');
    final currencySymbol =
        CurrencyFormatter.getCurrencySymbol(invoice.currency);

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
          if (invoice.status != InvoiceStatus.paid)
            await _markAsPaid(invoice);
          return false;
        } else {
          await _deleteInvoice(invoice);
          return false;
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: InkWell(
          onTap: () => _showInvoicePreview(invoice),
          borderRadius: BorderRadius.circular(12),
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
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            invoice.clientName,
                            style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary),
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
                              color: AppColors.textPrimary),
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
                                  color: AppColors.slate400),
                              const SizedBox(width: 4),
                              Text(
                                dateFormat.format(invoice.invoiceDate),
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                          if (invoice.dueDate != null)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.schedule_outlined,
                                    size: 12,
                                    color: AppColors.slate400),
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
                      icon: const Icon(Icons.more_vert,
                          color: AppColors.slate500),
                      onSelected: (value) =>
                          _handleInvoiceMenuAction(value, invoice),
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                            value: 'edit', child: Text('Edit')),
                        const PopupMenuItem(
                            value: 'save', child: Text('Save PDF')),
                        const PopupMenuItem(
                            value: 'print', child: Text('Print')),
                        const PopupMenuItem(
                            value: 'share', child: Text('Share')),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('Delete',
                              style:
                                  TextStyle(color: AppColors.accentRed)),
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
          Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600)),
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
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w700, color: text)),
    );
  }
}
