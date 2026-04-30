/// compost_inference_service_web.dart
/// Web implementation — calls FastAPI backend on HuggingFace Spaces.
/// Returns exact SegFormer-B3 results (same as notebook).
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

// ── API config ────────────────────────────────────────────────────────────────
const _kApiBase    = 'https://touuuuuuuuuuta-compost-api.hf.space';
const _kSegmentUrl = '$_kApiBase/segment';
const _kHealthUrl  = '$_kApiBase/health';

// ── Result (mirrors native service exactly) ───────────────────────────────────
class CompostInferenceResult {
  final Uint8List maskPng;
  final double    compostablePct;
  final double    nonCompostablePct;
  final double    backgroundPct;
  final int       inferenceTimeMs;
  final int       originalWidth;
  final int       originalHeight;

  const CompostInferenceResult({
    required this.maskPng,
    required this.compostablePct,
    required this.nonCompostablePct,
    required this.backgroundPct,
    required this.inferenceTimeMs,
    required this.originalWidth,
    required this.originalHeight,
  });

  CompostInferenceResult copyWithTime(int ms) => CompostInferenceResult(
        maskPng:           maskPng,
        compostablePct:    compostablePct,
        nonCompostablePct: nonCompostablePct,
        backgroundPct:     backgroundPct,
        inferenceTimeMs:   ms,
        originalWidth:     originalWidth,
        originalHeight:    originalHeight,
      );

  Map<String, dynamic> toMap() => {
        'compostablePct':    compostablePct,
        'nonCompostablePct': nonCompostablePct,
        'backgroundPct':     backgroundPct,
        'inferenceTimeMs':   inferenceTimeMs,
        'maskPng':           maskPng,
        'originalWidth':     originalWidth,
        'originalHeight':    originalHeight,
      };
}

// ── Service ───────────────────────────────────────────────────────────────────
class CompostInferenceService {
  bool _apiReachable = false;
  bool get isModelLoaded => _apiReachable;

  /// Ping the API health endpoint. Returns true if reachable.
  Future<bool> init() async {
    try {
      final resp = await http
          .get(Uri.parse(_kHealthUrl))
          .timeout(const Duration(seconds: 8));
      _apiReachable = resp.statusCode == 200;
      debugPrint('[Compost-Web] API reachable: $_apiReachable');
    } catch (e) {
      debugPrint('[Compost-Web] API unreachable: $e');
      _apiReachable = false;
    }
    return _apiReachable;
  }

  /// Send image to FastAPI /segment → get real SegFormer-B3 result.
  Future<CompostInferenceResult> classify(Uint8List imageBytes) async {
    final request = http.MultipartRequest('POST', Uri.parse(_kSegmentUrl))
      ..files.add(http.MultipartFile.fromBytes(
        'image',
        imageBytes,
        filename: 'image.jpg',
        contentType: MediaType('image', 'jpeg'),  // required — server validates content-type
      ));

    final streamed = await request.send().timeout(const Duration(seconds: 60));
    final resp     = await http.Response.fromStream(streamed);

    if (resp.statusCode != 200) {
      throw Exception('[Compost-Web] API error ${resp.statusCode}: ${resp.body}');
    }

    final json    = jsonDecode(resp.body) as Map<String, dynamic>;
    final maskPng = base64Decode(json['mask_png_b64'] as String);

    return CompostInferenceResult(
      maskPng:           maskPng,
      compostablePct:    (json['compostable_pct'] as num).toDouble(),
      nonCompostablePct: (json['non_compost_pct']  as num).toDouble(),
      backgroundPct:     (json['background_pct']   as num).toDouble(),
      inferenceTimeMs:   json['inference_ms'] as int,
      originalWidth:     json['original_width']  as int,
      originalHeight:    json['original_height'] as int,
    );
  }

  void dispose() {}
}
