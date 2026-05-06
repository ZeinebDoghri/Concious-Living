import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';

// Branch mapping: visual index → StatefulShellRoute branch index
// Branches in router: 0=Dashboard 1=Scan 2=Alertes 3=Dechets 4=Compost 5=Stocks 6=Profil
// New nav: 0=Dashboard  1=Scan  2=Dechets  3=Profil
const _branchMap = [0, 1, 3, 6];

class _Item {
  final IconData iconOff;
  final IconData iconOn;
  final String label;
  const _Item(this.iconOff, this.iconOn, this.label);
}

const _items = [
  _Item(Icons.dashboard_outlined, Icons.dashboard_rounded, 'Dashboard'),
  _Item(Icons.document_scanner_outlined, Icons.document_scanner_rounded, 'Scan'),
  _Item(Icons.delete_outline_rounded, Icons.delete_rounded, 'Dechets'),
  _Item(Icons.person_outline_rounded, Icons.person_rounded, 'Profile'),
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
    final vi = _visualIndex;

    return Scaffold(
      backgroundColor: AppColors.oat,
      extendBody: true,
      body: Stack(
        children: [
          AnimatedBuilder(
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
            child: Padding(
              padding: const EdgeInsets.only(bottom: 80),
              child: KeyedSubtree(
                key: ValueKey(vi),
                child: widget.navigationShell,
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: _FloatingNav(
              currentIndex: vi,
              onTap: _onTap,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Floating Nav ───────────────────────────────────────────────────────────────
class _FloatingNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _FloatingNav({
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    return Container(
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
          return _NavTile(
            item: _items[i],
            isActive: currentIndex == i,
            onTap: () => onTap(i),
          );
        }),
      ),
    );
  }
}

// ── Standard nav tile ──────────────────────────────────────────────────────────
class _NavTile extends StatelessWidget {
  final _Item item;
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
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.symmetric(
              horizontal: isActive ? 16 : 10,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: isActive ? AppColors.olive : Colors.transparent,
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
