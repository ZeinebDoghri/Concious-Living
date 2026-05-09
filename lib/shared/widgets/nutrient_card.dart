import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants.dart';
import 'risk_badge.dart';

class NutrientCard extends StatelessWidget {
  final String name;
  final double value;
  final String unit;
  final double dailyPct;
  final String riskLevel;
  final AnimationController controller;
  final Duration delay;

  const NutrientCard({
    super.key,
    required this.name,
    required this.value,
    required this.unit,
    required this.dailyPct,
    required this.riskLevel,
    required this.controller,
    required this.delay,
  });

  static Color riskColor(String level) {
    switch (level.toLowerCase()) {
      case 'high': return FreshGuardTheme.danger;
      case 'moderate': return FreshGuardTheme.warning;
      case 'low': default: return FreshGuardTheme.fresh;
    }
  }

  static Color riskBg(String level) {
    return riskColor(level).withValues(alpha: 0.10);
  }

  Animation<double> _barAnimation() {
    final totalMs = controller.duration?.inMilliseconds ?? 1400;
    final start = (delay.inMilliseconds / totalMs).clamp(0.0, 1.0);
    return CurvedAnimation(
      parent: controller,
      curve: Interval(start, 1.0, curve: Curves.easeOutQuart),
    );
  }

  Animation<double> _badgeAnimation() {
    final totalMs = controller.duration?.inMilliseconds ?? 1400;
    final start = ((delay.inMilliseconds + 520) / totalMs).clamp(0.0, 1.0);
    return CurvedAnimation(
      parent: controller,
      curve: Interval(start, 1.0, curve: Curves.easeOutQuart),
    );
  }

  @override
  Widget build(BuildContext context) {
    final barAnim = _barAnimation();
    final badgeAnim = _badgeAnimation();
    final target = (dailyPct / 100).clamp(0.0, 1.0);
    final barColor = riskColor(riskLevel);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadii.innerCard),
        boxShadow: AppShadows.sm(barColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                name,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 14, fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface, height: 1.2,
                ),
              ),
              const Spacer(),
              AnimatedBuilder(
                animation: barAnim,
                builder: (context, _) {
                  final v = (barAnim.value * value).clamp(0.0, value);
                  return Text(
                    '${v.toStringAsFixed(v % 1 == 0 ? 0 : 1)} $unit',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 14, fontWeight: FontWeight.w700,
                      color: barColor, height: 1.2,
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          AnimatedBuilder(
            animation: barAnim,
            builder: (context, _) {
              final v = (barAnim.value * target).clamp(0.0, target);
              return ClipRRect(
                borderRadius: BorderRadius.circular(AppRadii.pill),
                child: LinearProgressIndicator(
                  value: v,
                  backgroundColor: barColor.withValues(alpha: 0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(barColor),
                  minHeight: 6,
                ),
              );
            },
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              AnimatedBuilder(
                animation: barAnim,
                builder: (context, _) {
                  final pct = (barAnim.value * dailyPct).clamp(0.0, dailyPct);
                  return Text(
                    '${pct.toInt()}%',
                    style: GoogleFonts.inter(
                      fontSize: 10, fontWeight: FontWeight.w600,
                      color: barColor, height: 1.2,
                    ),
                  );
                },
              ),
              Text(
                ' ${AppStrings.ofDailyLimit}',
                style: GoogleFonts.inter(
                  fontSize: 10, fontWeight: FontWeight.w400,
                  color: Theme.of(context).textTheme.labelMedium?.color, height: 1.2,
                ),
              ),
              const Spacer(),
              FadeTransition(
                opacity: badgeAnim,
                child: RiskBadge(riskLevel),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
