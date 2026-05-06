import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants.dart';

class CustomerFlowFrame extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData badgeIcon;
  final String badgeLabel;
  final List<String> highlights;
  final Widget child;
  final VoidCallback? onBack;
  final String? backTooltip;
  final EdgeInsetsGeometry bodyPadding;

  const CustomerFlowFrame({
    super.key,
    required this.title,
    required this.subtitle,
    required this.badgeIcon,
    required this.badgeLabel,
    required this.highlights,
    required this.child,
    this.onBack,
    this.backTooltip,
    this.bodyPadding = const EdgeInsets.fromLTRB(24, 20, 24, 28),
  });

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: const Color(0xFFF0FDF4),
      body: Column(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF064E3B),
                  Color(0xFF065F46),
                  Color(0xFF047857),
                ],
              ),
            ),
            child: Column(
              children: [
                SizedBox(height: topPad + 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      if (onBack != null)
                        Tooltip(
                          message: backTooltip ?? 'Back',
                          child: IconButton(
                            onPressed: onBack,
                            icon: const Icon(Icons.arrow_back_ios_new_rounded),
                            color: Colors.white,
                            splashColor: Colors.white.withValues(alpha: 0.16),
                          ),
                        )
                      else
                        const SizedBox(width: 48),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Icon(
                                badgeIcon,
                                size: 11,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              badgeLabel,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.sora(
                          fontSize: 25,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        subtitle,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: Colors.white.withValues(alpha: 0.78),
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
                if (highlights.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: highlights
                          .map(
                            (label) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.14),
                                ),
                              ),
                              child: Text(
                                label,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          )
                          .toList(growable: false),
                    ),
                  ),
                ],
                const SizedBox(height: 18),
              ],
            ),
          ),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: AppColors.parchment,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: bodyPadding,
                child: child,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
