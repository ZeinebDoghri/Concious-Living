import 'dart:convert';

import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../constants.dart';
import 'nutrient_result.dart';

class ScanHistoryItem {
  final String id;
  final String dishName;
  final String? imagePath;
  final String? imageUrl;
  final DateTime scannedAt;
  final NutrientResult result;
  final List<String> detectedAllergens;
  final List<String> matchedAllergens;

  bool get hasAllergenAlert => matchedAllergens.isNotEmpty;

  ScanHistoryItem({
    String? id,
    required this.dishName,
    required this.scannedAt,
    required this.result,
    this.imagePath,
    this.imageUrl,
    this.detectedAllergens = const <String>[],
    this.matchedAllergens = const <String>[],
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'dishName': dishName,
      'imagePath': imagePath,
      'imageUrl': imageUrl,
      'scannedAt': scannedAt.toIso8601String(),
      'timestamp': Timestamp.fromDate(scannedAt),
      'riskLevel': result.overallRisk == 'high'
          ? 'danger'
          : result.overallRisk == 'moderate'
          ? 'warning'
          : 'safe',
      'detectedAllergens': detectedAllergens,
      'matchedAllergens': matchedAllergens,
      'hasAllergenAlert': hasAllergenAlert,
      'allergens': detectedAllergens,
      'nutrition': {
        'calories': result.calories.value,
        'protein_g': result.protein.value,
        'carbs_g': result.carbs.value,
        'fat_g': result.totalFat.value,
        'cholesterol_mg': result.cholesterol.value,
        'saturated_fat_g': result.saturatedFat.value,
        'sodium_mg': result.sodium.value,
        'sugar_g': result.sugar.value,
      },
      'result': result.toJson(),
      'results': {
        'dishName': dishName,
        'riskLevel': result.overallRisk == 'high'
            ? 'danger'
            : result.overallRisk == 'moderate'
            ? 'warning'
            : 'safe',
        'nutrition': {
          'cholesterol_mg': result.cholesterol.value,
          'saturated_fat_g': result.saturatedFat.value,
          'sodium_mg': result.sodium.value,
          'sugar_g': result.sugar.value,
          'calories': result.calories.value,
        },
        'allergens': {
          'detected': detectedAllergens,
          'matched': matchedAllergens,
          'hasAlert': hasAllergenAlert,
        },
      },
    };
  }

  factory ScanHistoryItem.fromJson(Map<String, dynamic> json) {
    return ScanHistoryItem(
      id: (json['id'] ?? '') as String,
      dishName: (json['dishName'] ?? '') as String,
      imagePath: json['imagePath'] as String?,
      imageUrl: json['imageUrl'] as String?,
      scannedAt: _dateFromJson(json),
      result: NutrientResult.fromJson(
        _extractNutrition(json),
      ),
      detectedAllergens: _stringList(
        json['detectedAllergens'] ?? (json['results'] as Map?)?['allergens']?['detected'],
      ),
      matchedAllergens: _stringList(
        json['matchedAllergens'] ?? (json['results'] as Map?)?['allergens']?['matched'],
      ),
    );
  }

  // Merge all known nutrition locations into a single NutrientResult-compatible map
  static Map<String, dynamic> _extractNutrition(Map<String, dynamic> json) {
    final merged = <String, dynamic>{};

    // 1. Base: result map has NutrientValue maps (cholesterol, fat, sodium, sugar…)
    final result = json['result'];
    if (result is Map) {
      result.forEach((k, v) => merged[k.toString()] = v);
    }

    // 2. Overlay: results.nutrition has flat numbers — fill any gap
    final results = json['results'];
    if (results is Map) {
      final nutrition = results['nutrition'];
      if (nutrition is Map) {
        void tryAdd(String destKey, dynamic raw, String unit) {
          // Skip only if existing NutrientValue map already has a non-zero value
          final existing = merged[destKey];
          if (existing is Map) {
            final existingVal = (existing['value'] as num?)?.toDouble() ?? 0.0;
            if (existingVal > 0) return;
          }
          if (raw is num && raw > 0) {
            merged[destKey] = {
              'value': raw.toDouble(),
              'unit': unit,
              'dailyValuePct': 0.0,
              'riskLevel': 'low',
            };
          }
        }

        tryAdd('calories',     nutrition['calories'],                 'kcal');
        tryAdd('protein',      nutrition['protein_g'] ?? nutrition['protein'], 'g');
        tryAdd('carbs',        nutrition['carbs_g']   ?? nutrition['carbs'],   'g');
        tryAdd('totalFat',     nutrition['fat_g']     ?? nutrition['totalFat'],'g');
        tryAdd('cholesterol',  nutrition['cholesterol_mg'] ?? nutrition['cholesterol'], 'mg');
        tryAdd('fat',          nutrition['saturated_fat_g'] ?? nutrition['fat'], 'g');
        tryAdd('sodium',       nutrition['sodium_mg'] ?? nutrition['sodium'],   'mg');
        tryAdd('sugar',        nutrition['sugar_g']   ?? nutrition['sugar'],    'g');
      }

      // carry overallRisk from results if missing
      if (!merged.containsKey('overallRisk')) {
        final risk = results['overallRisk'] ?? results['riskLevel'];
        if (risk != null) merged['overallRisk'] = risk;
      }
    }

    // 3. Top-level nutrition fallback
    if (merged.isEmpty) {
      final n = json['nutrition'];
      if (n is Map<String, dynamic>) return n;
      if (n is Map) return n.map((k, v) => MapEntry(k.toString(), v));
    }

    return merged;
  }

  static List<String> _stringList(dynamic raw) {
    if (raw is! List) return <String>[];
    return raw
        .map((e) => e.toString().trim())
        .where((e) => e.isNotEmpty)
        .toList(growable: false);
  }

  static DateTime _dateFromJson(Map<String, dynamic> json) {
    final timestamp = json['timestamp'];
    if (timestamp is Timestamp) return timestamp.toDate();
    final scannedAt = json['scannedAt'];
    if (scannedAt is Timestamp) return scannedAt.toDate();
    if (scannedAt is String) {
      return DateTime.tryParse(scannedAt) ?? DateTime.now();
    }
    return DateTime.now();
  }

  String toJsonString() => jsonEncode(toJson());

  factory ScanHistoryItem.fromJsonString(String raw) {
    return ScanHistoryItem.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  static String timeAgo(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inSeconds < 45) return AppStrings.justNow;
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} ${AppStrings.minutesAgo}';
    }
    if (diff.inHours < 24) {
      return '${diff.inHours} ${AppStrings.hoursAgo}';
    }
    if (diff.inDays < 7) {
      return '${diff.inDays} ${AppStrings.daysAgo}';
    }

    return DateFormat('dd MMM yyyy').format(dt);
  }
}
