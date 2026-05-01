import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/constants.dart';
import '../../../core/models/nutrient_result.dart';
import '../../../core/models/scan_history_item.dart';
import '../../../providers/scan_history_provider.dart';
import '../../../shared/widgets/animated_button.dart';
import '../../../shared/widgets/cherry_header.dart';
import '../../../shared/widgets/nutrient_card.dart';
import '../../../shared/widgets/risk_badge.dart';

//import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';

class ResultScreen extends StatefulWidget {
  final Map<String, dynamic> args;

  const ResultScreen({super.key, required this.args});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _nutrientController;
  late final TextEditingController _dishNameController;

  bool _saved = false;

  @override
  void initState() {
    super.initState();

    final initialDishName = (widget.args['dishName'] as String?)?.trim() ?? '';
    _dishNameController = TextEditingController(text: initialDishName);

    _nutrientController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..forward();
  }

  @override
  void dispose() {
    _nutrientController.dispose();
    _dishNameController.dispose();
    super.dispose();
  }

  NutrientResult _parseResult() {
    final raw = widget.args['result'];
    if (raw is Map<String, dynamic>) {
      return NutrientResult.fromJson(raw);
    }
    return NutrientResult.fromJson(const <String, dynamic>{});
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _save() async {
    if (_saved) return;

    final dish = _dishNameController.text.trim().isEmpty
        ? 'Dish'
        : _dishNameController.text.trim();

    final imagePath = (widget.args['imagePath'] as String?)?.trim();
    final result = _parseResult();

    final item = ScanHistoryItem(
      dishName: dish,
      scannedAt: DateTime.now(),
      result: result,
      imagePath: imagePath,
    );

    await context.read<ScanHistoryProvider>().addScan(item);

    if (!mounted) return;

    setState(() => _saved = true);
    _snack(AppStrings.ok);
  }

  @override
  Widget build(BuildContext context) {
    //final imagePath = (widget.args['imagePath'] as String?)?.trim();
    final result = _parseResult();

    final riskColor = NutrientCard.riskColor(result.overallRisk);
    final riskBg = NutrientCard.riskBg(result.overallRisk);

    return Scaffold(
      backgroundColor: AppColors.oat,
      body: SafeArea(
        child: Column(
          children: [
            CherryHeader(
              title: AppStrings.nutritionAnalysis,
              subtitle: AppStrings.overallRiskLevel,
              showBack: true,
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
                      /* if (imagePath != null && imagePath.isNotEmpty) ...[
                        Hero(
                          tag: 'scan_image',
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(AppRadii.screenCard),
                            child: AspectRatio(
                              aspectRatio: 16 / 10,
                              child: Image.file(
                                File(imagePath),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                      ], */
                      Builder(builder: (_) {
                        final imageBytes = widget.args['imageBytes'] as Uint8List?;
                        final imagePath = (widget.args['imagePath'] as String?)?.trim();
                        final hasImage = imageBytes != null || (imagePath != null && imagePath.isNotEmpty);
                        if (!hasImage) return const SizedBox.shrink();
                        return Column(
                          children: [
                            Hero(
                              tag: 'scan_image',
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(AppRadii.screenCard),
                                child: AspectRatio(
                                  aspectRatio: 16 / 10,
                                  child: imageBytes != null
                                      ? Image.memory(imageBytes, fit: BoxFit.cover)
                                      : Image.file(File(imagePath!), fit: BoxFit.cover),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                          ],
                        );
                      }),
                      TextField(
                        controller: _dishNameController,
                        decoration: const InputDecoration(
                          labelText: 'Dish name',
                          prefixIcon:
                              Icon(Icons.restaurant_menu, color: AppColors.cocoa),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: riskBg,
                          borderRadius:
                              BorderRadius.circular(AppRadii.innerCard),
                          border: Border.all(color: AppColors.sand, width: 0.5),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppColors.parchment
                                    .withValues(alpha: 0.8),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(
                                Icons.shield_outlined,
                                color: riskColor,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    AppStrings.overallRiskLevel,
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.cocoa,
                                      height: 1.2,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  RiskBadge(result.overallRisk),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        AppStrings.whatThisMeans,
                        style: GoogleFonts.dmSerifDisplay(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.espresso,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        result.message,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: AppColors.cocoa,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 18),
                      NutrientCard(
                        name: AppStrings.cholesterolLabel,
                        value: result.cholesterol.value,
                        unit: result.cholesterol.unit,
                        dailyPct: result.cholesterol.dailyValuePct,
                        riskLevel: result.cholesterol.riskLevel,
                        controller: _nutrientController,
                        delay: const Duration(milliseconds: 0),
                      ),
                      const SizedBox(height: 12),
                      NutrientCard(
                        name: AppStrings.saturatedFatLabel,
                        value: result.saturatedFat.value,
                        unit: result.saturatedFat.unit,
                        dailyPct: result.saturatedFat.dailyValuePct,
                        riskLevel: result.saturatedFat.riskLevel,
                        controller: _nutrientController,
                        delay: const Duration(milliseconds: 150),
                      ),
                      const SizedBox(height: 12),
                      NutrientCard(
                        name: AppStrings.sodiumLabel,
                        value: result.sodium.value,
                        unit: result.sodium.unit,
                        dailyPct: result.sodium.dailyValuePct,
                        riskLevel: result.sodium.riskLevel,
                        controller: _nutrientController,
                        delay: const Duration(milliseconds: 300),
                      ),
                      const SizedBox(height: 12),
                      NutrientCard(
                        name: AppStrings.sugarLabel,
                        value: result.sugar.value,
                        unit: result.sugar.unit,
                        dailyPct: result.sugar.dailyValuePct,
                        riskLevel: result.sugar.riskLevel,
                        controller: _nutrientController,
                        delay: const Duration(milliseconds: 450),
                      ),
                      const SizedBox(height: 18),
                      AnimatedButton(
                        label: AppStrings.saveToHistory,
                        color: _saved ? AppColors.olive : AppColors.cherry,
                        textColor: AppColors.butter,
                        onTap: _save,
                        height: 52,
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: () => context.go(AppRoutes.customerScan),
                        child: Text(AppStrings.scanAnotherDish),
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
