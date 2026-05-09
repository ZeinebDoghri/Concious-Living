import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'food_contamination_service.dart';

class AnnotatedContaminationImage extends StatelessWidget {
  final Uint8List imageBytes;
  final List<ContaminationDetection> detections;

  const AnnotatedContaminationImage({
    super.key,
    required this.imageBytes,
    required this.detections,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ui.Image>(
      future: _decodeImage(imageBytes),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const AspectRatio(
            aspectRatio: 1,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final decoded = snapshot.data!;
        final aspectRatio = decoded.width / decoded.height;

        return AspectRatio(
          aspectRatio: aspectRatio,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.memory(
                  imageBytes,
                  fit: BoxFit.contain,
                ),
                CustomPaint(
                  painter: _DetectionPainter(
                    detections: detections,
                    imageSize: Size(
                      decoded.width.toDouble(),
                      decoded.height.toDouble(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<ui.Image> _decodeImage(Uint8List bytes) {
    final completer = Completer<ui.Image>();
    ui.decodeImageFromList(bytes, (image) => completer.complete(image));
    return completer.future;
  }
}

class _DetectionPainter extends CustomPainter {
  final List<ContaminationDetection> detections;
  final Size imageSize;

  _DetectionPainter({
    required this.detections,
    required this.imageSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final fitted = applyBoxFit(BoxFit.contain, imageSize, size);
    final destination = Alignment.center.inscribe(fitted.destination, Offset.zero & size);
    final scaleX = destination.width / imageSize.width;
    final scaleY = destination.height / imageSize.height;

    final boxPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = const Color(0xFFEF4444);

    final fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFFEF4444).withValues(alpha: 0.12);

    for (final detection in detections) {
      if (detection.bbox.length < 4) {
        continue;
      }

      final isNormalized = detection.bbox.every((value) => value <= 1.5);
      final x1 = isNormalized ? detection.bbox[0] * imageSize.width : detection.bbox[0];
      final y1 = isNormalized ? detection.bbox[1] * imageSize.height : detection.bbox[1];
      final x2 = isNormalized ? detection.bbox[2] * imageSize.width : detection.bbox[2];
      final y2 = isNormalized ? detection.bbox[3] * imageSize.height : detection.bbox[3];

      final left = destination.left + (x1 * scaleX);
      final top = destination.top + (y1 * scaleY);
      final right = destination.left + (x2 * scaleX);
      final bottom = destination.top + (y2 * scaleY);
      final rect = Rect.fromLTRB(left, top, right, bottom);

      canvas.drawRect(rect, fillPaint);
      canvas.drawRect(rect, boxPaint);

      final label = detection.label;
      final textPainter = TextPainter(
        text: TextSpan(
          text: '$label ${(detection.confidence * 100).toStringAsFixed(0)}%',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: size.width - 16);

      final labelOffset = Offset(
        rect.left,
        (rect.top - textPainter.height - 8).clamp(0, size.height - textPainter.height).toDouble(),
      );
      final labelBg = RRect.fromRectAndRadius(
        Rect.fromLTWH(labelOffset.dx, labelOffset.dy, textPainter.width + 12, textPainter.height + 8),
        const Radius.circular(8),
      );

      canvas.drawRRect(labelBg, Paint()..color = const Color(0xFF111827).withValues(alpha: 0.88));
      textPainter.paint(canvas, labelOffset + const Offset(6, 4));
    }
  }

  @override
  bool shouldRepaint(covariant _DetectionPainter oldDelegate) {
    return oldDelegate.detections != detections || oldDelegate.imageSize != imageSize;
  }
}