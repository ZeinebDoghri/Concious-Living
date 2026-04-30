import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;

// Web stub — no dart:ffi, no onnxruntime.
//
// Mimics the real Mask2Former output using a FoodSeg103-aware colour heuristic.
//
// ── Class mapping (EPA/WRAP rules — exact from notebook CELL 4) ───────────────
//   NON-COMPOST: meats (steak, pork, chicken, sausage, lamb, fried meat),
//                fish/seafood, dairy (cheese, butter, milk, egg, ice cream),
//                sweets (cake, chocolate, candy, biscuit), liquids (coffee, juice, wine),
//                processed dishes (pizza, burger, soup, hanamaki, wonton, pie, salad)
//   COMPOSTABLE: ALL individual fruits/veg (incl. tomato, strawberry, cherry…),
//                grains (bread, rice, pasta, corn), nuts, legumes, mushrooms, tofu, herbs
//
// ── Colour rules based on FoodSeg103 visual statistics ───────────────────────
//   Very vivid red (tomato, strawberry, cherry, pepper) → COMPOSTABLE
//   Green dominant  (vegetables, herbs)                 → COMPOSTABLE
//   Orange/yellow, high saturation (carrot, corn, citrus) → COMPOSTABLE
//   Brown/muted-red (steak, pork, fried meat)           → NON-COMPOSTABLE
//   White/neutral grey (plate, table, background)        → BACKGROUND
//
// ── Preprocessing pipeline (matches notebook predict_image exactly) ───────────
//   1. Downsample to 80px classification canvas (fast heuristic)
//   2. Classify each pixel with colour rules
//   3. 3×3 majority-vote smoothing (×2) → large coherent regions
//   4. Nearest-neighbour upsample → original W×H
//   5. Build overlay: 0.55 × PALETTE[class] + 0.45 × original_pixel
//
// ── Exact palette (notebook CELL 4) ──────────────────────────────────────────
//   class 0 background  → original pixel
//   class 1 compostable → RGB(60, 200, 80)  lime-green
//   class 2 non-compost → RGB(220, 60, 60)  bright red
const _kCR = 60;  const _kCG = 200; const _kCB = 80;
const _kNR = 220; const _kNG = 60;  const _kNB = 60;
const double _kBlendColor = 0.55;   // same as notebook: 0.55*color + 0.45*original
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

    final (overlay, c1, c2, c0) = _buildSmoothOverlay(src, W, H);
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

