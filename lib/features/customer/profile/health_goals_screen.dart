import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/constants.dart';
import '../../../providers/user_provider.dart';
import '../../../shared/widgets/animated_button.dart';
import '../../../shared/widgets/cherry_header.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.oat,
      body: SafeArea(
        child: Column(
          children: [
            CherryHeader(
              title: AppStrings.healthGoals,
              subtitle: AppStrings.dailyIntakeGoals,
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
                      _GoalSlider(
                        title: AppStrings.cholesterolLabel,
                        unit: AppStrings.unitMg,
                        min: 100,
                        max: 500,
                        value: _chol,
                        color: AppColors.cherry,
                        onChanged: (v) => setState(() => _chol = v),
                      ),
                      const SizedBox(height: 12),
                      _GoalSlider(
                        title: AppStrings.saturatedFatLabel,
                        unit: AppStrings.unitG,
                        min: 5,
                        max: 40,
                        value: _sat,
                        color: AppColors.cherry,
                        onChanged: (v) => setState(() => _sat = v),
                      ),
                      const SizedBox(height: 12),
                      _GoalSlider(
                        title: AppStrings.sodiumLabel,
                        unit: AppStrings.unitMg,
                        min: 500,
                        max: 5000,
                        value: _sod,
                        color: AppColors.cherry,
                        onChanged: (v) => setState(() => _sod = v),
                      ),
                      const SizedBox(height: 12),
                      _GoalSlider(
                        title: AppStrings.sugarLabel,
                        unit: AppStrings.unitG,
                        min: 10,
                        max: 150,
                        value: _sug,
                        color: AppColors.cherry,
                        onChanged: (v) => setState(() => _sug = v),
                      ),
                      const SizedBox(height: 18),
                      AnimatedButton(
                        label: AppStrings.saveGoals,
                        color: AppColors.cherry,
                        textColor: AppColors.butter,
                        onTap: _save,
                        isLoading: _saving,
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

class _GoalSlider extends StatelessWidget {
  final String title;
  final String unit;
  final double min;
  final double max;
  final double value;
  final Color color;
  final ValueChanged<double> onChanged;

  const _GoalSlider({
    required this.title,
    required this.unit,
    required this.min,
    required this.max,
    required this.value,
    required this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.parchment,
        borderRadius: BorderRadius.circular(AppRadii.innerCard),
        border: Border.all(color: AppColors.sand, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.dmSerifDisplay(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.espresso,
                    height: 1.2,
                  ),
                ),
              ),
              Text(
                '${value.round()} $unit',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.cherry,
                  height: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            activeColor: color,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
