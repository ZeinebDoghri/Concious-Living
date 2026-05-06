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

  const _Item(this.iconOff, this.iconOn, this.label);
}

const _items = [
  _Item(Icons.home_outlined, Icons.home_rounded, 'Home'),
  _Item(Icons.camera_alt_outlined, Icons.camera_alt_rounded, 'Scan'),
  _Item(Icons.history_outlined, Icons.history_rounded, 'History'),
  _Item(Icons.shield_outlined, Icons.shield_rounded, 'Allergens'),
  _Item(Icons.person_outline_rounded, Icons.person_rounded, 'Profile'),
];

class CustomerShell extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const CustomerShell({super.key, required this.navigationShell});

  @override
  State<CustomerShell> createState() => _CustomerShellState();
}

class _CustomerShellState extends State<CustomerShell> {

  void _onTap(int index) {
    HapticFeedback.selectionClick();
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final index = widget.navigationShell.currentIndex;

    return Scaffold(
      backgroundColor: AppColors.oat,
      extendBody: true,
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 80),
            child: widget.navigationShell,
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: _WowNav(
              currentIndex: index,
              onTap: _onTap,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Floating nav bar ───────────────────────────────────────────────────────────
class _WowNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _WowNav({
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    return SizedBox(
      height: 64,
      child: Container(
        margin: EdgeInsets.fromLTRB(24, 0, 24, 16 + safeBottom),
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
        children: List.generate(_items.length, (i) {
          return _Tile(
            item: _items[i],
            isActive: currentIndex == i,
            activeColor: i == 1 ? AppColors.cherry : AppColors.olive,
            onTap: () => onTap(i),
          );
        }),
      ),
    ),
    );
  }
}

class _Tile extends StatelessWidget {
  final _Item item;
  final bool isActive;
  final Color activeColor;
  final VoidCallback onTap;

  const _Tile({
    required this.item,
    required this.isActive,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.symmetric(
              horizontal: isActive ? 16 : 10,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: isActive ? activeColor : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isActive ? item.iconOn : item.iconOff,
                  color: isActive ? AppColors.butter : AppColors.fog,
                  size: 20,
                ),
                if (isActive) ...[
                  const SizedBox(width: 8),
                  Text(
                    item.label,
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
      ),
    );
  }
}
