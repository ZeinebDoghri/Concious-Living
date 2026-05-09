import 'package:flutter/material.dart';

class StaggerList extends StatelessWidget {
  final AnimationController controller;
  final int index;
  final Widget child;

  const StaggerList({
    super.key,
    required this.controller,
    required this.index,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final start = (index.clamp(0, 8)) * 0.1;
    final end = (start + 0.6).clamp(0.0, 1.0);
    final animation = CurvedAnimation(
      parent: controller,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );

    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.04),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
    );
  }
}
