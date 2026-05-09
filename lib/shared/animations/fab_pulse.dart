import 'package:flutter/material.dart';

/// Wraps a FAB with animated pulse rings.
class FabWithPulse extends StatefulWidget {
  final Widget fab;
  final Color ringColor;

  const FabWithPulse({super.key, required this.fab, required this.ringColor});

  @override
  State<FabWithPulse> createState() => _FabWithPulseState();
}

class _FabWithPulseState extends State<FabWithPulse>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
  }

  Widget _ring(double delay) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final d = ((_ctrl.value - delay) % 1.0).clamp(0.0, 1.0);
        final scale = 1.0 + d * 0.7;
        final opacity = (1.0 - d).clamp(0.0, 1.0);
        return Transform.scale(
          scale: scale,
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: widget.ringColor.withOpacity(opacity * 0.5),
                width: 2,
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80,
      height: 80,
      child: Stack(
        alignment: Alignment.center,
        children: [
          _ring(0.0),
          _ring(0.4),
          widget.fab,
        ],
      ),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }
}
