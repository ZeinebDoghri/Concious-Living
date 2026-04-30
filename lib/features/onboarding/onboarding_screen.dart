import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants.dart';

// ── Page data ─────────────────────────────────────────────────────────────────
class _Page {
  final Color bg;
  final Color accentA;
  final Color accentB;
  final IconData icon;
  final String emoji;
  final String tag;
  final String title;
  final String body;

  const _Page({
    required this.bg,
    required this.accentA,
    required this.accentB,
    required this.icon,
    required this.emoji,
    required this.tag,
    required this.title,
    required this.body,
  });
}

const _pages = [
  _Page(
    bg: Color(0xFF0D1A0A),
    accentA: Color(0xFF5A7A18),
    accentB: Color(0xFF10B981),
    icon: Icons.eco_rounded,
    emoji: '🍃',
    tag: 'SCAN & ANALYSE',
    title: 'Votre assistant\nnutrition IA',
    body:
        'Photographiez n\'importe quel plat. Notre IA détecte instantanément le cholestérol, sodium, sucre et graisses saturées.',
  ),
  _Page(
    bg: Color(0xFF1A0A0D),
    accentA: Color(0xFF8B1A1F),
    accentB: Color(0xFFEF4444),
    icon: Icons.favorite_rounded,
    emoji: '❤️',
    tag: 'SANTÉ PERSONNALISÉE',
    title: 'Suivez votre\nsanté en temps réel',
    body:
        'Alertes allergens, objectifs quotidiens, rapports hebdomadaires. Votre profil santé vous protège à chaque repas.',
  ),
  _Page(
    bg: Color(0xFF0A0D1A),
    accentA: Color(0xFF3B5BB5),
    accentB: Color(0xFF10B981),
    icon: Icons.recycling_rounded,
    emoji: '♻️',
    tag: 'IA COMPOST',
    title: 'Zéro gaspillage\navec l\'IA Compost',
    body:
        'Mask2Former identifie en temps réel ce qui est compostable. Une révolution verte pour la restauration durable.',
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
  late final AnimationController _bgAnim;
  late final AnimationController _pulseAnim;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _bgAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _pulseAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _pageController.addListener(() {
      final i = (_pageController.page ?? 0).round().clamp(0, _pages.length - 1);
      if (i != _index) setState(() => _index = i);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _bgAnim.dispose();
    _pulseAnim.dispose();
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
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final page = _pages[_index];
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      backgroundColor: page.bg,
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        color: page.bg,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── Animated background mesh ─────────────────────────────────────
            AnimatedBuilder(
              animation: _pulseAnim,
              builder: (context, _) => CustomPaint(
                painter: _BgPainter(
                  accentA: page.accentA,
                  accentB: page.accentB,
                  t: _pulseAnim.value,
                ),
              ),
            ),

            // ── Page content ─────────────────────────────────────────────────
            PageView.builder(
              controller: _pageController,
              physics: const BouncingScrollPhysics(),
              itemCount: _pages.length,
              itemBuilder: (context, i) => _PageContent(
                page: _pages[i],
                isCurrent: i == _index,
                pulseAnim: _pulseAnim,
              ),
            ),

            // ── Skip button ──────────────────────────────────────────────────
            SafeArea(
              child: Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: AnimatedOpacity(
                    opacity: _index < _pages.length - 1 ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    child: GestureDetector(
                      onTap: _complete,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.12),
                          ),
                        ),
                        child: Text(
                          'Ignorer',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withValues(alpha: 0.6),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ── Bottom controls ──────────────────────────────────────────────
            Positioned(
              left: 24,
              right: 24,
              bottom: math.max(MediaQuery.paddingOf(context).bottom + 16, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_pages.length, (i) {
                      final active = i == _index;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 280),
                        curve: Curves.easeOutCubic,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 4,
                        width: active ? 28 : 4,
                        decoration: BoxDecoration(
                          color: active
                              ? _pages[_index].accentB
                              : Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 24),

                  // Next / Get Started button
                  _NextButton(
                    isLast: _index == _pages.length - 1,
                    accent: _pages[_index].accentB,
                    onTap: _next,
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

// ── Page content widget ────────────────────────────────────────────────────────
class _PageContent extends StatelessWidget {
  final _Page page;
  final bool isCurrent;
  final AnimationController pulseAnim;

  const _PageContent({
    required this.page,
    required this.isCurrent,
    required this.pulseAnim,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 80, 28, 160),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Hero illustration
            AnimatedBuilder(
              animation: pulseAnim,
              builder: (context, _) {
                final scale = 1.0 + pulseAnim.value * 0.04;
                return Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          page.accentA.withValues(alpha: 0.35),
                          page.accentB.withValues(alpha: 0.10),
                          Colors.transparent,
                        ],
                        radius: 0.8,
                      ),
                    ),
                    child: Center(
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [page.accentA, page.accentB],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: page.accentB.withValues(alpha: 0.4),
                              blurRadius: 32,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            page.emoji,
                            style: const TextStyle(fontSize: 52),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            )
                .animate(target: isCurrent ? 1 : 0)
                .scale(
                  begin: const Offset(0.7, 0.7),
                  end: const Offset(1.0, 1.0),
                  duration: 600.ms,
                  curve: Curves.elasticOut,
                ),

            const SizedBox(height: 40),

            // Tag
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: page.accentB.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: page.accentB.withValues(alpha: 0.3),
                  width: 0.8,
                ),
              ),
              child: Text(
                page.tag,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: page.accentB,
                  letterSpacing: 1.5,
                ),
              ),
            ).animate().fadeIn(delay: 200.ms, duration: 400.ms),

            const SizedBox(height: 16),

            // Title
            Text(
              page.title,
              textAlign: TextAlign.center,
              style: GoogleFonts.sora(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                height: 1.2,
                letterSpacing: -0.5,
              ),
            ).animate().fadeIn(delay: 300.ms, duration: 500.ms).slideY(
                  begin: 0.2,
                  end: 0,
                  delay: 300.ms,
                  duration: 500.ms,
                  curve: Curves.easeOutCubic,
                ),

            const SizedBox(height: 16),

            // Body
            Text(
              page.body,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Colors.white.withValues(alpha: 0.6),
                height: 1.7,
              ),
            ).animate().fadeIn(delay: 450.ms, duration: 500.ms),
          ],
        ),
      ),
    );
  }
}

