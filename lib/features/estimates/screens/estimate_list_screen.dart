import 'package:flutter/material.dart';
import '../services/estimate_actions.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/billing/billing_service.dart';
import '../../../core/database/db_provider.dart';
import '../../../core/providers/currency_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared_widgets/empty_state_view.dart';
import '../../invoices/models/line_item_model.dart';
import '../../invoices/screens/invoice_preview_screen.dart';
import '../../invoices/services/pdf_generator_service.dart';
import '../models/estimate_model.dart';
import 'create_estimate_screen.dart';
import 'estimate_preview_screen.dart';
import '../../../shared_widgets/paper.dart';
import '../../../shared_widgets/tab_chrome.dart';
import '../../../core/theme/app_icons.dart';

class EstimateListScreen extends StatefulWidget {
  const EstimateListScreen({super.key});

  @override
  State<EstimateListScreen> createState() => EstimateListScreenState();
}

class EstimateListScreenState extends State<EstimateListScreen> {
  List<EstimateModel> _allEstimates = [];
  bool _isLoading = true;
  String _selectedFilter = 'all'; // 'all', 'pending', 'accepted', 'declined', 'converted'
  String _searchQuery = '';

  double _totalEstimated = 0.0;
  double _totalAccepted = 0.0;
  double _totalPending = 0.0;
  String _currency = 'INR';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// Public entry-point so the navigation shell can trigger a refresh via GlobalKey.
  void reload() => _loadData();

  /// Called by the shell's search bar.
  void setSearch(String query) {
    final q = query.trim();
    if (q == _searchQuery) return;
    setState(() => _searchQuery = q);
  }

  // Only the first load shows a spinner; reloads swap the list in place.
  Future<void> _loadData() async {
    final currencyProvider = context.read<CurrencyProvider>();
    _currency = currencyProvider.currencyCode;

    final rows = await DbProvider.query(
      DbProvider.tableEstimates,
      orderBy: 'estimate_date DESC',
    );

    final List<EstimateModel> loaded = [];
    double estimatedSum = 0.0;
    double acceptedSum = 0.0;
    double pendingSum = 0.0;

    for (final row in rows) {
      final EstimateModel est;
      try {
        final estimateId = row['id'] as String;
        final itemRows = await DbProvider.query(
          DbProvider.tableEstimateLineItems,
          where: 'estimate_id = ?',
          whereArgs: [estimateId],
          orderBy: 'sort_order ASC',
        );
        final items = itemRows.map(LineItemModel.fromMap).toList();
        est = EstimateModel.fromMap(row, items: items);
      } catch (e) {
        // One unreadable row must not leave the whole tab on a spinner.
        debugPrint('Skipping unreadable estimate ${row['id']}: $e');
        continue;
      }
      loaded.add(est);

      estimatedSum += est.grandTotal;
      if (est.status == EstimateStatus.accepted || est.status == EstimateStatus.converted) {
        acceptedSum += est.grandTotal;
      } else if (est.status == EstimateStatus.pending) {
        pendingSum += est.grandTotal;
      }
    }

    if (mounted) {
      setState(() {
        _allEstimates = loaded;
        _totalEstimated = estimatedSum;
        _totalAccepted = acceptedSum;
        _totalPending = pendingSum;
        _isLoading = false;
      });
    }
  }

