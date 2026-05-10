import 'package:flutter/material.dart';

enum AmbientRole { customer, restaurant, hotel }

class RoleAnimatedBackground extends StatelessWidget {
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
  Widget build(BuildContext context) => child;
}
