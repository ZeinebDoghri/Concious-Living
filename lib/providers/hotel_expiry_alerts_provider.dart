import 'dart:convert';
import 'package:flutter/foundation.dart';

/// Model for expiry alert from AI detection
class HotelExpiryAlert {
  final String id;
  final String itemName;
  final DateTime expiresAt;
  final String? imageBase64; // Scanned image as base64
  final DateTime scannedAt;
  final bool isFromAI; // true if from AI detection, false if manual

  const HotelExpiryAlert({
    required this.id,
    required this.itemName,
    required this.expiresAt,
    this.imageBase64,
    required this.scannedAt,
    required this.isFromAI,
  });

  /// Is this item expired?
  bool get isExpired => expiresAt.isBefore(DateTime.now());

  /// Hours remaining until expiry
  int get hoursRemaining =>
      expiresAt.difference(DateTime.now()).inHours.clamp(0, 999);

  /// Is expiring within 48 hours?
  bool get isUrgent => hoursRemaining <= 48 && !isExpired;

  /// Decode image from base64
  String? get imageUrl {
    if (imageBase64 == null || imageBase64!.isEmpty) return null;
    return 'data:image/png;base64,$imageBase64';
  }

  HotelExpiryAlert copyWith({
    String? id,
    String? itemName,
    DateTime? expiresAt,
    String? imageBase64,
    DateTime? scannedAt,
    bool? isFromAI,
  }) {
    return HotelExpiryAlert(
      id: id ?? this.id,
      itemName: itemName ?? this.itemName,
      expiresAt: expiresAt ?? this.expiresAt,
      imageBase64: imageBase64 ?? this.imageBase64,
      scannedAt: scannedAt ?? this.scannedAt,
      isFromAI: isFromAI ?? this.isFromAI,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'itemName': itemName,
        'expiresAt': expiresAt.toIso8601String(),
        'imageBase64': imageBase64,
        'scannedAt': scannedAt.toIso8601String(),
        'isFromAI': isFromAI,
      };

  factory HotelExpiryAlert.fromJson(Map<String, dynamic> json) =>
      HotelExpiryAlert(
        id: json['id'] ?? '',
        itemName: json['itemName'] ?? 'Unknown',
        expiresAt: DateTime.tryParse(json['expiresAt'] ?? '') ??
            DateTime.now().add(const Duration(days: 1)),
        imageBase64: json['imageBase64'],
        scannedAt: DateTime.tryParse(json['scannedAt'] ?? '') ?? DateTime.now(),
        isFromAI: json['isFromAI'] ?? true,
      );
}

/// Provider for hotel expiry alerts from AI detection
/// Stores in-memory; results persist during the session
class HotelExpiryAlertsProvider extends ChangeNotifier {
  final List<HotelExpiryAlert> _alerts = [];

  List<HotelExpiryAlert> get alerts => List.unmodifiable(_alerts);

  /// Count of urgent alerts (< 48h or expired)
  int get urgentCount =>
      _alerts.where((a) => a.isUrgent || a.isExpired).length;

  /// Get sorted alerts (by expiry date, urgent first)
  List<HotelExpiryAlert> get sortedAlerts {
    final sorted = _alerts.toList()
      ..sort((a, b) {
        // Expired items first
        if (a.isExpired && !b.isExpired) return -1;
        if (!a.isExpired && b.isExpired) return 1;
        // Then by expiry date (soonest first)
        return a.expiresAt.compareTo(b.expiresAt);
      });
    return sorted;
  }

  /// Add a new alert from AI detection
  void addAlert(HotelExpiryAlert alert) {
    _alerts.add(alert);
    notifyListeners();
  }

  /// Remove alert by ID
  void removeAlert(String id) {
    _alerts.removeWhere((a) => a.id == id);
    notifyListeners();
  }

  /// Clear all alerts
  void clearAlerts() {
    _alerts.clear();
    notifyListeners();
  }

  /// Get alert by ID
  HotelExpiryAlert? getAlertById(String id) {
    try {
      return _alerts.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }
}
