import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;

// Web stub — no dart:ffi, no onnxruntime.
//
// Produces smooth segmentation that visually resembles the real Mask2Former
// output by using a downscale → classify → majority-vote smooth → upscale pipeline.
//
// Palette and blend are EXACT copies of the native (notebook) version:
//   PALETTE: 0=bg(original)  1=compostable(60,200,80)  2=non-compost(220,60,60)
//   Blend  : overlay[fg] = 0.55 * PALETTE[class] + 0.45 * original_pixel

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
/// Produces large coherent regions (like a real semantic segmentation model)
/// instead of noisy per-pixel decisions.
(Uint8List, int, int, int) _buildSmoothOverlay(img.Image? src, int W, int H) {
  // 1. Work at a small resolution for classification (avoids per-pixel noise)
  const kSmall = 96;
  final sw = (kSmall).clamp(1, W);
  final sh = (kSmall * H ~/ math.max(W, 1)).clamp(1, H);

  // Resize source to small canvas for classification
  final small = src != null
      ? img.copyResize(src, width: sw, height: sh,
          interpolation: img.Interpolation.average)
      : null;

  // 2. Classify each pixel in small canvas
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

  // 3. Apply 3×3 majority-vote smoothing (twice for extra coherence)
  var smoothed = _majoritySmooth(rawMask, sw, sh);
  smoothed = _majoritySmooth(smoothed, sw, sh);

  // 4. Upsample to original size (nearest-neighbour)
  final fullMask = Uint8List(W * H);
  for (int y = 0; y < H; y++) {
    for (int x = 0; x < W; x++) {
      final sx = (x * sw / W).floor().clamp(0, sw - 1);
      final sy = (y * sh / H).floor().clamp(0, sh - 1);
      fullMask[y * W + x] = smoothed[sy * sw + sx];
    }
  }

  // 5. Build overlay and count pixels
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
        case 1:
          out.setPixelRgb(x, y,
            (r * _kBlendOrig + _kCR * _kBlendColor).round(),
            (g * _kBlendOrig + _kCG * _kBlendColor).round(),
            (b * _kBlendOrig + _kCB * _kBlendColor).round());
          c1++;
        default:
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

/// 3×3 majority-vote smoothing pass.
Uint8List _majoritySmooth(Uint8List mask, int W, int H) {
  final out = Uint8List(W * H);
  for (int y = 0; y < H; y++) {
    for (int x = 0; x < W; x++) {
      final counts = [0, 0, 0];
      for (int dy = -1; dy <= 1; dy++) {
        for (int dx = -1; dx <= 1; dx++) {
          final nx = (x + dx).clamp(0, W - 1);
          final ny = (y + dy).clamp(0, H - 1);
          counts[mask[ny * W + nx]]++;
        }
      }
      // Pick class with most votes
      int best = 0;
      if (counts[1] > counts[best]) best = 1;
      if (counts[2] > counts[best]) best = 2;
      out[y * W + x] = best;
    }
  }
  return out;
}

/// Pixel-level food classifier based on colour.
/// Returns: 0=background, 1=compostable, 2=non-compostable
///
/// Rules calibrated for typical restaurant food images:
///   • Very bright white/grey (plate, table)   → background (0)
///   • Very dark (shadow, background)           → background (0)
///   • Green-dominant (veggies, herbs, salad)  → compostable (1)
///   • Yellow/orange (carrots, corn, peppers)  → compostable (1)  ← plant-based
///   • Red-dominant, low saturation (tomato)   → compostable (1)
///   • Brown/dark-red, meat-tone               → non-compostable (2)
///   • Dark processed orange (fried/nuggets)   → non-compostable (2)
///   • Default                                 → compostable (1)
int _classifyPixel(int r, int g, int b) {
  final brightness = (r + g + b) / 3.0;

  // ── Background ────────────────────────────────────────────────────────────
  if (r > 220 && g > 220 && b > 220) return 0;           // bright white plate
  if (brightness < 28) return 0;                          // near-black shadow
  final maxC = math.max(r, math.max(g, b));
  final minC = math.min(r, math.min(g, b));
  final saturation = maxC > 0 ? (maxC - minC) / maxC : 0.0;
  if (saturation < 0.09 && brightness > 155) return 0;   // unsaturated grey

  // ── Compostable: green-dominant (vegetables, herbs) ───────────────────────
  final greenness = g - math.max(r, b);
  if (greenness > 18) return 1;

  // ── Compostable: yellow / orange plant-based (carrots, corn, citrus) ──────
  // R high, G medium-high, B low — clearly saturated yellow/orange
  if (r > 160 && g > 110 && b < 70 && saturation > 0.35 &&
      (g.toDouble() / math.max(r, 1)) > 0.55) return 1;

  // ── Compostable: bright red (tomatoes, strawberries, peppers) ─────────────
  // Tomato: high R, low G & B, but not the dark/brownish meat tone
  if (r > 150 && g < 70 && b < 70 && brightness > 80 && brightness < 200) {
    // Distinguish tomato-red (more vivid) from dark meat (darker, lower brightness)
    if (brightness > 100) return 1; // bright vivid red → tomato/pepper
  }

  // ── Non-compostable: meat tones (brown, dark-red, processed) ─────────────
  // Dark meat / cooked protein: medium R, low G, very low B, lowish brightness
  if (r > 90 && r > g + 30 && g > b + 10 && b < 90 && brightness < 170) return 2;
  // Deep dark red meat (rare meat, sausage)
  if (r > 110 && g < 72 && b < 65 && brightness < 140) return 2;
  // Fried / processed food: dark orange-brown with low saturation
  if (r > 155 && g > 90 && g < 140 && b < 80 &&
      r > g * 1.18 && saturation > 0.2 && brightness < 175) return 2;

  // ── Default: compostable ──────────────────────────────────────────────────
  return 1;
}
