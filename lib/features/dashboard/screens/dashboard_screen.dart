import 'dart:async';
import '../../invoices/services/invoice_actions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/billing/billing_service.dart';
import '../../../core/database/db_provider.dart';
import '../../../core/providers/currency_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../invoices/models/invoice_model.dart';
import '../../invoices/screens/create_invoice_screen.dart';
import '../../invoices/screens/invoice_preview_screen.dart';
import '../../paywall/paywall_screen.dart';
import '../../settings/screens/settings_screen.dart';
import '../../../shared_widgets/app_popup_menu.dart';

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
  Map<String, int> _otherCurrencyCounts = const {};
  String _currency = 'INR';
  bool _hasProfileAlert = false;

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

    final prefs = await SharedPreferences.getInstance();
    final bizName = prefs.getString('biz_name');
    final hasIncompleteProfile = bizName == null || bizName.trim().isEmpty || bizName == 'My Business';

    final all = await DbProvider.loadInvoices();

    final List<InvoiceModel> loaded = [];
    double paidSum = 0.0;
    double unpaidSum = 0.0;
    final otherCurrencies = <String, int>{};

    for (final inv in all) {
      loaded.add(inv);

      // Amounts in different currencies can't be added up: the summary
      // counts the home currency and notes the rest.
      if (inv.currency.toUpperCase() != _currency.toUpperCase()) {
        otherCurrencies[inv.currency] = (otherCurrencies[inv.currency] ?? 0) + 1;
        continue;
      }
      if (inv.status == InvoiceStatus.paid) {
        paidSum += inv.grandTotal;
      } else {
        paidSum += inv.paidAmount;
        unpaidSum += inv.balanceDue;
      }
    }

    if (mounted) {
      setState(() {
        _allInvoices = loaded;
        _totalPaid = paidSum;
        _totalUnpaid = unpaidSum;
        _otherCurrencyCounts = otherCurrencies;
        _hasProfileAlert = hasIncompleteProfile;
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
      if (_selectedFilter == 'unpaid') return inv.effectiveStatus == InvoiceStatus.unpaid;
      if (_selectedFilter == 'partially_paid') return inv.effectiveStatus == InvoiceStatus.partiallyPaid;
      if (_selectedFilter == 'overdue') return inv.effectiveStatus == InvoiceStatus.overdue;
      if (_selectedFilter == 'paid') return inv.effectiveStatus == InvoiceStatus.paid;
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

  Color _getAvatarColor(String name) {
    final colors = [
      AppColors.badgeOrange,
      AppColors.badgePink,
      AppColors.badgeViolet,
      AppColors.badgeEmerald,
      AppColors.badgeBlue,
    ];
    if (name.isEmpty) return colors[0];
    final hash = name.codeUnits.fold(0, (prev, elem) => prev + elem);
    return colors[hash % colors.length];
  }

  String _getInitials(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return trimmed.substring(0, trimmed.length >= 2 ? 2 : 1).toUpperCase();
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

  /// Changes the payment state through payments (see InvoiceActions).
  Future<void> _quickUpdateStatus(InvoiceModel invoice, InvoiceStatus status) async {
    final changed = await InvoiceActions.changePaymentStatus(context, invoice, status);
    if (!changed) return;
    if (status == InvoiceStatus.paid) {
      HapticFeedback.mediumImpact();
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.ink,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            content: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: AppColors.statusPaid, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Invoice ${invoice.invoiceNumber} marked as Paid in Full',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppColors.canvas),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }
    await _loadData();
  }

  void _showQuickStatusPicker(InvoiceModel invoice) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.hairline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Update Status',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ink,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Invoice ${invoice.invoiceNumber}',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: AppColors.muted, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildStatusOptionTile(
                ctx: ctx,
                title: 'Unpaid',
                subtitle: 'Deletes recorded payments',
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
              _buildStatusOptionTile(
                ctx: ctx,
                title: 'Record a payment',
                subtitle: 'Add a deposit or part payment',
                icon: Icons.pie_chart_outline_rounded,
                iconColor: AppColors.statusPartiallyPaid,
                bgColor: AppColors.statusPartiallyPaidBg,
                isSelected: invoice.status == InvoiceStatus.partiallyPaid,
                onTap: () {
                  Navigator.pop(ctx);
                  _quickUpdateStatus(invoice, InvoiceStatus.partiallyPaid);
                },
              ),
              const SizedBox(height: 8),
              _buildStatusOptionTile(
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusOptionTile({
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
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.surfaceCard : AppColors.canvas,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.ink : AppColors.hairline,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle_rounded, color: AppColors.ink, size: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _sharePdf(InvoiceModel invoice) async {
    final updated = await InvoiceActions.share(context, invoice);
    if (updated != null) await _loadData();
  }

  Future<void> _deleteInvoice(InvoiceModel invoice) async {
    if (await InvoiceActions.confirmAndDelete(context, invoice)) await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final isPro = context.watch<BillingService>().isPro;
    final currencyProvider = context.watch<CurrencyProvider>();
    final currencyCode = currencyProvider.currencyCode;
    final currencySymbol = currencyProvider.currencySymbol;
    final filtered = _filteredInvoices;
    final grouped = _groupByMonth(filtered);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: AppColors.hairline),
        ),
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(Icons.settings_outlined, color: AppColors.ink, size: 22),
                if (_hasProfileAlert)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppColors.warning,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            tooltip: _hasProfileAlert ? 'Profile incomplete' : 'Settings',
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
                decoration: InputDecoration(
                  hintText: 'Search client or invoice #...',
                  border: InputBorder.none,
                  hintStyle: GoogleFonts.inter(color: AppColors.mutedSoft, fontSize: 15),
                ),
                style: GoogleFonts.inter(color: AppColors.ink, fontSize: 15, fontWeight: FontWeight.w500),
                onChanged: (val) => setState(() => _searchQuery = val.trim()),
              )
            : Text(
                'Invoices',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                  letterSpacing: -0.5,
                ),
              ),
        actions: [
          IconButton(
            icon: Icon(
              _isSearching ? Icons.close_rounded : Icons.search_rounded,
              color: AppColors.ink,
              size: 20,
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
                    color: AppColors.surfaceDark,
                    borderRadius: BorderRadius.circular(9999), // pill
                    border: Border.all(color: AppColors.proBadgeBorder),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star_rounded, size: 13, color: Color(0xFFFBBF24)),
                      const SizedBox(width: 4),
                      Text(
                        'PRO',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
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
                    // Cal.com Signature Hero Dark Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF161616), Color(0xFF0C0C0C)],
                        ),
                        borderRadius: BorderRadius.circular(16), // rounded.xl
                        border: Border.all(color: const Color(0xFF2A2A2A), width: 1),
                        boxShadow: const [
                          BoxShadow(
                            color: Color.fromRGBO(0, 0, 0, 0.18),
                            blurRadius: 24,
                            offset: Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 7,
                                    height: 7,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF10B981),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Total Paid',
                                    style: GoogleFonts.inter(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF999999),
                                      letterSpacing: 0.6,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF222222),
                                  borderRadius: BorderRadius.circular(9999),
                                  border: Border.all(color: const Color(0xFF333333)),
                                ),
                                child: Text(
                                  currencyCode,
                                  style: AppTypography.monoCode(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFFCCCCCC),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            CurrencyFormatter.format(
                              _totalPaid,
                              currencyCode: currencyCode,
                              currencySymbol: currencySymbol,
                            ),
                            style: AppTypography.money(
                              fontSize: 32,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              letterSpacing: -1.2,
                            ),
                          ),
                          if (_otherCurrencyCounts.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Totals are for $currencyCode invoices only. Not included: '
                              '${_otherCurrencyCounts.entries.map((e) => '${e.value} in ${e.key}').join(', ')}.',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: const Color(0xFF888888),
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),
                          const Divider(height: 1, color: Color(0xFF242424)),
                          const SizedBox(height: 14),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Total Unpaid',
                                    style: GoogleFonts.inter(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w400,
                                      color: const Color(0xFF888888),
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    CurrencyFormatter.format(
                                      _totalUnpaid,
                                      currencyCode: currencyCode,
                                      currencySymbol: currencySymbol,
                                    ),
                                    style: AppTypography.money(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFFF3F4F6),
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'Total Documents',
                                    style: GoogleFonts.inter(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w400,
                                      color: const Color(0xFF888888),
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    '${_allInvoices.length} invoices',
                                    style: AppTypography.money(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFFF3F4F6),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Cal.com Nav-Pill-Group Filter Row
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.canvas,
                          borderRadius: BorderRadius.circular(9999), // pill container
                          border: Border.all(color: AppColors.hairline),
                        ),
                        child: Row(
                          children: [
                            _buildFilterChip('all', 'All'),
                            _buildFilterChip('unpaid', 'Unpaid'),
                            _buildFilterChip('partially_paid', 'Partially Paid'),
                            _buildFilterChip('overdue', 'Overdue'),
                            _buildFilterChip('paid', 'Paid'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Invoices List or Clean SaaS Empty State
            if (_isLoading)
              SliverFillRemaining(
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
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final monthKey = grouped.keys.elementAt(index);
                      final invoicesInMonth = grouped[monthKey]!;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Month Header (e.g. "Aug 2026")
                          Padding(
                            padding: const EdgeInsets.only(top: 14, bottom: 8, left: 4),
                            child: Text(
                              monthKey,
                              style: GoogleFonts.inter(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.muted,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                          ...invoicesInMonth.map(_buildInvoiceCard),
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(9999), // pill
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12.5,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? AppColors.onPrimary : AppColors.body,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final hasExistingInvoices = _allInvoices.isNotEmpty;

    if (hasExistingInvoices) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.hairline),
              ),
              child: Icon(
                Icons.search_off_rounded,
                size: 28,
                color: AppColors.muted,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No matching invoices',
              style: GoogleFonts.inter(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No invoices match "$_searchQuery"'
                  : 'No ${const {'unpaid': 'unpaid', 'partially_paid': 'part-paid', 'overdue': 'overdue', 'paid': 'paid'}[_selectedFilter] ?? ''} invoices',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 13, color: AppColors.muted),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: () {
                HapticFeedback.lightImpact();
                setState(() {
                  _selectedFilter = 'all';
                  _searchQuery = '';
                  _isSearching = false;
                  _searchCtrl.clear();
                });
              },
              icon: const Icon(Icons.filter_alt_off_rounded, size: 16),
              label: const Text('Reset Filters'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.ink,
                side: BorderSide(color: AppColors.hairline),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(16), // rounded.xl
              border: Border.all(color: AppColors.hairline),
            ),
            child: Center(
              child: Icon(
                Icons.receipt_long_rounded,
                size: 32,
                color: AppColors.ink,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No invoices yet',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Create your first professional invoice in seconds',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13.5,
              color: AppColors.muted,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () async {
              if (await CreateInvoiceScreen.canCreateNewInvoice(context)) {
                if (!mounted) return;
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CreateInvoiceScreen()),
                );
                if (mounted) _loadData();
              }
            },
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Create Invoice'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceCard(InvoiceModel invoice) {
    final dateFormatted = DateFormat('dd MMM yyyy').format(invoice.invoiceDate);

    Color badgeColor;
    Color badgeBg;
    String badgeText;

    switch (invoice.effectiveStatus) {
      case InvoiceStatus.paid:
        badgeColor = AppColors.statusPaid;
        badgeBg = AppColors.statusPaidBg;
        badgeText = 'Paid';
        break;
      case InvoiceStatus.partiallyPaid:
        badgeColor = AppColors.statusPartiallyPaid;
        badgeBg = AppColors.statusPartiallyPaidBg;
        badgeText = 'Partial';
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

    final avatarColor = _getAvatarColor(invoice.clientName);
    final initials = _getInitials(invoice.clientName);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.canvas,
        borderRadius: BorderRadius.circular(12), // rounded.lg
        border: Border.all(color: AppColors.hairline),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _openInvoicePreview(invoice),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                // Circular Pastel Avatar with Initials
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: avatarColor,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      initials,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Left: Client Name & Invoice Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        invoice.clientName,
                        style: GoogleFonts.inter(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ink,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${invoice.invoiceNumber} • $dateFormatted',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.muted,
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
                        currencyCode: invoice.currency.isNotEmpty
                            ? invoice.currency
                            : _currency,
                      ),
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: () => _showQuickStatusPicker(invoice),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: badgeBg,
                          borderRadius: BorderRadius.circular(9999), // pill
                          border: Border.all(color: badgeColor.withValues(alpha: 0.18)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              badgeText,
                              style: GoogleFonts.inter(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                color: badgeColor,
                              ),
                            ),
                            const SizedBox(width: 2),
                            Icon(Icons.keyboard_arrow_down_rounded, size: 13, color: badgeColor),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(width: 4),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert_rounded, color: AppColors.muted, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onSelected: (action) {
                    if (action == 'preview') _openInvoicePreview(invoice);
                    if (action == 'share') _sharePdf(invoice);
                    if (action == 'save') InvoiceActions.saveToDevice(context, invoice);
                    if (action == 'print') InvoiceActions.printPdf(context, invoice);
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

