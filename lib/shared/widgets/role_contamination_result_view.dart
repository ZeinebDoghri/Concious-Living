import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/brand_palette.dart';
import '../animations/animated_gradient.dart';
import '../animations/organic_blobs.dart';
import '../animations/pressable.dart';
import 'role_scan_experience.dart';

class RoleContaminationResultView extends StatelessWidget {
  final ScanExperienceRole role;
  final String title;
  final String subtitle;
  final Widget preview;
  final bool isContaminated;
  final bool yoloOverrode;
  final int detectionCount;
  final double cleanPct;
  final double contaminatedPct;
  final double confidence;
  final List<String> detections;
  final VoidCallback onPrimary;
  final VoidCallback onScanAgain;
  final VoidCallback onBack;

  const RoleContaminationResultView({
    super.key,
    required this.role,
    required this.title,
    required this.subtitle,
    required this.preview,
    required this.isContaminated,
    required this.yoloOverrode,
    required this.detectionCount,
    required this.cleanPct,
    required this.contaminatedPct,
    required this.confidence,
    required this.detections,
    required this.onPrimary,
    required this.onScanAgain,
    required this.onBack,
  });

  bool get _hotel => role == ScanExperienceRole.hotel;
  Color get _primary => _hotel ? kHotel1 : kRest1;
  Color get _deep => _hotel ? kHotel2 : kRest2;
  Color get _surface => _hotel ? kHotel3 : kRest3;
  Color get _soft => _hotel ? kHotel4 : kRest4;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: Column(
        children: [
          _HeroHeader(
            title: title,
            subtitle: subtitle,
            role: role,
            onBack: onBack,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(_hotel ? 16 : 12),
                    child: preview,
                  ),
                  const SizedBox(height: 18),
                  if (_hotel)
                    _HotelGaugeCard(
                      score: cleanPct,
                      primary: _primary,
                      deep: _deep,
                      surface: _surface,
                    )
                  else
                    _RestaurantRadarCard(
                      cleanPct: cleanPct,
                      contaminatedPct: contaminatedPct,
                      confidence: confidence,
                      detectionCount: detectionCount,
                      yoloOverrode: yoloOverrode,
                      primary: _primary,
                      deep: _deep,
                      surface: _surface,
                      soft: _soft,
                    ),
                  const SizedBox(height: 16),
                  _hotel
                      ? _HotelDetailRows(
                          cleanPct: cleanPct,
                          contaminatedPct: contaminatedPct,
                          confidence: confidence,
                          detectionCount: detectionCount,
                          primary: _primary,
                          deep: _deep,
                          surface: _surface,
                        )
                      : _RestaurantMacroBars(
                          cleanPct: cleanPct,
                          contaminatedPct: contaminatedPct,
                          confidence: confidence,
                          detectionCount: detectionCount,
                          primary: _primary,
                          deep: _deep,
                          soft: _soft,
                        ),
                  const SizedBox(height: 16),
                  _RiskPanel(
                    role: role,
                    isContaminated: isContaminated,
                    color: isContaminated ? kDanger : kSuccess,
                    surface: _surface,
                    primary: _primary,
                    deep: _deep,
                  ),
                  const SizedBox(height: 16),
                  _DetectionSection(
                    role: role,
                    detections: detections,
                    primary: _primary,
                    deep: _deep,
                    surface: _surface,
                    soft: _soft,
                  ),
                  const SizedBox(height: 20),
                  _PrimaryAction(
                    label: _hotel ? 'Recommend to Guest' : 'Adapt Recipe',
                    icon: _hotel
                        ? Icons.send_rounded
                        : Icons.room_service_rounded,
                    primary: _primary,
                    deep: _deep,
                    pill: _hotel,
                    onTap: onPrimary,
                  ),
                  const SizedBox(height: 10),
                  Pressable(
                    onTap: onScanAgain,
                    child: Container(
                      height: 50,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: kCard,
                        borderRadius: BorderRadius.circular(_hotel ? 999 : 16),
                        border: Border.all(color: _soft),
                      ),
                      child: Text(
                        'Scan Again',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _deep,
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
    );
  }
}

class _HeroHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final ScanExperienceRole role;
  final VoidCallback onBack;

  const _HeroHeader({
    required this.title,
    required this.subtitle,
    required this.role,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final hotel = role == ScanExperienceRole.hotel;
    final colors = hotel
        ? [kHotel2, kHotel1, const Color(0xFF9CD6B6)]
        : [kRest2, kRest1, const Color(0xFFF8C0A0)];
    final soft = hotel ? kHotel4 : kRest3;

    return AnimatedGradientHero(
      colors: colors,
      height: hotel ? 240 : 220,
      child: Stack(
        children: [
          const Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBlobs(color: Colors.white, count: 2),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Pressable(
                    onTap: onBack,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    title,
                    style: GoogleFonts.lora(
                      fontSize: hotel ? 22 : 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(hotel ? 999 : 8),
                    ),
                    child: Text(
                      subtitle.toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: soft,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RestaurantRadarCard extends StatelessWidget {
  final double cleanPct;
  final double contaminatedPct;
  final double confidence;
  final int detectionCount;
  final bool yoloOverrode;
  final Color primary;
  final Color deep;
  final Color surface;
  final Color soft;

  const _RestaurantRadarCard({
    required this.cleanPct,
    required this.contaminatedPct,
    required this.confidence,
    required this.detectionCount,
    required this.yoloOverrode,
    required this.primary,
    required this.deep,
    required this.surface,
    required this.soft,
  });

  @override
  Widget build(BuildContext context) {
    final values = [
      (cleanPct / 100).clamp(0.0, 1.0),
      (1 - contaminatedPct / 100).clamp(0.0, 1.0),
      (confidence / 100).clamp(0.0, 1.0),
      (1 - detectionCount / 8).clamp(0.0, 1.0),
      yoloOverrode ? 0.72 : 0.92,
    ];
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primary.withValues(alpha: 0.35), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Nutritional safety radar',
            style: GoogleFonts.lora(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: deep,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 210,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              builder: (context, t, child) => CustomPaint(
                painter: _RadarChartPainter(
                  values: values.map((v) => v * t).toList(growable: false),
                  primary: primary,
                  soft: soft,
                  deep: deep,
                ),
                child: const SizedBox.expand(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RadarChartPainter extends CustomPainter {
  final List<double> values;
  final Color primary;
  final Color soft;
  final Color deep;

  _RadarChartPainter({
    required this.values,
    required this.primary,
    required this.soft,
    required this.deep,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) * 0.36;
    final labels = ['Clean', 'Allergen', 'Confidence', 'Fresh', 'Visual'];
    final gridPaint = Paint()
      ..color = soft.withValues(alpha: 0.65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final fillPaint = Paint()
      ..color = primary.withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;
    final linePaint = Paint()
      ..color = primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (var ring = 1; ring <= 3; ring++) {
      final r = radius * ring / 3;
      final p = _polygon(center, r, List.filled(5, 1));
      canvas.drawPath(p, gridPaint);
    }
    for (var i = 0; i < 5; i++) {
      final a = -pi / 2 + i * 2 * pi / 5;
      final end = Offset(
        center.dx + cos(a) * radius,
        center.dy + sin(a) * radius,
      );
      canvas.drawLine(center, end, gridPaint);
      final tp = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: GoogleFonts.inter(fontSize: 10, color: kText2),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final lp = Offset(
        center.dx + cos(a) * (radius + 20) - tp.width / 2,
        center.dy + sin(a) * (radius + 20) - tp.height / 2,
      );
      tp.paint(canvas, lp);
    }
    final path = _polygon(center, radius, values);
    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, linePaint);
  }

  Path _polygon(Offset center, double radius, List<double> values) {
    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final a = -pi / 2 + i * 2 * pi / values.length;
      final p = Offset(
        center.dx + cos(a) * radius * values[i],
        center.dy + sin(a) * radius * values[i],
      );
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    return path..close();
  }

  @override
  bool shouldRepaint(_RadarChartPainter oldDelegate) => true;
}

class _HotelGaugeCard extends StatelessWidget {
  final double score;
  final Color primary;
  final Color deep;
  final Color surface;

  const _HotelGaugeCard({
    required this.score,
    required this.primary,
    required this.deep,
    required this.surface,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kHotel4),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 170,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: (score / 100).clamp(0.0, 1.0)),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutBack,
              builder: (context, t, child) => CustomPaint(
                painter: _SemicircleGaugePainter(
                  progress: t,
                  primary: primary,
                  deep: deep,
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 44),
                    child: Text(
                      '${(t * 100).round()}',
                      style: GoogleFonts.lora(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: deep,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Poor',
                style: GoogleFonts.inter(fontSize: 10, color: kText3),
              ),
              Text(
                'Excellent',
                style: GoogleFonts.inter(fontSize: 10, color: kText3),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SemicircleGaugePainter extends CustomPainter {
  final double progress;
  final Color primary;
  final Color deep;

  _SemicircleGaugePainter({
    required this.progress,
    required this.primary,
    required this.deep,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.82);
    final radius = min(size.width * 0.38, size.height * 0.72);
    final rect = Rect.fromCircle(center: center, radius: radius);
    final bgPaint = Paint()
      ..color = kHotel3
      ..strokeWidth = 12
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final fillPaint = Paint()
      ..shader = LinearGradient(colors: [primary, deep]).createShader(rect)
      ..strokeWidth = 12
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, pi, pi, false, bgPaint);
    canvas.drawArc(rect, pi, pi * progress, false, fillPaint);

    final angle = pi + pi * progress;
    final needleEnd = Offset(
      center.dx + cos(angle) * (radius - 12),
      center.dy + sin(angle) * (radius - 12),
    );
    final needlePaint = Paint()
      ..color = deep
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(center, needleEnd, needlePaint);
    canvas.drawCircle(center, 5, Paint()..color = deep);
  }

  @override
  bool shouldRepaint(_SemicircleGaugePainter oldDelegate) => true;
}

class _RestaurantMacroBars extends StatelessWidget {
  final double cleanPct;
  final double contaminatedPct;
  final double confidence;
  final int detectionCount;
  final Color primary;
  final Color deep;
  final Color soft;

  const _RestaurantMacroBars({
    required this.cleanPct,
    required this.contaminatedPct,
    required this.confidence,
    required this.detectionCount,
    required this.primary,
    required this.deep,
    required this.soft,
  });

  @override
  Widget build(BuildContext context) {
    final rows = [
      ('Clean', cleanPct, kSuccess),
      ('Contaminated', contaminatedPct, kDanger),
      ('Confidence', confidence, deep),
      ('Detections', (detectionCount * 12.5).clamp(0, 100).toDouble(), primary),
    ];
    return Column(
      children: rows
          .asMap()
          .entries
          .map((entry) {
            final row = entry.value;
            return _AnimatedBarRow(
              label: row.$1,
              value: row.$2,
              color: row.$3,
              delay: Duration(milliseconds: 150 + entry.key * 150),
              compact: true,
            );
          })
          .toList(growable: false),
    );
  }
}

class _HotelDetailRows extends StatelessWidget {
  final double cleanPct;
  final double contaminatedPct;
  final double confidence;
  final int detectionCount;
  final Color primary;
  final Color deep;
  final Color surface;

  const _HotelDetailRows({
    required this.cleanPct,
    required this.contaminatedPct,
    required this.confidence,
    required this.detectionCount,
    required this.primary,
    required this.deep,
    required this.surface,
  });

  @override
  Widget build(BuildContext context) {
    final rows = [
      (
        Icons.verified_rounded,
        'Clean score',
        '${cleanPct.toStringAsFixed(1)}%',
        cleanPct,
      ),
      (
        Icons.warning_rounded,
        'Contamination',
        '${contaminatedPct.toStringAsFixed(1)}%',
        contaminatedPct,
      ),
      (
        Icons.analytics_rounded,
        'Confidence',
        '${confidence.toStringAsFixed(1)}%',
        confidence,
      ),
      (
        Icons.search_rounded,
        'Detected items',
        '$detectionCount',
        (detectionCount * 12.5).clamp(0, 100).toDouble(),
      ),
    ];
    return Column(
      children: rows
          .asMap()
          .entries
          .map((entry) {
            final row = entry.value;
            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: Duration(milliseconds: 450 + entry.key * 60),
              curve: Curves.easeOutCubic,
              builder: (_, t, child) => Opacity(
                opacity: t,
                child: Transform.translate(
                  offset: Offset((1 - t) * 24, 0),
                  child: child,
                ),
              ),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: kCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: kHotel4.withValues(alpha: 0.7)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: surface,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(row.$1, color: primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            row.$2,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: kText2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            row.$3,
                            style: GoogleFonts.lora(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: deep,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 70,
                      child: LinearProgressIndicator(
                        value: (row.$4 / 100).clamp(0.0, 1.0),
                        minHeight: 4,
                        color: primary,
                        backgroundColor: surface,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ],
                ),
              ),
            );
          })
          .toList(growable: false),
    );
  }
}

class _AnimatedBarRow extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final Duration delay;
  final bool compact;

  const _AnimatedBarRow({
    required this.label,
    required this.value,
    required this.color,
    required this.delay,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: (value / 100).clamp(0.0, 1.0)),
      duration: delay,
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kRest4.withValues(alpha: 0.55)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 92,
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: kText2,
                ),
              ),
            ),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: t,
                  minHeight: 8,
                  color: color,
                  backgroundColor: kRest3,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              '${value.toStringAsFixed(0)}%',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RiskPanel extends StatelessWidget {
  final ScanExperienceRole role;
  final bool isContaminated;
  final Color color;
  final Color surface;
  final Color primary;
  final Color deep;

  const _RiskPanel({
    required this.role,
    required this.isContaminated,
    required this.color,
    required this.surface,
    required this.primary,
    required this.deep,
  });

  @override
  Widget build(BuildContext context) {
    final hotel = role == ScanExperienceRole.hotel;
    final title = hotel
        ? (isContaminated
              ? 'Verify allergens before recommending'
              : 'Product cleared - safe to recommend')
        : (isContaminated
              ? 'Do not serve - risk detected'
              : 'All clear - safe to serve');
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(hotel ? 16 : 12),
        border: Border(
          top: BorderSide(
            color: hotel ? color : primary,
            width: hotel ? 3 : 1.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            hotel
                ? (isContaminated
                      ? Icons.warning_rounded
                      : Icons.verified_rounded)
                : Icons.room_service_rounded,
            color: color,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.lora(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: hotel ? kText2 : color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetectionSection extends StatelessWidget {
  final ScanExperienceRole role;
  final List<String> detections;
  final Color primary;
  final Color deep;
  final Color surface;
  final Color soft;

  const _DetectionSection({
    required this.role,
    required this.detections,
    required this.primary,
    required this.deep,
    required this.surface,
    required this.soft,
  });

  @override
  Widget build(BuildContext context) {
    final labels = detections.isEmpty
        ? ['No contamination detected']
        : detections;
    final hotel = role == ScanExperienceRole.hotel;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(hotel ? 16 : 8),
        border: Border.all(color: soft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            hotel ? 'Luxury label review' : 'Kitchen labels',
            style: GoogleFonts.lora(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: deep,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: labels
                .asMap()
                .entries
                .map((entry) {
                  final text = entry.value;
                  return TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: Duration(milliseconds: 260 + entry.key * 70),
                    curve: Curves.easeOutCubic,
                    builder: (_, t, child) => Opacity(
                      opacity: t,
                      child: Transform.scale(
                        scale: hotel ? 0.7 + t * 0.3 : 1,
                        child: Transform.translate(
                          offset: hotel ? Offset.zero : Offset((1 - t) * 16, 0),
                          child: child,
                        ),
                      ),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: hotel ? surface : soft,
                        borderRadius: BorderRadius.circular(hotel ? 999 : 6),
                        border: Border.all(color: soft),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (hotel) ...[
                            Icon(Icons.spa_rounded, color: primary, size: 14),
                            const SizedBox(width: 6),
                          ],
                          Text(
                            text,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: deep,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                })
                .toList(growable: false),
          ),
        ],
      ),
    );
  }
}

class _PrimaryAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color primary;
  final Color deep;
  final bool pill;
  final VoidCallback onTap;

  const _PrimaryAction({
    required this.label,
    required this.icon,
    required this.primary,
    required this.deep,
    required this.pill,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        height: pill ? 56 : 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [primary, deep]),
          borderRadius: BorderRadius.circular(pill ? 999 : 16),
          boxShadow: [
            BoxShadow(
              color: primary.withValues(alpha: 0.28),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 19),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
