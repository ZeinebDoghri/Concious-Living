import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;

// Web stub — no dart:ffi, no onnxruntime.
//
// Generates a realistic segmentation overlay using the EXACT same
// palette and blend formula as the real Mask2Former model (CELL C):
//
//   PALETTE: 0=bg(original)  1=compostable(60,200,80)  2=non-compost(220,60,60)
//   Blend  : overlay[fg] = 0.55 * PALETTE[class] + 0.45 * original_pixel
//
// The mock segmentation uses pixel-colour analysis (green → compost,
// brown/red → non-compost, white/dark → background) so the coloured
// zones actually follow the food content of the image.

// ── Exact palette from notebook CELL 4 ────────────────────────────────────────
const _kCR = 60;  const _kCG = 200; const _kCB = 80;   // compostable lime-green
const _kNR = 220; const _kNG = 60;  const _kNB = 60;   // non-compostable red
const double _kBlendColor = 0.55;
const double _kBlendOrig  = 0.45;

// ── Result (mirrors native) ────────────────────────────────────────────────────
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

// ── Web stub service ───────────────────────────────────────────────────────────
class CompostInferenceService {
  bool get isModelLoaded => false;

  Future<bool> init() async => false;

  Future<CompostInferenceResult> classify(Uint8List imageBytes) async {
    await Future.delayed(const Duration(milliseconds: 920));

    final src = img.decodeImage(imageBytes);
    final W   = src?.width  ?? 320;
    final H   = src?.height ?? 240;

    final (overlay, c1, c2, c0) = _buildSmartOverlay(src, W, H);
    final total = W * H;

    return CompostInferenceResult(
      maskPng: overlay,
      compostablePct:    c1 / total * 100,
      nonCompostablePct: c2 / total * 100,
      backgroundPct:     c0 / total * 100,
      inferenceTimeMs: 920,
      originalWidth:  W,
      originalHeight: H,
    );
  }

  void dispose() {}
}

// ── Smart colour-heuristic overlay ────────────────────────────────────────────
/// Classifies each pixel using colour analysis — produces realistic-looking
/// segmentation that follows the actual food content of the image.
///
/// Rules (simplified FoodSeg103 → compost/non-compost mapping):
///   • Very bright (plate, white table)      → background (0)
///   • Very dark (shadow, dark background)   → background (0)
///   • Green-dominant (veggies, herbs, salad)→ compostable (1)
///   • Red/brown dominant + meat-like saturation → non-compostable (2)
///   • Otherwise → compostable (1)   (most food is compostable)
(Uint8List, int, int, int) _buildSmartOverlay(img.Image? src, int W, int H) {
  final out = img.Image(width: W, height: H, numChannels: 3);
  int c0 = 0, c1 = 0, c2 = 0;

  for (int y = 0; y < H; y++) {
    for (int x = 0; x < W; x++) {
      // Get source pixel
      int r = 128, g = 100, b = 80;
      if (src != null) {
        final p = src.getPixel(x, y);
        r = p.r.toInt();
        g = p.g.toInt();
        b = p.b.toInt();
      }

      final cls = _classifyPixel(r, g, b);

      switch (cls) {
        case 0: // background — original pixel
          out.setPixelRgb(x, y, r, g, b);
          c0++;
        case 1: // compostable — lime-green tint
          out.setPixelRgb(x, y,
            (r * _kBlendOrig + _kCR * _kBlendColor).round(),
            (g * _kBlendOrig + _kCG * _kBlendColor).round(),
            (b * _kBlendOrig + _kCB * _kBlendColor).round());
          c1++;
        default: // non-compostable — red tint
          out.setPixelRgb(x, y,
            (r * _kBlendOrig + _kNR * _kBlendColor).round(),
            (g * _kBlendOrig + _kNG * _kBlendColor).round(),
            (b * _kBlendOrig + _kNB * _kBlendColor).round());
          c2++;
      }
    }
  }

  return (Uint8List.fromList(img.encodePng(out)), c1, c2, c0);
}

/// Pixel-level food classifier based on colour.
/// Returns: 0=background, 1=compostable, 2=non-compostable
int _classifyPixel(int r, int g, int b) {
  final brightness = (r + g + b) / 3;

  // ── Background detection ──────────────────────────────────────────────────
  // Very bright white → plate/table
  if (r > 215 && g > 215 && b > 215) return 0;
  // Very dark → shadow/black background
  if (brightness < 30) return 0;
  // Neutral grey → table/plate border
  final maxC = math.max(r, math.max(g, b));
  final minC = math.min(r, math.min(g, b));
  final saturation = maxC > 0 ? (maxC - minC) / maxC : 0.0;
  if (saturation < 0.08 && brightness > 160) return 0; // unsaturated light → bg

  // ── Compostable: green-dominant pixels (vegetables, herbs, salad) ─────────
  final greenness = g - math.max(r, b);
  if (greenness > 20) return 1; // clearly green → compostable

  // ── Non-compostable: meat tones (brown/dark-red, low green, low blue) ─────
  // Brown meat: r high, g medium, b low, r > g significantly
  if (r > 100 && r > g + 25 && g > b && b < 100 && brightness < 180) return 2;
  // Dark red (cooked meat, sausage)
  if (r > 120 && g < 80 && b < 80) return 2;
  // Orange-brown (fried food, processed)
  if (r > 160 && g > 90 && g < 145 && b < 90 && r > g * 1.15) return 2;

  // ── Default: compostable (most food items are plant-based) ───────────────
  return 1;
}
