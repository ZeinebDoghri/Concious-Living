import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:share_plus/share_plus.dart';

import '../../shared/animations/shimmer_box.dart';

class CompostDashboardPanel extends StatefulWidget {
  final String entityId;
  final String entityCollection;
  final String title;
  final bool showDepartmentSelector;
  final Color accent;
  final Color deep;
  final Color softBg;
  final Color surface;

  const CompostDashboardPanel({
    super.key,
    required this.entityId,
    required this.entityCollection,
    required this.title,
    required this.showDepartmentSelector,
    required this.accent,
    required this.deep,
    required this.softBg,
    required this.surface,
  });

  @override
  State<CompostDashboardPanel> createState() => _CompostDashboardPanelState();
}

class _CompostDashboardPanelState extends State<CompostDashboardPanel> {
  String _selectedDeptId = 'all';

  String _isoWeek() {
    final now = DateTime.now();
    final thursday = now.add(Duration(days: 3 - ((now.weekday + 6) % 7)));
    final firstThursday = DateTime(thursday.year, 1, 4);
    final week = 1 +
        (thursday.difference(firstThursday).inDays / 7).floor();
    return '${thursday.year}-W${week.toString().padLeft(2, '0')}';
  }

  double _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  String _deptField(String suffix) => 'dept_${_selectedDeptId}_$suffix';

  bool get _usesDepartmentData =>
      widget.showDepartmentSelector && _selectedDeptId != 'all';

  @override
  Widget build(BuildContext context) {
    final entityId = widget.entityId;
    if (entityId.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final entityDoc = FirebaseFirestore.instance
        .collection(widget.entityCollection)
        .doc(entityId)
        .snapshots();
    final totalsRoot = _usesDepartmentData
        ? FirebaseFirestore.instance.collection('waste_logs')
        : FirebaseFirestore.instance.collection('compost_totals');
    final weeklyRef = totalsRoot
        .doc(entityId)
        .collection('weekly')
        .doc(_isoWeek());
    final dailyQuery = totalsRoot
        .doc(entityId)
        .collection('daily')
        .orderBy(FieldPath.documentId)
        .limitToLast(7);

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: entityDoc,
      builder: (context, entitySnap) {
        final quotaData =
            entitySnap.data?.data()?['compostQuota'] as Map<String, dynamic>?;
        final weeklyGoal = _asDouble(quotaData?['weeklyCompostGoalKg']) > 0
            ? _asDouble(quotaData?['weeklyCompostGoalKg'])
            : 40.0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.showDepartmentSelector) ...[
              _DepartmentSelector(
                entityId: entityId,
                accent: widget.accent,
                selectedDeptId: _selectedDeptId,
                onSelected: (id, label) {
                  setState(() {
                    _selectedDeptId = id;
                  });
                },
              ),
              const SizedBox(height: 12),
            ],
            StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: weeklyRef.snapshots(),
              builder: (context, weeklySnap) {
                if (weeklySnap.connectionState == ConnectionState.waiting) {
                  return const _LoadingPanel();
                }
                final weekly =
                    weeklySnap.data?.data() ?? const <String, dynamic>{};
                final wasteKg = _asDouble(weekly['waste_kg']);
                final compostKg = _usesDepartmentData
                    ? _asDouble(weekly[_deptField('compostable_kg')])
                    : _asDouble(weekly['compostable_kg']);
                final co2 = _usesDepartmentData
                    ? compostKg * 0.5
                    : _asDouble(weekly['co2_saved']);
                final percent = weeklyGoal <= 0
                    ? 0.0
                    : (compostKg / weeklyGoal).clamp(0.0, 1.0);
                final quotaPct = weeklyGoal <= 0
                    ? 0
                    : ((compostKg / weeklyGoal) * 100).round();

                return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: dailyQuery.snapshots(),
                  builder: (context, dailySnap) {
                    final daily = dailySnap.data?.docs ?? const [];
                    final chart = daily
                        .map((doc) {
                          final data = doc.data();
                          final waste = _asDouble(data['waste_kg']);
                          final compost = _usesDepartmentData
                              ? _asDouble(data[_deptField('compostable_kg')])
                              : _asDouble(data['compostable_kg']);
                          return _DailyCompostPoint(
                            label: doc.id,
                            compostKg: compost,
                            wasteKg: waste,
                            co2: _asDouble(data['co2_saved']),
                          );
                        })
                        .toList(growable: false);

                    final trees = co2 / 21;
                    final water = compostKg * 6;

                    return SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _KpiGrid(
                            compostKg: compostKg,
                            wasteKg: wasteKg,
                            quotaPct: quotaPct,
                            co2Saved: co2,
                            accent: widget.accent,
                            deep: widget.deep,
                          ),
                          const SizedBox(height: 16),
                          _QuotaRing(
                            percent: percent,
                            compostKg: compostKg,
                            goalKg: weeklyGoal,
                            accent: widget.accent,
                            deep: widget.deep,
                          ),
                          const SizedBox(height: 16),
                          _CompostChart(
                            points: chart,
                            accent: widget.accent,
                            deep: widget.deep,
                            onTapPoint: (point) {
                              showModalBottomSheet<void>(
                                context: context,
                                showDragHandle: true,
                                builder: (_) => Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    20,
                                    0,
                                    20,
                                    24,
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        point.label,
                                        style: GoogleFonts.playfairDisplay(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 14),
                                      _DetailLine(
                                        label: 'Compostable',
                                        value:
                                            '${point.compostKg.toStringAsFixed(1)} kg',
                                      ),
                                      _DetailLine(
                                        label: 'Waste',
                                        value:
                                            '${point.wasteKg.toStringAsFixed(1)} kg',
                                      ),
                                      _DetailLine(
                                        label: 'CO2 saved',
                                        value:
                                            '${point.co2.toStringAsFixed(1)} kg',
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                          _ImpactStrip(
                            trees: trees,
                            waterLiters: water,
                            co2Saved: co2,
                            accent: widget.accent,
                            onTap: () {
                              Share.share(
                                'We composted ${compostKg.toStringAsFixed(1)} kg = ${trees.toStringAsFixed(1)} trees saved! #FreshGuard',
                              );
                            },
                          ),
                          const SizedBox(height: 120),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ],
        );
      },
    );
  }
}

class _DepartmentSelector extends StatelessWidget {
  final String entityId;
  final Color accent;
  final String selectedDeptId;
  final void Function(String id, String label) onSelected;

  const _DepartmentSelector({
    required this.entityId,
    required this.accent,
    required this.selectedDeptId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('hotels')
          .doc(entityId)
          .collection('departments')
          .snapshots(),
      builder: (context, snap) {
        final docs = snap.data?.docs ?? const [];
        final chips = <Widget>[
          _DeptChip(
            label: 'All',
            selected: selectedDeptId == 'all',
            accent: accent,
            onTap: () => onSelected('all', 'All'),
          ),
          ...docs.map(
            (doc) => _DeptChip(
              label: (doc.data()['name'] ?? doc.id).toString(),
              selected: selectedDeptId == doc.id,
              accent: accent,
              onTap: () =>
                  onSelected(doc.id, (doc.data()['name'] ?? doc.id).toString()),
            ),
          ),
        ];

        return SizedBox(
          height: 42,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: chips.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, index) => chips[index],
          ),
        );
      },
    );
  }
}

class _DeptChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  const _DeptChip({
    required this.label,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? accent : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: accent.withValues(alpha: 0.22)),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: selected ? Colors.white : accent,
          ),
        ),
      ),
    );
  }
}

