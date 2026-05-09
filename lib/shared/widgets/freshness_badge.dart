import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants.dart';

class FreshnessBadge extends StatelessWidget {
  final String status;

  const FreshnessBadge(this.status, {super.key});

  static String label(String status) {
    switch (status) {
      case 'spoiled': return AppStrings.freshnessSpoiled;
      case 'expiring': return AppStrings.freshnessExpiringSoon;
      case 'fresh': default: return AppStrings.freshnessFresh;
    }
  }

  static Color textColor(String status) {
    switch (status) {
      case 'spoiled': return const Color(0xFFCC3333);
      case 'expiring': return const Color(0xFFB87700);
      case 'fresh': default: return const Color(0xFF2D8A56);
    }
  }

  static Color bgColor(String status) {
    switch (status) {
      case 'spoiled': return FreshGuardTheme.danger.withValues(alpha: 0.12);
      case 'expiring': return FreshGuardTheme.warning.withValues(alpha: 0.15);
      case 'fresh': default: return FreshGuardTheme.fresh.withValues(alpha: 0.12);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = status.toLowerCase();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor(s),
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Text(
        label(s),
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textColor(s),
          height: 1.2,
        ),
      ),
    );
  }
}
