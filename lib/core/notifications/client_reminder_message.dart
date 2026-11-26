import 'package:intl/intl.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../l10n/gen/app_localizations_en.dart';

import '../../features/invoices/models/invoice_model.dart';
import 'reminder_schedule.dart';

String buildClientReminder({
  required InvoiceModel invoice,
  required DateTime now,
  required String businessName,
  String? upiId,
  AppLocalizations? l10n,
}) {
  final strings = l10n ?? AppLocalizationsEn('en_US');
  final client = invoice.clientName.trim();
  final balance = formatReminderBalance(invoice);
  final due = invoice.dueDate;
  final timing = due == null ? '' : _describeDueDate(due, now, strings);
  final upi = upiId?.trim();
  final sender = businessName.trim();
  return [
    client.isEmpty ? strings.clientGreeting : strings.clientGreetingByName(client),
    strings.clientReminderOutstanding(balance, invoice.invoiceNumber, timing),
    if (upi != null && upi.isNotEmpty) strings.clientReminderUpi(upi),
    strings.clientReminderAlreadyPaid,
    [strings.clientReminderThanks, if (sender.isNotEmpty) sender].join('\n'),
  ].join('\n\n');
}

String _describeDueDate(DateTime due, DateTime now, AppLocalizations l10n) {
  final dueDay = DateTime.utc(due.year, due.month, due.day);
  final today = DateTime.utc(now.year, now.month, now.day);
  final daysOverdue = today.difference(dueDay).inDays;
  final date = DateFormat('d MMM yyyy', l10n.localeName).format(due);
  if (daysOverdue > 0) {
    return l10n.clientReminderOverdue(date, l10n.daysCount(daysOverdue));
  }
  if (daysOverdue == 0) return l10n.clientReminderDueToday(date);
  return l10n.clientReminderDueOn(date);
}

/// wa.me needs an international number without punctuation or a leading +.
/// A ten-digit Indian mobile number can use the invoice currency as a hint.
String? normalizeWhatsAppPhone(String? phone, {required String currency}) {
  final input = phone?.trim() ?? '';
  if (!RegExp(r'^\+?[0-9() .-]+$').hasMatch(input)) return null;
  var digits = input.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.startsWith('00')) {
    digits = digits.substring(2);
  } else if (!input.startsWith('+') && currency.toUpperCase() == 'INR') {
    if (RegExp(r'^0[6-9][0-9]{9}$').hasMatch(digits)) {
      digits = digits.substring(1);
    }
    if (RegExp(r'^[6-9][0-9]{9}$').hasMatch(digits)) digits = '91$digits';
  }
  if (!RegExp(r'^[1-9][0-9]{7,14}$').hasMatch(digits)) return null;
  // Ten unprefixed digits are ambiguous outside the Indian mobile case.
  if (!input.startsWith('+') &&
      !input.startsWith('00') &&
      digits.length == 10) {
    return null;
  }
  return digits;
}
