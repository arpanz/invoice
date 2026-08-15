import 'package:flutter/material.dart';
import '../../invoices/models/invoice_model.dart';
import '../../invoices/models/line_item_model.dart';

enum EstimateStatus {
  pending,
  accepted,
  declined,
  converted,
}

extension EstimateStatusExtension on EstimateStatus {
  String get label {
    switch (this) {
      case EstimateStatus.pending:
        return 'Pending';
      case EstimateStatus.accepted:
        return 'Accepted';
      case EstimateStatus.declined:
        return 'Declined';
      case EstimateStatus.converted:
        return 'Converted';
    }
  }

  String get value {
    switch (this) {
      case EstimateStatus.pending:
        return 'pending';
      case EstimateStatus.accepted:
        return 'accepted';
      case EstimateStatus.declined:
        return 'declined';
      case EstimateStatus.converted:
        return 'converted';
    }
  }

  Color get color {
    switch (this) {
      case EstimateStatus.pending:
        return const Color(0xFFF59E0B); // Amber
      case EstimateStatus.accepted:
        return const Color(0xFF10B981); // Emerald Green
      case EstimateStatus.declined:
        return const Color(0xFFEF4444); // Red
      case EstimateStatus.converted:
        return const Color(0xFF3B82F6); // Blue
    }
  }

  Color get backgroundColor {
    switch (this) {
      case EstimateStatus.pending:
        return const Color(0xFFFEF3C7);
      case EstimateStatus.accepted:
        return const Color(0xFFD1FAE5);
      case EstimateStatus.declined:
        return const Color(0xFFFEE2E2);
      case EstimateStatus.converted:
        return const Color(0xFFDBEAFE);
    }
  }

  IconData get icon {
    switch (this) {
      case EstimateStatus.pending:
        return Icons.schedule_rounded;
      case EstimateStatus.accepted:
        return Icons.check_circle_rounded;
      case EstimateStatus.declined:
        return Icons.cancel_rounded;
      case EstimateStatus.converted:
        return Icons.receipt_long_rounded;
    }
  }

  static EstimateStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'accepted':
        return EstimateStatus.accepted;
      case 'declined':
        return EstimateStatus.declined;
      case 'converted':
        return EstimateStatus.converted;
      case 'pending':
      default:
        return EstimateStatus.pending;
    }
  }
}

class EstimateModel {
  final String id;
  final String estimateNumber;
  final String? clientId;
  final String clientName;
  final String? clientEmail;
  final String? clientPhone;
  final String? clientAddress;
  final String? clientGstin;
  final DateTime estimateDate;
  final DateTime? expiryDate;
  final double subtotal;
  final DiscountType discountType;
  final double discountValue;
  final double discountAmount;
  final double sgstRate;
  final double cgstRate;
  final double igstRate;
  final double taxAmount;
  final double grandTotal;
  final EstimateStatus status;
  final String? convertedInvoiceId;
  final String? notes;
  final String currency;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<LineItemModel> lineItems;

  const EstimateModel({
    required this.id,
    required this.estimateNumber,
    this.clientId,
    required this.clientName,
    this.clientEmail,
    this.clientPhone,
    this.clientAddress,
    this.clientGstin,
    required this.estimateDate,
    this.expiryDate,
    required this.subtotal,
    this.discountType = DiscountType.none,
    this.discountValue = 0,
    this.discountAmount = 0,
    this.sgstRate = 0,
    this.cgstRate = 0,
    this.igstRate = 0,
    this.taxAmount = 0,
    required this.grandTotal,
    this.status = EstimateStatus.pending,
    this.convertedInvoiceId,
    this.notes,
    this.currency = 'INR',
    required this.createdAt,
    required this.updatedAt,
    this.lineItems = const [],
  });

  /// True when the estimate is still pending and the valid-until date has passed.
  bool get isExpired =>
      status == EstimateStatus.pending &&
      expiryDate != null &&
      expiryDate!.isBefore(DateTime.now());

  /// True when this estimate can be converted to an invoice.
  bool get canConvert => status != EstimateStatus.converted;