  List<EstimateModel> get _filteredEstimates {
    return _allEstimates.where((est) {
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchesNum = est.estimateNumber.toLowerCase().contains(q);
        final matchesClient = est.clientName.toLowerCase().contains(q);
        if (!matchesNum && !matchesClient) return false;
      }

      // Status chip filter
      if (_selectedFilter == 'all') return true;
      if (_selectedFilter == 'pending') return est.status == EstimateStatus.pending;
      if (_selectedFilter == 'accepted') return est.status == EstimateStatus.accepted;
      if (_selectedFilter == 'declined') return est.status == EstimateStatus.declined;
      if (_selectedFilter == 'converted') return est.status == EstimateStatus.converted;
      return true;
    }).toList();
  }

  Future<void> _openEstimatePreview(EstimateModel estimate) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EstimatePreviewScreen(estimate: estimate),
      ),
    );
    if (mounted) {
      await _loadData();
    }
  }

  Future<void> _createNewEstimate() async {
    HapticFeedback.mediumImpact();
    if (await CreateEstimateScreen.canCreateNewEstimate(context)) {
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CreateEstimateScreen()),
      );
      if (mounted) {
        await _loadData();
      }
    }
  }

  Future<void> _quickUpdateStatus(EstimateModel estimate, EstimateStatus status) async {
    if (EstimateActions.isLocked(estimate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A converted estimate keeps its status. Delete its invoice to change it.')),
      );
      return;
    }
    await DbProvider.update(
      DbProvider.tableEstimates,
      {
        'status': status.value,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      'id = ?',
      [estimate.id],
    );
    await _loadData();
  }

  Future<void> _convertToInvoice(EstimateModel estimate) async {
    final invoice = await EstimateActions.convert(context, estimate);
    await _loadData();
    if (invoice == null || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Converted to Invoice ${invoice.invoiceNumber}'),
        persist: false,
        action: SnackBarAction(
          label: 'VIEW',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => InvoicePreviewScreen(invoice: invoice),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _sharePdf(EstimateModel estimate) async {
    try {
      final pdfBytes = await EstimateActions.render(
        estimate,
        isPro: context.read<BillingService>().isPro,
      );
      final path = await PdfGeneratorService.saveAndGetPath(
        pdfBytes,
        estimate.estimateNumber,
      );
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(path)],
          text: 'Estimate ${estimate.estimateNumber} for ${estimate.clientName}',
        ),
      );
    } catch (e) {
      debugPrint('Share estimate failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not share the estimate. Please try again.')),
        );
      }
    }
  }

  Future<void> _deleteEstimate(EstimateModel estimate) async {
    if (await EstimateActions.confirmAndDelete(context, estimate)) await _loadData();
  }

  bool _matches(EstimateModel est, String filter) => switch (filter) {
    'pending' => est.status == EstimateStatus.pending,
    'accepted' => est.status == EstimateStatus.accepted,
    'declined' => est.status == EstimateStatus.declined,
    'converted' => est.status == EstimateStatus.converted,
    _ => true,
  };

  @override
  Widget build(BuildContext context) {
    final currencyProvider = context.watch<CurrencyProvider>();
    final currencyCode = currencyProvider.currencyCode;
    final currencySymbol = currencyProvider.currencySymbol;
    final isPro = context.watch<BillingService>().isPro;
    final filtered = _filteredEstimates;
    String money(double v) =>
        CurrencyFormatter.formatCompact(v, currencyCode: currencyCode, currencySymbol: currencySymbol);

    Widget pill(String key, String label, {bool counted = true}) => FilterPill(
      label: label,
      selected: _selectedFilter == key,
      count: counted ? _allEstimates.where((e) => _matches(e, key)).length : null,
      onTap: () => setState(() => _selectedFilter = key),
    );

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
              SliverToBoxAdapter(
                child: TabHeader(
                  title: 'Estimates',
                  caption: _allEstimates.isEmpty
                      ? 'Quotes & proposals'
                      : '${_allEstimates.length} ${_allEstimates.length == 1 ? 'quote' : 'quotes'}',
                  showPro: !isPro,
                ),
              ),
              if (_allEstimates.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                    child: Row(
                      children: [
                        _stat('Pending', money(_totalPending), AppColors.ink),
                        _stat('Accepted', money(_totalAccepted), AppColors.statusPaid),
                        _stat('Estimated', money(_totalEstimated), AppColors.muted),
                      ],
                    ),
                  ),
                ),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: PinnedBarDelegate(
                    child: FilterRow(
                      children: [
                        pill('all', 'All', counted: false),
                        pill('pending', 'Pending'),
                        pill('accepted', 'Accepted'),
                        pill('converted', 'Converted'),
                        pill('declined', 'Declined'),
                      ],
                    ),
                  ),
                ),
              ],
              if (_isLoading)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                )
              else if (filtered.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 100),
                    child: EmptyStateView(
                      icon: AppIcons.estimate,
                      title: _allEstimates.isEmpty ? 'No Estimates Yet' : 'No Results Found',
                      subtitle: _allEstimates.isEmpty
                          ? 'Send a price before you bill. Accepted quotes turn into invoices in one tap.'
                          : 'Try another search or filter',
                      actionLabel: _allEstimates.isEmpty ? 'Create Estimate' : null,
                      onAction: _allEstimates.isEmpty ? _createNewEstimate : null,
                      isDarkBackground: false,
                    ),
                  ),
                )
              else ...[
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  sliver: SliverList.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) => _buildEstimateCard(filtered[index]),
                  ),
                ),
                const SliverToBoxAdapter(child: ListFootnote('Swipe right to convert · hold for more')),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _stat(String label, String value, Color color) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 12.5, color: AppColors.muted)),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, style: AppTypography.money(fontSize: 24, color: color, letterSpacing: -0.6)),
          ),
        ],
      ),
    );
  }

  /// Everything you can do to one estimate, on a long press.
  void _showActions(EstimateModel estimate) {
    Haptics.confirm();
    final locked = EstimateActions.isLocked(estimate);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) {
        Widget action(IconData icon, String label, VoidCallback f, {Color? color}) {
          final c = color ?? AppColors.ink;
          return ListTile(
            dense: true,
            visualDensity: VisualDensity.compact,
            leading: Icon(icon, color: c, size: 20),
            title: Text(label, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w500, color: c)),
            onTap: () {
              Navigator.pop(ctx);
              f();
            },
          );
        }

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 14, 8, 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(color: AppColors.hairline, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    estimate.clientName.isEmpty ? estimate.estimateNumber : estimate.clientName,
                    style: AppTypography.serif(fontSize: 20, color: AppColors.ink),
                  ),
                ),
                if (estimate.canConvert)
                  action(AppIcons.convert, 'Convert to Invoice', () => _convertToInvoice(estimate),
                      color: AppColors.statusPaid),
                action(AppIcons.visibility, 'View details', () => _openEstimatePreview(estimate)),
                action(AppIcons.share, 'Share PDF', () => _sharePdf(estimate)),
                if (!locked) ...[
                  if (estimate.status != EstimateStatus.accepted)
                    action(AppIcons.checkCircle, 'Mark accepted',
                        () => _quickUpdateStatus(estimate, EstimateStatus.accepted)),
                  if (estimate.status != EstimateStatus.declined)
                    action(AppIcons.cancel, 'Mark declined',
                        () => _quickUpdateStatus(estimate, EstimateStatus.declined)),
                  if (estimate.status != EstimateStatus.pending)
                    action(AppIcons.schedule, 'Mark pending',
                        () => _quickUpdateStatus(estimate, EstimateStatus.pending)),
                ],
                Divider(color: AppColors.hairline, height: 12),
                action(AppIcons.delete, 'Delete estimate', () => _deleteEstimate(estimate),
                    color: AppColors.error),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEstimateCard(EstimateModel estimate) {
    final status = estimate.status;
    final amount = CurrencyFormatter.format(
      estimate.grandTotal,
      currencyCode: estimate.currency.isNotEmpty ? estimate.currency : _currency,
    );
    final settled = status == EstimateStatus.converted || status == EstimateStatus.declined;

    final slip = PaperSlip(
      onTap: () {
        Haptics.tap();
        _openEstimatePreview(estimate);
      },
      onLongPress: () => _showActions(estimate),
      dimmed: settled,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  estimate.clientName.isEmpty ? 'No client' : estimate.clientName,
                  style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.ink),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  '${estimate.estimateNumber} · ${DateFormat('d MMM yyyy').format(estimate.estimateDate)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(fontSize: 12.5, color: AppColors.muted),
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
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: StampMark(label: status.stamp, color: status.color, fontSize: 9.5),
              ),
            ],
          ),
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Dismissible(
        key: ValueKey('est-${estimate.id}'),
        direction: estimate.canConvert ? DismissDirection.horizontal : DismissDirection.endToStart,
        dismissThresholds: const {DismissDirection.startToEnd: 0.3, DismissDirection.endToStart: 0.3},
        confirmDismiss: (direction) async {
          Haptics.tap();
          if (direction == DismissDirection.startToEnd) {
            _convertToInvoice(estimate);
          } else {
            _sharePdf(estimate);
          }
          return false;
        },
        background: _swipeBackground(true, AppColors.statusPaidBg, AppColors.statusPaid, AppIcons.convert, 'Convert'),
        secondaryBackground: _swipeBackground(false, AppColors.surfaceCard, AppColors.ink, AppIcons.share, 'Share'),
        child: slip,
      ),
    );
  }

  Widget _swipeBackground(bool left, Color bg, Color fg, IconData icon, String label) {
    final children = [
      Icon(icon, color: fg, size: 20),
      const SizedBox(width: 8),
      Text(label, style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w600, color: fg)),
    ];
    return Container(
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      alignment: left ? Alignment.centerLeft : Alignment.centerRight,
      child: Row(mainAxisSize: MainAxisSize.min, children: left ? children : children.reversed.toList()),
    );
  }

  /// For the shell's create sheet.
  Future<void> createNew() => _createNewEstimate();
}
