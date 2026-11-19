/// One payment received against an invoice. An invoice's paid amount is the
/// sum of its payments.
class PaymentModel {
  final String id;
  final String invoiceId;
  final double amount;
  final DateTime paidOn;
  final String? method;
  final String? note;
  final DateTime createdAt;

  const PaymentModel({
    required this.id,
    required this.invoiceId,
    required this.amount,
    required this.paidOn,
    this.method,
    this.note,
    required this.createdAt,
  });

  factory PaymentModel.fromMap(Map<String, dynamic> map) => PaymentModel(
        id: map['id'] as String,
        invoiceId: map['invoice_id'] as String,
        amount: (map['amount'] as num).toDouble(),
        paidOn: DateTime.fromMillisecondsSinceEpoch(map['paid_on'] as int),
        method: map['method'] as String?,
        note: map['note'] as String?,
        createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'invoice_id': invoiceId,
        'amount': amount,
        'paid_on': paidOn.millisecondsSinceEpoch,
        'method': method,
        'note': note,
        'created_at': createdAt.millisecondsSinceEpoch,
      };
}
