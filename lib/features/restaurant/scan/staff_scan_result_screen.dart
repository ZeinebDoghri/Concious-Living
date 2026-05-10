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
import '../../../shared/widgets/nutrient_card.dart';
import '../../../shared/widgets/risk_badge.dart';

// ── FreshGuard restaurant theme tokens ────────────────────────────────────────
const _rPrimary = Color(0xFF8FA84A);
const _rDeep = Color(0xFF5A7030);
const _rSurface = Color(0xFFF5F8EE);
const _rSoftBg = Color(0xFFE3E8D1);
const _rTextTitle = Color(0xFF26201B);
const _rTextBody = Color(0xFF5C4F48);
const _rTextMuted = Color(0xFF8C7E78);

class StaffScanResultScreen extends StatefulWidget {
  final Map<String, dynamic> args;

  const StaffScanResultScreen({super.key, required this.args});

  @override
  State<StaffScanResultScreen> createState() => _StaffScanResultScreenState();
}

class _StaffScanResultScreenState extends State<StaffScanResultScreen>
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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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
      backgroundColor: _rSurface,
      body: SafeArea(
        child: Column(
          children: [
            // ── Pastel header ───────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_rSoftBg, _rSurface],
                ),
                border: Border(
                  bottom: BorderSide(color: _rPrimary.withValues(alpha: 0.2)),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => context.canPop()
                        ? context.pop()
                        : context.go(AppRoutes.restaurantScan),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _rPrimary.withValues(alpha: 0.3),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _rPrimary.withValues(alpha: 0.1),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.arrow_back_ios_new,
                        color: _rDeep,
                        size: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Scan insights',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: _rTextTitle,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Save for reporting, then jump to Waste or Inventory.',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: _rTextMuted,
                            height: 1.4,
                          ),
                        ),
                      ],
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
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                            borderRadius: BorderRadius.circular(24),
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
                      // Dish name field
                      TextField(
                        controller: _dishNameController,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: _rTextTitle,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Dish / item name',
                          labelStyle: GoogleFonts.inter(
                            fontSize: 13,
                            color: _rTextMuted,
                          ),
                          prefixIcon: Icon(
                            Icons.restaurant_menu,
                            color: _rDeep,
                            size: 20,
                          ),
                          filled: true,
                          fillColor: _rSurface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: _rPrimary.withValues(alpha: 0.3),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: _rPrimary.withValues(alpha: 0.3),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: _rPrimary,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      // Overall signal card
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: riskBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: riskColor.withValues(alpha: 0.25),
                            width: 0.8,
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
                                Icons.insights_outlined,
                                color: riskColor,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Overall signal',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: _rTextBody,
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
                        'Summary',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: _rTextTitle,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        result.message,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: _rTextBody,
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
                        label: _saved ? 'Saved ✓' : 'Save scan',
                        color: _saved ? const Color(0xFF52C98A) : _rDeep,
                        textColor: Colors.white,
                        onTap: _save,
                        height: 52,
                      ),
                      const SizedBox(height: 12),
                      _OutlinedPastelButton(
                        icon: Icons.delete_outline,
                        label: 'Go to Waste',
                        onTap: () => context.go(AppRoutes.restaurantWaste),
                      ),
                      const SizedBox(height: 10),
                      _OutlinedPastelButton(
                        icon: Icons.inventory_2_outlined,
                        label: 'Go to Inventory & Expiry',
                        onTap: () => context.go(AppRoutes.restaurantInventory),
                      ),
                      const SizedBox(height: 10),
                      _OutlinedPastelButton(
                        icon: Icons.document_scanner_outlined,
                        label: 'Scan another dish',
                        onTap: () => context.go(AppRoutes.restaurantScan),
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

class _OutlinedPastelButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _OutlinedPastelButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: _rSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _rPrimary.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: _rDeep, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _rDeep,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
