import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants.dart';
import '../../core/firebase_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _orbitController;

  @override
  void initState() {
    super.initState();
    _orbitController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();

    Timer(const Duration(milliseconds: 3000), _navigate);
  }

  Future<void> _navigate() async {
    final ctx = context;
    if (!ctx.mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool(PrefKeys.seenOnboarding) ?? false;

    if (!ctx.mounted) return;

    if (!seen) {
      ctx.go(AppRoutes.onboarding);
      return;
    }

    final authUser = FirebaseService.currentUser;
    if (authUser != null) {
      try {
        final profile = await FirebaseService.getUser(authUser.uid);
        if (!ctx.mounted) return;
        final role = profile?.role;
        if (role == 'hotel') {
          ctx.go(AppRoutes.hotelDashboard);
        } else if (role == 'restaurant') {
          ctx.go(AppRoutes.restaurantDashboard);
        } else {
          ctx.go(AppRoutes.customerHome);
        }
        return;
      } catch (_) {}
    }

    ctx.go(AppRoutes.roleSelector);
  }

  @override
  void dispose() {
    _orbitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0A14),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Background radial glow ─────────────────────────────────────────
          Positioned.fill(
            child: CustomPaint(painter: _GlowPainter(_orbitController)),
          ),

          // ── Orbiting dots ──────────────────────────────────────────────────
          AnimatedBuilder(
            animation: _orbitController,
            builder: (context, _) {
              return CustomPaint(
                painter: _OrbitPainter(_orbitController.value),
                child: const SizedBox.expand(),
              );
            },
          ),

          // ── Centre content ─────────────────────────────────────────────────
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo badge
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const RadialGradient(
                      colors: [Color(0xFFB03A3F), Color(0xFF6B1215)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.cherry.withValues(alpha: 0.55),
                        blurRadius: 40,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.eco_rounded,
                    color: Colors.white,
                    size: 48,
                  ),
                )
                    .animate()
                    .scale(
                      begin: const Offset(0.4, 0.4),
                      end: const Offset(1.0, 1.0),
                      duration: 700.ms,
                      curve: Curves.elasticOut,
                    )
                    .fadeIn(duration: 400.ms),

                const SizedBox(height: 28),

                // App name
                Text(
                  AppStrings.appNameUpper,
                  style: GoogleFonts.sora(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 4,
                  ),
                )
                    .animate()
                    .fadeIn(delay: 500.ms, duration: 600.ms)
                    .slideY(
                      begin: 0.3,
                      end: 0,
                      delay: 500.ms,
                      duration: 600.ms,
                      curve: Curves.easeOutCubic,
                    ),

                const SizedBox(height: 8),

                // Tagline
                Text(
                  AppStrings.tagline,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withValues(alpha: 0.5),
                    letterSpacing: 1.2,
                  ),
                )
                    .animate()
                    .fadeIn(delay: 800.ms, duration: 600.ms),

                const SizedBox(height: 48),

                // Loading indicator
                SizedBox(
                  width: 120,
                  child: LinearProgressIndicator(
                    backgroundColor: Colors.white.withValues(alpha: 0.08),
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppColors.cherry),
                    minHeight: 2,
                    borderRadius: BorderRadius.circular(2),
                  ),
                )
                    .animate()
                    .fadeIn(delay: 1000.ms, duration: 400.ms),
              ],
            ),
          ),

          // ── Bottom brand mark ──────────────────────────────────────────────
          Positioned(
            bottom: 36,
            left: 0,
            right: 0,
            child: Text(
              'The Fungineers · 2026',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w400,
                color: Colors.white.withValues(alpha: 0.2),
                letterSpacing: 1.5,
              ),
            ).animate().fadeIn(delay: 1200.ms, duration: 600.ms),
          ),
        ],
      ),
    );
  }
}

// ── Background glow painter ────────────────────────────────────────────────────
class _GlowPainter extends CustomPainter {
  final Animation<double> animation;
  _GlowPainter(this.animation) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final t = animation.value;
    final cx = size.width * 0.5;
    final cy = size.height * 0.42;

    // Cherry glow
    canvas.drawCircle(
      Offset(cx, cy),
      size.width * 0.6,
      Paint()
        ..shader = RadialGradient(
          colors: [
            AppColors.cherry.withValues(alpha: 0.18 + 0.05 * math.sin(t * 2 * math.pi)),
            Colors.transparent,
          ],
        ).createShader(
          Rect.fromCircle(center: Offset(cx, cy), radius: size.width * 0.6),
        ),
    );

    // Olive accent glow (offset)
    final ox = cx + math.sin(t * 2 * math.pi) * 60;
    final oy = cy + math.cos(t * 2 * math.pi) * 40;
    canvas.drawCircle(
      Offset(ox, oy),
      size.width * 0.35,
      Paint()
        ..shader = RadialGradient(
          colors: [
            AppColors.olive.withValues(alpha: 0.10),
            Colors.transparent,
          ],
        ).createShader(
          Rect.fromCircle(center: Offset(ox, oy), radius: size.width * 0.35),
        ),
    );
  }

  @override
  bool shouldRepaint(_GlowPainter old) => true;
}

// ── Orbiting dots painter ──────────────────────────────────────────────────────
class _OrbitPainter extends CustomPainter {
  final double t;
  _OrbitPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width * 0.5;
    final cy = size.height * 0.42;
    const dots = 6;
    const radius = 120.0;

    for (int i = 0; i < dots; i++) {
      final angle = (i / dots) * 2 * math.pi + t * 2 * math.pi;
      final x = cx + math.cos(angle) * radius;
      final y = cy + math.sin(angle) * (radius * 0.4);
      final alpha = (0.15 + 0.1 * math.sin(angle)).clamp(0.05, 0.25);
      final dotR = 2.5 + math.sin(angle + t * math.pi) * 1.0;

      canvas.drawCircle(
        Offset(x, y),
        dotR,
        Paint()..color = Colors.white.withValues(alpha: alpha),
      );
    }
  }

  @override
  bool shouldRepaint(_OrbitPainter old) => old.t != t;
}
