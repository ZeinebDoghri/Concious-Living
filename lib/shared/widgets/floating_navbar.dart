import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/brand_palette.dart';
import '../../theme/role_colors.dart';

class FloatingNavItem {
  final IconData? icon;
  final IconData? iconOff;
  final IconData? iconOn;
  final String label;

  const FloatingNavItem({
    this.icon,
    this.iconOff,
    this.iconOn,
    required this.label,
  });

  IconData get inactiveIcon => iconOff ?? icon ?? Icons.circle_outlined;
  IconData get activeIcon => iconOn ?? icon ?? inactiveIcon;
}

class FloatingNavbar extends StatelessWidget {
  final List<FloatingNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final RoleColorScheme colors;

  const FloatingNavbar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1A000000),
                blurRadius: 24,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (index) {
              final active = index == currentIndex;
              final item = items[index];
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  HapticFeedback.selectionClick();
                  onTap(index);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  padding: active
                      ? const EdgeInsets.symmetric(horizontal: 16, vertical: 9)
                      : const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: active ? colors.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        active ? item.activeIcon : item.inactiveIcon,
                        size: active ? 18 : 20,
                        color: active ? Colors.white : colors.textMuted,
                      ),
                      if (active) ...[
                        const SizedBox(width: 4),
                        Text(
                          item.label,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            height: 1,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

/// Material bottom bar — fixed type, parchment surface, role accent selection.
class RoleMaterialBottomNav extends StatelessWidget {
  final List<FloatingNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final RoleColorScheme role;

  const RoleMaterialBottomNav({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 16,
      color: kParchment,
      shadowColor: kEspresso.withValues(alpha: 0.12),
      child: SafeArea(
        top: false,
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: kParchment,
          elevation: 0,
          selectedItemColor: role.navSelected,
          unselectedItemColor: kFog,
          selectedLabelStyle: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
          unselectedLabelStyle: GoogleFonts.inter(fontSize: 10),
          currentIndex: currentIndex.clamp(0, items.length - 1),
          onTap: (i) {
            HapticFeedback.selectionClick();
            onTap(i);
          },
          items: List.generate(items.length, (index) {
            final item = items[index];
            final selected = index == currentIndex;
            return BottomNavigationBarItem(
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: AnimatedContainer(
                  key: ValueKey('$index-${selected ? 1 : 0}'),
                  duration: const Duration(milliseconds: 200),
                  padding: EdgeInsets.all(selected ? 6 : 0),
                  decoration: BoxDecoration(
                    color: selected
                        ? role.navSelected.withValues(alpha: 0.12)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    selected ? item.activeIcon : item.inactiveIcon,
                    color: selected ? role.navSelected : kFog,
                    size: 24,
                  ),
                ),
              ),
              label: item.label,
            );
          }),
        ),
      ),
    );
  }
}

class FloatingPillNavbar extends StatelessWidget {
  final List<FloatingNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final RoleColorScheme role;
  final double bottomPad;

  const FloatingPillNavbar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
    required this.role,
    this.bottomPad = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, bottomPad + 20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 24,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(items.length, (index) {
            final active = index == currentIndex;
            final item = items[index];
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                HapticFeedback.selectionClick();
                onTap(index);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                padding: active
                    ? const EdgeInsets.symmetric(horizontal: 16, vertical: 9)
                    : const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: active ? role.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      active ? item.activeIcon : item.inactiveIcon,
                      size: active ? 18 : 20,
                      color: active ? Colors.white : role.textMuted,
                    ),
                    if (active) ...[
                      const SizedBox(width: 4),
                      Text(
                        item.label,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          height: 1,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
