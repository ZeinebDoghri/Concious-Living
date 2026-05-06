import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants.dart';

class RiskBadge extends StatelessWidget {
  final String riskLevel; // low | moderate | high

  const RiskBadge(this.riskLevel, {super.key});

  static String label(String level) {
    switch (level) {
      case 'high':
        return AppStrings.riskHigh;
      case 'moderate':
        return AppStrings.riskModerate;
      case 'low':
      default:
        return AppStrings.riskLow;
    }
  }

  static Color textColor(String level) {
    switch (level) {
      case 'high':
        return AppColors.butter;
      case 'moderate':
        return AppColors.espresso;
      case 'low':
      default:
        return AppColors.butter;
    }
  }

  static Color bgColor(String level) {
    switch (level) {
      case 'high':
        return AppColors.cherry;
      case 'moderate':
        return AppColors.butter;
      case 'low':
      default:
        return AppColors.olive;
    }
  }

  @override
  Widget build(BuildContext context) {
    final level = riskLevel.toLowerCase();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor(level),
        borderRadius: BorderRadius.circular(20),
        border: level == 'moderate'
            ? Border.all(color: AppColors.sand, width: 0.8)
            : null,
      ),
      child: Text(
        label(level),
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: textColor(level),
          height: 1.2,
        ),
      ),
    );
  }
}
