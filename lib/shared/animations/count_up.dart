import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/brand_palette.dart';

/// Animates a number counting up from 0 to [target].
class CountUp extends StatelessWidget {
  final double target;
  final String suffix;
  final String prefix;
  final TextStyle? style;
  final Duration duration;

  const CountUp({
    super.key,
    required this.target,
    this.suffix = '',
    this.prefix = '',
    this.style,
    this.duration = const Duration(milliseconds: 800),
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: duration,
      tween: Tween(begin: 0, end: target),
      curve: Curves.easeOutCubic,
      builder: (_, val, _) => Text(
        '$prefix${val.toInt()}$suffix',
        style: style ??
            GoogleFonts.lora(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: kText2,
            ),
      ),
    );
  }
}
