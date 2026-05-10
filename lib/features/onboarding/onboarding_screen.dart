import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants.dart';
import '../../shared/animations/pressable.dart';

// ── Palette ───────────────────────────────────────────────────────────────────
const _kLakeMist = Color(0xFFC8BAB4);
const _kTextTitle = Color(0xFF26201B);
const _kTextBody = Color(0xFF5C4F48);

const _kCustPrimary = Color(0xFFD9899F);
const _kCustDeep = Color(0xFFB27589);
const _kCustSurface = Color(0xFFF9E9F2); // card bg
const _kCustBg = Color(0xFFFEFAFC); // lightest tint — page background

const _kRestPrimary = Color(0xFF8FA84A);
const _kRestDeep = Color(0xFF5A6A2F);
const _kRestSurface = Color(0xFFE1E9D1); // card bg
const _kRestBg = Color(0xFFF8FAED); // lightest tint — page background

const _kHotelPrimary = Color(0xFF5A9FC9);
const _kHotelDeep = Color(0xFF35658F);
const _kHotelSurface = Color(0xFFD9E9F5); // card bg
const _kHotelBg = Color(0xFFF0F5F8); // lightest tint — page background

// ── Page data ─────────────────────────────────────────────────────────────────
class _Page {
  final Color bg;
  final Color accent;
  final Color deep;
  final Color cardBg;
  final String emoji;
  final String tag;
  final String title;
  final String body;
  final List<Color> blobs;

  const _Page({
    required this.bg,
    required this.accent,
    required this.deep,
    required this.cardBg,
    required this.emoji,
    required this.tag,
    required this.title,
    required this.body,
    required this.blobs,
  });
}

