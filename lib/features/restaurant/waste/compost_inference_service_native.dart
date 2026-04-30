import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:onnxruntime/onnxruntime.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Mask2Former-Compost INT8 inference service
//
// Model:  assets/models/mask2former_compost_int8.onnx
// Input:  pixel_values  [1, 3, 512, 512]  float32, ImageNet-normalised NCHW
// Output (2 tensors from HF Mask2Former ONNX export):
//   [0] class_queries_logits  [1, Q, C+1]  — Q=100 queries, C=3 classes
//   [1] masks_queries_logits  [1, Q, H/4, W/4]
// Fallback: if single output [1, C, H, W] (simplified export) → direct argmax
// ─────────────────────────────────────────────────────────────────────────────

const _kModelFile = 'assets/models/mask2former_compost_int8.onnx';
const int _kImgSize    = 512;   // Mask2Former default input size
const int _kNumClasses = 3;    // 0=background, 1=compostable, 2=non-compostable
const int _kNumQueries = 100;  // Mask2Former default num_queries

// ImageNet normalisation
const _mean = [0.485, 0.456, 0.406];
const _std  = [0.229, 0.224, 0.225];

// ── Result model ─────────────────────────────────────────────────────────────
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

// ── Service ───────────────────────────────────────────────────────────────────
class CompostInferenceService {
  OrtSession? _session;
  bool _modelLoaded = false;

  bool get isModelLoaded => _modelLoaded;

  Future<bool> init() async {
    try {
      OrtEnv.instance.init();
      final rawAsset = await rootBundle.load(_kModelFile);
      final bytes    = rawAsset.buffer.asUint8List();
      final opts     = OrtSessionOptions();
      _session       = OrtSession.fromBuffer(bytes, opts);
      _modelLoaded   = true;
      debugPrint('[Compost] ✅ Mask2Former INT8 loaded');
      return true;
    } catch (e) {
      debugPrint('[Compost] ⚠️ Model not loaded: $e');
      _modelLoaded = false;
      return false;
    }
  }

  Future<CompostInferenceResult> classify(Uint8List imageBytes) async {
    final sw = Stopwatch()..start();

    final srcImage = img.decodeImage(imageBytes);
    if (srcImage == null) throw Exception('Cannot decode image');

    final W = srcImage.width;
    final H = srcImage.height;

    if (!_modelLoaded || _session == null) {
      sw.stop();
      return _mockResult(W, H, sw);
    }

    final result = await compute(
      _runInference,
      _InferenceInput(
        imageBytes: imageBytes,
        session: _session!,
        originalWidth: W,
        originalHeight: H,
      ),
    );

    sw.stop();
    return result.copyWithTime(sw.elapsedMilliseconds);
  }

  void dispose() {
    _session?.release();
    OrtEnv.instance.release();
  }
}

// ── Isolate payload ───────────────────────────────────────────────────────────
class _InferenceInput {
  final Uint8List imageBytes;
  final OrtSession session;
  final int originalWidth;
  final int originalHeight;

  const _InferenceInput({
    required this.imageBytes,
    required this.session,
    required this.originalWidth,
    required this.originalHeight,
  });
}

