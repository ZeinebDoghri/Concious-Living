import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:onnxruntime/onnxruntime.dart';

// Input size for SegFormer-B3 (must match training)
const int _kImgSize = 384;
// Output size from SegFormer (downsampled 4x from input)
const int _kOutSize = 96;
const int _kNumClasses = 3;

// ImageNet normalisation stats
const _mean = [0.485, 0.456, 0.406];
const _std = [0.229, 0.224, 0.225];

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
  OrtSession? _session;
  bool _modelLoaded = false;

  bool get isModelLoaded => _modelLoaded;

  Future<bool> init() async {
    try {
      OrtEnv.instance.init();
      final rawAsset = await rootBundle.load(
        'assets/models/compost_segformer_b3.onnx',
      );
      final bytes = rawAsset.buffer.asUint8List();
      final opts = OrtSessionOptions();
      _session = OrtSession.fromBuffer(bytes, opts);
      _modelLoaded = true;
      debugPrint('[Compost] ONNX model loaded successfully');
      return true;
    } catch (e) {
      debugPrint('[Compost] Could not load ONNX model: $e');
      _modelLoaded = false;
      return false;
    }
  }

  Future<CompostInferenceResult> classify(Uint8List imageBytes) async {
    final stopwatch = Stopwatch()..start();

    final srcImage = img.decodeImage(imageBytes);
    if (srcImage == null) throw Exception('Could not decode image');

    final originalWidth = srcImage.width;
    final originalHeight = srcImage.height;

    if (!_modelLoaded || _session == null) {
      return _mockResult(originalWidth, originalHeight, stopwatch);
    }

    final result = await compute(
      _runInference,
      _InferenceInput(
        imageBytes: imageBytes,
        sessionPtr: _session!,
        originalWidth: originalWidth,
        originalHeight: originalHeight,
      ),
    );

    stopwatch.stop();
    return result.copyWithTime(stopwatch.elapsedMilliseconds);
  }

  void dispose() {
    _session?.release();
    OrtEnv.instance.release();
  }
}

// ── Isolate payload ──────────────────────────────────────────────────────────

class _InferenceInput {
  final Uint8List imageBytes;
  final OrtSession sessionPtr;
  final int originalWidth;
  final int originalHeight;

  const _InferenceInput({
    required this.imageBytes,
    required this.sessionPtr,
    required this.originalWidth,
    required this.originalHeight,
  });
}

