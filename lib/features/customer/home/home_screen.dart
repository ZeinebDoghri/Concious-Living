import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
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

// ── FreshGuard Customer design tokens ─────────────────────────────────────────
const _kPrimary       = Color(0xFF5B4E8A); // violet primary
const _kPrimaryDark   = Color(0xFF2D2350); // hero plate / AI pill bg
const _kPrimaryLight  = Color(0xFFC4B8F0); // light accent
const _kHeroCircle1   = Color(0xFF6E60A0); // large decorative circle
const _kHeroCircle2   = Color(0xFF4A3D78); // small decorative circle
const _kSurface       = Color(0xFFF4F2FA); // screen / card bg
const _kSurfaceTint   = Color(0xFFEDE9F7); // stat card / field bg
const _kFieldBorder   = Color(0xFFC8C0E8); // borders / dividers
const _kTextPrimary   = Color(0xFF2D2350); // main text
const _kTextSecondary = Color(0xFFA090C0); // captions / subtitles
// Shared semantic
const _kFreshGreen    = Color(0xFF2E8B69);
const _kWarningAmber  = Color(0xFFE8872A);
const _kDangerRed     = Color(0xFFE24B4A);

// ─────────────────────────────────────────────────────────────────────────────

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
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

  // ── Pure logic helpers (unchanged) ────────────────────────────────────────

  String _greetingForHour(int hour) {
    if (hour < 12) return 'Good morning,';
    if (hour < 18) return 'Good afternoon,';
    return 'Good evening,';
  }

  String _initials(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    final parts = trimmed.split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    String firstChar(String s) {
      final t = s.trim();
      return t.isEmpty ? '' : t.substring(0, 1).toUpperCase();
    }
    return (firstChar(parts.first) +
            (parts.length > 1 ? firstChar(parts[1]) : ''))
        .trim();
  }

  double _overallDailyPct(Map<String, double> values) {
    if (values.isEmpty) return 0;
    final sum = values.values.fold<double>(0, (a, b) => a + b);
    return (sum / values.length).clamp(0, 130);
  }

  Color _progressColor(double value) {
    if (value > 100) return _kDangerRed;
    if (value >= 80) return _kWarningAmber;
    return _kFreshGreen;
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
    final offset   = ((goalSeed / 2200) * 10).clamp(0, 12);
    final calories  = overall.clamp(0.0, 130.0).toDouble();
    final carbs     = (overall + 6 + offset * 0.15).clamp(0.0, 130.0).toDouble();
    final fats      = (overall - 4 + offset * 0.1).clamp(0.0, 130.0).toDouble();
    final proteins  = (overall + 2 - offset * 0.08).clamp(0.0, 130.0).toDouble();
    return [calories, carbs, fats, proteins];
  }

  List<_AlertCardData> _alertCards(List<double> progresses) {
    final data  = <_AlertCardData>[];
    final names = ['Calories', 'Carbs', 'Fats', 'Proteins'];
    for (var i = 0; i < progresses.length; i++) {
      final value = progresses[i];
      if (value > 100) {
        data.add(_AlertCardData(
          icon: Icons.error_outline,
          title: '${names[i]} exceeded',
          subtitle: 'You are over your target for today.',
          color: _kDangerRed,
        ));
      } else if (value >= 80) {
        data.add(_AlertCardData(
          icon: Icons.info_outline,
          title: '${names[i]} approaching limit',
          subtitle: 'You are close to your daily goal.',
          color: _kWarningAmber,
        ));
      } else {
        data.add(_AlertCardData(
          icon: Icons.check_circle_outline,
          title: '${names[i]} on track',
          subtitle: 'Nice work keeping this in range.',
          color: _kFreshGreen,
        ));
      }
    }
    return data;
  }

  List<String> _tipsFor(UserProvider provider) {
    final dietary = provider.currentUser?.dietaryOptions
            .map((e) => e.trim().toLowerCase())
            .where((e) => e.isNotEmpty)
            .toList(growable: false) ??
        const <String>[];
    final hasKeto       = dietary.any((e) => e.contains('keto'));
    final hasVegetarian = dietary.any((e) => e.contains('vegetarian'));
    final hasVegan      = dietary.any((e) => e.contains('vegan'));

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

  Color _weekBarColor(int value) {
    if (value >= 3) return _kDangerRed;
    if (value == 2) return _kWarningAmber;
    return _kFreshGreen;
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
    final userProvider   = context.watch<UserProvider>();
    final scanProvider   = context.watch<ScanHistoryProvider>();
    final alertsProvider = context.watch<AlertsProvider>();

    final user        = userProvider.currentUser;
    final rawName     = (user?.name ?? '').trim();
    final name        = rawName.isEmpty ? AppStrings.appName : rawName;
    final greeting    = _greetingForHour(DateTime.now().hour);
    final now         = DateTime.now();
    final dateText    = DateFormat('EEE, MMM d').format(now);
    final serviceText = _serviceLabel(now);

    final intakePct  = userProvider.mockDailyIntakePct;
    final overall    = _overallDailyPct(intakePct);
    final progresses = _goalProgresses(userProvider, overall);
    final alertCards = _alertCards(progresses);

    final scans = scanProvider.items.toList()
      ..sort((a, b) => b.scannedAt.compareTo(a.scannedAt));
    final recentScans      = scans.take(3).toList(growable: false);
    final weeklyCounts     = _weeklyCounts(scans);
    final totalWeeklyScans = weeklyCounts.fold<int>(0, (a, b) => a + b);
    final goalsMet         = progresses.where((v) => v <= 100).length;
    final averageRisk      = _averageRiskLabel(overall);
    final healthScore      = (100 - (overall - 60).clamp(0, 40)).round();
    final allergens        = user?.conditions ?? [];

    final headerStats = [
      '${scanProvider.items.length} scans',
      '${alertsProvider.pendingCount} alerts',
      '${overall.round()}% goals',
    ];

    final tipPool  = _tipsFor(userProvider);
    final tip      = tipPool[now.day % tipPool.length];
    final tipTitle = userProvider.currentUser?.dietaryOptions
                    .any((e) => e.trim().toLowerCase().contains('keto')) == true
        ? 'Keep carbs deliberate'
        : userProvider.currentUser?.dietaryOptions.any((e) =>
                  e.trim().toLowerCase().contains('vegetarian') ||
                  e.trim().toLowerCase().contains('vegan')) == true
            ? 'Build better plant protein'
            : 'Reduce waste before it starts';

    return Scaffold(
      backgroundColor: _kSurface,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Hero header ──────────────────────────────────────────────────
            _FGHero(
              greeting:     greeting,
              name:         name,
              dateText:     dateText,
              serviceText:  serviceText,
              healthScore:  healthScore,
              headerStats:  headerStats,
              allergens:    allergens,
            ),

            // ── Today's nutrition ────────────────────────────────────────────
            _FGSectionTitle(
              title: "Today's nutrition",
              actionLabel: 'Details',
              onTap: () => context.go(AppRoutes.nutritionProgress),
            ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.06, delay: 100.ms),

            _FGCardShell(
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
                      final labels = const ['Calories', 'Carbs', 'Fats', 'Proteins'];
                      final icons  = const [
                        Icons.local_fire_department_rounded,
                        Icons.grain_rounded,
                        Icons.water_drop_rounded,
                        Icons.fitness_center_rounded,
                      ];
                      final value = progresses[index];
                      return _FGProgressTile(
                        label: labels[index],
                        icon:  icons[index],
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
                        color: _kPrimary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _kPrimary.withOpacity(0.25)),
                      ),
                      child: Center(
                        child: Text(
                          '＋  Scan your next meal to update',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: _kPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Scan CTA banner ──────────────────────────────────────────────
            _FGScanBanner(onTap: () => context.go(AppRoutes.customerScan))
                .animate()
                .fadeIn(delay: 300.ms)
                .scale(
                  begin: const Offset(0.95, 0.95),
                  delay: 300.ms,
                  curve: Curves.easeOutBack,
                ),

            // ── Alerts ───────────────────────────────────────────────────────
            if (alertCards.isNotEmpty) ...[
              _FGSectionTitle(
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
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, index) =>
                      _FGAlertCard(data: alertCards[index]),
                ),
              ),
            ],

            // ── Quick actions ────────────────────────────────────────────────
            _FGSectionTitle(title: 'Quick actions', actionLabel: null, onTap: null),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: _FGQuickAction(
                      icon:  Icons.flag_outlined,
                      color: _kFreshGreen,
                      label: 'Goals',
                      onTap: () => context.go(AppRoutes.nutritionGoals),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _FGQuickAction(
                      icon:  Icons.ramen_dining,
                      color: _kWarningAmber,
                      label: 'Allergens',
                      onTap: () => context.go(AppRoutes.customerAllergens),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _FGQuickAction(
                      icon:  Icons.insights_outlined,
                      color: _kPrimary,
                      label: 'Progress',
                      onTap: () => context.go(AppRoutes.nutritionProgress),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _FGQuickAction(
                      icon:  Icons.history,
                      color: _kTextSecondary,
                      label: 'History',
                      onTap: () => context.go(AppRoutes.customerHistory),
                    ),
                  ),
                ],
              ),
            ),

            // ── Today's tip ──────────────────────────────────────────────────
            const SizedBox(height: 8),
            _FGSectionTitle(title: "Today's tip", actionLabel: null, onTap: null),
            _FGTipCard(title: tipTitle, body: tip),

            // ── Recent scans ─────────────────────────────────────────────────
            _FGSectionTitle(
              title: 'Recent scans',
              actionLabel: 'See all',
              onTap: () => context.go(AppRoutes.customerHistory),
            ),
            if (recentScans.isEmpty)
              _FGCardShell(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Text(
                  AppStrings.noScansSubtitle,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: _kTextSecondary,
                  ),
                ),
              )
            else
              Column(
                children: List.generate(recentScans.length, (index) {
                  final scan = recentScans[index];
                  return _StaggerIn(
                    controller: _enterController,
                    index: index,
                    child: _FGRecentScanTile(
                      item:  scan,
                      onTap: () => context.go(
                          AppRoutes.customerHistoryDetail(scan.id)),
                    ),
                  );
                }),
              ),

            // ── Weekly summary ────────────────────────────────────────────────
            _FGSectionTitle(title: 'This week', actionLabel: null, onTap: null),
            _FGCardShell(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _FGMetricPill(
                        label: '$totalWeeklyScans dishes scanned',
                        good:  totalWeeklyScans >= 4,
                      ),
                      _FGMetricPill(
                        label: 'Avg risk: $averageRisk',
                        good:  averageRisk == 'Low',
                      ),
                      _FGMetricPill(
                        label: '$goalsMet goals met',
                        good:  goalsMet >= 3,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 64,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: List.generate(7, (index) {
                        final labels = const ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                        final count  = weeklyCounts[index];
                        final barH   =
                            min(44.0, max(6.0, count == 0 ? 6.0 : count * 10.0));
                        final color  = _weekBarColor(count);
                        return Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              AnimatedContainer(
                                duration:
                                    Duration(milliseconds: 300 + index * 60),
                                curve: Curves.easeOutCubic,
                                height: barH,
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.85),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                labels[index],
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  color: _kTextSecondary,
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

// ═══════════════════════════════════════════════════════════════════════════════
// DESIGN COMPONENTS — FreshGuard Customer theme
// ═══════════════════════════════════════════════════════════════════════════════

// ── Hero ───────────────────────────────────────────────────────────────────────
class _FGHero extends StatelessWidget {
  final String       greeting;
  final String       name;
  final String       dateText;
  final String       serviceText;
  final int          healthScore;
  final List<String> headerStats;
  final List<String> allergens;

  const _FGHero({
    required this.greeting,
    required this.name,
    required this.dateText,
    required this.serviceText,
    required this.healthScore,
    required this.headerStats,
    required this.allergens,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          // Solid primary background
          Positioned.fill(child: Container(color: _kPrimary)),

          // Decorative circle 1 — large, top-right
          Positioned(
            top: -50,
            right: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _kHeroCircle1.withOpacity(0.25),
              ),
            ),
          ),

          // Decorative circle 2 — small, bottom-left
          Positioned(
            bottom: 20,
            left: -20,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _kHeroCircle2.withOpacity(0.20),
              ),
            ),
          ),

          // Food plate circle — bleeds off bottom-right
          Positioned(
            right: -14,
            bottom: -20,
            child: Container(
              width: 150,
              height: 150,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: _kPrimaryDark,
              ),
              child: const Center(
                child: Text('🥗', style: TextStyle(fontSize: 60)),
              ),
            ),
          ),

          // Content
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Greeting row + health ring
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'AI FOOD SAFETY',
                              style: GoogleFonts.inter(
                                fontSize: 9,
                                color: Colors.white70,
                                letterSpacing: 1.0,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              greeting,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: Colors.white.withOpacity(0.70),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              name,
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 24,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                height: 1.1,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$dateText · $serviceText',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: Colors.white.withOpacity(0.55),
                              ),
                            ),
                          ],
                        ),
                      ),
                      _FGHealthRing(score: healthScore),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Quick stat chips
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: headerStats
                        .map((stat) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.20),
                                  width: 0.5,
                                ),
                              ),
                              child: Text(
                                stat,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white.withOpacity(0.90),
                                ),
                              ),
                            ))
                        .toList(growable: false),
                  ),

                  // Allergen chips
                  if (allergens.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded,
                            color: _kWarningAmber, size: 13),
                        const SizedBox(width: 5),
                        Text(
                          'Active allergens:',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: _kWarningAmber,
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
                          .map((a) => Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _kWarningAmber.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                      color: _kWarningAmber.withOpacity(0.35)),
                                ),
                                child: Text(
                                  a,
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                    color: _kWarningAmber,
                                  ),
                                ),
                              ))
                          .toList(growable: false),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Health score ring ──────────────────────────────────────────────────────────
