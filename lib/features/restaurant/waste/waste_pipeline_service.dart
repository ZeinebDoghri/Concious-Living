import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../../../core/models/waste_pipeline_result.dart';

class WastePipelineException implements Exception {
  final String message;
  final int? statusCode;

  WastePipelineException(this.message, {this.statusCode});

  @override
  String toString() =>
      'WastePipelineException(statusCode: $statusCode, message: $message)';
}

class WastePipelineService {
  WastePipelineService({required this.baseUrl, http.Client? client})
    : _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  Uri _analyzeUri({required bool useClassifierGate}) {
    return Uri.parse('$baseUrl/analyze').replace(
      queryParameters: {'use_classifier_gate': useClassifierGate.toString()},
    );
  }

  Future<WastePipelineResult> analyze(
    Uint8List imageBytes, {
    bool useClassifierGate = true,
  }) async {
    final analyzeUri = _analyzeUri(useClassifierGate: useClassifierGate);
    debugPrint('[WastePipeline] POST $analyzeUri (bytes=${imageBytes.length})');
    final request = http.MultipartRequest('POST', analyzeUri)
      ..files.add(
        http.MultipartFile.fromBytes(
          'file',
          imageBytes,
          filename: 'image.jpg',
          contentType: MediaType('image', 'jpeg'),
        ),
      );

    final streamed = await request.send().timeout(const Duration(seconds: 90));
    final response = await http.Response.fromStream(streamed);

    debugPrint(
      '[WastePipeline] status=${response.statusCode} body=${response.body.length}',
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw WastePipelineException(
        'Server error. Please try again later.',
        statusCode: response.statusCode,
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw WastePipelineException('Invalid response format from server.');
    }

    final result = WastePipelineResult.fromJson(decoded);
    debugPrint(
      '[WastePipeline] top=${result.topClasses.length} det=${result.detections.length} mass=${result.massEstimates.length}',
    );
    return result;
  }

  void dispose() {
    _client.close();
  }
}
