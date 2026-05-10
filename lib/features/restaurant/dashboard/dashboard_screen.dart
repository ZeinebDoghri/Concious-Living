import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/constants.dart';
import '../../../core/firebase_service.dart';
import '../../../core/models/alert_model.dart';
import '../../../providers/alerts_provider.dart';
import '../../../providers/inventory_provider.dart';
import '../../../providers/scan_history_provider.dart';
import '../../../providers/user_provider.dart';
import '../../../providers/venue_type_provider.dart';
import '../../../features/shared/compost_dashboard_panel.dart';
import '../../../shared/animations/shimmer_box.dart';
import '../../../widgets/animated_chat_fab.dart';

// ── FreshGuard restaurant pastel tokens ───────────────────────────────────────
const _rPrimary = Color(0xFF8FA84A);
const _rDeep = Color(0xFF5A7030);
const _rSurface = Color(0xFFF5F8EE);
const _rSoftBg = Color(0xFFE3E8D1);
const _rTextTitle = Color(0xFF26201B);
const _rTextBody = Color(0xFF5C4F48);
const _rTextMuted = Color(0xFF8C7E78);

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
  int _dashboardTab = 0;

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

  String _restaurantId(UserProvider userProvider) {
    final user = userProvider.currentUser;
    if (user == null) return '';
    return user.entityId ?? user.restaurantId ?? user.id;
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

  String isoWeek() {
    final now = DateTime.now();
    final thursday = now.add(Duration(days: 3 - ((now.weekday + 6) % 7)));
    final firstThursday = DateTime(thursday.year, 1, 4);
    final week = 1 +
        (thursday.difference(firstThursday).inDays / 7).floor();
    return '${thursday.year}-W${week.toString().padLeft(2, '0')}';
  }

  Stream<_WeeklyMetrics> _weeklyMetricsStream(String restaurantId) {
    if (restaurantId.isEmpty) return Stream.value(const _WeeklyMetrics.empty());
    return FirebaseFirestore.instance
        .collection('compost_totals')
        .doc(restaurantId)
        .collection('weekly')
        .doc(isoWeek())
        .snapshots()
        .map((s) {
          if (!s.exists) return const _WeeklyMetrics.empty();
          final data = s.data() ?? const <String, dynamic>{};
          final waste = _asDouble(data['waste_kg']);
          final compost = _asDouble(data['compostable_kg']);
          final rate = waste <= 0 ? 0.0 : (compost / waste * 100);
          return _WeeklyMetrics(
            wasteKg: waste,
            compostRate: rate,
            exists: true,
          );
        });
  }

  Stream<_FreshnessMetric> _freshnessMetricStream(String restaurantId) {
    if (restaurantId.isEmpty) return Stream.value(const _FreshnessMetric(0));
    return FirebaseFirestore.instance
        .collection('restaurants')
        .doc(restaurantId)
        .collection('scans')
        .orderBy('timestamp', descending: true)
        .limit(10)
        .snapshots()
        .map((snap) {
          if (snap.docs.isEmpty) return const _FreshnessMetric.empty();
          final scores = snap.docs
              .map((d) => _asDouble(d.data()['freshness_confidence']))
              .where((v) => v > 0)
              .toList();
          if (scores.isEmpty) return const _FreshnessMetric.empty();
          return _FreshnessMetric(
            scores.reduce((a, b) => a + b) / scores.length,
            exists: true,
          );
        });
  }

  Stream<_ActiveAlertsMetric> _activeAlertsMetricStream(String restaurantId) {
    if (restaurantId.isEmpty) return Stream.value(const _ActiveAlertsMetric(0));
    return FirebaseFirestore.instance
        .collection('restaurants')
        .doc(restaurantId)
        .collection('alerts')
        .where('resolved', isEqualTo: false)
        .snapshots()
        .map((snap) => _ActiveAlertsMetric(snap.docs.length));
  }

  Stream<List<_DailyWastePoint>> _dailyWasteStream(String restaurantId) {
    if (restaurantId.isEmpty) return Stream.value(_emptyDailyWaste());
    final start = DateTime.now().subtract(const Duration(days: 6));
    final startId = DateFormat('yyyy-MM-dd').format(start);
    return FirebaseFirestore.instance
        .collection('waste_logs')
        .doc(restaurantId)
        .collection('daily')
        .orderBy(FieldPath.documentId)
        .startAt([startId])
        .limit(7)
        .snapshots()
        .map((snap) {
          final byId = {for (final doc in snap.docs) doc.id: doc.data()};
          return List.generate(7, (i) {
            final date = DateTime.now().subtract(Duration(days: 6 - i));
            final id = DateFormat('yyyy-MM-dd').format(date);
            final data = byId[id] ?? const <String, dynamic>{};
            return _DailyWastePoint(
              date: date,
              wasteKg: _asDouble(data['waste_kg']),
              compostKg: _asDouble(
                data['compostable_kg'] ?? data['compost_kg'],
              ),
              itemsScanned: (_asDouble(
                data['items_scanned'] ?? data['items'],
              )).round(),
              zoneBreakdown: _stringMap(
                data['zone_breakdown'] ?? data['zones'],
              ),
            );
          });
        });
  }

  Stream<List<_ExpiryScan>> _expiryStream(String restaurantId) {
    if (restaurantId.isEmpty) return Stream.value(const []);
    final deadline = DateTime.now().add(const Duration(hours: 72));
    return FirebaseFirestore.instance
        .collection('restaurants')
        .doc(restaurantId)
        .collection('scans')
        .where(
          'results.expiry.date',
          isLessThanOrEqualTo: Timestamp.fromDate(deadline),
        )
        .orderBy('results.expiry.date')
        .limit(8)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map(_expiryFromDoc).whereType<_ExpiryScan>().toList(),
        );
  }

  Stream<List<_SmartAlert>> _smartAlertsStream(String restaurantId) {
    if (restaurantId.isEmpty) return Stream.value(const []);
    return FirebaseFirestore.instance
        .collection('restaurants')
        .doc(restaurantId)
        .collection('alerts')
        .where('resolved', isEqualTo: false)
        .orderBy('severity')
        .snapshots()
        .map((snap) => snap.docs.map(_smartAlertFromDoc).toList());
  }

  Future<void> _dismissSmartAlert(
    String restaurantId,
    String alertId,
    String uid,
  ) {
    return FirebaseFirestore.instance
        .collection('restaurants')
        .doc(restaurantId)
        .collection('alerts')
        .doc(alertId)
        .update({
          'resolved': true,
          'resolvedAt': FieldValue.serverTimestamp(),
          'resolvedBy': uid,
        });
  }

  static double _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  static Map<String, double> _stringMap(dynamic value) {
    if (value is! Map) return const {};
    return value.map((key, val) => MapEntry(key.toString(), _asDouble(val)));
  }

  static List<_DailyWastePoint> _emptyDailyWaste() {
    return List.generate(7, (i) {
      final date = DateTime.now().subtract(Duration(days: 6 - i));
      return _DailyWastePoint(date: date);
    });
  }

  static _ExpiryScan? _expiryFromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final results = data['results'];
    if (results is! Map) return null;
    final expiry = results['expiry'];
    if (expiry is! Map) return null;
    final rawDate = expiry['date'];
    final date = rawDate is Timestamp
        ? rawDate.toDate()
        : DateTime.tryParse((rawDate ?? '').toString());
    if (date == null || date.isBefore(DateTime.now())) return null;
    return _ExpiryScan(
      id: doc.id,
      itemName:
          (data['itemName'] ??
                  data['item_name'] ??
                  expiry['itemName'] ??
                  'Food item')
              .toString(),
      zone: (data['zone'] ?? expiry['zone'] ?? 'Main storage').toString(),
      expiryDate: date,
    );
  }

  static _SmartAlert _smartAlertFromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final rawTimestamp = data['timestamp'] ?? data['createdAt'];
    final timestamp = rawTimestamp is Timestamp
        ? rawTimestamp.toDate()
        : DateTime.tryParse((rawTimestamp ?? '').toString()) ?? DateTime.now();
    return _SmartAlert(
      id: doc.id,
      type: (data['type'] ?? data['alertType'] ?? 'alert').toString(),
      itemName:
          (data['itemName'] ??
                  data['item_name'] ??
                  data['title'] ??
                  'Food item')
              .toString(),
      zone: (data['zone'] ?? 'Main storage').toString(),
      timestamp: timestamp,
      confidence: _asDouble(data['confidence']),
      severity: (data['severity'] ?? 'medium').toString(),
    );
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
      appBar: AppBar(
        backgroundColor: _rDeep,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _greeting(),
              style: GoogleFonts.inter(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              'FreshGuard',
              style: GoogleFonts.playfairDisplay(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.smart_toy_outlined, color: Colors.white),
            tooltip: 'Chef AI',
            onPressed: () => context.go('/restaurant/chatbot'),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
            tooltip: 'Sign out',
            onPressed: () async {
              await FirebaseService.signOut();
              if (!context.mounted) return;
              context.go('/');
            },
          ),
        ],
      ),
      floatingActionButton: AnimatedChatFab(
        color: const Color(0xFF5C7A3E),
        label: 'Chef AI',
        icon: Icons.smart_toy_rounded,
        onTap: () => context.go('/restaurant/chatbot'),
      ),
      body: Consumer<VenueTypeProvider>(
        builder: (ctx, venueP, _) {
          final isHotel = venueP.venueType == 'hotel';
          final alertsP = ctx.watch<AlertsProvider>();
          final invP = ctx.watch<InventoryProvider>();
          final userP = ctx.watch<UserProvider>();
          final scanP = ctx.watch<ScanHistoryProvider>();

          final name = _venueName(userP, isHotel);
          final subtitle = _venueSubtitle(userP, isHotel);
          final restaurantId = _restaurantId(userP);
          final fallbackPending = alertsP.pendingCount;
          final expiring = _expiringSoon(invP);
          final scans = scanP.items.length;
          final recentA = _recentAlerts(alertsP);
          final tips = _tips(isHotel);
          final tip = tips[DateTime.now().day % tips.length];
          final showCompost = _dashboardTab == 1;

          return MultiProvider(
            providers: [
              StreamProvider<_WeeklyMetrics>.value(
                value: _weeklyMetricsStream(restaurantId),
                initialData: const _WeeklyMetrics.empty(),
              ),
              StreamProvider<_FreshnessMetric>.value(
                value: _freshnessMetricStream(restaurantId),
                initialData: const _FreshnessMetric(0),
              ),
              StreamProvider<_ActiveAlertsMetric>.value(
                value: _activeAlertsMetricStream(restaurantId),
                initialData: _ActiveAlertsMetric(fallbackPending),
              ),
            ],
            child: Builder(
              builder: (context) {
                final weekly = context.watch<_WeeklyMetrics>();
                final pending = context.watch<_ActiveAlertsMetric>().count;
                final freshnessValue = context.watch<_FreshnessMetric>().value;
                final wasteKg = weekly.wasteKg > 0
                    ? weekly.wasteKg.round()
                    : _wasteEst(pending, expiring, scans);
                final freshness = freshnessValue > 0
                    ? freshnessValue.round()
                    : _freshnessScore(pending, expiring).round();

                return StreamBuilder<List<_DailyWastePoint>>(
                  stream: _dailyWasteStream(restaurantId),
                  initialData: _emptyDailyWaste(),
                  builder: (context, dailySnap) {
                    final daily = dailySnap.data ?? _emptyDailyWaste();
                    final fallbackSeries = _wasteSeries(
                      pending,
                      expiring,
                      scans,
                      isHotel,
                    );
                    final series = daily.any((p) => p.wasteKg > 0)
                        ? daily.map((p) => p.wasteKg).toList()
                        : fallbackSeries;
                    final compostSeries = daily
                        .map((p) => p.compostKg)
                        .toList();

                    return StreamBuilder<List<_ExpiryScan>>(
                      stream: _expiryStream(restaurantId),
                      initialData: const [],
                      builder: (context, expirySnap) {
                        final expiryScans = expirySnap.data ?? const [];
                        return StreamBuilder<List<_SmartAlert>>(
                          stream: _smartAlertsStream(restaurantId),
                          initialData: const [],
                          builder: (context, smartAlertSnap) {
                            final smartAlerts = smartAlertSnap.data ?? const [];
                            return CustomScrollView(
                              physics: const BouncingScrollPhysics(),
                              slivers: [
                                SliverToBoxAdapter(
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      16,
                                      14,
                                      16,
                                      0,
                                    ),
                                    child: _RestaurantDashboardTabs(
                                      showCompost: showCompost,
                                      onOverview: () =>
                                          setState(() => _dashboardTab = 0),
                                      onCompost: () =>
                                          setState(() => _dashboardTab = 1),
                                    ),
                                  ),
                                ),
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

                                if (!showCompost)
                                  SliverToBoxAdapter(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // ── Mini stat row ──────────────────────────────────────
                                        Padding(
                                          padding: const EdgeInsets.fromLTRB(
                                            16,
                                            20,
                                            16,
                                            0,
                                          ),
                                          child: _RestaurantKpiGrid(
                                            restaurantId: restaurantId,
                                          ),
                                        ),

                                        const SizedBox(height: 16),

                                        // ── Alert banner ───────────────────────────────────────
                                        if (pending > 0)
                                          _AlertBanner(
                                                count: pending,
                                                onTap: () {
                                                  HapticFeedback.selectionClick();
                                                  context.go(
                                                    AppRoutes.restaurantAlerts,
                                                  );
                                                },
                                              )
                                              .animate()
                                              .fadeIn(delay: 200.ms)
                                              .slideY(begin: 0.1, end: 0),

                                        // ── Quick actions ──────────────────────────────────────
                                        _SectionHeader(title: 'Quick Actions'),
                                        _QuickActions(
                                          onOpenCompost: () =>
                                              setState(() => _dashboardTab = 1),
                                        ),

                                        // ── Scan CTA ───────────────────────────────────────────
                                        _ScanCard(
                                              onTap: () {
                                                HapticFeedback.mediumImpact();
                                                context.go(
                                                  AppRoutes.restaurantScan,
                                                );
                                              },
                                            )
                                            .animate()
                                            .fadeIn(delay: 300.ms)
                                            .slideY(begin: 0.08, end: 0),

                                        // ── Waste chart ────────────────────────────────────────
                                        _SectionHeader(
                                          title: 'Waste This Week',
                                        ),
                                        _WasteCard(
                                          series: series,
                                          compostSeries: compostSeries,
                                          points: daily,
                                          touchedIndex: _touchedBarIndex,
                                          onTouch: (i) => setState(
                                            () => _touchedBarIndex = i,
                                          ),
                                          isHotel: isHotel,
                                        ).animate().fadeIn(delay: 400.ms),

                                        _SectionHeader(
                                          title: 'Freshness Score',
                                        ),
                                        _MiniStatStrip(
                                          label: 'Average of last 10 scans',
                                          value:
                                              context
                                                  .watch<_FreshnessMetric>()
                                                  .exists
                                              ? '$freshness%'
                                              : '—',
                                          icon: Icons.eco_rounded,
                                        ),

                                        if (expiryScans.isNotEmpty) ...[
                                          _SectionHeader(
                                            title: 'Expiry Timeline',
                                          ),
                                          _ExpiryTimeline(
                                            scans: expiryScans,
                                          ).animate().fadeIn(delay: 430.ms),
                                        ],

                                        // ── Inventory banner ───────────────────────────────────
                                        if (expiring > 0)
                                          _InventoryBanner(
                                            count: expiring,
                                            onTap: () {
                                              HapticFeedback.selectionClick();
                                              context.go(
                                                AppRoutes.restaurantInventory,
                                              );
                                            },
                                          ).animate().fadeIn(delay: 450.ms),

                                        // ── Daily tip ──────────────────────────────────────────
                                        _SectionHeader(title: 'Daily Tip'),
                                        _TipCard(
                                          tip: tip,
                                        ).animate().fadeIn(delay: 500.ms),

                                        // ── Recent alerts ──────────────────────────────────────
                                        if (recentA.isNotEmpty) ...[
                                          _SectionHeader(
                                            title: 'Recent Alerts',
                                            action: 'View All',
                                            onAction: () => context.go(
                                              AppRoutes.restaurantAlerts,
                                            ),
                                          ),
                                          ...recentA.asMap().entries.map(
                                            (e) =>
                                                _AlertRow(
                                                      alert: e.value,
                                                      onTap: () => context.go(
                                                        AppRoutes.restaurantAlertDetail(
                                                          e.value.id,
                                                        ),
                                                      ),
                                                    )
                                                    .animate()
                                                    .fadeIn(
                                                      delay: Duration(
                                                        milliseconds:
                                                            550 + e.key * 70,
                                                      ),
                                                    )
                                                    .slideY(
                                                      begin: 0.06,
                                                      end: 0,
                                                    ),
                                          ),
                                        ],

                                        if (smartAlerts.isNotEmpty) ...[
                                          _SectionHeader(title: 'Smart Alerts'),
                                          ...smartAlerts.asMap().entries.map(
                                            (entry) =>
                                                _SmartAlertRow(
                                                      alert: entry.value,
                                                      onDismissed: () =>
                                                          _dismissSmartAlert(
                                                            restaurantId,
                                                            entry.value.id,
                                                            userP
                                                                    .currentUser
                                                                    ?.id ??
                                                                restaurantId,
                                                          ),
                                                    )
                                                    .animate()
                                                    .fadeIn(
                                                      delay: Duration(
                                                        milliseconds:
                                                            600 +
                                                            entry.key * 70,
                                                      ),
                                                    )
                                                    .slideY(
                                                      begin: 0.06,
                                                      end: 0,
                                                    ),
                                          ),
                                        ],

                                        const SizedBox(height: 120),
                                      ],
                                    ),
                                  ),
                                if (showCompost)
                                  SliverToBoxAdapter(
                                    child: CompostDashboardPanel(
                                      entityId: restaurantId,
                                      entityCollection: 'restaurants',
                                      title: 'Restaurant Compost',
                                      showDepartmentSelector: false,
                                      accent: _fresh,
                                      deep: _rDeep,
                                      softBg: _rSoftBg,
                                      surface: _rSurface,
                                    ),
                                  ),
                              ],
                            );
                          },
                        );
                      },
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}

// ── Pastel header ──────────────────────────────────────────────────────────────
class _WeeklyMetrics {
  final double wasteKg;
  final double compostRate;
  final bool exists;

  const _WeeklyMetrics({
    required this.wasteKg,
    required this.compostRate,
    this.exists = false,
  });
  const _WeeklyMetrics.empty() : wasteKg = 0, compostRate = 0, exists = false;
}

class _FreshnessMetric {
  final double value;
  final bool exists;
  const _FreshnessMetric(this.value, {this.exists = false});
  const _FreshnessMetric.empty() : value = 0, exists = false;
}

class _ActiveAlertsMetric {
  final int count;
  const _ActiveAlertsMetric(this.count);
}

class _RestaurantKpiGrid extends StatelessWidget {
  final String restaurantId;

  const _RestaurantKpiGrid({required this.restaurantId});

  String isoWeek() {
    final now = DateTime.now();
    final thursday = now.add(Duration(days: 3 - ((now.weekday + 6) % 7)));
    final firstThursday = DateTime(thursday.year, 1, 4);
    final week = 1 +
        (thursday.difference(firstThursday).inDays / 7).floor();
    return '${thursday.year}-W${week.toString().padLeft(2, '0')}';
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> get _weeklyStream =>
      FirebaseFirestore.instance
          .collection('compost_totals')
          .doc(restaurantId)
          .collection('weekly')
          .doc(isoWeek())
          .snapshots();

  Stream<QuerySnapshot<Map<String, dynamic>>> get _freshnessStream =>
      FirebaseFirestore.instance
          .collection('restaurants')
          .doc(restaurantId)
          .collection('scans')
          .orderBy('timestamp', descending: true)
          .limit(10)
          .snapshots();

  Stream<QuerySnapshot<Map<String, dynamic>>> get _alertsStream =>
      FirebaseFirestore.instance
          .collection('restaurants')
          .doc(restaurantId)
          .collection('alerts')
          .where('resolved', isEqualTo: false)
          .snapshots();

  @override
  Widget build(BuildContext context) {
    if (restaurantId.isEmpty) {
      return const _RestaurantKpiCards(
        wasteValue: '—',
        compostValue: '—',
        freshnessValue: '—',
        alertsValue: '—',
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _weeklyStream,
      builder: (context, weeklySnap) {
        final weeklyLoading =
            weeklySnap.connectionState == ConnectionState.waiting;
        final weeklyExists = weeklySnap.data?.exists == true;
        final weekly = weeklySnap.data?.data() ?? const <String, dynamic>{};
        final wasteKg = _DashboardScreenState._asDouble(weekly['waste_kg']);
        final compostableKg = _DashboardScreenState._asDouble(
          weekly['compostable_kg'],
        );
        final compostRate = wasteKg <= 0 ? 0.0 : compostableKg / wasteKg * 100;

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _freshnessStream,
          builder: (context, freshnessSnap) {
            final freshnessLoading =
                freshnessSnap.connectionState == ConnectionState.waiting;
            final scores =
                freshnessSnap.data?.docs
                    .map(
                      (doc) => _DashboardScreenState._asDouble(
                        doc.data()['freshness_confidence'],
                      ),
                    )
                    .where((score) => score > 0)
                    .toList() ??
                const <double>[];
            final hasFreshness = scores.isNotEmpty;
            final freshness = hasFreshness
                ? scores.reduce((a, b) => a + b) / scores.length
                : 0.0;

            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _alertsStream,
              builder: (context, alertsSnap) {
                final alertsLoading =
                    alertsSnap.connectionState == ConnectionState.waiting;
                final alertCount = alertsSnap.data?.docs.length ?? 0;

                return _RestaurantKpiCards(
                  wasteValue: weeklyExists
                      ? '${wasteKg.toStringAsFixed(1)} kg'
                      : '—',
                  compostValue: weeklyExists
                      ? '${compostRate.toStringAsFixed(0)}%'
                      : '—',
                  freshnessValue: hasFreshness
                      ? '${freshness.toStringAsFixed(0)}%'
                      : '—',
                  alertsValue: '${alertCount} alerts',
                  wasteLoading: weeklyLoading,
                  compostLoading: weeklyLoading,
                  freshnessLoading: freshnessLoading,
                  alertsLoading: alertsLoading,
                );
              },
            );
          },
        );
      },
    );
  }
}

class _RestaurantKpiCards extends StatelessWidget {
  final String wasteValue;
  final String compostValue;
  final String freshnessValue;
  final String alertsValue;
  final bool wasteLoading;
  final bool compostLoading;
  final bool freshnessLoading;
  final bool alertsLoading;

  const _RestaurantKpiCards({
    required this.wasteValue,
    required this.compostValue,
    required this.freshnessValue,
    required this.alertsValue,
    this.wasteLoading = false,
    this.compostLoading = false,
    this.freshnessLoading = false,
    this.alertsLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.7,
      children: [
        _RestaurantKpiCard(
          label: 'Waste this week',
          value: wasteValue,
          color: _rDeep,
          icon: Icons.delete_outline_rounded,
          loading: wasteLoading,
        ),
        _RestaurantKpiCard(
          label: 'Compost rate',
          value: compostValue,
          color: _fresh,
          icon: Icons.recycling_rounded,
          loading: compostLoading,
        ),
        _RestaurantKpiCard(
          label: 'Freshness score',
          value: freshnessValue,
          color: _rPrimary,
          icon: Icons.eco_rounded,
          loading: freshnessLoading,
        ),
        _RestaurantKpiCard(
          label: 'Active alerts',
          value: alertsValue,
          color: _danger,
          icon: Icons.warning_amber_rounded,
          loading: alertsLoading,
        ),
      ],
    );
  }
}

class _RestaurantKpiCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  final bool loading;

  const _RestaurantKpiCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
          const Spacer(),
          if (loading)
            const ShimmerBox(width: 64, height: 20, radius: 8)
          else
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.playfairDisplay(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: color,
                height: 1.0,
              ),
            ),
          const SizedBox(height: 3),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(fontSize: 10, color: _rTextMuted),
          ),
        ],
      ),
    );
  }
}