class _KpiGrid extends StatelessWidget {
  final double compostKg;
  final double wasteKg;
  final int quotaPct;
  final double co2Saved;
  final Color accent;
  final Color deep;

  const _KpiGrid({
    required this.compostKg,
    required this.wasteKg,
    required this.quotaPct,
    required this.co2Saved,
    required this.accent,
    required this.deep,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.55,
      children: [
        _AnimatedKpiCard(
          label: 'Composted',
          value: compostKg,
          unit: 'kg',
          bg: const Color(0xFFD4EBC0),
          fg: const Color(0xFF4F8A2A),
        ),
        _AnimatedKpiCard(
          label: 'Waste',
          value: wasteKg,
          unit: 'kg',
          bg: const Color(0xFFFFF4CC),
          fg: const Color(0xFFB27B00),
        ),
        _AnimatedKpiCard(
          label: 'Quota',
          value: quotaPct.toDouble(),
          unit: '%',
          bg: const Color(0xFFF2FAF0),
          fg: deep,
        ),
        _AnimatedKpiCard(
          label: 'CO2 Saved',
          value: co2Saved,
          unit: 'kg',
          bg: const Color(0xFFD0F7EC),
          fg: const Color(0xFF0A9F84),
        ),
      ],
    );
  }
}

class _AnimatedKpiCard extends StatelessWidget {
  final String label;
  final double value;
  final String unit;
  final Color bg;
  final Color fg;

