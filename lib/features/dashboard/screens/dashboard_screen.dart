import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/billing/billing_service.dart';
import '../../../core/database/db_provider.dart';
import '../../../core/providers/currency_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_animations.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared_widgets/empty_state_view.dart';
import '../../invoices/models/invoice_model.dart';
import '../../invoices/models/line_item_model.dart';
import '../../invoices/screens/create_invoice_screen.dart';
import '../../invoices/screens/invoice_history_screen.dart';
import '../../invoices/services/pdf_generator_service.dart';
import '../../../core/app/app_review_service.dart';
import '../../paywall/paywall_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => DashboardScreenState();
}

class DashboardScreenState extends State<DashboardScreen> {
  List<InvoiceModel> _recentInvoices = [];
  double _totalOutstanding = 0;
  double _paidThisMonth = 0;
  double _totalOverdue = 0;
  int _monthlyInvoiceCount = 0;
  bool _isLoading = true;
  String _currency = 'INR';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// Public entry-point so the nav shell can trigger a refresh via GlobalKey.
  void reload() => _loadData();

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final currencyProvider = context.read<CurrencyProvider>();
    _currency = currencyProvider.currencyCode;

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

    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    double outstanding = 0, paidThisMonth = 0, overdue = 0;

    for (final inv in invoices) {
      if (inv.status == InvoiceStatus.unpaid ||
          inv.status == InvoiceStatus.overdue) {
        outstanding += inv.grandTotal;
        if (inv.status == InvoiceStatus.overdue || inv.isOverdue) {
          overdue += inv.grandTotal;
        }
      } else if (inv.status == InvoiceStatus.paid) {
        if (inv.updatedAt.isAfter(startOfMonth)) {
          paidThisMonth += inv.grandTotal;
        }
      }
    }

    final monthlyCount = await DbProvider.countInvoicesThisMonth();

