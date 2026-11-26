import 'package:intl/intl.dart';
import '../../../l10n/gen/app_localizations_en.dart';
import '../../../l10n/gen/app_localizations.dart';

import '../../../core/database/db_provider.dart';
import '../../../core/utils/document_totals.dart';
import '../../invoices/models/invoice_model.dart';
import '../../invoices/models/payment_model.dart';

/// Preset date ranges for reports and CSV export.
enum ReportPeriod { today, thisWeek, thisMonth, thisYear, allTime, custom }

/// Inclusive calendar-date range for filtering invoices and payments.
class ReportDateRange {
  final ReportPeriod period;
  final DateTime? start;
  final DateTime? end;

  const ReportDateRange._({required this.period, this.start, this.end});

  factory ReportDateRange.allTime() =>
      const ReportDateRange._(period: ReportPeriod.allTime);

  factory ReportDateRange.custom(DateTime start, DateTime end) {
    final s = DateTime(start.year, start.month, start.day);
    final e = DateTime(end.year, end.month, end.day);
    return s.isAfter(e)
        ? ReportDateRange._(period: ReportPeriod.custom, start: e, end: s)
        : ReportDateRange._(period: ReportPeriod.custom, start: s, end: e);
  }

  factory ReportDateRange.forPeriod(
    ReportPeriod period, {
    DateTime? now,
    DateTime? customStart,
    DateTime? customEnd,
  }) {
    final ref = now ?? DateTime.now();
    final today = DateTime(ref.year, ref.month, ref.day);
    switch (period) {
      case ReportPeriod.today:
        return ReportDateRange._(period: period, start: today, end: today);
      case ReportPeriod.thisWeek:
        final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
        final endOfWeek = startOfWeek.add(const Duration(days: 6));
        return ReportDateRange._(
          period: period,
          start: startOfWeek,
          end: endOfWeek,
        );
      case ReportPeriod.thisMonth:
        return ReportDateRange._(
          period: period,
          start: DateTime(today.year, today.month, 1),
          end: DateTime(today.year, today.month + 1, 0),
        );
      case ReportPeriod.thisYear:
        return ReportDateRange._(
          period: period,
          start: DateTime(today.year, 1, 1),
          end: DateTime(today.year, 12, 31),
        );
      case ReportPeriod.allTime:
        return ReportDateRange.allTime();
      case ReportPeriod.custom:
        if (customStart != null && customEnd != null) {
          return ReportDateRange.custom(customStart, customEnd);
        }
        return ReportDateRange.allTime();
    }
  }

  /// True when [date]'s calendar day falls within [start]..[end] inclusive.
  bool contains(DateTime date) {
    if (start == null && end == null) return true;
    final day = DateTime(date.year, date.month, date.day);
    if (start != null && day.isBefore(start!)) return false;
    if (end != null && day.isAfter(end!)) return false;
    return true;
  }

  String get label => localizedLabel(AppLocalizationsEn('en_US'));

  String localizedLabel(AppLocalizations l10n) {
    switch (period) {
      case ReportPeriod.today:
        return l10n.today;
      case ReportPeriod.thisWeek:
        return l10n.thisWeek;
      case ReportPeriod.thisMonth:
        return l10n.thisMonth;
      case ReportPeriod.thisYear:
        return l10n.thisYear;
      case ReportPeriod.allTime:
        return l10n.allTime;
      case ReportPeriod.custom:
        if (start == null || end == null) return l10n.custom;
        if (start!.year == end!.year) {
          if (start!.month == end!.month && start!.day == end!.day) {
            return DateFormat('d MMM yyyy', l10n.localeName).format(start!);
          }
          return '${DateFormat('d MMM', l10n.localeName).format(start!)} – ${DateFormat('d MMM yyyy', l10n.localeName).format(end!)}';
        }
        return '${DateFormat('d MMM yyyy', l10n.localeName).format(start!)} – ${DateFormat('d MMM yyyy', l10n.localeName).format(end!)}';
    }
  }

  @override
  bool operator ==(Object other) =>
      other is ReportDateRange &&
      other.period == period &&
      other.start == start &&
      other.end == end;

  @override
  int get hashCode => Object.hash(period, start, end);
}

