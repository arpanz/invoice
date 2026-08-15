import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/billing/billing_service.dart';
import '../../../core/database/db_provider.dart';
import '../../../core/providers/currency_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/pdf_helper.dart';
import '../../invoices/models/invoice_model.dart';
import '../../invoices/models/line_item_model.dart';
import '../../invoices/models/pdf_theme.dart';
import '../../invoices/screens/create_invoice_screen.dart';
import '../../invoices/screens/invoice_preview_screen.dart';
import '../../invoices/services/pdf_generator_service.dart';
import '../../paywall/paywall_screen.dart';
import '../../settings/screens/settings_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => DashboardScreenState();
}

class DashboardScreenState extends State<DashboardScreen> {
  List<InvoiceModel> _allInvoices = [];
  bool _isLoading = true;
  String _selectedFilter = 'all'; // 'all', 'unpaid', 'partially_paid', 'overdue', 'paid'
  String _searchQuery = '';
  bool _isSearching = false;
  final _searchCtrl = TextEditingController();

  double _totalPaid = 0.0;
  double _totalUnpaid = 0.0;
  String _currency = 'INR';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  /// Public entry-point so the nav shell can trigger a refresh via GlobalKey.
  void reload() => _loadData();

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final currencyProvider = context.read<CurrencyProvider>();
    _currency = currencyProvider.currencyCode;

    final rows = await DbProvider.query(
      DbProvider.tableInvoices,
      orderBy: 'invoice_date DESC',
    );

    final List<InvoiceModel> loaded = [];
    double paidSum = 0.0;
    double unpaidSum = 0.0;

    for (final row in rows) {
      final invoiceId = row['id'] as String;
      final itemRows = await DbProvider.query(
        DbProvider.tableLineItems,
        where: 'invoice_id = ?',
        whereArgs: [invoiceId],
        orderBy: 'sort_order ASC',
      );
      final items = itemRows.map(LineItemModel.fromMap).toList();
      final inv = InvoiceModel.fromMap(row, items: items);
      loaded.add(inv);

      if (inv.status == InvoiceStatus.paid) {
        paidSum += inv.grandTotal;
      } else if (inv.status == InvoiceStatus.partiallyPaid) {
        paidSum += inv.paidAmount;
        unpaidSum += inv.balanceDue;
      } else {
        unpaidSum += inv.grandTotal;
      }
    }