class _FGHealthRing extends StatelessWidget {
  final int score;
  const _FGHealthRing({required this.score});

  Color get _color {
    if (score >= 80) return _kFreshGreen;
    if (score >= 60) return _kWarningAmber;
    return _kDangerRed;
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
          backgroundColor: Colors.white.withOpacity(0.15),
          progressColor: _color,
          center: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$score',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  height: 1,
                ),
              ),
              Text(
                '/100',
                style: GoogleFonts.inter(
                  fontSize: 9,
                  color: Colors.white.withOpacity(0.55),
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
class _FGSectionTitle extends StatelessWidget {
  final String        title;
  final String?       actionLabel;
  final VoidCallback? onTap;

  const _FGSectionTitle({
    required this.title,
    required this.actionLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.playfairDisplay(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _kTextPrimary,
              ),
            ),
          ),
          if (actionLabel != null && onTap != null)
            GestureDetector(
              onTap: onTap,
              child: Text(
                actionLabel!,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: _kPrimary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Card shell ─────────────────────────────────────────────────────────────────
class _FGCardShell extends StatelessWidget {
  final Widget               child;
  final EdgeInsetsGeometry   margin;

  const _FGCardShell({required this.child, required this.margin});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: margin,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kFieldBorder, width: 0.5),
      ),
      child: child,
    );
  }
}

// ── Progress tile ──────────────────────────────────────────────────────────────
class _FGProgressTile extends StatelessWidget {
  final String   label;
  final IconData icon;
  final double   value;
  final Color    color;

  const _FGProgressTile({
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
        color: _kSurfaceTint,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kFieldBorder, width: 0.5),
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
            backgroundColor: _kFieldBorder,
            progressColor: color,
            center: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 14),
                const SizedBox(height: 2),
                Text(
                  '${value.round()}%',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _kTextPrimary,
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
              fontWeight: FontWeight.w400,
              color: _kTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Scan CTA banner ────────────────────────────────────────────────────────────
class _FGScanBanner extends StatefulWidget {
  final VoidCallback onTap;
  const _FGScanBanner({required this.onTap});

  @override
  State<_FGScanBanner> createState() => _FGScanBannerState();
}

class _FGScanBannerState extends State<_FGScanBanner>
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: GestureDetector(
        onTapDown:  (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) {
          setState(() => _pressed = false);
          widget.onTap();
        },
        child: AnimatedScale(
          scale:    _pressed ? 0.97 : 1,
          duration: const Duration(milliseconds: 120),
          child: AnimatedBuilder(
            animation: _pulse,
            builder: (_, child) => Container(
              height: 80,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: _kPrimary,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _kPrimaryLight
                      .withOpacity(0.25 + _pulse.value * 0.15),
                  width: 0.5,
                ),
              ),
              child: child,
            ),
            child: Row(
              children: [
                // Icon container — uses AI pill dark bg for contrast
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _kPrimaryDark.withOpacity(0.45),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.camera_alt_rounded,
                    color: Colors.white,
                    size: 24,
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
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Calories · Allergens · Chronic risk',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                          color: _kPrimaryLight.withOpacity(0.90),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: _kPrimaryLight.withOpacity(0.80),
                  size: 15,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Alert card data ────────────────────────────────────────────────────────────
class _AlertCardData {
  final IconData icon;
  final String   title;
  final String   subtitle;
  final Color    color;

  const _AlertCardData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });
}

// ── Alert card ─────────────────────────────────────────────────────────────────
class _FGAlertCard extends StatelessWidget {
  final _AlertCardData data;
  const _FGAlertCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border(
          left:   BorderSide(color: data.color, width: 3),
          top:    BorderSide(color: _kFieldBorder, width: 0.5),
          right:  BorderSide(color: _kFieldBorder, width: 0.5),
          bottom: BorderSide(color: _kFieldBorder, width: 0.5),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: data.color.withOpacity(0.10),
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
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: _kTextPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  data.subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: _kTextSecondary,
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

// ── Quick action ───────────────────────────────────────────────────────────────
class _FGQuickAction extends StatelessWidget {
  final IconData     icon;
  final Color        color;
  final String       label;
  final VoidCallback onTap;

  const _FGQuickAction({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _kFieldBorder, width: 0.5),
        ),
        child: Column(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withOpacity(0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: _kTextSecondary,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Tip card ───────────────────────────────────────────────────────────────────
class _FGTipCard extends StatelessWidget {
  final String title;
  final String body;

  const _FGTipCard({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    // AI insight pill spec: darkest primary bg, ✦ star, primaryLight text
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kPrimaryDark,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ✦ star prefix per design spec
          Text(
            '✦',
            style: GoogleFonts.inter(
              fontSize: 18,
              color: _kPrimaryLight,
              height: 1.2,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  body,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: _kPrimaryLight,
                    height: 1.5,
                    fontWeight: FontWeight.w400,
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
class _FGRecentScanTile extends StatelessWidget {
  final ScanHistoryItem item;
  final VoidCallback    onTap;

  const _FGRecentScanTile({required this.item, required this.onTap});

  Color _riskColor(double pct) {
    if (pct > 100) return _kDangerRed;
    if (pct >= 80) return _kWarningAmber;
    return _kFreshGreen;
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
    final avg   = values.fold<double>(0, (a, b) => a + b) / values.length;
    final color = _riskColor(avg);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _kFieldBorder, width: 0.5),
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
                    color: _kSurfaceTint,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: color.withOpacity(0.30), width: 0.5),
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
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: _kTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      ScanHistoryItem.timeAgo(item.scannedAt),
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: _kTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Freshness bar — 4px, semantic colors per spec
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: (avg / 100).clamp(0.0, 1.0),
                        minHeight: 4,
                        backgroundColor: _kSurfaceTint,
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _FGRiskBadge(text: _riskLabel(avg), color: color),
                  const SizedBox(height: 10),
                  const Icon(
                    Icons.chevron_right,
                    color: _kFieldBorder,
                    size: 18,
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

// ── Risk badge ─────────────────────────────────────────────────────────────────
class _FGRiskBadge extends StatelessWidget {
  final String text;
  final Color  color;

  const _FGRiskBadge({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
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
class _FGMetricPill extends StatelessWidget {
  final String label;
  final bool   good;

  const _FGMetricPill({required this.label, required this.good});

  @override
  Widget build(BuildContext context) {
    final color = good ? _kFreshGreen : _kDangerRed;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.20), width: 0.5),
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
  final int                 index;
  final Widget              child;

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
          end:   Offset.zero,
        ).animate(curve),
        child: child,
      ),
    );
  }
}