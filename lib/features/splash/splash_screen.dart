import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants.dart';
import '../../core/firebase_service.dart';
import '../../shared/animations/organic_blobs.dart';
import '../../shared/animations/shimmer_box.dart';
import '../../theme/brand_palette.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _enterCtrl;
  late final AnimationController _floatCtrl;
  late final AnimationController _pulseCtrl;

  late final Animation<double> _logoAnim;
  late final Animation<double> _nameAnim;
  late final Animation<double> _taglineAnim;
  late final Animation<double> _shimmerAnim;
  late final Animation<double> _floatAnim;

  @override
  void initState() {
    super.initState();

    // Stagger entrance controller
    _enterCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..forward();

    _logoAnim = CurvedAnimation(
      parent: _enterCtrl,
      curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
    );
    _nameAnim = CurvedAnimation(
      parent: _enterCtrl,
      curve: const Interval(0.2, 0.7, curve: Curves.easeOutCubic),
    );
    _taglineAnim = CurvedAnimation(
      parent: _enterCtrl,
      curve: const Interval(0.4, 0.8, curve: Curves.easeOutCubic),
    );
    _shimmerAnim = CurvedAnimation(
      parent: _enterCtrl,
      curve: const Interval(0.7, 1.0, curve: Curves.easeOutCubic),
    );

    // Float animation for logo
    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    )..repeat(reverse: true);
    _floatAnim = Tween<double>(begin: -10.0, end: 10.0).animate(
      CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut),
    );

    // Pulse rings
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
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
    _enterCtrl.dispose();
    _floatCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  Widget _pulseRing(double delay, double opacity) {
    return AnimatedBuilder(
      animation: _pulseCtrl,
      builder: (_, __) {
        final d = ((_pulseCtrl.value - delay) % 1.0).clamp(0.0, 1.0);
        final scale = 1.0 + d * 1.2;
        final o = ((1.0 - d) * opacity).clamp(0.0, 1.0);
        return Transform.scale(
          scale: scale,
          child: Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: kCust1.withOpacity(o),
                width: 2,
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Warm gradient background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [kBg, Color(0xFFEFF5F2), Color(0xFFF5F0EE)],
              ),
            ),
          ),

          // Animated organic blobs
          AnimatedBlobs(color: kCust1, count: 4),

          // Centre content
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo with float + pulse rings
                AnimatedBuilder(
                  animation: _floatAnim,
                  builder: (_, child) => Transform.translate(
                    offset: Offset(0, _floatAnim.value),
                    child: child,
                  ),
                  child: ScaleTransition(
                    scale: _logoAnim,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        _pulseRing(0.0, 0.20),
                        _pulseRing(0.33, 0.13),
                        _pulseRing(0.66, 0.07),
                        Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [kCust2, kCust1],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: kCust1.withOpacity(0.35),
                                blurRadius: 24,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.eco_rounded,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // App name
                FadeTransition(
                  opacity: _nameAnim,
                  child: Text(
                    'Conscious Living',
                    style: GoogleFonts.lora(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: kText2,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // Tagline
                FadeTransition(
                  opacity: _taglineAnim,
                  child: Text(
                    'Your intelligent food companion',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: kText3,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),

                const SizedBox(height: 48),

                // Shimmer loading bar
                FadeTransition(
                  opacity: _shimmerAnim,
                  child: const ShimmerBox(width: 100, height: 2, radius: 999),
                ),
              ],
            ),
          ),

          // Bottom brand mark
          Positioned(
            bottom: 36,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: _shimmerAnim,
              child: Text(
                'Conscious Living · 2026',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  color: kText3,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
