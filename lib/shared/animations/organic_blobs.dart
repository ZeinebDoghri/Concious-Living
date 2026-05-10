import 'dart:math';
import 'package:flutter/material.dart';

/// Paints a single organic morphing blob.
class OrganicBlobPainter extends CustomPainter {
  final double t;
  final Color color;
  final Offset center;
  final double radius;

  const OrganicBlobPainter({
    required this.t,
    required this.color,
    required this.center,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [color.withOpacity(0.25), color.withOpacity(0.0)],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    const int points = 8;
    final List<Offset> pts = List.generate(points, (i) {
      final angle = (i / points) * 2 * pi;
      final variation = radius * 0.25 * sin(t + i * 1.3);
      final r = radius + variation;
      return Offset(center.dx + r * cos(angle), center.dy + r * sin(angle));
    });

    final path = Path()..moveTo(pts[0].dx, pts[0].dy);
    for (int i = 0; i < points; i++) {
      final next = pts[(i + 1) % points];
      final mid = Offset(
        (pts[i].dx + next.dx) / 2,
        (pts[i].dy + next.dy) / 2,
      );
      path.quadraticBezierTo(pts[i].dx, pts[i].dy, mid.dx, mid.dy);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(OrganicBlobPainter old) => old.t != t;
}

/// Animated blobs widget — overlays multiple morphing blobs on the background.
class AnimatedBlobs extends StatefulWidget {
  final Color color;
  final int count;

  const AnimatedBlobs({super.key, required this.color, this.count = 3});

  @override
  State<AnimatedBlobs> createState() => _AnimatedBlobsState();
}

class _AnimatedBlobsState extends State<AnimatedBlobs>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 9),
    )..repeat();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, _) {
        final t = _ctrl.value * 2 * pi;
        return CustomPaint(
          painter: _MultiBlobPainter(
            t: t,
            color: widget.color,
            count: widget.count,
          ),
          size: Size.infinite,
        );
      },
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }
}

class _MultiBlobPainter extends CustomPainter {
  final double t;
  final Color color;
  final int count;

  _MultiBlobPainter({
    required this.t,
    required this.color,
    required this.count,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final configs = [
      (Offset(size.width * .85, size.height * .15), size.width * .32, 7.0),
      (Offset(size.width * .15, size.height * .75), size.width * .22, 9.0),
      (Offset(size.width * .55, size.height * .85), size.width * .14, 11.0),
      (Offset(size.width * .7, size.height * .5), size.width * .12, 8.0),
      (Offset(size.width * .3, size.height * .25), size.width * .10, 13.0),
    ];

    for (int i = 0; i < count && i < configs.length; i++) {
      final (center, radius, speed) = configs[i];
      final angle = t / speed * 2 * pi;
      final painter = OrganicBlobPainter(
        t: t * (1.0 + i * 0.3),
        color: color,
        center: Offset(
          center.dx + cos(angle) * radius * .2,
          center.dy + sin(angle) * radius * .2,
        ),
        radius: radius,
      );
      painter.paint(canvas, size);
    }
  }

  @override
  bool shouldRepaint(_MultiBlobPainter old) => old.t != t;
}
