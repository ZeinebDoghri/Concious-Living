import 'dart:math' as math;

import 'package:flutter/material.dart';

enum AmbientRole { customer, restaurant, hotel }

class RoleAnimatedBackground extends StatefulWidget {
  final AmbientRole role;
  final int activeIndex;
  final double intensity;
  final Widget child;

  const RoleAnimatedBackground({
    super.key,
    required this.role,
    required this.activeIndex,
    this.intensity = 1.0,
    required this.child,
  });

  @override
  State<RoleAnimatedBackground> createState() => _RoleAnimatedBackgroundState();
}

class _RoleAnimatedBackgroundState extends State<RoleAnimatedBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(
        milliseconds: (7200 / widget.intensity.clamp(0.75, 2.0)).round(),
      ),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        RepaintBoundary(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (_, _) => CustomPaint(
              painter: _AmbientPainter(
                role: widget.role,
                activeIndex: widget.activeIndex,
                intensity: widget.intensity,
                t: _controller.value,
                layer: _AmbientLayer.back,
              ),
            ),
          ),
        ),
        widget.child,
        // front layer removed — no more particles drawn over the white card
      ],
    );
  }
}

enum _AmbientLayer { back, front }

class _AmbientPainter extends CustomPainter {
  final AmbientRole role;
  final int activeIndex;
  final double intensity;
  final double t;
  final _AmbientLayer layer;

  const _AmbientPainter({
    required this.role,
    required this.activeIndex,
    required this.intensity,
    required this.t,
    required this.layer,
  });

  @override
  void paint(Canvas canvas, Size size) {
    switch (role) {
      case AmbientRole.customer:
        _paintCustomer(canvas, size);
      case AmbientRole.restaurant:
        _paintRestaurant(canvas, size);
      case AmbientRole.hotel:
        _paintHotel(canvas, size);
    }
  }

  void _paintCustomer(Canvas canvas, Size size) {
    final primary = const Color(0xFFA78BFA);
    final pink = const Color(0xFFF9A8D4);
    final mint = const Color(0xFF86EFAC);
    final blue = const Color(0xFF7DD3FC);
    final phase = t * math.pi * 2;
    final boost = intensity.clamp(0.8, 2.0);
    final opacity = (layer == _AmbientLayer.back ? 0.19 : 0.12) * boost;

    _drawWave(
      canvas,
      size,
      color: primary.withValues(alpha: opacity),
      y: size.height * (0.18 + activeIndex * 0.025),
      amp: 22 * boost,
      phase: phase,
      stroke: layer == _AmbientLayer.back ? 6 : 2.8,
    );
    _drawWave(
      canvas,
      size,
      color: pink.withValues(alpha: opacity * 0.85),
      y: size.height * 0.72,
      amp: 28 * boost,
      phase: -phase * 0.85,
      stroke: layer == _AmbientLayer.back ? 5 : 2.4,
    );

    final count = (24 * boost).round();
    for (var i = 0; i < count; i++) {
      final seed = i * 1.73 + activeIndex * 0.31;
      final x =
          ((math.sin(seed) * 0.5 + 0.5) * size.width +
              math.sin(phase + seed) * 32 * boost) %
          size.width;
      final y =
          ((math.cos(seed * 1.4) * 0.5 + 0.5) * size.height +
              math.cos(phase * 0.72 + seed) * 42 * boost) %
          size.height;
      final r = 4.0 + (i % 5) * 2.6;
      final color = [primary, pink, mint, blue][i % 4];
      canvas.drawCircle(
        Offset(x, y),
        r,
        Paint()..color = color.withValues(alpha: opacity * 0.75),
      );
      if (i % 2 == 0) {
        _drawSparkle(
          canvas,
          Offset(x, y),
          5 + math.sin(phase + i) * 2,
          color.withValues(alpha: opacity * 1.4),
        );
      }
    }
  }

