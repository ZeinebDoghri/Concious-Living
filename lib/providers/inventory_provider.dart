import 'package:flutter/foundation.dart';
import 'dart:async';

import '../core/models/inventory_item_model.dart';
import '../core/firebase_service.dart';

class InventoryProvider extends ChangeNotifier {
  final List<InventoryItemModel> _items = [];

  StreamSubscription<List<InventoryItemModel>>? _sub;
  String? _venueId;

  List<InventoryItemModel> get items => List.unmodifiable(_items);

  InventoryProvider();

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void setVenueId(String? venueId) {
    if (_venueId == venueId) return;

    _venueId = venueId;
    _sub?.cancel();

    if (venueId == null || venueId.isEmpty) {
      _items.clear();
      notifyListeners();
      return;
    }

    _sub = FirebaseService.watchInventory(venueId).listen((items) {
      items.sort((a, b) => a.expiryDate.compareTo(b.expiryDate));
      _items
        ..clear()
        ..addAll(items);
      notifyListeners();
    });

    notifyListeners();
  }

  int get needsAttentionCount => _items.where((e) => e.status != 'fresh').length;

  InventoryItemModel? byId(String id) {
    try {
      return _items.firstWhere((i) => i.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> removeItem(String id) async {
    final venueId = _venueId;
    if (venueId == null || venueId.isEmpty) return;
    await FirebaseService.removeInventoryItem(venueId, id);
  }

  Future<void> updateStatus(String id, String status) async {
    final venueId = _venueId;
    if (venueId == null || venueId.isEmpty) return;

    final idx = _items.indexWhere((e) => e.id == id);
    if (idx == -1) return;

    final updated = _items[idx].copyWith(status: status);
    await FirebaseService.saveInventoryItem(updated, venueId);
  }

  Future<void> updateExpiryDate(String id, DateTime expiryDate) async {
    final venueId = _venueId;
    if (venueId == null || venueId.isEmpty) return;

    final idx = _items.indexWhere((e) => e.id == id);
    if (idx == -1) return;

    final updated = _items[idx].copyWith(expiryDate: expiryDate);
    await FirebaseService.saveInventoryItem(updated, venueId);
  }

  List<InventoryItemModel> filteredItems({
    required String query,
    required String filter,
  }) {
    Iterable<InventoryItemModel> results = _items;

    final q = query.trim().toLowerCase();
    if (q.isNotEmpty) {
      results = results.where((e) => e.name.toLowerCase().contains(q));
    }

    switch (filter) {
      case 'fresh':
        results = results.where((e) => e.status == 'fresh');
        break;
      case 'expiring':
        results = results.where((e) => e.status == 'expiring');
        break;
      case 'spoiled':
        results = results.where((e) => e.status == 'spoiled');
        break;
      case 'all':
      default:
        break;
    }

    return results.toList(growable: false);
  }
}