class _DailyWastePoint {
  final DateTime date;
  final double wasteKg;
  final double compostKg;
  final int itemsScanned;
  final Map<String, double> zoneBreakdown;

  const _DailyWastePoint({
    required this.date,
    this.wasteKg = 0,
    this.compostKg = 0,
    this.itemsScanned = 0,
    this.zoneBreakdown = const {},
  });
}

class _ExpiryScan {
  final String id;
  final String itemName;
  final String zone;
  final DateTime expiryDate;

  const _ExpiryScan({
    required this.id,
    required this.itemName,
    required this.zone,
    required this.expiryDate,
  });

  int get hoursLeft => expiryDate.difference(DateTime.now()).inHours;

  Color get color {
    if (hoursLeft < 24) return _danger;
    if (hoursLeft < 48) return _warning;
    return const Color(0xFFFFD166);
  }
}

class _SmartAlert {
  final String id;
  final String type;
  final String itemName;
  final String zone;
  final DateTime timestamp;
  final double confidence;
  final String severity;

  const _SmartAlert({
    required this.id,
    required this.type,
    required this.itemName,
    required this.zone,
    required this.timestamp,
    required this.confidence,
    required this.severity,
  });
}

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
          colors: [Color(0xFFE3E8D1), Color(0xFFF5F8EE)],
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
class _MiniStatStrip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _MiniStatStrip({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _rSoftBg),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: _fresh.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: _fresh, size: 19),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _rTextBody,
              ),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.playfairDisplay(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: _fresh,
            ),
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
  final VoidCallback onOpenCompost;
  const _QuickActions({required this.onOpenCompost});

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
        route: '',
      ),
      _QA(
        icon: Icons.history_rounded,
        color: const Color(0xFF4A7FA5),
        label: 'History',
        route: AppRoutes.restaurantHistory,
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
                  if (a.label == 'Compost') {
                    onOpenCompost();
                    return;
                  }
                  context.go(a.route);
                },
                child: Container(
                  width: 64,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: a.color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: a.color.withValues(alpha: 0.3)),
                        ),
                        child: Icon(a.icon, color: a.color, size: 24),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        a.label,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Colors.black54,
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

