class LineItemModel {
  final String id;
  final String invoiceId;
  final String description;
  final double quantity;
  final double unitPrice;
  final double total;
  final int sortOrder;

  const LineItemModel({
    required this.id,
    required this.invoiceId,
    required this.description,
    required this.quantity,
    required this.unitPrice,
    required this.total,
    this.sortOrder = 0,
  });

  factory LineItemModel.fromMap(Map<String, dynamic> map) {
    return LineItemModel(
      id: map['id'] as String,
      invoiceId: map['invoice_id'] as String,
      description: map['description'] as String,
      quantity: (map['quantity'] as num).toDouble(),
      unitPrice: (map['unit_price'] as num).toDouble(),
      total: (map['total'] as num).toDouble(),
      sortOrder: map['sort_order'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'invoice_id': invoiceId,
      'description': description,
      'quantity': quantity,
      'unit_price': unitPrice,
      'total': total,
      'sort_order': sortOrder,
    };
  }

  LineItemModel copyWith({
    String? id,
    String? invoiceId,
    String? description,
    double? quantity,
    double? unitPrice,
    double? total,
    int? sortOrder,
  }) {
    return LineItemModel(
      id: id ?? this.id,
      invoiceId: invoiceId ?? this.invoiceId,
      description: description ?? this.description,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      total: total ?? this.total,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  String toString() =>
      'LineItemModel(description: $description, qty: $quantity, price: $unitPrice)';
}
