import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../providers/venue_type_provider.dart';

// ── colour tokens ─────────────────────────────────────────────────────────────
const _kEmerald      = Color(0xFF059669);
const _kEmeraldGlow  = Color(0xFF10B981);
const _kOlive        = Color(0xFF5A7A18);
const _kCherry       = Color(0xFF8B1A1F);
const _kAmber        = Color(0xFFD97706);
const _kSlate        = Color(0xFF64748B);
const _kIndigo       = Color(0xFF6366F1);
const _kCocoa        = Color(0xFF7C5C48);
const _kInactive     = Color(0xFFCBD5E1);
const _kNavBg        = Color(0xFFFFFFFF);

// ── nav item meta ─────────────────────────────────────────────────────────────
class _Item {
  final IconData icon;
  final IconData activeIcon;
  final String   label;
  final Color    color;
  final bool     isSpecial;
  const _Item(this.icon, this.activeIcon, this.label, this.color,
      {this.isSpecial = false});
}

const _items = [
  _Item(Icons.dashboard_outlined,         Icons.dashboard_rounded,        'Dashboard', _kOlive),
  _Item(Icons.document_scanner_outlined,  Icons.document_scanner_rounded, 'Scan',      _kCherry),
  _Item(Icons.notifications_none_rounded, Icons.notifications_rounded,    'Alertes',   _kAmber),
  _Item(Icons.delete_outline_rounded,     Icons.delete_rounded,           'Déchets',   _kSlate),
  _Item(Icons.eco_outlined,              Icons.eco_rounded,              'Compost',   _kEmerald, isSpecial: true),
  _Item(Icons.inventory_2_outlined,       Icons.inventory_2_rounded,      'Stocks',    _kIndigo),
  _Item(Icons.person_outline_rounded,     Icons.person_rounded,           'Profil',    _kCocoa),
];

// ── Shell ─────────────────────────────────────────────────────────────────────
class RestaurantShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  const RestaurantShell({super.key, required this.navigationShell});

  void _onTap(BuildContext context, int index) {
    HapticFeedback.selectionClick();
    // Branch 6 → Profile (hotel or restaurant)
    if (index == 6) {
      final vt = context.read<VenueTypeProvider>().venueType;
      context.go(vt == 'hotel'
          ? AppRoutes.hotelProfile
          : AppRoutes.restaurantProfile);
      return;
    }
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final idx = navigationShell.currentIndex;
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      extendBody: true,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 260),
        switchInCurve:  Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, anim) => FadeTransition(
          opacity: anim,
          child: SlideTransition(
            position: Tween<Offset>(
                    begin: const Offset(0, 0.018), end: Offset.zero)
                .animate(anim),
            child: child,
          ),
        ),
        child: KeyedSubtree(key: ValueKey(idx), child: navigationShell),
      ),
      bottomNavigationBar: _WowNav(
        currentIndex: idx,
        onTap: (i) => _onTap(context, i),
      ),
    );
  }
}

// ── WOW nav bar ───────────────────────────────────────────────────────────────
class _WowNav extends StatefulWidget {
  final int currentIndex;
  final void Function(int) onTap;
  const _WowNav({required this.currentIndex, required this.onTap});

  @override
  State<_WowNav> createState() => _WowNavState();
}

class _WowNavState extends State<_WowNav> with TickerProviderStateMixin {
  late final List<AnimationController> _bounce;
  late final List<Animation<double>>   _scale;

  @override
  void initState() {
    super.initState();
    _bounce = List.generate(_items.length, (i) {
      return AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 260),
        value: i == widget.currentIndex ? 1.0 : 0.0,
      );
    });
    _scale = _bounce.map((c) =>
      Tween<double>(begin: 1.0, end: 1.22)
          .animate(CurvedAnimation(parent: c, curve: Curves.easeOutBack)),
    ).toList();
  }

  @override
  void didUpdateWidget(_WowNav old) {
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
    final bottom = MediaQuery.of(context).padding.bottom;
    return Container(
      margin: EdgeInsets.fromLTRB(14, 0, 14, bottom + 12),
      decoration: BoxDecoration(
        color: _kNavBg,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.11),
            blurRadius: 28, spreadRadius: 0,
            offset: const Offset(0, 5),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: SizedBox(
          height: 66,
          child: Row(
            children: List.generate(_items.length, (i) => Expanded(
              child: _Tile(
                item: _items[i],
                isActive: widget.currentIndex == i,
                scale: _scale[i],
                onTap: () => widget.onTap(i),
              ),
            )),
          ),
        ),
      ),
    );
  }
}

// ── Regular tile ──────────────────────────────────────────────────────────────
class _Tile extends StatelessWidget {
  final _Item item;
  final bool  isActive;
  final Animation<double> scale;
  final VoidCallback onTap;
  const _Tile({required this.item, required this.isActive,
      required this.scale, required this.onTap});

  @override
  Widget build(BuildContext context) {
    if (item.isSpecial) {
      return _CompostTile(isActive: isActive, scale: scale, onTap: onTap);
    }

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: ScaleTransition(
        scale: scale,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 230),
              curve: Curves.easeOutCubic,
              width:  isActive ? 42 : 30,
              height: isActive ? 34 : 30,
              decoration: isActive
                  ? BoxDecoration(
                      color: item.color.withValues(alpha: 0.13),
                      borderRadius: BorderRadius.circular(12),
                    )
                  : null,
              child: Center(
                child: Icon(
                  isActive ? item.activeIcon : item.icon,
                  size: 21,
                  color: isActive ? item.color : _kInactive,
                ),
              ),
            ),
            const SizedBox(height: 2),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 230),
              style: GoogleFonts.inter(
                fontSize: 9,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                color: isActive ? item.color : _kInactive,
              ),
              child: Text(item.label),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Special Compost tile with animated glow ───────────────────────────────────
class _CompostTile extends StatefulWidget {
  final bool isActive;
  final Animation<double> scale;
  final VoidCallback onTap;
  const _CompostTile(
      {required this.isActive, required this.scale, required this.onTap});

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
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() { _pulse.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: ScaleTransition(
        scale: widget.scale,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _pulse,
              builder: (_, child) => Container(
                width: 46,
                height: 38,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF047857), _kEmeraldGlow],
                  ),
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: _kEmeraldGlow.withValues(
                          alpha: widget.isActive
                              ? 0.38 + _pulse.value * 0.22
                              : 0.18 + _pulse.value * 0.10),
                      blurRadius:
                          widget.isActive ? 14 + _pulse.value * 8 : 8,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: child,
              ),
              child: const Center(
                child: Icon(Icons.eco_rounded,
                    color: Colors.white, size: 22),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Compost',
              style: GoogleFonts.inter(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: widget.isActive ? _kEmerald : const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
