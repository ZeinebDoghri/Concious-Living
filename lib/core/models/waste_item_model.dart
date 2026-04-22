class WasteItemModel {
  final String id;
  final String name;
  final double quantityKg;
  final String category;
  final bool isCompostable;
  final String trend; // 'up' | 'down'

  const WasteItemModel({
    required this.id,
    required this.name,
    required this.quantityKg,
    required this.category,
    required this.isCompostable,
    required this.trend,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'quantityKg': quantityKg,
      'category': category,
      'isCompostable': isCompostable,
      'trend': trend,
    };
  }

  factory WasteItemModel.fromJson(Map<String, dynamic> json) {
    return WasteItemModel(
      id: (json['id'] ?? '') as String,
      name: (json['name'] ?? '') as String,
      quantityKg: (json['quantityKg'] as num?)?.toDouble() ?? 0.0,
      category: (json['category'] ?? '') as String,
      isCompostable: (json['isCompostable'] ?? false) as bool,
      trend: (json['trend'] ?? 'up') as String,
    );
  }
}
