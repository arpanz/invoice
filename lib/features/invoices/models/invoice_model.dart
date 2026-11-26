import 'dart:convert';

import 'document_custom_field.dart';
import 'line_item_model.dart';

enum InvoiceStatus { unpaid, partiallyPaid, paid, overdue }

enum DiscountType { none, percentage, flat }

extension InvoiceStatusExtension on InvoiceStatus {
  String get label {
    switch (this) {
      case InvoiceStatus.unpaid:
        return 'Unpaid';
      case InvoiceStatus.partiallyPaid:
        return 'Partially Paid';
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
      case InvoiceStatus.partiallyPaid:
        return 'partially_paid';
      case InvoiceStatus.paid:
        return 'paid';
      case InvoiceStatus.overdue:
        return 'overdue';
    }
  }

  static InvoiceStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'paid':
        return InvoiceStatus.paid;
      case 'partially_paid':
      case 'partiallypaid':
      case 'partial':
        return InvoiceStatus.partiallyPaid;
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

  /// Shipping or delivery charge, included in [grandTotal].
  final double shipping;
  final double grandTotal;
  final double paidAmount;
  final InvoiceStatus status;
  final String? notes;
  final List<DocumentCustomField> customFields;
  final String currency;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<LineItemModel> lineItems;
  final List<String> attachments;

  /// JSON of the business profile as it was when this invoice was last saved
  /// from the editor. Rendering uses it so later profile edits never rewrite
  /// past invoices. Null for invoices saved before this existed.
  final String? issuerSnapshot;

  /// When the invoice was marked as sent; null if not sent.
  final DateTime? sentAt;

  /// True when the invoice is unpaid or partially paid and the due date has passed.
  /// Overdue is derived, never stored: there is a balance and the due date
  /// (end of that day) has passed. A status manually set to overdue counts
  /// too while there is a balance.
  bool get isOverdue {
    if (status == InvoiceStatus.paid || balanceDue <= 0.009) return false;
    if (status == InvoiceStatus.overdue) return true;
    if (dueDate == null) return false;
    final endOfDue = DateTime(dueDate!.year, dueDate!.month, dueDate!.day).add(const Duration(days: 1));
    return DateTime.now().isAfter(endOfDue);
  }

  /// The status to show: [InvoiceStatus.overdue] when [isOverdue], else the
  /// stored status.
  InvoiceStatus get effectiveStatus => isOverdue ? InvoiceStatus.overdue : status;

  /// The payment status that matches [paid] against [total]. Overdue is
  /// never stored; it is derived when shown (see [isOverdue]).
  static InvoiceStatus paymentStatusFor(double paid, double total) {
    // Paid once the total is covered (also when the total is 0 but money
    // was received, e.g. after the invoice was edited down).
    if (paid >= total - 0.005 && (total > 0.005 || paid > 0.005)) return InvoiceStatus.paid;
    if (paid > 0.005) return InvoiceStatus.partiallyPaid;
    return InvoiceStatus.unpaid;
  }