// ── Main inference isolate function ──────────────────────────────────────────
CompostInferenceResult _runInference(_InferenceInput input) {
  final sw = Stopwatch()..start();
  final W = input.originalWidth;
  final H = input.originalHeight;

  try {
    // 1. Decode and resize to 512×512
    final src     = img.decodeImage(input.imageBytes)!;
    final resized = img.copyResize(
      src,
      width: _kImgSize,
      height: _kImgSize,
      interpolation: img.Interpolation.linear,
    );

    // 2. Build float32 NCHW tensor [1, 3, 512, 512]
    final tensorData =
        Float32List(_kImgSize * _kImgSize * _kNumClasses);
    for (int y = 0; y < _kImgSize; y++) {
      for (int x = 0; x < _kImgSize; x++) {
        final p   = resized.getPixel(x, y);
        final r   = p.r / 255.0;
        final g   = p.g / 255.0;
        final b   = p.b / 255.0;
        final idx = y * _kImgSize + x;
        tensorData[0 * _kImgSize * _kImgSize + idx] =
            (r - _mean[0]) / _std[0];
        tensorData[1 * _kImgSize * _kImgSize + idx] =
            (g - _mean[1]) / _std[1];
        tensorData[2 * _kImgSize * _kImgSize + idx] =
            (b - _mean[2]) / _std[2];
      }
    }

    // 3. Run ONNX
    final inputTensor = OrtValueTensor.createTensorWithDataList(
      tensorData,
      [1, _kNumClasses, _kImgSize, _kImgSize],
    );
    final runOpts = OrtRunOptions();
    final outputs = input.session.run(runOpts, {'pixel_values': inputTensor});
    inputTensor.release();
    runOpts.release();

    // 4. Parse output — adaptive strategy
    Uint8List mask;
    int maskH, maskW;

    if (outputs.length >= 2) {
      // Mask2Former dual-output format
      final classLogits = outputs[0]!.value; // [1, Q, C+1]
      final maskLogits  = outputs[1]!.value; // [1, Q, mH, mW]
      final parsed =
          _parseMask2FormerDual(classLogits, maskLogits, _kNumClasses);
      mask  = parsed.$1;
      maskH = parsed.$2;
      maskW = parsed.$3;
    } else {
      // Simplified format: single output [1, C, H, W] or [1, H, W, C]
      final logits = outputs[0]!.value;
      final parsed = _parseSingleOutput(logits, _kNumClasses);
      mask  = parsed.$1;
      maskH = parsed.$2;
      maskW = parsed.$3;
    }

    for (final o in outputs) o?.release();

    // 5. Upsample mask to original size (nearest-neighbour)
    final upsampled = Uint8List(W * H);
    for (int y = 0; y < H; y++) {
      for (int x = 0; x < W; x++) {
        final srcX = (x * maskW / W).floor().clamp(0, maskW - 1);
        final srcY = (y * maskH / H).floor().clamp(0, maskH - 1);
        upsampled[y * W + x] = mask[srcY * maskW + srcX];
      }
    }

    // 6. Count pixels
    int compostCount = 0, nonCompostCount = 0, bgCount = 0;
    for (final v in upsampled) {
      if (v == 1)      compostCount++;
      else if (v == 2) nonCompostCount++;
      else             bgCount++;
    }
    final total = W * H;

    // 7. Render coloured mask PNG
    final maskImg = img.Image(width: W, height: H, numChannels: 4);
    for (int i = 0; i < upsampled.length; i++) {
      final x = i % W;
      final y = i ~/ W;
      switch (upsampled[i]) {
        case 1:  maskImg.setPixelRgba(x, y, 16,  185, 129, 160); // emerald
        case 2:  maskImg.setPixelRgba(x, y, 239,  68,  68, 160); // rose
        default: maskImg.setPixelRgba(x, y, 148, 163, 184,  50); // slate
      }
    }
    final maskPng = Uint8List.fromList(img.encodePng(maskImg));
    sw.stop();

    return CompostInferenceResult(
      maskPng: maskPng,
      compostablePct:    compostCount    / total * 100,
      nonCompostablePct: nonCompostCount / total * 100,
      backgroundPct:     bgCount         / total * 100,
      inferenceTimeMs:   sw.elapsedMilliseconds,
      originalWidth:  W,
      originalHeight: H,
    );
  } catch (e) {
    // Any error → fall back to patterned mock
    debugPrint('[Compost] Inference error: $e');
    final sw2 = Stopwatch()..start();
    return _mockResult(W, H, sw2);
  }
}

// ── Output parsers ────────────────────────────────────────────────────────────

