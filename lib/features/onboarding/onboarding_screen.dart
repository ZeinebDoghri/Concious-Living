import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants.dart';
import '../../shared/animations/animated_gradient.dart';
import '../../shared/animations/organic_blobs.dart';
import '../../shared/animations/pressable.dart';
import '../../theme/brand_palette.dart';

// ── Page data — v4 colors ─────────────────────────────────────────────────────
class _Page {
  final List<Color> gradientColors;
  final Color accent;
  final Color deep;
  final Color surface;
  final IconData icon;
  final String emoji;
  final String tag;
  final String title;
  final String body;

  const _Page({
    required this.gradientColors,
    required this.accent,
    required this.deep,
    required this.surface,
    required this.icon,
    required this.emoji,
    required this.tag,
    required this.title,
    required this.body,
  });
}

const _pages = [
  _Page(
    gradientColors: [kCust2, kCust1, Color(0xFFD8B8F8)],
    accent: kCust1,
    deep: kCust2,
    surface: kCust3,
    icon: Icons.qr_code_scanner_rounded,
    emoji: '🔍',
    tag: 'SCAN ANYTHING',
    title: 'Scan Anything',
    body:
        'Point your camera at any food label.\nOur AI instantly reads ingredients,\nnutrients, and allergens.',
  ),
  _Page(
    gradientColors: [kRest2, kRest1, Color(0xFFF8C0A0)],
    accent: kRest1,
    deep: kRest2,
    surface: kRest3,
    icon: Icons.health_and_safety_rounded,
    emoji: '🛡️',
    tag: 'KNOW YOUR ALLERGIES',
    title: 'Know Your Allergies',
    body:
        'Get instant alerts before you eat.\nYour allergen profile protects you\nat every single meal.',
  ),
  _Page(
    gradientColors: [kHotel2, kHotel1, Color(0xFF9CD6B6)],
    accent: kHotel1,
    deep: kHotel2,
    surface: kHotel3,
    icon: Icons.insights_rounded,
    emoji: '📊',
    tag: 'TRACK NUTRITION',
    title: 'Track Nutrition',
    body:
        'See your full daily nutritional picture.\nCalories, macros, freshness — all in\none beautiful dashboard.',
  ),
];

