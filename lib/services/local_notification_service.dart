import 'package:flutter/foundation.dart';

class LocalNotificationService {
  static Future<void> showNutrientAlert(
    String nutrient,
    double current, [
    double? limit,
  ]) async {
    if (!kDebugMode) return;
    final message = limit == null
        ? '$nutrient ${(current * 100).toStringAsFixed(0)}%'
        : '$nutrient ${current.toStringAsFixed(1)} / ${limit.toStringAsFixed(1)}';
    debugPrint('Local notification nutrient_alerts: $message');
  }
}
