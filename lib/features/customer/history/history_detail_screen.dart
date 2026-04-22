import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/constants.dart';
import '../../../providers/scan_history_provider.dart';
import '../../../shared/widgets/animated_button.dart';
import '../../../shared/widgets/cherry_header.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/nutrient_card.dart';

class HistoryDetailScreen extends StatefulWidget {
  final String id;

  const HistoryDetailScreen({super.key, required this.id});

  @override
  State<HistoryDetailScreen> createState() => _HistoryDetailScreenState();
}

class _HistoryDetailScreenState extends State<HistoryDetailScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _nutrientController;

  @override
  void initState() {
    super.initState();
    _nutrientController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..forward();
  }

  @override
  void dispose() {
    _nutrientController.dispose();
    super.dispose();
  }

  Future<bool> _confirmDelete() async {
    return await showGeneralDialog<bool>(
          context: context,
          barrierDismissible: true,
          barrierLabel: AppStrings.cancel,
          barrierColor: AppColors.espresso.withValues(alpha: 0.45),
          transitionDuration: const Duration(milliseconds: 200),
          pageBuilder: (context, a1, a2) {
            return Center(
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: 320,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.parchment,
                    borderRadius: BorderRadius.circular(AppRadii.screenCard),
                    border: Border.all(color: AppColors.sand, width: 0.5),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.remove,
                        style: GoogleFonts.dmSerifDisplay(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.espresso,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AppStrings.scanDetail,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: AppColors.cocoa,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: Text(AppStrings.cancel),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: Text(AppStrings.remove),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ),
            );
          },
          transitionBuilder: (context, anim, _, child) {
            return FadeTransition(
              opacity: CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
              child: child,
            );
          },
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ScanHistoryProvider>();
    final item = provider.byId(widget.id);

    if (item == null) {
      return Scaffold(
        backgroundColor: AppColors.oat,
        body: SafeArea(
          child: Column(
            children: [
              CherryHeader(
                title: AppStrings.scanDetail,
                subtitle: AppStrings.scanHistory,
                showBack: true,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: EmptyState(
                    icon: Icons.history,
                    title: AppStrings.noScansYet,
                    subtitle: AppStrings.noScansSubtitle,
                    actionLabel: AppStrings.scanYourDish,
                    onAction: () => context.go(AppRoutes.customerScan),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final dateStr = DateFormat('dd MMM yyyy, HH:mm').format(item.scannedAt);

    return Scaffold(
      backgroundColor: AppColors.oat,
      body: SafeArea(
        child: Column(
          children: [
            CherryHeader(
              title: AppStrings.scanDetail,
              subtitle: item.dishName,
              showBack: true,
              actions: [
                IconButton(
                  onPressed: () async {
                    final ctx = context;
                    final historyProvider =
                        ctx.read<ScanHistoryProvider>();
                    final ok = await _confirmDelete();
                    if (!ctx.mounted || !ok) return;

                    final removed = await historyProvider.removeScan(item.id);
                    if (!ctx.mounted) return;

                    if (removed != null) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(
                          content: Text(AppStrings.remove),
                          action: SnackBarAction(
                            label: AppStrings.keep,
                            onPressed: () {
                              historyProvider.restoreScan(removed);
                            },
                          ),
                        ),
                      );
                    }

                    ctx.pop();
                  },
                  icon: const Icon(Icons.delete_outline),
                  color: AppColors.butter,
                  splashColor: AppColors.butter.withValues(alpha: 0.2),
                ),
              ],
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
                      if ((item.imagePath ?? '').trim().isNotEmpty) ...[
                        Hero(
                          tag: 'history_${item.id}',
                          child: ClipRRect(
                            borderRadius:
                                BorderRadius.circular(AppRadii.screenCard),
                            child: AspectRatio(
                              aspectRatio: 16 / 10,
                              child: Image.file(
                                File(item.imagePath!),
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => Container(
                                  color: AppColors.oat,
                                  alignment: Alignment.center,
                                  child: const Icon(
                                    Icons.image_outlined,
                                    size: 40,
                                    color: AppColors.cocoa,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.oat,
                          borderRadius:
                              BorderRadius.circular(AppRadii.innerCard),
                          border: Border.all(color: AppColors.sand, width: 0.5),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today_outlined,
                                color: AppColors.cocoa, size: 18),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                AppStrings.savedOnDate(dateStr),
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.espresso,
                                  height: 1.2,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      NutrientCard(
                        name: AppStrings.cholesterolLabel,
                        value: item.result.cholesterol.value,
                        unit: item.result.cholesterol.unit,
                        dailyPct: item.result.cholesterol.dailyValuePct,
                        riskLevel: item.result.cholesterol.riskLevel,
                        controller: _nutrientController,
                        delay: const Duration(milliseconds: 0),
                      ),
                      const SizedBox(height: 12),
                      NutrientCard(
                        name: AppStrings.saturatedFatLabel,
                        value: item.result.saturatedFat.value,
                        unit: item.result.saturatedFat.unit,
                        dailyPct: item.result.saturatedFat.dailyValuePct,
                        riskLevel: item.result.saturatedFat.riskLevel,
                        controller: _nutrientController,
                        delay: const Duration(milliseconds: 150),
                      ),
                      const SizedBox(height: 12),
                      NutrientCard(
                        name: AppStrings.sodiumLabel,
                        value: item.result.sodium.value,
                        unit: item.result.sodium.unit,
                        dailyPct: item.result.sodium.dailyValuePct,
                        riskLevel: item.result.sodium.riskLevel,
                        controller: _nutrientController,
                        delay: const Duration(milliseconds: 300),
                      ),
                      const SizedBox(height: 12),
                      NutrientCard(
                        name: AppStrings.sugarLabel,
                        value: item.result.sugar.value,
                        unit: item.result.sugar.unit,
                        dailyPct: item.result.sugar.dailyValuePct,
                        riskLevel: item.result.sugar.riskLevel,
                        controller: _nutrientController,
                        delay: const Duration(milliseconds: 450),
                      ),
                      const SizedBox(height: 18),
                      AnimatedButton(
                        label: AppStrings.scanAgain,
                        color: AppColors.cherry,
                        textColor: AppColors.butter,
                        onTap: () async =>
                            context.go(AppRoutes.customerScan),
                        height: 52,
                      ),
                    ],
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
