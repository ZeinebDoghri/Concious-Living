import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:provider/provider.dart';

import '../../../core/constants.dart';
import '../../../providers/user_provider.dart';
import '../../../services/nutrient_tracking_service.dart';

// Colors based on specs
const _kTeal = Color(0xFF45C4B0);
const _kAmber = Color(0xFFFFB347);
const _kPink = Color(0xFFFF6B8A);
const _kPrimary = Color(0xFFC4748A);

class CalorieTrackerScreen extends StatefulWidget {
  const CalorieTrackerScreen({super.key});

  @override
  State<CalorieTrackerScreen> createState() => _CalorieTrackerScreenState();
}

class _CalorieTrackerScreenState extends State<CalorieTrackerScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final todayStr = DateFormat('MMM d, yyyy').format(DateTime.now());

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Column(
          children: [
            Text(
              'Calorie Tracker',
              style: GoogleFonts.playfairDisplay(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              todayStr,
              style: GoogleFonts.inter(
                color: Colors.black54,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
      body: StreamBuilder<Map<String, dynamic>>(
        stream: NutrientTrackingService.watchTodayLog(user.id),
        builder: (context, snap) {
          final log = snap.data ?? {};

          final consumedCal = (log['calories'] ?? 0.0) as double;
          final consumedProtein = (log['protein_g'] ?? 0.0) as double;
          final consumedCarbs = (log['carbs_g'] ?? 0.0) as double;
          final consumedFat = (log['fat_g'] ?? 0.0) as double;

          final goalCal = (user.calorieGoal ?? 2000).toDouble();
          final goalProtein = (goalCal * 0.25) / 4.0;
          final goalCarbs = (goalCal * 0.50) / 4.0;
          final goalFat = (goalCal * 0.25) / 9.0;

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              _buildBar(
                title: 'Calories',
                consumed: consumedCal,
                goal: goalCal,
                unit: 'kcal',
                color: _kPrimary,
              ),
              const SizedBox(height: 24),
              _buildBar(
                title: 'Protein',
                consumed: consumedProtein,
                goal: goalProtein,
                unit: 'g',
                color: _kTeal,
              ),
              const SizedBox(height: 24),
              _buildBar(
                title: 'Carbs',
                consumed: consumedCarbs,
                goal: goalCarbs,
                unit: 'g',
                color: _kAmber,
              ),
              const SizedBox(height: 24),
              _buildBar(
                title: 'Fat',
                consumed: consumedFat,
                goal: goalFat,
                unit: 'g',
                color: _kPink,
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () => context.push(AppRoutes.healthGoals),
                  child: Text(
                    'View Health Goals',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBar({
    required String title,
    required double consumed,
    required double goal,
    required String unit,
    required Color color,
  }) {
    final rawPct = goal > 0 ? consumed / goal : 0.0;
    final pct = rawPct.clamp(0.0, 1.0);
    final remaining = goal - consumed;

    bool isWarning = rawPct >= 0.75 && rawPct < 1.0;
    bool isDanger = rawPct >= 1.0;
    Color barColor = isDanger ? _kPink : color;

    Widget bar = LinearPercentIndicator(
      lineHeight: 14.0,
      percent: pct,
      backgroundColor: const Color(0xFFF0F0F0),
      progressColor: barColor,
      barRadius: const Radius.circular(7),
      padding: EdgeInsets.zero,
      animation: true,
      animationDuration: 800,
    );

    if (isWarning) {
      bar = AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          return Opacity(
            opacity: 0.7 + (_pulseController.value * 0.3),
            child: child,
          );
        },
        child: bar,
      );
    } else if (isDanger) {
      bar = Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(7),
          boxShadow: [
            BoxShadow(
              color: _kPink.withOpacity(0.5),
              blurRadius: 8,
              spreadRadius: 2,
            )
          ],
        ),
        child: bar,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            if (isDanger)
              Row(
                children: [
                  const Icon(Icons.warning_rounded, color: _kPink, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    'Limit reached',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _kPink,
                    ),
                  ),
                ],
              ),
          ],
        ),
        const SizedBox(height: 8),
        bar,
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${consumed.toStringAsFixed(1)} $unit',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: barColor,
                  ),
                ),
                Text(
                  'Consumed',
                  style: GoogleFonts.inter(fontSize: 10, color: Colors.black38),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${remaining.toStringAsFixed(1)} $unit',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: remaining < 0 ? _kPink : Colors.black87,
                  ),
                ),
                Text(
                  remaining < 0 ? 'Over limit' : 'Remaining',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: remaining < 0 ? _kPink : Colors.black38,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            'Daily Goal: ${goal.toStringAsFixed(0)} $unit',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: Colors.black26,
            ),
          ),
        ),
      ],
    );
  }
}
