import 'package:flutter/foundation.dart';
import 'dart:async';

import '../core/models/alert_model.dart';
import '../core/firebase_service.dart';

class AlertsProvider extends ChangeNotifier {
  final List<AlertModel> _alerts = [];

  StreamSubscription<List<AlertModel>>? _sub;
  String? _scopeId;
  String _role = 'customer';

  List<AlertModel> get alerts => List.unmodifiable(_alerts);

  AlertsProvider();

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void setUserContext({required String role, required String? id}) {
    if (_scopeId == id && _role == role) return;

    _scopeId = id;
    _role = role;
    _sub?.cancel();

    if (id == null || id.isEmpty) {
      _alerts.clear();
      notifyListeners();
      return;
    }

    final stream = role == 'customer'
        ? FirebaseService.watchAlertsByCustomer(id)
        : FirebaseService.watchAlertsByVenue(id);

    _sub = stream.listen((items) {
      _alerts
        ..clear()
        ..addAll(items);
      notifyListeners();
    });

    notifyListeners();
  }

  void setVenueId(String? venueId) {
    setUserContext(role: 'restaurant', id: venueId);
  }

  int get pendingCount => _alerts.where((a) => a.status == 'pending').length;

  AlertModel? byId(String id) {
    try {
      return _alerts.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> resolveAlert(String id) async {
    await FirebaseService.resolveAlert(id);
  }

  Future<void> markResolved(String id) => resolveAlert(id);

  Future<void> undoResolve(String id) async {
    final idx = _alerts.indexWhere((a) => a.id == id);
    if (idx == -1) return;

    await FirebaseService.saveAlert(_alerts[idx].copyWith(status: 'pending'));
  }

  List<AlertModel> filterByStatus(String filter) {
    final now = DateTime.now();

    switch (filter) {
      case 'pending':
        return _alerts.where((a) => a.status == 'pending').toList(growable: false);
      case 'resolved':
        return _alerts.where((a) => a.status == 'resolved').toList(growable: false);
      case 'today':
        return _alerts
            .where((a) => a.timestamp.year == now.year && a.timestamp.month == now.month && a.timestamp.day == now.day)
            .toList(growable: false);
      case 'week':
      case 'this_week':
        return _alerts
            .where((a) => now.difference(a.timestamp).inDays <= 7)
            .toList(growable: false);
      case 'all':
      default:
        return alerts;
    }
  }
}
