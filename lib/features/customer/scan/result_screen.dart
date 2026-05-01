import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:provider/provider.dart';

import '../../../core/constants.dart';
import '../../../core/models/nutrient_result.dart';
import '../../../core/models/scan_history_item.dart';
import '../../../core/venue_alert_service.dart';
import '../../../providers/scan_history_provider.dart';
import '../../../providers/user_provider.dart';

// ── Brand palette ──────────────────────────────────────────────────────────────
const _kOat       = Color(0xFFF0E6DA);
const _kParchment = Color(0xFFFAF5EE);
const _kCherry    = Color(0xFF75070C);
const _kCherryL   = Color(0xFF9E1A21);
const _kCherryB   = Color(0xFFFBBCBF);
const _kOlive     = Color(0xFF4F6815);
const _kOliveM    = Color(0xFFD4E8A8);
const _kButter    = Color(0xFFFFEDAB);
const _kButterD   = Color(0xFFE8C84A);
const _kSand      = Color(0xFFD9C9B4);
const _kCocoa     = Color(0xFF5C3D3F);
const _kEspresso  = Color(0xFF2C1A1B);
const _kFog       = Color(0xFF8C7B7C);

class ResultScreen extends StatefulWidget {
  final Map<String, dynamic> args;
  const ResultScreen({super.key, required this.args});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen>
    with TickerProviderStateMixin {
  late final AnimationController _gaugeCtrl;
  late final AnimationController _allergenPulse;
  late final TextEditingController _dishNameCtrl;
  bool _saved = false;
  bool _showAllergenAlert = false;

  @override
  void initState() {
    super.initState();
    _dishNameCtrl = TextEditingController(
      text: (widget.args['dishName'] as String?)?.trim() ?? '',
    );
    _gaugeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..forward();
    _allergenPulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    // Delay allergen check until after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<UserProvider>().currentUser;
      final conditions = user?.conditions ?? [];
      if (conditions.isNotEmpty) {
        setState(() => _showAllergenAlert = true);
        // 🔔 Cross-notification: if a venueId was passed (e.g. customer is at
        //    a restaurant or hotel), notify the staff dashboard in real time.
        final venueId   = widget.args['venueId'] as String?;
        final venueType = widget.args['venueType'] as String? ?? 'restaurant';
        if (venueId != null && venueId.isNotEmpty) {
          final result    = _parseResult();
          final dishName  = (widget.args['dishName'] as String?)?.trim() ?? 'Unknown dish';
          VenueAlertService.notifyVenue(
            venueId:      venueId,
            venueType:    venueType,
            customerId:   user?.id ?? '',
            customerName: user?.name ?? 'Customer',
            allergens:    conditions,
            productName:  dishName,
            riskLevel:    result.overallRisk,
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _gaugeCtrl.dispose();
    _allergenPulse.dispose();
    _dishNameCtrl.dispose();
    super.dispose();
  }

  NutrientResult _parseResult() {
    final raw = widget.args['result'];
    if (raw is Map<String, dynamic>) return NutrientResult.fromJson(raw);
    return NutrientResult.fromJson(const {});
  }

  Future<void> _save() async {
    if (_saved) return;
    final dish = _dishNameCtrl.text.trim().isEmpty ? 'Dish' : _dishNameCtrl.text.trim();
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: _kOlive,
        content: Row(children: [
          const Icon(Icons.check_circle, color: Colors.white),
          const SizedBox(width: 10),
          Text('Scan saved!', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }

  Color _riskColor(String risk) {
    if (risk == 'high') return _kCherry;
    if (risk == 'moderate') return _kButterD;
    return _kOlive;
  }

  Color _riskBg(String risk) {
    if (risk == 'high') return _kCherryB;
    if (risk == 'moderate') return _kButter;
    return _kOliveM;
  }

  String _riskLabel(String risk) {
    if (risk == 'high') return 'HIGH RISK';
    if (risk == 'moderate') return 'MODERATE';
    return 'LOW RISK';
  }

  IconData _riskIcon(String risk) {
    if (risk == 'high') return Icons.warning_rounded;
    if (risk == 'moderate') return Icons.info_rounded;
    return Icons.check_circle_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final imagePath = (widget.args['imagePath'] as String?)?.trim();
    final result    = _parseResult();
    final user      = context.watch<UserProvider>().currentUser;
    final conditions = user?.conditions ?? [];

    return Scaffold(
      backgroundColor: _kOat,
      body: Stack(
        children: [
          // ── Main scroll content ──────────────────────────────────────────
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Hero food photo
              SliverAppBar(
                expandedHeight: imagePath != null && imagePath.isNotEmpty ? 280 : 120,
                pinned: true,
                backgroundColor: _kCherry,
                leading: GestureDetector(
                  onTap: () => context.pop(),
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white, size: 18),
                  ),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: _HeroHeader(
                    imagePath: imagePath,
                    overallRisk: result.overallRisk,
                    riskColor: _riskColor(result.overallRisk),
                    riskLabel: _riskLabel(result.overallRisk),
                    riskIcon: _riskIcon(result.overallRisk),
                  ),
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 120),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([

                    // Dish name input
                    _DishNameField(controller: _dishNameCtrl)
                        .animate().fadeIn(delay: 100.ms).slideY(begin: 0.1, delay: 100.ms),

                    const SizedBox(height: 20),

                    // ── Chronic risk gauges ──────────────────────────────
                    _SectionLabel(label: 'Chronic Risk Analysis', icon: Icons.monitor_heart_rounded)
                        .animate().fadeIn(delay: 200.ms),

                    const SizedBox(height: 12),

                    _GaugeGrid(
                      result: result,
                      controller: _gaugeCtrl,
                    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.06, delay: 300.ms),

                    const SizedBox(height: 24),

                    // ── Allergen alert ───────────────────────────────────
                    if (conditions.isNotEmpty)
                      _AllergenAlert(
                        conditions: conditions,
                        pulseCtrl: _allergenPulse,
                      )
                          .animate()
                          .fadeIn(delay: 500.ms)
                          .slideY(begin: 0.08, delay: 500.ms)
                          .shake(delay: 700.ms, duration: 400.ms),

                    if (conditions.isNotEmpty) const SizedBox(height: 20),

                    // ── AI Recommendation ────────────────────────────────
                    if (result.message.isNotEmpty)
                      _RecommendationCard(message: result.message)
                          .animate().fadeIn(delay: 600.ms).slideY(begin: 0.06, delay: 600.ms),

                    if (result.message.isNotEmpty) const SizedBox(height: 20),

                    // ── Nutrient detail list ─────────────────────────────
                    _SectionLabel(label: 'Detailed Breakdown', icon: Icons.bar_chart_rounded)
                        .animate().fadeIn(delay: 700.ms),

                    const SizedBox(height: 12),

                    ..._buildNutrientRows(result),

                    const SizedBox(height: 28),

                    // ── Save button ──────────────────────────────────────
                    _SaveButton(saved: _saved, onTap: _save)
                        .animate().fadeIn(delay: 900.ms).slideY(begin: 0.1, delay: 900.ms),

                    const SizedBox(height: 12),

                    // ── New scan button ──────────────────────────────────
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: Container(
                        width: double.infinity,
                        height: 52,
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: _kSand, width: 1.5),
                        ),
                        child: Center(
                          child: Text(
                            '← New scan',
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: _kCocoa,
                            ),
                          ),
                        ),
                      ),
                    ).animate().fadeIn(delay: 1000.ms),
                  ]),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildNutrientRows(NutrientResult result) {
    final nutrients = [
      _NutrientRowData('Cholesterol',    result.cholesterol,    Icons.opacity_rounded,      delay: 750),
      _NutrientRowData('Saturated Fat',  result.saturatedFat,  Icons.water_drop_rounded,   delay: 800),
      _NutrientRowData('Sodium',         result.sodium,         Icons.grain_rounded,        delay: 850),
      _NutrientRowData('Sugar',          result.sugar,          Icons.cake_rounded,         delay: 900),
    ];
    return nutrients.map((n) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: _NutrientRow(data: n, controller: _gaugeCtrl)
          .animate()
          .fadeIn(delay: Duration(milliseconds: n.delay))
          .slideX(begin: -0.05, delay: Duration(milliseconds: n.delay)),
    )).toList();
  }
}

// ── Hero header ────────────────────────────────────────────────────────────────
class _HeroHeader extends StatelessWidget {
  final String? imagePath;
  final String  overallRisk;
  final Color   riskColor;
  final String  riskLabel;
  final IconData riskIcon;

  const _HeroHeader({
    required this.imagePath,
    required this.overallRisk,
    required this.riskColor,
    required this.riskLabel,
    required this.riskIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Background
        if (imagePath != null && imagePath!.isNotEmpty)
          Image.file(File(imagePath!), fit: BoxFit.cover)
        else
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_kCherry, _kCherryL],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Icon(Icons.restaurant_menu,
                color: Colors.white24, size: 80),
          ),

        // Gradient overlay
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.black.withValues(alpha: 0.0),
                Colors.black.withValues(alpha: 0.7),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),

        // Risk badge at bottom
        Positioned(
          bottom: 20,
          left: 20,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: riskColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: riskColor.withValues(alpha: 0.5),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(riskIcon, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text(
                  riskLabel,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          )
              .animate()
              .fadeIn(delay: 100.ms)
              .slideY(begin: 0.3, delay: 100.ms, curve: Curves.easeOutBack),
        ),

        // Title
        Positioned(
          bottom: 60,
          left: 20,
          child: Text(
            'Nutrition Analysis',
            style: GoogleFonts.sora(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ).animate().fadeIn(delay: 50.ms).slideY(begin: 0.2, delay: 50.ms),
        ),
      ],
    );
  }
}

// ── Gauge grid — 2×2 animated circles ─────────────────────────────────────────
class _GaugeGrid extends StatelessWidget {
  final NutrientResult result;
  final AnimationController controller;

  const _GaugeGrid({required this.result, required this.controller});

  @override
  Widget build(BuildContext context) {
    final items = [
      _GaugeData('Cholesterol',  result.cholesterol,  Icons.opacity_rounded,   0),
      _GaugeData('Sat. Fat',     result.saturatedFat, Icons.water_drop_rounded, 1),
      _GaugeData('Sodium',       result.sodium,        Icons.grain_rounded,     2),
      _GaugeData('Sugar',        result.sugar,         Icons.cake_rounded,      3),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 0.92,
      children: items.map((item) => _AnimatedGaugeTile(
        data: item,
        controller: controller,
      )).toList(),
    );
  }
}

class _GaugeData {
  final String       label;
  final NutrientValue nutrient;
  final IconData     icon;
  final int          index;
  const _GaugeData(this.label, this.nutrient, this.icon, this.index);
}

class _AnimatedGaugeTile extends StatelessWidget {
  final _GaugeData data;
  final AnimationController controller;

  const _AnimatedGaugeTile({required this.data, required this.controller});

  Color get _color {
    if (data.nutrient.riskLevel == 'high')     return _kCherry;
    if (data.nutrient.riskLevel == 'moderate') return _kButterD;
    return _kOlive;
  }

  Color get _bgColor {
    if (data.nutrient.riskLevel == 'high')     return _kCherryB;
    if (data.nutrient.riskLevel == 'moderate') return _kButter;
    return _kOliveM;
  }

  String get _riskEmoji {
    if (data.nutrient.riskLevel == 'high')     return '⚠️';
    if (data.nutrient.riskLevel == 'moderate') return '⚡';
    return '✅';
  }

  @override
  Widget build(BuildContext context) {
    final startDelay = data.index * 0.15;
    final curve = CurvedAnimation(
      parent: controller,
      curve: Interval(startDelay.clamp(0.0, 0.8), 1.0, curve: Curves.easeOutCubic),
    );
    final pct = (data.nutrient.dailyValuePct / 100).clamp(0.0, 1.0);

    return AnimatedBuilder(
      animation: curve,
      builder: (_, __) => Container(
        decoration: BoxDecoration(
          color: _bgColor.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _color.withValues(alpha: 0.3), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: _color.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularPercentIndicator(
              radius: 48,
              lineWidth: 7,
              percent: pct * curve.value,
              circularStrokeCap: CircularStrokeCap.round,
              backgroundColor: _color.withValues(alpha: 0.12),
              progressColor: _color,
              center: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(data.icon, color: _color, size: 16),
                  const SizedBox(height: 2),
                  Text(
                    '${(data.nutrient.dailyValuePct * curve.value).round()}%',
                    style: GoogleFonts.sora(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: _kEspresso,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              data.label,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: _kEspresso,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              '${data.nutrient.value.toStringAsFixed(1)} ${data.nutrient.unit}',
              style: GoogleFonts.inter(
                fontSize: 10,
                color: _kCocoa,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _riskEmoji + ' ' + data.nutrient.riskLevel.toUpperCase(),
              style: GoogleFonts.inter(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: _color,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    ).animate(controller: controller)
        .fadeIn(delay: Duration(milliseconds: data.index * 120))
        .scale(
          begin: const Offset(0.85, 0.85),
          end: const Offset(1, 1),
          delay: Duration(milliseconds: data.index * 120),
          curve: Curves.easeOutBack,
        );
  }
}

// ── Allergen Alert — dramatic pulsing ─────────────────────────────────────────
class _AllergenAlert extends StatelessWidget {
  final List<String>       conditions;
  final AnimationController pulseCtrl;

  const _AllergenAlert({required this.conditions, required this.pulseCtrl});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulseCtrl,
      builder: (_, __) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _kCherryB,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _kCherry.withValues(alpha: 0.5 + pulseCtrl.value * 0.4),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: _kCherry.withValues(alpha: 0.15 + pulseCtrl.value * 0.15),
              blurRadius: 16 + pulseCtrl.value * 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _kCherry.withValues(alpha: 0.12 + pulseCtrl.value * 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.warning_rounded,
                      color: _kCherry.withValues(alpha: 0.7 + pulseCtrl.value * 0.3),
                      size: 22),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '⚠️ ALLERGEN ALERT',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: _kCherry,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      'Check your profile conditions',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: _kCherryL,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Condition pills
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: conditions.take(6).map((c) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _kCherry.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _kCherry.withValues(alpha: 0.4)),
                ),
                child: Text(
                  c,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _kCherry,
                  ),
                ),
              )).toList(),
            ),
            const SizedBox(height: 10),
            Text(
              'Inform restaurant staff if you have concerns about this dish.',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: _kCherryL,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Recommendation card ────────────────────────────────────────────────────────
class _RecommendationCard extends StatelessWidget {
  final String message;
  const _RecommendationCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kOliveM.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _kOlive.withValues(alpha: 0.25), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: _kOlive.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.lightbulb_outline_rounded,
                color: _kOlive, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Recommendation',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _kOlive,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  message,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: _kEspresso,
                    height: 1.45,
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

// ── Section label ──────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String   label;
  final IconData icon;
  const _SectionLabel({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: _kCherry.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: _kCherry, size: 16),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: GoogleFonts.sora(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: _kEspresso,
          ),
        ),
      ],
    );
  }
}

// ── Nutrient detail row ────────────────────────────────────────────────────────
class _NutrientRowData {
  final String       label;
  final NutrientValue nutrient;
  final IconData     icon;
  final int          delay;
  const _NutrientRowData(this.label, this.nutrient, this.icon, {required this.delay});
}

class _NutrientRow extends StatelessWidget {
  final _NutrientRowData data;
  final AnimationController controller;

  const _NutrientRow({required this.data, required this.controller});

  Color get _color {
    if (data.nutrient.riskLevel == 'high')     return _kCherry;
    if (data.nutrient.riskLevel == 'moderate') return _kButterD;
    return _kOlive;
  }

  @override
  Widget build(BuildContext context) {
    final pct = (data.nutrient.dailyValuePct / 100).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kParchment,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kSand, width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(data.icon, color: _color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      data.label,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _kEspresso,
                      ),
                    ),
                    Text(
                      '${data.nutrient.value.toStringAsFixed(1)} ${data.nutrient.unit}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // Animated bar
                AnimatedBuilder(
                  animation: controller,
                  builder: (_, __) => ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: pct * controller.value,
                      minHeight: 6,
                      backgroundColor: _color.withValues(alpha: 0.12),
                      valueColor: AlwaysStoppedAnimation<Color>(_color),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${data.nutrient.dailyValuePct.round()}% of daily value',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: _kFog,
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

// ── Dish name field ────────────────────────────────────────────────────────────
class _DishNameField extends StatelessWidget {
  final TextEditingController controller;
  const _DishNameField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _kParchment,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kSand, width: 0.8),
      ),
      child: TextField(
        controller: controller,
        style: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: _kEspresso,
        ),
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.restaurant_menu, color: _kCherry, size: 20),
          hintText: 'Dish name (optional)',
          hintStyle: GoogleFonts.inter(color: _kFog, fontSize: 14),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}

// ── Save button ────────────────────────────────────────────────────────────────
class _SaveButton extends StatefulWidget {
  final bool saved;
  final VoidCallback onTap;
  const _SaveButton({required this.saved, required this.onTap});

  @override
  State<_SaveButton> createState() => _SaveButtonState();
}

class _SaveButtonState extends State<_SaveButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: widget.saved
                  ? [_kOlive, const Color(0xFF374A0F)]
                  : [_kCherry, _kCherryL],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: (widget.saved ? _kOlive : _kCherry).withValues(alpha: 0.4),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.saved ? Icons.check_circle_rounded : Icons.bookmark_add_rounded,
                color: Colors.white,
                size: 22,
              ),
              const SizedBox(width: 10),
              Text(
                widget.saved ? 'Saved to history ✓' : 'Save to history',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