class MonthlyRevenuePoint {
  final DateTime month;
  final double billed;
  final double collected;

  const MonthlyRevenuePoint({
    required this.month,
    required this.billed,
    required this.collected,
  });
}

class ClientReportRow {
  final String name;
  final bool hasName;
  final int invoiceCount;
  final double billedAmount;
  final double paidAmount;

  const ClientReportRow({
    required this.name,
    this.hasName = true,
    required this.invoiceCount,
    required this.billedAmount,
    required this.paidAmount,
  });

  String localizedName(AppLocalizations l10n) => hasName ? name : l10n.noClient;
}

class ItemReportRow {
  final String description;
  final double quantity;
  final double revenue;
  final int invoiceCount;

  const ItemReportRow({
    required this.description,
    required this.quantity,
    required this.revenue,
    required this.invoiceCount,
  });
}

class StatusBreakdownRow {
  final InvoiceStatus status;
  final int count;
  final double amount;

  const StatusBreakdownRow({
    required this.status,
    required this.count,
    required this.amount,
  });
}

class TaxBreakdown {
  final double cgst;
  final double sgst;
  final double igst;
  final double singleTax;

  const TaxBreakdown({
    this.cgst = 0,
    this.sgst = 0,
    this.igst = 0,
    this.singleTax = 0,
  });

  double get total => cgst + sgst + igst + singleTax;
}

class ReportData {
  final List<InvoiceModel> invoices;
  final List<PaymentModel> payments;

  const ReportData({required this.invoices, required this.payments});
}

class ReportSummary {
  final ReportDateRange range;
  final String? currencyCode;
  final double totalBilled;
  final double totalCollected;
  final double totalOutstanding;
  final double overdueAmount;
  final int overdueCount;
  final int invoiceCount;
  final double averageInvoiceValue;
  final double totalTax;
  final TaxBreakdown taxBreakdown;
  final List<MonthlyRevenuePoint> monthlyRevenue;
  final List<ClientReportRow> topClients;
  final List<ItemReportRow> topItems;
  final Map<InvoiceStatus, StatusBreakdownRow> statusBreakdown;
  final Map<String, int> otherCurrencyCounts;

  const ReportSummary({
    required this.range,
    this.currencyCode,
    required this.totalBilled,
    required this.totalCollected,
    required this.totalOutstanding,
    required this.overdueAmount,
    required this.overdueCount,
    required this.invoiceCount,
    required this.averageInvoiceValue,
    required this.totalTax,
    required this.taxBreakdown,
    required this.monthlyRevenue,
    required this.topClients,
    required this.topItems,
    required this.statusBreakdown,
    this.otherCurrencyCounts = const {},
  });

  bool get isEmpty => invoiceCount == 0 && totalCollected == 0;
}

class ReportService {
  ReportService._();

  /// Loads invoices (with lines) and payments through [DbProvider]'s public API.
  static Future<ReportData> loadFromDb() async {
    final invoices = await DbProvider.loadInvoices();
    final paymentRows = await DbProvider.query(
      DbProvider.tablePayments,
      orderBy: 'paid_on ASC, created_at ASC',
    );
    final payments = paymentRows.map(PaymentModel.fromMap).toList();
    return ReportData(invoices: invoices, payments: payments);
  }

  /// Computes [DocumentTotals] for [invoice], falling back to stored header
  /// totals only when [invoice.lineItems] is empty.
  static DocumentTotals totalsForInvoice(InvoiceModel invoice) {
    if (invoice.lineItems.isNotEmpty) {
      return DocumentTotals.ofInvoice(invoice);
    }
    final taxable = (invoice.subtotal - invoice.discountAmount).clamp(
      0.0,
      double.infinity,
    );
    return DocumentTotals(
      subtotal: invoice.subtotal,
      discountAmount: invoice.discountAmount,
      taxableAmount: taxable,
      taxComponents: const [],
      taxAmount: invoice.taxAmount,
      shipping: invoice.shipping,
      grandTotal: invoice.grandTotal,
    );
  }

