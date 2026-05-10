import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NutrientProgressBar extends StatelessWidget {
  final String label;
  final double value;
  final double limit;
  final String unit;

  const NutrientProgressBar({
    super.key,
    required this.label,
    required this.value,
    required this.limit,
    required this.unit,
  });

  Color get _color {
    final pct = limit <= 0 ? 0.0 : value / limit;
    if (pct >= 1) return const Color(0xFFFF6B8A);
    if (pct >= 0.75) return const Color(0xFFFFB347);
    return const Color(0xFF45C4B0);
  }

  @override
  Widget build(BuildContext context) {
    final pct = limit <= 0 ? 0.0 : value / limit;
    final safePct = pct.clamp(0.0, 1.0);
    final isLimit = pct >= 1;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _color.withValues(alpha: 0.22)),
        boxShadow: [
          if (isLimit)
            BoxShadow(
              color: _color.withValues(alpha: 0.30),
              blurRadius: 18,
              spreadRadius: 1,
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF7D3A4F),
                  ),
                ),
              ),
              if (isLimit)
                Text(
                  'Limit reached',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: _color,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: safePct),
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOutCubic,
              builder: (_, value, _) => LinearProgressIndicator(
                value: value,
                minHeight: 10,
                backgroundColor: _color.withValues(alpha: 0.14),
                valueColor: AlwaysStoppedAnimation<Color>(_color),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${value.toStringAsFixed(0)} / ${limit.toStringAsFixed(0)} $unit  (${(pct * 100).toStringAsFixed(0)}%)',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF7D3A4F).withValues(alpha: 0.74),
            ),
          ),
        ],
      ),
    );
  }
}
