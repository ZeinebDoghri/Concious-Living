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
  late final AnimationController _blobAnim;
  String? _pendingRoute;

  @override
  void initState() {
    super.initState();
    _blobAnim = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _blobAnim.dispose();
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
      backgroundColor: FreshGuardTheme.customerSurface,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Animated blob background ─────────────────────────────────────────
          AnimatedBuilder(
            animation: _blobAnim,
            builder: (context, _) => CustomPaint(
              painter: _BlobBackgroundPainter(_blobAnim.value),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // ── Header ─────────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 40, 28, 0),
                  child: Column(
                    children: [
                      // FreshGuard logo badge
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              FreshGuardTheme.customerPrimary,
                              FreshGuardTheme.customerDeep,
                            ],
                          ),
                          boxShadow: AppShadows.lg(FreshGuardTheme.customerPrimary),
                        ),
                        child: const Icon(
                          Icons.eco_rounded,
                          color: Colors.white,
                          size: 34,
                        ),
                      )
                          .animate()
                          .scale(
                            begin: const Offset(0.5, 0.5),
                            duration: AppDurations.xl,
                            curve: Curves.elasticOut,
                          )
                          .fadeIn(duration: AppDurations.lg),

                      const SizedBox(height: 16),

                      // App name
                      Text(
                        AppStrings.appNameUpper,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: FreshGuardTheme.customerTextMuted,
                          letterSpacing: 3,
                        ),
                      ).animate().fadeIn(delay: 200.ms, duration: 500.ms),

                      const SizedBox(height: 24),

                      // "Who are you?" title
                      Text(
                        AppStrings.whoAreYou,
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: FreshGuardTheme.customerTextTitle,
                          letterSpacing: -0.3,
                        ),
                      ).animate().fadeIn(delay: 300.ms, duration: 500.ms),

                      const SizedBox(height: 8),

                      // Subtitle
                      Text(
                        AppStrings.chooseRole,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: FreshGuardTheme.customerTextMuted,
                          height: 1.5,
                        ),
                      ).animate().fadeIn(delay: 380.ms, duration: 500.ms),
                    ],
                  ),
                ),

                const SizedBox(height: 36),

                // ── Role cards ─────────────────────────────────────────────────
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                    child: Column(
                      children: [
                        // Customer card
                        _RoleCard(
                          cardColor: FreshGuardTheme.customerSoftLavender,
                          primary: FreshGuardTheme.customerPrimary,
                          deep: FreshGuardTheme.customerDeep,
                          textTitle: FreshGuardTheme.customerTextTitle,
                          textBody: FreshGuardTheme.customerTextBody,
                          icon: Icons.person_rounded,
                          title: AppStrings.iAmCustomer,
                          subtitle: AppStrings.customerCardSubtitle,
                          delay: 450,
                          onTap: () => _select(
                            venueType: '',
                            route: AppRoutes.customerLogin,
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Restaurant card
                        _RoleCard(
                          cardColor: FreshGuardTheme.restaurantSoftPink,
                          primary: FreshGuardTheme.restaurantPrimary,
                          deep: FreshGuardTheme.restaurantDeep,
                          textTitle: FreshGuardTheme.restaurantTextTitle,
                          textBody: FreshGuardTheme.restaurantTextBody,
                          icon: Icons.restaurant_rounded,
                          title: AppStrings.iAmRestaurant,
                          subtitle: AppStrings.restaurantCardSubtitle,
                          delay: 550,
                          onTap: () => _select(
                            venueType: 'restaurant',
                            route: AppRoutes.restaurantLogin,
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Hotel card
                        _RoleCard(
                          cardColor: FreshGuardTheme.hotelSoftGreen,
                          primary: FreshGuardTheme.hotelPrimary,
                          deep: FreshGuardTheme.hotelDeep,
                          textTitle: FreshGuardTheme.hotelTextTitle,
                          textBody: FreshGuardTheme.hotelTextBody,
                          icon: Icons.hotel_rounded,
                          title: AppStrings.iAmHotel,
                          subtitle: AppStrings.hotelCardSubtitle,
                          delay: 650,
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
  final Color cardColor;
  final Color primary;
  final Color deep;
  final Color textTitle;
  final Color textBody;
  final IconData icon;
  final String title;
  final String subtitle;
  final int delay;
  final VoidCallback onTap;

  const _RoleCard({
    required this.cardColor,
    required this.primary,
    required this.deep,
    required this.textTitle,
    required this.textBody,
    required this.icon,
    required this.title,
    required this.subtitle,
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
            color: widget.cardColor,
            borderRadius: BorderRadius.circular(AppRadii.innerCard),
            boxShadow: AppShadows.md(widget.primary),
          ),
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              // ── Icon circle ─────────────────────────────────────────────────
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.primary,
                  boxShadow: AppShadows.sm(widget.primary),
                ),
                child: Icon(
                  widget.icon,
                  color: Colors.white,
                  size: 26,
                ),
              ),

              const SizedBox(width: 16),

              // ── Text content ────────────────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: widget.textTitle,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      widget.subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: widget.textBody,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // ── Arrow icon ──────────────────────────────────────────────────
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: widget.primary,
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

// ── Blob background painter ────────────────────────────────────────────────────
class _BlobBackgroundPainter extends CustomPainter {
  final double t;
  _BlobBackgroundPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final angle = t * 2 * math.pi;

    // Blob 1 — customer lavender, top-left
    final c1 = Offset(
      size.width * 0.15 + math.cos(angle) * 30,
      size.height * 0.2 + math.sin(angle) * 20,
    );
    canvas.drawCircle(
      c1,
      size.width * 0.55,
      Paint()
        ..shader = RadialGradient(
          colors: [
            FreshGuardTheme.customerPrimary.withValues(alpha: 0.10),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: c1, radius: size.width * 0.55)),
    );

    // Blob 2 — restaurant pink, bottom-right
    final c2 = Offset(
      size.width * 0.85 + math.sin(angle * 0.7) * 25,
      size.height * 0.72 + math.cos(angle * 0.7) * 30,
    );
    canvas.drawCircle(
      c2,
      size.width * 0.50,
      Paint()
        ..shader = RadialGradient(
          colors: [
            FreshGuardTheme.restaurantPrimary.withValues(alpha: 0.08),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: c2, radius: size.width * 0.50)),
    );

    // Blob 3 — hotel green, center
    final c3 = Offset(
      size.width * 0.5 + math.sin(angle * 1.3) * 20,
      size.height * 0.5 + math.cos(angle * 1.1) * 25,
    );
    canvas.drawCircle(
      c3,
      size.width * 0.35,
      Paint()
        ..shader = RadialGradient(
          colors: [
            FreshGuardTheme.hotelPrimary.withValues(alpha: 0.06),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: c3, radius: size.width * 0.35)),
    );
  }

  @override
  bool shouldRepaint(_BlobBackgroundPainter old) => old.t != t;
}
