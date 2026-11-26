import 'package:flutter_test/flutter_test.dart';
import 'package:invoice/core/notifications/client_reminder_message.dart';
import 'package:invoice/features/invoices/models/invoice_model.dart';

void main() {
  final today = DateTime(2026, 3, 9, 8);
  InvoiceModel invoice({DateTime? dueDate, String currency = 'INR'}) =>
      InvoiceModel(
        id: 'invoice-12',
        invoiceNumber: 'INV00012',
        clientName: '  Acme  ',
        invoiceDate: today,
        dueDate: dueDate,
        subtotal: 5000,
        grandTotal: 5000,
        paidAmount: 499.75,
        currency: currency,
        status: InvoiceStatus.partiallyPaid,
        createdAt: today,
        updatedAt: today,
      );

  test('uses the remaining amount, due date, UPI, and named sender', () {
    final message = buildClientReminder(
      invoice: invoice(dueDate: DateTime(2026, 3, 8, 22)),
      now: today,
      businessName: 'Northstar Studio ',
      upiId: ' northstar@upi ',
    );
    expect(message, startsWith('Hi Acme,'));
    expect(message, contains('₹4,500.25 is outstanding on invoice INV00012'));
    expect(message, contains('8 Mar 2026 (1 day overdue)'));
    expect(message, contains('UPI to northstar@upi.'));
    expect(message, endsWith('Thanks,\nNorthstar Studio'));
  });

  test('formats other currencies and handles a blank UPI ID', () {
    final message = buildClientReminder(
      invoice: invoice(dueDate: DateTime(2026, 3, 9), currency: 'USD'),
      now: today,
      businessName: 'Northstar Studio',
      upiId: ' ',
    );
    expect(message, contains(r'$4,500.25'));
    expect(message, contains('due today (9 Mar 2026)'));
    expect(message, isNot(contains('UPI')));
  });

  test('handles future and undated invoices', () {
    String messageFor(DateTime? due) => buildClientReminder(
      invoice: invoice(dueDate: due),
      now: today,
      businessName: 'Northstar Studio',
    );
    expect(messageFor(DateTime(2026, 3, 11)), contains('due on 11 Mar 2026'));
    expect(messageFor(null), isNot(contains('due on')));
  });

  test('normalizes WhatsApp numbers and rejects ambiguous phone data', () {
    expect(
      normalizeWhatsAppPhone('+44 (7700) 900123', currency: 'GBP'),
      '447700900123',
    );
    expect(
      normalizeWhatsAppPhone('0044 7700 900123', currency: 'GBP'),
      '447700900123',
    );
    expect(
      normalizeWhatsAppPhone('098765 43210', currency: 'INR'),
      '919876543210',
    );
    expect(
      normalizeWhatsAppPhone('98765-43210', currency: 'INR'),
      '919876543210',
    );
    expect(normalizeWhatsAppPhone('415 555 0139', currency: 'USD'), isNull);
    expect(
      normalizeWhatsAppPhone('+1 415 555 0139 ext 12', currency: 'USD'),
      isNull,
    );
    expect(normalizeWhatsAppPhone(null, currency: 'INR'), isNull);
  });
}