    if (mounted) {
      setState(() {
        _allInvoices = loaded;
        _totalPaid = paidSum;
        _totalUnpaid = unpaidSum;
        _isLoading = false;
      });
    }
  }

  List<InvoiceModel> get _filteredInvoices {
    return _allInvoices.where((inv) {
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchesNum = inv.invoiceNumber.toLowerCase().contains(q);
        final matchesClient = inv.clientName.toLowerCase().contains(q);
        if (!matchesNum && !matchesClient) return false;
      }

      // Status chip filter
      if (_selectedFilter == 'all') return true;
      if (_selectedFilter == 'unpaid') return inv.status == InvoiceStatus.unpaid;
      if (_selectedFilter == 'partially_paid') return inv.status == InvoiceStatus.partiallyPaid;
      if (_selectedFilter == 'overdue') return inv.status == InvoiceStatus.overdue;
      if (_selectedFilter == 'paid') return inv.status == InvoiceStatus.paid;
      return true;
    }).toList();
  }

  // Groups invoices by month/year (e.g. "Aug 2026", "Jul 2026")
  Map<String, List<InvoiceModel>> _groupByMonth(List<InvoiceModel> list) {
    final Map<String, List<InvoiceModel>> grouped = {};
    for (final inv in list) {
      final key = DateFormat('MMM yyyy').format(inv.invoiceDate);
      grouped.putIfAbsent(key, () => []).add(inv);
    }
    return grouped;
  }

  Future<void> _openInvoicePreview(InvoiceModel invoice) async {
    final updated = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => InvoicePreviewScreen(invoice: invoice),
      ),
    );
    if (updated == true || mounted) {
      await _loadData();
    }
  }

  Future<void> _quickUpdateStatus(
    InvoiceModel invoice,
    InvoiceStatus status, {
    double? paidAmount,
  }) async {
    final updateData = <String, dynamic>{
      'status': status.value,
      'updated_at': DateTime.now().millisecondsSinceEpoch,
    };
    if (paidAmount != null) {
      updateData['paid_amount'] = paidAmount;
    } else if (status == InvoiceStatus.paid) {
      updateData['paid_amount'] = invoice.grandTotal;
    } else if (status == InvoiceStatus.unpaid) {
      updateData['paid_amount'] = 0.0;
    }

    await DbProvider.update(
      DbProvider.tableInvoices,
      updateData,
      'id = ?',
      [invoice.id],
    );
    await _loadData();
  }

  void _promptPartialPayment(InvoiceModel invoice) {
    final defaultAmount = invoice.paidAmount > 0
        ? invoice.paidAmount
        : (invoice.grandTotal * 0.5);
    final ctrl = TextEditingController(
      text: defaultAmount > 0
          ? defaultAmount.toStringAsFixed(2).replaceAll('.00', '')
          : '',
    );
    final currencySymbol = CurrencyFormatter.getCurrencySymbol(_currency);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Record Partial Payment',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter amount paid for ${invoice.invoiceNumber} (Total: $currencySymbol${invoice.grandTotal.toStringAsFixed(2)}):',
              style: const TextStyle(fontSize: 13, color: AppColors.slate600),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: ctrl,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                prefixText: '$currencySymbol ',
                labelText: 'Amount Paid',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(ctrl.text.trim()) ?? 0.0;
              Navigator.pop(ctx);
              if (amount >= invoice.grandTotal && invoice.grandTotal > 0) {
                _quickUpdateStatus(
                  invoice,
                  InvoiceStatus.paid,
                  paidAmount: invoice.grandTotal,
                );
              } else if (amount <= 0) {
                _quickUpdateStatus(
                  invoice,
                  InvoiceStatus.unpaid,
                  paidAmount: 0.0,
                );
              } else {
                _quickUpdateStatus(
                  invoice,
                  InvoiceStatus.partiallyPaid,
                  paidAmount: amount,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showQuickStatusPicker(InvoiceModel invoice) {
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
              Text(
                'Mark ${invoice.invoiceNumber} As',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(
                  Icons.pending_rounded,
                  color: AppColors.statusUnpaid,
                ),
                title: const Text(
                  'Unpaid',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                trailing: invoice.status == InvoiceStatus.unpaid
                    ? const Icon(Icons.check_rounded, color: AppColors.primary)
                    : null,
                onTap: () {
                  Navigator.pop(ctx);
                  _quickUpdateStatus(invoice, InvoiceStatus.unpaid);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.pie_chart_outline_rounded,
                  color: AppColors.statusPartiallyPaid,
                ),
                title: const Text(
                  'Partially Paid',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                trailing: invoice.status == InvoiceStatus.partiallyPaid
                    ? const Icon(Icons.check_rounded, color: AppColors.primary)
                    : null,
                onTap: () {
                  Navigator.pop(ctx);
                  _promptPartialPayment(invoice);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.statusPaid,
                ),
                title: const Text(
                  'Paid',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                trailing: invoice.status == InvoiceStatus.paid
                    ? const Icon(Icons.check_rounded, color: AppColors.primary)
                    : null,
                onTap: () {
                  Navigator.pop(ctx);
                  _quickUpdateStatus(invoice, InvoiceStatus.paid);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.error_rounded,
                  color: AppColors.statusOverdue,
                ),
                title: const Text(
                  'Overdue',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                trailing: invoice.status == InvoiceStatus.overdue
                    ? const Icon(Icons.check_rounded, color: AppColors.primary)
                    : null,
                onTap: () {
                  Navigator.pop(ctx);
                  _quickUpdateStatus(invoice, InvoiceStatus.overdue);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _sharePdf(InvoiceModel invoice) async {
    try {
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
        currency: invoice.currency,
      );

      final savedThemeId = prefs.getString('invoice_theme_${invoice.id}') ??
          prefs.getString('default_pdf_theme');
      final theme = PdfTheme.fromId(savedThemeId);

      final pdfBytes = await PdfGeneratorService.generateInvoicePdf(
        invoice: invoice,
        businessProfile: profile,
        isPro: isPro,
        theme: theme,
      );

      final path = await PdfGeneratorService.saveAndGetPath(
        pdfBytes,
        invoice.invoiceNumber,
      );

      await Share.shareXFiles(
        [XFile(path)],
        text: 'Invoice ${invoice.invoiceNumber} for ${invoice.clientName}',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to share: $e')),
        );
      }
    }
  }

  Future<void> _deleteInvoice(InvoiceModel invoice) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Invoice?'),
        content: Text('Are you sure you want to delete ${invoice.invoiceNumber}?'),
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
      await DbProvider.delete(DbProvider.tableInvoices, 'id = ?', [invoice.id]);
      await PdfHelper.deletePdf(invoice.invoiceNumber);
      await _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPro = context.watch<BillingService>().isPro;
    final currencySymbol = CurrencyFormatter.getCurrencySymbol(_currency);
    final filtered = _filteredInvoices;
    final grouped = _groupByMonth(filtered);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.menu_rounded, color: AppColors.textPrimary, size: 24),
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: AppColors.accentRed,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
            onPressed: () async {
              HapticFeedback.lightImpact();
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
              if (mounted) {
                _loadData();
              }
            },
          ),
        ),
        title: _isSearching
            ? TextField(
                controller: _searchCtrl,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search client or invoice #...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: AppColors.slate400, fontSize: 15),
                ),
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
                onChanged: (val) => setState(() => _searchQuery = val.trim()),
              )
            : const Text(
                'Invoices',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
        actions: [
          IconButton(
            icon: Icon(
              _isSearching ? Icons.close_rounded : Icons.search_rounded,
              color: AppColors.textPrimary,
              size: 22,
            ),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _isSearching = false;
                  _searchQuery = '';
                  _searchCtrl.clear();
                } else {
                  _isSearching = true;
                }
              });
            },
          ),
          if (!isPro)
            Padding(
              padding: const EdgeInsets.only(right: 14),
              child: GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PaywallScreen()),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.workspace_premium_rounded, size: 14, color: AppColors.proGold),
                      SizedBox(width: 4),
                      Text(
                        'PRO',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFFB45309),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            const SizedBox(width: 12),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: AppColors.primary,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Summary Cards (Total Paid / Total Unpaid) matching screenshots 4 & 5
                    Row(
                      children: [
                        // Card 1: Total Paid
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.cardBorder),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.02),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Total Paid',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.slate500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '$currencySymbol${_totalPaid.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.statusPaid,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Card 2: Total Unpaid
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.cardBorder),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.02),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Total Unpaid',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.slate500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '$currencySymbol${_totalUnpaid.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.textPrimary,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Filter Chips Row
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip('all', 'All'),
                          const SizedBox(width: 8),
                          _buildFilterChip('unpaid', 'Unpaid'),
                          const SizedBox(width: 8),
                          _buildFilterChip('partially_paid', 'Partially Paid'),
                          const SizedBox(width: 8),
                          _buildFilterChip('overdue', 'Overdue'),
                          const SizedBox(width: 8),
                          _buildFilterChip('paid', 'Paid'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Invoices List or Clean Empty State with Balloon
            if (_isLoading)
              const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              )
            else if (filtered.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _buildEmptyState(),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final monthKey = grouped.keys.elementAt(index);
                      final invoicesInMonth = grouped[monthKey]!;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Month Header (e.g. "Aug 2026") matching screenshot 5
                          Padding(
                            padding: const EdgeInsets.only(top: 14, bottom: 8, left: 4),
                            child: Text(
                              monthKey,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.slate500,
                              ),
                            ),
                          ),
                          ...invoicesInMonth.map((inv) => _buildInvoiceCard(inv, currencySymbol)),
                        ],
                      );
                    },
                    childCount: grouped.keys.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final isSelected = _selectedFilter == key;
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _selectedFilter = key);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.cardBorder,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.slate700,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 30),
          // Empty State Icon (Illustration container)
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 58,
                    height: 72,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.slate300, width: 1.5),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(width: 32, height: 3, color: AppColors.slate400),
                        const SizedBox(height: 5),
                        Container(width: 26, height: 3, color: AppColors.slate300),
                        const SizedBox(height: 5),
                        Container(width: 30, height: 3, color: AppColors.slate300),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No invoices found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Create your first invoice in seconds by tapping below',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.slate500,
            ),
          ),
          const SizedBox(height: 40),

          // Onboarding Coachmark Balloon pointing down towards + FAB (Screenshot 4)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Column(
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.touch_app_rounded, color: Colors.white70, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Create Your First Invoice',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Text(
                  'Tap the + button to get started',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildInvoiceCard(InvoiceModel invoice, String currencySymbol) {
    final dateFormatted = DateFormat('dd/MM/yyyy').format(invoice.invoiceDate);

    Color badgeColor;
    Color badgeBg;
    String badgeText;

    switch (invoice.status) {
      case InvoiceStatus.paid:
        badgeColor = AppColors.statusPaid;
        badgeBg = AppColors.statusPaidBg;
        badgeText = 'Paid';
        break;
      case InvoiceStatus.partiallyPaid:
        badgeColor = AppColors.statusPartiallyPaid;
        badgeBg = AppColors.statusPartiallyPaidBg;
        badgeText = 'Partially Paid';
        break;
      case InvoiceStatus.overdue:
        badgeColor = AppColors.statusOverdue;
        badgeBg = AppColors.statusOverdueBg;
        badgeText = 'Overdue';
        break;
      case InvoiceStatus.unpaid:
        badgeColor = AppColors.statusUnpaid;
        badgeBg = AppColors.statusUnpaidBg;
        badgeText = 'Unpaid';
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _openInvoicePreview(invoice),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                // Left: Client Name & Invoice Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        invoice.clientName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${invoice.invoiceNumber} | $dateFormatted',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.slate500,
                        ),
                      ),
                    ],
                  ),
                ),

                // Right: Amount + Status Dropdown Pill + 3-dots Menu
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$currencySymbol${invoice.grandTotal.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: () => _showQuickStatusPicker(invoice),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: badgeBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: badgeColor.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              badgeText,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: badgeColor,
                              ),
                            ),
                            const SizedBox(width: 2),
                            Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: badgeColor),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded, color: AppColors.slate500, size: 20),
                  onSelected: (action) {
                    if (action == 'preview') _openInvoicePreview(invoice);
                    if (action == 'share') _sharePdf(invoice);
                    if (action == 'edit') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CreateInvoiceScreen(existingInvoice: invoice),
                        ),
                      ).then((_) => _loadData());
                    }
                    if (action == 'delete') _deleteInvoice(invoice);
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'preview', child: Text('View Details')),
                    const PopupMenuItem(value: 'edit', child: Text('Edit Invoice')),
                    const PopupMenuItem(value: 'share', child: Text('Share PDF')),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete', style: TextStyle(color: AppColors.accentRed)),
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
}
