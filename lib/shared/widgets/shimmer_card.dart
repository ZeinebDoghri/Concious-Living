import 'package:flutter/material.dart';

import '../../core/constants.dart';

class ShimmerCard extends StatefulWidget {
  final double height;
  final double radius;

  const ShimmerCard({
    super.key,
    this.height = 84,
    this.radius = AppRadii.innerCard,
  });

  @override
  State<ShimmerCard> createState() => _ShimmerCardState();
}

class _ShimmerCardState extends State<ShimmerCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        final dx = (t * 2) - 1;

        final gradient = LinearGradient(
          begin: Alignment(-1 + dx, 0),
          end: Alignment(1 + dx, 0),
          colors: [
            primary.withValues(alpha: 0.04),
            primary.withValues(alpha: 0.10),
            primary.withValues(alpha: 0.04),
          ],
          stops: const [0.2, 0.5, 0.8],
        );

        return ClipRRect(
          borderRadius: BorderRadius.circular(widget.radius),
          child: ShaderMask(
            shaderCallback: (rect) => gradient.createShader(rect),
            blendMode: BlendMode.srcATop,
            child: Container(
              height: widget.height,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(widget.radius),
              ),
            ),
          ),
        );
      },
    );
  }
}
