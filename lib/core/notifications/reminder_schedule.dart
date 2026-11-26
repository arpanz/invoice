import '../../l10n/gen/app_localizations.dart';
import '../../l10n/gen/app_localizations_en.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../features/invoices/models/invoice_model.dart';
import '../utils/currency_formatter.dart';

enum BeforeDueReminder {
  off(0),
  oneDay(1),
  threeDays(3),
  sevenDays(7);

  const BeforeDueReminder(this.days);
  final int days;
}

enum OverdueReminder {
  off(0),
  threeDays(3),
  sevenDays(7);

  const OverdueReminder(this.days);
  final int days;
}

class ReminderSettings {
  const ReminderSettings({
    this.enabled = false,
    this.beforeDue = BeforeDueReminder.oneDay,
    this.overdue = OverdueReminder.sevenDays,
  });

  final bool enabled;
  final BeforeDueReminder beforeDue;
  final OverdueReminder overdue;

  ReminderSettings copyWith({
    bool? enabled,
    BeforeDueReminder? beforeDue,
    OverdueReminder? overdue,
  }) => ReminderSettings(
    enabled: enabled ?? this.enabled,
    beforeDue: beforeDue ?? this.beforeDue,
    overdue: overdue ?? this.overdue,
  );
}

typedef ScheduledReminder = ({
  int id,
  String invoiceId,
  DateTime time,
  String text,
});

bool hasReminderBalance(InvoiceModel invoice) =>
    invoice.status != InvoiceStatus.paid && invoice.balanceDue > 0.009;

String formatReminderBalance(InvoiceModel invoice, {bool compact = false}) =>
    CurrencyFormatter.format(
      invoice.balanceDue,
      currencyCode: invoice.currency,
      decimalDigits:
          compact && invoice.balanceDue == invoice.balanceDue.truncate()
          ? 0
          : null,
    );

/// Calendar slots are at 9 AM. A zoned [now] keeps that hour across DST.
List<ScheduledReminder> computeReminderSchedule(
  Iterable<InvoiceModel> invoices,
  ReminderSettings settings,
  DateTime now, {
  AppLocalizations? l10n,
}) {
  final strings = l10n ?? AppLocalizationsEn();
  if (!settings.enabled) return [];
  final eligible =
      invoices
          .where(
            (invoice) => invoice.dueDate != null && hasReminderBalance(invoice),
          )
          .toList()
        ..sort((a, b) => a.id.compareTo(b.id));
  final schedule = <ScheduledReminder>[];
  final usedIds = <int>{};

  for (final invoice in eligible) {
    final due = invoice.dueDate!;
    final client = invoice.clientName.trim();
    final amount = formatReminderBalance(invoice, compact: true);
    final balance = client.isEmpty
        ? strings.reminderBalance(amount)
        : strings.reminderBalanceFromClient(amount, client);
    final baseId = _stableInvoiceHash(invoice.id);

    void add(int slot, int offset, String detail) {
      // Allocate the slot even if its date has passed, so the remaining
      // reminders retain their IDs on the next sync.
      var id = (baseId << 3) | slot;
      while (!usedIds.add(id)) {
        id = (id + 8) & 0x7fffffff;
      }
      final time = _reminderTime(now, due, offset);
      if (time.isAfter(now)) {
        schedule.add((
          id: id,
          invoiceId: invoice.id,
          time: time,
          text: strings.reminderNotificationBody(invoice.invoiceNumber, balance, detail),
        ));
      }
    }

    final before = settings.beforeDue.days;
    if (before > 0) {
      add(0, -before, before == 1 ? strings.reminderTomorrow : strings.reminderInDays(before));
    }
    add(1, 0, strings.reminderToday);
    final repeat = settings.overdue.days;
    if (repeat > 0) {
      for (var occurrence = 1; occurrence <= 3; occurrence++) {
        final days = repeat * occurrence;
        add(occurrence + 1, days, strings.reminderDaysOverdue(days));
      }
    }
  }
  return schedule..sort((a, b) {
    final byTime = a.time.compareTo(b.time);
    return byTime == 0 ? a.id.compareTo(b.id) : byTime;
  });
}

int _stableInvoiceHash(String invoiceId) {
  // FNV-1a with 28 bits, leaving three bits for the slot in a signed int.
  var hash = 0x811c9dc5 & 0xfffffff;
  for (final unit in invoiceId.codeUnits) {
    hash = ((hash ^ unit) * 0x01000193) & 0xfffffff;
  }
  return hash;
}

DateTime _reminderTime(DateTime now, DateTime due, int offset) {
  final day = due.day + offset;
  if (now is tz.TZDateTime) {
    return tz.TZDateTime(now.location, due.year, due.month, day, 9);
  }
  return now.isUtc
      ? DateTime.utc(due.year, due.month, day, 9)
      : DateTime(due.year, due.month, day, 9);
}