// ── Next button ────────────────────────────────────────────────────────────────
class _NextButton extends StatefulWidget {
  final bool isLast;
  final Color accent;
  final VoidCallback onTap;

  const _NextButton({
    required this.isLast,
    required this.accent,
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
            gradient: LinearGradient(
              colors: [widget.accent, widget.accent.withValues(alpha: 0.75)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: widget.accent.withValues(alpha: 0.4),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.isLast ? 'Commencer' : 'Suivant',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                widget.isLast ? Icons.check_rounded : Icons.arrow_forward_rounded,
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

// ── Background mesh painter ────────────────────────────────────────────────────
class _BgPainter extends CustomPainter {
  final Color accentA;
  final Color accentB;
  final double t;

  const _BgPainter({
    required this.accentA,
    required this.accentB,
    required this.t,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Top-left blob
    canvas.drawCircle(
      Offset(size.width * 0.15, size.height * 0.15),
      size.width * 0.55,
      Paint()
        ..shader = RadialGradient(
          colors: [accentA.withValues(alpha: 0.25 + t * 0.08), Colors.transparent],
        ).createShader(Rect.fromCircle(
          center: Offset(size.width * 0.15, size.height * 0.15),
          radius: size.width * 0.55,
        )),
    );

    // Bottom-right blob
    canvas.drawCircle(
      Offset(size.width * 0.85, size.height * 0.75),
      size.width * 0.5,
      Paint()
        ..shader = RadialGradient(
          colors: [accentB.withValues(alpha: 0.18 + t * 0.05), Colors.transparent],
        ).createShader(Rect.fromCircle(
          center: Offset(size.width * 0.85, size.height * 0.75),
          radius: size.width * 0.5,
        )),
    );
  }

  @override
  bool shouldRepaint(_BgPainter old) =>
      old.t != t || old.accentA != accentA || old.accentB != accentB;
}
