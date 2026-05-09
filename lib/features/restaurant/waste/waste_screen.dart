import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants.dart';
import '../../../shared/widgets/animated_button.dart';

// ── FreshGuard restaurant theme tokens ────────────────────────────────────────
const _rPrimary   = Color(0xFFF2A7A7);
const _rDeep      = Color(0xFFE47878);
const _rSurface   = Color(0xFFFFF5F5);
const _rSoftBg    = Color(0xFFFFE4E4);
const _rTextTitle = Color(0xFF3D1515);
const _rTextBody  = Color(0xFF7A4040);
const _rTextMuted = Color(0xFFB08080);
const _fresh      = Color(0xFF52C98A);
const _warning    = Color(0xFFFFAB5B);
const _danger     = Color(0xFFFF7070);

class WasteScreen extends StatelessWidget {
  const WasteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = <_WasteItem>[
      _WasteItem(AppStrings.wasteItemLettuce,  12.5, _fresh),
      _WasteItem(AppStrings.wasteItemTomatoes,  9.1, _danger),
      _WasteItem(AppStrings.wasteItemBread,     6.4, _warning),
      _WasteItem(AppStrings.wasteItemChicken,   4.2, _rDeep),
    ];

    final total = items.fold<double>(0, (sum, it) => sum + it.kg);

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
                    AppStrings.wasteReportTitle,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: _rTextTitle,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppStrings.topWastedItems,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: _rTextMuted,
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
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Pie chart card ────────────────────────────────────
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _rSurface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: _rPrimary.withValues(alpha: 0.2),
                              width: 0.8),
                          boxShadow: [
                            BoxShadow(
                              color: _rPrimary.withValues(alpha: 0.07),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 120,
                              height: 120,
                              child: PieChart(
                                PieChartData(
                                  sectionsSpace: 2,
                                  centerSpaceRadius: 36,
                                  sections: items
                                      .map(
                                        (it) => PieChartSectionData(
                                          value: it.kg,
                                          color: it.color,
                                          radius: 32,
                                          showTitle: false,
                                        ),
                                      )
                                      .toList(growable: false),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    AppStrings.topWastedItems,
                                    style: GoogleFonts.playfairDisplay(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: _rTextTitle,
                                      height: 1.2,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${total.toStringAsFixed(1)} ${AppStrings.unitG}',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: _rTextBody,
                                      height: 1.2,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  ...items.map((it) {
                                    final pct = total <= 0
                                        ? 0
                                        : ((it.kg / total) * 100).round();
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 6),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 10,
                                            height: 10,
                                            decoration: BoxDecoration(
                                              color: it.color,
                                              borderRadius:
                                                  BorderRadius.circular(3),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              it.name,
                                              style: GoogleFonts.inter(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                                color: _rTextTitle,
                                                height: 1.2,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            AppStrings.percent(pct),
                                            style: GoogleFonts.inter(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: _rTextBody,
                                              height: 1.2,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // ── Compost nav button ────────────────────────────────
                      GestureDetector(
                        onTap: () => context.go(AppRoutes.restaurantCompost),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [_fresh, Color(0xFF3DB876)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: _fresh.withValues(alpha: 0.3),
                                blurRadius: 14,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40, height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.eco_rounded,
                                    color: Colors.white, size: 22),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      AppStrings.compostOverview,
                                      style: GoogleFonts.playfairDisplay(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                        height: 1.2,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      AppStrings.viewCompostBreakdown,
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: Colors.white.withValues(
                                            alpha: 0.85),
                                        height: 1.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right,
                                  color: Colors.white),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // ── Log waste button ──────────────────────────────────
                      AnimatedButton(
                        label: AppStrings.logNewWasteBatch,
                        color: _rDeep,
                        textColor: Colors.white,
                        onTap: () async {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(AppStrings.genericError)),
                          );
                        },
                        height: 52,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WasteItem {
  final String name;
  final double kg;
  final Color color;

  const _WasteItem(this.name, this.kg, this.color);
}
