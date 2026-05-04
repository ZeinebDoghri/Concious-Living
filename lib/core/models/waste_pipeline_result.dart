import 'dart:convert';
import 'dart:typed_data';

class WasteTopClass {
  final String label;
  final double confidence;
  final int rank;

  const WasteTopClass({
    required this.label,
    required this.confidence,
    required this.rank,
  });

  Map<String, dynamic> toJson() => {
        'label': label,
        'confidence': confidence,
        'rank': rank,
      };

  factory WasteTopClass.fromJson(Map<String, dynamic> json) {
    return WasteTopClass(
      label: (json['label'] ?? json['class_name'] ?? '') as String,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0,
      rank: (json['rank'] as num?)?.toInt() ?? 0,
    );
  }
}

class WasteDetection {
  final String label;
  final double confidence;
  final int pixelCount;
  final double maskFraction;
  final String? sourceClass;

  const WasteDetection({
    required this.label,
    required this.confidence,
    required this.pixelCount,
    required this.maskFraction,
    this.sourceClass,
  });

  Map<String, dynamic> toJson() => {
        'label': label,
        'confidence': confidence,
        'pixelCount': pixelCount,
        'maskFraction': maskFraction,
        if (sourceClass != null) 'sourceClass': sourceClass,
      };

  factory WasteDetection.fromJson(Map<String, dynamic> json) {
    return WasteDetection(
      label: (json['label'] ?? json['class_name'] ?? json['name'] ?? '') as String,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0,
      pixelCount: (json['pixelCount'] ?? json['mask_pixels'] ?? json['pixels'] as Object?) is num
          ? (json['pixelCount'] ?? json['mask_pixels'] ?? json['pixels'] as num).toInt()
          : 0,
      maskFraction: (json['maskFraction'] ?? json['mask_fraction'] as Object?) is num
          ? (json['maskFraction'] ?? json['mask_fraction'] as num).toDouble()
          : 0,
      sourceClass: json['sourceClass'] as String?,
    );
  }
}

class WasteMassEstimate {
  final String label;
  final double estimatedKg;
  final int pixelCount;
  final double gramsPerPixel;
  final String? sourceClass;

  const WasteMassEstimate({
    required this.label,
    required this.estimatedKg,
    required this.pixelCount,
    required this.gramsPerPixel,
    this.sourceClass,
  });

  Map<String, dynamic> toJson() => {
        'label': label,
        'estimatedKg': estimatedKg,
        'pixelCount': pixelCount,
        'gramsPerPixel': gramsPerPixel,
        if (sourceClass != null) 'sourceClass': sourceClass,
      };

  factory WasteMassEstimate.fromJson(Map<String, dynamic> json) {
    return WasteMassEstimate(
      label: (json['label'] ?? json['class_name'] ?? json['name'] ?? '') as String,
      estimatedKg: (json['estimatedKg'] ?? json['estimated_kg'] as Object?) is num
          ? (json['estimatedKg'] ?? json['estimated_kg'] as num).toDouble()
          : 0,
      pixelCount: (json['pixelCount'] ?? json['mask_pixels'] ?? json['pixels'] as Object?) is num
          ? (json['pixelCount'] ?? json['mask_pixels'] ?? json['pixels'] as num).toInt()
          : 0,
      gramsPerPixel: (json['gramsPerPixel'] ?? json['grams_per_pixel'] as Object?) is num
          ? (json['gramsPerPixel'] ?? json['grams_per_pixel'] as num).toDouble()
          : 0,
      sourceClass: json['sourceClass'] as String?,
    );
  }
}

class WastePipelineResult {
  final List<WasteTopClass> topClasses;
  final List<int> activeClassIds;
  final List<double> classifierProbabilities;
  final List<WasteDetection> detections;
  final List<WasteMassEstimate> massEstimates;
  final Uint8List? overlayPng;
  final int classifierTimeMs;
  final int segmenterTimeMs;
  final int massCalculationTimeMs;
  final int originalWidth;
  final int originalHeight;
  final String? notes;

  const WastePipelineResult({
    required this.topClasses,
    this.activeClassIds = const [],
    this.classifierProbabilities = const [],
    required this.detections,
    required this.massEstimates,
    required this.overlayPng,
    required this.classifierTimeMs,
    required this.segmenterTimeMs,
    required this.massCalculationTimeMs,
    required this.originalWidth,
    required this.originalHeight,
    this.notes,
  });

  double get totalWasteKg =>
      massEstimates.fold(0.0, (sum, item) => sum + item.estimatedKg);

  int get pipelineTimeMs =>
      classifierTimeMs + segmenterTimeMs + massCalculationTimeMs;

  Map<String, dynamic> toJson() => {
        'top_classes': topClasses.map((e) => e.toJson()).toList(growable: false),
      'active_classes': activeClassIds,
      'classifier_probs': classifierProbabilities,
        'detections': detections.map((e) => e.toJson()).toList(growable: false),
        'mass_estimates': massEstimates.map((e) => e.toJson()).toList(growable: false),
        'overlay_png_b64': overlayPng == null ? null : base64Encode(overlayPng!),
        'classifier_ms': classifierTimeMs,
        'segmenter_ms': segmenterTimeMs,
        'mass_calculation_ms': massCalculationTimeMs,
        'original_width': originalWidth,
        'original_height': originalHeight,
        'notes': notes,
        'total_waste_kg': totalWasteKg,
        'pipeline_time_ms': pipelineTimeMs,
      };

  factory WastePipelineResult.fromJson(Map<String, dynamic> json) {
    List<T> _parseList<T>(dynamic raw, T Function(Map<String, dynamic>) parser) {
      if (raw is List) {
        return raw
            .whereType<Map>()
            .map((item) => parser(item.map((k, v) => MapEntry(k.toString(), v))))
            .toList(growable: false);
      }
      return <T>[];
    }

    Uint8List? _parseBytes(dynamic raw) {
      if (raw is String && raw.isNotEmpty) {
        return base64Decode(raw);
      }
      return null;
    }

    int _readInt(dynamic value) => value is num ? value.toInt() : 0;

    List<int> _parseIntList(dynamic raw) {
      if (raw is! List) return <int>[];
      return raw.whereType<num>().map((value) => value.toInt()).toList(growable: false);
    }

    List<double> _parseDoubleList(dynamic raw) {
      if (raw is! List) return <double>[];
      return raw.whereType<num>().map((value) => value.toDouble()).toList(growable: false);
    }

    return WastePipelineResult(
      topClasses: _parseList(json['top_classes'], WasteTopClass.fromJson),
      activeClassIds: _parseIntList(json['active_classes']),
      classifierProbabilities: _parseDoubleList(json['classifier_probs']),
      detections: _parseList(json['detections'], WasteDetection.fromJson),
      massEstimates: _parseList(json['mass_estimates'], WasteMassEstimate.fromJson),
      overlayPng: _parseBytes(json['overlay_png_b64']),
      classifierTimeMs: _readInt(json['classifier_ms']),
      segmenterTimeMs: _readInt(json['segmenter_ms']),
      massCalculationTimeMs: _readInt(json['mass_calculation_ms']),
      originalWidth: _readInt(json['original_width']),
      originalHeight: _readInt(json['original_height']),
      notes: json['notes'] as String?,
    );
  }
}