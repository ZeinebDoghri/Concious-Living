import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/firebase_service.dart';

Future<List<String>> getMatchingAllergens(List<String> dishAllergens) async {
  List<String> saved = <String>[];

  final currentUid = FirebaseAuth.instance.currentUser?.uid;
  if (currentUid != null && currentUid.isNotEmpty) {
    try {
      saved = await FirebaseService.getUserAllergens(uid: currentUid);
    } catch (_) {
      saved = <String>[];
    }
  }

  if (saved.isEmpty) {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('customer_allergens_json');
    if (raw != null && raw.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) saved = decoded.whereType<String>().toList();
      } catch (_) {
        saved = <String>[];
      }
    }
  }

  return dishAllergens
      .where((a) => saved.any(
            (s) => s.toLowerCase() == a.toLowerCase(),
          ))
      .toList();
}