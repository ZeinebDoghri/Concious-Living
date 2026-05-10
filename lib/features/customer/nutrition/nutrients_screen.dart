import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/constants.dart';
import '../../../providers/user_provider.dart';
import '../../../services/nutrient_tracking_service.dart';
import '../../../shared/widgets/nutrient_progress_bar.dart';

const _bg = Color(0xFFFFF0F3);
const _card = Color(0xFFFFD6E0);
const _brand = Color(0xFFC4748A);
const _hotPink = Color(0xFFFF6B8A);
const _text = Color(0xFF7D3A4F);

class NutrientsScreen extends StatefulWidget {
  const NutrientsScreen({super.key});

  @override
  State<NutrientsScreen> createState() => _NutrientsScreenState();
}

class _NutrientsScreenState extends State<NutrientsScreen> {
  String get _today => DateFormat('yyyy-MM-dd').format(DateTime.now());

  @override
  Widget build(BuildContext context) {
    final uid = context.watch<UserProvider>().currentUser?.id ?? '';

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: uid.isEmpty
            ? const _LoadingSkeleton()
            : StreamBuilder<Map<String, dynamic>>(
                stream: NutrientTrackingService.watchTodayLog(uid),
                builder: (context, logSnap) {
                  return StreamBuilder<Map<String, dynamic>>(
                    stream: NutrientTrackingService.watchLimits(uid),
                    builder: (context, limitSnap) {
                      if (!logSnap.hasData || !limitSnap.hasData) {
                        return const _LoadingSkeleton();
                      }
                      final log = logSnap.data ?? const <String, dynamic>{};
                      final limits =
                          limitSnap.data ??
                          const {
                            'cholesterol_mg': 300,
                            'saturated_fat_g': 20,
                            'sodium_mg': 2300,
                            'sugar_g': 50,
                          };
                      return SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            _Header(today: _today),
                            const SizedBox(height: 18),
                            _SummaryCard(log: log, limits: limits),
                            const SizedBox(height: 14),
                            NutrientProgressBar(
                              label: 'Cholesterol',
                              value:
                                  (log['cholesterol_mg'] as num?)?.toDouble() ??
                                  0,
                              limit:
                                  (limits['cholesterol_mg'] as num?)
                                      ?.toDouble() ??
                                  300,
                              unit: 'mg',
                            ),
                            NutrientProgressBar(
                              label: 'Saturated Fat',
                              value:
                                  (log['saturated_fat_g'] as num?)
                                      ?.toDouble() ??
                                  0,
                              limit:
                                  (limits['saturated_fat_g'] as num?)
                                      ?.toDouble() ??
                                  20,
                              unit: 'g',
                            ),
                            NutrientProgressBar(
                              label: 'Sodium',
                              value:
                                  (log['sodium_mg'] as num?)?.toDouble() ?? 0,
                              limit:
                                  (limits['sodium_mg'] as num?)?.toDouble() ??
                                  2300,
                              unit: 'mg',
                            ),
                            NutrientProgressBar(
                              label: 'Sugar',
                              value: (log['sugar_g'] as num?)?.toDouble() ?? 0,
                              limit:
                                  (limits['sugar_g'] as num?)?.toDouble() ?? 50,
                              unit: 'g',
                            ),
                            const SizedBox(height: 18),
                            _SettingsButton(
                              onTap: () =>
                                  context.go('/customer/nutrition-goals'),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String today;

  const _Header({required this.today});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 22),
      decoration: const BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.canPop()
                ? context.pop()
                : context.go(AppRoutes.customerProfile),
            icon: const Icon(Icons.arrow_back_ios_rounded, color: _text),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nutrient tracker',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: _text,
                  ),
                ),
                Text(
                  today,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _text.withValues(alpha: 0.72),
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

class _SummaryCard extends StatelessWidget {
  final Map<String, dynamic> log;
  final Map<String, dynamic> limits;

  const _SummaryCard({required this.log, required this.limits});

  @override
  Widget build(BuildContext context) {
    double pct(String key) {
      final value = (log[key] as num?)?.toDouble() ?? 0;
      final limit = (limits[key] as num?)?.toDouble() ?? 1;
      return limit <= 0 ? 0 : value / limit;
    }

    final maxPct = [
      pct('cholesterol_mg'),
      pct('saturated_fat_g'),
      pct('sodium_mg'),
      pct('sugar_g'),
    ].reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEDE9FE),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFA78BFA).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.bolt_rounded, color: Color(0xFFA78BFA)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              maxPct >= 1
                  ? 'A daily limit has been reached.'
                  : 'Real-time progress from your saved scans.',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _text,
                height: 1.35,
              ),
            ),
          ),
          Text(
            '${(maxPct * 100).toStringAsFixed(0)}%',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: maxPct >= 1 ? _hotPink : const Color(0xFFA78BFA),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsButton extends StatelessWidget {
  final VoidCallback onTap;

  const _SettingsButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: _brand,
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            BoxShadow(
              color: _brand.withValues(alpha: 0.28),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Center(
          child: Text(
            'Adjust limits',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _LoadingSkeleton extends StatelessWidget {
  const _LoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Column(
          children: List.generate(
            4,
            (_) => Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
