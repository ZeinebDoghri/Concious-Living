import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/constants.dart';
import '../../../core/models/alert_model.dart';
import '../../../providers/alerts_provider.dart';
import '../../../providers/inventory_provider.dart';
import '../../../providers/scan_history_provider.dart';
import '../../../providers/user_provider.dart';
import '../../../providers/venue_type_provider.dart';

// ── FreshGuard restaurant pastel tokens ───────────────────────────────────────
const _rPrimary = Color(0xFFF2A7A7);
const _rDeep = Color(0xFFE47878);
const _rSurface = Color(0xFFFFF5F5);
const _rSoftBg = Color(0xFFFFE4E4);
const _rTextTitle = Color(0xFF3D1515);
const _rTextBody = Color(0xFF7A4040);
const _rTextMuted = Color(0xFFB08080);

const _fresh = Color(0xFF52C98A);
const _warning = Color(0xFFFFAB5B);
const _danger = Color(0xFFFF7070);

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _enterController;
  int? _touchedBarIndex;

  @override
  void initState() {
    super.initState();
    _enterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();
  }

  @override
  void dispose() {
    _enterController.dispose();
    super.dispose();
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 18) return 'Good afternoon';
    return 'Good evening';
  }

  String _serviceLabel() {
    final h = DateTime.now().hour;
    if (h < 11) return 'Breakfast service';
    if (h < 15) return 'Lunch service';
    if (h < 18) return 'Afternoon service';
    return 'Dinner service';
  }

  String _venueName(UserProvider u, bool isHotel) {
    final n = isHotel
        ? u.currentUser?.hotelName
        : u.currentUser?.restaurantName;
    final t = (n ?? '').trim();
    return t.isEmpty ? AppStrings.appName : t;
  }

  String _venueSubtitle(UserProvider u, bool isHotel) {
    if (isHotel) {
      final cat = (u.currentUser?.hotelType ?? '').trim();
      final rooms = u.currentUser?.rooms ?? 0;
      return '${cat.isEmpty ? 'Hotel' : cat} - $rooms rooms';
    }
    final cuisine = (u.currentUser?.cuisineType ?? '').trim();
    final covers = u.currentUser?.covers ?? 0;
    return '${cuisine.isEmpty ? 'Restaurant' : cuisine} - $covers seats';
  }

  int _expiringSoon(InventoryProvider p) =>
      p.items.where((i) => i.isExpiringSoon).length;

  int _wasteEst(int alerts, int expiring, int scans) =>
      max(1, alerts * 2 + expiring * 3 + max(2, scans ~/ 2));

  double _freshnessScore(int alerts, int expiring) =>
      (100 - min(24, alerts * 3 + expiring * 2)).clamp(0, 100).toDouble();

  List<double> _wasteSeries(int alerts, int expiring, int scans, bool isHotel) {
    final base = max(4, alerts + expiring + max(2, scans ~/ 3));
    return List.generate(5, (i) {
      final wobble = isHotel ? [1, -1, 2, 0, 1][i] : [0, 2, -1, 1, -1][i];
      return max(2, base + i + wobble).toDouble();
    });
  }

  List<AlertModel> _recentAlerts(AlertsProvider p) {
    final list = p.alerts.toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return list.take(3).toList();
  }

  List<_Tip> _tips(bool isHotel) => isHotel
      ? [
          _Tip(
            'Serve smaller batches',
            'Reduce buffet waste with smaller, more frequent refills.',
          ),
          _Tip(
            'Confirm allergens',
            'Check guest dietary restrictions at arrival.',
          ),
          _Tip(
            'Holding temperatures',
            'Check twice to keep food safety under control.',
          ),
        ]
      : [
          _Tip(
            'Use FIFO now',
            'Move older stock to the front so it is used first.',
          ),
          _Tip(
            'Label allergens',
            'A quick prep label helps prevent cross-contact.',
          ),
          _Tip(
            'Keep portions consistent',
            'Predictable portions make scan comparisons easier.',
          ),
        ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _rSurface,
      body: Consumer<VenueTypeProvider>(
        builder: (ctx, venueP, _) {
          final isHotel = venueP.venueType == 'hotel';
          final alertsP = ctx.watch<AlertsProvider>();
          final invP = ctx.watch<InventoryProvider>();
          final userP = ctx.watch<UserProvider>();
          final scanP = ctx.watch<ScanHistoryProvider>();

          final name = _venueName(userP, isHotel);
          final subtitle = _venueSubtitle(userP, isHotel);
          final pending = alertsP.pendingCount;
          final expiring = _expiringSoon(invP);
          final scans = scanP.items.length;
          final wasteKg = _wasteEst(pending, expiring, scans);
          final freshness = _freshnessScore(pending, expiring).round();
          final series = _wasteSeries(pending, expiring, scans, isHotel);
          final recentA = _recentAlerts(alertsP);
          final tips = _tips(isHotel);
          final tip = tips[DateTime.now().day % tips.length];

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── Pastel header ──────────────────────────────────────────────
              SliverToBoxAdapter(
                child: _Header(
                  greeting: _greeting(),
                  name: name,
                  subtitle: subtitle,
                  serviceChip: _serviceLabel(),
                  pendingAlerts: pending,
                  wasteKg: wasteKg,
                  user: userP.currentUser,
                  isHotel: isHotel,
                ),
              ),

              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Mini stat row ──────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                      child: Row(
                        children: [
                          _MiniStatCard(
                            label: 'Alerts',
                            value: '$pending',
                            color: _danger,
                            icon: Icons.warning_amber_rounded,
                          ),
                          const SizedBox(width: 10),
                          _MiniStatCard(
                            label: 'Expiring',
                            value: '$expiring',
                            color: _warning,
                            icon: Icons.inventory_2_rounded,
                          ),
                          const SizedBox(width: 10),
                          _MiniStatCard(
                            label: 'Freshness',
                            value: '$freshness%',
                            color: _fresh,
                            icon: Icons.eco_rounded,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Alert banner ───────────────────────────────────────
                    if (pending > 0)
                      _AlertBanner(
                            count: pending,
                            onTap: () {
                              HapticFeedback.selectionClick();
                              context.go(AppRoutes.restaurantAlerts);
                            },
                          )
                          .animate()
                          .fadeIn(delay: 200.ms)
                          .slideY(begin: 0.1, end: 0),

                    // ── Quick actions ──────────────────────────────────────
                    _SectionHeader(title: 'Quick Actions'),
                    _QuickActions(isHotel: isHotel),

                    // ── Scan CTA ───────────────────────────────────────────
                    _ScanCard(
                          onTap: () {
                            HapticFeedback.mediumImpact();
                            context.go(AppRoutes.restaurantScan);
                          },
                        )
                        .animate()
                        .fadeIn(delay: 300.ms)
                        .slideY(begin: 0.08, end: 0),

                    // ── Waste chart ────────────────────────────────────────
                    _SectionHeader(title: 'Waste This Week'),
                    _WasteCard(
                      series: series,
                      touchedIndex: _touchedBarIndex,
                      onTouch: (i) => setState(() => _touchedBarIndex = i),
                      isHotel: isHotel,
                    ).animate().fadeIn(delay: 400.ms),

                    // ── Inventory banner ───────────────────────────────────
                    if (expiring > 0)
                      _InventoryBanner(
                        count: expiring,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          context.go(AppRoutes.restaurantInventory);
                        },
                      ).animate().fadeIn(delay: 450.ms),

                    // ── Daily tip ──────────────────────────────────────────
                    _SectionHeader(title: 'Daily Tip'),
                    _TipCard(tip: tip).animate().fadeIn(delay: 500.ms),

                    // ── Recent alerts ──────────────────────────────────────
                    if (recentA.isNotEmpty) ...[
                      _SectionHeader(
                        title: 'Recent Alerts',
                        action: 'View All',
                        onAction: () => context.go(AppRoutes.restaurantAlerts),
                      ),
                      ...recentA.asMap().entries.map(
                        (e) =>
                            _AlertRow(
                                  alert: e.value,
                                  onTap: () => context.go(
                                    AppRoutes.restaurantAlertDetail(e.value.id),
                                  ),
                                )
                                .animate()
                                .fadeIn(
                                  delay: Duration(
                                    milliseconds: 550 + e.key * 70,
                                  ),
                                )
                                .slideY(begin: 0.06, end: 0),
                      ),
                    ],

                    const SizedBox(height: 120),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Pastel header ──────────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  final String greeting;
  final String name;
  final String subtitle;
  final String serviceChip;
  final int pendingAlerts;
  final int wasteKg;
  final dynamic user;
  final bool isHotel;

  const _Header({
    required this.greeting,
    required this.name,
    required this.subtitle,
    required this.serviceChip,
    required this.pendingAlerts,
    required this.wasteKg,
    required this.user,
    required this.isHotel,
  });

  String _initials() {
    final n = (isHotel ? user?.hotelName : user?.restaurantName) ?? '';
    final parts = n.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    final a = parts.first.substring(0, 1).toUpperCase();
    final b = parts.length > 1 ? parts[1].substring(0, 1).toUpperCase() : '';
    return a + b;
  }

  @override
  Widget build(BuildContext context) {
    final logoUrl = (user?.avatarPath ?? '').toString().trim();
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFE4E4), Color(0xFFFFF5F5)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
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
                          greeting,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: _rTextMuted,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          name,
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: _rTextTitle,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: _rTextMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _rSoftBg,
                      border: Border.all(color: _rPrimary, width: 2),
                    ),
                    child: logoUrl.isNotEmpty
                        ? ClipOval(
                            child: Image.network(
                              logoUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  _initText(),
                            ),
                          )
                        : _initText(),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _HeaderChip(label: serviceChip, bg: _rSoftBg, fg: _rDeep),
                  const SizedBox(width: 8),
                  _HeaderChip(
                    label: '$pendingAlerts alerts',
                    bg: pendingAlerts > 0
                        ? _danger.withValues(alpha: 0.12)
                        : _rSoftBg,
                    fg: pendingAlerts > 0 ? _danger : _rTextMuted,
                  ),
                  const SizedBox(width: 8),
                  _HeaderChip(
                    label: '♻️ ${wasteKg}kg',
                    bg: _rSoftBg,
                    fg: _rTextBody,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _initText() => Center(
    child: Text(
      _initials(),
      style: GoogleFonts.playfairDisplay(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: _rDeep,
      ),
    ),
  );
}

class _HeaderChip extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;
  const _HeaderChip({required this.label, required this.bg, required this.fg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: fg,
        ),
      ),
    );
  }
}

// ── Section header ─────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;

  const _SectionHeader({required this.title, this.action, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Row(
        children: [
          Text(
            title,
            style: GoogleFonts.playfairDisplay(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _rTextTitle,
            ),
          ),
          const Spacer(),
          if (action != null)
            GestureDetector(
              onTap: onAction,
              child: Text(
                action!,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _rDeep,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Mini stat cards ────────────────────────────────────────────────────────────
class _MiniStatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _MiniStatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.10),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: GoogleFonts.playfairDisplay(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: color,
                height: 1.0,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.inter(fontSize: 10, color: _rTextMuted),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Alert banner ───────────────────────────────────────────────────────────────
class _AlertBanner extends StatelessWidget {
  final int count;
  final VoidCallback onTap;
  const _AlertBanner({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _danger.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _danger.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _danger.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.notifications_active_rounded,
                color: _danger,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$count$count alert${count == 1 ? '' : 's'} need your attention',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _danger,
                    ),
                  ),
                  Text(
                    'Tap to review and resolve',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: _danger.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: _danger, size: 20),
          ],
        ),
      ),
    );
  }
}

// ── Quick actions ──────────────────────────────────────────────────────────────
class _QA {
  final IconData icon;
  final Color color;
  final String label;
  final String route;
  const _QA({
    required this.icon,
    required this.color,
    required this.label,
    required this.route,
  });
}

class _QuickActions extends StatelessWidget {
  final bool isHotel;
  const _QuickActions({required this.isHotel});

  @override
  Widget build(BuildContext context) {
    final actions = [
      _QA(
        icon: Icons.document_scanner_rounded,
        color: _rPrimary,
        label: 'Scanner',
        route: AppRoutes.restaurantScan,
      ),
      _QA(
        icon: Icons.notifications_rounded,
        color: _warning,
        label: 'Alerts',
        route: AppRoutes.restaurantAlerts,
      ),
      _QA(
        icon: Icons.event_available_rounded,
        color: _danger,
        label: 'Expiry',
        route: AppRoutes.restaurantExpiryDate,
      ),
      _QA(
        icon: Icons.delete_outline_rounded,
        color: _rTextMuted,
        label: 'Waste',
        route: AppRoutes.restaurantWaste,
      ),
      _QA(
        icon: Icons.recycling_rounded,
        color: _fresh,
        label: 'Compost',
        route: AppRoutes.restaurantCompost,
      ),
      _QA(
        icon: Icons.inventory_2_rounded,
        color: _rDeep,
        label: 'Stocks',
        route: AppRoutes.restaurantInventory,
      ),
    ];

    return SizedBox(
      height: 88,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: actions.length,
        separatorBuilder: (context, index) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final a = actions[i];
          return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  context.go(a.route);
                },
                child: Container(
                  width: 72,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: a.color.withValues(alpha: 0.10),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: a.color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(a.icon, color: a.color, size: 20),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        a.label,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: _rTextBody,
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .animate()
              .fadeIn(
                delay: Duration(milliseconds: 180 + i * 50),
                duration: 350.ms,
              )
              .slideX(
                begin: 0.1,
                end: 0,
                delay: Duration(milliseconds: 180 + i * 50),
                duration: 350.ms,
              );
        },
      ),
    );
  }
}

