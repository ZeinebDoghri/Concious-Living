import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../providers/venue_type_provider.dart';

// ── Design tokens ──────────────────────────────────────────────────────────────
const _kOlive   = Color(0xFF5A7A18);
const _kCherry  = Color(0xFF8B1A1F);
const _kEmerald = Color(0xFF059669);
const _kEmeraldGlow = Color(0xFF10B981);
const _kCocoa   = Color(0xFF7C5C48);

// ── Branch mapping: visual index → StatefulShellRoute branch index ─────────────
// Branches in router: 0=Dashboard 1=Scan 2=Alertes 3=Déchets 4=Compost 5=Stocks 6=Profil
// We show only 4 tabs:           0=Dashboard   1=Scan   2=Compost   3=Profil
const _branchMap = [0, 1, 4, 6];

// ── Nav item meta ──────────────────────────────────────────────────────────────
class _Item {
  final IconData iconOff;
  final IconData iconOn;
  final String   label;
  final Color    color;
  final bool     isSpecial;
  const _Item(this.iconOff, this.iconOn, this.label, this.color,
      {this.isSpecial = false});
}

const _items = [
  _Item(Icons.dashboard_outlined,        Icons.dashboard_rounded,       'Dashboard', _kOlive),
  _Item(Icons.document_scanner_outlined, Icons.document_scanner_rounded,'Scan',      _kCherry),
  _Item(Icons.eco_outlined,              Icons.eco_rounded,             'Compost',   _kEmerald, isSpecial: true),
  _Item(Icons.person_outline_rounded,    Icons.person_rounded,          'Profil',    _kCocoa),
];

// ── Shell ──────────────────────────────────────────────────────────────────────
class RestaurantShell extends StatefulWidget {
  final StatefulNavigationShell navigationShell;
  const RestaurantShell({super.key, required this.navigationShell});

  @override
  State<RestaurantShell> createState() => _RestaurantShellState();
}

class _RestaurantShellState extends State<RestaurantShell>
    with TickerProviderStateMixin {
  late final AnimationController _pageAnim;

  @override
  void initState() {
    super.initState();
    _pageAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    )..forward();
  }

  @override
  void dispose() {
    _pageAnim.dispose();
    super.dispose();
  }

  /// Returns the visual tab index (0–3) for the current branch index.
  int get _visualIndex {
    final bi = widget.navigationShell.currentIndex;
    final vi = _branchMap.indexOf(bi);
    return vi < 0 ? 0 : vi;
  }

  void _onTap(int visualIndex) {
    HapticFeedback.selectionClick();
    final branchIndex = _branchMap[visualIndex];
    // Profile tab — route differs for hotel vs restaurant
    if (branchIndex == 6) {
      final vt = context.read<VenueTypeProvider>().venueType;
      context.go(vt == 'hotel'
          ? AppRoutes.hotelProfile
          : AppRoutes.restaurantProfile);
      return;
    }
    widget.navigationShell.goBranch(
      branchIndex,
      initialLocation: branchIndex == widget.navigationShell.currentIndex,
    );
    // Restart page entrance animation
    _pageAnim.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final vi     = _visualIndex;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F0),
      extendBody: true,
      body: AnimatedBuilder(
        animation: _pageAnim,
        builder: (_, child) => FadeTransition(
          opacity: CurvedAnimation(parent: _pageAnim, curve: Curves.easeOut),
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.016),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(parent: _pageAnim, curve: Curves.easeOutCubic),
            ),
            child: child,
          ),
        ),
        child: KeyedSubtree(
          key: ValueKey(vi),
          child: widget.navigationShell,
        ),
      ),
      bottomNavigationBar: _GlassNav(
        currentIndex: vi,
        bottomPad: bottom,
        onTap: _onTap,
      ),
    );
  }
}

// ── Glassmorphism nav bar ──────────────────────────────────────────────────────
class _GlassNav extends StatefulWidget {
  final int currentIndex;
  final double bottomPad;
  final ValueChanged<int> onTap;

  const _GlassNav({
    required this.currentIndex,
    required this.bottomPad,
    required this.onTap,
  });

  @override
  State<_GlassNav> createState() => _GlassNavState();
}

class _GlassNavState extends State<_GlassNav> with TickerProviderStateMixin {
  late final List<AnimationController> _bounce;
  late final List<Animation<double>>   _scale;

