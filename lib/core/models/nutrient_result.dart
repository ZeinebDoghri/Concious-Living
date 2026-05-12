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
  final NutrientValue calories;
  final NutrientValue protein;
  final NutrientValue carbs;
  final NutrientValue totalFat;
  final NutrientValue cholesterol;
  final NutrientValue saturatedFat;
  final NutrientValue sodium;
  final NutrientValue sugar;
  final String overallRisk; // 'low' | 'moderate' | 'high'
  final String message;

  const NutrientResult({
    this.calories = const NutrientValue(value: 0, unit: 'kcal', dailyValuePct: 0, riskLevel: 'low'),
    this.protein = const NutrientValue(value: 0, unit: 'g', dailyValuePct: 0, riskLevel: 'low'),
    this.carbs = const NutrientValue(value: 0, unit: 'g', dailyValuePct: 0, riskLevel: 'low'),
    this.totalFat = const NutrientValue(value: 0, unit: 'g', dailyValuePct: 0, riskLevel: 'low'),
    required this.cholesterol,
    required this.saturatedFat,
    required this.sodium,
    required this.sugar,
    required this.overallRisk,
    required this.message,
  });

  Map<String, dynamic> toJson() {
    return {
      'calories': calories.toJson(),
      'protein': protein.toJson(),
      'carbs': carbs.toJson(),
      'totalFat': totalFat.toJson(),
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
    Map<String, dynamic> toMap(dynamic raw, {String unit = '', double dailyLimit = 1}) {
      if (raw is Map<String, dynamic>) return raw;
      if (raw is Map) return raw.map((k, v) => MapEntry(k.toString(), v));
      if (raw is num) return {'value': raw.toDouble(), 'unit': unit, 'dailyValuePct': 0.0, 'riskLevel': 'low'};
      return {};
    }

    return NutrientResult(
      calories:     NutrientValue.fromJson(toMap(json['calories'], unit: 'kcal')),
      protein:      NutrientValue.fromJson(toMap(json['protein'], unit: 'g')),
      carbs:        NutrientValue.fromJson(toMap(json['carbs'], unit: 'g')),
      totalFat:     NutrientValue.fromJson(toMap(json['totalFat'], unit: 'g')),
      cholesterol:  NutrientValue.fromJson(toMap(json['cholesterol'], unit: 'mg')),
      saturatedFat: NutrientValue.fromJson(toMap(json['fat'] ?? json['saturatedFat'], unit: 'g')),
      sodium:       NutrientValue.fromJson(toMap(json['sodium'], unit: 'mg')),
      sugar:        NutrientValue.fromJson(toMap(json['sugar'], unit: 'g')),
      overallRisk:  (json['overallRisk'] ?? 'low') as String,
      message:      (json['message'] ?? '') as String,
    );
  }
}
