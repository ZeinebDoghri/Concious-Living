import 'dart:math';

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
      final text = s.trim();
      if (text.isEmpty) return '';
      return text.substring(0, 1).toUpperCase();
    }

    final first = firstChar(parts.first);
    final second = parts.length > 1 ? firstChar(parts[1]) : '';
    return (first + second).trim();
  }

  double _overallDailyPct(Map<String, double> values) {
    if (values.isEmpty) return 0;
    final sum = values.values.fold<double>(0, (a, b) => a + b);
    return (sum / values.length).clamp(0, 130);
  }

  Color _progressColor(double value) {
    if (value > 100) return AppColors.cherry;
    if (value >= 80) return AppColors.butterDeep;
    return AppColors.olive;
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
        data.add(_AlertCardData(
          icon: Icons.error_outline,
          title: '${names[i]} exceeded',
          subtitle: 'You are over your target for today.',
          color: AppColors.cherry,
        ));
      } else if (value >= 80) {
        data.add(_AlertCardData(
          icon: Icons.info_outline,
          title: '${names[i]} approaching limit',
          subtitle: 'You are close to your daily goal.',
          color: AppColors.butterDeep,
        ));
      } else {
        data.add(_AlertCardData(
          icon: Icons.check_circle_outline,
          title: '${names[i]} on track',
          subtitle: 'Nice work keeping this in range.',
          color: AppColors.olive,
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

    final hasKeto = dietary.any((e) => e.contains('keto'));
    final hasVegetarian = dietary.any((e) => e.contains('vegetarian'));
    final hasVegan = dietary.any((e) => e.contains('vegan'));

    if (hasKeto) {
      return const [
        'Choose lean proteins with low-carb vegetables to keep meals balanced.',
        'Watch sauces and dressings, because hidden carbs add up quickly.',
        'Prioritize hydration so hunger signals stay clear between meals.',
        'Pair fats with fibre-rich sides to stay full without overshooting.',
        'Plan your next meal before you get hungry to avoid convenience picks.',
        'Keep snacks simple: eggs, nuts, seeds, or plain yogurt if you tolerate dairy.',
        'Batch-prep proteins early in the week to make better choices easier.',
        'Scan mixed dishes carefully, because carb content can hide in grains and breading.',
        'Build each plate around protein first, then add volume with vegetables.',
        'If you are training, time carbs strategically around the most active parts of your day.',
      ];
    }

    if (hasVegetarian || hasVegan) {
      return const [
        'Rotate legumes, tofu, tempeh, and seeds so protein intake stays diverse.',
        'Add vitamin C-rich produce to plant meals to support better iron absorption.',
        'Use nuts and avocado in small portions to keep meals satisfying.',
        'Look for whole grains and beans together for more complete nutrition.',
        'Keep a simple protein fallback ready for busy days, like yogurt or edamame.',
        'Balance lunch and dinner so you do not rely on late snacks for protein.',
        'Check labels for added sugar in plant-based sauces and snacks.',
        'Hydrate first if you feel tired, because dehydration is easy to mistake for hunger.',
        'Build meals with colour first, then add a dependable protein source.',
        'Use leftovers early in the week to reduce waste and decision fatigue.',
      ];
    }

    return const [
      'Scan your next meal before eating so you can adjust portions early.',
      'Keep water visible on your desk or table to make hydration automatic.',
      'Use half-plate vegetables when possible to reduce energy density and waste.',
      'Try eating at consistent times to make hunger and energy easier to predict.',
      'Choose one item to improve today rather than changing the whole meal.',
      'Leftovers are better than waste, so plan smaller servings if you are unsure.',
      'If a dish looks heavy, balance it with a lighter snack later in the day.',
      'A short walk after meals can help you notice fullness sooner.',
      'Check the highest-risk nutrient first when reviewing a scan result.',
      'Progress compounds when you repeat small, simple choices every day.',
    ];
  }

  Color _weekColor(int value) {
    if (value >= 3) return AppColors.cherry;
    if (value == 2) return AppColors.butterDeep;
    return AppColors.olive;
  }

  List<int> _weeklyCounts(List<ScanHistoryItem> items) {
    final now = DateTime.now();
    return List<int>.generate(7, (index) {
      final day = DateTime(now.year, now.month, now.day - (6 - index));
      return items.where((item) {
        final dt = item.scannedAt;
        return dt.year == day.year && dt.month == day.month && dt.day == day.day;
      }).length;
    });
  }

  String _averageRiskLabel(double overall) {
    if (overall > 100) return 'High';
    if (overall >= 80) return 'Moderate';
    return 'Low';
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final scanProvider = context.watch<ScanHistoryProvider>();
    final alertsProvider = context.watch<AlertsProvider>();

    final user = userProvider.currentUser;
    final rawName = (user?.name ?? '').trim();
    final name = rawName.isEmpty ? AppStrings.appName : rawName;
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
    final goalsMet = progresses.where((value) => value <= 100).length;
    final averageRisk = _averageRiskLabel(overall);

    final headerStats = [
      '${scanProvider.items.length} scans',
      '${alertsProvider.pendingCount} alerts',
      '${overall.round()}% goals',
    ];

    final tipPool = _tipsFor(userProvider);
    final tip = tipPool[now.day % tipPool.length];
    final tipTitle = userProvider.currentUser?.dietaryOptions.any(
              (e) => e.trim().toLowerCase().contains('keto'),
            ) ==
        true
        ? 'Keep carbs deliberate'
        : userProvider.currentUser?.dietaryOptions.any(
                  (e) => e.trim().toLowerCase().contains('vegetarian') ||
                      e.trim().toLowerCase().contains('vegan'),
                ) ==
            true
            ? 'Build better plant protein'
            : 'Reduce waste before it starts';

    return Scaffold(
      backgroundColor: AppColors.oat,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 200,
              width: double.infinity,
              child: Container(
                color: AppColors.cherry,
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                greeting,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w400,
                                  color: const Color(0xFFF5C0C2),
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                name,
                                style: GoogleFonts.dmSerifDisplay(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.butter,
                                  height: 1.1,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '$dateText · $serviceText',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                  color: const Color(0xFFF5C0C2),
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: headerStats
                                    .map(
                                      (stat) => Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: AppColors.butter.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          stat,
                                          style: GoogleFonts.inter(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                            color: AppColors.butter,
                                            height: 1.2,
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(growable: false),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () => context.go(AppRoutes.customerProfile),
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.butter.withValues(alpha: 0.15),
                              border: Border.all(color: AppColors.butter.withValues(alpha: 0.35), width: 1),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              _initials(name),
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.butter,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Transform.translate(
              offset: const Offset(0, -24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionTitle(
                    title: " ",
                    actionLabel: 'View details',
                    onTap: () => context.go(AppRoutes.nutritionProgress),
                    topPadding: 0,
                  ),
                  _CardShell(
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              "Today's progress",
                              style: GoogleFonts.dmSerifDisplay(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.espresso,
                              ),
                            ),
                            const Spacer(),
                            GestureDetector(
                              onTap: () => context.go(AppRoutes.nutritionProgress),
                              child: Text(
                                'View details',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.cherry,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 1.05,
                          children: List.generate(4, (index) {
                            final labels = const ['Calories', 'Carbs', 'Fats', 'Proteins'];
                            final value = progresses[index];
                            return _ProgressTile(
                              label: labels[index],
                              value: value,
                              color: _progressColor(value),
                            );
                          }),
                        ),
                        const SizedBox(height: 10),
                        Center(
                          child: GestureDetector(
                            onTap: () => context.go(AppRoutes.customerScan),
                            child: Text(
                              'Tap to scan your next meal →',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.cherry,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _ScanBanner(
                    onTap: () => context.go(AppRoutes.customerScan),
                  ),
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
                        itemBuilder: (context, index) {
                          final alert = alertCards[index];
                          return _AlertCard(data: alert);
                        },
                        separatorBuilder: (_, _) => const SizedBox(width: 10),
                        itemCount: alertCards.length,
                      ),
                    ),
                  ],
                  _SectionTitle(title: 'Quick actions', actionLabel: null, onTap: null),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: _QuickAction(
                            icon: Icons.flag_outlined,
                            iconColor: AppColors.cherry,
                            label: 'My Goals',
                            onTap: () => context.go(AppRoutes.nutritionGoals),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _QuickAction(
                            icon: Icons.ramen_dining,
                            iconColor: AppColors.cherry,
                            iconBg: AppColors.cherryBlush,
                            label: 'Allergens',
                            onTap: () => context.go(AppRoutes.customerAllergens),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _QuickAction(
                            icon: Icons.insights_outlined,
                            iconColor: AppColors.olive,
                            label: 'Progress',
                            onTap: () => context.go(AppRoutes.nutritionProgress),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _QuickAction(
                            icon: Icons.history,
                            iconColor: AppColors.cocoa,
                            label: 'History',
                            onTap: () => context.go(AppRoutes.customerHistory),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  _SectionTitle(title: "Today's recommendation", actionLabel: null, onTap: null),
                  _TipCard(title: tipTitle, body: tip),
                  _SectionTitle(
                    title: 'Recent scans',
                    actionLabel: 'See all',
                    onTap: () => context.go(AppRoutes.customerHistory),
                  ),
                  if (recentScans.isEmpty)
                    _CardShell(
                      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: Text(
                        AppStrings.noScansSubtitle,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.cocoa,
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
                          child: _RecentScanTile(
                            item: scan,
                            onTap: () => context.go(AppRoutes.customerHistoryDetail(scan.id)),
                          ),
                        );
                      }),
                    ),
                  _SectionTitle(title: 'This week', actionLabel: null, onTap: null),
                  _CardShell(
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
                          height: 52,
                          child: CustomPaint(
                            painter: _WeeklyBarPainter(
                              values: weeklyCounts,
                              color: AppColors.cherry,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: List.generate(7, (index) {
                                final labels = const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                                return Expanded(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Container(
                                        height: min(40.0, max(6.0, weeklyCounts[index] == 0 ? 6.0 : weeklyCounts[index] * 8.0)),
                                        margin: const EdgeInsets.symmetric(horizontal: 5),
                                        decoration: BoxDecoration(
                                          color: _weekColor(weeklyCounts[index]),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        labels[index],
                                        style: GoogleFonts.inter(
                                          fontSize: 10,
                                          color: AppColors.cocoa,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onTap;
  final double topPadding;

  const _SectionTitle({
    required this.title,
    required this.actionLabel,
    required this.onTap,
    this.topPadding = 20,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, topPadding, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.dmSerifDisplay(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.espresso,
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
                  color: AppColors.cherry,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CardShell extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry margin;

  const _CardShell({required this.child, required this.margin});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: margin,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.parchment,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.sand, width: 0.5),
      ),
      child: child,
    );
  }
}

class _ProgressTile extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _ProgressTile({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final pct = (value / 100).clamp(0.0, 1.0);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.sand, width: 0.5),
      ),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularPercentIndicator(
            radius: 40,
            lineWidth: 6,
            percent: pct,
            circularStrokeCap: CircularStrokeCap.round,
            backgroundColor: AppColors.sand,
            progressColor: color,
            center: Text(
              '${value.round()}%',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.espresso,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.cocoa,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScanBanner extends StatefulWidget {
  final VoidCallback onTap;

  const _ScanBanner({required this.onTap});

  @override
  State<_ScanBanner> createState() => _ScanBannerState();
}

class _ScanBannerState extends State<_ScanBanner> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) {
          setState(() => _pressed = false);
          widget.onTap();
        },
        child: AnimatedScale(
          scale: _pressed ? 0.98 : 1,
          duration: const Duration(milliseconds: 120),
          child: Container(
            height: 72,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.cherry,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.camera_alt, color: AppColors.butter, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Scan a dish',
                        style: GoogleFonts.dmSerifDisplay(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.butter,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Get instant nutrition analysis',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFFF5C0C2),
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, color: AppColors.butter, size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

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

class _AlertCard extends StatelessWidget {
  final _AlertCardData data;

  const _AlertCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.parchment,
        borderRadius: BorderRadius.circular(14),
        border: Border(
          left: BorderSide(color: data.color, width: 3),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.espresso.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
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
            child: Icon(data.icon, color: data.color, size: 18),
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
                    color: AppColors.espresso,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  data.subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: AppColors.cocoa,
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

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final VoidCallback onTap;
  final Color? iconBg;

  const _QuickAction({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.onTap,
    this.iconBg,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.parchment,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.sand, width: 0.5),
        ),
        child: Column(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconBg ?? AppColors.oliveMist,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.cocoa,
                height: 1.15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TipCard extends StatelessWidget {
  final String title;
  final String body;

  const _TipCard({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.oliveMist,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: AppColors.olive,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.lightbulb_outline, color: AppColors.butter, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.cherryBlush,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      "Today's tip",
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.olive,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  title,
                  style: GoogleFonts.dmSerifDisplay(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.espresso,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: AppColors.cocoa,
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

class _RecentScanTile extends StatelessWidget {
  final ScanHistoryItem item;
  final VoidCallback onTap;

  const _RecentScanTile({required this.item, required this.onTap});

  Color _tileColor() {
    final seed = item.id.hashCode.abs();
    const colors = [AppColors.oliveMist, AppColors.cherryBlush, AppColors.oatDeep, AppColors.butter];
    return colors[seed % colors.length];
  }

  Color _riskDotColor(double pct) {
    if (pct > 100) return AppColors.cherry;
    if (pct >= 80) return AppColors.butterDeep;
    return AppColors.olive;
  }

  Color _progressDotColor(double pct) {
    if (pct > 100) return AppColors.cherry;
    if (pct >= 80) return AppColors.butterDeep;
    return AppColors.olive;
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

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.parchment,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.sand, width: 0.5),
          ),
          child: Row(
            children: [
              Hero(
                tag: 'dish-${item.id}',
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: _tileColor(),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.restaurant_menu, color: AppColors.espresso),
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
                        fontWeight: FontWeight.w500,
                        color: AppColors.espresso,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      ScanHistoryItem.timeAgo(item.scannedAt),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: AppColors.cocoa,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: values
                          .map(
                            (value) => Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.only(right: 6),
                              decoration: BoxDecoration(
                                color: _progressDotColor(value),
                                shape: BoxShape.circle,
                              ),
                            ),
                          )
                          .toList(growable: false),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _RiskBadge(
                    text: _riskLabel(avg),
                    color: _riskDotColor(avg),
                  ),
                  const SizedBox(height: 12),
                  const Icon(Icons.chevron_right, color: AppColors.fog),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _WeeklyBarPainter extends CustomPainter {
  final List<int> values;
  final Color color;

  _WeeklyBarPainter({required this.values, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final height = size.height;
    canvas.drawLine(Offset(0, height), Offset(size.width, height), paint);
  }

  @override
  bool shouldRepaint(covariant _WeeklyBarPainter oldDelegate) {
    return oldDelegate.values != values || oldDelegate.color != color;
  }
}

class _MetricPill extends StatelessWidget {
  final String label;
  final bool good;

  const _MetricPill({required this.label, required this.good});

  @override
  Widget build(BuildContext context) {
    final background = good ? AppColors.oliveMist : AppColors.cherryBlush;
    final foreground = good ? AppColors.olive : AppColors.cherry;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: foreground,
        ),
      ),
    );
  }
}

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

    final offset = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(curve);

    return FadeTransition(
      opacity: curve,
      child: SlideTransition(position: offset, child: child),
    );
  }
}
