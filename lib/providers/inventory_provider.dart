import 'dart:async';
import 'dart:convert'; // ✅ for base64Decode
import 'dart:typed_data'; // ✅ for Uint8List

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Modèle
// ─────────────────────────────────────────────────────────────────────────────

class InventoryItem {
  final String id;
  final String name;
  final DateTime expiryDate;
  final String status; // 'fresh' | 'expiring' | 'spoiled'
  final double quantity;
  final String unit;
  final String? imageBase64; // ✅ product image stored as base64

  const InventoryItem({
    required this.id,
    required this.name,
    required this.expiryDate,
    required this.status,
    required this.quantity,
    required this.unit,
    this.imageBase64,
  });

  // ✅ Getters utilisés dans dashboard_screen.dart
  bool get isExpiringSoon => status == 'expiring';
  bool get isSpoiled => status == 'spoiled';
  bool get isFresh => status == 'fresh';

  // ✅ Returns decoded image bytes for display, or null if no image
  Uint8List? get imageBytes {
    if (imageBase64 == null || imageBase64!.isEmpty) return null;
    try {
      return base64Decode(imageBase64!);
    } catch (_) {
      return null;
    }
  }

  factory InventoryItem.fromFirestore(Map<String, dynamic> data, String id) {
    final ts = data['expiryDate'];
    final expiryDate = ts is Timestamp ? ts.toDate() : DateTime.now();

    return InventoryItem(
      id: id,
      name: data['name'] ?? 'Unknown',
      expiryDate: expiryDate,
      status: data['status'] ?? 'fresh',
      quantity: (data['quantity'] ?? 1).toDouble(),
      unit: data['unit'] ?? 'pcs',
      imageBase64: data['imageBase64'] as String?, // ✅ load image from Firestore
    );
  }

  InventoryItem copyWith({
    String? id,
    String? name,
    DateTime? expiryDate,
    String? status,
    double? quantity,
    String? unit,
    String? imageBase64,
  }) {
    return InventoryItem(
      id: id ?? this.id,
      name: name ?? this.name,
      expiryDate: expiryDate ?? this.expiryDate,
      status: status ?? this.status,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      imageBase64: imageBase64 ?? this.imageBase64,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'expiryDate': Timestamp.fromDate(expiryDate),
      'status': status,
      'quantity': quantity,
      'unit': unit,
      if (imageBase64 != null) 'imageBase64': imageBase64,
    };
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Provider
// ─────────────────────────────────────────────────────────────────────────────

class InventoryProvider extends ChangeNotifier {
  List<InventoryItem> _items = [];
  bool _loading = false;
  String? _currentUid;
  StreamSubscription<QuerySnapshot>? _subscription;

  // ── Getters ────────────────────────────────────────────────────────────────

  List<InventoryItem> get items => List.unmodifiable(_items);
  bool get loading => _loading;
  String? get currentUid => _currentUid;

  int get needsAttentionCount => _items
      .where((i) => i.status == 'expiring' || i.status == 'spoiled')
      .length;

  int get freshCount    => _items.where((i) => i.status == 'fresh').length;
  int get expiringCount => _items.where((i) => i.status == 'expiring').length;
  int get spoiledCount  => _items.where((i) => i.status == 'spoiled').length;
  int get totalCount    => _items.length;

  // ── Filter (used by InventoryScreen) ──────────────────────────────────────

  List<InventoryItem> filteredItems({
    required String query,
    required String filter,
  }) {
    return _items.where((item) {
      final matchQuery = query.isEmpty ||
          item.name.toLowerCase().contains(query.toLowerCase());
      final matchFilter = filter == 'all' ||
          (filter == 'fresh'    && item.status == 'fresh') ||
          (filter == 'expiring' && item.status == 'expiring') ||
          (filter == 'spoiled'  && item.status == 'spoiled');
      return matchQuery && matchFilter;
    }).toList()
      ..sort((a, b) => a.expiryDate.compareTo(b.expiryDate));
  }

  // ✅ Used in inventory_item_screen.dart
  InventoryItem? byId(String id) {
    try {
      return _items.firstWhere((i) => i.id == id);
    } catch (_) {
      return null;
    }
  }

  // Alias for compatibility
  InventoryItem? getItemById(String id) => byId(id);

  // ── Listen to Firestore in real-time ──────────────────────────────────────

  void listenToUserInventory(String uid) {
    if (_currentUid == uid && _subscription != null) return;

    _subscription?.cancel();
    _currentUid = uid;
    _loading = true;
    notifyListeners();

    _subscription = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('inventory')
        .orderBy('expiryDate')
        .snapshots()
        .listen(
          (snapshot) {
            _items = snapshot.docs
                .map((doc) => InventoryItem.fromFirestore(
                      doc.data(),
                      doc.id,
                    ))
                .toList();
            _loading = false;
            notifyListeners();
          },
          onError: (Object e) {
            debugPrint('❌ InventoryProvider stream error: $e');
            _loading = false;
            notifyListeners();
          },
        );
  }

  // ── CRUD Firestore ────────────────────────────────────────────────────────

  /// Add an item
  Future<void> addItem(InventoryItem item) async {
    if (_currentUid == null) return;
    try {
      final ref = FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUid)
          .collection('inventory')
          .doc(item.id.isEmpty ? null : item.id);
      await ref.set(item.toMap());
    } catch (e) {
      debugPrint('❌ addItem error: $e');
    }
  }

  /// Update a full item
  Future<void> updateItem(InventoryItem item) async {
    if (_currentUid == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUid)
          .collection('inventory')
          .doc(item.id)
          .update(item.toMap());
    } catch (e) {
      debugPrint('❌ updateItem error: $e');
    }
  }

  // ✅ Used in inventory_item_screen.dart
  Future<void> updateStatus(String id, String newStatus) async {
    if (_currentUid == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUid)
          .collection('inventory')
          .doc(id)
          .update({'status': newStatus});
    } catch (e) {
      debugPrint('❌ updateStatus error: $e');
    }
  }

  // ✅ Used in inventory_item_screen.dart
  Future<void> updateExpiryDate(String id, DateTime newDate) async {
    if (_currentUid == null) return;
    try {
      final diff = newDate.difference(DateTime.now()).inDays;
      final newStatus = diff < 0
          ? 'spoiled'
          : diff <= 3
              ? 'expiring'
              : 'fresh';

      await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUid)
          .collection('inventory')
          .doc(id)
          .update({
        'expiryDate': Timestamp.fromDate(newDate),
        'status': newStatus,
      });
    } catch (e) {
      debugPrint('❌ updateExpiryDate error: $e');
    }
  }

  // ✅ Used in inventory_item_screen.dart and staff_result_screen.dart
  Future<void> removeItem(String itemId) async {
    if (_currentUid == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUid)
          .collection('inventory')
          .doc(itemId)
          .delete();
    } catch (e) {
      debugPrint('❌ removeItem error: $e');
    }
  }

  // Alias for compatibility
  Future<void> deleteItem(String itemId) => removeItem(itemId);

  // ── Reset (logout) ────────────────────────────────────────────────────────

  void clear() {
    _subscription?.cancel();
    _subscription = null;
    _currentUid = null;
    _items = [];
    _loading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}