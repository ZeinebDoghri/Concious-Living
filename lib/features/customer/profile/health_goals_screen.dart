import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/constants.dart';
import '../../../providers/user_provider.dart';

// ── Customer design tokens ─────────────────────────────────────────────────────
const _kPrimary = Color(0xFFD9899F);
const _kDeep = Color(0xFFB27589);
const _kSurface = Color(0xFFFEFAFC);
const _kSoftBg = Color(0xFFF9E9F2);
const _kTextTitle = Color(0xFF26201B);
const _kTextBody = Color(0xFF5C4F48);
const _kTextMuted = Color(0xFF8C7E78);
const _kFresh = Color(0xFF52C98A);
const _kWarning = Color(0xFFFFAB5B);
const _kDanger = Color(0xFFFF7070);

class HealthGoalsScreen extends StatefulWidget {
  const HealthGoalsScreen({super.key});

  @override
  State<HealthGoalsScreen> createState() => _HealthGoalsScreenState();
}

class _HealthGoalsScreenState extends State<HealthGoalsScreen> {
  double _chol = AppLimits.cholesterol;
  double _sat = AppLimits.saturatedFat;
  double _sod = AppLimits.sodium;
  double _sug = AppLimits.sugar;

  late final TextEditingController _cholController;
  late final TextEditingController _satController;
  late final TextEditingController _sodController;
  late final TextEditingController _sugController;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final p = context.read<UserProvider>();
    _chol = p.cholesterolGoal;
    _sat = p.saturatedFatGoal;
    _sod = p.sodiumGoal;
    _sug = p.sugarGoal;
    _cholController = TextEditingController(text: _chol.toStringAsFixed(0));
    _satController = TextEditingController(text: _sat.toStringAsFixed(0));
    _sodController = TextEditingController(text: _sod.toStringAsFixed(0));
    _sugController = TextEditingController(text: _sug.toStringAsFixed(0));
  }

  @override
  void dispose() {
    _cholController.dispose();
    _satController.dispose();
    _sodController.dispose();
    _sugController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);

    double parse(TextEditingController controller, double fallback) {
      return double.tryParse(controller.text.trim().replaceAll(',', '.')) ??
          fallback;
    }

    _chol = parse(_cholController, AppLimits.cholesterol);
    _sat = parse(_satController, AppLimits.saturatedFat);
    _sod = parse(_sodController, AppLimits.sodium);
    _sug = parse(_sugController, AppLimits.sugar);

    await context.read<UserProvider>().updateNutrientGoals(
      cholesterol: _chol,
      saturatedFat: _sat,
      sodium: _sod,
      sugar: _sug,
    );

    if (!mounted) return;
    setState(() => _saving = false);

    context.canPop() ? context.pop() : context.go(AppRoutes.customerProfile);
  }

  @override
  Widget build(BuildContext context) {
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
                        : context.go(AppRoutes.customerProfile),
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
                          AppStrings.healthGoals,
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          AppStrings.dailyIntakeGoals,
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
                    // ── Info banner ───────────────────────────────────────
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _kSoftBg,
                        borderRadius: BorderRadius.circular(AppRadii.innerCard),
                        border: Border.all(
                          color: _kPrimary.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.tune_rounded, color: _kPrimary),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Set your daily nutrient limits. These will trigger alerts when you approach or exceed them.',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: _kTextBody,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Goal fields ───────────────────────────────────────
                    _GoalLimitField(
                      title: 'Cholesterol',
                      unit: AppStrings.unitMg,
                      controller: _cholController,
                      accentColor: _kFresh,
                      info:
                          'A daily cholesterol limit helps reduce cardiovascular risk.',
                    ),
                    const SizedBox(height: 12),
                    _GoalLimitField(
                      title: 'Graisses saturees',
                      unit: AppStrings.unitG,
                      controller: _satController,
                      accentColor: _kWarning,
                      info:
                          'Saturated fat tracking keeps daily intake within your personal target.',
                    ),
                    const SizedBox(height: 12),
                    _GoalLimitField(
                      title: 'Sodium',
                      unit: AppStrings.unitMg,
                      controller: _sodController,
                      accentColor: _kDanger,
                      info:
                          'Sodium limits are useful for blood pressure and hydration balance.',
                    ),
                    const SizedBox(height: 12),
                    _GoalLimitField(
                      title: 'Sucre',
                      unit: AppStrings.unitG,
                      controller: _sugController,
                      accentColor: _kPrimary,
                      info:
                          'Sugar limits help detect high-sugar scan patterns before they become habits.',
                    ),
                    const SizedBox(height: 24),

                    // ── Save CTA ──────────────────────────────────────────
                    GestureDetector(
                      onTap: _saving ? null : _save,
                      child: Container(
                        width: double.infinity,
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFB27589), Color(0xFFD9899F)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(AppRadii.pill),
                          boxShadow: AppShadows.md(_kPrimary),
                        ),
                        child: Center(
                          child: _saving
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  AppStrings.saveGoals,
                                  style: GoogleFonts.inter(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
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

class _GoalLimitField extends StatelessWidget {
  final String title;
  final String unit;
  final TextEditingController controller;
  final Color accentColor;
  final String info;

  const _GoalLimitField({
    required this.title,
    required this.unit,
    required this.controller,
    required this.accentColor,
    required this.info,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadii.innerCard),
        boxShadow: AppShadows.sm(_kPrimary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.tune_rounded, color: accentColor, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _kTextTitle,
                    height: 1.2,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Why this limit matters',
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text(title),
                    content: Text(info),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                ),
                icon: Icon(Icons.info_outline_rounded, color: accentColor),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: _kSoftBg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                unit,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: accentColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
