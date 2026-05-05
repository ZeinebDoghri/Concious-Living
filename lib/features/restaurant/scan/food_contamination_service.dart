import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:conscious_living/core/api_config.dart';

class ContaminationDetection {
  final String label;
  final double confidence;
  final List<double> bbox;

  const ContaminationDetection({
    required this.label,
    required this.confidence,
    required this.bbox,
  });

  factory ContaminationDetection.fromJson(Map<String, dynamic> json) =>
      ContaminationDetection(
        label: json['label'] as String,
        confidence: (json['confidence'] as num).toDouble(),
        bbox: (json['bbox'] as List).map((v) => (v as num).toDouble()).toList(),
      );

  Map<String, dynamic> toJson() => {
        'label': label,
        'confidence': confidence,
        'bbox': bbox,
      };
}

class FoodAnalysisResult {
  final String label; // "clean" or "contaminated"
  final double confidence; // 0-100
  final double cleanPct;
  final double contaminatedPct;
  final bool yoloOverrode;
  final List<ContaminationDetection> detections;
  final int detectionCount;

  bool get isContaminated => label == 'contaminated';
  bool get isClean => label == 'clean';

  const FoodAnalysisResult({
    required this.label,
    required this.confidence,
    required this.cleanPct,
    required this.contaminatedPct,
    required this.yoloOverrode,
    required this.detections,
    required this.detectionCount,
  });

  factory FoodAnalysisResult.fromJson(Map<String, dynamic> json) =>
      FoodAnalysisResult(
        label: json['label'] as String,
        confidence: (json['confidence'] as num).toDouble(),
        cleanPct: (json['clean_pct'] as num).toDouble(),
        contaminatedPct: (json['contaminated_pct'] as num).toDouble(),
        yoloOverrode: json['yolo_overrode'] as bool,
        detections: (json['detections'] as List)
            .map((d) =>
                ContaminationDetection.fromJson(d as Map<String, dynamic>))
            .toList(),
        detectionCount: json['detection_count'] as int,
      );

  Map<String, dynamic> toJson() => {
        'label': label,
        'confidence': confidence,
        'clean_pct': cleanPct,
        'contaminated_pct': contaminatedPct,
        'yolo_overrode': yoloOverrode,
        'detections': detections.map((d) => d.toJson()).toList(growable: false),
        'detection_count': detectionCount,
      };
}

class ContaminationScanResultPayload {
  final FoodAnalysisResult result;
  final Uint8List imageBytes;

  const ContaminationScanResultPayload({
    required this.result,
    required this.imageBytes,
  });
}

class FoodContaminationService {
  static const String _base = ApiConfig.contaminationApiBase;

  Future<bool> init() async {
    try {
      final resp = await http
          .get(Uri.parse('$_base/health'))
          .timeout(const Duration(seconds: 15));
      return resp.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<FoodAnalysisResult> analyze(Uint8List imageBytes) async {
    final request =
        http.MultipartRequest('POST', Uri.parse('$_base/analyze'))
          ..files.add(http.MultipartFile.fromBytes(
            'image',
            imageBytes,
            filename: 'image.jpg',
            contentType: MediaType('image', 'jpeg'),
          ));
    final streamed =
        await request.send().timeout(const Duration(seconds: 60));
    final resp = await http.Response.fromStream(streamed);
    if (resp.statusCode != 200) {
      throw Exception(
          'Contamination API error ${resp.statusCode}: ${resp.body}');
    }
    return FoodAnalysisResult.fromJson(
        jsonDecode(resp.body) as Map<String, dynamic>);
  }
}