  void _paintRestaurant(Canvas canvas, Size size) {
    final rose = const Color(0xFFF2A7A7);
    final coral = const Color(0xFFE47878);
    final butter = const Color(0xFFFFAB5B);
    final fresh = const Color(0xFF52C98A);
    final phase = t * math.pi * 2;
    final boost = intensity.clamp(0.8, 2.0);
    final opacity = (layer == _AmbientLayer.back ? 0.18 : 0.115) * boost;

    for (var i = 0; i < (8 * boost).round(); i++) {
      final x = size.width * (0.12 + i * 0.16);
      final yBase = size.height * (0.20 + (i % 3) * 0.22);
      final path = Path()..moveTo(x, yBase + 80);
      for (var s = 0; s <= 28; s++) {
        final p = s / 28;
        path.lineTo(
          x + math.sin(phase * 0.7 + p * math.pi * 3 + i) * 24 * boost,
          yBase + 80 - p * 170,
        );
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = (i.isEven ? rose : butter).withValues(alpha: opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = layer == _AmbientLayer.back ? 6 : 2.6
          ..strokeCap = StrokeCap.round,
      );
    }

    for (var i = 0; i < (22 * boost).round(); i++) {
      final a = phase + i * 0.62;
      final center = Offset(
        size.width * (0.18 + (i % 4) * 0.22),
        size.height * (0.16 + (i % 5) * 0.17),
      );
      final wobble = Offset(
        math.cos(a) * 24 * boost,
        math.sin(a * 0.8) * 20 * boost,
      );
      final color = [rose, coral, butter, fresh][i % 4];
      canvas.save();
      canvas.translate(center.dx + wobble.dx, center.dy + wobble.dy);
      canvas.rotate(a * 0.25);
      final rect = Rect.fromCenter(
        center: Offset.zero,
        width: 7 + (i % 3) * 3,
        height: 7 + (i % 2) * 4,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(3)),
        Paint()..color = color.withValues(alpha: opacity * 1.2),
      );
      canvas.restore();
    }

    _drawOrbit(
      canvas,
      Offset(size.width * 0.78, size.height * 0.20),
      82 + math.sin(phase) * 10,
      coral.withValues(alpha: opacity * 0.8),
    );
  }

  void _paintHotel(Canvas canvas, Size size) {
    final sage = const Color(0xFF7DC5A0);
    final mint = const Color(0xFFC8EDD9);
    final teal = const Color(0xFF4A8A6A);
    final cream = const Color(0xFFF4FAF7);
    final phase = t * math.pi * 2;
    final boost = intensity.clamp(0.8, 2.0);
    final opacity = (layer == _AmbientLayer.back ? 0.19 : 0.105) * boost;

    for (var i = -5; i < 17; i++) {
      final x = i * 62.0 + math.sin(phase + i) * 22 * boost;
      final path = Path()
        ..moveTo(x, -20)
        ..quadraticBezierTo(
          x + 58,
          size.height * 0.35 + math.sin(phase + i) * 22,
          x + 6,
          size.height + 40,
        );
      canvas.drawPath(
        path,
        Paint()
          ..color = mint.withValues(alpha: opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = layer == _AmbientLayer.back ? 4.5 : 2
          ..strokeCap = StrokeCap.round,
      );
    }

    for (var i = 0; i < (22 * boost).round(); i++) {
      final seed = i * 0.91 + activeIndex * 0.4;
      final center = Offset(
        size.width * ((0.08 + i * 0.071) % 1.0),
        size.height * (0.12 + ((i * 0.19) % 0.78)),
      );
      final pos =
          center +
          Offset(
            math.sin(phase + seed) * 28 * boost,
            math.cos(phase * 0.8 + seed) * 24 * boost,
          );
      _drawLeaf(
        canvas,
        pos,
        10 + (i % 4) * 2.5,
        phase * 0.35 + seed,
        [sage, mint, teal, cream][i % 4].withValues(alpha: opacity * 1.15),
      );
    }
  }

  void _drawWave(
    Canvas canvas,
    Size size, {
    required Color color,
    required double y,
    required double amp,
    required double phase,
    required double stroke,
  }) {
    final path = Path()..moveTo(-20, y);
    for (double x = -20; x <= size.width + 20; x += 16) {
      path.lineTo(
        x,
        y + math.sin((x / size.width) * math.pi * 3 + phase) * amp,
      );
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  void _drawSparkle(Canvas canvas, Offset c, double r, Color color) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(c + Offset(-r, 0), c + Offset(r, 0), paint);
    canvas.drawLine(c + Offset(0, -r), c + Offset(0, r), paint);
  }

  void _drawOrbit(Canvas canvas, Offset center, double radius, Color color) {
    canvas.drawOval(
      Rect.fromCenter(center: center, width: radius * 1.7, height: radius),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  void _drawLeaf(
    Canvas canvas,
    Offset center,
    double radius,
    double rotation,
    Color color,
  ) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);
    final path = Path()
      ..moveTo(0, -radius)
      ..cubicTo(radius, -radius * 0.45, radius, radius * 0.45, 0, radius)
      ..cubicTo(-radius, radius * 0.45, -radius, -radius * 0.45, 0, -radius);
    canvas.drawPath(path, Paint()..color = color);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_AmbientPainter oldDelegate) =>
      oldDelegate.t != t ||
      oldDelegate.activeIndex != activeIndex ||
      oldDelegate.intensity != intensity ||
      oldDelegate.role != role ||
      oldDelegate.layer != layer;
}