import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants.dart';
import 'risk_badge.dart';

class NutrientCard extends StatelessWidget {
  final String name;
  final double value;
  final String unit;
  final double dailyPct; // 0..100
  final String riskLevel; // low|moderate|high
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
      case 'high':
        return AppColors.cherry;
      case 'moderate':
        return AppColors.riskModerateText;
      case 'low':
      default:
        return AppColors.olive;
    }
  }

  static Color riskBg(String level) {
    switch (level.toLowerCase()) {
      case 'high':
        return AppColors.cherryBlush;
      case 'moderate':
        return AppColors.butter;
      case 'low':
      default:
        return AppColors.oliveMist;
    }
  }

  Animation<double> _barAnimation() {
    final totalMs = controller.duration?.inMilliseconds ?? 1400;
    final start = (delay.inMilliseconds / totalMs).clamp(0.0, 1.0);
    return CurvedAnimation(
      parent: controller,
      curve: Interval(start, 1.0, curve: Curves.easeOutCubic),
    );
  }

  Animation<double> _badgeAnimation() {
    final totalMs = controller.duration?.inMilliseconds ?? 1400;
    final start =
        ((delay.inMilliseconds + 520) / totalMs).clamp(0.0, 1.0);
    return CurvedAnimation(
      parent: controller,
      curve: Interval(start, 1.0, curve: Curves.easeOutCubic),
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
        color: AppColors.parchment,
        borderRadius: BorderRadius.circular(AppRadii.innerCard),
        border: Border.all(color: AppColors.sand, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                name,
                style: GoogleFonts.dmSerifDisplay(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.espresso,
                  height: 1.2,
                ),
              ),
              const Spacer(),
              Text(
                '${value.toStringAsFixed(value % 1 == 0 ? 0 : 1)} $unit',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.cherry,
                  height: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          AnimatedBuilder(
            animation: barAnim,
            builder: (context, _) {
              final v = (barAnim.value * target).clamp(0.0, target);
              return ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: v,
                  backgroundColor: AppColors.sand,
                  valueColor: AlwaysStoppedAnimation<Color>(barColor),
                  minHeight: 8,
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
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.cocoa,
                      height: 1.2,
                    ),
                  );
                },
              ),
              const Spacer(),
              Text(
                AppStrings.ofDailyLimit,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: AppColors.cocoa,
                  height: 1.2,
                ),
              ),
              const SizedBox(width: 8),
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