  const _AnimatedKpiCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.bg,
    required this.fg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: fg,
            ),
          ),
          const Spacer(),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: value),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutCubic,
            builder: (_, animatedValue, __) => Text(
              unit == '%'
                  ? '${animatedValue.toStringAsFixed(0)}%'
                  : '${animatedValue.toStringAsFixed(1)} $unit',
              style: GoogleFonts.playfairDisplay(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: fg,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuotaRing extends StatelessWidget {
  final double percent;
  final double compostKg;
  final double goalKg;
  final Color accent;
  final Color deep;

  const _QuotaRing({
    required this.percent,
    required this.compostKg,
    required this.goalKg,
    required this.accent,
    required this.deep,
  });

  @override
  Widget build(BuildContext context) {
    final color = percent < 0.75
        ? const Color(0xFF8FD14F)
        : percent < 1.0
        ? const Color(0xFFFFD166)
        : const Color(0xFF06D6A0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          CircularPercentIndicator(
            radius: 80,
            lineWidth: 12,
            percent: percent,
            animation: true,
            animationDuration: 900,
            circularStrokeCap: CircularStrokeCap.round,
            progressColor: color,
            backgroundColor: color.withValues(alpha: 0.14),
            center: Text(
              '${(percent * 100).toStringAsFixed(0)}%\n${compostKg.toStringAsFixed(1)}/${goalKg.toStringAsFixed(1)} kg',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: deep,
              ),
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Weekly compost goal',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: deep,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  percent >= 1
                      ? 'Goal reached for this week.'
                      : 'Your composted output is tracked against the weekly goal.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: deep.withValues(alpha: 0.75),
                    height: 1.45,
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

class _CompostChart extends StatelessWidget {
  final List<_DailyCompostPoint> points;
  final Color accent;
  final Color deep;
  final void Function(_DailyCompostPoint point) onTapPoint;

  const _CompostChart({
    required this.points,
    required this.accent,
    required this.deep,
    required this.onTapPoint,
  });

  @override
  Widget build(BuildContext context) {
    final maxY =
        points.fold<double>(8, (max, p) {
          final combined = p.compostKg + p.wasteKg;
          return combined > max ? combined : max;
        }) +
        2;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Seven-day compost trend',
            style: GoogleFonts.playfairDisplay(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: deep,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 220,
            child: BarChart(
              BarChartData(
                maxY: maxY,
                alignment: BarChartAlignment.spaceAround,
                barGroups: points.asMap().entries.map((entry) {
                  final p = entry.value;
                  return BarChartGroupData(
                    x: entry.key,
                    barRods: [
                      BarChartRodData(
                        toY: p.compostKg,
                        width: 10,
                        color: const Color(0xFF8FD14F),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      BarChartRodData(
                        toY: p.wasteKg,
                        width: 10,
                        color: const Color(0xFFFFD166),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  );
                }).toList(),
                titlesData: FlTitlesData(
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
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= points.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            points[index].label,
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: deep.withValues(alpha: 0.7),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 2,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: deep.withValues(alpha: 0.08),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                barTouchData: BarTouchData(
                  touchCallback: (event, response) {
                    final index = response?.spot?.touchedBarGroupIndex;
                    if (event is FlTapUpEvent &&
                        index != null &&
                        index >= 0 &&
                        index < points.length) {
                      onTapPoint(points[index]);
                    }
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ImpactStrip extends StatelessWidget {
  final double trees;
  final double waterLiters;
  final double co2Saved;
  final Color accent;
  final VoidCallback onTap;

  const _ImpactStrip({
    required this.trees,
    required this.waterLiters,
    required this.co2Saved,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: accent.withValues(alpha: 0.22)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _ImpactItem(label: 'Trees', value: trees.toStringAsFixed(1)),
            _ImpactItem(label: 'Water', value: waterLiters.toStringAsFixed(0)),
            _ImpactItem(label: 'CO2', value: co2Saved.toStringAsFixed(1)),
          ],
        ),
      ),
    );
  }
}

class _ImpactItem extends StatelessWidget {
  final String label;
  final String value;

  const _ImpactItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.playfairDisplay(
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w800),
        ),
      ],
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
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 12)),
          Text(
            value,
            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _DailyCompostPoint {
  final String label;
  final double compostKg;
  final double wasteKg;
  final double co2;

  const _DailyCompostPoint({
    required this.label,
    required this.compostKg,
    required this.wasteKg,
    required this.co2,
  });
}

class _LoadingPanel extends StatelessWidget {
  const _LoadingPanel();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ShimmerBox(width: double.infinity, height: 120, radius: 24),
        const SizedBox(height: 12),
        ShimmerBox(width: double.infinity, height: 180, radius: 24),
      ],
    );
  }
}
