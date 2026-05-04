import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';

// ── Design tokens ──────────────────────────────────────────────────────────────
const _kDark     = Color(0xFF0A1628);
const _kEmerald  = Color(0xFF00C896);
const _kAmber    = Color(0xFFF59E0B);
const _kRose     = Color(0xFFFF6B6B);
const _kSlate    = Color(0xFF94A3B8);

// Branch mapping: visual index → StatefulShellRoute branch index
// Branches in router: 0=Dashboard 1=Scan 2=Alertes 3=Dechets 4=Compost 5=Stocks 6=Profil
// New nav: 0=Dashboard  1=Scan  2=Dechets  3=Profil
const _branchMap = [0, 1, 3, 6];

class _Item {
  final IconData icon;
  final String   label;
  final Color    color;
  const _Item(this.icon, this.label, this.color);
}

const _items = [
  _Item(Icons.dashboard_rounded,        'Dashboard', _kEmerald),
  _Item(Icons.document_scanner_rounded, 'Scan',      _kAmber),
  _Item(Icons.delete_rounded,           'Dechets',   _kRose),
  _Item(Icons.person_rounded,           'Profile',   _kSlate),
];

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
      duration: const Duration(milliseconds: 320),
    )..forward();
  }

  @override
  void dispose() {
    _pageAnim.dispose();
    super.dispose();
  }

  int get _visualIndex {
    final bi = widget.navigationShell.currentIndex;
    final vi = _branchMap.indexOf(bi);
    return vi < 0 ? 0 : vi;
  }

  void _onTap(int visualIndex) {
    HapticFeedback.selectionClick();
    final branchIndex = _branchMap[visualIndex];
    if (branchIndex == 6) {
      context.go(AppRoutes.restaurantProfile);
      return;
    }
    widget.navigationShell.goBranch(
      branchIndex,
      initialLocation: branchIndex == widget.navigationShell.currentIndex,
    );
    _pageAnim.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final vi     = _visualIndex;

    return Scaffold(
      backgroundColor: _kDark,
      extendBody: true,
      body: AnimatedBuilder(
        animation: _pageAnim,
        builder: (_, child) => FadeTransition(
          opacity: CurvedAnimation(parent: _pageAnim, curve: Curves.easeOut),
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.012),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: _pageAnim, curve: Curves.easeOutCubic)),
            child: child,
          ),
        ),
        child: KeyedSubtree(
          key: ValueKey(vi),
          child: widget.navigationShell,
        ),
      ),
      bottomNavigationBar: _FloatingNav(
        currentIndex: vi,
        bottomPad: bottom,
        onTap: _onTap,
      ),
    );
  }
}

// ── Floating Nav ───────────────────────────────────────────────────────────────
class _FloatingNav extends StatefulWidget {
  final int currentIndex;
  final double bottomPad;
  final ValueChanged<int> onTap;

  const _FloatingNav({
    required this.currentIndex,
    required this.bottomPad,
    required this.onTap,
  });

  @override
  State<_FloatingNav> createState() => _FloatingNavState();
}

class _FloatingNavState extends State<_FloatingNav>
    with TickerProviderStateMixin {
  late final List<AnimationController> _controllers;
  late final List<Animation<double>>   _scales;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(_items.length, (i) {
      return AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 300),
        value: i == widget.currentIndex ? 1.0 : 0.0,
      );
    });
    _scales = _controllers.map((c) =>
      Tween<double>(begin: 1.0, end: 1.15)
          .animate(CurvedAnimation(parent: c, curve: Curves.easeOutBack)),
    ).toList();
  }

  @override
  void didUpdateWidget(_FloatingNav old) {
    super.didUpdateWidget(old);
    if (old.currentIndex != widget.currentIndex) {
      _controllers[old.currentIndex].reverse();
      _controllers[widget.currentIndex].forward();
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, widget.bottomPad + 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Container(
            height: 70,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF1E2D3D).withValues(alpha: 0.95),
                  const Color(0xFF0A1628).withValues(alpha: 0.98),
                ],
              ),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.08),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 40,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: _kEmerald.withValues(alpha: 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Dashboard
                _NavTile(
                  item: _items[0],
                  isActive: widget.currentIndex == 0,
                  scale: _scales[0],
                  onTap: () => widget.onTap(0),
                ),
                // Scan — centre special
                _ScanCenterButton(
                  isActive: widget.currentIndex == 1,
                  scale: _scales[1],
                  onTap: () => widget.onTap(1),
                ),
                // Dechets
                _NavTile(
                  item: _items[2],
                  isActive: widget.currentIndex == 2,
                  scale: _scales[2],
                  onTap: () => widget.onTap(2),
                ),
                // Profil
                _NavTile(
                  item: _items[3],
                  isActive: widget.currentIndex == 3,
                  scale: _scales[3],
                  onTap: () => widget.onTap(3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Standard nav tile ──────────────────────────────────────────────────────────
class _NavTile extends StatelessWidget {
  final _Item item;
  final bool isActive;
  final Animation<double> scale;
  final VoidCallback onTap;

  const _NavTile({
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
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                width: isActive ? 48 : 36,
                height: isActive ? 36 : 28,
                decoration: isActive
                    ? BoxDecoration(
                        color: item.color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: item.color.withValues(alpha: 0.3),
                            blurRadius: 12,
                          ),
                        ],
                      )
                    : null,
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    transitionBuilder: (child, anim) =>
                        ScaleTransition(scale: anim, child: child),
                    child: Icon(
                      item.icon,
                      key: ValueKey(isActive),
                      size: 20,
                      color: isActive
                          ? item.color
                          : Colors.white.withValues(alpha: 0.30),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                  color: isActive
                      ? item.color
                      : Colors.white.withValues(alpha: 0.30),
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

// ── Scan centre button — glowing amber ────────────────────────────────────────
class _ScanCenterButton extends StatefulWidget {
  final bool isActive;
  final Animation<double> scale;
  final VoidCallback onTap;

  const _ScanCenterButton({
    required this.isActive,
    required this.scale,
    required this.onTap,
  });

  @override
  State<_ScanCenterButton> createState() => _ScanCenterButtonState();
}

class _ScanCenterButtonState extends State<_ScanCenterButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
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
      flex: 2,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.mediumImpact();
          widget.onTap();
        },
        behavior: HitTestBehavior.opaque,
        child: ScaleTransition(
          scale: widget.scale,
          child: Center(
            child: AnimatedBuilder(
              animation: _pulse,
              builder: (_, child) => Container(
                width: 62,
                height: 52,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFFF9A3C), Color(0xFFF59E0B)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: _kAmber.withValues(
                        alpha: widget.isActive
                            ? 0.55 + _pulse.value * 0.25
                            : 0.25 + _pulse.value * 0.15,
                      ),
                      blurRadius: widget.isActive
                          ? 20 + _pulse.value * 12
                          : 10 + _pulse.value * 6,
                      spreadRadius: widget.isActive ? 2 : 0,
                    ),
                  ],
                ),
                child: child,
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.document_scanner_rounded,
                      color: Colors.white, size: 22),
                  SizedBox(height: 2),
                  Text(
                    'SCAN',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