// ── Screen ─────────────────────────────────────────────────────────────────────
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  late final PageController _pageController;
  late final AnimationController _blobAnim;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _blobAnim = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _pageController.addListener(() {
      final i = (_pageController.page ?? 0).round().clamp(0, _pages.length - 1);
      if (i != _index) setState(() => _index = i);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _blobAnim.dispose();
    super.dispose();
  }

  Future<void> _complete() async {
    HapticFeedback.mediumImpact();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(PrefKeys.seenOnboarding, true);
    if (!mounted) return;
    context.go(AppRoutes.roleSelector);
  }

  Future<void> _next() async {
    if (_index == _pages.length - 1) {
      await _complete();
      return;
    }
    HapticFeedback.selectionClick();
    await _pageController.animateToPage(
      _index + 1,
      duration: AppDurations.hero,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final page = _pages[_index];

    return Scaffold(
      backgroundColor: page.surface,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Animated gradient hero (top 260px) ──────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AnimatedGradientHero(
              colors: page.gradientColors,
              height: 260,
              child: Stack(
                children: [
                  AnimatedBlobs(color: Colors.white, count: 3),
                  Center(
                    child: ClipOval(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.25),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withOpacity(0.4),
                              width: 1.5,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              _pages[_index].emoji,
                              style: const TextStyle(fontSize: 44),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Page content scrollable ──────────────────────────────────────────
          PageView.builder(
            controller: _pageController,
            physics: const BouncingScrollPhysics(),
            itemCount: _pages.length,
            itemBuilder: (context, i) => _PageContent(
              page: _pages[i],
              isCurrent: i == _index,
              blobAnim: _blobAnim,
            ),
          ),

          // ── Skip button ────────────────────────────────────────────────────
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                child: AnimatedOpacity(
                  opacity: _index < _pages.length - 1 ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: Pressable(
                    onTap: _complete,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: page.accent.withOpacity(0.20),
                        ),
                      ),
                      child: Text(
                        'Skip',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: page.deep,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Bottom controls ────────────────────────────────────────────────
          Positioned(
            left: 24,
            right: 24,
            bottom: math.max(MediaQuery.paddingOf(context).bottom + 16, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // v4 Animated dots
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_pages.length, (i) {
                    final active = i == _index;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      height: 6,
                      width: active ? 22 : 6,
                      decoration: BoxDecoration(
                        color: active ? page.deep : kBorder,
                        borderRadius: BorderRadius.circular(active ? 11 : 3),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 24),

                // Pressable gradient CTA button
                Pressable(
                  onTap: _next,
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [page.deep, page.accent],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: [
                        BoxShadow(
                          color: page.accent.withOpacity(0.35),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _index == _pages.length - 1
                              ? 'Get Started'
                              : 'Continue',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          _index == _pages.length - 1
                              ? Icons.check_rounded
                              : Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Page content widget ────────────────────────────────────────────────────────
class _PageContent extends StatelessWidget {
  final _Page page;
  final bool isCurrent;
  final AnimationController blobAnim;

  const _PageContent({
    required this.page,
    required this.isCurrent,
    required this.blobAnim,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 276, 28, 160),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ── Tag chip ─────────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: page.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadii.pill),
                border: Border.all(
                  color: page.accent.withValues(alpha: 0.25),
                  width: 1,
                ),
              ),
              child: Text(
                page.tag,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: page.deep,
                  letterSpacing: 1.5,
                ),
              ),
            ).animate().fadeIn(delay: 200.ms, duration: 400.ms),

            const SizedBox(height: 18),

            // ── Title ────────────────────────────────────────────────────────
            Text(
                  page.title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.lora(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: kText2,
                    height: 1.2,
                  ),
                )
                .animate()
                .fadeIn(delay: 300.ms, duration: 500.ms)
                .slideY(
                  begin: 0.2,
                  end: 0,
                  delay: 300.ms,
                  duration: 500.ms,
                  curve: Curves.easeOutCubic,
                ),

            const SizedBox(height: 16),

            // ── Body ─────────────────────────────────────────────────────────
            Text(
              page.body,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: kText3,
                height: 1.6,
              ),
            ).animate().fadeIn(delay: 450.ms, duration: 500.ms),
          ],
        ),
      ),
    );
  }
}

// ── Next / Get Started button ──────────────────────────────────────────────────
class _NextButton extends StatefulWidget {
  final bool isLast;
  final Color deep;
  final VoidCallback onTap;

  const _NextButton({
    required this.isLast,
    required this.deep,
    required this.onTap,
  });

  @override
  State<_NextButton> createState() => _NextButtonState();
}

class _NextButtonState extends State<_NextButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            color: widget.deep,
            borderRadius: BorderRadius.circular(AppRadii.input),
            boxShadow: AppShadows.md(widget.deep),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.isLast ? AppStrings.getStarted : AppStrings.next,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                widget.isLast
                    ? Icons.check_rounded
                    : Icons.arrow_forward_rounded,
                color: Colors.white,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Blob painter ───────────────────────────────────────────────────────────────
class _BlobPainter extends CustomPainter {
  final double t;
  final Color primary;
  _BlobPainter(this.t, this.primary);

  @override
  void paint(Canvas canvas, Size size) {
    final angle = t * 2 * math.pi;
    // blob 1 top-left
    final c1 = Offset(
      size.width * 0.2 + math.cos(angle) * 30,
      size.height * 0.25 + math.sin(angle) * 20,
    );
    canvas.drawCircle(
      c1,
      size.width * 0.45,
      Paint()
        ..shader = RadialGradient(
          colors: [primary.withValues(alpha: 0.10), Colors.transparent],
        ).createShader(Rect.fromCircle(center: c1, radius: size.width * 0.45)),
    );
    // blob 2 bottom-right
    final c2 = Offset(
      size.width * 0.8 + math.sin(angle * 0.7) * 25,
      size.height * 0.7 + math.cos(angle * 0.7) * 30,
    );
    canvas.drawCircle(
      c2,
      size.width * 0.4,
      Paint()
        ..shader = RadialGradient(
          colors: [primary.withValues(alpha: 0.07), Colors.transparent],
        ).createShader(Rect.fromCircle(center: c2, radius: size.width * 0.4)),
    );
  }

  @override
  bool shouldRepaint(_BlobPainter old) => old.t != t || old.primary != primary;
}