// ── Scan CTA card ──────────────────────────────────────────────────────────────
class _ScanCard extends StatefulWidget {
  final VoidCallback onTap;
  const _ScanCard({required this.onTap});

  @override
  State<_ScanCard> createState() => _ScanCardState();
}

class _ScanCardState extends State<_ScanCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (_, child) => Container(
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFF2A7A7), Color(0xFFE47878)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: _rPrimary.withValues(alpha: 0.30 + _pulse.value * 0.15),
                blurRadius: 24 + _pulse.value * 8,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.document_scanner_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '3 ANALYSES IN 1 SCAN',
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Freshness · Compost · Waste',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Simultaneous AI - Result in 2 seconds',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_forward_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Waste chart card ───────────────────────────────────────────────────────────
class _WasteCard extends StatelessWidget {
  final List<double> series;
  final int? touchedIndex;
  final ValueChanged<int?> onTouch;
  final bool isHotel;

  const _WasteCard({
    required this.series,
    required this.touchedIndex,
    required this.onTouch,
    required this.isHotel,
  });

  @override
  Widget build(BuildContext context) {
    final maxV = series.isEmpty ? 10.0 : series.reduce(max) + 2;
    const days = ['L', 'M', 'M', 'J', 'V'];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _rPrimary.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 130,
            child: BarChart(
              BarChartData(
                maxY: maxV,
                alignment: BarChartAlignment.spaceAround,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 4,
                  getDrawingHorizontalLine: (_) =>
                      FlLine(color: _rSoftBg, strokeWidth: 0.8),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) => Text(
                        days[v.toInt().clamp(0, 4)],
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: _rTextMuted,
                        ),
                      ),
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: series.asMap().entries.map((e) {
                  final active = e.key == touchedIndex;
                  return BarChartGroupData(
                    x: e.key,
                    barRods: [
                      BarChartRodData(
                        toY: e.value,
                        width: 18,
                        borderRadius: BorderRadius.circular(6),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: active
                              ? [_rDeep, _rPrimary]
                              : [_rPrimary.withValues(alpha: 0.6), _rSoftBg],
                        ),
                      ),
                    ],
                  );
                }).toList(),
                barTouchData: BarTouchData(
                  enabled: true,
                  touchCallback: (event, response) =>
                      onTouch(response?.spot?.touchedBarGroupIndex),
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) =>
                        BarTooltipItem(
                          '${rod.toY.toStringAsFixed(1)} kg',
                          GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                    tooltipRoundedRadius: 8,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _Pill(
                text: 'Down 8% vs week',
                bg: _fresh.withValues(alpha: 0.10),
                color: _fresh,
              ),
              const SizedBox(width: 8),
              _Pill(
                text: '${isHotel ? 'Buffet' : 'Bread'} - top waste',
                bg: _danger.withValues(alpha: 0.08),
                color: _danger,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;
  final Color bg;
  final Color color;
  const _Pill({required this.text, required this.bg, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ),
    );
  }
}

// ── Inventory banner ───────────────────────────────────────────────────────────
class _InventoryBanner extends StatelessWidget {
  final int count;
  final VoidCallback onTap;
  const _InventoryBanner({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _warning.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _warning.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _warning.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.inventory_2_outlined,
                color: _warning,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '$count$count item${count == 1 ? '' : 's'} expire within 3 days',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _warning,
                ),
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: _warning, size: 18),
          ],
        ),
      ),
    );
  }
}

