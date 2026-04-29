import 'dart:math' as math;
import 'dart:typed_data';

// Web stub — no dart:ffi, no onnxruntime, no image package needed.
// Returns a realistic mock result so the UI is fully demo-able in the browser.

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
      maskPng: _createMockPng(),
      compostablePct: compost,
      nonCompostablePct: nonCompost,
      backgroundPct: bg,
      inferenceTimeMs: 920,
      originalWidth: 640,
      originalHeight: 480,
    );
  }

  void dispose() {}
}

/// Minimal valid 1×1 transparent PNG (68 bytes).
Uint8List _createMockPng() {
  return Uint8List.fromList([
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
    0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
    0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
    0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
    0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41,
    0x54, 0x78, 0x9C, 0x62, 0x00, 0x00, 0x00, 0x02,
    0x00, 0x01, 0xE2, 0x21, 0xBC, 0x33, 0x00, 0x00,
    0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42,
    0x60, 0x82,
  ]);
}
