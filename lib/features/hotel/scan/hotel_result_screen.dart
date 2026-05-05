import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../restaurant/scan/annotated_contamination_image.dart';
import '../../restaurant/scan/food_contamination_service.dart';

// Hotel brand colors
const _kCherry = Color(0xFF75070C);
const _kEmerald = Color(0xFF4F6815);
const _kRose = Color(0xFF75070C);
const _kAmber = Color(0xFFE8C84A);
const _kSlate = Color(0xFF8C7B7C);
const _kSurface = Color(0xFFEDE0D3);
const _kCard = Color(0xFFFAF5EE);
const _kBorder = Color(0xFFD9C9B4);

class HotelResultScreen extends StatefulWidget {
  final Map<String, dynamic> args;
  const HotelResultScreen({super.key, required this.args});

  @override
  State<HotelResultScreen> createState() => _HotelResultScreenState();
}

class _HotelResultScreenState extends State<HotelResultScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _enterCtrl;

  @override
  void initState() {
    super.initState();
    _enterCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();
  }

  @override
  void dispose() {
    _enterCtrl.dispose();
    super.dispose();
  }

  File? get _imageFile {
    if (kIsWeb) return null;
    final raw = widget.args['imageFile'];
    if (raw is File) return raw;
    final path = widget.args['imagePath'];
    if (path is String && path.trim().isNotEmpty) return File(path);
    return null;
  }

  Uint8List? get _imageBytes {
    final raw = widget.args['imageBytes'];
    if (raw is Uint8List) return raw;
    return null;
  }

  bool get _isFusion =>
      widget.args['isFusion'] == true &&
      widget.args.containsKey('freshnessResult');

  Map<String, dynamic> get _freshnessResult =>
      (widget.args['freshnessResult'] as Map<String, dynamic>?) ?? {};
  Map<String, dynamic> get _wasteResult =>
      (widget.args['wasteResult'] as Map<String, dynamic>?) ?? {};
  Map<String, dynamic> get _compostResult =>
      (widget.args['compostResult'] as Map<String, dynamic>?) ?? {};
  Map<String, dynamic> get _contaminationResult =>
      (widget.args['contaminationResult'] as Map<String, dynamic>?) ?? {};

  @override
  Widget build(BuildContext context) {
    if (!_isFusion) {
      return Scaffold(
        backgroundColor: _kSurface,
        appBar: AppBar(
          title: const Text('Result'),
          backgroundColor: _kCherry,
        ),
        body: const Center(child: Text('No fusion data')),
      );
    }

    return _buildFusion();
  }

  Widget _buildFusion() {
    final compostPct =
        (_compostResult['compostablePct'] as num?)?.toDouble() ?? 0.0;
    final status =
        ((_freshnessResult['status'] as String?) ?? 'fresh').toLowerCase();
    final contamination = _contaminationResult.isNotEmpty
        ? FoodAnalysisResult.fromJson(_contaminationResult)
        : null;
    final maskPng = _compostResult['maskPng'] as Uint8List?;
    final ms = (_compostResult['inferenceTimeMs'] as num?)?.toInt() ?? 920;

    return Scaffold(
      backgroundColor: _kSurface,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            automaticallyImplyLeading: false,
            backgroundColor: _kCherry,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (_imageBytes != null && contamination != null)
                    AnnotatedContaminationImage(
                      imageBytes: _imageBytes!,
                      detections: contamination.detections,
                    )
                  else
                    (_imageFile != null && !kIsWeb
                        ? Image.file(_imageFile!, fit: BoxFit.cover)
                        : Container(
                            color: _kCherry,
                            child: const Center(child: Text('No image')),
                          )),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          _kCherry.withValues(alpha: 0.7),
                          _kCherry,
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Résultats d\'analyse',
                            style: GoogleFonts.sora(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Fraîcheur · Déchets · Compost · Insectes',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.75),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _SectionCard(
                    title: '♻️ Compost IA',
                    subtitle: 'mask2former_fp32 · Swin-B · mIoU 0.86',
                    color: _kEmerald,
                    delay: 0,
                    child: _CompostCard(
                      maskPng: maskPng,
                      compostPct: compostPct,
                      nonCompostPct:
                          (_compostResult['nonCompostablePct'] as num?)
                                  ?.toDouble() ??
                              0.0,
                      bgPct: (_compostResult['backgroundPct'] as num?)
                              ?.toDouble() ??
                          0.0,
                      ms: ms,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _SectionCard(
                    title: '🌡️ Fraîcheur',
                    subtitle: 'Deep transfer learning model',
                    color: _kRose,
                    delay: 100,
                    child: _FreshnessCard(status: status),
                  ),
                  const SizedBox(height: 12),
                  _SectionCard(
                    title: '🗑️ Déchets détectés',
                    subtitle: 'Real-time pipeline',
                    color: _kAmber,
                    delay: 200,
                    child: _WasteCard(wasteResult: _wasteResult),
                  ),
                  const SizedBox(height: 12),
                  if (contamination != null)
                    _contaminationCard(
                      contamination: contamination,
                      imageBytes: _imageBytes,
                    ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _contaminationCard({
    required FoodAnalysisResult contamination,
    Uint8List? imageBytes,
  }) {
    final confPct = (contamination.confidence * 100).toStringAsFixed(1);

    return Column(
      children: [
        _SectionCard(
          title: '🔍 Insectes & Contamination',
          subtitle: 'YOLO detection',
          color: Colors.red.shade600,
          delay: 300,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (imageBytes != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: SizedBox(
                    height: 200,
                    width: double.infinity,
                    child: AnnotatedContaminationImage(
                      imageBytes: imageBytes,
                      detections: contamination.detections,
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: contamination.label == 'clean'
                      ? Colors.green.shade50
                      : Colors.red.shade50,
                  border: Border.all(
                    color: contamination.label == 'clean'
                        ? Colors.green.shade300
                        : Colors.red.shade300,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      contamination.label == 'clean'
                          ? '✓ Clean'
                          : '⚠ Contaminated',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: contamination.label == 'clean'
                            ? Colors.green.shade700
                            : Colors.red.shade700,
                      ),
                    ),
                    Text(
                      '$confPct%',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: contamination.label == 'clean'
                            ? Colors.green.shade700
                            : Colors.red.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _ConfidenceBar(
                      label: 'Clean',
                      percentage: contamination.cleanPct,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ConfidenceBar(
                      label: 'Contaminated',
                      percentage: contamination.contaminatedPct,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
              if (contamination.detections.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'Detected: ${contamination.detectionCount} items',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: _kSlate,
                  ),
                ),
                const SizedBox(height: 8),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: contamination.detections.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 4),
                  itemBuilder: (_, i) {
                    final det = contamination.detections[i];
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          det.label,
                          style: GoogleFonts.inter(fontSize: 11),
                        ),
                        Text(
                          '${(det.confidence * 100).toStringAsFixed(0)}%',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _kSlate,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color color;
  final int delay;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.delay,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _kCard,
        border: Border.all(color: _kBorder),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              border: Border(
                bottom: BorderSide(
                  color: color.withValues(alpha: 0.2),
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.sora(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: _kSlate,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: child,
          ),
        ],
      ),
    ).animate().fadeIn(duration: Duration(milliseconds: delay)).slideY(
          begin: 0.2,
          duration: Duration(milliseconds: 600 + delay),
        );
  }
}

class _CompostCard extends StatelessWidget {
  final Uint8List? maskPng;
  final double compostPct;
  final double nonCompostPct;
  final double bgPct;
  final int ms;

  const _CompostCard({
    required this.maskPng,
    required this.compostPct,
    required this.nonCompostPct,
    required this.bgPct,
    required this.ms,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            height: 210,
            width: double.infinity,
            child: maskPng != null
                ? Image.memory(
                    maskPng!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => _MaskFallback(
                      compostPct: compostPct,
                      nonCompostPct: nonCompostPct,
                      bgPct: bgPct,
                    ),
                  )
                : _MaskFallback(
                    compostPct: compostPct,
                    nonCompostPct: nonCompostPct,
                    bgPct: bgPct,
                  ),
          ),
        ),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _Dot(color: _kEmerald),
          const SizedBox(width: 4),
          Text('Compostable',
              style: GoogleFonts.inter(fontSize: 11, color: _kSlate)),
          const SizedBox(width: 14),
          _Dot(color: _kRose),
          const SizedBox(width: 4),
          Text('Non-compost.',
              style: GoogleFonts.inter(fontSize: 11, color: _kSlate)),
        ]),
        const SizedBox(height: 12),
        _ConfidenceBar(label: 'Compostable', percentage: compostPct, color: _kEmerald),
        const SizedBox(height: 6),
        _ConfidenceBar(label: 'Non-Compostable', percentage: nonCompostPct, color: _kRose),
        const SizedBox(height: 12),
        Text('Inference: ${ms}ms',
            style: GoogleFonts.inter(fontSize: 10, color: _kSlate)),
      ],
    );
  }
}

class _MaskFallback extends StatelessWidget {
  final double compostPct;
  final double nonCompostPct;
  final double bgPct;

  const _MaskFallback({
    required this.compostPct,
    required this.nonCompostPct,
    required this.bgPct,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Color(0xFFFAF5EE),
      child: Center(
        child: Text(
          'Compostable: ${compostPct.toStringAsFixed(1)}%',
          style: GoogleFonts.inter(fontSize: 12),
        ),
      ),
    );
  }
}

class _FreshnessCard extends StatelessWidget {
  final String status;

  const _FreshnessCard({required this.status});

  @override
  Widget build(BuildContext context) {
    final isFresh = status == 'fresh';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isFresh ? Colors.green.shade50 : Colors.orange.shade50,
            border: Border.all(
              color:
                  isFresh ? Colors.green.shade300 : Colors.orange.shade300,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            isFresh ? '✓ Fresh' : '⚠ Not Fresh',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isFresh ? Colors.green.shade700 : Colors.orange.shade700,
            ),
          ),
        ),
      ],
    );
  }
}

class _WasteCard extends StatelessWidget {
  final Map<String, dynamic> wasteResult;

  const _WasteCard({required this.wasteResult});

  @override
  Widget build(BuildContext context) {
    final items = (wasteResult['detectedItems'] as List?)?.cast<Map>() ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (items.isNotEmpty)
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final item = items[i];
              final name = item['name'] ?? 'Unknown';
              final kg = (item['quantityKg'] as num?)?.toStringAsFixed(2) ?? '0';
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(name,
                      style: GoogleFonts.inter(
                          fontSize: 12, fontWeight: FontWeight.w500)),
                  Text('~${kg}kg',
                      style: GoogleFonts.inter(
                          fontSize: 11,
                          color: _kSlate,
                          fontWeight: FontWeight.w600)),
                ],
              );
            },
          )
        else
          Text('No waste detected',
              style: GoogleFonts.inter(fontSize: 12, color: _kSlate)),
      ],
    );
  }
}

class _ConfidenceBar extends StatelessWidget {
  final String label;
  final double percentage;
  final Color color;

  const _ConfidenceBar({
    required this.label,
    required this.percentage,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: GoogleFonts.inter(fontSize: 11, color: _kSlate)),
            Text('${(percentage).toStringAsFixed(1)}%',
                style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _kSlate)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percentage / 100,
            minHeight: 8,
            backgroundColor: color.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  final Color color;
  const _Dot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}
