import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/billing/billing_service.dart';
import '../../../core/database/db_provider.dart';
import '../../../core/providers/currency_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/pdf_helper.dart';
import '../../../shared_widgets/empty_state_view.dart';
import '../../settings/screens/business_profile_screen.dart';
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
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.accentRed)),
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

  Future<void> _previewPdf(InvoiceModel invoice) async {
    final isPro = context.read<BillingService>().isPro;
    final profile = await _getBusinessProfile();

    final pdfBytes = await PdfGeneratorService.generateInvoicePdf(
      invoice: invoice,
      businessProfile: profile,
      isPro: isPro,
    );

    if (mounted) {
      await Printing.layoutPdf(onLayout: (_) async => pdfBytes);
    }
  }

  Future<void> _sharePdf(InvoiceModel invoice) async {
    final isPro = context.read<BillingService>().isPro;
    final profile = await _getBusinessProfile();

    final pdfBytes = await PdfGeneratorService.generateInvoicePdf(
      invoice: invoice,
      businessProfile: profile,
      isPro: isPro,
    );

    final path = await PdfGeneratorService.saveAndGetPath(pdfBytes, invoice.invoiceNumber);
    await Share.shareXFiles([XFile(path)], text: 'Invoice ${invoice.invoiceNumber}');
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
              : _filteredInvoices.isEmpty
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
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                        itemCount: _filteredInvoices.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, index) {
                          final invoice = _filteredInvoices[index];
                          return _buildInvoiceCard(invoice);
                        },
                      ),
                    ),
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.cardBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildInvoiceCard(InvoiceModel invoice) {
    final dateFormat = DateFormat('dd MMM yyyy');
    final currencySymbol = CurrencyFormatter.getCurrencySymbol(invoice.currency);

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
            await _markAsPaid(invoice);
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
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: InkWell(
          onTap: () => _previewPdf(invoice),
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
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            invoice.clientName,
                            style: const TextStyle(
                              fontSize: 13,
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
                          CurrencyFormatter.format(invoice.grandTotal, currencySymbol: currencySymbol),
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
                  children: [
                    Icon(Icons.calendar_today_outlined, size: 12, color: AppColors.slate400),
                    const SizedBox(width: 4),
                    Text(
                      dateFormat.format(invoice.invoiceDate),
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    if (invoice.dueDate != null) ...[
                      const SizedBox(width: 12),
                      Icon(Icons.schedule_outlined, size: 12, color: AppColors.slate400),
                      const SizedBox(width: 4),
                      Text(
                        'Due ${dateFormat.format(invoice.dueDate!)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: invoice.isOverdue ? AppColors.statusOverdue : AppColors.textSecondary,
                          fontWeight: invoice.isOverdue ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ],
                    const Spacer(),
                    // Action buttons
                    IconButton(
                      onPressed: () => _sharePdf(invoice),
                      icon: const Icon(Icons.share_outlined, size: 18),
                      color: AppColors.slate500,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CreateInvoiceScreen(existingInvoice: invoice),
                        ),
                      ).then((_) => _loadInvoices()),
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      color: AppColors.slate500,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
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
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(InvoiceStatus status) {
    Color bg;
    Color text;
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
