import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/localization/catalog_localization.dart';
import '../../../core/localization/l10n.dart';

import '../../../core/export/csv_export_service.dart';
import '../../../core/providers/currency_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/number_text.dart';
import '../../../shared_widgets/empty_state_view.dart';
import '../../../shared_widgets/paper.dart';
import '../../../shared_widgets/tab_chrome.dart';
import '../../invoices/models/invoice_model.dart';
import '../services/report_service.dart';
import '../widgets/revenue_bar_chart.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  ReportDateRange _range = ReportDateRange.allTime();
  ReportData _data = const ReportData(invoices: [], payments: []);
  String? _businessName;
  bool _isLoading = true;
  bool _isExporting = false;
  int _loadSeq = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final seq = ++_loadSeq;
    try {
      final results = await Future.wait([
        ReportService.loadFromDb(),
        SharedPreferences.getInstance(),
      ]);
      if (!mounted || seq != _loadSeq) return;
      final reportData = results[0] as ReportData;
      final prefs = results[1] as SharedPreferences;
      final bizName = prefs.getString('biz_name');
      setState(() {
        _data = reportData;
        _businessName = bizName;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Failed to load reports: $e');
      if (!mounted || seq != _loadSeq) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(context.l10n.couldNotLoadReportsPullDownToTry),
        ),
      );
    }
  }

  Future<void> _selectPeriod(ReportPeriod period) async {
    if (period == ReportPeriod.custom) {
      final now = DateTime.now();
      final initialStart = _range.start ?? DateTime(now.year, now.month, 1);
      final initialEnd = _range.end ?? DateTime(now.year, now.month, now.day);
      final picked = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2000),
        lastDate: DateTime(now.year + 5, 12, 31),
        initialDateRange: DateTimeRange(
          start: initialStart,
          end: initialEnd.isBefore(initialStart) ? initialStart : initialEnd,
        ),
      );
      if (picked == null || !mounted) return;
      setState(() {
        _range = ReportDateRange.custom(picked.start, picked.end);
      });
      return;
    }

    setState(() {
      _range = ReportDateRange.forPeriod(period);
    });
  }

  Future<void> _shareSummary(
    ReportSummary summary,
    String Function(double) formatMoney,
  ) async {
    Haptics.tap();
    final text = ReportService.buildShareSummary(
      summary,
      formatMoney: formatMoney,
      businessName: _businessName,
      localizations: context.l10n,
    );
    try {
      await SharePlus.instance.share(ShareParams(text: text));
    } catch (e) {
      debugPrint('Share summary failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text(context.l10n.couldNotShareSummaryPleaseTryAgain),
          ),
        );
      }
    }
  }

  Future<void> _exportCsv() async {
    if (_isExporting) return;
    HapticFeedback.mediumImpact();
    setState(() => _isExporting = true);
    try {
      await CsvExportService.exportAndShare(range: _range);
    } catch (e) {
      debugPrint('CSV export failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text(context.l10n.couldNotExportCsvFilesPleaseTryAgain),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = context.watch<CurrencyProvider>();
    final code = currency.currencyCode;
    final symbol = currency.currencySymbol;
    String money(double v) =>
        CurrencyFormatter.format(v, currencyCode: code, currencySymbol: symbol);

    final summary = ReportService.aggregate(
      invoices: _data.invoices,
      payments: _data.payments,
      range: _range,
      currencyCode: code,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: AppColors.hairline),
        ),
        leading: IconButton(
          icon: Icon(AppIcons.arrowBack, color: AppColors.ink),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(context.l10n.reports),
        centerTitle: true,
        actions: [
          if (!summary.isEmpty)
            IconButton(
              tooltip: context.l10n.shareSummary,
              onPressed: () => _shareSummary(summary, money),
              icon: Icon(AppIcons.share, color: AppColors.ink, size: 20),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: AppColors.primary,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _buildDateChips()),
            if (_isLoading)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              )
            else if (summary.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyStateView(
                  icon: AppIcons.pieChart,
                  title: _data.invoices.isEmpty
                      ? context.l10n.noReportsYet
                      : context.l10n.nothingInThisRange,
                  subtitle: _data.invoices.isEmpty
                      ? context.l10n.createAnInvoiceToTrackBilledRevenueCollections
                      : summary.otherCurrencyCounts.isNotEmpty
                      ? context.l10n.noInvoicesMatchInvoicesInOtherCurrencies(code, _range.localizedLabel(context.l10n), summary.otherCurrencyCounts.entries.map((e) => context.l10n.countInCurrency(e.value, e.key)).join(', '))
                      : context.l10n.noInvoicesOrPaymentsMatchTryAnotherDate(_range.localizedLabel(context.l10n)),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    if (summary.otherCurrencyCounts.isNotEmpty) ...[
                      _OtherCurrenciesBanner(
                        currencyCode: code,
                        counts: summary.otherCurrencyCounts,
                      ),
                      const SizedBox(height: 12),
                    ],
                    _buildSummaryGrid(summary, money),
                    const SizedBox(height: 12),
                    RevenueBarChart(
                      points: summary.monthlyRevenue,
                      currencyCode: code,
                      currencySymbol: symbol,
                    ),
                    const SizedBox(height: 12),
                    _StatusBreakdownCard(summary: summary, formatMoney: money),
                    if (summary.topClients.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _TopClientsCard(
                        clients: summary.topClients,
                        formatMoney: money,
                      ),
                    ],
                    if (summary.topItems.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _TopItemsCard(
                        items: summary.topItems,
                        formatMoney: money,
                      ),
                    ],
                    const SizedBox(height: 16),
                    _buildExportActions(summary, money),
                  ]),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateChips() {
    Widget chip(ReportPeriod period, String label) {
      final selected = _range.period == period;
      return FilterPill(
        label: label,
        selected: selected,
        onTap: () => _selectPeriod(period),
      );
    }

    final customLabel = _range.period == ReportPeriod.custom
        ? _range.localizedLabel(context.l10n)
        : context.l10n.custom;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: FilterRow(
        children: [
          chip(ReportPeriod.today, context.l10n.today),
          chip(ReportPeriod.thisWeek, context.l10n.thisWeek),
          chip(ReportPeriod.thisMonth, context.l10n.thisMonth),
          chip(ReportPeriod.thisYear, context.l10n.thisYear),
          chip(ReportPeriod.allTime, context.l10n.allTime),
          // Custom can be re-tapped even while selected to pick a new range.
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Semantics(
              selected: _range.period == ReportPeriod.custom,
              button: true,
              child: GestureDetector(
                onTap: () {
                  Haptics.tap();
                  _selectPeriod(ReportPeriod.custom);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  height: 34,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: _range.period == ReportPeriod.custom
                        ? AppColors.primary
                        : AppColors.canvas,
                    borderRadius: BorderRadius.circular(9999),
                    border: Border.all(
                      color: _range.period == ReportPeriod.custom
                          ? AppColors.primary
                          : AppColors.hairline,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        AppIcons.calendar,
                        size: 14,
                        color: _range.period == ReportPeriod.custom
                            ? AppColors.onPrimary
                            : AppColors.body,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        customLabel,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: _range.period == ReportPeriod.custom
                              ? AppColors.onPrimary
                              : AppColors.body,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryGrid(
    ReportSummary summary,
    String Function(double) money,
  ) {
    final tax = summary.taxBreakdown;
    final taxNoteParts = <String>[
      if (tax.cgst > 0) 'CGST ${money(tax.cgst)}',
      if (tax.sgst > 0) 'SGST ${money(tax.sgst)}',
      if (tax.igst > 0) 'IGST ${money(tax.igst)}',
    ];
    final taxSubtitle = taxNoteParts.isNotEmpty
        ? taxNoteParts.join(' · ')
        : context.l10n.acrossInvoices(summary.invoiceCount);

    final collectionPct = summary.totalBilled > 0
        ? context.l10n.percentOfBilled(((summary.totalCollected / summary.totalBilled) * 100).clamp(0, 999).round())
        : context.l10n.paymentsReceived;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatTile(
                label: context.l10n.billed,
                value: money(summary.totalBilled),
                subtitle:
                    context.l10n.invoiceCount(summary.invoiceCount),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatTile(
                label: context.l10n.collectedHeading,
                value: money(summary.totalCollected),
                valueColor: AppColors.statusPaid,
                subtitle: collectionPct,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _StatTile(
                label: context.l10n.outstanding,
                value: money(summary.totalOutstanding),
                subtitle: context.l10n.balanceRemaining,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatTile(
                label: context.l10n.overdueStamp,
                value: money(summary.overdueAmount),
                valueColor: summary.overdueCount > 0
                    ? AppColors.statusOverdue
                    : AppColors.ink,
                subtitle:
                    context.l10n.overdueInvoices(summary.overdueCount),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _StatTile(
                label: context.l10n.taxCollected,
                value: money(summary.totalTax),
                subtitle: taxSubtitle,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatTile(
                label: context.l10n.avgInvoice,
                value: money(summary.averageInvoiceValue),
                subtitle: _range.localizedLabel(context.l10n),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildExportActions(
    ReportSummary summary,
    String Function(double) money,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          onPressed: _isExporting ? null : _exportCsv,
          icon: _isExporting
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.onPrimary,
                  ),
                )
              : Icon(AppIcons.download, size: 18),
          label: Text(
            _isExporting ? context.l10n.preparingCsvFiles : context.l10n.exportToCsvExcel,
          ),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: () => _shareSummary(summary, money),
          icon: Icon(AppIcons.share, size: 18),
          label: Text(context.l10n.shareSummary),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final String subtitle;
  final Color? valueColor;

  const _StatTile({
    required this.label,
    required this.value,
    required this.subtitle,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return PaperSlip(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TabHeader.captionStyle.copyWith(color: AppColors.mutedSoft),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: AppTypography.money(
                fontSize: 22,
                color: valueColor ?? AppColors.ink,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(fontSize: 11.5, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

class _StatusBreakdownCard extends StatelessWidget {
  final ReportSummary summary;
  final String Function(double) formatMoney;

  const _StatusBreakdownCard({
    required this.summary,
    required this.formatMoney,
  });

  @override
  Widget build(BuildContext context) {
    final ordered = [
      InvoiceStatus.paid,
      InvoiceStatus.partiallyPaid,
      InvoiceStatus.unpaid,
      InvoiceStatus.overdue,
    ];

    final totalAmt = ordered.fold<double>(
      0,
      (s, st) => s + (summary.statusBreakdown[st]?.amount ?? 0),
    );
    final totalCount = summary.invoiceCount;

    return PaperSlip(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.statusBreakdown,
            style: AppTypography.serif(fontSize: 19, color: AppColors.ink),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(9999),
            child: SizedBox(
              height: 10,
              width: double.infinity,
              child: Row(
                children: [
                  for (final status in ordered)
                    if (_weight(status, totalAmt, totalCount) > 0)
                      Expanded(
                        flex: _weight(status, totalAmt, totalCount),
                        child: ColoredBox(color: _statusColor(status)),
                      ),
                  if (totalCount == 0)
                    Expanded(child: ColoredBox(color: AppColors.hairline)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          for (final status in ordered) ...[
            _StatusRow(
              status: status,
              row: summary.statusBreakdown[status]!,
              color: _statusColor(status),
              formatMoney: formatMoney,
            ),
            if (status != ordered.last) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  int _weight(InvoiceStatus status, double totalAmt, int totalCount) {
    final row = summary.statusBreakdown[status];
    if (row == null || row.count == 0) return 0;
    if (totalAmt > 0) {
      return (row.amount * 1000 / totalAmt).round().clamp(1, 1000);
    }
    return totalCount > 0 ? row.count : 0;
  }

  Color _statusColor(InvoiceStatus status) => switch (status) {
    InvoiceStatus.paid => AppColors.statusPaid,
    InvoiceStatus.partiallyPaid => AppColors.statusPartiallyPaid,
    InvoiceStatus.unpaid => AppColors.statusUnpaid,
    InvoiceStatus.overdue => AppColors.statusOverdue,
  };
}

class _StatusRow extends StatelessWidget {
  final InvoiceStatus status;
  final StatusBreakdownRow row;
  final Color color;
  final String Function(double) formatMoney;

  const _StatusRow({
    required this.status,
    required this.row,
    required this.color,
    required this.formatMoney,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            context.l10n.catalogLabel(status.label),
            style: GoogleFonts.inter(
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              color: AppColors.ink,
            ),
          ),
        ),
        Text(
          '${row.count}',
          style: GoogleFonts.inter(
            fontSize: 12.5,
            color: AppColors.muted,
            fontFeatures: AppTypography.tabularFigures,
          ),
        ),
        const SizedBox(width: 14),
        Text(
          formatMoney(row.amount),
          style: AppTypography.money(fontSize: 14, color: AppColors.ink),
        ),
      ],
    );
  }
}

class _TopClientsCard extends StatelessWidget {
  final List<ClientReportRow> clients;
  final String Function(double) formatMoney;

  const _TopClientsCard({required this.clients, required this.formatMoney});

  @override
  Widget build(BuildContext context) {
    final topAmount = clients.first.billedAmount;

    return PaperSlip(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.topClients,
            style: AppTypography.serif(fontSize: 19, color: AppColors.ink),
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < clients.length; i++) ...[
            _RankedBarRow(
              rank: i + 1,
              title: clients[i].localizedName(context.l10n),
              subtitle:
                  context.l10n.invoiceCount(clients[i].invoiceCount),
              amountText: formatMoney(clients[i].billedAmount),
              fraction: topAmount <= 0
                  ? 0
                  : (clients[i].billedAmount / topAmount).clamp(0.0, 1.0),
              barColor: AppColors.ink,
            ),
            if (i < clients.length - 1) const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _TopItemsCard extends StatelessWidget {
  final List<ItemReportRow> items;
  final String Function(double) formatMoney;

  const _TopItemsCard({required this.items, required this.formatMoney});

  @override
  Widget build(BuildContext context) {
    final topRevenue = items.first.revenue;

    return PaperSlip(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.topItems,
            style: AppTypography.serif(fontSize: 19, color: AppColors.ink),
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < items.length; i++) ...[
            _RankedBarRow(
              rank: i + 1,
              title: items[i].description,
              subtitle:
                  context.l10n.reportItemQuantity(NumberText.trim(items[i].quantity), context.l10n.invoiceCount(items[i].invoiceCount)),
              amountText: formatMoney(items[i].revenue),
              fraction: topRevenue <= 0
                  ? 0
                  : (items[i].revenue / topRevenue).clamp(0.0, 1.0),
              barColor: AppColors.statusPaid,
            ),
            if (i < items.length - 1) const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _RankedBarRow extends StatelessWidget {
  final int rank;
  final String title;
  final String subtitle;
  final String amountText;
  final double fraction;
  final Color barColor;

  const _RankedBarRow({
    required this.rank,
    required this.title,
    required this.subtitle,
    required this.amountText,
    required this.fraction,
    required this.barColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SizedBox(
              width: 20,
              child: Text(
                '$rank.',
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.mutedSoft,
                  fontFeatures: AppTypography.tabularFigures,
                ),
              ),
            ),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              amountText,
              style: AppTypography.money(fontSize: 14.5, color: AppColors.ink),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(left: 20),
          child: Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(9999),
                  child: SizedBox(
                    height: 4,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: ColoredBox(color: AppColors.hairlineSoft),
                        ),
                        FractionallySizedBox(
                          widthFactor: fraction,
                          heightFactor: 1,
                          alignment: Alignment.centerLeft,
                          child: ColoredBox(color: barColor),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  color: AppColors.muted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _OtherCurrenciesBanner extends StatelessWidget {
  final String currencyCode;
  final Map<String, int> counts;

  const _OtherCurrenciesBanner({
    required this.currencyCode,
    required this.counts,
  });

  @override
  Widget build(BuildContext context) {
    final list = counts.entries.map((e) => context.l10n.countInCurrency(e.value, e.key)).join(', ');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.hairline),
      ),
      child: Text(
        context.l10n.totalsAreForInvoicesOnlyNotIncluded(currencyCode, list),
        style: GoogleFonts.inter(fontSize: 12, color: AppColors.muted),
      ),
    );
  }
}
