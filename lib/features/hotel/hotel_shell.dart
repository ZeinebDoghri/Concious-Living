import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants.dart';

// ── Brand tokens ───────────────────────────────────────────────────────────────
const _kOat      = Color(0xFFEDE0D3);
const _kCherry   = Color(0xFF75070C);
const _kOlive    = Color(0xFF4F6815);
const _kButterD  = Color(0xFFE8C84A);
const _kEspresso = Color(0xFF2C1A1B);

// Hotel nav: 0=Dashboard  1=Scan  2=Profile
// Router branch indices must match StatefulShellRoute branches order:
//   branch 0 = hotel/dashboard
//   branch 1 = hotel/scan
//   branch 2 = hotel/profile
const _branchMap = [0, 1, 2];

class _Item {
  final IconData icon;
  final String label;
  final Color color;
  const _Item(this.icon, this.label, this.color);
}

const _items = [
  _Item(Icons.hotel_rounded,             'Dashboard', _kCherry),
  _Item(Icons.document_scanner_rounded,  'Scan',      _kButterD),
  _Item(Icons.person_rounded,            'Profile',   _kOlive),
];

// ── Shell widget ───────────────────────────────────────────────────────────────
class HotelShell extends StatefulWidget {
  final StatefulNavigationShell navigationShell;
  const HotelShell({super.key, required this.navigationShell});

  @override
  State<HotelShell> createState() => _HotelShellState();
}

class _HotelShellState extends State<HotelShell> with TickerProviderStateMixin {
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
    if (branchIndex == 2) {
      context.go(AppRoutes.hotelProfile);
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
      backgroundColor: _kOat,
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
      bottomNavigationBar: _HotelFloatingNav(
        currentIndex: vi,
        bottomPad: bottom,
        onTap: _onTap,
      ),
    );
  }
}

// ── Floating Nav ───────────────────────────────────────────────────────────────
class _HotelFloatingNav extends StatefulWidget {
  final int currentIndex;
  final double bottomPad;
  final ValueChanged<int> onTap;

  const _HotelFloatingNav({
    required this.currentIndex,
    required this.bottomPad,
    required this.onTap,
  });

  @override
  State<_HotelFloatingNav> createState() => _HotelFloatingNavState();
}

class _HotelFloatingNavState extends State<_HotelFloatingNav>
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
  void didUpdateWidget(_HotelFloatingNav old) {
    super.didUpdateWidget(old);
    if (old.currentIndex != widget.currentIndex) {
      _controllers[old.currentIndex].reverse();
      _controllers[widget.currentIndex].forward();
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) c.dispose();
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
                  _kEspresso.withValues(alpha: 0.92),
                  const Color(0xFF1A0C0D).withValues(alpha: 0.97),
                ],
              ),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: _kCherry.withValues(alpha: 0.20),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 40,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: _kCherry.withValues(alpha: 0.08),
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
                // Profile
                _NavTile(
                  item: _items[2],
                  isActive: widget.currentIndex == 2,
                  scale: _scales[2],
                  onTap: () => widget.onTap(2),
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
                        color: item.color.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: item.color.withValues(alpha: 0.35),
                            blurRadius: 14,
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
                    colors: [Color(0xFFFFD966), Color(0xFFE8C84A)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: _kButterD.withValues(
                        alpha: widget.isActive
                            ? 0.60 + _pulse.value * 0.25
                            : 0.28 + _pulse.value * 0.15,
                      ),
                      blurRadius: widget.isActive
                          ? 22 + _pulse.value * 12
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
                      color: Color(0xFF2C1A1B), size: 22),
                  SizedBox(height: 2),
                  Text(
                    'SCAN',
                    style: TextStyle(
                      color: Color(0xFF2C1A1B),
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