// ── Tip card ───────────────────────────────────────────────────────────────────
class _Tip {
  final String title;
  final String body;
  const _Tip(this.title, this.body);
}

class _TipCard extends StatelessWidget {
  final _Tip tip;
  const _TipCard({required this.tip});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _rPrimary.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [_rPrimary, _rDeep],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lightbulb_outline_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: _rSoftBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'DAILY TIP',
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: _rDeep,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  tip.title,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _rTextTitle,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tip.body,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: _rTextBody,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Recent alert row ───────────────────────────────────────────────────────────
class _AlertRow extends StatelessWidget {
  final AlertModel alert;
  final VoidCallback onTap;
  const _AlertRow({required this.alert, required this.onTap});

  String _timeAgo() {
    final d = DateTime.now().difference(alert.timestamp);
    if (d.inSeconds < 45) return 'Just now';
    if (d.inMinutes < 60) return '${d.inMinutes}min';
    if (d.inHours < 24) return '${d.inHours}h';
    return DateFormat('dd MMM').format(alert.timestamp);
  }

  String _initials() {
    final parts = alert.customerName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    final a = parts.first.isEmpty ? '?' : parts.first[0].toUpperCase();
    final b = parts.length > 1 && parts[1].isNotEmpty
        ? parts[1][0].toUpperCase()
        : '';
    return a + b;
  }

  @override
  Widget build(BuildContext context) {
    final isResolved = alert.status == 'resolved';
    final color = isResolved ? _fresh : _danger;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _rSoftBg, width: 0.5),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: color.withValues(alpha: 0.15),
              child: Text(
                _initials(),
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    alert.customerName,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _rTextTitle,
                    ),
                  ),
                  Text(
                    '⚠ ${alert.allergen} · ${alert.dishName}',
                    style: GoogleFonts.inter(fontSize: 11, color: _danger),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _timeAgo(),
                  style: GoogleFonts.inter(fontSize: 10, color: _rTextMuted),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isResolved ? 'Resolved' : 'Open',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
