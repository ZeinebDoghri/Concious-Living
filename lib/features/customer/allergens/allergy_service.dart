import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class AllergyResult {
  final String dish;
  final double confidence;
  final List<String> ingredients;
  final List<String> allergens;
  final List<Map<String, dynamic>> top5;
  final String allergenSource; // "api", "fallback", or "none"

  AllergyResult({
    required this.dish,
    required this.confidence,
    required this.ingredients,
    required this.allergens,
    required this.top5,
    required this.allergenSource,
  });

  factory AllergyResult.fromJson(Map<String, dynamic> json) {
    List<String> asStringList(dynamic raw) {
      if (raw is List) {
        return raw.map((item) => item.toString()).toList(growable: false);
      }
      return const [];
    }

    String asString(dynamic raw, [String fallback = '']) {
      if (raw == null) return fallback;
      final value = raw.toString().trim();
      return value.isEmpty ? fallback : value;
    }

    List<Map<String, dynamic>> asMapList(dynamic raw) {
      if (raw is! List) return const [];
      return raw
          .whereType<Map>()
          .map((item) {
            return item.map((key, value) => MapEntry(key.toString(), value));
          })
          .toList(growable: false);
    }

    return AllergyResult(
      dish: asString(
        json['dish'] ??
            json['dish_name'] ??
            json['predicted_dish'] ??
            json['label'],
        'Dish',
      ),
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      ingredients: asStringList(json['ingredients'] ?? json['ingredient_list']),
      allergens: asStringList(
        json['allergens'] ?? json['allergy_list'] ?? json['labels'],
      ),
      top5: asMapList(json['top5'] ?? json['top_5'] ?? json['predictions']),
      allergenSource: asString(
        json['allergen_source'] ?? json['allergenSource'] ?? json['source'],
        'none',
      ),
    );
  }
}

class AllergyService {
  static const String _baseUrl = 'https://nadiahafhouf-allergymodel.hf.space';

  // Call this when the app starts to wake up the Space early
  Future<void> warmUpApi() async {
    try {
      await http
          .get(Uri.parse('$_baseUrl/health'))
          .timeout(const Duration(seconds: 60));
    } catch (_) {} // ignore — it's just a warm-up ping
  }

  Future<bool> isApiAlive() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/health'))
          .timeout(const Duration(seconds: 10));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<AllergyResult> detectAllergens({
    File? imageFile,
    Uint8List? imageBytes,
    String filename = 'image.jpg',
  }) async {
    if (imageFile == null && imageBytes == null) {
      throw ArgumentError('Provide either imageFile or imageBytes.');
    }

    final uri = Uri.parse('$_baseUrl/predict');
    final request = http.MultipartRequest('POST', uri);

    if (kIsWeb || imageBytes != null) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          imageBytes ?? await imageFile!.readAsBytes(),
          filename: filename,
          contentType: MediaType('image', 'jpeg'),
        ),
      );
    } else {
      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          imageFile!.path,
          contentType: MediaType('image', 'jpeg'),
        ),
      );
    }

    final streamedResponse = await request.send().timeout(
      const Duration(seconds: 60),
    ); // 60s for cold start

    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final dynamic decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw Exception(
          'Invalid allergy response format: expected JSON object.',
        );
      }
      return AllergyResult.fromJson(decoded);
    } else {
      throw Exception(
        'Allergy API error: ${response.statusCode} — ${response.body}',
      );
    }
  }
}
