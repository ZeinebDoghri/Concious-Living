// lib/features/customer/nutrition/calorie_inference_service_web.dart
//
// CalorieSwinV2 API service — matches your HuggingFace FastAPI exactly.
//
// Endpoints used:
//   GET  /health           → ping the server
//   POST /predict          → RGB image only  (depth = grey fallback on server)
//   POST /predict_with_depth → RGB + depth image (better accuracy)
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../../../core/api_config.dart';

// ── Result model ──────────────────────────────────────────────────────────────

class NutritionResult {
  final double mass;       // grams
  final double calories;   // kcal
  final double fat;        // grams
  final double carb;       // grams
  final double protein;    // grams
  final String calorieLevel; // "Low" / "Moderate" / "High" / "Very high"
  final double r2Calories;
  final double maeCalories;

  const NutritionResult({
    required this.mass,
    required this.calories,
    required this.fat,
    required this.carb,
    required this.protein,
    required this.calorieLevel,
    required this.r2Calories,
    required this.maeCalories,
  });

  factory NutritionResult.fromJson(Map<String, dynamic> json) {
    final nutrition = json['nutrition'];
    final modelInfo = json['model_info'];

    final nut = nutrition is Map<String, dynamic>
        ? nutrition
        : <String, dynamic>{
            'mass': json['mass'],
            'calories': json['calories'],
            'fat': json['fat'],
            'carb': json['carb'],
            'protein': json['protein'],
          };

    final info = modelInfo is Map<String, dynamic>
        ? modelInfo
        : <String, dynamic>{
            'r2_calories': json['r2Calories'] ?? json['r2_calories'],
            'mae_calories': json['maeCalories'] ?? json['mae_calories'],
          };

    final calorieLevel = json['calorie_level'] ?? json['calorieLevel'];
    return NutritionResult(
      mass: (nut['mass'] as num?)?.toDouble() ?? 0.0,
      calories: (nut['calories'] as num?)?.toDouble() ?? 0.0,
      fat: (nut['fat'] as num?)?.toDouble() ?? 0.0,
      carb: (nut['carb'] as num?)?.toDouble() ?? 0.0,
      protein: (nut['protein'] as num?)?.toDouble() ?? 0.0,
      calorieLevel: calorieLevel as String? ?? '',
      r2Calories: (info['r2_calories'] as num?)?.toDouble() ?? 0.0,
      maeCalories: (info['mae_calories'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// Returns a short summary string for display.
  String get summary =>
      '${calories.toStringAsFixed(0)} kcal · '
      '${fat.toStringAsFixed(1)}g fat · '
      '${carb.toStringAsFixed(1)}g carb · '
      '${protein.toStringAsFixed(1)}g protein';

  @override
  String toString() => 'NutritionResult($summary)';

  /// Serialize to JSON for storage/passing between screens.
  Map<String, dynamic> toJson() => {
    'mass': mass,
    'calories': calories,
    'fat': fat,
    'carb': carb,
    'protein': protein,
    'calorieLevel': calorieLevel,
    'r2Calories': r2Calories,
    'maeCalories': maeCalories,
  };
}

// ── Exception ─────────────────────────────────────────────────────────────────

class NutritionApiException implements Exception {
  final String message;
  final int?   statusCode;
  const NutritionApiException(this.message, {this.statusCode});
  @override
  String toString() => 'NutritionApiException[$statusCode]: $message';
}

// ── Service ───────────────────────────────────────────────────────────────────

class CalorieInferenceService {
  static const Duration _timeout = Duration(seconds: 45);

  String get _baseUrl => ApiConfig.calorieApi;

  // ── Ping ──────────────────────────────────────────────────────────────────
  /// Call this when the screen loads to warm up the API early.
  Future<bool> init() async {
    try {
      final resp = await http
          .get(Uri.parse('$_baseUrl/health'))
          .timeout(_timeout);
      return resp.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ── RGB only ──────────────────────────────────────────────────────────────
  /// Send [imageBytes] to /predict. Depth is handled server-side (grey fallback).
  Future<NutritionResult> predict(Uint8List imageBytes) async {
    return _postMultipart(
      endpoint: '/predict',
      files: [
        _makeFile('image', imageBytes, 'image.jpg'),
      ],
    );
  }

  // ── RGB + depth ───────────────────────────────────────────────────────────
  /// Send RGB + depth to /predict_with_depth for better accuracy.
  Future<NutritionResult> predictWithDepth(
    Uint8List imageBytes,
    Uint8List depthBytes,
  ) async {
    return _postMultipart(
      endpoint: '/predict_with_depth',
      files: [
        _makeFile('image', imageBytes, 'image.jpg'),
        _makeFile('depth', depthBytes, 'depth.png'),
      ],
    );
  }

  // ── Internal helpers ──────────────────────────────────────────────────────
  http.MultipartFile _makeFile(
      String field, Uint8List bytes, String filename) {
    final isJpeg = filename.endsWith('.jpg') || filename.endsWith('.jpeg');
    return http.MultipartFile.fromBytes(
      field,
      bytes,
      filename: filename,
      contentType: MediaType('image', isJpeg ? 'jpeg' : 'png'),
    );
  }

  Future<NutritionResult> _postMultipart({
    required String endpoint,
    required List<http.MultipartFile> files,
  }) async {
    final uri     = Uri.parse('$_baseUrl$endpoint');
    final request = http.MultipartRequest('POST', uri)..files.addAll(files);

    http.StreamedResponse streamed;
    try {
      streamed = await request.send().timeout(_timeout);
    } on Exception catch (e) {
      throw NutritionApiException('Network error: $e');
    }

    final response = await http.Response.fromStream(streamed);
    if (response.statusCode != 200) {
      throw NutritionApiException(
        'Server error: ${response.body}',
        statusCode: response.statusCode,
      );
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return NutritionResult.fromJson(json);
  }
}
