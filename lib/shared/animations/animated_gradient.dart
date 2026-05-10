import 'package:flutter/material.dart';

/// A full-width hero container kept for compatibility, without animated visuals.
class AnimatedGradientHero extends StatelessWidget {
  final List<Color> colors;
  final Widget child;
  final double height;
  final BorderRadiusGeometry? borderRadius;

  const AnimatedGradientHero({
    super.key,
    required this.colors,
    required this.child,
    this.height = 260,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        color: colors.isEmpty ? Colors.transparent : colors.first,
      ),
      child: child,
    );
  }
}
