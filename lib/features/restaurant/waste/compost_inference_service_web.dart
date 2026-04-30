import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;

// Web stub — no dart:ffi, no onnxruntime.
// Decodes the real image and applies a realistic segmentation overlay using
// the pure-Dart image package (safe on web — no dart:ffi).

// ── Result (mirrors native version) ───────────────────────────────────────────
class CompostInferenceResult {
  /// PNG = original image with coloured segmentation overlay
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

// ── Web stub service ───────────────────────────────────────────────────────────
class CompostInferenceService {
  bool get isModelLoaded => false;

  Future<bool> init() async => false;

  Future<CompostInferenceResult> classify(Uint8List imageBytes) async {
    // Simulate inference latency
    await Future.delayed(const Duration(milliseconds: 920));

    final rng        = math.Random();
    final compost    = 38.0 + rng.nextDouble() * 32;
    final nonCompost = 18.0 + rng.nextDouble() * 22;
    final bg         = 100.0 - compost - nonCompost;

    // Decode the actual image so the overlay looks realistic
    final src = img.decodeImage(imageBytes);
    final int W = src?.width  ?? 320;
    final int H = src?.height ?? 240;

    final overlayPng = _buildMockOverlay(src, W, H);

    return CompostInferenceResult(
      maskPng: overlayPng,
      compostablePct: compost,
      nonCompostablePct: nonCompost,
      backgroundPct: bg,
      inferenceTimeMs: 920,
      originalWidth: W,
      originalHeight: H,
    );
  }

  void dispose() {}
}

// ── Realistic overlay mock ─────────────────────────────────────────────────────
/// Applies a segmentation overlay matching the Kaggle notebook output:
///   • Plate centre left  → compostable (vivid lime-green)  — vegetables/salad
///   • Plate centre right → non-compostable (vivid red)     — meat/processed
///   • Edges/background   → original pixel (plate, table…)
///
/// Uses 25 % original texture + 75 % pure class colour — same as native service.
Uint8List _buildMockOverlay(img.Image? src, int W, int H) {
  // Class colours — identical to native service
  const cr = 50;  const cg = 210; const cb = 50;  // compostable lime-green
  const nr = 220; const ng = 30;  const nb = 30;  // non-compostable red
  const blendOrig  = 0.25;
  const blendColor = 0.75;

  final out = img.Image(width: W, height: H, numChannels: 3);
  final rng = math.Random(42); // fixed seed → deterministic organic edge

  for (int y = 0; y < H; y++) {
    for (int x = 0; x < W; x++) {
      final nx = x / W;
      final ny = y / H;

      // Original pixel (grey fallback if no image)
      int r = 130, g = 110, b = 90;
      if (src != null) {
        final p = src.getPixel(x, y);
        r = p.r.toInt();
        g = p.g.toInt();
        b = p.b.toInt();
      }

      // Organic noise to soften the boundary (like a real segmentation model)
      final noise = (rng.nextDouble() - 0.5) * 0.07;
      final dist  = math.sqrt(
          math.pow(nx - 0.50, 2) + math.pow(ny - 0.47, 2));

      if (dist > 0.43 + noise) {
        // Background — original pixel (plate border, table…)
        out.setPixelRgb(x, y, r, g, b);
      } else if (nx < 0.52 + noise * 0.5) {
        // Compostable — vivid lime-green (matches Kaggle green)
        out.setPixelRgb(x, y,
          (r * blendOrig + cr * blendColor).round(),
          (g * blendOrig + cg * blendColor).round(),
          (b * blendOrig + cb * blendColor).round());
      } else {
        // Non-compostable — vivid red (matches Kaggle red)
        out.setPixelRgb(x, y,
          (r * blendOrig + nr * blendColor).round(),
          (g * blendOrig + ng * blendColor).round(),
          (b * blendOrig + nb * blendColor).round());
      }
    }
  }
  return Uint8List.fromList(img.encodePng(out));
}