  /// Mirrors [InvoiceModel.effectiveStatus] with an explicit [now] clock and
  /// computed [balanceDue] so overdue calculations are deterministic in tests.
  static InvoiceStatus effectiveStatusOf(
    InvoiceModel invoice,
    DateTime now, {
    double? balanceOverride,
  }) {
    final balance = balanceOverride ?? invoice.balanceDue;
    if (invoice.status == InvoiceStatus.paid || balance <= 0.009) {
      return InvoiceStatus.paid;
    }
    if (invoice.status == InvoiceStatus.overdue) {
      return InvoiceStatus.overdue;
    }
    if (invoice.dueDate != null) {
      final endOfDue = DateTime(
        invoice.dueDate!.year,
        invoice.dueDate!.month,
        invoice.dueDate!.day,
      ).add(const Duration(days: 1));
      if (now.isAfter(endOfDue)) {
        return InvoiceStatus.overdue;
      }
    }
    return invoice.status;
  }

  /// Pure aggregation over [invoices] and [payments] for [range].
  ///
  /// When [currencyCode] is provided, only invoices matching that currency (and
  /// payments linked to them) are included in the sums, while mismatched
  /// invoices in [range] are counted in [ReportSummary.otherCurrencyCounts].
  static ReportSummary aggregate({
    required List<InvoiceModel> invoices,
    required List<PaymentModel> payments,
    required ReportDateRange range,
    String? currencyCode,
    DateTime? now,
  }) {
    final refNow = now ?? DateTime.now();
    final targetCurrency = currencyCode?.trim().toUpperCase();

    final otherCurrencies = <String, int>{};
    final matchingInvoices = <InvoiceModel>[];
    final matchingInvoiceIds = <String>{};

    for (final inv in invoices) {
      final invCurrency = inv.currency.trim().toUpperCase();
      if (targetCurrency != null &&
          targetCurrency.isNotEmpty &&
          invCurrency.isNotEmpty &&
          invCurrency != targetCurrency) {
        if (range.contains(inv.invoiceDate)) {
          otherCurrencies[inv.currency] =
              (otherCurrencies[inv.currency] ?? 0) + 1;
        }
        continue;
      }
      matchingInvoices.add(inv);
      matchingInvoiceIds.add(inv.id);
    }

    final inRangeInvoices = matchingInvoices
        .where((i) => range.contains(i.invoiceDate))
        .toList();
    final matchingPayments = targetCurrency == null || targetCurrency.isEmpty
        ? payments
        : payments
              .where((p) => matchingInvoiceIds.contains(p.invoiceId))
              .toList();
    final inRangePayments = matchingPayments
        .where((p) => range.contains(p.paidOn))
        .toList();

    double totalBilled = 0;
    double totalOutstanding = 0;
    double overdueAmount = 0;
    int overdueCount = 0;
    double totalTax = 0;
    double cgst = 0;
    double sgst = 0;
    double igst = 0;
    double singleTax = 0;

    final statusCounts = <InvoiceStatus, int>{
      for (final s in InvoiceStatus.values) s: 0,
    };
    final statusAmounts = <InvoiceStatus, double>{
      for (final s in InvoiceStatus.values) s: 0.0,
    };

    final clientAcc = <String, _ClientAcc>{};
    final itemAcc = <String, _ItemAcc>{};

    for (final inv in inRangeInvoices) {
      final totals = totalsForInvoice(inv);
      final billed = totals.grandTotal;
      final balance = (billed - inv.paidAmount).clamp(0.0, double.infinity);
      final status = effectiveStatusOf(inv, refNow, balanceOverride: balance);

      totalBilled += billed;
      if (status != InvoiceStatus.paid) {
        totalOutstanding += balance;
      }
      if (status == InvoiceStatus.overdue) {
        overdueCount++;
        overdueAmount += balance;
      }

      statusCounts[status] = (statusCounts[status] ?? 0) + 1;
      statusAmounts[status] = (statusAmounts[status] ?? 0) + billed;

      totalTax += totals.taxAmount;
      if (totals.taxComponents.isNotEmpty) {
        for (final c in totals.taxComponents) {
          switch (c.kind) {
            case TaxComponentKind.cgst:
              cgst += c.amount;
            case TaxComponentKind.sgst:
              sgst += c.amount;
            case TaxComponentKind.igst:
              igst += c.amount;
            case TaxComponentKind.single:
              singleTax += c.amount;
          }
        }
      } else if (totals.taxAmount > 0) {
        if (inv.cgstRate > 0 || inv.sgstRate > 0) {
          final half = totals.taxAmount / 2;
          cgst += half;
          sgst += half;
        } else if (inv.igstRate > 0) {
          igst += totals.taxAmount;
        } else {
          singleTax += totals.taxAmount;
        }
      }

      // Top clients aggregation
      final clientKey =
          (inv.clientId != null && inv.clientId!.trim().isNotEmpty)
          ? 'id:${inv.clientId!.trim()}'
          : 'name:${inv.clientName.trim().toLowerCase()}';
      final clientDisplay = inv.clientName.trim();
      final cEntry = clientAcc.putIfAbsent(
        clientKey,
        () => _ClientAcc(clientDisplay),
      );
      cEntry.invoiceCount++;
      cEntry.billedAmount += billed;
      cEntry.paidAmount += inv.paidAmount;

      // Top items aggregation
      for (final line in inv.lineItems) {
        final desc = line.description.trim();
        if (desc.isEmpty) continue;
        final itemKey = desc.toLowerCase();
        final iEntry = itemAcc.putIfAbsent(itemKey, () => _ItemAcc(desc));
        iEntry.quantity += line.quantity;
        iEntry.revenue += line.total;
        iEntry.invoiceIds.add(inv.id);
      }
    }

    final totalCollected = inRangePayments.fold<double>(
      0.0,
      (sum, p) => sum + p.amount,
    );
    final invoiceCount = inRangeInvoices.length;
    final averageInvoiceValue = invoiceCount == 0
        ? 0.0
        : totalBilled / invoiceCount;

    final topClients =
        clientAcc.values
            .map(
              (c) => ClientReportRow(
                name: c.name.isEmpty ? AppLocalizationsEn('en_US').noClient : c.name,
                hasName: c.name.isNotEmpty,
                invoiceCount: c.invoiceCount,
                billedAmount: c.billedAmount,
                paidAmount: c.paidAmount,
              ),
            )
            .toList()
          ..sort((a, b) {
            final cmp = b.billedAmount.compareTo(a.billedAmount);
            if (cmp != 0) return cmp;
            final cntCmp = b.invoiceCount.compareTo(a.invoiceCount);
            return cntCmp != 0 ? cntCmp : a.name.compareTo(b.name);
          });

    final topItems =
        itemAcc.values
            .map(
              (i) => ItemReportRow(
                description: i.description,
                quantity: i.quantity,
                revenue: i.revenue,
                invoiceCount: i.invoiceIds.length,
              ),
            )
            .toList()
          ..sort((a, b) {
            final cmp = b.revenue.compareTo(a.revenue);
            if (cmp != 0) return cmp;
            final qtyCmp = b.quantity.compareTo(a.quantity);
            return qtyCmp != 0
                ? qtyCmp
                : a.description.compareTo(b.description);
          });

    final monthlySeries = _buildMonthlySeries(
      invoices: inRangeInvoices,
      payments: inRangePayments,
      range: range,
      now: refNow,
    );

    final breakdown = <InvoiceStatus, StatusBreakdownRow>{
      for (final s in InvoiceStatus.values)
        s: StatusBreakdownRow(
          status: s,
          count: statusCounts[s] ?? 0,
          amount: statusAmounts[s] ?? 0,
        ),
    };

    return ReportSummary(
      range: range,
      currencyCode: currencyCode,
      totalBilled: totalBilled,
      totalCollected: totalCollected,
      totalOutstanding: totalOutstanding,
      overdueAmount: overdueAmount,
      overdueCount: overdueCount,
      invoiceCount: invoiceCount,
      averageInvoiceValue: averageInvoiceValue,
      totalTax: totalTax,
      taxBreakdown: TaxBreakdown(
        cgst: cgst,
        sgst: sgst,
        igst: igst,
        singleTax: singleTax,
      ),
      monthlyRevenue: monthlySeries,
      topClients: topClients.take(5).toList(),
      topItems: topItems.take(5).toList(),
      statusBreakdown: breakdown,
      otherCurrencyCounts: otherCurrencies,
    );
  }