class _RestaurantDashboardTabs extends StatelessWidget {
  final bool showCompost;
  final VoidCallback onOverview;
  final VoidCallback onCompost;

  const _RestaurantDashboardTabs({
    required this.showCompost,
    required this.onOverview,
    required this.onCompost,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: onOverview,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: showCompost ? Colors.transparent : const Color(0xFF5C7A3E),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Overview',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: showCompost ? Colors.black54 : Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onTap: onCompost,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: showCompost ? const Color(0xFF5C7A3E) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Compost',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: showCompost ? Colors.white : Colors.black54,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
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
              colors: [Color(0xFF8FA84A), Color(0xFF5A7030)],
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
  final List<double> compostSeries;
  final List<_DailyWastePoint> points;
  final int? touchedIndex;
  final ValueChanged<int?> onTouch;
  final bool isHotel;

  const _WasteCard({
    required this.series,
    required this.compostSeries,
    required this.points,
    required this.touchedIndex,
    required this.onTouch,
    required this.isHotel,
  });

  @override
  Widget build(BuildContext context) {
    final totals = List.generate(
      series.length,
      (i) => series[i] + (i < compostSeries.length ? compostSeries[i] : 0),
    );
    final maxV = totals.isEmpty ? 10.0 : totals.reduce(max) + 2;
    const days = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];

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
                        days[v.toInt().clamp(0, days.length - 1)],
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
                  final compost = e.key < compostSeries.length
                      ? compostSeries[e.key]
                      : 0.0;
                  return BarChartGroupData(
                    x: e.key,
                    barRods: [
                      BarChartRodData(
                        toY: e.value + compost,
                        width: 18,
                        borderRadius: BorderRadius.circular(6),
                        rodStackItems: [
                          BarChartRodStackItem(
                            0,
                            e.value,
                            active
                                ? _rPrimary
                                : _rPrimary.withValues(alpha: 0.65),
                          ),
                          BarChartRodStackItem(
                            e.value,
                            e.value + compost,
                            active ? _rDeep : _rDeep.withValues(alpha: 0.78),
                          ),
                        ],
                      ),
                    ],
                  );
                }).toList(),
                barTouchData: BarTouchData(
                  enabled: true,
                  touchCallback: (event, response) {
                    final index = response?.spot?.touchedBarGroupIndex;
                    onTouch(index);
                    if (event is FlTapUpEvent && index != null) {
                      _showWasteDetails(context, index);
                    }
                  },
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

  void _showWasteDetails(BuildContext context, int index) {
    if (index < 0 || index >= points.length) return;
    final point = points[index];
    final zones = point.zoneBreakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormat('EEEE, dd MMM').format(point.date),
                style: GoogleFonts.playfairDisplay(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: _rTextTitle,
                ),
              ),
              const SizedBox(height: 14),
              _DetailLine(
                label: 'Items scanned',
                value: '${point.itemsScanned}',
              ),
              _DetailLine(
                label: 'Waste',
                value: '${point.wasteKg.toStringAsFixed(1)} kg',
              ),
              _DetailLine(
                label: 'Compost',
                value: '${point.compostKg.toStringAsFixed(1)} kg',
              ),
              if (zones.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  'Zone breakdown',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _rTextBody,
                  ),
                ),
                const SizedBox(height: 6),
                ...zones
                    .take(4)
                    .map(
                      (z) => _DetailLine(
                        label: z.key,
                        value: '${z.value.toStringAsFixed(1)} kg',
                      ),
                    ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _DetailLine extends StatelessWidget {
  final String label;
  final String value;

  const _DetailLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(fontSize: 12, color: _rTextMuted),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _rTextTitle,
            ),
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
class _ExpiryTimeline extends StatelessWidget {
  final List<_ExpiryScan> scans;

  const _ExpiryTimeline({required this.scans});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 112,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: scans.length,
        separatorBuilder: (context, index) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final scan = scans[index];
          return Container(
            width: 168,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: scan.color.withValues(alpha: 0.30)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.schedule_rounded, size: 17, color: scan.color),
                    const SizedBox(width: 6),
                    Text(
                      '${scan.hoursLeft.clamp(0, 72)}h left',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: scan.color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 9),
                Text(
                  scan.itemName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _rTextTitle,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  scan.zone,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(fontSize: 11, color: _rTextMuted),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SmartAlertRow extends StatelessWidget {
  final _SmartAlert alert;
  final Future<void> Function() onDismissed;

  const _SmartAlertRow({required this.alert, required this.onDismissed});

  String _timeAgo() {
    final d = DateTime.now().difference(alert.timestamp);
    if (d.inMinutes < 1) return 'Just now';
    if (d.inMinutes < 60) return '${d.inMinutes}min';
    if (d.inHours < 24) return '${d.inHours}h';
    return DateFormat('dd MMM').format(alert.timestamp);
  }

  IconData _icon() {
    final type = alert.type.toLowerCase();
    if (type.contains('expiry')) return Icons.event_busy_rounded;
    if (type.contains('waste')) return Icons.delete_outline_rounded;
    if (type.contains('fresh')) return Icons.eco_rounded;
    return Icons.notifications_active_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final confidence = alert.confidence > 0
        ? '${alert.confidence.toStringAsFixed(0)}%'
        : 'Live';
    return Dismissible(
      key: ValueKey(alert.id),
      direction: DismissDirection.startToEnd,
      background: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        padding: const EdgeInsets.symmetric(horizontal: 18),
        alignment: Alignment.centerLeft,
        decoration: BoxDecoration(
          color: _fresh.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(Icons.check_rounded, color: _fresh),
      ),
      onDismissed: (_) => onDismissed(),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _rSoftBg),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: _danger.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_icon(), color: _danger, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    alert.itemName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _rTextTitle,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${alert.zone} - ${_timeAgo()} - $confidence',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(fontSize: 11, color: _rTextMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              alert.severity.toUpperCase(),
              style: GoogleFonts.inter(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: _danger,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
