import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/constants.dart';
import '../../../providers/user_provider.dart';

// ── Customer design tokens ─────────────────────────────────────────────────────
const _kPrimary   = Color(0xFFA78BFA);
const _kDeep      = Color(0xFF7C3AED);
const _kSurface   = Color(0xFFF5F3FF);
const _kSoftBg    = Color(0xFFEDE9FE);
const _kTextTitle = Color(0xFF2D1B69);
const _kTextBody  = Color(0xFF4B3B8C);
const _kTextMuted = Color(0xFF8B7BC0);
const _kFresh     = Color(0xFF52C98A);
const _kWarning   = Color(0xFFFFAB5B);
const _kDanger    = Color(0xFFFF7070);

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

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final p = context.read<UserProvider>();
    _chol = p.cholesterolGoal;
    _sat = p.saturatedFatGoal;
    _sod = p.sodiumGoal;
    _sug = p.sugarGoal;
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);

    await context.read<UserProvider>().updateNutrientGoals(
          cholesterol: _chol,
          saturatedFat: _sat,
          sodium: _sod,
          sugar: _sug,
        );

    if (!mounted) return;
    setState(() => _saving = false);

    context.pop();
  }

  Color _sliderColor(double value, double min, double max) {
    final pct = ((value - min) / (max - min)).clamp(0.0, 1.0);
    if (pct > 0.75) return _kDanger;
    if (pct > 0.5)  return _kWarning;
    return _kFresh;
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
                  colors: [Color(0xFF7C3AED), Color(0xFFA78BFA)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft:  Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
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
                        border: Border.all(color: _kPrimary.withValues(alpha: 0.2)),
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

                    // ── Goal sliders ──────────────────────────────────────
                    _GoalSlider(
                      title: AppStrings.cholesterolLabel,
                      unit: AppStrings.unitMg,
                      min: 100,
                      max: 500,
                      value: _chol,
                      accentColor: _sliderColor(_chol, 100, 500),
                      onChanged: (v) => setState(() => _chol = v),
                    ),
                    const SizedBox(height: 12),
                    _GoalSlider(
                      title: AppStrings.saturatedFatLabel,
                      unit: AppStrings.unitG,
                      min: 5,
                      max: 40,
                      value: _sat,
                      accentColor: _sliderColor(_sat, 5, 40),
                      onChanged: (v) => setState(() => _sat = v),
                    ),
                    const SizedBox(height: 12),
                    _GoalSlider(
                      title: AppStrings.sodiumLabel,
                      unit: AppStrings.unitMg,
                      min: 500,
                      max: 5000,
                      value: _sod,
                      accentColor: _sliderColor(_sod, 500, 5000),
                      onChanged: (v) => setState(() => _sod = v),
                    ),
                    const SizedBox(height: 12),
                    _GoalSlider(
                      title: AppStrings.sugarLabel,
                      unit: AppStrings.unitG,
                      min: 10,
                      max: 150,
                      value: _sug,
                      accentColor: _sliderColor(_sug, 10, 150),
                      onChanged: (v) => setState(() => _sug = v),
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
                            colors: [Color(0xFF7C3AED), Color(0xFFA78BFA)],
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

class _GoalSlider extends StatelessWidget {
  final String title;
  final String unit;
  final double min;
  final double max;
  final double value;
  final Color accentColor;
  final ValueChanged<double> onChanged;

  const _GoalSlider({
    required this.title,
    required this.unit,
    required this.min,
    required this.max,
    required this.value,
    required this.accentColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final pct = ((value - min) / (max - min)).clamp(0.0, 1.0);

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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                ),
                child: Text(
                  '${value.round()} $unit',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: accentColor,
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 6,
              backgroundColor: _kSoftBg,
              valueColor: AlwaysStoppedAnimation<Color>(accentColor),
            ),
          ),
          const SizedBox(height: 4),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: accentColor,
              inactiveTrackColor: _kSoftBg,
              thumbColor: accentColor,
              overlayColor: accentColor.withValues(alpha: 0.15),
              trackHeight: 2,
            ),
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${min.round()} $unit',
                style: GoogleFonts.inter(fontSize: 10, color: _kTextMuted),
              ),
              Text(
                '${max.round()} $unit',
                style: GoogleFonts.inter(fontSize: 10, color: _kTextMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
