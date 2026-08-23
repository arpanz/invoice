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
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_animations.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/pdf_helper.dart';
import '../../../shared_widgets/empty_state_view.dart';
import '../models/invoice_model.dart';
import '../models/line_item_model.dart';
import '../models/pdf_theme.dart';
import '../services/pdf_generator_service.dart';
import 'create_invoice_screen.dart';
import 'invoice_preview_screen.dart';
import '../../paywall/paywall_screen.dart';
import '../../../shared_widgets/app_dialog.dart';
import '../../../shared_widgets/app_popup_menu.dart';

class InvoiceHistoryScreen extends StatefulWidget {
  const InvoiceHistoryScreen({super.key});

  @override
  State<InvoiceHistoryScreen> createState() => InvoiceHistoryScreenState();
}

class InvoiceHistoryScreenState extends State<InvoiceHistoryScreen> {
  List<InvoiceModel> _invoices = [];
  bool _isLoading = true;
  String _filterStatus = 'all'; // 'all', 'unpaid', 'partially_paid', 'overdue', 'paid'
  String _searchQuery = '';
  bool _isSearching = false;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadInvoices();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  /// Public entry-point so the nav shell can trigger a refresh via GlobalKey.
  void reload() => _loadInvoices();

  Future<void> _loadInvoices() async {
    setState(() => _isLoading = true);

    final rows = await DbProvider.query(
      DbProvider.tableInvoices,
      orderBy: 'invoice_date DESC',
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

    if (mounted) {
      setState(() {
        _invoices = invoices;
        _isLoading = false;
      });
    }
  }

  List<InvoiceModel> get _filteredInvoices {
    return _invoices.where((inv) {
      // 1. Search Query Filter (invoice #, client name, email, phone, gstin, notes, line items)
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchNum = inv.invoiceNumber.toLowerCase().contains(q);
        final matchName = inv.clientName.toLowerCase().contains(q);
        final matchEmail = inv.clientEmail?.toLowerCase().contains(q) ?? false;
        final matchPhone = inv.clientPhone?.toLowerCase().contains(q) ?? false;
        final matchGstin = inv.clientGstin?.toLowerCase().contains(q) ?? false;
        final matchNotes = inv.notes?.toLowerCase().contains(q) ?? false;
        final matchItems = inv.lineItems.any(
          (li) => li.description.toLowerCase().contains(q),
        );

        if (!matchNum &&
            !matchName &&
            !matchEmail &&
            !matchPhone &&
            !matchGstin &&
            !matchNotes &&
            !matchItems) {
          return false;
        }
      }

      // 2. Status Filter Chip
      if (_filterStatus == 'all') return true;
      if (_filterStatus == 'unpaid') return inv.status == InvoiceStatus.unpaid;
      if (_filterStatus == 'partially_paid') {
        return inv.status == InvoiceStatus.partiallyPaid;
      }
      if (_filterStatus == 'overdue') return inv.status == InvoiceStatus.overdue;
      if (_filterStatus == 'paid') return inv.status == InvoiceStatus.paid;
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
    await _loadInvoices();
  }

  Future<void> _promptPartialPayment(InvoiceModel invoice) async {
    final currencySymbol = CurrencyFormatter.getCurrencySymbol(invoice.currency);
    final amount = await AppDialog.showPartialPayment(
      context: context,
      documentNumber: invoice.invoiceNumber,
      grandTotal: invoice.grandTotal,
      currencySymbol: currencySymbol,
      currentPaidAmount: invoice.paidAmount,
    );

    if (amount == null) return;

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
  }

  void _showQuickStatusPicker(InvoiceModel invoice) {
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
                        'Invoice ${invoice.invoiceNumber}',
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
              _buildHistoryStatusTile(
                ctx: ctx,
                title: 'Unpaid',
                subtitle: 'Awaiting payment from client',
                icon: Icons.pending_actions_rounded,
                iconColor: AppColors.statusUnpaid,
                bgColor: AppColors.statusUnpaidBg,
                isSelected: invoice.status == InvoiceStatus.unpaid,
                onTap: () {
                  Navigator.pop(ctx);
                  _quickUpdateStatus(invoice, InvoiceStatus.unpaid);
                },
              ),
              const SizedBox(height: 8),
              _buildHistoryStatusTile(
                ctx: ctx,
                title: 'Partially Paid',
                subtitle: 'Record a deposit or partial amount',
                icon: Icons.pie_chart_outline_rounded,
                iconColor: AppColors.statusPartiallyPaid,
                bgColor: AppColors.statusPartiallyPaidBg,
                isSelected: invoice.status == InvoiceStatus.partiallyPaid,
                onTap: () {
                  Navigator.pop(ctx);
                  _promptPartialPayment(invoice);
                },
              ),
              const SizedBox(height: 8),
              _buildHistoryStatusTile(
                ctx: ctx,
                title: 'Paid in Full',
                subtitle: 'Payment received successfully',
                icon: Icons.check_circle_rounded,
                iconColor: AppColors.statusPaid,
                bgColor: AppColors.statusPaidBg,
                isSelected: invoice.status == InvoiceStatus.paid,
                onTap: () {
                  Navigator.pop(ctx);
                  _quickUpdateStatus(invoice, InvoiceStatus.paid);
                },
              ),
              const SizedBox(height: 8),
              _buildHistoryStatusTile(
                ctx: ctx,
                title: 'Overdue',
                subtitle: 'Past payment due date',
                icon: Icons.alarm_off_rounded,
                iconColor: AppColors.statusOverdue,
                bgColor: AppColors.statusOverdueBg,
                isSelected: invoice.status == InvoiceStatus.overdue,
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

  Widget _buildHistoryStatusTile({
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

  Future<void> _deleteInvoice(InvoiceModel invoice) async {
    final confirm = await AppDialog.showDelete(
      context: context,
      title: 'Delete Invoice?',
      message: 'Delete ${invoice.invoiceNumber}? This action cannot be undone.',
    );
    if (confirm == true) {
      await DbProvider.delete(DbProvider.tableInvoices, 'id = ?', [invoice.id]);
      await PdfHelper.deletePdf(invoice.invoiceNumber);
      await _loadInvoices();
    }
  }

  Future<Uint8List> _buildInvoicePdf(InvoiceModel invoice) async {
    final isPro = context.read<BillingService>().isPro;
    final profile = await _getBusinessProfile(invoice.currency);
    final prefs = await SharedPreferences.getInstance();
    final savedThemeId = prefs.getString('invoice_theme_${invoice.id}') ??
        prefs.getString('default_pdf_theme');
    final theme = PdfTheme.fromId(savedThemeId);
    return PdfGeneratorService.generateInvoicePdf(
      invoice: invoice,
      businessProfile: profile,
      isPro: isPro,
      theme: theme,
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
    try {
      final pdfBytes = await _buildInvoicePdf(invoice);
      if (mounted) await Printing.layoutPdf(onLayout: (_) async => pdfBytes);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to print: $e')),
        );
      }
    }
  }

  Future<void> _sharePdf(InvoiceModel invoice) async {
    try {
      final pdfBytes = await _buildInvoicePdf(invoice);
      final path = await PdfGeneratorService.saveAndGetPath(
        pdfBytes,
        invoice.invoiceNumber,
      );
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(path)],
          text: 'Invoice ${invoice.invoiceNumber} for ${invoice.clientName}',
        ),
      );
      await AppReviewService.instance.registerSignificantAction();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to share: $e')),
        );
      }
    }
  }

