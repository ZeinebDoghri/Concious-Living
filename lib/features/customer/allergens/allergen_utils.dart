import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

Future<List<String>> getMatchingAllergens(List<String> dishAllergens) async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString('customer_allergens_json');
  if (raw == null) return [];

  final saved = List<String>.from(jsonDecode(raw));

  return dishAllergens
      .where((a) => saved.any(
            (s) => s.toLowerCase() == a.toLowerCase(),
          ))
      .toList();
}