CompostInferenceResult _runInference(_InferenceInput input) {
  final sw = Stopwatch()..start();

  final srcImage = img.decodeImage(input.imageBytes)!;

  // 1. Resize to 384×384
  final resized = img.copyResize(
    srcImage,
    width: _kImgSize,
    height: _kImgSize,
    interpolation: img.Interpolation.linear,
  );

  // 2. Build float32 NCHW tensor [1, 3, 384, 384]
  final tensorData = Float32List(_kImgSize * _kImgSize * _kNumClasses);
  for (int y = 0; y < _kImgSize; y++) {
    for (int x = 0; x < _kImgSize; x++) {
      final pixel = resized.getPixel(x, y);
      final r = pixel.r / 255.0;
      final g = pixel.g / 255.0;
      final b = pixel.b / 255.0;
      final idx = y * _kImgSize + x;
      tensorData[0 * _kImgSize * _kImgSize + idx] = (r - _mean[0]) / _std[0];
      tensorData[1 * _kImgSize * _kImgSize + idx] = (g - _mean[1]) / _std[1];
      tensorData[2 * _kImgSize * _kImgSize + idx] = (b - _mean[2]) / _std[2];
    }
  }

  // 3. Run ONNX inference
  final inputOrt = OrtValueTensor.createTensorWithDataList(
    tensorData,
    [1, _kNumClasses, _kImgSize, _kImgSize],
  );
  final runOptions = OrtRunOptions();
  final outputs = input.sessionPtr.run(
    runOptions,
    {'pixel_values': inputOrt},
  );
  inputOrt.release();
  runOptions.release();

  // 4. Argmax on class dim → mask [96×96]
  final logits = outputs[0]!.value as List;
  final flat = logits[0] as List;
  final mask = Uint8List(_kOutSize * _kOutSize);
  for (int i = 0; i < _kOutSize * _kOutSize; i++) {
    double maxVal = double.negativeInfinity;
    int maxClass = 0;
    for (int c = 0; c < _kNumClasses; c++) {
      double val;
      if (flat[c] is List) {
        final row = flat[c] as List;
        final col = row[i ~/ _kOutSize] as List;
        val = (col[i % _kOutSize] as num).toDouble();
      } else {
        val = (flat[c * _kOutSize * _kOutSize + i] as num).toDouble();
      }
      if (val > maxVal) {
        maxVal = val;
        maxClass = c;
      }
    }
    mask[i] = maxClass;
  }
  for (final o in outputs) {
    o?.release();
  }

  // 5. Upsample to original size (nearest neighbour)
  final W = input.originalWidth;
  final H = input.originalHeight;
  final upsampled = Uint8List(W * H);
  for (int y = 0; y < H; y++) {
    for (int x = 0; x < W; x++) {
      final srcX = (x * _kOutSize / W).floor().clamp(0, _kOutSize - 1);
      final srcY = (y * _kOutSize / H).floor().clamp(0, _kOutSize - 1);
      upsampled[y * W + x] = mask[srcY * _kOutSize + srcX];
    }
  }

  // 6. Count pixels per class
  int compostCount = 0, nonCompostCount = 0, bgCount = 0;
  for (final v in upsampled) {
    if (v == 1) {
      compostCount++;
    } else if (v == 2) {
      nonCompostCount++;
    } else {
      bgCount++;
    }
  }
  final total = W * H;

  // 7. Render mask PNG (RGBA overlay)
  final maskImage = img.Image(width: W, height: H, numChannels: 4);
  for (int i = 0; i < upsampled.length; i++) {
    final x = i % W;
    final y = i ~/ W;
    switch (upsampled[i]) {
      case 1: // compostable — emerald
        maskImage.setPixelRgba(x, y, 16, 185, 129, 153);
      case 2: // non-compostable — red
        maskImage.setPixelRgba(x, y, 239, 68, 68, 153);
      default: // background — slate
        maskImage.setPixelRgba(x, y, 148, 163, 184, 50);
    }
  }
  final maskPng = Uint8List.fromList(img.encodePng(maskImage));
  sw.stop();

  return CompostInferenceResult(
    maskPng: maskPng,
    compostablePct: compostCount / total * 100,
    nonCompostablePct: nonCompostCount / total * 100,
    backgroundPct: bgCount / total * 100,
    inferenceTimeMs: sw.elapsedMilliseconds,
    originalWidth: W,
    originalHeight: H,
  );
}

// ── Mock (model not loaded) ──────────────────────────────────────────────────

CompostInferenceResult _mockResult(int w, int h, Stopwatch sw) {
  final rng = math.Random();
  final compost = 40.0 + rng.nextDouble() * 30;
  final nonCompost = 20.0 + rng.nextDouble() * 20;
  final bg = 100.0 - compost - nonCompost;

  final maskImage = img.Image(width: w, height: h, numChannels: 4);
  for (int y = 0; y < h; y++) {
    for (int x = 0; x < w; x++) {
      final nx = x / w;
      final ny = y / h;
      if (nx < 0.5 && ny < 0.5) {
        maskImage.setPixelRgba(x, y, 16, 185, 129, 153);
      } else if (nx > 0.5) {
        maskImage.setPixelRgba(x, y, 239, 68, 68, 153);
      } else {
        maskImage.setPixelRgba(x, y, 148, 163, 184, 50);
      }
    }
  }
  final maskPng = Uint8List.fromList(img.encodePng(maskImage));
  sw.stop();

  return CompostInferenceResult(
    maskPng: maskPng,
    compostablePct: compost,
    nonCompostablePct: nonCompost,
    backgroundPct: bg,
    inferenceTimeMs: sw.elapsedMilliseconds,
    originalWidth: w,
    originalHeight: h,
  );
}
