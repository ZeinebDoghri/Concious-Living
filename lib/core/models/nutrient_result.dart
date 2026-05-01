class NutrientValue {
  final double value;
  final String unit;
  final double dailyValuePct;
  final String riskLevel; // 'low' | 'moderate' | 'high'

  const NutrientValue({
    required this.value,
    required this.unit,
    required this.dailyValuePct,
    required this.riskLevel,
  });

  Map<String, dynamic> toJson() {
    return {
      'value': value,
      'unit': unit,
      'dailyValuePct': dailyValuePct,
      'riskLevel': riskLevel,
    };
  }

  factory NutrientValue.fromJson(Map<String, dynamic> json) {
    return NutrientValue(
      value: (json['value'] as num?)?.toDouble() ?? 0.0,
      unit: (json['unit'] ?? '') as String,
      dailyValuePct: (json['dailyValuePct'] as num?)?.toDouble() ?? 0.0,
      riskLevel: (json['riskLevel'] ?? 'low') as String,
    );
  }
}

class NutrientResult {
  final NutrientValue cholesterol;
  final NutrientValue saturatedFat;
  final NutrientValue sodium;
  final NutrientValue sugar;
  final String overallRisk; // 'low' | 'moderate' | 'high'
  final String message;

  const NutrientResult({
    required this.cholesterol,
    required this.saturatedFat,
    required this.sodium,
    required this.sugar,
    required this.overallRisk,
    required this.message,
  });

  Map<String, dynamic> toJson() {
    return {
      'cholesterol': cholesterol.toJson(),
      'fat': saturatedFat.toJson(),
      'sodium': sodium.toJson(),
      'sugar': sugar.toJson(),
      'overallRisk': overallRisk,
      'message': message,
    };
  }

  /* factory NutrientResult.fromJson(Map<String, dynamic> json) {
    return NutrientResult(
      cholesterol:
          NutrientValue.fromJson((json['cholesterol'] ?? {}) as Map<String, dynamic>),
      saturatedFat: NutrientValue.fromJson(
          (json['fat'] ?? {}) as Map<String, dynamic>),
      sodium: NutrientValue.fromJson((json['sodium'] ?? {}) as Map<String, dynamic>),
      sugar: NutrientValue.fromJson((json['sugar'] ?? {}) as Map<String, dynamic>),
      overallRisk: (json['overallRisk'] ?? 'low') as String,
      message: (json['message'] ?? '') as String,
    );
  } */

    factory NutrientResult.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> toMap(dynamic raw) {
      if (raw is Map<String, dynamic>) return raw;
      if (raw is Map) return raw.map((k, v) => MapEntry(k.toString(), v));
      return {};
    }

    return NutrientResult(
      cholesterol:  NutrientValue.fromJson(toMap(json['cholesterol'])),
      saturatedFat: NutrientValue.fromJson(toMap(json['fat'])),
      sodium:       NutrientValue.fromJson(toMap(json['sodium'])),
      sugar:        NutrientValue.fromJson(toMap(json['sugar'])),
      overallRisk:  (json['overallRisk'] ?? 'low') as String,
      message:      (json['message'] ?? '') as String,
    );
  }
}