const _pages = [
  _Page(
    bg: _kCustBg,
    accent: _kCustPrimary,
    deep: _kCustDeep,
    cardBg: _kCustSurface,
    emoji: '🔍',
    tag: 'SCAN ANYTHING',
    title: 'Scan Anything',
    body:
        'Point your camera at any food label.\nOur AI instantly reads ingredients,\nnutrients, and allergens.',
    blobs: [_kCustPrimary, _kRestPrimary, _kHotelPrimary],
  ),
  _Page(
    bg: _kRestBg,
    accent: _kRestPrimary,
    deep: _kRestDeep,
    cardBg: _kRestSurface,
    emoji: '🛡️',
    tag: 'KNOW YOUR ALLERGIES',
    title: 'Know Your Allergies',
    body:
        'Get instant alerts before you eat.\nYour allergen profile protects you\nat every single meal.',
    blobs: [_kRestPrimary, _kHotelPrimary, _kCustPrimary],
  ),
  _Page(
    bg: _kHotelBg,
    accent: _kHotelPrimary,
    deep: _kHotelDeep,
    cardBg: _kHotelSurface,
    emoji: '📊',
    tag: 'TRACK NUTRITION',
    title: 'Track Nutrition',
    body:
        'See your full daily nutritional picture.\nCalories, macros, freshness — all in\none beautiful dashboard.',
    blobs: [_kHotelPrimary, _kCustPrimary, _kRestPrimary],
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
      duration: const Duration(seconds: 14),
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

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      color: page.bg,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // Blobs
            AnimatedBuilder(
              animation: _blobAnim,
              builder: (_, __) => CustomPaint(
                painter: _BlobPainter(_blobAnim.value, page.blobs),
              ),
            ),

            PageView.builder(
              controller: _pageController,
              physics: const BouncingScrollPhysics(),
              itemCount: _pages.length,
              itemBuilder: (context, i) =>
                  _PageContent(page: _pages[i], isCurrent: i == _index),
            ),

            // Skip button
            SafeArea(
              child: Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  child: AnimatedOpacity(
                    opacity: _index < _pages.length - 1 ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    child: Pressable(
                      onTap: _complete,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.88),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: _kLakeMist),
                          boxShadow: [
                            BoxShadow(
                              color: page.accent.withOpacity(0.10),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          'Skip',
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _kTextBody,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Bottom controls
            Positioned(
              left: 24,
              right: 24,
              bottom: math.max(MediaQuery.paddingOf(context).bottom + 20, 36),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_pages.length, (i) {
                      final active = i == _index;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        height: 6,
                        width: active ? 24 : 6,
                        decoration: BoxDecoration(
                          color: active ? page.deep : _kLakeMist,
                          borderRadius: BorderRadius.circular(active ? 12 : 3),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 22),

                  // CTA
                  Pressable(
                    onTap: _next,
                    child: Container(
                      height: 56,
                      decoration: BoxDecoration(
                        color: page.deep,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: page.deep.withOpacity(0.32),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
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
                            style: GoogleFonts.dmSans(
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
      ),
    );
  }
}

// ── Page content ───────────────────────────────────────────────────────────────
class _PageContent extends StatelessWidget {
  final _Page page;
  final bool isCurrent;

  const _PageContent({required this.page, required this.isCurrent});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: size.height * 0.09),

            // Hero card
            Container(
                  width: double.infinity,
                  height: size.height * 0.30,
                  decoration: BoxDecoration(
                    color: page.cardBg,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: page.accent.withOpacity(0.22),
                      width: 1.4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: page.accent.withOpacity(0.13),
                        blurRadius: 28,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Positioned(
                        top: 16,
                        left: 16,
                        child: _Dot(color: page.blobs[1], size: 10),
                      ),
                      Positioned(
                        top: 30,
                        left: 34,
                        child: _Dot(color: page.blobs[2], size: 6),
                      ),
                      Positioned(
                        bottom: 20,
                        right: 20,
                        child: _Dot(color: page.blobs[2], size: 12),
                      ),
                      Positioned(
                        bottom: 36,
                        right: 44,
                        child: _Dot(color: page.blobs[1], size: 7),
                      ),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                          child: Container(
                            width: 96,
                            height: 96,
                            decoration: BoxDecoration(
                              color: page.accent.withOpacity(0.18),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: page.accent.withOpacity(0.35),
                                width: 1.5,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              page.emoji,
                              style: const TextStyle(fontSize: 46),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
                .animate()
                .fadeIn(duration: 500.ms)
                .slideY(
                  begin: 0.08,
                  end: 0,
                  duration: 500.ms,
                  curve: Curves.easeOutCubic,
                ),

            SizedBox(height: size.height * 0.045),

            // Tag chip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: page.accent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: page.accent.withOpacity(0.30),
                  width: 1,
                ),
              ),
              child: Text(
                page.tag,
                style: GoogleFonts.dmSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: page.deep,
                  letterSpacing: 1.8,
                ),
              ),
            ).animate().fadeIn(delay: 150.ms, duration: 400.ms),

            const SizedBox(height: 16),

            // Title
            Text(
                  page.title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                    color: _kTextTitle,
                    height: 1.15,
                  ),
                )
                .animate()
                .fadeIn(delay: 220.ms, duration: 500.ms)
                .slideY(
                  begin: 0.15,
                  end: 0,
                  delay: 220.ms,
                  duration: 500.ms,
                  curve: Curves.easeOutCubic,
                ),

            const SizedBox(height: 14),

            // Body
            Text(
              page.body,
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                fontSize: 15,
                color: _kTextBody,
                height: 1.65,
              ),
            ).animate().fadeIn(delay: 340.ms, duration: 500.ms),

            const SizedBox(height: 20),

            // Three-dot mixed accent row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _Dot(color: page.blobs[0], size: 8),
                const SizedBox(width: 8),
                _Dot(color: page.blobs[1], size: 8),
                const SizedBox(width: 8),
                _Dot(color: page.blobs[2], size: 8),
              ],
            ).animate().fadeIn(delay: 420.ms, duration: 400.ms),
          ],
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  final Color color;
  final double size;
  const _Dot({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withOpacity(0.55),
        shape: BoxShape.circle,
      ),
    );
  }
}

// ── Blob painter ───────────────────────────────────────────────────────────────
class _BlobPainter extends CustomPainter {
  final double t;
  final List<Color> colors;
  _BlobPainter(this.t, this.colors);

  @override
  void paint(Canvas canvas, Size size) {
    final angle = t * 2 * math.pi;
    for (int i = 0; i < colors.length; i++) {
      final phase = angle + (i * 2 * math.pi / colors.length);
      final cx =
          size.width * (0.2 + 0.6 * i / (colors.length - 1)) +
          math.cos(phase) * 28;
      final cy = size.height * (0.15 + 0.35 * i) + math.sin(phase * 0.8) * 22;
      final center = Offset(cx, cy);
      final radius = size.width * 0.42;
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..shader = RadialGradient(
            colors: [colors[i].withOpacity(0.11), Colors.transparent],
          ).createShader(Rect.fromCircle(center: center, radius: radius)),
      );
    }
  }

  @override
  bool shouldRepaint(_BlobPainter old) => old.t != t;
}