  static List<MonthlyRevenuePoint> _buildMonthlySeries({
    required List<InvoiceModel> invoices,
    required List<PaymentModel> payments,
    required ReportDateRange range,
    required DateTime now,
  }) {
    final months = _monthBuckets(range, now);
    final billedByMonth = <(int, int), double>{};
    final collectedByMonth = <(int, int), double>{};

    for (final inv in invoices) {
      final key = (inv.invoiceDate.year, inv.invoiceDate.month);
      billedByMonth[key] =
          (billedByMonth[key] ?? 0) + totalsForInvoice(inv).grandTotal;
    }
    for (final p in payments) {
      final key = (p.paidOn.year, p.paidOn.month);
      collectedByMonth[key] = (collectedByMonth[key] ?? 0) + p.amount;
    }

    return [
      for (final m in months)
        MonthlyRevenuePoint(
          month: m,
          billed: billedByMonth[(m.year, m.month)] ?? 0,
          collected: collectedByMonth[(m.year, m.month)] ?? 0,
        ),
    ];
  }

  static List<DateTime> _monthBuckets(ReportDateRange range, DateTime now) {
    if (range.period == ReportPeriod.allTime) {
      return [
        for (var i = 11; i >= 0; i--) DateTime(now.year, now.month - i, 1),
      ];
    }
    if (range.period == ReportPeriod.thisYear) {
      return [for (var m = 1; m <= 12; m++) DateTime(now.year, m, 1)];
    }
    final s = range.start ?? now;
    final e = range.end ?? now;
    final startMonth = DateTime(s.year, s.month, 1);
    final endMonth = DateTime(e.year, e.month, 1);
    final list = <DateTime>[];
    var cursor = startMonth;
    while (!cursor.isAfter(endMonth)) {
      list.add(cursor);
      cursor = DateTime(cursor.year, cursor.month + 1, 1);
    }
    if (list.length > 12) {
      return list.sublist(list.length - 12);
    }
    return list;
  }