  @override
  void initState() {
    super.initState();
    _bounce = List.generate(_items.length, (i) {
      final ctrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 320),
        value: i == widget.currentIndex ? 1.0 : 0.0,
      );
      return ctrl;
    });
    _scale = _bounce.map((c) =>
      Tween<double>(begin: 1.0, end: 1.18)
          .animate(CurvedAnimation(parent: c, curve: Curves.easeOutBack)),
    ).toList();
  }

  @override
  void didUpdateWidget(_GlassNav old) {
    super.didUpdateWidget(old);
    if (old.currentIndex != widget.currentIndex) {
      _bounce[old.currentIndex].reverse();
      _bounce[widget.currentIndex].forward();
    }
  }

  @override
  void dispose() {
    for (final c in _bounce) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(14, 0, 14, widget.bottomPad + 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            height: 66,
            decoration: BoxDecoration(
              color: const Color(0xFF1A2310).withValues(alpha: 0.88),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.10),
                width: 0.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.28),
                  blurRadius: 32,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: _kEmeraldGlow.withValues(alpha: 0.06),
                  blurRadius: 20,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: List.generate(_items.length, (i) {
                final item = _items[i];
                if (item.isSpecial) {
                  return _CompostTile(
                    isActive: widget.currentIndex == i,
                    scale: _scale[i],
                    onTap: () => widget.onTap(i),
                  );
                }
                return _Tile(
                  item: item,
                  isActive: widget.currentIndex == i,
                  scale: _scale[i],
                  onTap: () => widget.onTap(i),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Standard tile ──────────────────────────────────────────────────────────────
class _Tile extends StatelessWidget {
  final _Item item;
  final bool  isActive;
  final Animation<double> scale;
  final VoidCallback onTap;

  const _Tile({
    required this.item,
    required this.isActive,
    required this.scale,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: ScaleTransition(
          scale: scale,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOutCubic,
                width:  isActive ? 46 : 34,
                height: isActive ? 34 : 28,
                decoration: isActive
                    ? BoxDecoration(
                        color: item.color.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: item.color.withValues(alpha: 0.25),
                            blurRadius: 10,
                          ),
                        ],
                      )
                    : null,
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    transitionBuilder: (child, anim) => ScaleTransition(
                      scale: anim, child: child,
                    ),
                    child: Icon(
                      isActive ? item.iconOn : item.iconOff,
                      key: ValueKey(isActive),
                      size: 21,
                      color: isActive
                          ? item.color
                          : Colors.white.withValues(alpha: 0.38),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 3),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: GoogleFonts.inter(
                  fontSize: 9.5,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                  color: isActive
                      ? item.color
                      : Colors.white.withValues(alpha: 0.38),
                ),
                child: Text(item.label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Compost tile — pulsing emerald jewel ───────────────────────────────────────
class _CompostTile extends StatefulWidget {
  final bool isActive;
  final Animation<double> scale;
  final VoidCallback onTap;

  const _CompostTile({
    required this.isActive,
    required this.scale,
    required this.onTap,
  });

  @override
  State<_CompostTile> createState() => _CompostTileState();
}

class _CompostTileState extends State<_CompostTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.mediumImpact();
          widget.onTap();
        },
        behavior: HitTestBehavior.opaque,
        child: ScaleTransition(
          scale: widget.scale,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedBuilder(
                animation: _pulse,
                builder: (_, child) => Container(
                  width: 50,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF065F46), _kEmeraldGlow],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: _kEmeraldGlow.withValues(
                          alpha: widget.isActive
                              ? 0.45 + _pulse.value * 0.25
                              : 0.20 + _pulse.value * 0.12,
                        ),
                        blurRadius: widget.isActive
                            ? 16 + _pulse.value * 10
                            : 8 + _pulse.value * 4,
                        spreadRadius: widget.isActive ? 1 : 0,
                      ),
                    ],
                  ),
                  child: child,
                ),
                child: const Center(
                  child: Icon(Icons.eco_rounded, color: Colors.white, size: 22),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Compost',
                style: GoogleFonts.inter(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  color: widget.isActive
                      ? _kEmeraldGlow
                      : Colors.white.withValues(alpha: 0.50),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
