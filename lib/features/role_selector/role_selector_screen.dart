import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../providers/venue_type_provider.dart';

// ── Palette ───────────────────────────────────────────────────────────────────
const _kBg         = Color(0xFFFCFEF1); // yellow-green tinted white
const _kLakeMist   = Color(0xFFC8BAB4);
const _kTextTitle  = Color(0xFF26201B);
const _kTextBody   = Color(0xFF5C4F48);
const _kTextMuted  = Color(0xFF8C7E78);

const _kCustPrimary  = Color(0xFFD9899F);
const _kCustDeep     = Color(0xFFB27589);
const _kCustSurface  = Color(0xFFF9E9F2);
const _kCustBorder   = Color(0xFFEFCCE0);

const _kRestPrimary  = Color(0xFF8FA84A);
const _kRestDeep     = Color(0xFF5A7030);
const _kRestSurface  = Color(0xFFE3E8D1);
const _kRestBorder   = Color(0xFFC0D089);

const _kHotelPrimary = Color(0xFF5A9FC9);
const _kHotelDeep    = Color(0xFF35658F);
const _kHotelSurface = Color(0xFFD9E9F5);
const _kHotelBorder  = Color(0xFFA8C8E1);

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
      backgroundColor: _kBg,
      body: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedBuilder(
            animation: _blobAnim,
            builder: (_, _) => CustomPaint(
              painter: _BlobBgPainter(_blobAnim.value),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 40, 28, 0),
                  child: Column(
                    children: [
                      _LogoBadge()
                          .animate()
                          .scale(
                            begin: const Offset(0.5, 0.5),
                            duration: AppDurations.xl,
                            curve: Curves.elasticOut,
                          )
                          .fadeIn(duration: AppDurations.lg),

                      const SizedBox(height: 16),

                      Text(
                        AppStrings.appNameUpper,
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _kTextMuted,
                          letterSpacing: 3.2,
                        ),
                      ).animate().fadeIn(delay: 200.ms, duration: 500.ms),

                      const SizedBox(height: 22),

                      Text(
                        AppStrings.whoAreYou,
                        style: GoogleFonts.cormorantGaramond(
                          fontSize: 30,
                          fontWeight: FontWeight.w700,
                          color: _kTextTitle,
                          letterSpacing: -0.3,
                        ),
                      ).animate().fadeIn(delay: 300.ms, duration: 500.ms),

                      const SizedBox(height: 8),

                      Text(
                        AppStrings.chooseRole,
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          color: _kTextMuted,
                          height: 1.5,
                        ),
                      ).animate().fadeIn(delay: 380.ms, duration: 500.ms),

                      const SizedBox(height: 18),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _DividerDot(color: _kCustPrimary),
                          _DividerLine(),
                          _DividerDot(color: _kRestPrimary),
                          _DividerLine(),
                          _DividerDot(color: _kHotelPrimary),
                        ],
                      ).animate().fadeIn(delay: 430.ms, duration: 400.ms),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 36),
                    child: Column(
                      children: [
                        _RoleCard(
                          surfaceColor: _kCustSurface,
                          borderColor: _kCustBorder,
                          primary: _kCustPrimary,
                          deep: _kCustDeep,
                          accentDots: [_kRestPrimary, _kHotelPrimary],
                          icon: Icons.person_rounded,
                          title: AppStrings.iAmCustomer,
                          subtitle: AppStrings.customerCardSubtitle,
                          delay: 460,
                          onTap: () => _select(
                            venueType: '',
                            route: AppRoutes.customerLogin,
                          ),
                        ),

                        const SizedBox(height: 14),

                        _RoleCard(
                          surfaceColor: _kRestSurface,
                          borderColor: _kRestBorder,
                          primary: _kRestPrimary,
                          deep: _kRestDeep,
                          accentDots: [_kCustPrimary, _kHotelPrimary],
                          icon: Icons.restaurant_rounded,
                          title: AppStrings.iAmRestaurant,
                          subtitle: AppStrings.restaurantCardSubtitle,
                          delay: 560,
                          onTap: () => _select(
                            venueType: 'restaurant',
                            route: AppRoutes.restaurantLogin,
                          ),
                        ),

                        const SizedBox(height: 14),

                        _RoleCard(
                          surfaceColor: _kHotelSurface,
                          borderColor: _kHotelBorder,
                          primary: _kHotelPrimary,
                          deep: _kHotelDeep,
                          accentDots: [_kCustPrimary, _kRestPrimary],
                          icon: Icons.hotel_rounded,
                          title: AppStrings.iAmHotel,
                          subtitle: AppStrings.hotelCardSubtitle,
                          delay: 660,
                          onTap: () => _select(
                            venueType: 'hotel',
                            route: AppRoutes.hotelLogin,
                          ),
                        ),

                        const SizedBox(height: 28),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 6, height: 6,
                              decoration: BoxDecoration(
                                color: _kCustPrimary.withOpacity(0.60),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Your role shapes your experience',
                              style: GoogleFonts.dmSans(
                                fontSize: 12,
                                color: _kTextMuted,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              width: 6, height: 6,
                              decoration: BoxDecoration(
                                color: _kRestPrimary.withOpacity(0.60),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ).animate().fadeIn(delay: 760.ms, duration: 400.ms),
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

class _LogoBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 78, height: 78,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 78, height: 78,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: _kHotelPrimary.withOpacity(0.30), width: 1.5),
            ),
          ),
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: _kRestPrimary.withOpacity(0.35), width: 1.5),
            ),
          ),
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _kCustPrimary,
              boxShadow: [
                BoxShadow(
                  color: _kCustPrimary.withOpacity(0.35),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.eco_rounded, color: Colors.white, size: 26),
          ),
        ],
      ),
    );
  }
}

