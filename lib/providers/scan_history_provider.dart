import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../core/firebase_service.dart';
import '../core/models/scan_result.dart';
import '../core/models/scan_history_item.dart';
import '../services/nutrient_tracking_service.dart';

class ScanHistoryProvider extends ChangeNotifier {
  final List<ScanHistoryItem> _items = [];
  StreamSubscription<List<ScanHistoryItem>>? _sub;

  String? _userId;

  String? get userId => _userId;

  List<ScanHistoryItem> get items => List.unmodifiable(_items);

  ScanHistoryProvider();

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void setUser(String? userId) {
    if (_userId == userId) return;

    _userId = userId;
    _sub?.cancel();

    if (userId == null || userId.isEmpty) {
      _items.clear();
      notifyListeners();
      return;
    }

    _sub = FirebaseService.watchScans(userId).listen((items) {
      _items
        ..clear()
        ..addAll(items);
      notifyListeners();
    });

    notifyListeners();
  }

  Future<void> addScan(
    ScanHistoryItem item, {
    bool updateNutritionTracker = false,
  }) async {
    final uid = _userId;
    if (uid == null || uid.isEmpty) return;
    await FirebaseService.saveScan(uid, item);
    if (updateNutritionTracker) {
      await NutrientTrackingService.onScanSaved(
        uid,
        _nutritionFromScanHistory(item),
      );
    }
  }

  Future<ScanHistoryItem?> removeScan(String id) async {
    final uid = _userId;
    if (uid == null || uid.isEmpty) return null;

    final existing = byId(id);
    await FirebaseService.deleteScan(uid, id);
    if (existing != null) {
      await NutrientTrackingService().deleteScan(
        ScanResult.fromHistoryItem(existing, uid),
        uid,
        DateFormat('yyyy-MM-dd').format(existing.scannedAt),
      );
    }
    return existing;
  }

  Future<void> restoreScan(ScanHistoryItem item) async {
    final uid = _userId;
    if (uid == null || uid.isEmpty) return;
    await FirebaseService.saveScan(uid, item);
  }

  Future<void> clearAll() async {
    // Firestore doesn't support a single "delete all" without a batch.
    // Keep UI action as a local clear for now.
    _items.clear();
    notifyListeners();
  }

  List<ScanHistoryItem> filteredItems(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return items;

    return _items
        .where((e) => e.dishName.toLowerCase().contains(q))
        .toList(growable: false);
  }

  ScanHistoryItem? byId(String id) {
    try {
      return _items.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  static Map<String, dynamic> _nutritionFromScanHistory(ScanHistoryItem item) {
    return {
      'scanId': item.id,
      'cholesterol_mg': item.result.cholesterol.value,
      'saturated_fat_g': item.result.saturatedFat.value,
      'sodium_mg': item.result.sodium.value,
      'sugar_g': item.result.sugar.value,
      'calories': 0.0,
    };
  }
}
