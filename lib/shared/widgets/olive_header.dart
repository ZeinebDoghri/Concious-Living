import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants.dart';

class OliveHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool showBack;
  final List<Widget>? actions;
  final double height;

  const OliveHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.showBack = true,
    this.actions,
    this.height = 180,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: height,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF5A7A18), Color(0xFF445C12)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _HeaderArcPainter(),
                ),
              ),
              Align(
                alignment: Alignment.topLeft,
                child: Row(
                  children: [
                    if (showBack)
                      IconButton(
                        onPressed: () => context.pop(),
                        icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                        color: AppColors.butter,
                        splashColor: AppColors.butter.withValues(alpha: 0.2),
                      )
                    else
                      const SizedBox(width: 48),
                    const Spacer(),
                    if (actions != null) ...actions!,
                  ],
                ),
              ),
              Align(
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.dmSerifDisplay(
                        fontSize: 20,
                        fontWeight: FontWeight.w400,
                        color: AppColors.butter,
                        letterSpacing: 0.3,
                        height: 1.2,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        subtitle!,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: AppColors.oliveMist,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderArcPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(size.width + 36, size.height + 12),
      120,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
