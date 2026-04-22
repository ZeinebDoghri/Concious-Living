class AlertModel {
  final String id;
  final String customerId;
  final String customerName;
  final String dishName;
  final String allergen;
  final DateTime timestamp;
  final String status; // 'pending' | 'resolved'

  const AlertModel({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.dishName,
    required this.allergen,
    required this.timestamp,
    required this.status,
  });

  AlertModel copyWith({
    String? status,
  }) {
    return AlertModel(
      id: id,
      customerId: customerId,
      customerName: customerName,
      dishName: dishName,
      allergen: allergen,
      timestamp: timestamp,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customerId': customerId,
      'customerName': customerName,
      'dishName': dishName,
      'allergen': allergen,
      'timestamp': timestamp.toIso8601String(),
      'status': status,
    };
  }

  factory AlertModel.fromJson(Map<String, dynamic> json) {
    return AlertModel(
      id: (json['id'] ?? '') as String,
      customerId: (json['customerId'] ?? '') as String,
      customerName: (json['customerName'] ?? '') as String,
      dishName: (json['dishName'] ?? '') as String,
      allergen: (json['allergen'] ?? '') as String,
      timestamp: DateTime.tryParse((json['timestamp'] ?? '') as String) ??
          DateTime.now(),
      status: (json['status'] ?? 'pending') as String,
    );
  }
}
