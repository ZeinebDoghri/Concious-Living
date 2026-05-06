import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/constants.dart';
import '../../../providers/alerts_provider.dart';

// ── Brand palette (mirrors dashboard) ─────────────────────────────────────────
const _kCherry        = Color(0xFF75070C);
const _kOlive         = Color(0xFF4F6815);
const _kAmber         = Color(0xFFE8C84A);
const _kSurface       = Color(0xFFEDE0D3);
const _kCard          = Color(0xFFFAF5EE);
const _kBorder        = Color(0xFFD9C9B4);
const _kSlate         = Color(0xFF8C7B7C);
const _kTextPrimary   = Color(0xFF2C1A1B);
const _kTextSecondary = Color(0xFF5C3D3F);

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen>
    with SingleTickerProviderStateMixin {
  String _filter = 'pending';
  late final AnimationController _enterController;

  @override
  void initState() {
    super.initState();
    _enterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
  }

  @override
  void dispose() {
    _enterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AlertsProvider>();
    final items    = provider.filterByStatus(_filter);
    final pending  = provider.pendingCount;

    return Scaffold(
      backgroundColor: _kSurface,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [

          // ── Gradient header ──────────────────────────────────────────────
          SliverPersistentHeader(
            pinned: false,
            delegate: _AlertsHeaderDelegate(
              minH: 0,
              maxH: 180,
              pending: pending,
            ),
          ),

          SliverToBoxAdapter(
            child: Transform.translate(
              offset: const Offset(0, -28),
              child: Container(
                decoration: const BoxDecoration(
                  color: _kSurface,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    const SizedBox(height: 20),

                    // ── Filter chips ───────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          _FilterChip(
                            label: 'Pending',
                            count: pending,
                            selected: _filter == 'pending',
                            activeColor: _kCherry,
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() => _filter = 'pending');
                            },
                          ),
                          const SizedBox(width: 10),
                          _FilterChip(
                            label: 'Resolved',
                            count: provider.alerts
                                .where((a) => a.status == 'resolved')
                                .length,
                            selected: _filter == 'resolved',
                            activeColor: _kOlive,
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() => _filter = 'resolved');
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Alert list ─────────────────────────────────────────
                    items.isEmpty
                        ? _EmptyState(filter: _filter)
                            .animate()
                            .fadeIn(delay: 200.ms)
                            .slideY(begin: 0.08, end: 0)
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                            itemCount: items.length,
                            itemBuilder: (context, index) {
                              final a = items[index];
                              return _AlertTile(
                                alert: a,
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  context.go(
                                    AppRoutes.restaurantAlertDetail(a.id),
                                  );
                                },
                              )
                                  .animate()
                                  .fadeIn(
                                    delay: Duration(
                                        milliseconds: 100 + index * 60),
                                    duration: 400.ms,
                                  )
                                  .slideY(
                                    begin: 0.08,
                                    end: 0,
                                    delay: Duration(
                                        milliseconds: 100 + index * 60),
                                    duration: 400.ms,
                                    curve: Curves.easeOutCubic,
                                  );
                            },
                          ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Header delegate ────────────────────────────────────────────────────────────
class _AlertsHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double minH;
  final double maxH;
  final int pending;

  const _AlertsHeaderDelegate({
    required this.minH,
    required this.maxH,
    required this.pending,
  });

  @override
  double get minExtent => minH;
  @override
  double get maxExtent => maxH;

  @override
  Widget build(BuildContext ctx, double shrinkOffset, bool overlapsContent) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0A1628), Color(0xFF0D2137), Color(0xFF00695C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Decorative circles
          Positioned(
            top: -40,
            right: -40,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.04),
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            left: -30,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.03),
              ),
            ),
          ),

          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Allergen Alerts',
                              style: GoogleFonts.sora(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              pending > 0
                                  ? '$pending unresolved alert${pending == 1 ? '' : 's'}'
                                  : 'All clear — no pending alerts',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.55),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Alert count badge
                      if (pending > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: _kCherry.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _kCherry.withValues(alpha: 0.5),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.notifications_active_rounded,
                                color: Colors.white,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '$pending',
                                style: GoogleFonts.sora(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Status pills
                  Row(
                    children: [
                      _HeaderStat(
                        label: '🚨 $pending pending',
                        color: pending > 0
                            ? Colors.red.withValues(alpha: 0.3)
                            : Colors.white.withValues(alpha: 0.10),
                      ),
                      const SizedBox(width: 8),
                      _HeaderStat(
                        label: '✓ Staff notified',
                        color: Colors.white.withValues(alpha: 0.10),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(_AlertsHeaderDelegate old) =>
      old.pending != pending;
}

class _HeaderStat extends StatelessWidget {
  final String label;
  final Color color;
  const _HeaderStat({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
      ),
    );
  }
}

// ── Filter chip ────────────────────────────────────────────────────────────────
class _FilterChip extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final Color activeColor;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? activeColor : _kCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? activeColor : _kBorder,
            width: selected ? 1.5 : 0.8,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: activeColor.withValues(alpha: 0.20),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : _kSlate,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: selected
                    ? Colors.white.withValues(alpha: 0.25)
                    : _kBorder.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$count',
                style: GoogleFonts.sora(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : _kSlate,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Alert tile ─────────────────────────────────────────────────────────────────
class _AlertTile extends StatelessWidget {
  final dynamic alert;
  final VoidCallback onTap;
  const _AlertTile({required this.alert, required this.onTap});

  String _timeAgo() {
    final d = DateTime.now().difference(alert.timestamp as DateTime);
    if (d.inSeconds < 45) return 'Just now';
    if (d.inMinutes < 60) return '${d.inMinutes}min ago';
    if (d.inHours < 24) return '${d.inHours}h ago';
    return DateFormat('dd MMM').format(alert.timestamp as DateTime);
  }

  String _initials() {
    final parts =
        (alert.customerName as String).trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    final a = parts.first.isEmpty ? '?' : parts.first[0].toUpperCase();
    final b = parts.length > 1 && parts[1].isNotEmpty
        ? parts[1][0].toUpperCase()
        : '';
    return a + b;
  }

  @override
  Widget build(BuildContext context) {
    final isPending  = (alert.status as String) == 'pending';
    final accent     = isPending ? _kCherry : _kOlive;
    final accentMist = isPending
        ? const Color(0xFFFFF0F0)
        : const Color(0xFFF0F5EC);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(18),
          border: Border(
            left: BorderSide(color: accent, width: 3),
            top: BorderSide(color: _kBorder, width: 0.5),
            right: BorderSide(color: _kBorder, width: 0.5),
            bottom: BorderSide(color: _kBorder, width: 0.5),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              CircleAvatar(
                radius: 22,
                backgroundColor: accent.withValues(alpha: 0.15),
                child: Text(
                  _initials(),
                  style: GoogleFonts.sora(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: accent,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Customer + time
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            alert.customerName as String,
                            style: GoogleFonts.sora(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: _kTextPrimary,
                            ),
                          ),
                        ),
                        Text(
                          _timeAgo(),
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: _kSlate,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),

                    // Dish name
                    Text(
                      alert.dishName as String,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: _kTextSecondary,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Allergen chip + status badge
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            color: accentMist,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: accent.withValues(alpha: 0.25),
                              width: 0.8,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                size: 12,
                                color: accent,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                alert.allergen as String,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: accent,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isPending ? 'Pending' : 'Resolved',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: accent,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: _kSlate,
                          size: 18,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Empty state ────────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final String filter;
  const _EmptyState({required this.filter});

  @override
  Widget build(BuildContext context) {
    final isPending = filter == 'pending';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 32),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: isPending
                  ? _kCherry.withValues(alpha: 0.08)
                  : _kOlive.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isPending
                  ? Icons.notifications_off_outlined
                  : Icons.check_circle_outline_rounded,
              size: 34,
              color: isPending ? _kCherry : _kOlive,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isPending ? 'No pending alerts' : 'No resolved alerts yet',
            style: GoogleFonts.sora(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _kTextPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isPending
                ? 'All clear — your team is on top of it.'
                : 'Resolved alerts will appear here.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: _kSlate,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}