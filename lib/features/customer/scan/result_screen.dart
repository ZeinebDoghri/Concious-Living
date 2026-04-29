import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants.dart';
import '../../../core/models/nutrient_result.dart';
import '../../../core/models/scan_history_item.dart';
import '../../../providers/scan_history_provider.dart';
import '../allergens/allergen_lookup.dart';
import '../../../shared/widgets/animated_button.dart';
import '../../../shared/widgets/cherry_header.dart';
import '../../../shared/widgets/nutrient_card.dart';
import '../../../shared/widgets/risk_badge.dart';

class ResultScreen extends StatefulWidget {
  final Map<String, dynamic> args;

  const ResultScreen({super.key, required this.args});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen>
    with SingleTickerProviderStateMixin {
  static const _prefsAllergensKey = 'customer_allergens_json';
  static const _confidenceThreshold = 65.0;

  late final AnimationController _nutrientController;
  late final TextEditingController _dishNameController;

  bool _saved = false;
  bool _loadingAllergens = true;
  bool _lowConfidence = false;
  double _modelConfidence = 0.0;
  List<String> _dishAllergens = <String>[];
  List<String> _matchedAllergens = <String>[];
  List<String> _dishIngredients = <String>[];
  String _lookupSource = 'unknown';

  @override
  void initState() {
    super.initState();

    final initialDishName = (widget.args['dishName'] as String?)?.trim() ?? '';
    final confidence = (widget.args['dishConfidence'] as num?)?.toDouble() ?? 0.0;

    _dishNameController = TextEditingController(text: initialDishName);
    _modelConfidence = confidence;
    _lowConfidence = confidence < _confidenceThreshold;

    _nutrientController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..forward();

    if (!_lowConfidence) {
      _loadAllergenInfo();
    } else {
      setState(() => _loadingAllergens = false);
    }
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

  Future<void> _loadAllergenInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final rawProfile = prefs.getString(_prefsAllergensKey);

    final profileAllergens = <String>[];
    if (rawProfile != null && rawProfile.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(rawProfile);
        if (decoded is List) {
          profileAllergens.addAll(decoded.whereType<String>());
        }
      } catch (_) {
        profileAllergens.clear();
      }
    }

    final dishName = _dishNameController.text.trim();
    final lookup = await AllergenLookupService.fetch(dishName);
    final matched = AllergenLookupService.matchAgainstProfile(
      profileAllergens: profileAllergens,
      detectedAllergens: lookup.allergens,
    ).toList(growable: false)
      ..sort();

    if (!mounted) return;

    setState(() {
      _dishAllergens = lookup.allergens;
      _matchedAllergens = matched;
      _dishIngredients = lookup.ingredients;
      _lookupSource = lookup.source;
      _loadingAllergens = false;
    });
  }

  Future<void> _refreshAllergens() async {
    setState(() => _loadingAllergens = true);
    await _loadAllergenInfo();
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
    final imagePath = (widget.args['imagePath'] as String?)?.trim();
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
                      if (imagePath != null && imagePath.isNotEmpty) ...[
                        Hero(
                          tag: 'scan_image',
                          child: ClipRRect(
                            borderRadius:
                                BorderRadius.circular(AppRadii.screenCard),
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
                      ],
                      TextField(
                        controller: _dishNameController,
                        onSubmitted: (_) => _refreshAllergens(),
                        decoration: const InputDecoration(
                          labelText: 'Dish name',
                          prefixIcon:
                              Icon(Icons.restaurant_menu, color: AppColors.cocoa),
                          suffixIcon: Icon(Icons.search, color: AppColors.cocoa),
                        ),
                      ),
                      const SizedBox(height: 14),
                      if (_lowConfidence) ...[
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3E2),
                            borderRadius:
                                BorderRadius.circular(AppRadii.innerCard),
                            border: Border.all(
                              color: AppColors.butterDeep.withValues(alpha: 0.5),
                              width: 0.5,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.help_outline,
                                    color: AppColors.butterDeep,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Unable to identify this dish',
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.butterDeep,
                                        height: 1.3,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Confidence: ${_modelConfidence.toStringAsFixed(1)}%',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.cocoa,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'We don\'t have enough information in our database to identify this dish with confidence. Please ask a staff member for assistance.',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                  color: AppColors.cocoa,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                      ] else ...[
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: _matchedAllergens.isEmpty
                                ? AppColors.infoBg
                                : const Color(0xFFFDEBEC),
                            borderRadius:
                                BorderRadius.circular(AppRadii.innerCard),
                            border: Border.all(
                              color: _matchedAllergens.isEmpty
                                  ? AppColors.sand
                                  : AppColors.cherry.withValues(alpha: 0.25),
                              width: 0.5,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    _matchedAllergens.isEmpty
                                        ? Icons.info_outline
                                        : Icons.warning_amber_rounded,
                                    color: _matchedAllergens.isEmpty
                                        ? AppColors.infoText
                                        : AppColors.cherry,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      _loadingAllergens
                                          ? 'Checking allergen profile...'
                                          : _matchedAllergens.isEmpty
                                              ? (_dishAllergens.isEmpty
                                                  ? 'No allergen overlap detected.'
                                                  : 'Safe to consume.')
                                              : '⚠️ WARNING: Allergen match detected!',
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: _matchedAllergens.isEmpty
                                            ? AppColors.infoText
                                            : AppColors.cherry,
                                        height: 1.3,
                                      ),
                                    ),
                                  ),
                                  if (!_loadingAllergens)
                                    TextButton(
                                      onPressed: _refreshAllergens,
                                      child: Text(
                                        'Refresh',
                                        style: GoogleFonts.inter(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              if (!_loadingAllergens && _dishAllergens.isNotEmpty) ...[
                                Text(
                                  'Detected allergens',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.cocoa,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: _dishAllergens
                                      .map(
                                        (item) => _Chip(
                                          label: item,
                                          background: AppColors.parchment,
                                          foreground: AppColors.espresso,
                                          border: AppColors.sand,
                                        ),
                                      )
                                      .toList(growable: false),
                                ),
                              ],
                              if (!_loadingAllergens && _matchedAllergens.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Text(
                                  'Your allergen profile matches',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.cherry,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: _matchedAllergens
                                      .map(
                                        (item) => _Chip(
                                          label: item,
                                          background: AppColors.cherryBlush,
                                          foreground: AppColors.cherry,
                                          border: AppColors.cherry,
                                        ),
                                      )
                                      .toList(growable: false),
                                ),
                              ],
                              if (!_loadingAllergens && _dishIngredients.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Text(
                                  'Source: $_lookupSource',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.cocoa,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _dishIngredients.join(' • '),
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                    color: AppColors.cocoa,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],
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

class _Chip extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;
  final Color border;

  const _Chip({
    required this.label,
    required this.background,
    required this.foreground,
    required this.border,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadii.badge),
        border: Border.all(color: border, width: 0.6),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: foreground,
          height: 1.2,
        ),
      ),
    );
  }
}
