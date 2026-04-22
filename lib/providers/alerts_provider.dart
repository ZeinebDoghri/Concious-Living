import 'package:flutter/foundation.dart';
import 'dart:async';

import '../core/models/alert_model.dart';
import '../core/firebase_service.dart';

class AlertsProvider extends ChangeNotifier {
  final List<AlertModel> _alerts = [];

  StreamSubscription<List<AlertModel>>? _sub;
  String? _venueId;

  List<AlertModel> get alerts => List.unmodifiable(_alerts);

  AlertsProvider();

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
      _alerts.clear();
      notifyListeners();
      return;
    }

    _sub = FirebaseService.watchAlerts(venueId).listen((items) {
      _alerts
        ..clear()
        ..addAll(items);
      notifyListeners();
    });

    notifyListeners();
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
