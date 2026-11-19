/// One line on an invoice or an estimate.
///
/// [unitPrice] is the price as entered. [discountRate] is a per-line discount
/// in percent. [total] is the line's net amount (quantity × unit price, less
/// the line discount), before any tax. Tax is never folded into [unitPrice].
///
/// [taxRate] is the line's own full tax rate in percent. `null` means the line
/// uses the document's tax rate; `0` means the line is exempt.
class LineItemModel {
  final String id;

  /// Parent document id: the invoice id, or the estimate id for estimate lines.
  final String invoiceId;
  final String description;
  final double quantity;
  final double unitPrice;
  final double total;
  final int sortOrder;
  final double discountRate;
  final double? taxRate;
  final String? hsnSac;
  final String? unit;

  const LineItemModel({
    required this.id,
    required this.invoiceId,
    required this.description,
    required this.quantity,
    required this.unitPrice,
    required this.total,
    this.sortOrder = 0,
    this.discountRate = 0,
    this.taxRate,
    this.hsnSac,
    this.unit,
  });

  /// Builds a line from what the user entered, computing [total].
  factory LineItemModel.create({
    required String id,
    required String invoiceId,
    required String description,
    required double quantity,
    required double unitPrice,
    double discountRate = 0,
    double? taxRate,
    String? hsnSac,
    String? unit,
    int sortOrder = 0,
  }) {
    return LineItemModel(
      id: id,
      invoiceId: invoiceId,
      description: description,
      quantity: quantity,
      unitPrice: unitPrice,
      total: netAmountFor(quantity, unitPrice, discountRate),
      sortOrder: sortOrder,
      discountRate: discountRate,
      taxRate: taxRate,
      hsnSac: hsnSac,
      unit: unit,
    );
  }

  /// Net line amount: quantity × price less the line discount, never negative.
  static double netAmountFor(double quantity, double unitPrice, double discountRate) {
    final base = quantity * unitPrice;
    final discount = (base * discountRate / 100).clamp(0.0, base.abs());
    final net = base - discount;
    return net < 0 ? 0 : net;
  }

  double get baseAmount => quantity * unitPrice;
  double get lineDiscountAmount => baseAmount - total;
  bool get hasOwnTaxRate => taxRate != null;

  factory LineItemModel.fromMap(Map<String, dynamic> map) {
    return LineItemModel(
      id: map['id'] as String,
      // Estimate lines are stored with `estimate_id`; invoice lines with
      // `invoice_id`. The model carries either as its parent document id.
      invoiceId: (map['invoice_id'] ?? map['estimate_id'] ?? '') as String,
      description: map['description'] as String,
      quantity: (map['quantity'] as num).toDouble(),
      unitPrice: (map['unit_price'] as num).toDouble(),
      total: (map['total'] as num).toDouble(),
      sortOrder: map['sort_order'] as int? ?? 0,
      discountRate: (map['discount_rate'] as num? ?? 0).toDouble(),
      taxRate: (map['tax_rate'] as num?)?.toDouble(),
      hsnSac: map['hsn_sac'] as String?,
      unit: map['unit'] as String?,
    );
  }

  /// Row for the `line_items` table.
  Map<String, dynamic> toMap() => _toMap('invoice_id');

  /// Row for the `estimate_line_items` table.
  Map<String, dynamic> toEstimateMap() => _toMap('estimate_id');

  Map<String, dynamic> _toMap(String parentColumn) {
    return {
      'id': id,
      parentColumn: invoiceId,
      'description': description,
      'quantity': quantity,
      'unit_price': unitPrice,
      'total': total,
      'sort_order': sortOrder,
      'discount_rate': discountRate,
      'tax_rate': taxRate,
      'hsn_sac': hsnSac,
      'unit': unit,
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
    double? discountRate,
    double? taxRate,
    bool clearTaxRate = false,
    String? hsnSac,
    String? unit,
  }) {
    return LineItemModel(
      id: id ?? this.id,
      invoiceId: invoiceId ?? this.invoiceId,
      description: description ?? this.description,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      total: total ?? this.total,
      sortOrder: sortOrder ?? this.sortOrder,
      discountRate: discountRate ?? this.discountRate,
      taxRate: clearTaxRate ? null : (taxRate ?? this.taxRate),
      hsnSac: hsnSac ?? this.hsnSac,
      unit: unit ?? this.unit,
    );
  }

  @override
  String toString() =>
      'LineItemModel(description: $description, qty: $quantity, price: $unitPrice)';
}
