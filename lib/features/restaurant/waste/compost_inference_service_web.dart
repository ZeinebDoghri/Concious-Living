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
/// Applies a fake segmentation overlay on the real image:
///   • Centre area  → compostable (emerald tint)  — e.g. vegetables/salad
///   • Right region → non-compostable (rose tint) — e.g. meat
///   • Edges        → background (original pixels)
Uint8List _buildMockOverlay(img.Image? src, int W, int H) {
  const blendOrig  = 0.42;
  const blendColor = 0.58;

  final out = img.Image(width: W, height: H, numChannels: 3);
  final rng = math.Random(42); // fixed seed for deterministic look

  for (int y = 0; y < H; y++) {
    for (int x = 0; x < W; x++) {
      final nx = x / W;
      final ny = y / H;

      // Get original pixel (or grey if no image)
      int r = 120, g = 120, b = 120;
      if (src != null) {
        final p = src.getPixel(x, y);
        r = p.r.toInt();
        g = p.g.toInt();
        b = p.b.toInt();
      }

      // Smooth noise for organic-looking edges
      final noise = (rng.nextDouble() - 0.5) * 0.08;
      final dist = math.sqrt(
          math.pow(nx - 0.5, 2) + math.pow(ny - 0.48, 2));

      if (dist > 0.44 + noise) {
        // Background — original pixel
        out.setPixelRgb(x, y, r, g, b);
      } else if (nx < 0.50 + noise) {
        // Compostable — emerald tint
        out.setPixelRgb(x, y,
          (r * blendOrig + 16  * blendColor).round(),
          (g * blendOrig + 185 * blendColor).round(),
          (b * blendOrig + 129 * blendColor).round());
      } else {
        // Non-compostable — rose tint
        out.setPixelRgb(x, y,
          (r * blendOrig + 239 * blendColor).round(),
          (g * blendOrig + 68  * blendColor).round(),
          (b * blendOrig + 68  * blendColor).round());
      }
    }
  }
  return Uint8List.fromList(img.encodePng(out));
}
