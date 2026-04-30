import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;

// Web stub — no dart:ffi, no onnxruntime.
// Uses the pure-Dart image package to generate a real coloured mask PNG.

class CompostInferenceResult {
  final Uint8List maskPng;
  final double compostablePct;
  final double nonCompostablePct;
  final double backgroundPct;
  final int inferenceTimeMs;
  final int originalWidth;
  final int originalHeight;

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
        maskPng: maskPng,
        compostablePct: compostablePct,
        nonCompostablePct: nonCompostablePct,
        backgroundPct: backgroundPct,
        inferenceTimeMs: ms,
        originalWidth: originalWidth,
        originalHeight: originalHeight,
      );

  Map<String, dynamic> toMap() => {
        'compostablePct': compostablePct,
        'nonCompostablePct': nonCompostablePct,
        'backgroundPct': backgroundPct,
        'inferenceTimeMs': inferenceTimeMs,
        'maskPng': maskPng,
        'originalWidth': originalWidth,
        'originalHeight': originalHeight,
      };
}

class CompostInferenceService {
  bool get isModelLoaded => false;

  Future<bool> init() async => false;

  Future<CompostInferenceResult> classify(Uint8List imageBytes) async {
    await Future.delayed(const Duration(milliseconds: 900));

    final rng = math.Random();
    final compost = 42.0 + rng.nextDouble() * 28;
    final nonCompost = 15.0 + rng.nextDouble() * 20;
    final bg = 100.0 - compost - nonCompost;

    return CompostInferenceResult(
      maskPng: _createMockPng(compost, nonCompost),
      compostablePct: compost,
      nonCompostablePct: nonCompost,
      backgroundPct: bg,
      inferenceTimeMs: 920,
      originalWidth: 320,
      originalHeight: 240,
    );
  }

  void dispose() {}
}

/// Generates a real 320×240 coloured segmentation mask PNG using the
/// pure-Dart image package (safe on web — no dart:ffi).
Uint8List _createMockPng(double compostPct, double nonCompostPct) {
  const w = 320;
  const h = 240;
  final mask = img.Image(width: w, height: h, numChannels: 4);
  final rng  = math.Random();

  for (int y = 0; y < h; y++) {
    for (int x = 0; x < w; x++) {
      final nx = x / w;
      final ny = y / h;
      // Left half + top-right quarter → compostable (emerald)
      if (nx < 0.55 && ny < 0.85) {
        mask.setPixelRgba(x, y, 16, 185, 129, 160);   // emerald
      } else if (nx > 0.6 || ny > 0.7) {
        mask.setPixelRgba(x, y, 239, 68, 68, 160);    // rose
      } else {
        mask.setPixelRgba(x, y, 148, 163, 184, 50);   // slate
      }
    }
  }
  return Uint8List.fromList(img.encodePng(mask));
}
