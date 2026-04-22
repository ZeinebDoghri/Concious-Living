import 'dart:convert';

import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../constants.dart';
import 'nutrient_result.dart';

class ScanHistoryItem {
  final String id;
  final String dishName;
  final String? imagePath;
  final DateTime scannedAt;
  final NutrientResult result;

  ScanHistoryItem({
    String? id,
    required this.dishName,
    required this.scannedAt,
    required this.result,
    this.imagePath,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'dishName': dishName,
      'imagePath': imagePath,
      'scannedAt': scannedAt.toIso8601String(),
      'result': result.toJson(),
    };
  }

  factory ScanHistoryItem.fromJson(Map<String, dynamic> json) {
    return ScanHistoryItem(
      id: (json['id'] ?? '') as String,
      dishName: (json['dishName'] ?? '') as String,
      imagePath: json['imagePath'] as String?,
      scannedAt: DateTime.tryParse((json['scannedAt'] ?? '') as String) ??
          DateTime.now(),
      result: NutrientResult.fromJson((json['result'] ?? {}) as Map<String, dynamic>),
    );
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
