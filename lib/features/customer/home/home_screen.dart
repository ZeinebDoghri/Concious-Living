import 'dart:math';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:provider/provider.dart';

import '../../../core/constants.dart';
import '../../../core/models/scan_history_item.dart';
import '../../../providers/alerts_provider.dart';
import '../../../providers/scan_history_provider.dart';
import '../../../providers/user_provider.dart';

// ── Customer design tokens ─────────────────────────────────────────────────────
const _kPrimary = Color(0xFFA78BFA);
const _kDeep = Color(0xFF7C3AED);
const _kSurface = Color(0xFFF5F3FF);
const _kSoftBg = Color(0xFFEDE9FE);
const _kLilac = Color(0xFFF3F0FF);
const _kTextTitle = Color(0xFF2D1B69);
const _kTextBody = Color(0xFF4B3B8C);
const _kTextMuted = Color(0xFF8B7BC0);
const _kBlob1 = Color(0xFFC4B5FD);
const _kFresh = Color(0xFF52C98A);
const _kWarning = Color(0xFFFFAB5B);
const _kDanger = Color(0xFFFF7070);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late final AnimationController _enterController;
  late final AnimationController _motionController;

  @override
  void initState() {
    super.initState();
    _enterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _motionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5200),
    )..repeat();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<UserProvider>().refreshCurrentUserFromDatabase(
        expectedRole: 'customer',
      );
    });
  }

  @override
  void dispose() {
    _enterController.dispose();
    _motionController.dispose();
    super.dispose();
  }

  // ── Pure logic helpers (unchanged) ────────────────────────────────────────

  String _greetingForHour(int hour) {
    if (hour < 12) return 'Good morning,';
    if (hour < 18) return 'Good afternoon,';
    return 'Good evening,';
  }

  double _overallDailyPct(Map<String, double> values) {
    if (values.isEmpty) return 0;
    final sum = values.values.fold<double>(0, (a, b) => a + b);
    return (sum / values.length).clamp(0, 130);
  }

  Color _progressColor(double value) {
    if (value > 100) return _kDanger;
    if (value >= 80) return _kWarning;
    return _kFresh;
  }

  String _serviceLabel(DateTime now) {
    final hour = now.hour;
    if (hour < 10) return 'Breakfast service';
    if (hour < 15) return 'Lunch service';
    if (hour < 19) return 'Afternoon service';
    return 'Dinner service';
  }

  List<double> _goalProgresses(UserProvider provider, double overall) {
    final goalSeed = provider.currentUser?.calorieGoal.toDouble() ?? 2200;
    final offset = ((goalSeed / 2200) * 10).clamp(0, 12);
    final calories = overall.clamp(0.0, 130.0).toDouble();
    final carbs = (overall + 6 + offset * 0.15).clamp(0.0, 130.0).toDouble();
    final fats = (overall - 4 + offset * 0.1).clamp(0.0, 130.0).toDouble();
    final proteins = (overall + 2 - offset * 0.08).clamp(0.0, 130.0).toDouble();
    return [calories, carbs, fats, proteins];
  }

  List<_AlertCardData> _alertCards(List<double> progresses) {
    final data = <_AlertCardData>[];
    final names = ['Calories', 'Carbs', 'Fats', 'Proteins'];
    for (var i = 0; i < progresses.length; i++) {
      final value = progresses[i];
      if (value > 100) {
        data.add(
          _AlertCardData(
            icon: Icons.error_outline,
            title: '${names[i]} exceeded',
            subtitle: 'You are over your target for today.',
            color: _kDanger,
          ),
        );
      } else if (value >= 80) {
        data.add(
          _AlertCardData(
            icon: Icons.info_outline,
            title: '${names[i]} approaching limit',
            subtitle: 'You are close to your daily goal.',
            color: _kWarning,
          ),
        );
      } else {
        data.add(
          _AlertCardData(
            icon: Icons.check_circle_outline,
            title: '${names[i]} on track',
            subtitle: 'Nice work keeping this in range.',
            color: _kFresh,
          ),
        );
      }
    }
    return data;
  }

  List<String> _tipsFor(UserProvider provider) {
    final dietary =
        provider.currentUser?.dietaryOptions
            .map((e) => e.trim().toLowerCase())
            .where((e) => e.isNotEmpty)
            .toList(growable: false) ??
        const <String>[];
    final hasKeto = dietary.any((e) => e.contains('keto'));
    final hasVegetarian = dietary.any((e) => e.contains('vegetarian'));
    final hasVegan = dietary.any((e) => e.contains('vegan'));

    if (hasKeto) {
      return const [
        'Choose lean proteins with low-carb vegetables to keep meals balanced.',
        'Watch sauces and dressings — hidden carbs add up quickly.',
        'Prioritize hydration so hunger signals stay clear between meals.',
        'Pair fats with fibre-rich sides to stay full without overshooting.',
        'Plan your next meal before you get hungry to avoid convenience picks.',
        'Keep snacks simple: eggs, nuts, seeds, or plain yogurt.',
        'Batch-prep proteins early in the week to make better choices easier.',
        'Scan mixed dishes carefully — carbs hide in grains and breading.',
        'Build each plate around protein first, then add volume with vegetables.',
        'If you are training, time carbs around the most active parts of your day.',
      ];
    }
    if (hasVegetarian || hasVegan) {
      return const [
        'Rotate legumes, tofu, tempeh, and seeds so protein stays diverse.',
        'Add vitamin C-rich produce to plant meals to improve iron absorption.',
        'Use nuts and avocado in small portions to keep meals satisfying.',
        'Look for whole grains and beans together for more complete nutrition.',
        'Keep a simple protein fallback ready for busy days: yogurt or edamame.',
        'Balance lunch and dinner so you do not rely on late snacks for protein.',
        'Check labels for added sugar in plant-based sauces and snacks.',
        'Hydrate first if you feel tired — dehydration mimics hunger.',
        'Build meals with colour first, then add a dependable protein source.',
        'Use leftovers early in the week to reduce waste and decision fatigue.',
      ];
    }
    return const [
      'Scan your next meal before eating so you can adjust portions early.',
      'Keep water visible to make hydration automatic.',
      'Use half-plate vegetables to reduce energy density.',
      'Try eating at consistent times to make hunger easier to predict.',
      'Choose one item to improve today rather than changing the whole meal.',
      'Leftovers are better than waste — plan smaller servings if unsure.',
      'If a dish looks heavy, balance it with a lighter snack later.',
      'A short walk after meals can help you notice fullness sooner.',
      'Check the highest-risk nutrient first when reviewing a scan result.',
      'Progress compounds when you repeat small, simple choices every day.',
    ];
  }

  Color _weekColor(int value) {
    if (value >= 3) return _kDanger;
    if (value == 2) return _kWarning;
    return _kFresh;
  }

  List<int> _weeklyCounts(List<ScanHistoryItem> items) {
    final now = DateTime.now();
    return List<int>.generate(7, (index) {
      final day = DateTime(now.year, now.month, now.day - (6 - index));
      return items.where((item) {
        final dt = item.scannedAt;
        return dt.year == day.year &&
            dt.month == day.month &&
            dt.day == day.day;
      }).length;
    });
  }

  String _averageRiskLabel(double overall) {
    if (overall > 100) return 'High';
    if (overall >= 80) return 'Moderate';
    return 'Low';
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final scanProvider = context.watch<ScanHistoryProvider>();
    final alertsProvider = context.watch<AlertsProvider>();

    final user = userProvider.currentUser;
    final rawName = user?.role == 'customer' ? (user?.name ?? '').trim() : '';
    final name = rawName.isEmpty ? 'Customer' : rawName;
    final greeting = _greetingForHour(DateTime.now().hour);
    final now = DateTime.now();
    final dateText = DateFormat('EEE, MMM d').format(now);
    final serviceText = _serviceLabel(now);

    final intakePct = userProvider.mockDailyIntakePct;
    final overall = _overallDailyPct(intakePct);
    final progresses = _goalProgresses(userProvider, overall);
    final alertCards = _alertCards(progresses);

    final scans = scanProvider.items.toList()
      ..sort((a, b) => b.scannedAt.compareTo(a.scannedAt));
    final recentScans = scans.take(3).toList(growable: false);
    final weeklyCounts = _weeklyCounts(scans);
    final totalWeeklyScans = weeklyCounts.fold<int>(0, (a, b) => a + b);
    final goalsMet = progresses.where((v) => v <= 100).length;
    final averageRisk = _averageRiskLabel(overall);
    final healthScore = (100 - (overall - 60).clamp(0, 40)).round();
    final allergens = user?.allergens ?? [];

    final headerStats = [
      '${scanProvider.items.length} scans',
      '${alertsProvider.pendingCount} alerts',
      '${overall.round()}% goals',
    ];

    final tipPool = _tipsFor(userProvider);
    final tip = tipPool[now.day % tipPool.length];
    final tipTitle =
        userProvider.currentUser?.dietaryOptions.any(
              (e) => e.trim().toLowerCase().contains('keto'),
            ) ==
            true
        ? 'Keep carbs deliberate'
        : userProvider.currentUser?.dietaryOptions.any(
                (e) =>
                    e.trim().toLowerCase().contains('vegetarian') ||
                    e.trim().toLowerCase().contains('vegan'),
              ) ==
              true
        ? 'Build better plant protein'
        : 'Reduce waste before it starts';

    return Scaffold(
      backgroundColor: _kSurface,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Hero Header ─────────────────────────────────────────────────
            Stack(
              children: [
                Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFF7C3AED),
                        Color(0xFFA78BFA),
                        Color(0xFFC4B5FD),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(32),
                      bottomRight: Radius.circular(32),
                    ),
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Top row: greeting + health ring
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      greeting,
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        color: Colors.white.withValues(
                                          alpha: 0.75,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      name,
                                      style: GoogleFonts.playfairDisplay(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '$dateText · $serviceText',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: Colors.white.withValues(
                                          alpha: 0.65,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              _HealthScoreRing(score: healthScore),
                            ],
                          ),
                          const SizedBox(height: 20),
                          // Quick stats chips
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: headerStats
                                .map(
                                  (stat) => Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: 0.18,
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: Colors.white.withValues(
                                          alpha: 0.25,
                                        ),
                                        width: 0.8,
                                      ),
                                    ),
                                    child: Text(
                                      stat,
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(growable: false),
                          ),
                          // Allergen quick-chips
                          if (allergens.isNotEmpty) ...[
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                const Icon(
                                  Icons.warning_amber_rounded,
                                  color: Color(0xFFFFE566),
                                  size: 14,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  'Active allergens:',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFFFFE566),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: allergens
                                  .take(5)
                                  .map(
                                    (a) => Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(
                                          alpha: 0.15,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.white.withValues(
                                            alpha: 0.35,
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        a,
                                        style: GoogleFonts.inter(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(growable: false),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                // Blob decoration
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(32),
                      bottomRight: Radius.circular(32),
                    ),
                    child: IgnorePointer(
                      child: AnimatedBuilder(
                        animation: _motionController,
                        builder: (_, _) => CustomPaint(
                          painter: _BlobPainter(
                            _motionController.value,
                            _kBlob1,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // ── Quick Scan CTA ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: _ScanBanner(
                onTap: () => context.go(AppRoutes.customerScan),
              ),
            ),

            // ── Macro progress grid ─────────────────────────────────────────
            _SectionTitle(
              title: "Today's nutrition",
              actionLabel: 'Details',
              onTap: () => context.go(AppRoutes.nutritionProgress),
            ),
            _PastelCard(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1.05,
                    children: List.generate(4, (index) {
                      final labels = const [
                        'Calories',
                        'Carbs',
                        'Fats',
                        'Proteins',
                      ];
                      final icons = const [
                        Icons.local_fire_department_rounded,
                        Icons.grain_rounded,
                        Icons.water_drop_rounded,
                        Icons.fitness_center_rounded,
                      ];
                      final value = progresses[index];
                      return _ProgressTile(
                        label: labels[index],
                        icon: icons[index],
                        value: value,
                        color: _progressColor(value),
                      );
                    }),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () => context.go(AppRoutes.customerScan),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      decoration: BoxDecoration(
                        color: _kSoftBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _kPrimary.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '＋  Scan your next meal to update',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _kPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Alerts ───────────────────────────────────────────────────────
            if (alertCards.isNotEmpty) ...[
              _SectionTitle(
                title: 'Your alerts',
                actionLabel: 'See all',
                onTap: () => context.go(AppRoutes.nutritionProgress),
              ),
              SizedBox(
                height: 90,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: alertCards.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 10),
                  itemBuilder: (context, index) =>
                      _AlertCard(data: alertCards[index]),
                ),
              ),
            ],

            // ── Quick actions ───────────────────────────────────────────────
            _SectionTitle(
              title: 'Quick actions',
              actionLabel: null,
              onTap: null,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: _QuickAction(
                      icon: Icons.flag_outlined,
                      label: 'Goals',
                      onTap: () => context.go(AppRoutes.nutritionGoals),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _QuickAction(
                      icon: Icons.ramen_dining,
                      label: 'Allergens',
                      onTap: () => context.go(AppRoutes.customerAllergens),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _QuickAction(
                      icon: Icons.insights_outlined,
                      label: 'Progress',
                      onTap: () => context.go(AppRoutes.nutritionProgress),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _QuickAction(
                      icon: Icons.history,
                      label: 'History',
                      onTap: () => context.go(AppRoutes.customerHistory),
                    ),
                  ),
                ],
              ),
            ),

            // ── Today's tip ──────────────────────────────────────────────────
            const SizedBox(height: 8),
            _SectionTitle(title: "Today's tip", actionLabel: null, onTap: null),
            _TipCard(title: tipTitle, body: tip),

            // ── Recent scans ────────────────────────────────────────────────
            _SectionTitle(
              title: 'Recent scans',
              actionLabel: 'See all',
              onTap: () => context.go(AppRoutes.customerHistory),
            ),
            if (recentScans.isEmpty)
              _PastelCard(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Text(
                  AppStrings.noScansSubtitle,
                  style: GoogleFonts.inter(fontSize: 13, color: _kTextMuted),
                ),
              )
            else
              Column(
                children: List.generate(recentScans.length, (index) {
                  final scan = recentScans[index];
                  return _StaggerIn(
                    controller: _enterController,
                    index: index,
                    child: _RecentScanTile(
                      item: scan,
                      onTap: () =>
                          context.go(AppRoutes.customerHistoryDetail(scan.id)),
                    ),
                  );
                }),
              ),

            // ── Weekly summary ──────────────────────────────────────────────
            _SectionTitle(title: 'This week', actionLabel: null, onTap: null),
            _PastelCard(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _MetricPill(
                        label: '$totalWeeklyScans dishes scanned',
                        good: totalWeeklyScans >= 4,
                      ),
                      _MetricPill(
                        label: 'Avg risk: $averageRisk',
                        good: averageRisk == 'Low',
                      ),
                      _MetricPill(
                        label: '$goalsMet goals met',
                        good: goalsMet >= 3,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 64,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: List.generate(7, (index) {
                        final labels = const [
                          'M',
                          'T',
                          'W',
                          'T',
                          'F',
                          'S',
                          'S',
                        ];
                        final count = weeklyCounts[index];
                        final barH = min(
                          44.0,
                          max(6.0, count == 0 ? 6.0 : count * 10.0),
                        );
                        final color = _weekColor(count);
                        return Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              AnimatedBuilder(
                                animation: _motionController,
                                builder: (_, _) {
                                  final wave = math.sin(
                                    _motionController.value * 2 * math.pi +
                                        index * 0.8,
                                  );
                                  return AnimatedContainer(
                                    duration: Duration(
                                      milliseconds: 260 + index * 45,
                                    ),
                                    curve: Curves.easeOutCubic,
                                    height: (barH + wave * 5).clamp(6.0, 50.0),
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: color.withValues(
                                        alpha: 0.72 + (wave + 1) * 0.10,
                                      ),
                                      borderRadius: BorderRadius.circular(6),
                                      boxShadow: [
                                        BoxShadow(
                                          color: color.withValues(alpha: 0.3),
                                          blurRadius: 6 + (wave + 1) * 2,
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 5),
                              Text(
                                labels[index],
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  color: _kTextMuted,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 120),
          ],
        ),
      ),
    );
  }
}

// ── Blob painter ───────────────────────────────────────────────────────────────
class _BlobPainter extends CustomPainter {
  final double t;
  final Color c;
  _BlobPainter(this.t, this.c);

  @override
  void paint(Canvas canvas, Size size) {
    final a = t * 2 * math.pi;
    final p1 = Offset(
      size.width * 0.2 + math.cos(a) * 25,
      size.height * 0.25 + math.sin(a) * 18,
    );
    canvas.drawCircle(
      p1,
      size.width * 0.4,
      Paint()
        ..shader = RadialGradient(
          colors: [c.withValues(alpha: 0.10), Colors.transparent],
        ).createShader(Rect.fromCircle(center: p1, radius: size.width * 0.4)),
    );
    final p2 = Offset(
      size.width * 0.8 + math.sin(a * 0.7) * 20,
      size.height * 0.65 + math.cos(a * 0.7) * 25,
    );
    canvas.drawCircle(
      p2,
      size.width * 0.35,
      Paint()
        ..shader = RadialGradient(
          colors: [c.withValues(alpha: 0.07), Colors.transparent],
        ).createShader(Rect.fromCircle(center: p2, radius: size.width * 0.35)),
    );
  }

  @override
  bool shouldRepaint(_BlobPainter o) => o.t != t;
}

// ── Health Score Ring ──────────────────────────────────────────────────────────
class _HealthScoreRing extends StatelessWidget {
  final int score;
  const _HealthScoreRing({required this.score});

  Color get _color {
    if (score >= 80) return _kFresh;
    if (score >= 60) return _kWarning;
    return _kDanger;
  }

  String get _label {
    if (score >= 80) return 'Excellent';
    if (score >= 60) return 'Good';
    return 'Watch out';
  }

  @override
  Widget build(BuildContext context) {
    final pct = (score / 100).clamp(0.0, 1.0);
    return Column(
      children: [
        CircularPercentIndicator(
          radius: 38,
          lineWidth: 5,
          percent: pct,
          circularStrokeCap: CircularStrokeCap.round,
          backgroundColor: Colors.white.withValues(alpha: 0.20),
          progressColor: _color,
          center: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$score',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  height: 1,
                ),
              ),
              Text(
                '/100',
                style: GoogleFonts.inter(
                  fontSize: 9,
                  color: Colors.white.withValues(alpha: 0.65),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 5),
        Text(
          _label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: _color,
          ),
        ),
      ],
    );
  }
}

// ── Section title ──────────────────────────────────────────────────────────────
class _SectionTitle extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onTap;

  const _SectionTitle({
    required this.title,
    required this.actionLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.playfairDisplay(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: _kTextTitle,
              ),
            ),
          ),
          if (actionLabel != null && onTap != null)
            GestureDetector(
              onTap: onTap,
              child: Text(
                actionLabel!,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _kPrimary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Pastel card shell ──────────────────────────────────────────────────────────
class _PastelCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry margin;

  const _PastelCard({required this.child, required this.margin});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: margin,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadii.innerCard),
        boxShadow: AppShadows.sm(_kPrimary),
      ),
      child: child,
    );
  }
}

// ── Progress tile ──────────────────────────────────────────────────────────────
class _ProgressTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final double   value;
  final Color    color;

  const _ProgressTile({
    required this.label,
    required this.icon,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (value / 100).clamp(0.0, 1.0);
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularPercentIndicator(
            radius: 36,
            lineWidth: 5,
            percent: pct,
            circularStrokeCap: CircularStrokeCap.round,
            backgroundColor: _kSoftBg,
            progressColor: color,
            center: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 14),
                const SizedBox(height: 2),
                Text(
                  '${value.round()}%',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: _kTextTitle,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: _kTextMuted,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Scan banner ────────────────────────────────────────────────────────────────
class _ScanBanner extends StatefulWidget {
  final VoidCallback onTap;
  const _ScanBanner({required this.onTap});

  @override
  State<_ScanBanner> createState() => _ScanBannerState();
}

class _ScanBannerState extends State<_ScanBanner>
    with SingleTickerProviderStateMixin {
  bool _pressed = false;
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
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
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1,
        duration: const Duration(milliseconds: 120),
        child: AnimatedBuilder(
          animation: _pulse,
          builder: (_, child) => Container(
            height: 80,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF7C3AED), Color(0xFFA78BFA)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppRadii.xl),
              border: Border.all(
                color: _kPrimary.withValues(alpha: 0.35 + _pulse.value * 0.15),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: _kPrimary.withValues(alpha: 0.2 + _pulse.value * 0.12),
                  blurRadius: 18 + _pulse.value * 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: child,
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.camera_alt_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Scan a dish',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Calories · Allergens · Chronic risk',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Alert card data ────────────────────────────────────────────────────────────
class _AlertCardData {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _AlertCardData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });
}

// ── Alert card ─────────────────────────────────────────────────────────────────
class _AlertCard extends StatelessWidget {
  final _AlertCardData data;
  const _AlertCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: _kSoftBg, width: 1),
        boxShadow: AppShadows.sm(_kPrimary),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: data.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(data.icon, color: data.color, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.title,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _kTextTitle,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  data.subtitle,
                  style: GoogleFonts.inter(fontSize: 11, color: _kTextMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Quick action ───────────────────────────────────────────────────────────────
class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.md),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadii.md),
          boxShadow: AppShadows.sm(_kPrimary),
        ),
        child: Column(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _kSoftBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: _kPrimary, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _kTextBody,
                height: 1.15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Tip card ───────────────────────────────────────────────────────────────────
class _TipCard extends StatelessWidget {
  final String title;
  final String body;

  const _TipCard({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    // AI insight pill spec: darkest primary bg, ✦ star, primaryLight text
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_kSoftBg, _kLilac],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadii.innerCard),
        border: Border.all(color: _kPrimary.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _kPrimary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lightbulb_outline,
              color: _kPrimary,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: _kPrimary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    "Today's tip",
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: _kDeep,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  title,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _kTextTitle,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  body,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: _kTextBody,
                    height: 1.4,
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

// ── Recent scan tile ───────────────────────────────────────────────────────────
class _RecentScanTile extends StatelessWidget {
  final ScanHistoryItem item;
  final VoidCallback onTap;

  const _RecentScanTile({required this.item, required this.onTap});

  Color _riskDotColor(double pct) {
    if (pct > 100) return _kDanger;
    if (pct >= 80) return _kWarning;
    return _kFresh;
  }

  String _riskLabel(double pct) {
    if (pct > 100) return 'High risk';
    if (pct >= 80) return 'Moderate';
    return 'Low risk';
  }

  @override
  Widget build(BuildContext context) {
    final result = item.result;
    final values = [
      result.cholesterol.dailyValuePct,
      result.saturatedFat.dailyValuePct,
      result.sodium.dailyValuePct,
      result.sugar.dailyValuePct,
    ];
    final avg = values.fold<double>(0, (a, b) => a + b) / values.length;
    final color = _riskDotColor(avg);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.innerCard),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadii.innerCard),
            boxShadow: AppShadows.sm(_kPrimary),
          ),
          child: Row(
            children: [
              // Icon thumb — follows item card spec: 36×36, surfaceTint bg, radiusThumb 12
              Hero(
                tag: 'dish-${item.id}',
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: color.withValues(alpha: 0.25)),
                  ),
                  child: Icon(Icons.restaurant_menu, color: color, size: 22),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.dishName,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _kTextTitle,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      ScanHistoryItem.timeAgo(item.scannedAt),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: _kTextMuted,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: values
                          .map(
                            (v) => Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.only(right: 5),
                              decoration: BoxDecoration(
                                color: _riskDotColor(v),
                                shape: BoxShape.circle,
                              ),
                            ),
                          )
                          .toList(growable: false),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _RiskBadge(text: _riskLabel(avg), color: color),
                  const SizedBox(height: 12),
                  Icon(
                    Icons.chevron_right,
                    color: _kTextMuted.withValues(alpha: 0.5),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RiskBadge extends StatelessWidget {
  final String text;
  final Color color;

  const _RiskBadge({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.25), width: 0.5),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }
}

// ── Metric pill ────────────────────────────────────────────────────────────────
class _MetricPill extends StatelessWidget {
  final String label;
  final bool good;

  const _MetricPill({required this.label, required this.good});

  @override
  Widget build(BuildContext context) {
    final color = good ? _kFresh : _kDanger;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }
}

// ── Stagger-in (unchanged logic) ───────────────────────────────────────────────
class _StaggerIn extends StatelessWidget {
  final AnimationController controller;
  final int index;
  final Widget child;

  const _StaggerIn({
    required this.controller,
    required this.index,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final start = (0.06 * index).clamp(0.0, 0.8);
    final curve = CurvedAnimation(
      parent: controller,
      curve: Interval(start, 1, curve: Curves.easeOutCubic),
    );
    return FadeTransition(
      opacity: curve,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.06),
          end: Offset.zero,
        ).animate(curve),
        child: child,
      ),
    );
  }
}