// ── Smooth segmentation pipeline ──────────────────────────────────────────────
/// Downscale → classify → majority-vote smooth → upsample.
/// Produces large coherent food regions that match real Mask2Former output.
(Uint8List, int, int, int) _buildSmoothOverlay(img.Image? src, int W, int H) {
  // Work at small resolution for coherent regions (avoids per-pixel noise)
  const kSmall = 80;
  final sw = kSmall.clamp(1, W);
  final sh = (kSmall * H ~/ math.max(W, 1)).clamp(1, H);

  // Downsample with averaging for better colour representation
  final small = src != null
      ? img.copyResize(src, width: sw, height: sh,
          interpolation: img.Interpolation.average)
      : null;

  // Classify each pixel in the small canvas
  final rawMask = Uint8List(sw * sh);
  for (int y = 0; y < sh; y++) {
    for (int x = 0; x < sw; x++) {
      int r = 128, g = 100, b = 80;
      if (small != null) {
        final p = small.getPixel(x, y);
        r = p.r.toInt(); g = p.g.toInt(); b = p.b.toInt();
      }
      rawMask[y * sw + x] = _classifyPixel(r, g, b);
    }
  }

  // Two passes of 3×3 majority-vote smoothing → large coherent regions
  var smoothed = _majoritySmooth(rawMask, sw, sh);
  smoothed     = _majoritySmooth(smoothed, sw, sh);

  // Nearest-neighbour upsample to original size
  final fullMask = Uint8List(W * H);
  for (int y = 0; y < H; y++) {
    for (int x = 0; x < W; x++) {
      final sx = (x * sw / W).floor().clamp(0, sw - 1);
      final sy = (y * sh / H).floor().clamp(0, sh - 1);
      fullMask[y * W + x] = smoothed[sy * sw + sx];
    }
  }

  // Build overlay and count pixels
  final out = img.Image(width: W, height: H, numChannels: 3);
  int c0 = 0, c1 = 0, c2 = 0;

  for (int y = 0; y < H; y++) {
    for (int x = 0; x < W; x++) {
      int r = 128, g = 100, b = 80;
      if (src != null) {
        final p = src.getPixel(x, y);
        r = p.r.toInt(); g = p.g.toInt(); b = p.b.toInt();
      }
      switch (fullMask[y * W + x]) {
        case 0:
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

/// 3×3 majority-vote smoothing — produces smooth region boundaries.
Uint8List _majoritySmooth(Uint8List mask, int W, int H) {
  final out = Uint8List(W * H);
  for (int y = 0; y < H; y++) {
    for (int x = 0; x < W; x++) {
      final votes = [0, 0, 0];
      for (int dy = -1; dy <= 1; dy++) {
        for (int dx = -1; dx <= 1; dx++) {
          final nx = (x + dx).clamp(0, W - 1);
          final ny = (y + dy).clamp(0, H - 1);
          votes[mask[ny * W + nx]]++;
        }
      }
      int best = 0;
      if (votes[1] > votes[best]) best = 1;
      if (votes[2] > votes[best]) best = 2;
      out[y * W + x] = best;
    }
  }
  return out;
}

// ── FoodSeg103-aware colour classifier ────────────────────────────────────────
/// Returns: 0=background, 1=compostable, 2=non-compostable
///
/// Based on the exact EPA/WRAP class mapping from notebook CELL 4:
///
/// NON-COMPOSTABLE (class 2) visual colours:
///   • Meat (steak/pork/lamb): warm brown  R>G>B, R>120, G:50-110, B<90
///   • Fried/processed meat: golden-brown  R>150, G:90-145, B<90
///   • Dark sausage/cooked: dark reddish-brown, low brightness
///   • Pale yellow (egg, cream, cheese butter): R≈G>B, low saturation
///
/// COMPOSTABLE (class 1) visual colours — KEY: vivid red = COMPOSTABLE:
///   • Tomato/strawberry/cherry/pepper: very VIVID pure red,  saturation > 0.55
///     → R>160, G<80, B<80, saturation > 0.55, R > G*2.5
///   • Green veg/herbs: G-dominant, greenness > 15
///   • Yellow/orange plant-based (carrot, corn, citrus, mango):
///     R>155, G>100, B<90, G/R>0.55, saturation>0.35
///   • Purple/blue fruits (blueberry, grape): B≈R>G, low overall
///
/// BACKGROUND (class 0):
///   • Bright white plate: all channels > 222
///   • Near-black shadow/bg: brightness < 25
///   • Neutral grey (unsaturated + bright): saturation < 0.09 + brightness > 150
int _classifyPixel(int r, int g, int b) {
  final brightness = (r + g + b) / 3.0;
  final maxC = math.max(r, math.max(g, b));
  final minC = math.min(r, math.min(g, b));
  final saturation = maxC > 0 ? (maxC - minC) / maxC : 0.0;

  // ══ BACKGROUND ═══════════════════════════════════════════════════════════
  if (r > 222 && g > 222 && b > 222) return 0;           // bright white plate
  if (brightness < 25) return 0;                          // near-black shadow
  if (saturation < 0.09 && brightness > 150) return 0;   // neutral grey (table)

  // ══ COMPOSTABLE: green-dominant (vegetables, herbs, lettuce, broccoli) ══
  final greenness = g - math.max(r, b);
  if (greenness > 15) return 1;

  // ══ COMPOSTABLE: VIVID RED (tomato, strawberry, cherry, red pepper) ═════
  // KEY FIX: tomatoes have very HIGH saturation pure red — not the brownish meat tone
  // R dominates strongly over G and B, G and B both very low
  if (r > 155 && g < 90 && b < 90 && saturation > 0.50 && r.toDouble() / math.max(g + 1, 1) > 2.2) {
    return 1; // vivid red = tomato / strawberry / red pepper → COMPOSTABLE
  }

  // ══ COMPOSTABLE: orange/yellow plant-based (carrot, corn, citrus, mango) ═
  // G must be a reasonable fraction of R (not too brownish)
  if (r > 155 && g > 100 && b < 90 && saturation > 0.35 &&
      g.toDouble() / math.max(r, 1) > 0.55) return 1;

  // ══ COMPOSTABLE: bright yellow (corn, banana, lemon) ═════════════════════
  if (r > 180 && g > 160 && b < 80 && saturation > 0.3) return 1;

  // ══ COMPOSTABLE: purple/dark blue fruits (blueberry, grape, blackberry) ══
  if (b > r && b > g && b > 80 && r < 130) return 1;

  // ══ COMPOSTABLE: pink fruits (peach, raspberry — pinkish tone) ═══════════
  if (r > 180 && g > 100 && g < 170 && b > 120 && saturation < 0.35) return 1;

  // ══ NON-COMPOST: classic meat (steak, pork, lamb) ════════════════════════
  // Warm brown: R>G>B, R clearly dominant, medium-low brightness
  if (r > 90 && r > g * 1.22 && g > b * 1.05 && b < 110 &&
      brightness < 185 && saturation > 0.12) return 2;

  // ══ NON-COMPOST: dark cooked meat / sausage ══════════════════════════════
  // Dark reddish-brown (not vivid enough for tomato):
  if (r > 100 && g < 85 && b < 75 && brightness < 145 && saturation > 0.15) return 2;

  // ══ NON-COMPOST: golden-fried / processed (nuggets, fried chicken, pastry)
  if (r > 155 && g > 95 && g < 155 && b < 85 &&
      r.toDouble() / math.max(g, 1) > 1.15 && saturation > 0.18 &&
      brightness < 195) return 2;

  // ══ NON-COMPOST: pale egg / cream / cheese (yellow-white, low saturation) =
  if (r > 190 && g > 165 && b < 140 && saturation > 0.08 && saturation < 0.32 &&
      brightness > 160) return 2;

  // ══ DEFAULT: compostable ══════════════════════════════════════════════════
  // Most unclassified food pixels are plant-based (grains, tofu, legumes, etc.)
  return 1;
}
