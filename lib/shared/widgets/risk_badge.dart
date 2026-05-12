import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants.dart';

class RiskBadge extends StatelessWidget {
  final String riskLevel;

  const RiskBadge(this.riskLevel, {super.key});

  static String label(String level) {
    switch (level) {
      case 'high': return AppStrings.riskHigh;
      case 'moderate': return AppStrings.riskModerate;
      case 'low': default: return AppStrings.riskLow;
    }
  }

  static Color textColor(String level) {
    switch (level) {
      case 'high': return const Color(0xFFCC3333);
      case 'moderate': return const Color(0xFFB87700);
      case 'low': default: return const Color(0xFF2D8A56);
    }
  }

  static Color bgColor(String level) {
    switch (level) {
      case 'high': return ORKATheme.danger.withValues(alpha: 0.12);
      case 'moderate': return ORKATheme.warning.withValues(alpha: 0.15);
      case 'low': default: return ORKATheme.fresh.withValues(alpha: 0.12);
    }
  }

  @override
  Widget build(BuildContext context) {
    final level = riskLevel.toLowerCase();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor(level),
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Text(
        label(level),
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textColor(level),
          height: 1.2,
        ),
      ),
    );
  }
}
