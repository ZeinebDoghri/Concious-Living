import 'package:cloud_firestore/cloud_firestore.dart';

import 'nutrient_result.dart';
import 'scan_history_item.dart';

class ScanNutrition {
  final double cholesterol_mg;
  final double saturated_fat_g;
  final double sodium_mg;
  final double sugar_g;
  final double calories;
  final double carbs;
  final double fat;
  final double protein;

  const ScanNutrition({
    required this.cholesterol_mg,
    required this.saturated_fat_g,
    required this.sodium_mg,
    required this.sugar_g,
    this.calories = 0,
    this.carbs = 0,
    this.fat = 0,
    this.protein = 0,
  });

  factory ScanNutrition.fromNutrientResult(NutrientResult result) {
    return ScanNutrition(
      cholesterol_mg: result.cholesterol.value,
      saturated_fat_g: result.saturatedFat.value,
      sodium_mg: result.sodium.value,
      sugar_g: result.sugar.value,
      calories: result.calories.value,
      carbs: result.carbs.value,
      fat: result.totalFat.value,
      protein: result.protein.value,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cholesterol_mg': cholesterol_mg,
      'saturated_fat_g': saturated_fat_g,
      'sodium_mg': sodium_mg,
      'sugar_g': sugar_g,
      'calories': calories,
      'carbs': carbs,
      'fat': fat,
      'protein': protein,
    };
  }
}

class ScanWaste {
  final double estimatedWasteKg;
  final double compostableRatio;

  const ScanWaste({
    required this.estimatedWasteKg,
    required this.compostableRatio,
  });

  factory ScanWaste.fromAiMaps({
    required Map<String, dynamic> wasteResult,
    required Map<String, dynamic> compostResult,
  }) {
    final items = (wasteResult['detectedItems'] as List?) ?? const [];
    final kg = items.fold<double>(0, (sum, item) {
      if (item is Map) {
        return sum + ((item['quantityKg'] as num?)?.toDouble() ?? 0);
      }
      return sum;
    });
    final compostPct =
        (compostResult['compostablePct'] as num?)?.toDouble() ?? 0;
    final ratio = compostPct > 1 ? compostPct / 100 : compostPct;
    return ScanWaste(
      estimatedWasteKg: kg,
      compostableRatio: ratio.clamp(0, 1).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'estimatedWasteKg': estimatedWasteKg,
      'compostableRatio': compostableRatio,
    };
  }
}

class ScanResult {
  final String id;
  final String entityId;
  final String? departmentId;
  final DateTime timestamp;
  final ScanNutrition nutrition;
  final ScanWaste waste;

  const ScanResult({
    required this.id,
    required this.entityId,
    required this.timestamp,
    required this.nutrition,
    required this.waste,
    this.departmentId,
  });

  factory ScanResult.fromHistoryItem(ScanHistoryItem item, String uid) {
    return ScanResult(
      id: item.id,
      entityId: uid,
      timestamp: item.scannedAt,
      nutrition: ScanNutrition.fromNutrientResult(item.result),
      waste: const ScanWaste(estimatedWasteKg: 0, compostableRatio: 0),
    );
  }

  factory ScanResult.fromVenueScan({
    required String id,
    required String entityId,
    required DateTime timestamp,
    required Map<String, dynamic> wasteResult,
    required Map<String, dynamic> compostResult,
    String? departmentId,
  }) {
    return ScanResult(
      id: id,
      entityId: entityId,
      departmentId: departmentId,
      timestamp: timestamp,
      nutrition: const ScanNutrition(
        cholesterol_mg: 0,
        saturated_fat_g: 0,
        sodium_mg: 0,
        sugar_g: 0,
      ),
      waste: ScanWaste.fromAiMaps(
        wasteResult: wasteResult,
        compostResult: compostResult,
      ),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'entityId': entityId,
      'departmentId': departmentId,
      'timestamp': Timestamp.fromDate(timestamp),
      'results': {
        'nutrition': nutrition.toJson(),
        'waste': waste.toJson(),
      },
    }..removeWhere((key, value) => value == null);
  }
}
