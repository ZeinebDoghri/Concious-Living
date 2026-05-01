import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants.dart';

// ── Nav item definition ────────────────────────────────────────────────────────
class _Item {
  final IconData iconOff;
  final IconData iconOn;
  final String label;
  final Color color;

  const _Item(this.iconOff, this.iconOn, this.label, this.color);
}

const _items = [
  _Item(Icons.home_outlined, Icons.home_rounded, 'Accueil', Color(0xFF5A7A18)),
  _Item(Icons.camera_alt_outlined, Icons.camera_alt_rounded, 'Scanner', Color(0xFF8B1A1F)),
  _Item(Icons.history_outlined, Icons.history_rounded, 'Historique', Color(0xFF3B5BB5)),
  _Item(Icons.shield_outlined, Icons.shield_rounded, 'Allergènes', Color(0xFFD97706)),
  _Item(Icons.person_outline_rounded, Icons.person_rounded, 'Profil', Color(0xFF6B4F52)),
];

class CustomerShell extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const CustomerShell({super.key, required this.navigationShell});

  @override
  State<CustomerShell> createState() => _CustomerShellState();
}

class _CustomerShellState extends State<CustomerShell>
    with SingleTickerProviderStateMixin {
  late final AnimationController _rippleController;

  @override
  void initState() {
    super.initState();
    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void dispose() {
    _rippleController.dispose();
    super.dispose();
  }

  void _onTap(int index) {
    HapticFeedback.selectionClick();
    _rippleController.forward(from: 0);
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final index = widget.navigationShell.currentIndex;
    final bottomPad = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1E),
      extendBody: true,
      body: widget.navigationShell,
      bottomNavigationBar: _WowNav(
        currentIndex: index,
        bottomPad: bottomPad,
        rippleController: _rippleController,
        onTap: _onTap,
      ),
    );
  }
}

// ── Floating nav bar ───────────────────────────────────────────────────────────
class _WowNav extends StatelessWidget {
  final int currentIndex;
  final double bottomPad;
  final AnimationController rippleController;
  final ValueChanged<int> onTap;

  const _WowNav({
    required this.currentIndex,
    required this.bottomPad,
    required this.rippleController,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, bottomPad + 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B).withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.08),
                width: 0.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: List.generate(_items.length, (i) {
                // Scanner tab gets special treatment
                if (i == 1) {
                  return _ScanTile(
                    isActive: currentIndex == 1,
                    onTap: () => onTap(1),
                  );
                }
                return _Tile(
                  item: _items[i],
                  isActive: currentIndex == i,
                  onTap: () => onTap(i),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Standard tab tile ──────────────────────────────────────────────────────────
class _Tile extends StatelessWidget {
  final _Item item;
  final bool isActive;
  final VoidCallback onTap;

  const _Tile({
    required this.item,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              width: isActive ? 40 : 32,
              height: isActive ? 32 : 24,
              decoration: BoxDecoration(
                color: isActive
                    ? item.color.withValues(alpha: 0.18)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    isActive ? item.iconOn : item.iconOff,
                    key: ValueKey(isActive),
                    color: isActive
                        ? item.color
                        : Colors.white.withValues(alpha: 0.35),
                    size: 20,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 3),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: GoogleFonts.inter(
                fontSize: 9,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                color: isActive
                    ? item.color
                    : Colors.white.withValues(alpha: 0.35),
              ),
              child: Text(item.label),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Scan tab (special elevated style) ─────────────────────────────────────────
class _ScanTile extends StatelessWidget {
  final bool isActive;
  final VoidCallback onTap;

  const _ScanTile({required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutBack,
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isActive
                    ? [AppColors.cherryLight, AppColors.cherry]
                    : [
                        AppColors.cherry.withValues(alpha: 0.6),
                        AppColors.cherryDark.withValues(alpha: 0.6),
                      ],
              ),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: AppColors.cherry.withValues(alpha: 0.5),
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                    ]
                  : [],
            ),
            child: Icon(
              Icons.camera_alt_rounded,
              color: Colors.white,
              size: isActive ? 22 : 20,
            ),
          ),
        ),
      ),
    );
  }
}
