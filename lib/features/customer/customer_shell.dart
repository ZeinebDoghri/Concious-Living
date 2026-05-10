import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../providers/venue_type_provider.dart';
import '../../shared/animations/role_animated_background.dart';

// ── Customer design tokens ─────────────────────────────────────────────────────
const _kPrimary = Color(0xFFD9899F);
const _kTextMuted = Color(0xFF8C7E78);
const _kSoftBg = Color(0xFFF9E9F2);

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
  _Item(Icons.history_rounded, Icons.history_rounded, 'History'),
  _Item(Icons.shield_outlined, Icons.shield_rounded, 'Allergens'),
  _Item(Icons.person_outline_rounded, Icons.person_rounded, 'Profile'),
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final venueType = context.read<VenueTypeProvider>();
      if (venueType.venueType.isNotEmpty) {
        venueType.clear();
      }
    });
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

    return Scaffold(
      backgroundColor: const Color(0xFFFEFAFC),
      extendBody: true,
      body: RoleAnimatedBackground(
        role: AmbientRole.customer,
        activeIndex: index,
        intensity: 1.65,
        child: widget.navigationShell,
      ),
      bottomNavigationBar: _PastelNav(currentIndex: index, onTap: _onTap),
    );
  }
}

// ── Pastel nav bar ─────────────────────────────────────────────────────────────
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
        boxShadow: AppShadows.sm(_kPrimary),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: List.generate(_items.length, (i) {
              final item = _items[i];
              final isActive = currentIndex == i;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isActive ? _kSoftBg : Colors.transparent,
                      borderRadius: BorderRadius.circular(AppRadii.md),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isActive ? item.iconOn : item.iconOff,
                          color: isActive ? _kPrimary : _kTextMuted,
                          size: 22,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          item.label,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: isActive
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: isActive ? _kPrimary : _kTextMuted,
                          ),
                        ),
                      ],
                    ),
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
