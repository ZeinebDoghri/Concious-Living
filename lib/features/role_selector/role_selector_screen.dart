import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../providers/venue_type_provider.dart';

class RoleSelectorScreen extends StatefulWidget {
  const RoleSelectorScreen({super.key});

  @override
  State<RoleSelectorScreen> createState() => _RoleSelectorScreenState();
}

class _RoleSelectorScreenState extends State<RoleSelectorScreen>
    with TickerProviderStateMixin {
  late final AnimationController _bgAnim;
  String? _pendingRoute;

  @override
  void initState() {
    super.initState();
    _bgAnim = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _bgAnim.dispose();
    super.dispose();
  }

  Future<void> _select({
    required String venueType,
    required String route,
  }) async {
    if (_pendingRoute != null) return;
    HapticFeedback.mediumImpact();
    _pendingRoute = route;

    final venueProvider = context.read<VenueTypeProvider>();
    if (venueType.isEmpty) {
      await venueProvider.clear();
    } else {
      await venueProvider.setVenueType(venueType);
    }
    if (!mounted) return;
    context.go(route);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0A14),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Animated mesh background ─────────────────────────────────────────
          AnimatedBuilder(
            animation: _bgAnim,
            builder: (context, _) => CustomPaint(
              painter: _MeshPainter(_bgAnim.value),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // ── Header ─────────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 32, 28, 0),
                  child: Column(
                    children: [
                      // Logo
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const RadialGradient(
                            colors: [Color(0xFFB03A3F), Color(0xFF6B1215)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.cherry.withValues(alpha: 0.5),
                              blurRadius: 24,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.eco_rounded,
                          color: Colors.white,
                          size: 32,
                        ),
                      )
                          .animate()
                          .scale(
                            begin: const Offset(0.5, 0.5),
                            duration: 600.ms,
                            curve: Curves.elasticOut,
                          )
                          .fadeIn(duration: 400.ms),

                      const SizedBox(height: 20),

                      Text(
                        AppStrings.appNameUpper,
                        style: GoogleFonts.sora(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 3,
                        ),
                      ).animate().fadeIn(delay: 200.ms, duration: 500.ms),

                      const SizedBox(height: 8),

                      Text(
                        AppStrings.taglineLong,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.4),
                          letterSpacing: 0.5,
                        ),
                      ).animate().fadeIn(delay: 350.ms, duration: 500.ms),

                      const SizedBox(height: 36),

                      // Section title
                      Text(
                        'Choisissez votre rôle',
                        style: GoogleFonts.sora(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -0.3,
                        ),
                      ).animate().fadeIn(delay: 450.ms, duration: 500.ms),

                      const SizedBox(height: 6),

                      Text(
                        'Pour personnaliser votre expérience',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.45),
                        ),
                      ).animate().fadeIn(delay: 500.ms, duration: 500.ms),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // ── Role cards ─────────────────────────────────────────────────
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    child: Column(
                      children: [
                        _RoleCard(
                          gradientA: const Color(0xFF1A3A5C),
                          gradientB: const Color(0xFF0D1F35),
                          glowColor: const Color(0xFF3B82F6),
                          icon: Icons.person_outline_rounded,
                          emoji: '🥗',
                          tag: 'CONSOMMATEUR',
                          title: AppStrings.iAmCustomer,
                          subtitle: AppStrings.customerCardSubtitle,
                          features: const [
                            'Scan de plats par IA',
                            'Alertes allergènes',
                            'Suivi nutritionnel',
                          ],
                          delay: 600,
                          onTap: () => _select(
                            venueType: '',
                            route: AppRoutes.customerLogin,
                          ),
                        ),

                        const SizedBox(height: 14),

                        _RoleCard(
                          gradientA: const Color(0xFF1A2E0A),
                          gradientB: const Color(0xFF0D1A05),
                          glowColor: AppColors.olive,
                          icon: Icons.restaurant_rounded,
                          emoji: '👨‍🍳',
                          tag: 'RESTAURATEUR',
                          title: AppStrings.iAmRestaurant,
                          subtitle: AppStrings.restaurantCardSubtitle,
                          features: const [
                            'IA Compost Mask2Former',
                            'Monitoring déchets',
                            'Alertes cuisine',
                          ],
                          delay: 700,
                          onTap: () => _select(
                            venueType: 'restaurant',
                            route: AppRoutes.restaurantLogin,
                          ),
                        ),

                        const SizedBox(height: 14),

                        _RoleCard(
                          gradientA: const Color(0xFF2A1A00),
                          gradientB: const Color(0xFF1A1000),
                          glowColor: const Color(0xFFD97706),
                          icon: Icons.hotel_rounded,
                          emoji: '🏨',
                          tag: 'HÔTELIER',
                          title: AppStrings.iAmHotel,
                          subtitle: AppStrings.hotelCardSubtitle,
                          features: const [
                            'Room service tracking',
                            'Santé des hôtes',
                            'Alertes cuisine',
                          ],
                          delay: 800,
                          onTap: () => _select(
                            venueType: 'hotel',
                            route: AppRoutes.hotelLogin,
                          ),
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

// ── Role Card ──────────────────────────────────────────────────────────────────
class _RoleCard extends StatefulWidget {
  final Color gradientA;
  final Color gradientB;
  final Color glowColor;
  final IconData icon;
  final String emoji;
  final String tag;
  final String title;
  final String subtitle;
  final List<String> features;
  final int delay;
  final VoidCallback onTap;

  const _RoleCard({
    required this.gradientA,
    required this.gradientB,
    required this.glowColor,
    required this.icon,
    required this.emoji,
    required this.tag,
    required this.title,
    required this.subtitle,
    required this.features,
    required this.delay,
    required this.onTap,
  });

  @override
  State<_RoleCard> createState() => _RoleCardState();
}

class _RoleCardState extends State<_RoleCard> {
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
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 130),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [widget.gradientA, widget.gradientB],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: widget.glowColor.withValues(alpha: 0.25),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.glowColor.withValues(alpha: _pressed ? 0.15 : 0.08),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              // Icon area
              Column(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.glowColor.withValues(alpha: 0.12),
                      border: Border.all(
                        color: widget.glowColor.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        widget.emoji,
                        style: const TextStyle(fontSize: 28),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: widget.glowColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      widget.tag,
                      style: GoogleFonts.inter(
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                        color: widget.glowColor,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(width: 16),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: GoogleFonts.sora(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ...widget.features.map(
                      (f) => Padding(
                        padding: const EdgeInsets.only(bottom: 3),
                        child: Row(
                          children: [
                            Container(
                              width: 5,
                              height: 5,
                              decoration: BoxDecoration(
                                color: widget.glowColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              f,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                color: Colors.white.withValues(alpha: 0.55),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Arrow
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: widget.glowColor.withValues(alpha: 0.6),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: widget.delay), duration: 500.ms)
        .slideY(
          begin: 0.15,
          end: 0,
          delay: Duration(milliseconds: widget.delay),
          duration: 500.ms,
          curve: Curves.easeOutCubic,
        );
  }
}

// ── Background mesh painter ────────────────────────────────────────────────────
class _MeshPainter extends CustomPainter {
  final double t;
  _MeshPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    void glow(Offset c, double r, Color col, double alpha) {
      canvas.drawCircle(
        c,
        r,
        Paint()
          ..shader = RadialGradient(
            colors: [col.withValues(alpha: alpha), Colors.transparent],
          ).createShader(Rect.fromCircle(center: c, radius: r)),
      );
    }

    final a = t * 2 * math.pi;
    glow(
      Offset(size.width * (0.15 + 0.05 * math.sin(a)), size.height * 0.2),
      size.width * 0.6,
      AppColors.cherry,
      0.12,
    );
    glow(
      Offset(size.width * (0.85 + 0.05 * math.cos(a)), size.height * 0.65),
      size.width * 0.55,
      AppColors.olive,
      0.10,
    );
    glow(
      Offset(size.width * 0.5, size.height * (0.5 + 0.05 * math.sin(a * 1.3))),
      size.width * 0.4,
      const Color(0xFF3B82F6),
      0.06,
    );
  }

  @override
  bool shouldRepaint(_MeshPainter old) => old.t != t;
}
