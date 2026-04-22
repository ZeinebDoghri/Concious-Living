import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants.dart';

class FreshnessBadge extends StatelessWidget {
  final String status; // fresh | expiring | spoiled

  const FreshnessBadge(this.status, {super.key});

  static String label(String status) {
    switch (status) {
      case 'spoiled':
        return AppStrings.freshnessSpoiled;
      case 'expiring':
        return AppStrings.freshnessExpiringSoon;
      case 'fresh':
      default:
        return AppStrings.freshnessFresh;
    }
  }

  static Color textColor(String status) {
    switch (status) {
      case 'spoiled':
        return AppColors.cherry;
      case 'expiring':
        return AppColors.riskModerateText;
      case 'fresh':
      default:
        return AppColors.olive;
    }
  }

  static Color bgColor(String status) {
    switch (status) {
      case 'spoiled':
        return AppColors.cherryBlush;
      case 'expiring':
        return AppColors.butter;
      case 'fresh':
      default:
        return AppColors.oliveMist;
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = status.toLowerCase();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor(s),
        borderRadius: BorderRadius.circular(AppRadii.badge),
        border: Border.all(color: AppColors.sand, width: 0.5),
      ),
      child: Text(
        label(s),
            style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: textColor(s),
          height: 1.2,
        ),
      ),
    );
  }
}
