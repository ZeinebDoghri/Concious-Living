import 'package:flutter/material.dart';

/// A full-width hero container with a slowly animated gradient.
/// The gradient oscillates between the provided [colors] over 6 seconds.
class AnimatedGradientHero extends StatefulWidget {
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
  State<AnimatedGradientHero> createState() => _AnimatedGradientHeroState();
}

class _AnimatedGradientHeroState extends State<AnimatedGradientHero>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.colors;
    final c0 = c[0];
    final c1 = c.length > 1 ? c[1] : c[0];
    final c2 = c.length > 2 ? c[2] : c[0];

    return AnimatedBuilder(
      animation: _anim,
      builder: (_, child) {
        final t = _anim.value;
        return Container(
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.lerp(c0, c2, t)!,
                c1,
                Color.lerp(c2, c0, t)!,
              ],
              stops: [0.0, 0.5 + t * 0.2, 1.0],
            ),
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }
}
