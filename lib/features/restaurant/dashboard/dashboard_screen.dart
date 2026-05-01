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
import '../../../core/venue_alert_service.dart';
import '../../../providers/alerts_provider.dart';
import '../../../providers/inventory_provider.dart';
import '../../../providers/scan_history_provider.dart';
import '../../../providers/user_provider.dart';
import '../../../providers/venue_type_provider.dart';

// ── Brand palette ─────────────────────────────────────────────────────────────
const _kCherry   = Color(0xFF75070C);   // Cherry
const _kOlive    = Color(0xFF4F6815);   // Olive
const _kAmber    = Color(0xFFE8C84A);   // Butter Deep
const _kIndigo   = Color(0xFF185FA5);   // Info Blue
const _kEmerald  = Color(0xFF4F6815);   // Olive = success
const _kSurface  = Color(0xFFEDE0D3);   // warm oat
const _kCard     = Color(0xFFFAF5EE);   // parchment
const _kBorder   = Color(0xFFD9C9B4);   // sand
const _kSlate    = Color(0xFF8C7B7C);   // fog
const _kTextPrimary   = Color(0xFF2C1A1B);   // espresso
const _kTextSecondary = Color(0xFF5C3D3F);   // cocoa

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

  // ── Utility helpers ──────────────────────────────────────────────────────────
  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning 👋';
    if (h < 18) return 'Good afternoon 👋';
    return 'Good evening 👋';
  }

  String _serviceLabel() {
    final h = DateTime.now().hour;
    if (h < 11) return '🥐 Breakfast';
    if (h < 15) return '🍽 Lunch';
    if (h < 18) return '☕ Afternoon';
    return '🌙 Dinner';
  }

  String _venueName(UserProvider u, bool isHotel) {
    final n = isHotel ? u.currentUser?.hotelName : u.currentUser?.restaurantName;
    final t = (n ?? '').trim();
    return t.isEmpty ? AppStrings.appName : t;
  }

  String _venueSubtitle(UserProvider u, bool isHotel) {
    if (isHotel) {
      final cat = (u.currentUser?.hotelType ?? '').trim();
      final rooms = u.currentUser?.rooms ?? 0;
      return '${cat.isEmpty ? 'Hotel' : cat} · $rooms rooms';
    }
    final cuisine = (u.currentUser?.cuisineType ?? '').trim();
    final covers = u.currentUser?.covers ?? 0;
    return '${cuisine.isEmpty ? 'Restaurant' : cuisine} · $covers covers';
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

  List<_Tip> _tips(bool isHotel) => isHotel ? [
    _Tip('Serve in small batches', 'Reduce buffet waste with fractional restocking.'),
    _Tip('Allergen confirmation', 'Verify guest dietary restrictions at check-in.'),
    _Tip('Holding temperatures', 'Double-check to maintain food safety standards.'),
  ] : [
    _Tip('FIFO now', 'Place older stock at the front to use it first.'),
    _Tip('Label allergens', 'A quick label at prep time prevents cross-contamination.'),
    _Tip('Consistent portions', 'Predictable portions make scan comparisons easier.'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kSurface,
      body: Consumer<VenueTypeProvider>(
        builder: (ctx, venueP, _) {
          final isHotel = venueP.venueType == 'hotel';
          final alertsP   = ctx.watch<AlertsProvider>();
          final invP      = ctx.watch<InventoryProvider>();
          final userP     = ctx.watch<UserProvider>();
          final scanP     = ctx.watch<ScanHistoryProvider>();

          final name      = _venueName(userP, isHotel);
          final subtitle  = _venueSubtitle(userP, isHotel);
          final pending   = alertsP.pendingCount;
          final expiring  = _expiringSoon(invP);
          final scans     = scanP.items.length;
          final wasteKg   = _wasteEst(pending, expiring, scans);
          final freshness = _freshnessScore(pending, expiring).round();
          final series    = _wasteSeries(pending, expiring, scans, isHotel);
          final recentA   = _recentAlerts(alertsP);
          final tips      = _tips(isHotel);
          final tip       = tips[DateTime.now().day % tips.length];

          final headerGradient = isHotel
              ? const LinearGradient(
                  colors: [Color(0xFF1A0A2E), Color(0xFF2D1B69), Color(0xFF11998E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : const LinearGradient(
                  colors: [Color(0xFF0A1628), Color(0xFF0D2137), Color(0xFF00695C)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                );

          final accentColor = isHotel ? const Color(0xFFB388FF) : _kOlive;

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── Premium gradient header ────────────────────────────────────
              SliverPersistentHeader(
                pinned: false,
                delegate: _HeaderDelegate(
                  minH: 0,
                  maxH: 220,
                  gradient: headerGradient,
                  greeting: _greeting(),
                  name: name,
                  subtitle: subtitle,
                  serviceChip: _serviceLabel(),
                  pendingAlerts: pending,
                  wasteKg: wasteKg,
                  expiring: expiring,
                  isHotel: isHotel,
                  user: userP.currentUser,
                ),
              ),

              SliverToBoxAdapter(
                child: Transform.translate(
                  offset: const Offset(0, -28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // ── KPI tiles ──────────────────────────────────────────
                      _Section(title: "Today's Performance"),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                        child: _KpiGrid(
                          tiles: [
                            _KpiData(
                              value: '$pending',
                              label: 'Allergen Alerts',
                              icon: Icons.warning_amber_rounded,
                              color: _kCherry,
                              trend: '↑ $pending active',
                            ),
                            _KpiData(
                              value: isHotel ? '${(userP.currentUser?.rooms ?? 0) ~/ 10 + 1}' : '$expiring',
                              label: isHotel ? 'Active Services' : 'Expiring Soon',
                              icon: isHotel ? Icons.room_service_rounded : Icons.inventory_2_rounded,
                              color: _kAmber,
                              trend: isHotel ? '↑ In progress' : '↑ Check now',
                            ),
                            _KpiData(
                              value: '${wasteKg}kg',
                              label: 'Waste Today',
                              icon: Icons.delete_outline_rounded,
                              color: _kOlive,
                              trend: '↓ 8% vs last week',
                            ),
                            _KpiData(
                              value: '$freshness%',
                              label: 'Freshness Score',
                              icon: Icons.eco_rounded,
                              color: _kEmerald,
                              trend: freshness >= 90 ? '✓ Excellent' : '↑ Improving',
                            ),
                          ],
                          enterController: _enterController,
                        ),
                      ),

                      const SizedBox(height: 16),

                      // ── 🔔 Live customer allergen alerts ───────────────────
                      if (userP.currentUser?.id != null)
                        _LiveVenueAlerts(venueId: userP.currentUser!.id)
                            .animate()
                            .fadeIn(delay: 280.ms)
                            .slideY(begin: 0.08, end: 0),

                      // ── Alert banner ───────────────────────────────────────
                      if (pending > 0)
                        _AlertBanner(
                          count: pending,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            context.go(AppRoutes.restaurantAlerts);
                          },
                        ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1, end: 0),

                      // ── Quick actions ──────────────────────────────────────
                      _Section(title: 'Quick Actions'),
                      _QuickActions(
                        isHotel: isHotel,
                        accentColor: accentColor,
                      ),

                      // ── Environmental impact ───────────────────────────────
                      _ImpactRow(
                        wasteKg: wasteKg,
                        scans: scans,
                        freshness: freshness,
                      ).animate().fadeIn(delay: 350.ms).slideY(begin: 0.08, end: 0),

                      // ── 3-in-1 Scan card ───────────────────────────────────
                      _ScanAllCard(
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          context.go(AppRoutes.restaurantScan);
                        },
                      ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.08, end: 0),

                      // ── Waste chart ────────────────────────────────────────
                      _Section(title: 'Waste This Week'),
                      _WasteCard(
                        series: series,
                        touchedIndex: _touchedBarIndex,
                        onTouch: (i) => setState(() => _touchedBarIndex = i),
                        isHotel: isHotel,
                      ).animate().fadeIn(delay: 500.ms),

                      // ── Inventory warning ──────────────────────────────────
                      if (expiring > 0)
                        _InventoryBanner(
                          count: expiring,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            context.go(AppRoutes.restaurantInventory);
                          },
                        ).animate().fadeIn(delay: 550.ms),

                      // ── Daily tip ──────────────────────────────────────────
                      _Section(title: 'Tip of the Day'),
                      _TipCard(tip: tip, accent: accentColor)
                          .animate()
                          .fadeIn(delay: 600.ms),

                      // ── Recent alerts ──────────────────────────────────────
                      if (recentA.isNotEmpty) ...[
                        _Section(
                          title: 'Recent Alerts',
                          action: 'View all',
                          onAction: () => context.go(AppRoutes.restaurantAlerts),
                        ),
                        ...recentA.asMap().entries.map(
                          (e) => _AlertRow(
                            alert: e.value,
                            onTap: () => context.go(
                              AppRoutes.restaurantAlertDetail(e.value.id),
                            ),
                          )
                              .animate()
                              .fadeIn(delay: Duration(milliseconds: 650 + e.key * 80))
                              .slideY(begin: 0.06, end: 0),
                        ),
                      ],

                      const SizedBox(height: 120), // bottom nav clearance
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Header delegate ────────────────────────────────────────────────────────────
class _HeaderDelegate extends SliverPersistentHeaderDelegate {
  final double minH;
  final double maxH;
  final Gradient gradient;
  final String greeting;
  final String name;
  final String subtitle;
  final String serviceChip;
  final int pendingAlerts;
  final int wasteKg;
  final int expiring;
  final bool isHotel;
  final dynamic user;

  _HeaderDelegate({
    required this.minH,
    required this.maxH,
    required this.gradient,
    required this.greeting,
    required this.name,
    required this.subtitle,
    required this.serviceChip,
    required this.pendingAlerts,
    required this.wasteKg,
    required this.expiring,
    required this.isHotel,
    required this.user,
  });

  @override
  double get minExtent => minH;
  @override
  double get maxExtent => maxH;

  @override
  Widget build(BuildContext ctx, double shrinkOffset, bool overlapsContent) {
    return Container(
      decoration: BoxDecoration(gradient: gradient),
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
                              greeting,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: Colors.white.withValues(alpha: 0.65),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              name,
                              style: GoogleFonts.sora(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              subtitle,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                      _Avatar(user: user, isHotel: isHotel),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Stats row
                  Row(
                    children: [
                      _HeaderStat(
                        label: serviceChip,
                        color: Colors.white.withValues(alpha: 0.15),
                      ),
                      const SizedBox(width: 8),
                      _HeaderStat(
                        label: '🚨 $pendingAlerts alerts',
                        color: pendingAlerts > 0
                            ? Colors.red.withValues(alpha: 0.3)
                            : Colors.white.withValues(alpha: 0.10),
                      ),
                      const SizedBox(width: 8),
                      _HeaderStat(
                        label: '♻️ ${wasteKg}kg',
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
  bool shouldRebuild(_HeaderDelegate old) => true;
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

// ── Avatar ────────────────────────────────────────────────────────────────────
class _Avatar extends StatelessWidget {
  final dynamic user;
  final bool isHotel;
  const _Avatar({required this.user, required this.isHotel});

  String _initials() {
    final n = (isHotel
        ? user?.hotelName
        : user?.restaurantName) ?? '';
    final parts = n.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    final a = parts.first.substring(0, 1).toUpperCase();
    final b = parts.length > 1 ? parts[1].substring(0, 1).toUpperCase() : '';
    return a + b;
  }

  @override
  Widget build(BuildContext context) {
    final logo = (user?.avatarPath ?? '').toString().trim();
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.15),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.5),
      ),
      child: logo.isNotEmpty
          ? ClipOval(
              child: Image.network(
                logo,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _initText(),
              ),
            )
          : _initText(),
    );
  }

  Widget _initText() => Center(
        child: Text(
          _initials(),
          style: GoogleFonts.sora(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      );
}

// ── Section header ─────────────────────────────────────────────────────────────
class _Section extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;

  const _Section({required this.title, this.action, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Row(
        children: [
          Text(
            title,
            style: GoogleFonts.sora(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: -0.2,
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
                  color: _kCherry,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── KPI Grid ───────────────────────────────────────────────────────────────────
class _KpiData {
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  final String trend;
  const _KpiData({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
    required this.trend,
  });
}

class _KpiGrid extends StatelessWidget {
  final List<_KpiData> tiles;
  final AnimationController enterController;

  const _KpiGrid({required this.tiles, required this.enterController});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.35,
      children: tiles.asMap().entries.map((e) {
        return _KpiTile(data: e.value)
            .animate()
            .fadeIn(delay: Duration(milliseconds: 100 + e.key * 80), duration: 500.ms)
            .slideY(
              begin: 0.12,
              end: 0,
              delay: Duration(milliseconds: 100 + e.key * 80),
              duration: 500.ms,
              curve: Curves.easeOutCubic,
            );
      }).toList(),
    );
  }
}

class _KpiTile extends StatelessWidget {
  final _KpiData data;
  const _KpiTile({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: data.color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(data.icon, color: data.color, size: 18),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: data.color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  data.trend,
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: data.color,
                  ),
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data.value,
                style: GoogleFonts.sora(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: data.color,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                data.label,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: _kSlate,
                ),
              ),
            ],
          ),
        ],
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
          color: _kCherry.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _kCherry.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _kCherry.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.notifications_active_rounded, color: _kCherry, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$count alert${count == 1 ? '' : 's'} need your attention',
                    style: GoogleFonts.sora(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _kCherry,
                    ),
                  ),
                  Text(
                    'Tap to review and resolve',
                    style: GoogleFonts.inter(fontSize: 11, color: _kCherry.withValues(alpha: 0.7)),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: _kCherry, size: 20),
          ],
        ),
      ),
    );
  }
}

// ── Quick actions ──────────────────────────────────────────────────────────────
class _QuickActions extends StatelessWidget {
  final bool isHotel;
  final Color accentColor;
  const _QuickActions({required this.isHotel, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    final actions = [
      _QA(icon: Icons.document_scanner_rounded, color: _kCherry, label: 'Scan', route: AppRoutes.restaurantScan),
      _QA(icon: Icons.notifications_rounded, color: _kAmber, label: 'Alerts', route: AppRoutes.restaurantAlerts),
      _QA(icon: Icons.delete_outline_rounded, color: _kSlate, label: 'Waste', route: AppRoutes.restaurantWaste),
      _QA(icon: Icons.eco_rounded, color: _kEmerald, label: 'Compost', route: AppRoutes.restaurantCompost),
      _QA(icon: Icons.inventory_2_rounded, color: _kIndigo, label: 'Inventory', route: AppRoutes.restaurantInventory),
    ];

    return SizedBox(
      height: 88,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: actions.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
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
                color: _kCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _kBorder, width: 0.8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 6,
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
                      color: a.color.withValues(alpha: 0.10),
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
                      color: _kSlate,
                    ),
                  ),
                ],
              ),
            ),
          )
              .animate()
              .fadeIn(delay: Duration(milliseconds: 200 + i * 60), duration: 400.ms)
              .slideX(begin: 0.1, end: 0, delay: Duration(milliseconds: 200 + i * 60), duration: 400.ms);
        },
      ),
    );
  }
}

class _QA {
  final IconData icon;
  final Color color;
  final String label;
  final String route;
  const _QA({required this.icon, required this.color, required this.label, required this.route});
}

// ── Compost AI teaser card ─────────────────────────────────────────────────────
class _CompostTeaser extends StatelessWidget {
  final VoidCallback onTap;
  const _CompostTeaser({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF064E3B), Color(0xFF065F46)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: _kEmerald.withValues(alpha: 0.25),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _kEmerald.withValues(alpha: 0.2),
                border: Border.all(color: _kEmerald.withValues(alpha: 0.4)),
              ),
              child: const Center(
                child: Text('♻️', style: TextStyle(fontSize: 26)),
              ),
            ),
            const SizedBox(width: 14),
            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _kEmerald.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '⭐ IA COMPOST',
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: _kEmerald,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Analysez vos déchets\npar segmentation IA',
                    style: GoogleFonts.sora(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Mask2Former INT8 · On-device',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.55),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white38,
              size: 16,
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
        color: _kCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kBorder, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
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
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: _kBorder,
                    strokeWidth: 0.8,
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) => Text(
                        days[v.toInt().clamp(0, 4)],
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: _kSlate,
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
                              ? [_kOlive, _kOlive.withValues(alpha: 0.6)]
                              : [_kOlive.withValues(alpha: 0.5), _kOlive.withValues(alpha: 0.3)],
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
                    getTooltipItem: (group, _, rod, _) => BarTooltipItem(
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
              _Pill(text: '↓ 8% vs last week', bg: _kOlive.withValues(alpha: 0.10), color: _kOlive),
              const SizedBox(width: 8),
              _Pill(
                text: '${isHotel ? 'Buffet' : 'Bread'} — top waste',
                bg: _kCherry.withValues(alpha: 0.08),
                color: _kCherry,
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
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: color),
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
          color: _kAmber.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _kAmber.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: _kAmber.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.inventory_2_outlined, color: _kAmber, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '$count item${count == 1 ? '' : 's'} expiring within 3 days',
                style: GoogleFonts.sora(
                  fontSize: 13, fontWeight: FontWeight.w700, color: _kAmber,
                ),
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: _kAmber, size: 18),
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
  final Color accent;
  const _TipCard({required this.tip, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kBorder, width: 0.8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [accent, accent.withValues(alpha: 0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.lightbulb_outline_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'CONSEIL DU JOUR',
                    style: GoogleFonts.inter(
                      fontSize: 9, fontWeight: FontWeight.w700, color: accent, letterSpacing: 1,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  tip.title,
                  style: GoogleFonts.sora(
                    fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tip.body,
                  style: GoogleFonts.inter(
                    fontSize: 12, color: _kSlate, height: 1.5,
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
    if (d.inSeconds < 45) return 'À l\'instant';
    if (d.inMinutes < 60) return '${d.inMinutes}min';
    if (d.inHours < 24) return '${d.inHours}h';
    return DateFormat('dd MMM').format(alert.timestamp);
  }

  String _initials() {
    final parts = alert.customerName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    final a = parts.first.isEmpty ? '?' : parts.first[0].toUpperCase();
    final b = parts.length > 1 && parts[1].isNotEmpty ? parts[1][0].toUpperCase() : '';
    return a + b;
  }

  @override
  Widget build(BuildContext context) {
    final isResolved = alert.status == 'resolved';
    final color = isResolved ? _kOlive : _kCherry;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(16),
          border: Border(
            left: BorderSide(color: color, width: 3),
            top: BorderSide(color: _kBorder, width: 0.5),
            right: BorderSide(color: _kBorder, width: 0.5),
            bottom: BorderSide(color: _kBorder, width: 0.5),
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: color.withValues(alpha: 0.15),
              child: Text(
                _initials(),
                style: GoogleFonts.sora(
                  fontSize: 12, fontWeight: FontWeight.w700, color: color,
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
                      fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white,
                    ),
                  ),
                  Text(
                    '⚠ ${alert.allergen} · ${alert.dishName}',
                    style: GoogleFonts.inter(fontSize: 11, color: _kCherry),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _timeAgo(),
                  style: GoogleFonts.inter(fontSize: 10, color: _kSlate),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isResolved ? 'Resolved' : 'Pending',
                    style: GoogleFonts.inter(
                      fontSize: 10, fontWeight: FontWeight.w700, color: color,
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

// ── Environmental Impact Row ────────────────────────────────────────────────────
class _ImpactRow extends StatelessWidget {
  final int wasteKg;
  final int scans;
  final int freshness;
  const _ImpactRow({required this.wasteKg, required this.scans, required this.freshness});

  @override
  Widget build(BuildContext context) {
    final co2 = (wasteKg * 2.5).toStringAsFixed(1);
    final meals = (wasteKg * 1.8).round();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🌍 Environmental Impact Today',
            style: GoogleFonts.sora(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _ImpactChip(emoji: '♻️', value: '${wasteKg}kg', label: 'avoided', color: _kOlive),
              const SizedBox(width: 8),
              _ImpactChip(emoji: '💨', value: '${co2}kg', label: 'CO₂', color: _kIndigo),
              const SizedBox(width: 8),
              _ImpactChip(emoji: '🍽', value: '$meals', label: 'meals', color: _kAmber),
            ],
          ),
        ],
      ),
    );
  }
}

class _ImpactChip extends StatelessWidget {
  final String emoji, value, label;
  final Color color;
  const _ImpactChip({
    required this.emoji, required this.value,
    required this.label, required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withValues(alpha: 0.15), color.withValues(alpha: 0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.25), width: 0.8),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.sora(
                fontSize: 16, fontWeight: FontWeight.w800, color: color,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10, color: Colors.white.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 🔔 Live Customer Allergen Alert Stream ─────────────────────────────────────
/// Displayed on the staff dashboard. Shows real-time alerts when a customer
/// with allergens has been seen at this venue (via VenueAlertService).
class _LiveVenueAlerts extends StatefulWidget {
  final String venueId;
  const _LiveVenueAlerts({required this.venueId});

  @override
  State<_LiveVenueAlerts> createState() => _LiveVenueAlertsState();
}

class _LiveVenueAlertsState extends State<_LiveVenueAlerts>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: VenueAlertService.alertsStream(widget.venueId),
      builder: (context, snap) {
        if (!snap.hasData || snap.data!.docs.isEmpty) return const SizedBox.shrink();

        final docs = snap.data!.docs;

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Container(
            decoration: BoxDecoration(
              color: _kCherry.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _kCherry.withValues(alpha: 0.25), width: 1.2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
                  child: Row(
                    children: [
                      AnimatedBuilder(
                        animation: _pulse,
                        builder: (_, _) => Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _kCherry.withValues(alpha: 0.5 + _pulse.value * 0.5),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '🚨 Live Allergen Alerts — ${docs.length} active',
                          style: GoogleFonts.sora(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _kCherry,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => VenueAlertService.resolveAll(widget.venueId),
                        style: TextButton.styleFrom(
                          foregroundColor: _kCherry,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'Clear all',
                          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Alert tiles
                ...docs.map((doc) {
                  final d = doc.data();
                  final name      = d['customerName'] as String? ?? 'Guest';
                  final allergens = List<String>.from(d['allergens'] as List? ?? []);
                  final product   = d['productName'] as String? ?? '';
                  final risk      = d['riskLevel'] as String? ?? 'moderate';
                  final riskColor = risk == 'high' ? _kCherry : risk == 'low' ? _kOlive : _kAmber;

                  return Container(
                    margin: const EdgeInsets.fromLTRB(10, 0, 10, 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _kCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: riskColor.withValues(alpha: 0.30), width: 0.8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: riskColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Icon(Icons.person_rounded, size: 18, color: riskColor),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: GoogleFonts.sora(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: _kTextPrimary,
                                ),
                              ),
                              if (product.isNotEmpty)
                                Text(
                                  'Scanned: $product',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: _kTextSecondary,
                                  ),
                                ),
                              const SizedBox(height: 4),
                              Wrap(
                                spacing: 4,
                                runSpacing: 4,
                                children: allergens.map((a) => Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: riskColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: riskColor.withValues(alpha: 0.30)),
                                  ),
                                  child: Text(
                                    a,
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: riskColor,
                                    ),
                                  ),
                                )).toList(),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () => VenueAlertService.resolve(doc.id),
                          child: Icon(Icons.check_circle_outline_rounded,
                              size: 20, color: _kOlive),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── 3-in-1 Scan Card ───────────────────────────────────────────────────────────
class _ScanAllCard extends StatefulWidget {
  final VoidCallback onTap;
  const _ScanAllCard({required this.onTap});

  @override
  State<_ScanAllCard> createState() => _ScanAllCardState();
}

class _ScanAllCardState extends State<_ScanAllCard>
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
              colors: [Color(0xFFFF9A3C), Color(0xFFF59E0B), Color(0xFFFF6B35)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: _kAmber.withValues(alpha: 0.30 + _pulse.value * 0.15),
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
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.document_scanner_rounded,
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '3 ANALYSES EN 1 SCAN',
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
                    style: GoogleFonts.sora(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'AI-powered · Results in 2 seconds',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.75),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_forward_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
