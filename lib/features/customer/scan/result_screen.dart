import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants.dart';
import '../../../core/firebase_service.dart';
import '../../../core/models/alert_model.dart';
import '../../../core/models/nutrient_result.dart';
import '../../../core/models/scan_history_item.dart';
import '../../../core/models/user_model.dart';
import '../../../providers/scan_history_provider.dart';
import '../../../providers/user_provider.dart';
import '../../../services/cloudinary_service.dart';
import '../../../services/nutrient_tracking_service.dart';
import '../../../shared/widgets/nutrient_card.dart';
import '../../../shared/widgets/risk_badge.dart';
import '../allergens/allergen_utils.dart';
import '../allergens/allergy_service.dart';
import '../nutrition/calorie_inference_service.dart';

// ── Customer design tokens ─────────────────────────────────────────────────────
const _kPrimary = Color(0xFFD9899F);
const _kSurface = Color(0xFFFEFAFC);
const _kSoftBg = Color(0xFFF9E9F2);
const _kTextTitle = Color(0xFF26201B);
const _kTextBody = Color(0xFF5C4F48);
const _kTextMuted = Color(0xFF8C7E78);

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
  bool _saving = false;
  bool _loadingAllergenMatches = true;
  List<String> _matchedAllergens = const <String>[];
  List<String> _detectedAllergens = const <String>[];

  @override
  void initState() {
    super.initState();

    final initialDishName = (widget.args['dishName'] as String?)?.trim() ?? '';
    final allergyDish = (_parseAllergyResult()?.dish ?? '').trim();
    _dishNameController = TextEditingController(
      text: allergyDish.isNotEmpty && allergyDish.toLowerCase() != 'dish'
          ? allergyDish
          : initialDishName,
    );

    _nutrientController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..forward();

    _prepareAllergenMatching();
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

  AllergyResult? _parseAllergyResult() {
    final raw = widget.args['allergyResult'];
    if (raw is Map<String, dynamic>) {
      return AllergyResult.fromJson(raw);
    }
    return null;
  }

  NutritionResult? _parseCalorieResult() {
    final raw = widget.args['calorieResult'];
    if (raw is Map<String, dynamic>) {
      try {
        return NutritionResult.fromJson(raw);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  Future<void> _prepareAllergenMatching() async {
    final allergyResult = _parseAllergyResult();
    if (allergyResult == null) {
      if (!mounted) return;
      setState(() {
        _detectedAllergens = const <String>[];
        _matchedAllergens = const <String>[];
        _loadingAllergenMatches = false;
      });
      return;
    }

    final detected = allergyResult.allergens
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList(growable: false);
    final matches = await getMatchingAllergens(detected);
    if (!mounted) return;
    setState(() {
      _detectedAllergens = detected;
      _matchedAllergens = matches;
      _loadingAllergenMatches = false;
    });
  }

  Future<void> _saveAlertsIfNeeded({
    required UserModel? user,
    required ScanHistoryItem item,
    required List<String> matchedAllergens,
  }) async {
    if (matchedAllergens.isEmpty) return;
    final authUid = FirebaseAuth.instance.currentUser?.uid;
    final customerId = (user?.id ?? '').trim().isEmpty
        ? (authUid ?? '')
        : user!.id;
    if (customerId.isEmpty) return;

    final venueId = (widget.args['venueId'] as String?)?.trim();
    final venueType = (widget.args['venueType'] as String?)?.trim();
    final now = DateTime.now();

    for (final allergen in matchedAllergens) {
      final alert = AlertModel(
        id: const Uuid().v4(),
        customerId: customerId,
        customerName: (user?.name ?? '').trim().isEmpty
            ? 'Customer'
            : user!.name,
        dishName: item.dishName,
        allergen: allergen,
        venueId: (venueId == null || venueId.isEmpty) ? null : venueId,
        venueType: (venueType == null || venueType.isEmpty) ? null : venueType,
        timestamp: now,
        status: 'pending',
      );
      await FirebaseService.saveAlert(alert);
    }
  }

  Future<void> _save() async {
    if (_saved || _saving) return;
    final router = GoRouter.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final userProvider = context.read<UserProvider>();
    final scanHistoryProvider = context.read<ScanHistoryProvider>();

    setState(() => _saving = true);

    try {
      if (_loadingAllergenMatches) {
        await _prepareAllergenMatching();
      }

      final dish = _dishNameController.text.trim().isEmpty
          ? 'Dish'
          : _dishNameController.text.trim();

      final imagePath = (widget.args['imagePath'] as String?)?.trim();
      final rawImageBytes = widget.args['imageBytes'];
      final imageBytes = rawImageBytes is Uint8List ? rawImageBytes : null;
      final result = _parseResult();
      final calorieResult = _parseCalorieResult();
      String? imageUrl;

      try {
        if (imageBytes != null && imageBytes.isNotEmpty) {
          imageUrl = await CloudinaryService.uploadScanImage(
            imageBytes,
            folder: 'freshguard/customer',
          );
        } else if (imagePath != null && imagePath.isNotEmpty && !kIsWeb) {
          final fileBytes = await File(imagePath).readAsBytes();
          imageUrl = await CloudinaryService.uploadScanImage(
            fileBytes,
            folder: 'freshguard/customer',
          );
        }
      } catch (_) {
        imageUrl = null;
      }

      final item = ScanHistoryItem(
        dishName: dish,
        scannedAt: DateTime.now(),
        result: result,
        imagePath: imagePath,
        imageUrl: imageUrl,
        detectedAllergens: _detectedAllergens,
        matchedAllergens: _matchedAllergens,
      );

      final user = userProvider.currentUser;
      final uid = user?.id ?? '';

      await scanHistoryProvider.addScan(item);
      await _saveAlertsIfNeeded(
        user: user,
        item: item,
        matchedAllergens: _matchedAllergens,
      );
      if (uid.isNotEmpty) {
        await NutrientTrackingService.onScanSaved(uid, {
          'scanId': item.id,
          'cholesterol_mg': result.cholesterol.value,
          'saturated_fat_g': result.saturatedFat.value,
          'sodium_mg': result.sodium.value,
          'sugar_g': result.sugar.value,
          'calories': calorieResult?.calories ?? 0.0,
        });
      }

      if (!mounted) return;

      setState(() => _saved = true);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            _matchedAllergens.isNotEmpty
                ? 'Saved. Allergen alert flagged and added to history.'
                : 'Saved to history successfully.',
          ),
          backgroundColor: _matchedAllergens.isNotEmpty
              ? const Color(0xFFFF7070)
              : const Color(0xFF45C4B0),
        ),
      );
      router.go(AppRoutes.customerHistory);
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Could not save scan: $e'),
          backgroundColor: const Color(0xFFFF7070),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final readOnly = widget.args['readOnly'] == true;
    final imagePath = (widget.args['imagePath'] as String?)?.trim();
    final rawImageBytes = widget.args['imageBytes'];
    final imageBytes = rawImageBytes is Uint8List ? rawImageBytes : null;
    final result = _parseResult();
    final allergyResult = _parseAllergyResult();
    final calorieResult = _parseCalorieResult();
    final calorieError = (widget.args['calorieError'] as String?)?.trim() ?? '';
    final hasImageBytes = imageBytes != null && imageBytes.isNotEmpty;
    final hasImagePath = imagePath != null && imagePath.isNotEmpty;

    final riskColor = NutrientCard.riskColor(result.overallRisk);
    final riskBg = NutrientCard.riskBg(result.overallRisk);

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
                  colors: [Color(0xFFB27589), Color(0xFFD9899F)],
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
                    onPressed: () => context.canPop()
                        ? context.pop()
                        : context.go(AppRoutes.customerHome),
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
                          AppStrings.nutritionAnalysis,
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          AppStrings.overallRiskLevel,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.75),
                          ),
                        ),
                      ],
                    ),
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
                    if (!_loadingAllergenMatches && _matchedAllergens.isNotEmpty)
                      _AllergenAlertBanner(matches: _matchedAllergens),
                    if (!_loadingAllergenMatches && _matchedAllergens.isNotEmpty)
                      const SizedBox(height: 14),
                    // ── Dish image ────────────────────────────────────────
                    if (hasImageBytes || hasImagePath) ...[
                      Hero(
                        tag: 'scan_image',
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadii.xl),
                          child: AspectRatio(
                            aspectRatio: 16 / 10,
                            child: hasImageBytes
                                ? Image.memory(imageBytes, fit: BoxFit.cover)
                                : kIsWeb
                                ? _ImagePlaceholder()
                                : Image.file(
                                    File(imagePath!),
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) =>
                                        _ImagePlaceholder(),
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // ── Dish name field ───────────────────────────────────
                    TextField(
                      controller: _dishNameController,
                      enabled: !readOnly,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: _kTextTitle,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Dish name',
                        labelStyle: GoogleFonts.inter(color: _kTextMuted),
                        prefixIcon: Icon(
                          Icons.restaurant_menu,
                          color: _kPrimary,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadii.input),
                          borderSide: BorderSide(color: _kSoftBg, width: 1.5),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadii.input),
                          borderSide: BorderSide(color: _kPrimary, width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // ── Overall risk ──────────────────────────────────────
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: riskBg,
                        borderRadius: BorderRadius.circular(AppRadii.innerCard),
                        border: Border.all(
                          color: riskColor.withValues(alpha: 0.25),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.8),
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
                                    color: _kTextBody,
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

                    // ── What this means ───────────────────────────────────
                    Text(
                      AppStrings.whatThisMeans,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _kTextTitle,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      result.message,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: _kTextBody,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 18),

                    // ── Nutrient cards ────────────────────────────────────
                    if (allergyResult != null) ...[
                      _AllergenModelCard(
                        result: allergyResult,
                        matches: _matchedAllergens,
                      ),
                      const SizedBox(height: 18),
                    ],

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppRadii.innerCard),
                        border: Border.all(color: _kSoftBg, width: 1.5),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.local_fire_department_outlined,
                                color: _kPrimary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Calorie & Nutrition Analysis',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: _kTextTitle,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          if (calorieResult != null) ...[
                            Text(
                              '${calorieResult.calories.toStringAsFixed(0)} kcal • ${calorieResult.mass.toStringAsFixed(0)} g',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _kTextBody,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _MetricChip(
                                  label: 'Protein',
                                  value:
                                      '${calorieResult.protein.toStringAsFixed(1)} g',
                                  color: const Color(0xFF10B981),
                                ),
                                _MetricChip(
                                  label: 'Fat',
                                  value:
                                      '${calorieResult.fat.toStringAsFixed(1)} g',
                                  color: const Color(0xFFF59E0B),
                                ),
                                _MetricChip(
                                  label: 'Carbs',
                                  value:
                                      '${calorieResult.carb.toStringAsFixed(1)} g',
                                  color: _kPrimary,
                                ),
                              ],
                            ),
                          ] else
                            Text(
                              calorieError.isNotEmpty
                                  ? 'Calorie analysis unavailable: $calorieError'
                                  : 'Calorie analysis is unavailable for this scan.',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: _kTextBody,
                                height: 1.4,
                              ),
                            ),
                        ],
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

                    // ── Save CTA ──────────────────────────────────────────
                    if (!readOnly) ...[
                      GestureDetector(
                        onTap: _saving ? null : _save,
                        child: Container(
                          width: double.infinity,
                          height: 52,
                          decoration: BoxDecoration(
                            gradient: _saved
                                ? const LinearGradient(
                                    colors: [
                                      Color(0xFF52C98A),
                                      Color(0xFF3AA870),
                                    ],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  )
                                : const LinearGradient(
                                    colors: [
                                      Color(0xFFB27589),
                                      Color(0xFFD9899F),
                                    ],
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
                                Icon(
                                  _saving
                                      ? Icons.hourglass_top_rounded
                                      : _saved
                                      ? Icons.check_circle_outline
                                      : Icons.bookmark_add_outlined,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _saving
                                      ? 'Saving...'
                                      : AppStrings.saveToHistory,
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
                      const SizedBox(height: 12),
                    ],

                    // ── Scan another ──────────────────────────────────────
                    GestureDetector(
                      onTap: () => context.go(AppRoutes.customerScan),
                      child: Container(
                        width: double.infinity,
                        height: 52,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(AppRadii.pill),
                          border: Border.all(color: _kPrimary, width: 1.5),
                          boxShadow: AppShadows.sm(_kPrimary),
                        ),
                        child: Center(
                          child: Text(
                            AppStrings.scanAnotherDish,
                            style: GoogleFonts.inter(
                              fontSize: 15,
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
            ),
          ],
        ),
      ),
    );
  }
}

class _AllergenModelCard extends StatelessWidget {
  final AllergyResult result;
  final List<String> matches;

  const _AllergenModelCard({required this.result, required this.matches});

  @override
  Widget build(BuildContext context) {
    final hasRisk = matches.isNotEmpty;
    final confidencePct = result.confidence <= 1
        ? (result.confidence * 100).round()
        : result.confidence.round();
    final accent = hasRisk ? const Color(0xFFFF7070) : _kPrimary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: hasRisk ? const Color(0xFFFF7070).withValues(alpha: 0.10) : _kSoftBg,
        borderRadius: BorderRadius.circular(AppRadii.innerCard),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
        boxShadow: AppShadows.sm(_kPrimary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                hasRisk ? Icons.warning_amber_rounded : Icons.verified_outlined,
                color: accent,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  hasRisk ? 'Allergen risk detected' : 'Allergen model result',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _kTextTitle,
                  ),
                ),
              ),
              if (confidencePct > 0)
                Text(
                  '$confidencePct%',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _kTextMuted,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            result.dish.trim().isEmpty ? 'Dish detected' : result.dish,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _kTextBody,
            ),
          ),
          if (result.allergens.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: result.allergens
                  .map((allergen) {
                    final risky = matches.any(
                      (match) => match.toLowerCase() == allergen.toLowerCase(),
                    );
                    final color = risky ? const Color(0xFFFF7070) : _kPrimary;
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(AppRadii.pill),
                        border: Border.all(color: color.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        allergen,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                    );
                  })
                  .toList(growable: false),
            ),
          ],
        ],
      ),
    );
  }
}

class _AllergenAlertBanner extends StatelessWidget {
  final List<String> matches;

  const _AllergenAlertBanner({required this.matches});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFF7070).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadii.innerCard),
        border: Border.all(color: const Color(0xFFFF7070).withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, color: Color(0xFFFF7070)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ALLERGEN ALERT',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFFFF7070),
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Matched allergens: ${matches.join(', ')}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _kTextBody,
                    height: 1.35,
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

class _MetricChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MetricChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        '$label: $value',
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
