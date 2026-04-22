class InventoryItemModel {
  final String id;
  final String name;
  final double quantity;
  final String unit;
  final DateTime expiryDate;
  final String status; // 'fresh' | 'expiring' | 'spoiled'

  const InventoryItemModel({
    required this.id,
    required this.name,
    required this.quantity,
    required this.unit,
    required this.expiryDate,
    required this.status,
  });

  bool get isExpiringSoon {
    final days = expiryDate.difference(DateTime.now()).inDays;
    return days < 3;
  }

  InventoryItemModel copyWith({
    DateTime? expiryDate,
    String? status,
    double? quantity,
  }) {
    return InventoryItemModel(
      id: id,
      name: name,
      quantity: quantity ?? this.quantity,
      unit: unit,
      expiryDate: expiryDate ?? this.expiryDate,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'quantity': quantity,
      'unit': unit,
      'expiryDate': expiryDate.toIso8601String(),
      'status': status,
    };
  }

  factory InventoryItemModel.fromJson(Map<String, dynamic> json) {
    return InventoryItemModel(
      id: (json['id'] ?? '') as String,
      name: (json['name'] ?? '') as String,
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0.0,
      unit: (json['unit'] ?? '') as String,
      expiryDate: DateTime.tryParse((json['expiryDate'] ?? '') as String) ??
          DateTime.now().add(const Duration(days: 7)),
      status: (json['status'] ?? 'fresh') as String,
    );
  }
}