  /// Generates a clean plain-text summary suitable for sharing.
  static String buildShareSummary(
    ReportSummary summary, {
    required String Function(double) formatMoney,
    String? businessName,
    AppLocalizations? localizations,
  }) {
    final l10n = localizations ?? AppLocalizationsEn('en_US');
    final buf = StringBuffer();
    final business = businessName?.trim() ?? '';
    buf.writeln(business.isEmpty ? l10n.reportFinancial : l10n.reportFinancialFor(business));
    buf.writeln(l10n.reportPeriod(summary.range.localizedLabel(l10n)));
    buf.writeln();
    buf.writeln(l10n.reportBilledAmount(
      formatMoney(summary.totalBilled), l10n.invoiceCount(summary.invoiceCount),
    ));
    buf.writeln(l10n.reportCollectedAmount(formatMoney(summary.totalCollected)));
    buf.writeln(l10n.reportOutstandingAmount(formatMoney(summary.totalOutstanding)));
    buf.writeln(l10n.reportOverdueAmount(formatMoney(summary.overdueAmount), summary.overdueCount));
    buf.writeln(l10n.reportTaxAmount(formatMoney(summary.totalTax)));
    buf.writeln(l10n.reportAverageInvoice(formatMoney(summary.averageInvoiceValue)));

    if (summary.topClients.isNotEmpty) {
      buf.writeln('');
      buf.writeln(l10n.reportTopClientsHeading);
      for (var i = 0; i < summary.topClients.length; i++) {
        final c = summary.topClients[i];
        buf.writeln(
          '${i + 1}. ${c.localizedName(l10n)} — ${formatMoney(c.billedAmount)} (${c.invoiceCount})',
        );
      }
    }

    if (summary.topItems.isNotEmpty) {
      buf.writeln('');
      buf.writeln(l10n.reportTopItemsHeading);
      for (var i = 0; i < summary.topItems.length; i++) {
        final item = summary.topItems[i];
        buf.writeln(
          '${i + 1}. ${item.description} — ${formatMoney(item.revenue)}',
        );
      }
    }

    return buf.toString().trimRight();
  }
}

class _ClientAcc {
  final String name;
  int invoiceCount = 0;
  double billedAmount = 0;
  double paidAmount = 0;

  _ClientAcc(this.name);
}

class _ItemAcc {
  final String description;
  double quantity = 0;
  double revenue = 0;
  final Set<String> invoiceIds = {};

  _ItemAcc(this.description);
}