class _RoleCard extends StatefulWidget {
  final Color surfaceColor;
  final Color borderColor;
  final Color primary;
  final Color deep;
  final List<Color> accentDots;
  final IconData icon;
  final String title;
  final String subtitle;
  final int delay;
  final VoidCallback onTap;

  const _RoleCard({
    required this.surfaceColor,
    required this.borderColor,
    required this.primary,
    required this.deep,
    required this.accentDots,
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
            color: widget.surfaceColor,
            borderRadius: BorderRadius.circular(AppRadii.innerCard),
            border: Border.all(color: widget.borderColor, width: 1.3),
            boxShadow: [
              BoxShadow(
                color: widget.primary.withOpacity(0.13),
                blurRadius: 18,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 54, height: 54,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.primary,
                      boxShadow: [
                        BoxShadow(
                          color: widget.primary.withOpacity(0.28),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(widget.icon, color: Colors.white, size: 24),
                  ),
                  Positioned(
                    top: -2, right: -2,
                    child: Container(
                      width: 10, height: 10,
                      decoration: BoxDecoration(
                        color: widget.accentDots[0],
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: widget.surfaceColor, width: 1.5),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -2, left: -2,
                    child: Container(
                      width: 8, height: 8,
                      decoration: BoxDecoration(
                        color: widget.accentDots[1].withOpacity(0.75),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: widget.surfaceColor, width: 1.5),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: GoogleFonts.cormorantGaramond(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: _kTextTitle,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.subtitle,
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: _kTextBody,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _AccentPill(color: widget.primary),
                        const SizedBox(width: 4),
                        _AccentPill(color: widget.accentDots[0]),
                        const SizedBox(width: 4),
                        _AccentPill(color: widget.accentDots[1]),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: widget.primary.withOpacity(0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: widget.deep,
                  size: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(
            delay: Duration(milliseconds: widget.delay), duration: 500.ms)
        .slideY(
          begin: 0.15,
          end: 0,
          delay: Duration(milliseconds: widget.delay),
          duration: 500.ms,
          curve: Curves.easeOutCubic,
        );
  }
}

class _AccentPill extends StatelessWidget {
  final Color color;
  const _AccentPill({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18, height: 4,
      decoration: BoxDecoration(
        color: color.withOpacity(0.55),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

class _DividerDot extends StatelessWidget {
  final Color color;
  const _DividerDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 7, height: 7,
      decoration: BoxDecoration(
        color: color.withOpacity(0.65),
        shape: BoxShape.circle,
      ),
    );
  }
}

class _DividerLine extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28, height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 5),
      color: _kLakeMist,
    );
  }
}

class _BlobBgPainter extends CustomPainter {
  final double t;
  _BlobBgPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final angle = t * 2 * math.pi;

    void blob(double cx, double cy, double r, Color c, double op) {
      final center = Offset(cx, cy);
      canvas.drawCircle(center, r,
        Paint()..shader = RadialGradient(
          colors: [c.withOpacity(op), Colors.transparent],
        ).createShader(Rect.fromCircle(center: center, radius: r)));
    }

    blob(
      size.width * 0.12 + math.cos(angle) * 24,
      size.height * 0.18 + math.sin(angle) * 18,
      size.width * 0.50, _kCustPrimary, 0.11,
    );
    blob(
      size.width * 0.88 + math.sin(angle * 0.7) * 22,
      size.height * 0.70 + math.cos(angle * 0.7) * 26,
      size.width * 0.45, _kRestPrimary, 0.09,
    );
    blob(
      size.width * 0.5 + math.sin(angle * 1.2) * 18,
      size.height * 0.48 + math.cos(angle * 1.0) * 22,
      size.width * 0.32, _kHotelPrimary, 0.08,
    );
    blob(
      size.width * 0.80 + math.cos(angle * 0.9) * 20,
      size.height * 0.12 + math.sin(angle * 1.1) * 16,
      size.width * 0.30, const Color(0xFFEDD5A8), 0.35,
    );
  }

  @override
  bool shouldRepaint(_BlobBgPainter old) => old.t != t;
}