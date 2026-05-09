import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/constants.dart';
import '../../../providers/alerts_provider.dart';

// ── FreshGuard restaurant theme tokens ────────────────────────────────────────
const _rPrimary   = Color(0xFFF2A7A7);
const _rDeep      = Color(0xFFE47878);
const _rSurface   = Color(0xFFFFF5F5);
const _rSoftBg    = Color(0xFFFFE4E4);
const _rTextTitle = Color(0xFF3D1515);
const _rTextBody  = Color(0xFF7A4040);
const _rTextMuted = Color(0xFFB08080);
const _danger     = Color(0xFFFF7070);
const _dangerBg   = Color(0xFFFFEEEE);
const _fresh      = Color(0xFF52C98A);
const _freshBg    = Color(0xFFE8F9F1);

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  String _filter = 'pending';

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AlertsProvider>();
    final items = provider.filterByStatus(_filter);

    return Scaffold(
      backgroundColor: _rSurface,
      body: SafeArea(
        child: Column(
          children: [
            // ── Pastel header ─────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_rSoftBg, _rSurface],
                ),
                border: Border(
                  bottom: BorderSide(
                      color: _rPrimary.withValues(alpha: 0.2)),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.alerts,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: _rTextTitle,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: provider.pendingCount > 0
                              ? _dangerBg
                              : _freshBg,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          AppStrings.unresolvedCount(provider.pendingCount),
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: provider.pendingCount > 0
                                ? _danger
                                : _fresh,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    // Filter tabs
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          _FilterTab(
                            label: AppStrings.pending,
                            selected: _filter == 'pending',
                            onTap: () =>
                                setState(() => _filter = 'pending'),
                          ),
                          const SizedBox(width: 10),
                          _FilterTab(
                            label: AppStrings.resolved,
                            selected: _filter == 'resolved',
                            onTap: () =>
                                setState(() => _filter = 'resolved'),
                          ),
                          const Spacer(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: items.isEmpty
                          ? _EmptyAlerts(filter: _filter)
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                              itemCount: items.length,
                              itemBuilder: (context, index) {
                                final a = items[index];
                                return TweenAnimationBuilder<double>(
                                  tween: Tween(begin: 0, end: 1),
                                  duration: Duration(
                                      milliseconds: 250 + (index * 35)),
                                  curve: Curves.easeOutCubic,
                                  builder: (context, v, child) {
                                    return Opacity(
                                      opacity: v,
                                      child: Transform.translate(
                                        offset: Offset(0, (1 - v) * 10),
                                        child: child,
                                      ),
                                    );
                                  },
                                  child: GestureDetector(
                                    onTap: () => context.go(
                                        AppRoutes.restaurantAlertDetail(
                                            a.id)),
                                    child: Container(
                                      margin:
                                          const EdgeInsets.only(bottom: 12),
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius:
                                            BorderRadius.circular(16),
                                        border: Border.all(
                                          color: a.status == 'pending'
                                              ? _rPrimary
                                                  .withValues(alpha: 0.3)
                                              : _fresh
                                                  .withValues(alpha: 0.3),
                                          width: 0.8,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: _rPrimary
                                                .withValues(alpha: 0.06),
                                            blurRadius: 10,
                                            offset: const Offset(0, 3),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // Status icon
                                          Container(
                                            width: 38,
                                            height: 38,
                                            decoration: BoxDecoration(
                                              color: a.status == 'pending'
                                                  ? _dangerBg
                                                  : _freshBg,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Icon(
                                              a.status == 'pending'
                                                  ? Icons
                                                      .warning_amber_rounded
                                                  : Icons.check_circle_rounded,
                                              color: a.status == 'pending'
                                                  ? _danger
                                                  : _fresh,
                                              size: 20,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  a.dishName,
                                                  style: GoogleFonts.inter(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w700,
                                                    color: _rTextTitle,
                                                    height: 1.2,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  a.customerName,
                                                  style: GoogleFonts.inter(
                                                    fontSize: 12,
                                                    color: _rTextBody,
                                                    height: 1.2,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                          horizontal: 8,
                                                          vertical: 3),
                                                  decoration: BoxDecoration(
                                                    color: _dangerBg,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                  ),
                                                  child: Text(
                                                    AppStrings.containsAllergen(
                                                        a.allergen),
                                                    style: GoogleFonts.inter(
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: _danger,
                                                      height: 1.2,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Icon(Icons.chevron_right,
                                              color: _rTextMuted),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? _rSoftBg : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? _rPrimary.withValues(alpha: 0.5)
                : _rPrimary.withValues(alpha: 0.2),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? _rDeep : _rTextMuted,
          ),
        ),
      ),
    );
  }
}

class _EmptyAlerts extends StatelessWidget {
  final String filter;
  const _EmptyAlerts({required this.filter});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: _rSoftBg,
              shape: BoxShape.circle,
            ),
            child: Icon(
              filter == 'pending'
                  ? Icons.notifications_off_outlined
                  : Icons.check_circle_outline_rounded,
              size: 36,
              color: _rPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            filter == 'pending'
                ? 'Aucune alerte en attente'
                : 'Aucune alerte résolue',
            style: GoogleFonts.playfairDisplay(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _rTextTitle,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            filter == 'pending'
                ? 'Tout est sous contrôle !'
                : 'Les alertes résolues apparaîtront ici.',
            style: GoogleFonts.inter(fontSize: 13, color: _rTextMuted),
          ),
        ],
      ),
    );
  }
}
