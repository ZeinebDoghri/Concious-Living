import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/scan_result.dart';
import '../../../providers/user_provider.dart';
import '../../../services/cloudinary_service.dart';
import '../../../services/compost_ingestion_service.dart';
import '../../restaurant/scan/annotated_contamination_image.dart';
import '../../restaurant/scan/food_contamination_service.dart';

// Hotel brand colors
const _kCherry = Color(0xFF5A9FC9);
const _kEmerald = Color(0xFF52C98A);
const _kRose = Color(0xFFFF7070);
const _kAmber = Color(0xFFFFAB5B);
const _kSlate = Color(0xFF8C7E78);
const _kSurface = Color(0xFFF0F5F8);
const _kCard = Color(0xFFFFFFFF);
const _kBorder = Color(0xFFD9E9F5);

class HotelResultScreen extends StatefulWidget {
  final Map<String, dynamic> args;
  const HotelResultScreen({super.key, required this.args});

  @override
  State<HotelResultScreen> createState() => _HotelResultScreenState();
}

class _HotelResultScreenState extends State<HotelResultScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _enterCtrl;
  bool _compostIngested = false;

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
  Map<String, dynamic> get _nutritionResult =>
      (widget.args['nutritionResult'] as Map<String, dynamic>?) ?? {};

  Future<String> _hotelId() async {
    final user = context.read<UserProvider>().currentUser;
    final uid = user?.id ?? '';
    if (uid.isEmpty) return '';
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    final userData = userDoc.data() ?? <String, dynamic>{};
    return (userData['entityId'] ??
            userData['restaurantId'] ??
            userData['hotelId'] ??
            user?.entityId ??
            user?.hotelId ??
            uid)
        .toString();
  }

  Future<void> _ingestCompostScan() async {
    if (_compostIngested) return;
    final entityId = await _hotelId();
    if (entityId.isEmpty || _wasteResult.isEmpty) return;
    _compostIngested = true;

    final deptId = (widget.args['departmentId'] as String?)?.trim();
    final scan = ScanResult.fromVenueScan(
      id: 'hotel-${DateTime.now().millisecondsSinceEpoch}',
      entityId: entityId,
      departmentId: deptId == null || deptId.isEmpty ? null : deptId,
      timestamp: DateTime.now(),
      wasteResult: _wasteResult,
      compostResult: _compostResult,
    );
    await _saveHotelScan(scan);

    // Wrap secondary writes in try/catch — scan already saved successfully
    try {
      await CompostIngestionService.onScanComplete(scan);
    } catch (e) {
      // Log but don't show error — scan already saved to history
      debugPrint('CompostIngestion error (non-critical): $e');
    }

    // Show SUCCESS snackbar
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Scan saved to history'),
          backgroundColor: Color(0xFF5C7A3E),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _saveHotelScan(ScanResult scan) async {
    final user = context.read<UserProvider>().currentUser;
    final hotelId = await _hotelId();
    String? imageUrl;
    if (_imageBytes != null && _imageBytes!.isNotEmpty) {
      imageUrl = await CloudinaryService.uploadScanImage(
        _imageBytes!,
        folder: 'orka/hotel/$hotelId',
      );
    }
    await FirebaseFirestore.instance
        .collection('hotels')
        .doc(hotelId)
        .collection('scans')
        .doc(scan.id)
        .set({
          'id': scan.id,
          'scanId': scan.id,
          'timestamp': FieldValue.serverTimestamp(),
          'departmentId': scan.departmentId ?? 'kitchen',
          'imageUrl': imageUrl ?? '',
          'scanType': 'Smart scan',
          'zone': widget.args['zone'] ?? 'F&B',
          'entityId': hotelId,
          'staffName': user?.name ?? 'Staff',
          'dishName':
              _freshnessResult['itemName'] ??
              _wasteResult['itemName'] ??
              'Unknown dish',
          'contamination_confidence': _contaminationConfidence,
          'contamination_label': _contaminationLabel,
          'contamination_pct': _contaminationPct,
          'clean_pct': _cleanPct,
          'detection_count': _detectionCount,
          'freshness_status': _freshnessStatus,
          'freshness_confidence': _freshnessConfidence,
          'freshness_label': _freshnessLabel,
          'waste_kg': _wasteKg,
          'compostable_pct': _compostablePct,
          'non_compostable_pct': _nonCompostablePct,
          'background_pct': _backgroundPct,
          'compostable_kg': _compostableKg,
          'riskLevel': _venueRiskLevel,
          'calories': (_nutritionResult['calories'] as num?)?.toDouble() ?? 0.0,
          'protein_g': (_nutritionResult['protein'] as num?)?.toDouble() ?? 0.0,
          'carbs_g': (_nutritionResult['carbs'] as num?)?.toDouble() ?? 0.0,
          'fat_g': (_nutritionResult['fat'] as num?)?.toDouble() ?? 0.0,
        }, SetOptions(merge: true));
  }

  double get _contaminationConfidence =>
      (_contaminationResult['confidence'] as num?)?.toDouble() ?? 0.0;

  String get _contaminationLabel =>
      (_contaminationResult['label'] as String?) ?? 'clean';

  double get _contaminationPct {
    final value =
        _contaminationResult['contaminated_pct'] ??
        _contaminationResult['contaminatedPct'] ??
        _contaminationResult['riskPct'];
    return (value as num?)?.toDouble() ?? 0.0;
  }

  double get _cleanPct {
    final value =
        _contaminationResult['clean_pct'] ?? _contaminationResult['cleanPct'];
    return (value as num?)?.toDouble() ?? 0.0;
  }

  int get _detectionCount {
    final value = _contaminationResult['detection_count'];
    if (value is num) return value.toInt();
    final detections = _contaminationResult['detections'];
    return detections is List ? detections.length : 0;
  }

  String get _freshnessStatus =>
      (_freshnessResult['status'] as String?) ?? 'unknown';

  double get _freshnessConfidence =>
      (_freshnessResult['confidence'] as num?)?.toDouble() ?? 0.0;

  String get _freshnessLabel =>
      (_freshnessResult['label'] as String?) ?? 'Unknown';

  double get _wasteKg {
    final items = _wasteResult['detectedItems'];
    if (items is! List) return 0.0;
    return items.fold<double>(0.0, (sum, item) {
      if (item is Map) {
        return sum + ((item['quantityKg'] as num?)?.toDouble() ?? 0.0);
      }
      return sum;
    });
  }

  double get _compostablePct =>
      (_compostResult['compostablePct'] as num?)?.toDouble() ?? 0.0;

  double get _nonCompostablePct =>
      (_compostResult['nonCompostablePct'] as num?)?.toDouble() ?? 0.0;

  double get _backgroundPct =>
      (_compostResult['backgroundPct'] as num?)?.toDouble() ?? 0.0;

  double get _compostableKg => _wasteKg * _compostablePct / 100.0;

  String get _venueRiskLevel {
    final contaminated =
        (_contaminationResult['contaminatedPct'] as num?)?.toDouble() ?? 0;
    final status = ((_freshnessResult['status'] as String?) ?? '')
        .toLowerCase();
    if (contaminated >= 50 || status == 'spoiled') return 'danger';
    if (contaminated > 0 || status == 'expiring') return 'warning';
    return 'safe';
  }

  @override
  Widget build(BuildContext context) {
    if (!_isFusion) {
      return Scaffold(
        backgroundColor: _kSurface,
        appBar: AppBar(title: const Text('Result'), backgroundColor: _kCherry),
        body: const Center(child: Text('No fusion data')),
      );
    }

    return _buildFusion();
  }

  Widget _buildFusion() {
    final compostPct =
        (_compostResult['compostablePct'] as num?)?.toDouble() ?? 0.0;
    final status = ((_freshnessResult['status'] as String?) ?? 'fresh')
        .toLowerCase();
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
                  if (_imageBytes != null)
                    Image.memory(_imageBytes!, fit: BoxFit.cover)
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
                            'Analysis results',
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Freshness · Waste · Compost · Contamination',
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
                    title: 'Compost AI',
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
                      bgPct:
                          (_compostResult['backgroundPct'] as num?)
                              ?.toDouble() ??
                          0.0,
                      ms: ms,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _SectionCard(
                    title: 'Freshness',
                    subtitle: 'Deep transfer learning model',
                    color: _kRose,
                    delay: 100,
                    child: _FreshnessCard(status: status),
                  ),
                  const SizedBox(height: 12),
                  _SectionCard(
                    title: 'Waste detected',
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
                  const SizedBox(height: 12),
                  if (_nutritionResult.isNotEmpty)
                    _SectionCard(
                      title: 'Nutrition analysis',
                      subtitle: 'Gemini 1.5 Flash Vision',
                      color: const Color(0xFFC4748A),
                      delay: 350,
                      child: _NutritionCard(data: _nutritionResult),
                    ),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: () async {
                      if (!_compostIngested) {
                        await _ingestCompostScan();
                        if (mounted) setState(() {});
                      }
                    },
                    child: Container(
                      height: 56,
                      decoration: BoxDecoration(
                        color: _compostIngested ? Colors.grey : _kCherry,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: _kCherry.withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          _compostIngested ? 'Session sauvegardée' : 'Sauvegarder la session',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _kCherry.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'Nouveau scan',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _kSlate,
                          ),
                        ),
                      ),
                    ),
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

  String _normalizeConfidencePercent(double confidence) {
    return (confidence * 100).toStringAsFixed(1);
  }

  Widget _contaminationCard({
    required FoodAnalysisResult contamination,
    Uint8List? imageBytes,
  }) {
    final confPct = _normalizeConfidencePercent(contamination.confidence);

    return Column(
      children: [
        _SectionCard(
          title: 'Insects & contamination',
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
                  style: GoogleFonts.inter(fontSize: 11, color: _kSlate),
                ),
                const SizedBox(height: 8),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: contamination.detections.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 4),
                  itemBuilder: (_, i) {
                    final det = contamination.detections[i];
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(det.label, style: GoogleFonts.inter(fontSize: 11)),
                        Text(
                          '${_normalizeConfidencePercent(det.confidence).split('.')[0]}%',
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
                  border: Border.all(color: color.withValues(alpha: 0.2)),
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
                            style: GoogleFonts.playfairDisplay(
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
              Padding(padding: const EdgeInsets.all(12), child: child),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: Duration(milliseconds: delay))
        .slideY(begin: 0.2, duration: Duration(milliseconds: 600 + delay));
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
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _Dot(color: _kEmerald),
            const SizedBox(width: 4),
            Text(
              'Compostable',
              style: GoogleFonts.inter(fontSize: 11, color: _kSlate),
            ),
            const SizedBox(width: 14),
            _Dot(color: _kRose),
            const SizedBox(width: 4),
            Text(
              'Non-compostable',
              style: GoogleFonts.inter(fontSize: 11, color: _kSlate),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _ConfidenceBar(
          label: 'Compostable',
          percentage: compostPct,
          color: _kEmerald,
        ),
        const SizedBox(height: 6),
        _ConfidenceBar(
          label: 'Non-Compostable',
          percentage: nonCompostPct,
          color: _kRose,
        ),
        const SizedBox(height: 12),
        Text(
          'Inference: ${ms}ms',
          style: GoogleFonts.inter(fontSize: 10, color: _kSlate),
        ),
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
              color: isFresh ? Colors.green.shade300 : Colors.orange.shade300,
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
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final item = items[i];
              final name = item['name'] ?? 'Unknown';
              final kg =
                  (item['quantityKg'] as num?)?.toStringAsFixed(2) ?? '0';
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '~${kg}kg',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: _kSlate,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              );
            },
          )
        else
          Text(
            'No waste detected',
            style: GoogleFonts.inter(fontSize: 12, color: _kSlate),
          ),
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
            Text(label, style: GoogleFonts.inter(fontSize: 11, color: _kSlate)),
            Text(
              '${(percentage).toStringAsFixed(1)}%',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _kSlate,
              ),
            ),
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
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

class _NutritionCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _NutritionCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final cal = (data['calories'] as num?)?.toDouble() ?? 0;
    final pro = (data['protein'] as num?)?.toDouble() ?? 0;
    final car = (data['carb'] as num?)?.toDouble() ?? 0;
    final fat = (data['fat'] as num?)?.toDouble() ?? 0;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _NutrientCol('Calories', '${cal.toInt()} kcal', _kCherry),
            _NutrientCol('Protein', '${pro.toStringAsFixed(1)}g', _kEmerald),
            _NutrientCol('Carbs', '${car.toStringAsFixed(1)}g', _kAmber),
            _NutrientCol('Fat', '${fat.toStringAsFixed(1)}g', _kRose),
          ],
        ),
      ],
    );
  }
}

class _NutrientCol extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _NutrientCol(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 10, color: _kSlate),
        ),
      ],
    );
  }
}
