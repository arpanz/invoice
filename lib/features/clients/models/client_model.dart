class ClientModel {
  final String id;
  final String name;
  final String? email;
  final String? phone;
  final String? address;
  final String? gstin;
  final DateTime createdAt;

  const ClientModel({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    this.address,
    this.gstin,
    required this.createdAt,
  });

  factory ClientModel.fromMap(Map<String, dynamic> map) {
    return ClientModel(
      id: map['id'] as String,
      name: map['name'] as String,
      email: map['email'] as String?,
      phone: map['phone'] as String?,
      address: map['address'] as String?,
      gstin: map['gstin'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'address': address,
      'gstin': gstin,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  ClientModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? address,
    String? gstin,
    DateTime? createdAt,
  }) {
    return ClientModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      gstin: gstin ?? this.gstin,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() => 'ClientModel(id: $id, name: $name)';
}