  /// Remaining balance to be paid.
  double get balanceDue => (grandTotal - paidAmount).clamp(0, double.infinity);

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
    this.shipping = 0,
    required this.grandTotal,
    this.paidAmount = 0,
    this.status = InvoiceStatus.unpaid,
    this.notes,
    this.customFields = const [],
    this.currency = 'INR',
    required this.createdAt,
    required this.updatedAt,
    this.lineItems = const [],
    this.attachments = const [],
    this.issuerSnapshot,
    this.sentAt,
  });

  factory InvoiceModel.fromMap(
    Map<String, dynamic> map, {
    List<LineItemModel>? items,
  }) {
    final status = InvoiceStatusExtension.fromString(
      map['status'] as String? ?? 'unpaid',
    );
    final grandTotal = (map['grand_total'] as num).toDouble();
    final rawPaidAmount = map['paid_amount'] as num?;
    final paidAmount = rawPaidAmount != null
        ? rawPaidAmount.toDouble()
        : (status == InvoiceStatus.paid ? grandTotal : 0.0);

    return InvoiceModel(
      id: map['id'] as String,
      invoiceNumber: map['invoice_number'] as String,
      clientId: map['client_id'] as String?,
      clientName: map['client_name'] as String,
      clientEmail: map['client_email'] as String?,
      clientPhone: map['client_phone'] as String?,
      clientAddress: map['client_address'] as String?,
      clientGstin: map['client_gstin'] as String?,
      invoiceDate: DateTime.fromMillisecondsSinceEpoch(
        map['invoice_date'] as int,
      ),
      dueDate: map['due_date'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['due_date'] as int)
          : null,
      subtotal: (map['subtotal'] as num).toDouble(),
      discountType: _discountTypeFromString(
        map['discount_type'] as String? ?? 'none',
      ),
      discountValue: (map['discount_value'] as num? ?? 0).toDouble(),
      discountAmount: (map['discount_amount'] as num? ?? 0).toDouble(),
      sgstRate: (map['sgst_rate'] as num? ?? 0).toDouble(),
      cgstRate: (map['cgst_rate'] as num? ?? 0).toDouble(),
      igstRate: (map['igst_rate'] as num? ?? 0).toDouble(),
      taxAmount: (map['tax_amount'] as num? ?? 0).toDouble(),
      shipping: (map['shipping'] as num? ?? 0).toDouble(),
      grandTotal: grandTotal,
      paidAmount: paidAmount,
      status: status,
      notes: map['notes'] as String?,
      customFields: DocumentCustomField.decode(map['custom_fields']),
      currency: map['currency'] as String? ?? 'INR',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
      lineItems: items ?? [],
      attachments: decodeAttachmentPaths(map['attachments']),
      issuerSnapshot: map['issuer_snapshot'] as String?,
      sentAt: map['sent_at'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(map['sent_at'] as int),
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
      'shipping': shipping,
      'grand_total': grandTotal,
      'paid_amount': paidAmount,
      'status': status.value,
      'notes': notes,
      'custom_fields': DocumentCustomField.encode(customFields),
      'currency': currency,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
      'attachments': jsonEncode(attachments),
      'issuer_snapshot': issuerSnapshot,
      'sent_at': sentAt?.millisecondsSinceEpoch,
    };
  }

  static List<String> decodeAttachmentPaths(Object? stored) {
    if (stored is! String || stored.isEmpty) return const [];
    try {
      final paths = jsonDecode(stored);
      if (paths is List) {
        return List.unmodifiable(paths.whereType<String>().where((path) => path.isNotEmpty));
      }
    } on FormatException {
      return const [];
    }
    return const [];
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
    double? shipping,
    double? grandTotal,
    double? paidAmount,
    InvoiceStatus? status,
    String? notes,
    List<DocumentCustomField>? customFields,
    String? currency,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<LineItemModel>? lineItems,
    List<String>? attachments,
    String? issuerSnapshot,
    DateTime? sentAt,
    bool clearSentAt = false,
    bool clearDueDate = false,
    bool clearNotes = false,
    bool clearClientId = false,
  }) {
    return InvoiceModel(
      id: id ?? this.id,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      clientId: clearClientId ? null : (clientId ?? this.clientId),
      clientName: clientName ?? this.clientName,
      clientEmail: clientEmail ?? this.clientEmail,
      clientPhone: clientPhone ?? this.clientPhone,
      clientAddress: clientAddress ?? this.clientAddress,
      clientGstin: clientGstin ?? this.clientGstin,
      invoiceDate: invoiceDate ?? this.invoiceDate,
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      subtotal: subtotal ?? this.subtotal,
      discountType: discountType ?? this.discountType,
      discountValue: discountValue ?? this.discountValue,
      discountAmount: discountAmount ?? this.discountAmount,
      sgstRate: sgstRate ?? this.sgstRate,
      cgstRate: cgstRate ?? this.cgstRate,
      igstRate: igstRate ?? this.igstRate,
      taxAmount: taxAmount ?? this.taxAmount,
      shipping: shipping ?? this.shipping,
      grandTotal: grandTotal ?? this.grandTotal,
      paidAmount: paidAmount ?? this.paidAmount,
      status: status ?? this.status,
      notes: clearNotes ? null : (notes ?? this.notes),
      customFields: customFields ?? this.customFields,
      currency: currency ?? this.currency,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lineItems: lineItems ?? this.lineItems,
      attachments: attachments ?? this.attachments,
      issuerSnapshot: issuerSnapshot ?? this.issuerSnapshot,
      sentAt: clearSentAt ? null : (sentAt ?? this.sentAt),
    );
  }

  @override
  String toString() =>
      'InvoiceModel(invoiceNumber: $invoiceNumber, total: $grandTotal, paid: $paidAmount, status: ${status.value})';
}