  factory EstimateModel.fromMap(
    Map<String, dynamic> map, {
    List<LineItemModel>? items,
  }) {
    return EstimateModel(
      id: map['id'] as String,
      estimateNumber: map['estimate_number'] as String,
      clientId: map['client_id'] as String?,
      clientName: map['client_name'] as String,
      clientEmail: map['client_email'] as String?,
      clientPhone: map['client_phone'] as String?,
      clientAddress: map['client_address'] as String?,
      clientGstin: map['client_gstin'] as String?,
      estimateDate: DateTime.fromMillisecondsSinceEpoch(
        map['estimate_date'] as int,
      ),
      expiryDate: map['expiry_date'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['expiry_date'] as int)
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
      grandTotal: (map['grand_total'] as num).toDouble(),
      status: EstimateStatusExtension.fromString(
        map['status'] as String? ?? 'pending',
      ),
      convertedInvoiceId: map['converted_invoice_id'] as String?,
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
      'estimate_number': estimateNumber,
      'client_id': clientId,
      'client_name': clientName,
      'client_email': clientEmail,
      'client_phone': clientPhone,
      'client_address': clientAddress,
      'client_gstin': clientGstin,
      'estimate_date': estimateDate.millisecondsSinceEpoch,
      'expiry_date': expiryDate?.millisecondsSinceEpoch,
      'subtotal': subtotal,
      'discount_type': discountType.name,
      'discount_value': discountValue,
      'discount_amount': discountAmount,
      'sgst_rate': sgstRate,
      'cgst_rate': cgstRate,
      'igst_rate': igstRate,
      'tax_amount': taxAmount,
      'grand_total': grandTotal,
      'status': status.value,
      'converted_invoice_id': convertedInvoiceId,
      'notes': notes,
      'currency': currency,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  EstimateModel copyWith({
    String? id,
    String? estimateNumber,
    String? clientId,
    String? clientName,
    String? clientEmail,
    String? clientPhone,
    String? clientAddress,
    String? clientGstin,
    DateTime? estimateDate,
    DateTime? expiryDate,
    double? subtotal,
    DiscountType? discountType,
    double? discountValue,
    double? discountAmount,
    double? sgstRate,
    double? cgstRate,
    double? igstRate,
    double? taxAmount,
    double? grandTotal,
    EstimateStatus? status,
    String? convertedInvoiceId,
    String? notes,
    String? currency,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<LineItemModel>? lineItems,
  }) {
    return EstimateModel(
      id: id ?? this.id,
      estimateNumber: estimateNumber ?? this.estimateNumber,
      clientId: clientId ?? this.clientId,
      clientName: clientName ?? this.clientName,
      clientEmail: clientEmail ?? this.clientEmail,
      clientPhone: clientPhone ?? this.clientPhone,
      clientAddress: clientAddress ?? this.clientAddress,
      clientGstin: clientGstin ?? this.clientGstin,
      estimateDate: estimateDate ?? this.estimateDate,
      expiryDate: expiryDate ?? this.expiryDate,
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
      convertedInvoiceId: convertedInvoiceId ?? this.convertedInvoiceId,
      notes: notes ?? this.notes,
      currency: currency ?? this.currency,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lineItems: lineItems ?? this.lineItems,
    );
  }

  /// Converts this Estimate into an InvoiceModel with a new invoice number.
  InvoiceModel toInvoiceModel({
    required String newInvoiceId,
    required String newInvoiceNumber,
    DateTime? invoiceDate,
    DateTime? dueDate,
  }) {
    final now = DateTime.now();
    return InvoiceModel(
      id: newInvoiceId,
      invoiceNumber: newInvoiceNumber,
      clientId: clientId,
      clientName: clientName,
      clientEmail: clientEmail,
      clientPhone: clientPhone,
      clientAddress: clientAddress,
      clientGstin: clientGstin,
      invoiceDate: invoiceDate ?? now,
      dueDate: dueDate ?? now.add(const Duration(days: 7)),
      subtotal: subtotal,
      discountType: discountType,
      discountValue: discountValue,
      discountAmount: discountAmount,
      sgstRate: sgstRate,
      cgstRate: cgstRate,
      igstRate: igstRate,
      taxAmount: taxAmount,
      grandTotal: grandTotal,
      status: InvoiceStatus.unpaid,
      notes: notes,
      currency: currency,
      createdAt: now,
      updatedAt: now,
      lineItems: lineItems,
    );
  }

  static DiscountType _discountTypeFromString(String val) {
    switch (val.toLowerCase()) {
      case 'percentage':
        return DiscountType.percentage;
      case 'flat':
        return DiscountType.flat;
      default:
        return DiscountType.none;
    }
  }
}
