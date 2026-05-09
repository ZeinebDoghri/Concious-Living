import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants.dart';
import '../../shared/animations/role_animated_background.dart';
import '../../shared/widgets/floating_navbar.dart';
import '../../theme/role_colors.dart';

const _branchMap = [0, 1, 2];

const _items = [
  FloatingNavItem(
    iconOff: Icons.dashboard_outlined,
    iconOn: Icons.dashboard_rounded,
    label: 'Dashboard',
  ),
  FloatingNavItem(
    iconOff: Icons.qr_code_scanner_outlined,
    iconOn: Icons.qr_code_scanner_rounded,
    label: 'Scan',
  ),
  FloatingNavItem(
    iconOff: Icons.person_outline_rounded,
    iconOn: Icons.person_rounded,
    label: 'Profile',
  ),
];

class HotelShell extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const HotelShell({super.key, required this.navigationShell});

  @override
  State<HotelShell> createState() => _HotelShellState();
}

class _HotelShellState extends State<HotelShell>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    )..forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  int get _visualIndex {
    final branchIndex = widget.navigationShell.currentIndex;
    final visualIndex = _branchMap.indexOf(branchIndex);
    return visualIndex < 0 ? 0 : visualIndex;
  }

  void _onTap(int visualIndex) {
    final branchIndex = _branchMap[visualIndex];
    if (branchIndex == 2) {
      context.go(AppRoutes.hotelProfile);
    } else {
      widget.navigationShell.goBranch(
        branchIndex,
        initialLocation: branchIndex == widget.navigationShell.currentIndex,
      );
    }
    _ctrl.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    const colors = RoleColorScheme.hotel;

    return Scaffold(
      backgroundColor: const Color(0xFFF4FAF7),
      body: RoleAnimatedBackground(
        role: AmbientRole.hotel,
        activeIndex: _visualIndex,
        intensity: 1.65,
        child: FadeTransition(
          opacity: CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
          child: SlideTransition(
            position:
                Tween<Offset>(
                  begin: const Offset(0, 0.025),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
                ),
            child: widget.navigationShell,
          ),
        ),
      ),
      bottomNavigationBar: RoleMaterialBottomNav(
        items: _items,
        currentIndex: _visualIndex,
        onTap: _onTap,
        role: colors,
      ),
    );
  }
}
