import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/constants.dart';
import '../../../providers/scan_history_provider.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/nutrient_card.dart';

// ── Customer design tokens ─────────────────────────────────────────────────────
const _kPrimary = Color(0xFFA78BFA);
const _kDeep = Color(0xFF7C3AED);
const _kSurface = Color(0xFFF5F3FF);
const _kSoftBg = Color(0xFFEDE9FE);
const _kTextTitle = Color(0xFF2D1B69);
const _kTextBody = Color(0xFF4B3B8C);
const _kTextMuted = Color(0xFF8B7BC0);

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
          barrierColor: _kDeep.withValues(alpha: 0.45),
          transitionDuration: const Duration(milliseconds: 200),
          pageBuilder: (context, a1, a2) {
            return Center(
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: 320,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppRadii.xl),
                    boxShadow: AppShadows.lg(_kPrimary),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.remove,
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: _kTextTitle,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AppStrings.scanDetail,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: _kTextBody,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => Navigator.of(context).pop(false),
                              child: Container(
                                height: 44,
                                decoration: BoxDecoration(
                                  color: _kSoftBg,
                                  borderRadius: BorderRadius.circular(
                                    AppRadii.pill,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    AppStrings.cancel,
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: _kTextBody,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => Navigator.of(context).pop(true),
                              child: Container(
                                height: 44,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF7070),
                                  borderRadius: BorderRadius.circular(
                                    AppRadii.pill,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    AppStrings.remove,
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
          transitionBuilder: (context, anim, _, child) {
            return FadeTransition(
              opacity: CurvedAnimation(
                parent: anim,
                curve: Curves.easeOutCubic,
              ),
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
        backgroundColor: _kSurface,
        body: SafeArea(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF7C3AED), Color(0xFFA78BFA)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => context.pop(),
                      icon: const Icon(
                        Icons.arrow_back_ios_rounded,
                        color: Colors.white,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      AppStrings.scanDetail,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
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
    final imagePath = (item.imagePath ?? '').trim();
    final hasImagePath = imagePath.isNotEmpty;

    return Scaffold(
      backgroundColor: _kSurface,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ─────────────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF7C3AED), Color(0xFFA78BFA)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(
                      Icons.arrow_back_ios_rounded,
                      color: Colors.white,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.scanDetail,
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.dishName,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.75),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () async {
                      final ctx = context;
                      final historyProvider = ctx.read<ScanHistoryProvider>();
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
                    color: Colors.white.withValues(alpha: 0.85),
                    splashColor: Colors.white.withValues(alpha: 0.2),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Dish image ────────────────────────────────────────
                    if (hasImagePath) ...[
                      Hero(
                        tag: 'history_${item.id}',
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadii.xl),
                          child: AspectRatio(
                            aspectRatio: 16 / 10,
                            child: kIsWeb
                                ? _ImagePlaceholder()
                                : Image.file(
                                    File(imagePath),
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) =>
                                        _ImagePlaceholder(),
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // ── Date card ─────────────────────────────────────────
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppRadii.innerCard),
                        boxShadow: AppShadows.sm(_kPrimary),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            color: _kPrimary,
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              AppStrings.savedOnDate(dateStr),
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: _kTextBody,
                                height: 1.2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // ── Dish name ─────────────────────────────────────────
                    Text(
                      item.dishName,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: _kTextTitle,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Nutrient cards ────────────────────────────────────
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

                    // ── Scan again CTA ────────────────────────────────────
                    GestureDetector(
                      onTap: () async => context.go(AppRoutes.customerScan),
                      child: Container(
                        width: double.infinity,
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF7C3AED), Color(0xFFA78BFA)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(AppRadii.pill),
                          boxShadow: AppShadows.md(_kPrimary),
                        ),
                        child: Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.camera_alt_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                AppStrings.scanAgain,
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: _kSoftBg,
      alignment: Alignment.center,
      child: Icon(Icons.image_outlined, size: 40, color: _kTextMuted),
    );
  }
}