  Future<void> _savePdf(InvoiceModel invoice) async {
    try {
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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
      }
    }
  }

  Future<BusinessProfile> _getBusinessProfile(String currency) async {
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
      currency: currency,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isPro = context.watch<BillingService>().isPro;
    final filtered = _filteredInvoices;

    // Cap list at 5 for free users; pro users see everything
    const int freeLimit = 5;
    final visibleInvoices = (!isPro && filtered.length > freeLimit)
        ? filtered.sublist(0, freeLimit)
        : filtered;
    final isLimited = !isPro && filtered.length > freeLimit;
    final grouped = _groupByMonth(visibleInvoices);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: _isSearching
            ? TextField(
                controller: _searchCtrl,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search client, invoice #, items...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: AppColors.slate400, fontSize: 15),
                ),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                ),
                onChanged: (val) => setState(() => _searchQuery = val.trim()),
              )
            : const Text(
                'History',
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.workspace_premium_rounded,
                        size: 14,
                        color: AppColors.proGold,
                      ),
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
        onRefresh: _loadInvoices,
        color: AppColors.primary,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Filter Chips Bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('All', 'all'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Unpaid', 'unpaid'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Partially Paid', 'partially_paid'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Overdue', 'overdue'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Paid', 'paid'),
                    ],
                  ),
                ),
              ),
            ),

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
                      // Pro upsell card at the end of the list
                      if (isLimited && index == grouped.keys.length) {
                        return _buildProUpsellCard(
                          context,
                          filtered.length - freeLimit,
                        );
                      }

                      final monthKey = grouped.keys.elementAt(index);
                      final invoicesInMonth = grouped[monthKey]!;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Month Header (e.g. "Aug 2026")
                          Padding(
                            padding: const EdgeInsets.only(
                              top: 14,
                              bottom: 8,
                              left: 4,
                            ),
                            child: Text(
                              monthKey,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.slate500,
                              ),
                            ),
                          ),
                          ...invoicesInMonth.asMap().entries.map(
                            (entry) => StaggeredEntrance(
                              index: entry.key,
                              child: _buildInvoiceCard(entry.value),
                            ),
                          ),
                        ],
                      );
                    },
                    childCount: grouped.keys.length + (isLimited ? 1 : 0),
                  ),
                ),
              ),
          ],
        ),
      ),
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
    if (_searchQuery.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.slate100,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.search_off_rounded,
                  size: 36,
                  color: AppColors.slate400,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'No invoices found for "$_searchQuery"',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Try searching with a different keyword or filter',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppColors.slate500),
              ),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _searchQuery = '';
                    _searchCtrl.clear();
                    _isSearching = false;
                  });
                },
                icon: const Icon(Icons.clear_rounded, size: 18),
                label: const Text('Clear Search'),
              ),
            ],
          ),
        ),
      );
    }

    return EmptyStateView(
      icon: Icons.receipt_long_rounded,
      title: 'No Invoices',
      subtitle: _filterStatus == 'all'
          ? 'Create your first invoice to get started'
          : 'No ${_filterStatus.replaceAll('_', ' ')} invoices found',
      isDarkBackground: false,
    );
  }

  Widget _buildProUpsellCard(BuildContext context, int hiddenCount) {
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 8),
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
          onTap: () => _showInvoicePreview(invoice),
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
                      CurrencyFormatter.format(
                        invoice.grandTotal,
                        currencyCode: invoice.currency,
                      ),
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: badgeBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: badgeColor.withValues(alpha: 0.2),
                          ),
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
                            Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 14,
                              color: badgeColor,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                PopupMenuButton<String>(
                  icon: const Icon(
                    Icons.more_vert_rounded,
                    color: AppColors.slate500,
                    size: 20,
                  ),
                  onSelected: (action) {
                    if (action == 'preview') _showInvoicePreview(invoice);
                    if (action == 'share') _sharePdf(invoice);
                    if (action == 'save') _savePdf(invoice);
                    if (action == 'print') _printPdf(invoice);
                    if (action == 'edit') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              CreateInvoiceScreen(existingInvoice: invoice),
                        ),
                      ).then((_) => _loadInvoices());
                    }
                    if (action == 'delete') _deleteInvoice(invoice);
                  },
                  itemBuilder: (_) => [
                    AppPopupMenuItem.item(
                      value: 'preview',
                      title: 'View Details',
                      icon: Icons.visibility_outlined,
                    ),
                    AppPopupMenuItem.item(
                      value: 'edit',
                      title: 'Edit Invoice',
                      icon: Icons.edit_outlined,
                    ),
                    AppPopupMenuItem.item(
                      value: 'share',
                      title: 'Share PDF',
                      icon: Icons.share_outlined,
                    ),
                    AppPopupMenuItem.item(
                      value: 'save',
                      title: 'Save PDF',
                      icon: Icons.download_rounded,
                    ),
                    AppPopupMenuItem.item(
                      value: 'print',
                      title: 'Print',
                      icon: Icons.print_outlined,
                    ),
                    AppPopupMenuItem.divider(),
                    AppPopupMenuItem.item(
                      value: 'delete',
                      title: 'Delete Invoice',
                      icon: Icons.delete_outline_rounded,
                      isDestructive: true,
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
