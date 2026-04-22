import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/firebase_service.dart';
import '../core/models/scan_history_item.dart';

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

  Future<void> addScan(ScanHistoryItem item) async {
    final uid = _userId;
    if (uid == null || uid.isEmpty) return;
    await FirebaseService.saveScan(uid, item);
  }

  Future<ScanHistoryItem?> removeScan(String id) async {
    final uid = _userId;
    if (uid == null || uid.isEmpty) return null;

    final existing = byId(id);
    await FirebaseService.deleteScan(uid, id);
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
}