    setState(() {
      _recentInvoices = invoices.take(5).toList();
      _totalOutstanding = outstanding;
      _paidThisMonth = paidThisMonth;
      _totalOverdue = overdue;
      _monthlyInvoiceCount = monthlyCount;
      _isLoading = false;
    });
  }

  Future<void> _previewInvoice(InvoiceModel invoice) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (ctx) =>
          _InvoicePreviewSheet(invoice: invoice, currency: _currency),
    );
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
      if (mounted) _loadData();
      return;
    }
    if (action == 'delete') {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Delete Invoice?'),
          content: const Text('This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: TextButton.styleFrom(foregroundColor: AppColors.accentRed),
              child: const Text('Delete'),
            ),
          ],
        ),
      );
      if (confirm == true) {
        await DbProvider.delete(DbProvider.tableInvoices, 'id = ?', [
          invoice.id,
        ]);
        if (mounted) _loadData();
      }
      return;
    }
    if (action == 'print' || action == 'share' || action == 'save') {
      final isPro = context.read<BillingService>().isPro;
      if (!mounted) return;

      final prefs = await SharedPreferences.getInstance();
      final profile = BusinessProfile(
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
        currency: _currency,
      );

      final pdfBytes = await PdfGeneratorService.generateInvoicePdf(
        invoice: invoice,
        businessProfile: profile,
        isPro: isPro,
      );

      if (action == 'print') {
        await Printing.layoutPdf(onLayout: (_) async => pdfBytes);
      } else if (action == 'share') {
        final path = await PdfGeneratorService.saveAndGetPath(
          pdfBytes,
          invoice.invoiceNumber,
        );
        await Share.shareXFiles([
          XFile(path),
        ], text: 'Invoice ${invoice.invoiceNumber}');
        AppReviewService.instance.registerSignificantAction();
      } else if (action == 'save') {
        final path = await PdfGeneratorService.saveAndGetPath(
          pdfBytes,
          invoice.invoiceNumber,
        );
        AppReviewService.instance.registerSignificantAction();
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Invoice saved at $path')));
        }
      }
    }
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
    if (mounted) _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final currencyProvider = context.watch<CurrencyProvider>();
    final currencySymbol = currencyProvider.currencySymbol;
    final billing = context.watch<BillingService>();

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF0F172A),
            Color(0xFF1E40AF),
            Color(0xFF2563EB),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: RefreshIndicator(
          onRefresh: _loadData,
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 0,
                floating: true,
                snap: true,
                backgroundColor: Colors.transparent,
                surfaceTintColor: Colors.transparent,
                elevation: 0,
                systemOverlayStyle: SystemUiOverlayStyle.light,
                title: const Text(
                  'Overview',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                actions: [
                  IconButton(
                    onPressed: _loadData,
                    icon: const Icon(Icons.refresh_rounded),
                    color: Colors.white,
                  ),
                ],
              ),
              SliverToBoxAdapter(
                child: _isLoading
                    ? const SizedBox(
                        height: 400,
                        child: Center(child: CircularProgressIndicator(color: Colors.white)),
                      )
                    : Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Hero Outstanding Card
                            StaggeredEntrance(
                              index: 0,
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: AppColors.cardShadow,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: AppColors.primaryMuted,
                                            borderRadius: BorderRadius.circular(14),
                                          ),
                                          child: const Icon(
                                            Icons.account_balance_wallet_rounded,
                                            color: AppColors.primary,
                                            size: 24,
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        const Text(
                                          'TOTAL OUTSTANDING',
                                          style: TextStyle(
                                            color: AppColors.textSecondary,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 1.0,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      CurrencyFormatter.format(
                                        _totalOutstanding,
                                        currencySymbol: currencySymbol,
                                      ),
                                      style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 34,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: -1.0,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),

                            if (!billing.isPro) ...[
                              StaggeredEntrance(
                                index: 1,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: AppColors.cardShadow,
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryMuted,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: const Icon(
                                          Icons.receipt_long_rounded,
                                          size: 20,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Free Plan Usage',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w800,
                                                color: AppColors.textPrimary,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '$_monthlyInvoiceCount of 10 invoices created this month',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => const PaywallScreen(),
                                          ),
                                        ),
                                        style: TextButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 14,
                                            vertical: 6,
                                          ),
                                          minimumSize: Size.zero,
                                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                          backgroundColor: AppColors.proGoldLight,
                                          foregroundColor: AppColors.proGold,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                        ),
                                        child: const Text(
                                          'PRO',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                            ],

                            // Metrics Row
                            StaggeredEntrance(
                              index: 2,
                              child: Row(
                                children: [
                                  Expanded(
                                    child: _buildMetricCard(
                                      label: 'Paid This Month',
                                      value: CurrencyFormatter.format(
                                        _paidThisMonth,
                                        currencySymbol: currencySymbol,
                                      ),
                                      icon: Icons.check_circle_rounded,
                                      iconColor: AppColors.statusPaid,
                                      bgColor: AppColors.statusPaidBg,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildMetricCard(
                                      label: 'Overdue',
                                      value: CurrencyFormatter.format(
                                        _totalOverdue,
                                        currencySymbol: currencySymbol,
                                      ),
                                      icon: Icons.warning_rounded,
                                      iconColor: AppColors.statusOverdue,
                                      bgColor: AppColors.statusOverdueBg,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Recent Invoices Header
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Recent Invoices',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                if (_recentInvoices.isNotEmpty)
                                  TextButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => const InvoiceHistoryScreen(),
                                        ),
                                      ).then((_) => _loadData());
                                    },
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      minimumSize: Size.zero,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: const Text(
                                      'View All',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF93C5FD),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            if (_recentInvoices.isEmpty)
                              const EmptyStateView(
                                icon: Icons.receipt_long_rounded,
                                title: 'No Invoices Yet',
                                subtitle: 'Tap "+ New Invoice" to create your first invoice',
                                isDarkBackground: true,
                              )
                            else
                              ..._recentInvoices.asMap().entries.map(
                                (entry) => StaggeredEntrance(
                                  index: 3 + entry.key,
                                  child: Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: _buildRecentInvoiceCard(
                                      entry.value,
                                      currencySymbol,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String label,
    required String value,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: iconColor),
              ),
              const Spacer(),
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: iconColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentInvoiceCard(InvoiceModel invoice, String currencySymbol) {
    final dateFormat = DateFormat('dd MMM');
    Color statusBg, statusText;
    String statusLabel;

    switch (invoice.status) {
      case InvoiceStatus.paid:
        statusBg = AppColors.statusPaidBg;
        statusText = AppColors.statusPaid;
        statusLabel = 'Paid';
        break;
      case InvoiceStatus.overdue:
        statusBg = AppColors.statusOverdueBg;
        statusText = AppColors.statusOverdue;
        statusLabel = 'Overdue';
        break;
      default:
        statusBg = AppColors.statusUnpaidBg;
        statusText = AppColors.statusUnpaid;
        statusLabel = 'Unpaid';
    }

    final initials = invoice.clientName
        .split(' ')
        .take(2)
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
        .join();

    return GestureDetector(
      onTap: () => _previewInvoice(invoice),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder),
          boxShadow: AppColors.cardShadow,
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.primaryMuted,
              child: Text(
                initials.isEmpty ? 'IN' : initials,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    invoice.clientName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${invoice.invoiceNumber} • ${dateFormat.format(invoice.invoiceDate)}',
                    style: const TextStyle(
                      fontSize: 12,
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
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: statusText,
                    ),
                  ),
                ),
              ],
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded, color: AppColors.slate400),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              color: Colors.white,
              elevation: 4,
              onSelected: (value) => _handleInvoiceMenuAction(value, invoice),
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
      ),
    );
  }
}

class _InvoicePreviewSheet extends StatefulWidget {
  final InvoiceModel invoice;
  final String currency;
  const _InvoicePreviewSheet({required this.invoice, required this.currency});

  @override
  State<_InvoicePreviewSheet> createState() => _InvoicePreviewSheetState();
}

class _InvoicePreviewSheetState extends State<_InvoicePreviewSheet> {
  Uint8List? _pdfBytes;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _generatePdf();
  }

  Future<void> _generatePdf() async {
    final isPro = context.read<BillingService>().isPro;
    final prefs = await SharedPreferences.getInstance();
    final profile = BusinessProfile(
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
      currency: widget.currency,
    );

    final bytes = await PdfGeneratorService.generateInvoicePdf(
      invoice: widget.invoice,
      businessProfile: profile,
      isPro: isPro,
    );

    if (mounted) {
      setState(() {
        _pdfBytes = bytes;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
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
                const Text(
                  'Invoice Preview',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Generating PDF...',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )
                : _PdfRasterViewer(pdfBytes: _pdfBytes!),
          ),
          if (!_isLoading && _pdfBytes != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        Navigator.pop(context);
                        await Printing.layoutPdf(
                          onLayout: (_) async => _pdfBytes!,
                        );
                      },
                      icon: const Icon(Icons.print_outlined, size: 18),
                      label: const Text('Print'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        Navigator.pop(context);
                        final path = await PdfGeneratorService.saveAndGetPath(
                          _pdfBytes!,
                          widget.invoice.invoiceNumber,
                        );
                        await Share.shareXFiles([
                          XFile(path),
                        ], text: 'Invoice ${widget.invoice.invoiceNumber}');
                      },
                      icon: const Icon(Icons.share_outlined, size: 18),
                      label: const Text('Share'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Renders a PDF as rasterised images inside an [InteractiveViewer] so
/// pinch-to-zoom works immediately without any focus/tap-to-activate step.
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
