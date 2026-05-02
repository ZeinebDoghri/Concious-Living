import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/constants.dart';
import '../../../core/models/scan_history_item.dart';
import '../../../providers/scan_history_provider.dart';
import '../../../shared/widgets/animated_button.dart';
import '../../../shared/widgets/olive_header.dart';

class StaffScanResultScreen extends StatefulWidget {
  final Map<String, dynamic> args;

  const StaffScanResultScreen({super.key, required this.args});

  @override
  State<StaffScanResultScreen> createState() => _StaffScanResultScreenState();
}

class _StaffScanResultScreenState extends State<StaffScanResultScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final TextEditingController _dishNameController;

  bool _saved = false;

  @override
  void initState() {
    super.initState();

    final initialDishName = (widget.args['dishName'] as String?)?.trim() ?? '';
    _dishNameController = TextEditingController(text: initialDishName);

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _dishNameController.dispose();
    super.dispose();
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _save() async {
    if (_saved) return;

    final dish = _dishNameController.text.trim().isEmpty
        ? 'Scan Result'
        : _dishNameController.text.trim();

    final imagePath = (widget.args['imagePath'] as String?)?.trim();

    final item = ScanHistoryItem(
      dishName: dish,
      scannedAt: DateTime.now(),
      result: null,
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
    final freshnessResult = (widget.args['freshnessResult'] as Map<String, dynamic>?) ?? {};
    final compostResult = (widget.args['compostResult'] as Map<String, dynamic>?) ?? {};

    return Scaffold(
      backgroundColor: AppColors.oat,
      body: SafeArea(
        child: Column(
          children: [
            const OliveHeader(
              title: 'Analysis Results',
              subtitle: 'Freshness & Compost insights',
              showBack: true,
              height: 140,
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
                  child: FadeTransition(
                    opacity: _fadeController,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Image Preview
                        if (imagePath != null && imagePath.isNotEmpty) ...[
                          Hero(
                            tag: 'scan_image',
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(AppRadii.screenCard),
                              child: AspectRatio(
                                aspectRatio: 16 / 10,
                                child: kIsWeb
                                    ? Container(
                                        color: Colors.grey[300],
                                        child: const Center(
                                          child: Icon(Icons.image),
                                        ),
                                      )
                                    : Image.file(
                                        File(imagePath),
                                        fit: BoxFit.cover,
                                      ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                        ],

                        // Dish Name Input
                        TextField(
                          controller: _dishNameController,
                          decoration: const InputDecoration(
                            labelText: 'Dish / item name',
                            prefixIcon: Icon(
                              Icons.restaurant_menu,
                              color: AppColors.cocoa,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // SECTION 1: FRESHNESS ANALYSIS
                        _buildFreshnessCard(freshnessResult),
                        const SizedBox(height: 16),

                        // SECTION 2: COMPOST ANALYSIS
                        _buildCompostCard(compostResult),
                        const SizedBox(height: 24),

                        // Action Buttons
                        AnimatedButton(
                          label: _saved ? 'Saved' : 'Save scan',
                          color: _saved ? AppColors.olive : AppColors.olive,
                          textColor: AppColors.butter,
                          onTap: _save,
                          height: 52,
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: () => context.go(AppRoutes.restaurantWaste),
                          icon: const Icon(Icons.delete_outline),
                          label: const Text('Go to Waste'),
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          onPressed: () =>
                              context.go(AppRoutes.restaurantInventory),
                          icon: const Icon(Icons.inventory_2_outlined),
                          label: const Text('Go to Inventory & Expiry'),
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton(
                          onPressed: () => context.go(AppRoutes.restaurantScan),
                          child: const Text('Scan another dish'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFreshnessCard(Map<String, dynamic> result) {
    final status = (result['status'] as String?)?.toLowerCase() ?? 'unknown';
    final confidence = (result['confidence'] as num?)?.toDouble() ?? 0.0;
    final confidencePct = (confidence * 100).toStringAsFixed(1);

    // Determine colors and icons based on status
    Color bgColor;
    Color iconColor;
    String statusText;
    Color borderColor;

    switch (status) {
      case 'fresh':
        bgColor = const Color(0xFFF0FFF4);
        iconColor = const Color(0xFF10B981);
        statusText = 'Fraîche ✅';
        borderColor = const Color(0xFFA7F3D0);
        break;
      case 'not_fresh':
        bgColor = const Color(0xFFFFF5F5);
        iconColor = const Color(0xFFEF4444);
        statusText = 'Pas Fraîche ❌';
        borderColor = const Color(0xFFFCA5A5);
        break;
      default:
        bgColor = const Color(0xFFF3F4F6);
        iconColor = const Color(0xFF6B7280);
        statusText = 'Non détecté';
        borderColor = const Color(0xFFD1D5DB);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppRadii.innerCard),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: iconColor.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                status == 'fresh'
                    ? Icons.check_circle_rounded
                    : status == 'not_fresh'
                        ? Icons.cancel_rounded
                        : Icons.help_outline_rounded,
                color: iconColor,
                size: 48,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Freshness Analysis 🌡️',
                      style: GoogleFonts.sora(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.espresso,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      statusText,
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: iconColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Confiance: $confidencePct%',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.cocoa,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Confidence bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: confidence.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: Colors.white.withValues(alpha: 0.5),
              valueColor: AlwaysStoppedAnimation<Color>(iconColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompostCard(Map<String, dynamic> result) {
    final compostablePct = ((result['compostablePct'] as num?)?.toDouble() ?? 0.0)
        .clamp(0.0, 100.0);
    final nonCompostablePct = ((result['nonCompostablePct'] as num?)?.toDouble() ?? 0.0)
        .clamp(0.0, 100.0);
    final backgroundPct = ((result['backgroundPct'] as num?)?.toDouble() ?? 0.0)
        .clamp(0.0, 100.0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(AppRadii.innerCard),
        border: Border.all(
          color: const Color(0xFFA7F3D0),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.eco_rounded,
                color: const Color(0xFF10B981),
                size: 48,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Compost Analysis 🌱',
                      style: GoogleFonts.sora(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.espresso,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Segmentation Results',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.cocoa,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Compostable percentage
          _buildPercentageItem(
            label: 'Compostable',
            value: compostablePct,
            color: const Color(0xFF10B981),
          ),
          const SizedBox(height: 10),
          // Non-compostable percentage
          _buildPercentageItem(
            label: 'Non-Compostable',
            value: nonCompostablePct,
            color: const Color(0xFFEF4444),
          ),
          const SizedBox(height: 10),
          // Background percentage
          _buildPercentageItem(
            label: 'Background',
            value: backgroundPct,
            color: const Color(0xFF9CA3AF),
          ),
        ],
      ),
    );
  }

  Widget _buildPercentageItem({
    required String label,
    required double value,
    required Color color,
  }) {
    final displayValue = value.toStringAsFixed(1);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.cocoa,
              ),
            ),
            Text(
              '$displayValue%',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: (value / 100).clamp(0.0, 1.0),
            minHeight: 5,
            backgroundColor: color.withValues(alpha: 0.15),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}
