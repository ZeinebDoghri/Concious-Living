import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../core/models/scan_result.dart';
import 'local_notification_service.dart';

class NutrientTrackingService {
  static final _db = FirebaseFirestore.instance;

  static String get todayKey => DateFormat('yyyy-MM-dd').format(DateTime.now());

  static Future<void> onScanSaved(
    String uid,
    Map<String, dynamic> nutrition,
  ) async {
    final ref = _db
        .collection('users')
        .doc(uid)
        .collection('daily_logs')
        .doc(todayKey);

    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final current = snap.exists ? snap.data()! : <String, dynamic>{};

      tx.set(ref, {
        'cholesterol_mg':
            _num(current['cholesterol_mg']) + _num(nutrition['cholesterol_mg']),
        'saturated_fat_g':
            _num(current['saturated_fat_g']) +
            _num(nutrition['saturated_fat_g']),
        'sodium_mg': _num(current['sodium_mg']) + _num(nutrition['sodium_mg']),
        'sugar_g': _num(current['sugar_g']) + _num(nutrition['sugar_g']),
        'calories': _num(current['calories']) + _num(nutrition['calories']),
        'protein_g': _num(current['protein_g']) + _num(nutrition['protein_g']),
        'carbs_g': _num(current['carbs_g']) + _num(nutrition['carbs_g']),
        'fat_g': _num(current['fat_g']) + _num(nutrition['fat_g']),
        'scan_refs': FieldValue.arrayUnion([nutrition['scanId'] ?? '']),
        'last_updated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });

    await _checkLimitsAndNotify(uid);
  }

  static Future<void> onScanDeleted(
    String uid,
    Map<String, dynamic> nutrition,
    String date,
  ) async {
    final ref = _db
        .collection('users')
        .doc(uid)
        .collection('daily_logs')
        .doc(date);

    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return;
      final current = snap.data()!;

      tx.update(ref, {
        'cholesterol_mg': max(
          0.0,
          _num(current['cholesterol_mg']) - _num(nutrition['cholesterol_mg']),
        ),
        'saturated_fat_g': max(
          0.0,
          _num(current['saturated_fat_g']) - _num(nutrition['saturated_fat_g']),
        ),
        'sodium_mg': max(
          0.0,
          _num(current['sodium_mg']) - _num(nutrition['sodium_mg']),
        ),
        'sugar_g': max(
          0.0,
          _num(current['sugar_g']) - _num(nutrition['sugar_g']),
        ),
        'calories': max(
          0.0,
          _num(current['calories']) - _num(nutrition['calories']),
        ),
        'protein_g': max(
          0.0,
          _num(current['protein_g']) - _num(nutrition['protein_g']),
        ),
        'carbs_g': max(
          0.0,
          _num(current['carbs_g']) - _num(nutrition['carbs_g']),
        ),
        'fat_g': max(
          0.0,
          _num(current['fat_g']) - _num(nutrition['fat_g']),
        ),
        'scan_refs': FieldValue.arrayRemove([nutrition['scanId'] ?? '']),
        'last_updated': FieldValue.serverTimestamp(),
      });
    });
  }

  static Stream<Map<String, dynamic>> watchTodayLog(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('daily_logs')
        .doc(todayKey)
        .snapshots()
        .map((s) => s.data() ?? {});
  }

  static Stream<Map<String, dynamic>> watchLimits(String uid) {
    return _db.collection('users').doc(uid).snapshots().map((s) {
      final limits = s.data()?['nutrientLimits'];
      if (limits is Map<String, dynamic>) return limits;
      if (limits is Map) {
        return limits.map((key, value) => MapEntry(key.toString(), value));
      }
      return {
        'cholesterol_mg': 300,
        'saturated_fat_g': 20,
        'sodium_mg': 2300,
        'sugar_g': 50,
      };
    });
  }

  static Future<void> _checkLimitsAndNotify(String uid) async {
    final logSnap = await _db
        .collection('users')
        .doc(uid)
        .collection('daily_logs')
        .doc(todayKey)
        .get();
    final userSnap = await _db.collection('users').doc(uid).get();

    final log = logSnap.data() ?? {};
    final limits = userSnap.data()?['nutrientLimits'];
    final limitMap = limits is Map ? limits : const <String, dynamic>{};

    final fields = {
      'cholesterol_mg': 'Cholesterol',
      'saturated_fat_g': 'Saturated fat',
      'sodium_mg': 'Sodium',
      'sugar_g': 'Sugar',
    };

    for (final entry in fields.entries) {
      final current = _num(log[entry.key]);
      final limit = _num(limitMap[entry.key], fallback: 999.0);
      if (limit > 0 && current >= limit) {
        await LocalNotificationService.showNutrientAlert(
          entry.value,
          current,
          limit,
        );
      }
    }
  }

  static Future<void> saveLimits({
    required String uid,
    required double cholesterol_mg,
    required double saturated_fat_g,
    required double sodium_mg,
    required double sugar_g,
  }) async {
    await _db.collection('users').doc(uid).update({
      'nutrientLimits': {
        'cholesterol_mg': cholesterol_mg,
        'saturated_fat_g': saturated_fat_g,
        'sodium_mg': sodium_mg,
        'sugar_g': sugar_g,
      },
    });
  }

  Future<void> onScanComplete(ScanResult scan, String uid, String date) {
    return onScanSaved(uid, _nutritionFromScan(scan));
  }

  Future<void> deleteScan(ScanResult scan, String uid, String date) {
    return onScanDeleted(uid, _nutritionFromScan(scan), date);
  }

  Stream<Map<String, dynamic>> watchDailyLog(String uid, String date) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('daily_logs')
        .doc(date)
        .snapshots()
        .map((snap) => snap.data() ?? {});
  }

  static Map<String, dynamic> _nutritionFromScan(ScanResult scan) {
    return {
      'scanId': scan.id,
      'cholesterol_mg': scan.nutrition.cholesterol_mg,
      'saturated_fat_g': scan.nutrition.saturated_fat_g,
      'sodium_mg': scan.nutrition.sodium_mg,
      'sugar_g': scan.nutrition.sugar_g,
      'calories': scan.nutrition.calories,
      'protein_g': scan.nutrition.protein,
      'carbs_g': scan.nutrition.carbs,
      'fat_g': scan.nutrition.fat,
    };
  }

  static double _num(dynamic value, {double fallback = 0.0}) {
    if (value is num) return value.toDouble();
    return fallback;
  }
}
