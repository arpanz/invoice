import 'line_item_model.dart';

enum InvoiceStatus { unpaid, paid, overdue }

enum DiscountType { none, percentage, flat }

extension InvoiceStatusExtension on InvoiceStatus {
  String get label {
    switch (this) {
      case InvoiceStatus.unpaid:
        return 'Unpaid';
      case InvoiceStatus.paid:
        return 'Paid';
      case InvoiceStatus.overdue:
        return 'Overdue';
    }
  }

  String get value {
    switch (this) {
      case InvoiceStatus.unpaid:
        return 'unpaid';
      case InvoiceStatus.paid:
        return 'paid';
      case InvoiceStatus.overdue:
        return 'overdue';
    }
  }

  static InvoiceStatus fromString(String value) {
    switch (value) {
      case 'paid':
        return InvoiceStatus.paid;
      case 'overdue':
        return InvoiceStatus.overdue;
      default:
        return InvoiceStatus.unpaid;
    }
  }
}

class InvoiceModel {
  final String id;
  final String invoiceNumber;
  final String? clientId;
  final String clientName;
  final String? clientEmail;
  final String? clientPhone;
  final String? clientAddress;
  final String? clientGstin;
  final DateTime invoiceDate;
  final DateTime? dueDate;
  final double subtotal;
  final DiscountType discountType;
  final double discountValue;
  final double discountAmount;
  final double sgstRate;
  final double cgstRate;
  final double igstRate;
  final double taxAmount;
  final double grandTotal;
  final InvoiceStatus status;
  final String? notes;
  final String currency;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<LineItemModel> lineItems;

  const InvoiceModel({
    required this.id,
    required this.invoiceNumber,
    this.clientId,
    required this.clientName,
    this.clientEmail,
    this.clientPhone,
    this.clientAddress,
    this.clientGstin,
    required this.invoiceDate,
    this.dueDate,
    required this.subtotal,
    this.discountType = DiscountType.none,
    this.discountValue = 0,
    this.discountAmount = 0,
    this.sgstRate = 0,
    this.cgstRate = 0,
    this.igstRate = 0,
    this.taxAmount = 0,
    required this.grandTotal,
    this.status = InvoiceStatus.unpaid,
    this.notes,
    this.currency = 'INR',
    required this.createdAt,
    required this.updatedAt,
    this.lineItems = const [],
  });

  factory InvoiceModel.fromMap(Map<String, dynamic> map, {List<LineItemModel>? items}) {
    return InvoiceModel(
      id: map['id'] as String,
      invoiceNumber: map['invoice_number'] as String,
      clientId: map['client_id'] as String?,
      clientName: map['client_name'] as String,
      clientEmail: map['client_email'] as String?,
      clientPhone: map['client_phone'] as String?,
      clientAddress: map['client_address'] as String?,
      clientGstin: map['client_gstin'] as String?,
      invoiceDate: DateTime.fromMillisecondsSinceEpoch(map['invoice_date'] as int),
      dueDate: map['due_date'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['due_date'] as int)
          : null,
      subtotal: (map['subtotal'] as num).toDouble(),
      discountType: _discountTypeFromString(map['discount_type'] as String? ?? 'none'),
      discountValue: (map['discount_value'] as num? ?? 0).toDouble(),
      discountAmount: (map['discount_amount'] as num? ?? 0).toDouble(),
      sgstRate: (map['sgst_rate'] as num? ?? 0).toDouble(),
      cgstRate: (map['cgst_rate'] as num? ?? 0).toDouble(),
      igstRate: (map['igst_rate'] as num? ?? 0).toDouble(),
      taxAmount: (map['tax_amount'] as num? ?? 0).toDouble(),
      grandTotal: (map['grand_total'] as num).toDouble(),
      status: InvoiceStatusExtension.fromString(map['status'] as String? ?? 'unpaid'),
      notes: map['notes'] as String?,
      currency: map['currency'] as String? ?? 'INR',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
      lineItems: items ?? [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'invoice_number': invoiceNumber,
      'client_id': clientId,
      'client_name': clientName,
      'client_email': clientEmail,
      'client_phone': clientPhone,
      'client_address': clientAddress,
      'client_gstin': clientGstin,
      'invoice_date': invoiceDate.millisecondsSinceEpoch,
      'due_date': dueDate?.millisecondsSinceEpoch,
      'subtotal': subtotal,
      'discount_type': _discountTypeToString(discountType),
      'discount_value': discountValue,
      'discount_amount': discountAmount,
      'sgst_rate': sgstRate,
      'cgst_rate': cgstRate,
      'igst_rate': igstRate,
      'tax_amount': taxAmount,
      'grand_total': grandTotal,
      'status': status.value,
      'notes': notes,
      'currency': currency,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  static DiscountType _discountTypeFromString(String value) {
    switch (value) {
      case 'percentage':
        return DiscountType.percentage;
      case 'flat':
        return DiscountType.flat;
      default:
        return DiscountType.none;
    }
  }

  static String _discountTypeToString(DiscountType type) {
    switch (type) {
      case DiscountType.percentage:
        return 'percentage';
      case DiscountType.flat:
        return 'flat';
      default:
        return 'none';
    }
  }

  InvoiceModel copyWith({
    String? id,
    String? invoiceNumber,
    String? clientId,
    String? clientName,
    String? clientEmail,
    String? clientPhone,
    String? clientAddress,
    String? clientGstin,
    DateTime? invoiceDate,
    DateTime? dueDate,
    double? subtotal,
    DiscountType? discountType,
    double? discountValue,
    double? discountAmount,
    double? sgstRate,
    double? cgstRate,
    double? igstRate,
    double? taxAmount,
    double? grandTotal,
    InvoiceStatus? status,
    String? notes,
    String? currency,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<LineItemModel>? lineItems,
  }) {
    return InvoiceModel(
      id: id ?? this.id,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      clientId: clientId ?? this.clientId,
      clientName: clientName ?? this.clientName,
      clientEmail: clientEmail ?? this.clientEmail,
      clientPhone: clientPhone ?? this.clientPhone,
      clientAddress: clientAddress ?? this.clientAddress,
      clientGstin: clientGstin ?? this.clientGstin,
      invoiceDate: invoiceDate ?? this.invoiceDate,
      dueDate: dueDate ?? this.dueDate,
      subtotal: subtotal ?? this.subtotal,
      discountType: discountType ?? this.discountType,
      discountValue: discountValue ?? this.discountValue,
      discountAmount: discountAmount ?? this.discountAmount,
      sgstRate: sgstRate ?? this.sgstRate,
      cgstRate: cgstRate ?? this.cgstRate,
      igstRate: igstRate ?? this.igstRate,
      taxAmount: taxAmount ?? this.taxAmount,
      grandTotal: grandTotal ?? this.grandTotal,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      currency: currency ?? this.currency,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lineItems: lineItems ?? this.lineItems,
    );
  }

  bool get isOverdue {
    if (status == InvoiceStatus.paid) return false;
    if (dueDate == null) return false;
    return DateTime.now().isAfter(dueDate!);
  }

  @override
  String toString() =>
      'InvoiceModel(invoiceNumber: $invoiceNumber, total: $grandTotal, status: ${status.value})';
}
