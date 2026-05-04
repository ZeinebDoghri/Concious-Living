import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:conscious_living/core/models/waste_pipeline_result.dart';

void main() {
  test('WastePipelineResult round-trips JSON and computes totals', () {
    final original = WastePipelineResult(
      topClasses: const [
        WasteTopClass(label: 'rice', confidence: 0.93, rank: 1),
        WasteTopClass(label: 'bread', confidence: 0.81, rank: 2),
      ],
      detections: const [
        WasteDetection(
          label: 'rice',
          confidence: 0.91,
          pixelCount: 1200,
          maskFraction: 0.32,
          sourceClass: 'rice',
        ),
      ],
      massEstimates: const [
        WasteMassEstimate(
          label: 'rice',
          estimatedKg: 0.42,
          pixelCount: 1200,
          gramsPerPixel: 0.35,
          sourceClass: 'rice',
        ),
        WasteMassEstimate(
          label: 'bread',
          estimatedKg: 0.18,
          pixelCount: 600,
          gramsPerPixel: 0.30,
          sourceClass: 'bread',
        ),
      ],
      overlayPng: Uint8List.fromList([1, 2, 3]),
      classifierTimeMs: 120,
      segmenterTimeMs: 340,
      massCalculationTimeMs: 55,
      originalWidth: 1024,
      originalHeight: 768,
      notes: 'hf-pipeline',
    );

    final json = original.toJson();
    expect(json['total_waste_kg'], closeTo(0.60, 1e-9));
    expect(json['pipeline_time_ms'], 515);

    final restored = WastePipelineResult.fromJson(json);
    expect(restored.topClasses.length, 2);
    expect(restored.detections.single.label, 'rice');
    expect(restored.massEstimates.length, 2);
    expect(restored.totalWasteKg, closeTo(0.60, 1e-9));
    expect(restored.pipelineTimeMs, 515);
    expect(restored.overlayPng, isNotNull);
    expect(base64Encode(restored.overlayPng!), base64Encode(Uint8List.fromList([1, 2, 3])));
  });

  test('WasteDetection and WasteMassEstimate parse HF-style keys', () {
    final detection = WasteDetection.fromJson({
      'class_name': 'pasta',
      'confidence': 0.77,
      'mask_pixels': 900,
      'mask_fraction': 0.21,
      'sourceClass': 'pasta',
    });

    final estimate = WasteMassEstimate.fromJson({
      'name': 'pasta',
      'estimated_kg': 0.31,
      'pixels': 900,
      'grams_per_pixel': 0.34,
      'sourceClass': 'pasta',
    });

    expect(detection.label, 'pasta');
    expect(detection.pixelCount, 900);
    expect(detection.maskFraction, closeTo(0.21, 1e-9));
    expect(estimate.label, 'pasta');
    expect(estimate.pixelCount, 900);
    expect(estimate.estimatedKg, closeTo(0.31, 1e-9));
  });
}