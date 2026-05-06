import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants.dart';

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
  _Item(Icons.hotel_rounded,             'Dashboard', AppColors.cherry),
  _Item(Icons.document_scanner_rounded,  'Scan',      AppColors.butterDeep),
  _Item(Icons.person_rounded,            'Profile',   AppColors.olive),
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
      backgroundColor: AppColors.oat,
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
class _HotelFloatingNav extends StatelessWidget {
  final int currentIndex;
  final double bottomPad;
  final ValueChanged<int> onTap;

  const _HotelFloatingNav({
    required this.currentIndex,
    required this.bottomPad,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      margin: EdgeInsets.fromLTRB(24, 0, 24, 16 + bottomPad),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A2C1A1B),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: List.generate(_items.length, (i) {
          return Expanded(
            child: Center(
              child: _NavTile(
                item: _items[i],
                isActive: currentIndex == i,
                onTap: () => onTap(i),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ── Standard nav tile ──────────────────────────────────────────────────────────
class _NavTile extends StatefulWidget {
  final _Item item;
  final bool isActive;
  final VoidCallback onTap;

  const _NavTile({
    required this.item,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_NavTile> createState() => _NavTileState();
}

class _NavTileState extends State<_NavTile> with SingleTickerProviderStateMixin {
  late final AnimationController _scaleController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      value: widget.isActive ? 1.0 : 0.0,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOutBack),
    );
  }

  @override
  void didUpdateWidget(_NavTile old) {
    super.didUpdateWidget(old);
    if (old.isActive != widget.isActive) {
      if (widget.isActive) {
        _scaleController.forward();
      } else {
        _scaleController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(
            horizontal: widget.isActive ? 16 : 10,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: widget.isActive ? AppColors.olive : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.item.icon,
                color: widget.isActive ? AppColors.butter : AppColors.fog,
                size: 20,
              ),
              if (widget.isActive) ...[
                const SizedBox(width: 8),
                Text(
                  widget.item.label,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.butter,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