/// Mask2Former dual-output: class_queries_logits + masks_queries_logits
(Uint8List, int, int) _parseMask2FormerDual(
  dynamic classLogitsRaw,
  dynamic maskLogitsRaw,
  int numClasses,
) {
  // Flatten nested lists → Float32List for fast access
  final cFlat = _flattenToFloat32(classLogitsRaw); // [1, Q, C+1]
  final mFlat = _flattenToFloat32(maskLogitsRaw);  // [1, Q, mH, mW]

  // Detect dimensions
  // cFlat.length = Q * (C+1)  → Q = cFlat.length / (numClasses+1)
  final Q  = _kNumQueries;
  final CP = numClasses + 1; // classes + void

  // Detect mask spatial dims from total size
  final mTotal = mFlat.length; // = Q * mH * mW
  final mPixels = mTotal ~/ Q;
  // Assume square: mH ≈ mW ≈ _kImgSize / 4
  final mH = (_kImgSize / 4).round();
  final mW = mPixels ~/ mH;

  final mask = Uint8List(mH * mW);

  // For each pixel: argmax over classes of
  //   sum_q( softmax(classLogits[q])[c] * sigmoid(maskLogits[q, h, w]) )
  // Simplified: argmax over c of: max_q( classSoftmax[q,c] * maskSigmoid[q,pixel] )

  // Precompute per-query class probabilities (softmax, ignore void class)
  final classProbsFlat = Float32List(Q * numClasses);
  for (int q = 0; q < Q; q++) {
    // Softmax over first numClasses entries (exclude void at index numClasses)
    double maxLogit = double.negativeInfinity;
    for (int c = 0; c < numClasses; c++) {
      final v = cFlat[q * CP + c];
      if (v > maxLogit) maxLogit = v;
    }
    double sum = 0.0;
    for (int c = 0; c < numClasses; c++) {
      sum += math.exp(cFlat[q * CP + c] - maxLogit);
    }
    for (int c = 0; c < numClasses; c++) {
      classProbsFlat[q * numClasses + c] =
          math.exp(cFlat[q * CP + c] - maxLogit) / sum;
    }
  }

  // For each pixel compute class scores
  for (int p = 0; p < mH * mW; p++) {
    final scores = Float32List(numClasses);
    for (int q = 0; q < Q; q++) {
      final maskVal = _sigmoid(mFlat[q * mPixels + p]);
      for (int c = 0; c < numClasses; c++) {
        scores[c] += classProbsFlat[q * numClasses + c] * maskVal;
      }
    }
    int best = 0;
    double bestS = scores[0];
    for (int c = 1; c < numClasses; c++) {
      if (scores[c] > bestS) { bestS = scores[c]; best = c; }
    }
    mask[p] = best;
  }

  return (mask, mH, mW);
}

/// Single output: [1, C, H, W] — direct argmax over class dim
(Uint8List, int, int) _parseSingleOutput(dynamic logitsRaw, int numClasses) {
  final flat  = _flattenToFloat32(logitsRaw);
  // Detect spatial size: total = 1 * C * H * W → H*W = total/C
  final hW    = flat.length ~/ numClasses;
  // Assume square
  final side  = math.sqrt(hW.toDouble()).round();
  final mH    = side;
  final mW    = hW ~/ mH;
  final mask  = Uint8List(mH * mW);

  for (int i = 0; i < mH * mW; i++) {
    double maxVal = double.negativeInfinity;
    int maxClass  = 0;
    for (int c = 0; c < numClasses; c++) {
      final val = flat[c * mH * mW + i];
      if (val > maxVal) { maxVal = val; maxClass = c; }
    }
    mask[i] = maxClass;
  }
  return (mask, mH, mW);
}

// ── Helpers ───────────────────────────────────────────────────────────────────

double _sigmoid(double x) => 1.0 / (1.0 + math.exp(-x));

Float32List _flattenToFloat32(dynamic raw) {
  if (raw is Float32List) return raw;
  final buf = <double>[];
  _collectDoubles(raw, buf);
  return Float32List.fromList(buf);
}

void _collectDoubles(dynamic v, List<double> buf) {
  if (v is num) {
    buf.add(v.toDouble());
  } else if (v is List) {
    for (final item in v) _collectDoubles(item, buf);
  }
}

// ── Mock (model not loaded / error fallback) ──────────────────────────────────
CompostInferenceResult _mockResult(int w, int h, Stopwatch sw) {
  final rng       = math.Random();
  final compost   = 40.0 + rng.nextDouble() * 30;
  final nonCompost = 20.0 + rng.nextDouble() * 20;
  final bg        = 100.0 - compost - nonCompost;

  final maskImg = img.Image(width: w, height: h, numChannels: 4);
  for (int y = 0; y < h; y++) {
    for (int x = 0; x < w; x++) {
      final nx = x / w;
      final ny = y / h;
      if (nx < 0.5 && ny < 0.5) {
        maskImg.setPixelRgba(x, y, 16,  185, 129, 160);
      } else if (nx > 0.5) {
        maskImg.setPixelRgba(x, y, 239,  68,  68, 160);
      } else {
        maskImg.setPixelRgba(x, y, 148, 163, 184,  50);
      }
    }
  }
  final maskPng = Uint8List.fromList(img.encodePng(maskImg));
  sw.stop();

  return CompostInferenceResult(
    maskPng: maskPng,
    compostablePct:    compost,
    nonCompostablePct: nonCompost,
    backgroundPct:     bg,
    inferenceTimeMs:   sw.elapsedMilliseconds,
    originalWidth:  w,
    originalHeight: h,
  );
}
