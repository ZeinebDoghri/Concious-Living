import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants.dart';
import '../../../shared/widgets/animated_button.dart';
import '../../../shared/widgets/olive_header.dart';

class WasteScreen extends StatelessWidget {
  const WasteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = <_WasteItem>[
      const _WasteItem(AppStrings.wasteItemLettuce, 12.5, AppColors.olive),
      const _WasteItem(AppStrings.wasteItemTomatoes, 9.1, AppColors.cherry),
      const _WasteItem(AppStrings.wasteItemBread, 6.4, AppColors.riskModerateText),
      const _WasteItem(AppStrings.wasteItemChicken, 4.2, AppColors.cocoa),
    ];

    final total = items.fold<double>(0, (sum, it) => sum + it.kg);

    return Scaffold(
      backgroundColor: AppColors.oat,
      body: SafeArea(
        child: Column(
          children: [
            OliveHeader(
              title: AppStrings.wasteReportTitle,
              subtitle: AppStrings.topWastedItems,
              showBack: false,
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: AppColors.parchment,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.parchment,
                          borderRadius: BorderRadius.circular(AppRadii.screenCard),
                          border: Border.all(color: AppColors.sand, width: 0.5),
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
                                    style: GoogleFonts.dmSerifDisplay(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.espresso,
                                      height: 1.2,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '${total.toStringAsFixed(1)} ${AppStrings.unitG}',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.cocoa,
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
                                                color: AppColors.espresso,
                                                height: 1.2,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            AppStrings.percent(pct),
                                            style: GoogleFonts.inter(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.cocoa,
                                              height: 1.2,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: () => context.go(AppRoutes.restaurantCompost),
                        borderRadius: BorderRadius.circular(AppRadii.screenCard),
                        splashColor: AppColors.olive.withValues(alpha: 0.12),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.olive,
                            borderRadius:
                                BorderRadius.circular(AppRadii.screenCard),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.eco, color: AppColors.butter),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      AppStrings.compostOverview,
                                      style: GoogleFonts.dmSerifDisplay(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.butter,
                                        height: 1.2,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      AppStrings.viewCompostBreakdown,
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w400,
                                        color: AppColors.oliveMist,
                                        height: 1.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right,
                                  color: AppColors.butter),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      AnimatedButton(
                        label: AppStrings.logNewWasteBatch,
                        color: AppColors.cherry,
                        textColor: AppColors.butter,
                        onTap: () async {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(AppStrings.genericError)),
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
