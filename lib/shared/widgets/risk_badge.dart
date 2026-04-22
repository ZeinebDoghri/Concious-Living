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
        return AppColors.cherry;
      case 'moderate':
        return AppColors.riskModerateText;
      case 'low':
      default:
        return AppColors.olive;
    }
  }

  static Color bgColor(String level) {
    switch (level) {
      case 'high':
        return AppColors.cherryBlush;
      case 'moderate':
        return AppColors.butter;
      case 'low':
      default:
        return AppColors.oliveMist;
    }
  }

  @override
  Widget build(BuildContext context) {
    final level = riskLevel.toLowerCase();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor(level),
        borderRadius: BorderRadius.circular(AppRadii.badge),
        border: Border.all(color: AppColors.sand, width: 0.5),
      ),
      child: Text(
        label(level),
          style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: textColor(level),
          height: 1.2,
        ),
      ),
    );
  }
}
