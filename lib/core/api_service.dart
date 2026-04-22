import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'constants.dart';
import 'models/nutrient_result.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => 'ApiException(statusCode: $statusCode, message: $message)';
}

class ApiService {
  static Future<NutrientResult> predictNutrients(File image) async {
    final uri = Uri.parse('$apiBaseUrl/predict/nutrients');

    final request = http.MultipartRequest('POST', uri);
    request.files.add(await http.MultipartFile.fromPath('image', image.path));

    http.StreamedResponse streamed;
    try {
      streamed = await request.send().timeout(const Duration(seconds: 30));
    } on TimeoutException {
      throw ApiException('Request timed out. Please try again.');
    } on SocketException {
      throw ApiException('Network error. Please check your connection.');
    } catch (e) {
      throw ApiException('Unexpected error: $e');
    }

    final response = await http.Response.fromStream(streamed);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        'Server error. Please try again later.',
        statusCode: response.statusCode,
      );
    }

    final dynamic decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw ApiException('Invalid response format from server.');
    }

    return NutrientResult.fromJson(decoded);
  }









  static Future<Map<String, dynamic>> predictFreshness(File image) async {
    await Future.delayed(const Duration(seconds: 2));
    return {'status': 'expiring', 'confidence': 0.87, 'daysLeft': 2};
    // NOTE: replace with POST $apiBaseUrl/predict/freshness
  }

  static Future<Map<String, dynamic>> predictCompost(File image) async {
    await Future.delayed(const Duration(seconds: 2));
    return {
      'isCompostable': true,
      'confidence': 0.91,
      'category': 'Vegetable scraps',
    };
    // NOTE: replace with POST $apiBaseUrl/predict/compost
  }

  static Future<Map<String, dynamic>> predictWaste(File image) async {
    await Future.delayed(const Duration(seconds: 2));
    return {
      'detectedItems': [
        {'name': 'Bread', 'quantityKg': 0.4},
        {'name': 'Rice', 'quantityKg': 0.2},
      ],
      'confidence': 0.89,
    };
    // NOTE: replace with POST $apiBaseUrl/predict/waste
  }
}
