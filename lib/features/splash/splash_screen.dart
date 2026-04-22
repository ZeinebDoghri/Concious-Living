import 'dart:async';

import 'package:flutter/material.dart';
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
    with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final AnimationController _textController;

  late final Animation<double> _pulseScale;
  late final Animation<double> _titleFade;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _subtitleFade;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _pulseScale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();

    _titleFade = CurvedAnimation(
      parent: _textController,
      curve: Curves.easeOutCubic,
    );

    _titleSlide = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOutCubic),
    );

    _subtitleFade = CurvedAnimation(
      parent: _textController,
      curve: const Interval(0.5, 1.0, curve: Curves.easeOutCubic),
    );

    Timer(const Duration(milliseconds: 2800), _navigate);
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
        if (role == 'restaurant' || role == 'hotel') {
          ctx.go(AppRoutes.restaurantDashboard);
        } else {
          ctx.go(AppRoutes.customerHome);
        }
        return;
      } catch (_) {
        // fall through
      }
    }

    ctx.go(AppRoutes.roleSelector);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.oat,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FutureBuilder<bool>(
                future: Future<bool>.value(false),
                builder: (context, snapshot) {
                  return ScaleTransition(
                    scale: _pulseScale,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: const BoxDecoration(
                        color: AppColors.cherry,
                        shape: BoxShape.circle,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              FadeTransition(
                opacity: _titleFade,
                child: SlideTransition(
                  position: _titleSlide,
                  child: Text(
                    AppStrings.appNameUpper,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.dmSerifDisplay(
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      color: AppColors.cherry,
                      letterSpacing: 3,
                      height: 1.2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              FadeTransition(
                opacity: _subtitleFade,
                child: Text(
                  AppStrings.tagline,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: AppColors.cocoa,
                    height: 1.6,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
