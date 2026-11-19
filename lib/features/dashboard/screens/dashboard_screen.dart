import 'dart:async';
import 'package:flutter/material.dart';
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
import '../../../shared_widgets/paper.dart';
import '../../../shared_widgets/tab_chrome.dart';
import '../../invoices/models/invoice_model.dart';
import '../../invoices/screens/create_invoice_screen.dart';
import '../../invoices/screens/invoice_preview_screen.dart';
import '../../invoices/services/invoice_actions.dart';
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

  double _totalPaid = 0.0;
  double _totalUnpaid = 0.0;
  Map<String, int> _otherCurrencyCounts = const {};
  String _currency = 'INR';
  bool _hasProfileAlert = false;

  /// The invoice whose stamp should drop in on the next build.
  String? _stampedId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// Public entry-point so the nav shell can trigger a refresh via GlobalKey.
  void reload() => _loadData();

  /// Called by the shell's search bar.
  void setSearch(String query) {
    final q = query.trim();
    if (q == _searchQuery) return;
    setState(() => _searchQuery = q);
  }

  /// Bumped on every load so a slow, older load can't overwrite a newer one.
  int _loadSeq = 0;

  Future<void> _loadData() async {
    if (!mounted) return;
    final seq = ++_loadSeq;
    // Only the first load shows a spinner; later reloads swap in place.
    final currencyProvider = context.read<CurrencyProvider>();
    _currency = currencyProvider.currencyCode;

    // A failed read must not leave the tab on a spinner: fall back to
    // "no profile alert" and an empty list.
    bool hasIncompleteProfile = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      final bizName = prefs.getString('biz_name');
      hasIncompleteProfile = bizName == null || bizName.trim().isEmpty || bizName == 'My Business';
    } catch (e) {
      debugPrint('Could not read the business name: $e');
    }

    // On a failed reload keep what is on screen (an empty list would look
    // like lost data); only the very first load falls back to empty.
    List<InvoiceModel> all = _allInvoices;
    try {
      all = await DbProvider.loadInvoices();
    } catch (e) {
      debugPrint('Could not load invoices: $e');
      if (mounted && !_isLoading) {
        ScaffoldMessenger.of(context).showSnackBar(_snack('Could not refresh invoices. Pull down to try again.'));
      }
    }
    if (seq != _loadSeq) return;

    double paidSum = 0.0;
    double unpaidSum = 0.0;
    final otherCurrencies = <String, int>{};

    for (final inv in all) {
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
        _allInvoices = all;
        _totalPaid = paidSum;
        _totalUnpaid = unpaidSum;
        _otherCurrencyCounts = otherCurrencies;
        _hasProfileAlert = hasIncompleteProfile;
        _isLoading = false;
      });
    }
  }

  bool _matchesFilter(InvoiceModel inv, String filter) => switch (filter) {
    'unpaid' => inv.effectiveStatus == InvoiceStatus.unpaid,
    'partially_paid' => inv.effectiveStatus == InvoiceStatus.partiallyPaid,
    'overdue' => inv.effectiveStatus == InvoiceStatus.overdue,
    'paid' => inv.effectiveStatus == InvoiceStatus.paid,
    _ => true,
  };

  List<InvoiceModel> get _filteredInvoices {
    final q = _searchQuery.toLowerCase();
    return _allInvoices.where((inv) {
      if (q.isNotEmpty &&
          !inv.invoiceNumber.toLowerCase().contains(q) &&
          !inv.clientName.toLowerCase().contains(q)) {
        return false;
      }
      return _matchesFilter(inv, _selectedFilter);
    }).toList();
  }

  /// Overdue invoices first, then ones due in the next three days.
  List<InvoiceModel> get _needsYou {
    final today = DateUtils.dateOnly(DateTime.now());
    final soon = today.add(const Duration(days: 3));
    final list = _allInvoices.where((inv) {
      final s = inv.effectiveStatus;
      if (s == InvoiceStatus.overdue) return true;
      if (s == InvoiceStatus.paid || inv.dueDate == null) return false;
      return !DateUtils.dateOnly(inv.dueDate!).isAfter(soon);
    }).toList()
      // An old row can be stored as overdue with no due date; it goes first.
      ..sort((a, b) {
        final da = a.dueDate, db = b.dueDate;
        if (da == null || db == null) return da == null ? (db == null ? 0 : -1) : 1;
        return da.compareTo(db);
      });
    return list.take(3).toList();
  }

  /// Rows for the list: a month label (String) before each month's invoices.
  List<Object> _rows(List<InvoiceModel> list) {
    final rows = <Object>[];
    String? month;
    for (final inv in list) {
      final key = DateFormat('MMMM yyyy').format(inv.invoiceDate);
      if (key != month) {
        rows.add(key);
        month = key;
      }
      rows.add(inv);
    }
    return rows;
  }

  String _dueLine(InvoiceModel inv) {
    if (inv.dueDate == null) return inv.invoiceNumber;
    final today = DateUtils.dateOnly(DateTime.now());
    final days = DateUtils.dateOnly(inv.dueDate!).difference(today).inDays;
    if (days < 0) return '${-days} ${-days == 1 ? 'day' : 'days'} overdue';
    if (days == 0) return 'Due today';
    if (days == 1) return 'Due tomorrow';
    return 'Due in $days days';
  }

  Future<void> _openInvoicePreview(InvoiceModel invoice) async {
    Haptics.tap();
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => InvoicePreviewScreen(invoice: invoice)),
    );
    if (mounted) await _loadData();
  }

  Future<void> _openSettings() async {
    Haptics.tap();
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
    if (mounted) _loadData();
  }

  SnackBar _snack(String text, {SnackBarAction? action}) => SnackBar(
    behavior: SnackBarBehavior.floating,
    content: Text(text),
    action: action,
    // With an action a snackbar stays up by default; let it time out.
    persist: false,
    duration: const Duration(seconds: 4),
  );

  /// Records the balance as paid, drops the PAID stamp, and offers Undo.
  Future<void> _markPaid(InvoiceModel invoice) async {
    final messenger = ScaffoldMessenger.of(context);
    String? paymentId;
    try {
      paymentId = await DbProvider.markPaidInFull(invoice.id);
    } catch (e) {
      debugPrint('Mark paid failed: $e');
      messenger.showSnackBar(_snack('Could not update the payment. Please try again.'));
      return;
    }
    if (!mounted) return;
    if (paymentId == null) {
      messenger.showSnackBar(_snack('Nothing is left to pay on ${invoice.invoiceNumber}.'));
      return;
    }
    setState(() => _stampedId = invoice.id);
    // The stamp drops once; clear it so scrolling back doesn't replay it.
    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted && _stampedId == invoice.id) setState(() => _stampedId = null);
    });
    // The thud lands as the stamp hits the page.
    Future.delayed(const Duration(milliseconds: 250), Haptics.stamp);
    await _loadData();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        _snack(
          '${invoice.invoiceNumber} marked paid',
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () async {
              try {
                await DbProvider.deletePayment(paymentId!);
              } catch (e) {
                debugPrint('Undo failed: $e');
                messenger.showSnackBar(_snack('Could not undo. Remove the payment from the invoice instead.'));
                return;
              }
              if (!mounted) return;
              setState(() => _stampedId = null);
              _loadData();
            },
          ),
        ),
      );
  }

  /// Changes the payment state through payments (see InvoiceActions).
  Future<void> _quickUpdateStatus(InvoiceModel invoice, InvoiceStatus status) async {
    if (status == InvoiceStatus.paid) return _markPaid(invoice);
    final changed = await InvoiceActions.changePaymentStatus(context, invoice, status);
    if (changed) await _loadData();
  }

  void _showQuickStatusPicker(InvoiceModel invoice) {
    Haptics.tap();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SheetHandle(),
              const SizedBox(height: 16),
              Text('Payment', style: AppTypography.serif(fontSize: 22, color: AppColors.ink)),
              const SizedBox(height: 2),
              Text(
                '${invoice.invoiceNumber} · ${invoice.clientName}',
                style: GoogleFonts.inter(fontSize: 13, color: AppColors.muted),
              ),
              const SizedBox(height: 16),
              if (invoice.effectiveStatus != InvoiceStatus.paid) ...[
                _statusOption(
                  title: 'Paid in Full',
                  subtitle: 'Records the balance as received today',
                  stamp: StampMark(label: 'PAID', color: AppColors.statusPaid),
                  onTap: () {
                    Navigator.pop(ctx);
                    _quickUpdateStatus(invoice, InvoiceStatus.paid);
                  },
                ),
                const SizedBox(height: 8),
                _statusOption(
                  title: 'Record a payment',
                  subtitle: 'Add a deposit or part payment',
                  stamp: StampMark(label: 'PART', color: AppColors.statusPartiallyPaid),
                  onTap: () {
                    Navigator.pop(ctx);
                    _quickUpdateStatus(invoice, InvoiceStatus.partiallyPaid);
                  },
                ),
              ],
              if (invoice.paidAmount > 0.005) ...[
                const SizedBox(height: 8),
                _statusOption(
                  title: 'Unpaid',
                  subtitle: 'Deletes recorded payments',
                  stamp: StampMark(label: 'DUE', color: AppColors.muted),
                  onTap: () {
                    Navigator.pop(ctx);
                    _quickUpdateStatus(invoice, InvoiceStatus.unpaid);
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusOption({
    required String title,
    required String subtitle,
    required Widget stamp,
    required VoidCallback onTap,
  }) {
    return PaperSlip(
      onTap: onTap,
      child: Row(
        children: [
          SizedBox(width: 64, child: Center(child: stamp)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.inter(fontSize: 14.5, fontWeight: FontWeight.w600, color: AppColors.ink)),
                const SizedBox(height: 2),
                Text(subtitle, style: GoogleFonts.inter(fontSize: 12, color: AppColors.muted)),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: AppColors.mutedSoft, size: 20),
        ],
      ),
    );
  }

  /// Everything you can do to one invoice, on a long press.
  void _showActions(InvoiceModel invoice) {
    Haptics.confirm();
    Widget action(IconData icon, String label, VoidCallback onTap, {bool destructive = false}) {
      final color = destructive ? AppColors.error : AppColors.ink;
      return ListTile(
        leading: Icon(icon, color: color, size: 20),
        title: Text(label, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w500, color: color)),
        onTap: onTap,
        dense: true,
        visualDensity: VisualDensity.compact,
      );
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) {
        void run(VoidCallback f) {
          Navigator.pop(ctx);
          f();
        }

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 14, 8, 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(child: _SheetHandle()),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(invoice.clientName, style: AppTypography.serif(fontSize: 20, color: AppColors.ink)),
                ),
                action(Icons.visibility_outlined, 'View details', () => run(() => _openInvoicePreview(invoice))),
                action(Icons.edit_outlined, 'Edit invoice', () => run(() {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => CreateInvoiceScreen(existingInvoice: invoice)),
                  ).then((_) => _loadData());
                })),
                action(Icons.payments_outlined, 'Payment status', () => run(() => _showQuickStatusPicker(invoice))),
                action(Icons.ios_share_rounded, 'Share PDF', () => run(() => _sharePdf(invoice))),
                action(Icons.download_rounded, 'Save PDF', () => run(() => InvoiceActions.saveToDevice(context, invoice))),
                action(Icons.print_outlined, 'Print', () => run(() => InvoiceActions.printPdf(context, invoice))),
                Divider(color: AppColors.hairline, height: 12),
                action(Icons.delete_outline_rounded, 'Delete invoice', () => run(() => _deleteInvoice(invoice)),
                    destructive: true),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _sharePdf(InvoiceModel invoice) async {
    final updated = await InvoiceActions.share(context, invoice);
    if (updated != null) await _loadData();
  }

  Future<void> _deleteInvoice(InvoiceModel invoice) async {
    if (await InvoiceActions.confirmAndDelete(context, invoice)) await _loadData();
  }

  Future<void> _createInvoice() async {
    if (!await CreateInvoiceScreen.canCreateNewInvoice(context)) return;
    if (!mounted) return;
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateInvoiceScreen()));
    if (mounted) _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final isPro = context.watch<BillingService>().isPro;
    final currencyProvider = context.watch<CurrencyProvider>();
    final currencyCode = currencyProvider.currencyCode;
    final currencySymbol = currencyProvider.currencySymbol;
    final filtered = _filteredInvoices;
    final rows = _rows(filtered);
    final needsYou = (_selectedFilter == 'all' && _searchQuery.isEmpty) ? _needsYou : const <InvoiceModel>[];
    String money(double v) => CurrencyFormatter.format(v, currencyCode: currencyCode, currencySymbol: currencySymbol);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _loadData,
          color: AppColors.primary,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _buildHeader(isPro)),
              if (_allInvoices.isNotEmpty || !_isLoading)
                SliverToBoxAdapter(child: _buildHero(money, currencyCode)),
              if (needsYou.isNotEmpty) SliverToBoxAdapter(child: _buildNeedsYou(needsYou)),
              if (_allInvoices.isNotEmpty)
                SliverPersistentHeader(
                  pinned: true,
                  delegate: PinnedBarDelegate(child: _buildFilters()),
                ),
              if (_isLoading)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                )
              else if (filtered.isEmpty)
                SliverFillRemaining(hasScrollBody: false, child: _buildEmptyState())
              else ...[
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                  sliver: SliverList.builder(
                    itemCount: rows.length,
                    itemBuilder: (context, i) {
                      final row = rows[i];
                      if (row is String) return ListSectionLabel(row);
                      return _buildInvoiceRow(row as InvoiceModel);
                    },
                  ),
                ),
                const SliverToBoxAdapter(child: ListFootnote('Swipe right to mark paid · hold for more')),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isPro) {
    return TabHeader(
      title: 'Invoices',
      caption: DateFormat('EEEE, d MMMM').format(DateTime.now()),
      showPro: !isPro,
      trailing: [
        const SizedBox(width: 2),
        _CircleButton(
          tooltip: _hasProfileAlert ? 'Profile incomplete' : 'Settings',
          onTap: _openSettings,
          dot: _hasProfileAlert,
          child: Icon(Icons.settings_outlined, color: AppColors.ink, size: 21),
        ),
      ],
    );
  }

  Widget _buildHero(String Function(double) money, String currencyCode) {
    final total = _totalPaid + _totalUnpaid;
    final collected = total <= 0 ? 0.0 : (_totalPaid / total).clamp(0.0, 1.0);
    final label = TabHeader.captionStyle.copyWith(color: AppColors.muted);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('TO COLLECT', style: label),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: _totalUnpaid),
              duration: const Duration(milliseconds: 450),
              curve: Curves.easeOutCubic,
              builder: (context, v, _) => Text(
                money(v),
                style: AppTypography.money(fontSize: 44, color: AppColors.ink, letterSpacing: -1.4),
              ),
            ),
          ),
          const SizedBox(height: 14),
          // How much of everything billed has come in.
          ClipRRect(
            borderRadius: BorderRadius.circular(9999),
            child: SizedBox(
              height: 4,
              width: double.infinity,
              child: Stack(
                children: [
                  Positioned.fill(child: ColoredBox(color: AppColors.hairline)),
                  AnimatedFractionallySizedBox(
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOutCubic,
                    widthFactor: collected,
                    heightFactor: 1,
                    alignment: Alignment.centerLeft,
                    child: ColoredBox(color: AppColors.statusPaid),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text('Collected ', style: GoogleFonts.inter(fontSize: 13, color: AppColors.muted)),
              Flexible(
                child: Text(
                  money(_totalPaid),
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.statusPaid),
                ),
              ),
              const Spacer(),
              Text(
                '${_allInvoices.length} ${_allInvoices.length == 1 ? 'invoice' : 'invoices'}',
                style: GoogleFonts.inter(fontSize: 13, color: AppColors.muted),
              ),
            ],
          ),
          if (_otherCurrencyCounts.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Totals are for $currencyCode invoices only. Not included: '
              '${_otherCurrencyCounts.entries.map((e) => '${e.value} in ${e.key}').join(', ')}.',
              style: GoogleFonts.inter(fontSize: 11.5, color: AppColors.mutedSoft),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNeedsYou(List<InvoiceModel> list) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text('Needs you', style: AppTypography.serif(fontSize: 19, color: AppColors.ink)),
          ),
          for (final inv in list) ...[
            PaperSlip(
              onTap: () => _openInvoicePreview(inv),
              onLongPress: () => _showActions(inv),
              padding: const EdgeInsets.fromLTRB(16, 12, 10, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          inv.clientName.isEmpty ? inv.invoiceNumber : inv.clientName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(fontSize: 14.5, fontWeight: FontWeight.w600, color: AppColors.ink),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${_dueLine(inv)} · ${CurrencyFormatter.format(inv.balanceDue, currencyCode: inv.currency.isNotEmpty ? inv.currency : _currency)}',
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: inv.effectiveStatus == InvoiceStatus.overdue ? AppColors.statusOverdue : AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () => _markPaid(inv),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.statusPaid,
                      backgroundColor: AppColors.statusPaidBg,
                      minimumSize: const Size(0, 36),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9999)),
                      textStyle: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600),
                    ),
                    child: const Text('Mark paid'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  Widget _buildFilters() {
    int count(String key) => _allInvoices.where((i) => _matchesFilter(i, key)).length;
    Widget pill(String key, String label, {bool counted = true}) => FilterPill(
      label: label,
      selected: _selectedFilter == key,
      count: counted ? count(key) : null,
      onTap: () => setState(() => _selectedFilter = key),
    );
    return FilterRow(
      children: [
        pill('all', 'All', counted: false),
        pill('unpaid', 'Unpaid'),
        pill('overdue', 'Overdue'),
        pill('partially_paid', 'Partially Paid'),
        pill('paid', 'Paid'),
      ],
    );
  }

  Widget _buildEmptyState() {
    if (_allInvoices.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(32, 24, 32, 120),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Nothing here', style: AppTypography.serif(fontSize: 22, color: AppColors.ink)),
            const SizedBox(height: 6),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No invoices match "$_searchQuery"'
                  : 'No ${const {'unpaid': 'unpaid', 'partially_paid': 'part-paid', 'overdue': 'overdue', 'paid': 'paid'}[_selectedFilter] ?? ''} invoices',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 13.5, color: AppColors.muted),
            ),
            if (_selectedFilter != 'all') ...[
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () {
                  Haptics.tap();
                  setState(() => _selectedFilter = 'all');
                },
                child: const Text('Show all'),
              ),
            ],
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 8, 32, 120),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // A blank slip, waiting for its first invoice.
          Transform.rotate(
            angle: -0.04,
            child: Container(
              width: 150,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
              decoration: BoxDecoration(
                color: AppColors.canvas,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.hairline),
                boxShadow: [
                  BoxShadow(color: const Color.fromRGBO(60, 45, 20, 0.08), blurRadius: 18, offset: const Offset(0, 8)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final w in [0.55, 0.9, 0.75, 0.4]) ...[
                    FractionallySizedBox(
                      widthFactor: w,
                      child: Container(height: 6, decoration: BoxDecoration(color: AppColors.surfaceCard, borderRadius: BorderRadius.circular(3))),
                    ),
                    const SizedBox(height: 9),
                  ],
                  Align(
                    alignment: Alignment.centerRight,
                    child: StampMark(label: 'NEW', color: AppColors.brandAccent, fontSize: 11),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),
          Text('Your first invoice', style: AppTypography.serif(fontSize: 24, color: AppColors.ink)),
          const SizedBox(height: 6),
          Text(
            'Make one in under a minute. Tap + below any time.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 14, color: AppColors.muted, height: 1.4),
          ),
          const SizedBox(height: 22),
          ElevatedButton(
            onPressed: _createInvoice,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
              elevation: 0,
              minimumSize: const Size(0, 48),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9999)),
            ),
            child: const Text('Create Invoice'),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceRow(InvoiceModel invoice) {
    final status = invoice.effectiveStatus;
    final isPaid = status == InvoiceStatus.paid;
    final amount = CurrencyFormatter.format(
      invoice.grandTotal,
      currencyCode: invoice.currency.isNotEmpty ? invoice.currency : _currency,
    );
    final meta = isPaid || invoice.dueDate == null
        ? '${invoice.invoiceNumber} · ${DateFormat('d MMM').format(invoice.invoiceDate)}'
        : '${invoice.invoiceNumber} · ${_dueLine(invoice)}';

    final slip = PaperSlip(
      onTap: () => _openInvoicePreview(invoice),
      onLongPress: () => _showActions(invoice),
      dimmed: isPaid,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  invoice.clientName.isEmpty ? 'No client' : invoice.clientName,
                  style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.ink),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  meta,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    color: status == InvoiceStatus.overdue ? AppColors.statusOverdue : AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(amount, style: AppTypography.money(fontSize: 17, color: AppColors.ink, letterSpacing: -0.3)),
              const SizedBox(height: 6),
              Semantics(
                button: true,
                hint: 'Change payment status',
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _showQuickStatusPicker(invoice),
                  child: Padding(
                    padding: const EdgeInsets.only(left: 12, top: 2),
                    child: StampMark.forStatus(
                      status,
                      fontSize: 9.5,
                      animate: _stampedId == invoice.id && isPaid,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Dismissible(
        key: ValueKey('inv-${invoice.id}'),
        direction: isPaid ? DismissDirection.endToStart : DismissDirection.horizontal,
        dismissThresholds: const {DismissDirection.startToEnd: 0.3, DismissDirection.endToStart: 0.3},
        // The row never leaves; the swipe is a gesture, not a delete.
        confirmDismiss: (direction) async {
          if (direction == DismissDirection.startToEnd) {
            _markPaid(invoice);
          } else {
            Haptics.tap();
            _sharePdf(invoice);
          }
          return false;
        },
        background: _swipeBackground(
          alignLeft: true,
          color: AppColors.statusPaidBg,
          fg: AppColors.statusPaid,
          icon: Icons.task_alt_rounded,
          label: 'Mark paid',
        ),
        secondaryBackground: _swipeBackground(
          alignLeft: false,
          color: AppColors.surfaceCard,
          fg: AppColors.ink,
          icon: Icons.ios_share_rounded,
          label: 'Share',
        ),
        child: slip,
      ),
    );
  }

  Widget _swipeBackground({
    required bool alignLeft,
    required Color color,
    required Color fg,
    required IconData icon,
    required String label,
  }) {
    final children = [
      Icon(icon, color: fg, size: 20),
      const SizedBox(width: 8),
      Text(label, style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w600, color: fg)),
    ];
    return Container(
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      alignment: alignLeft ? Alignment.centerLeft : Alignment.centerRight,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: alignLeft ? children : children.reversed.toList(),
      ),
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 36,
        height: 4,
        decoration: BoxDecoration(color: AppColors.hairline, borderRadius: BorderRadius.circular(2)),
      ),
    );
  }
}

/// A 44dp round button on paper, with an optional attention dot.
class _CircleButton extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;
  final String tooltip;
  final bool dot;

  const _CircleButton({required this.child, required this.onTap, required this.tooltip, this.dot = false});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: PressScale(
        pressedScale: 0.92,
        child: Material(
          color: AppColors.canvas,
          shape: CircleBorder(side: BorderSide(color: AppColors.hairline)),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: SizedBox(
              width: 44,
              height: 44,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  child,
                  if (dot)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppColors.warning,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.canvas, width: 1.5),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
