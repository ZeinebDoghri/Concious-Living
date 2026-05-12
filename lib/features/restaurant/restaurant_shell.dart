import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../providers/venue_type_provider.dart';
import '../../shared/animations/role_animated_background.dart';

// ── Restaurant ORKA pastel theme tokens ──────────────────────────────────
const _rPrimary = Color(0xFF8FA84A);
const _rDeep = Color(0xFF5A7030);
const _rSurface = Color(0xFFF5F8EE);
const _rSoftBg = Color(0xFFE3E8D1);
const _rTextMuted = Color(0xFF8C7E78);

// Branch mapping: visual index → StatefulShellRoute branch index
// Router branches: 0=Dashboard 1=Scan 2=Alerts 3=Waste/History 4=Compost 5=Inventory 6=Profile
const _branchMap = [0, 1, 2, 3, 4, 6];

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem(this.icon, this.label);
}

const _navItems = [
  _NavItem(Icons.dashboard_rounded, 'Dashboard'),
  _NavItem(Icons.document_scanner_rounded, 'Scan'),
  _NavItem(Icons.notifications_rounded, 'Alerts'),
  _NavItem(Icons.history_rounded, 'History'),
  _NavItem(Icons.eco_rounded, 'Compost'),
  _NavItem(Icons.person_rounded, 'Profile'),
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
    if (branchIndex == 3) {
      context.go(AppRoutes.restaurantHistory);
      _pageAnim.forward(from: 0);
      return;
    }
    if (branchIndex == 6) {
      final vt = context.read<VenueTypeProvider>().venueType;
      context.go(
        vt == 'hotel' ? AppRoutes.hotelProfile : AppRoutes.restaurantProfile,
      );
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
    final vi = _visualIndex;

    return Scaffold(
      backgroundColor: _rSurface,
      body: RoleAnimatedBackground(
        role: AmbientRole.restaurant,
        activeIndex: vi,
        intensity: 1.65,
        child: AnimatedBuilder(
          animation: _pageAnim,
          builder: (_, child) => FadeTransition(
            opacity: CurvedAnimation(parent: _pageAnim, curve: Curves.easeOut),
            child: child,
          ),
          child: KeyedSubtree(key: ValueKey(vi), child: widget.navigationShell),
        ),
      ),
      bottomNavigationBar: _PastelNav(currentIndex: vi, onTap: _onTap),
    );
  }
}

// ── Pastel bottom nav bar ──────────────────────────────────────────────────────
class _PastelNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _PastelNav({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: _rPrimary.withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Row(
            children: List.generate(_navItems.length, (i) {
              return _NavTile(
                item: _navItems[i],
                isActive: currentIndex == i,
                onTap: () => onTap(i),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  final _NavItem item;
  final bool isActive;
  final VoidCallback onTap;

  const _NavTile({
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
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: isActive
                  ? BoxDecoration(
                      color: _rSoftBg,
                      borderRadius: BorderRadius.circular(999),
                    )
                  : null,
              child: Icon(
                item.icon,
                size: 22,
                color: isActive ? _rPrimary : _rTextMuted,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              item.label,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                color: isActive ? _rDeep : _rTextMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
