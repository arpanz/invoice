class SavedItemModel {
  final String id;
  final String name;
  final String? description;
  final double unitPrice;
  final String unit;
  final String? hsnCode;
  final String? category;
  final bool isTaxable;
  final double taxRate; // Tax rate in percentage, e.g. 18.0 for 18%
  final double discountRate; // Item-level discount in percentage, e.g. 10.0 for 10%
  final double defaultQuantity;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SavedItemModel({
    required this.id,
    required this.name,
    this.description,
    required this.unitPrice,
    this.unit = 'pcs',
    this.hsnCode,
    this.category,
    this.isTaxable = true,
    this.taxRate = 0,
    this.discountRate = 0,
    this.defaultQuantity = 1,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Effective price per unit after discount
  double get discountedUnitPrice {
    if (discountRate <= 0) return unitPrice;
    final discount = (unitPrice * discountRate / 100).clamp(0, unitPrice);
    return unitPrice - discount;
  }

  /// Tax amount per unit
  double get unitTaxAmount {
    if (!isTaxable || taxRate <= 0) return 0;
    return discountedUnitPrice * taxRate / 100;
  }

  /// Net total per unit (price - discount + tax)
  double get netUnitPrice => discountedUnitPrice + unitTaxAmount;

  /// Total calculated for default quantity
  double get defaultTotal => netUnitPrice * defaultQuantity;

  factory SavedItemModel.fromMap(Map<String, dynamic> map) {
    return SavedItemModel(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String?,
      unitPrice: (map['unit_price'] as num).toDouble(),
      unit: map['unit'] as String? ?? 'pcs',
      hsnCode: map['hsn_code'] as String?,
      category: map['category'] as String?,
      isTaxable: (map['is_taxable'] as int? ?? 1) == 1,
      taxRate: (map['tax_rate'] as num? ?? 0).toDouble(),
      discountRate: (map['discount_rate'] as num? ?? 0).toDouble(),
      defaultQuantity: (map['default_quantity'] as num? ?? 1).toDouble(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'unit_price': unitPrice,
      'unit': unit,
      'hsn_code': hsnCode,
      'category': category,
      'is_taxable': isTaxable ? 1 : 0,
      'tax_rate': taxRate,
      'discount_rate': discountRate,
      'default_quantity': defaultQuantity,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  SavedItemModel copyWith({
    String? id,
    String? name,
    String? description,
    double? unitPrice,
    String? unit,
    String? hsnCode,
    String? category,
    bool? isTaxable,
    double? taxRate,
    double? discountRate,
    double? defaultQuantity,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SavedItemModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      unitPrice: unitPrice ?? this.unitPrice,
      unit: unit ?? this.unit,
      hsnCode: hsnCode ?? this.hsnCode,
      category: category ?? this.category,
      isTaxable: isTaxable ?? this.isTaxable,
      taxRate: taxRate ?? this.taxRate,
      discountRate: discountRate ?? this.discountRate,
      defaultQuantity: defaultQuantity ?? this.defaultQuantity,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() =>
      'SavedItemModel(name: $name, price: $unitPrice, disc: $discountRate%, tax: $taxRate%)';
}
