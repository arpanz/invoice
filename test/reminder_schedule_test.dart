import 'package:flutter_test/flutter_test.dart';
import 'package:invoice/core/notifications/reminder_schedule.dart';
import 'package:invoice/features/invoices/models/invoice_model.dart';
import 'package:invoice/l10n/gen/app_localizations_hi.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

void main() {
  final now = DateTime.utc(2026, 3, 1, 8);
  final due = DateTime.utc(2026, 3, 2);
  const settings = ReminderSettings(enabled: true);

  InvoiceModel invoice({
    String id = 'invoice-12',
    DateTime? dueDate,
    InvoiceStatus status = InvoiceStatus.unpaid,
    double paid = 0,
  }) => InvoiceModel(
    id: id,
    invoiceNumber: 'INV00012',
    clientName: 'Acme',
    invoiceDate: now,
    dueDate: dueDate,
    subtotal: 5000,
    grandTotal: 5000,
    paidAmount: paid,
    status: status,
    createdAt: now,
    updatedAt: now,
  );

  test('default schedule uses the outstanding balance and three repeats', () {
    final plan = computeReminderSchedule(
      [invoice(dueDate: due, status: InvoiceStatus.partiallyPaid, paid: 500)],
      settings,
      now,
    );
    expect(plan.map((reminder) => reminder.time), [
      DateTime.utc(2026, 3, 1, 9),
      DateTime.utc(2026, 3, 2, 9),
      DateTime.utc(2026, 3, 9, 9),
      DateTime.utc(2026, 3, 16, 9),
      DateTime.utc(2026, 3, 23, 9),
    ]);
    expect(plan[1].text, 'INV00012 · ₹4,500 due from Acme today');
    expect(plan[4].text, endsWith('21 days overdue'));
    expect(plan.map((reminder) => reminder.id).toSet(), hasLength(5));
  });

  test('Hindi changes the notification text and preserves its ID and time', () {
    final invoices = [invoice(dueDate: due)];
    final english = computeReminderSchedule(invoices, settings, now);
    final hindi = computeReminderSchedule(
      invoices,
      settings,
      now,
      l10n: AppLocalizationsHi(),
    );
    expect(hindi.first.text, 'INV00012 · Acme से ₹5,000 बकाया कल');
    expect(
      hindi.map((item) => (item.id, item.time)),
      english.map((item) => (item.id, item.time)),
    );
  });

  test(
    'off options leave only the due date and the master switch skips all',
    () {
      final invoices = [invoice(dueDate: due)];
      final plan = computeReminderSchedule(
        invoices,
        settings.copyWith(
          beforeDue: BeforeDueReminder.off,
          overdue: OverdueReminder.off,
        ),
        now,
      );
      expect(plan.single.time, DateTime.utc(2026, 3, 2, 9));
      expect(
        computeReminderSchedule(invoices, const ReminderSettings(), now),
        isEmpty,
      );
    },
  );

  test('ignores paid, settled, and undated invoices', () {
    expect(
      computeReminderSchedule(
        [
          invoice(id: 'paid', dueDate: due, status: InvoiceStatus.paid),
          invoice(id: 'settled', dueDate: due, paid: 5000),
          invoice(id: 'undated'),
        ],
        settings,
        now,
      ),
      isEmpty,
    );
  });

  test('overdue installments keep their IDs and skip elapsed dates', () {
    final invoices = [
      invoice(dueDate: due),
      invoice(id: 'other', dueDate: due),
    ];
    final custom = settings.copyWith(
      beforeDue: BeforeDueReminder.threeDays,
      overdue: OverdueReminder.threeDays,
    );
    final original = computeReminderSchedule(
      invoices,
      custom,
      DateTime.utc(2026, 2, 26),
    );
    expect(original.first.time, DateTime.utc(2026, 2, 27, 9));
    final cutoff = DateTime.utc(2026, 3, 5, 9);
    expect(
      computeReminderSchedule(invoices.reversed, custom, cutoff),
      original.where((reminder) => reminder.time.isAfter(cutoff)),
    );
    expect(original.map((reminder) => reminder.id).toSet(), hasLength(10));
  });

  test('calendar slots keep the same local hour across DST', () {
    tz_data.initializeTimeZones();
    final zone = tz.getLocation('America/New_York');
    final plan = computeReminderSchedule(
      [invoice(dueDate: DateTime(2026, 3, 8))],
      settings,
      tz.TZDateTime(zone, 2026, 3, 6),
    );
    expect(plan[0].time, tz.TZDateTime(zone, 2026, 3, 7, 9));
    expect(plan[1].time, tz.TZDateTime(zone, 2026, 3, 8, 9));
    expect(plan[1].time.difference(plan[0].time), const Duration(hours: 23));
  });
}
