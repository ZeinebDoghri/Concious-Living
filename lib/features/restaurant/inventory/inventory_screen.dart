import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/constants.dart';
import '../../../providers/inventory_provider.dart';
import '../../../shared/widgets/freshness_badge.dart';

// ── FreshGuard restaurant theme tokens ────────────────────────────────────────
const _rPrimary   = Color(0xFFF2A7A7);
const _rDeep      = Color(0xFFE47878);
const _rSurface   = Color(0xFFFFF5F5);
const _rSoftBg    = Color(0xFFFFE4E4);
const _rTextTitle = Color(0xFF3D1515);
const _rTextBody  = Color(0xFF7A4040);
const _rTextMuted = Color(0xFFB08080);
const _warning    = Color(0xFFFFAB5B);
const _warningBg  = Color(0xFFFFF4E8);

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final _search = TextEditingController();
  String _filter = 'all';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InventoryProvider>();
    final items = provider.filteredItems(query: _search.text, filter: _filter);

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
                  Row(
                    children: [
                      // ── Back button ────────────────────────────────────
                      GestureDetector(
                        onTap: () => GoRouter.of(context).go('/restaurant/dashboard'),
                        child: MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _rPrimary.withValues(alpha: 0.3),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: _rPrimary.withValues(alpha: 0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.arrow_back_ios_new,
                              color: _rDeep,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      // ── Title ──────────────────────────────────────────
                      Text(
                        '📦 ${AppStrings.inventory}',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: _rTextTitle,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (provider.needsAttentionCount > 0)
                    ScaleTransition(
                      scale: Tween<double>(begin: 0.8, end: 1).animate(
                        CurvedAnimation(
                          parent: ModalRoute.of(context)?.animation ?? AlwaysStoppedAnimation(1),
                          curve: Curves.elasticOut,
                        ),
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _warningBg,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: _warning.withValues(alpha: 0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          '⚠️ ${AppStrings.itemsNeedAttentionCount(provider.needsAttentionCount)}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _warning,
                          ),
                        ),
                      ),
                    )
                  else
                    Opacity(
                      opacity: 0.7,
                      child: Text(
                        '✅ ${AppStrings.itemsNeedAttentionCount(0)}',
                        style: GoogleFonts.inter(
                            fontSize: 13, color: _rTextMuted),
                      ),
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
                    const SizedBox(height: 14),
                    // Search bar
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: TextField(
                        controller: _search,
                        onChanged: (_) => setState(() {}),
                        style: GoogleFonts.inter(
                            fontSize: 14, color: _rTextTitle),
                        decoration: InputDecoration(
                          hintText: AppStrings.searchInventory,
                          hintStyle: GoogleFonts.inter(
                              fontSize: 13, color: _rTextMuted),
                          prefixIcon:
                              Icon(Icons.search, color: _rTextMuted, size: 20),
                          filled: true,
                          fillColor: _rSurface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                                color: _rPrimary.withValues(alpha: 0.3)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                                color: _rPrimary.withValues(alpha: 0.3)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                                color: _rPrimary, width: 1.5),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Filter chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          _FilterTab(
                            emoji: '🔹',
                            label: AppStrings.all,
                            selected: _filter == 'all',
                            onTap: () => setState(() => _filter = 'all'),
                          ),
                          const SizedBox(width: 8),
                          _FilterTab(
                            emoji: '🟢',
                            label: AppStrings.fresh,
                            selected: _filter == 'fresh',
                            onTap: () => setState(() => _filter = 'fresh'),
                          ),
                          const SizedBox(width: 8),
                          _FilterTab(
                            emoji: '⏰',
                            label: AppStrings.expiringSoon,
                            selected: _filter == 'expiring',
                            onTap: () =>
                                setState(() => _filter = 'expiring'),
                          ),
                          const SizedBox(width: 8),
                          _FilterTab(
                            emoji: '❌',
                            label: AppStrings.spoiled,
                            selected: _filter == 'spoiled',
                            onTap: () => setState(() => _filter = 'spoiled'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: items.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ScaleTransition(
                                    scale: Tween<double>(begin: 0.5, end: 1).animate(
                                      CurvedAnimation(
                                        parent: ModalRoute.of(context)?.animation ?? AlwaysStoppedAnimation(1),
                                        curve: Curves.elasticOut,
                                      ),
                                    ),
                                    child: const Text(
                                      '📭',
                                      style: TextStyle(fontSize: 56),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Aucun article trouvé',
                                    style: GoogleFonts.playfairDisplay(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: _rTextTitle,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Scannez des produits pour commencer',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: _rTextMuted,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(
                                  20, 4, 20, 24),
                              itemCount: items.length,
                              itemBuilder: (context, index) {
                                final it = items[index];
                                final date = DateFormat('MMM d')
                                    .format(it.expiryDate);
                                final emoji = _statusEmoji(it.status);

                                return TweenAnimationBuilder<double>(
                                  tween: Tween(begin: 0, end: 1),
                                  duration: Duration(
                                      milliseconds: 240 + (index * 35)),
                                  curve: Curves.easeOutCubic,
                                  builder: (context, v, child) {
                                    return Opacity(
                                      opacity: v,
                                      child: Transform.translate(
                                        offset:
                                            Offset(0, (1 - v) * 10),
                                        child: child,
                                      ),
                                    );
                                  },
                                  child: GestureDetector(
                                    onTap: () => context.go(AppRoutes
                                        .restaurantInventoryItem(it.id)),
                                    child: MouseRegion(
                                      cursor: SystemMouseCursors.click,
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 200),
                                        margin: const EdgeInsets.only(
                                            bottom: 12),
                                        padding: const EdgeInsets.all(14),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          border: Border.all(
                                            color: _rPrimary
                                                .withValues(alpha: 0.2),
                                            width: 0.8,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: _rPrimary
                                                  .withValues(alpha: 0.08),
                                              blurRadius: 12,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          children: [
                                            // ── Emoji icon ─────────────────────
                                            Container(
                                              width: 40,
                                              height: 40,
                                              decoration: BoxDecoration(
                                                color: _getStatusColor(it.status)
                                                    .withValues(alpha: 0.12),
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                              child: Center(
                                                child: Text(
                                                  emoji,
                                                  style: const TextStyle(
                                                      fontSize: 20),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    it.name,
                                                    style: GoogleFonts.inter(
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      color: _rTextTitle,
                                                      height: 1.2,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    '${it.quantity.toStringAsFixed(it.quantity % 1 == 0 ? 0 : 1)} ${it.unit} · ${AppStrings.expiresOn(date)}',
                                                    style: GoogleFonts.inter(
                                                      fontSize: 12,
                                                      color: _rTextBody,
                                                      height: 1.2,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            FreshnessBadge(it.status),
                                            const SizedBox(width: 8),
                                            Icon(Icons.chevron_right,
                                                color: _rTextMuted),
                                          ],
                                        ),
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
  final String emoji;
  final bool selected;
  final VoidCallback onTap;

  const _FilterTab({
    required this.label,
    required this.emoji,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? _rSoftBg : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected
                  ? _rPrimary.withValues(alpha: 0.5)
                  : _rPrimary.withValues(alpha: 0.2),
              width: selected ? 1.5 : 1.0,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: _rPrimary.withValues(alpha: 0.12),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                emoji,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  color: selected ? _rDeep : _rTextMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Helper functions ──────────────────────────────────────────────────────────

String _statusEmoji(String status) {
  switch (status.toLowerCase()) {
    case 'fresh':
      return '🥒';
    case 'expiring':
      return '⏳';
    case 'spoiled':
      return '🚫';
    default:
      return '📦';
  }
}

Color _getStatusColor(String status) {
  switch (status.toLowerCase()) {
    case 'fresh':
      return const Color(0xFF52C98A);
    case 'expiring':
      return const Color(0xFFFFAB5B);
    case 'spoiled':
      return const Color(0xFFFF7070);
    default:
      return const Color(0xFFE47878);
  }
}
