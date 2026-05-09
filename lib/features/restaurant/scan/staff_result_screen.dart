import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/firebase_service.dart';
import '../../../core/models/waste_item_model.dart';
import '../../../providers/inventory_provider.dart';
import '../../../providers/user_provider.dart';
import '../../../shared/widgets/freshness_badge.dart';
import 'annotated_contamination_image.dart';
import 'food_contamination_service.dart';

// ── FreshGuard restaurant theme tokens ────────────────────────────────────────
const _rPrimary = Color(0xFFF2A7A7);
const _rDeep = Color(0xFFE47878);
const _rSurface = Color(0xFFFFF5F5);
const _rSoftBg = Color(0xFFFFE4E4);
const _rTextTitle = Color(0xFF3D1515);
const _rTextBody = Color(0xFF7A4040);
const _rTextMuted = Color(0xFFB08080);
const _fresh = Color(0xFF52C98A);
const _freshBg = Color(0xFFE8F9F1);
const _warning = Color(0xFFFFAB5B);
const _warningBg = Color(0xFFFFF4E8);
const _danger = Color(0xFFFF7070);
const _dangerBg = Color(0xFFFFEEEE);

class StaffResultScreen extends StatefulWidget {
  final Map<String, dynamic> args;
  const StaffResultScreen({super.key, required this.args});

  @override
  State<StaffResultScreen> createState() => _StaffResultScreenState();
}

class _StaffResultScreenState extends State<StaffResultScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _enterCtrl;
  bool _actionDone = false;
  bool _actionLoading = false;

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

  // ── Helpers ──────────────────────────────────────────────────────────────────
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

  void _snack(String msg, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              success ? Icons.check_circle_rounded : Icons.info_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(msg)),
          ],
        ),
      ),
    );
  }

  Future<void> _doSmartAction() async {
    if (_actionLoading || _actionDone) return;
    HapticFeedback.mediumImpact();
    setState(() => _actionLoading = true);

    try {
      final user = context.read<UserProvider>().currentUser;
      final venueId = user?.id ?? '';

      // 1. Log waste items if detected
      final rawItems = _wasteResult['detectedItems'];
      final items = rawItems is List
          ? rawItems.whereType<Map>().toList()
          : <Map>[];

      for (final entry in items) {
        final name = (entry['name'] as String?)?.trim() ?? 'Waste';
        final kg = (entry['quantityKg'] as num?)?.toDouble() ?? 0.0;
        if (venueId.isNotEmpty) {
          await FirebaseService.logWaste(
            venueId,
            WasteItemModel(
              id: '${DateTime.now().millisecondsSinceEpoch}-$name',
              name: name,
              quantityKg: kg,
              category: name,
              isCompostable: false,
              trend: 'up',
            ),
          );
        }
      }

      // 2. Remove spoiled item from inventory if needed
      final status = ((_freshnessResult['status'] as String?) ?? '')
          .toLowerCase();
      if (status == 'spoiled') {
        final inv = context.read<InventoryProvider>();
        final candidate = inv.items
            .where((e) => e.status == 'spoiled')
            .followedBy(inv.items.where((e) => e.status == 'expiring'))
            .toList();
        if (candidate.isNotEmpty) {
          await inv.removeItem(candidate.first.id);
        }
      }

      if (!mounted) return;
      setState(() {
        _actionDone = true;
        _actionLoading = false;
      });
      _snack('Actions enregistrées avec succès ✓', success: true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _actionLoading = false);
      _snack('Erreur : ${e.toString().split(':').last.trim()}');
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_isFusion) return _buildFusion();
    return _buildLegacy();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FUSION VIEW
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildFusion() {
    final compostPct =
        (_compostResult['compostablePct'] as num?)?.toDouble() ?? 0.0;
    final status = ((_freshnessResult['status'] as String?) ?? 'fresh')
        .toLowerCase();
    final detectedCount =
        ((_wasteResult['detectedItems'] as List?)?.length ?? 0);
    final maskPng = _compostResult['maskPng'] as Uint8List?;
    final ms = (_compostResult['inferenceTimeMs'] as num?)?.toInt() ?? 920;
    final contamination = _contaminationResult.isNotEmpty
        ? FoodAnalysisResult.fromJson(_contaminationResult)
        : null;

    return Scaffold(
      backgroundColor: _rSurface,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Hero image header ──────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            automaticallyImplyLeading: false,
            backgroundColor: _rTextTitle,
            leading: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                context.pop();
              },
              child: Container(
                margin: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _rSoftBg.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.fromLTRB(0, 10, 12, 10),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _rPrimary.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _rPrimary.withValues(alpha: 0.5),
                    width: 0.8,
                  ),
                ),
                child: Text(
                  '⚡ Smart Scan',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Scanned image
                  if (_imageBytes != null && contamination != null)
                    AnnotatedContaminationImage(
                      imageBytes: _imageBytes!,
                      detections: contamination.detections,
                    )
                  else if (_imageBytes != null)
                    Image.memory(
                      _imageBytes!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _imageFallback(),
                    )
                  else if (!kIsWeb && _imageFile != null)
                    Image.file(_imageFile!, fit: BoxFit.cover)
                  else
                    _imageFallback(),
                  // Gradient overlay
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          _rTextTitle.withValues(alpha: 0.85),
                        ],
                        stops: const [0.4, 1.0],
                      ),
                    ),
                  ),
                  // Bottom label
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 80,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Analyse complète',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          '3 IA · fraîcheur · déchets · compost',
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
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── AI Summary banner ──────────────────────────────────────
                _SummaryBanner(
                  status: status,
                  compostPct: compostPct,
                  detectedItems: detectedCount,
                ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),

                const SizedBox(height: 14),

                // ── Compost IA card (star feature — first!) ────────────────
                _SectionCard(
                  title: '♻️ Compost IA',
                  subtitle: 'mask2former_fp32 · Swin-B · mIoU 0.86',
                  color: _fresh,
                  delay: 0,
                  child: _CompostCard(
                    maskPng: maskPng,
                    compostPct: compostPct,
                    nonCompostPct:
                        (_compostResult['nonCompostablePct'] as num?)
                            ?.toDouble() ??
                        0.0,
                    bgPct:
                        (_compostResult['backgroundPct'] as num?)?.toDouble() ??
                        0.0,
                    ms: ms,
                  ),
                ),

                const SizedBox(height: 12),

                // ── Freshness card ─────────────────────────────────────────
                _SectionCard(
                  title: 'Freshness',
                  subtitle: _freshnessStatusLabel(status),
                  color: _freshnessColor(status),
                  delay: 100,
                  child: _FreshnessCard(result: _freshnessResult),
                ),

                const SizedBox(height: 12),

                // ── Waste card ─────────────────────────────────────────────
                _SectionCard(
                  title: 'Detected Waste',
                  subtitle: '$detectedCount article(s) identifié(s)',
                  color: _warning,
                  delay: 200,
                  child: _WasteCard(result: _wasteResult),
                ),

                if (contamination != null) ...[
                  const SizedBox(height: 12),
                  _SectionCard(
                    title: 'Contamination',
                    subtitle: 'YOLO food safety detection',
                    color: contamination.isClean ? _fresh : _danger,
                    delay: 300,
                    child: _ContaminationCard(
                      result: contamination,
                      imageBytes: _imageBytes,
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                // ── Single smart action button ─────────────────────────────
                _SmartActionButton(
                  isDone: _actionDone,
                  isLoading: _actionLoading,
                  status: status,
                  detectedCount: detectedCount,
                  onTap: _doSmartAction,
                ).animate().fadeIn(delay: 350.ms, duration: 400.ms),

                const SizedBox(height: 10),

                // ── Scan again ─────────────────────────────────────────────
                GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    context.pop();
                  },
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _rPrimary.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.camera_alt_outlined,
                          size: 18,
                          color: _rTextMuted,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Nouveau scan',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _rTextMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ).animate().fadeIn(delay: 420.ms, duration: 350.ms),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  String _freshnessStatusLabel(String s) {
    if (s == 'fresh') return 'Produit frais ✓';
    if (s == 'expiring') return 'Expire bientôt';
    if (s == 'spoiled') return 'Périmé — retrait requis';
    return 'Analyse fraîcheur';
  }

  Color _freshnessColor(String s) {
    if (s == 'fresh') return _fresh;
    if (s == 'expiring') return _warning;
    return _danger;
  }

  Widget _imageFallback() => Container(
    color: _rSoftBg,
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.image_search_rounded,
            size: 48,
            color: _rPrimary.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 8),
          Text(
            'Image non disponible sur web',
            style: GoogleFonts.inter(fontSize: 12, color: _rTextMuted),
          ),
        ],
      ),
    ),
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // LEGACY VIEW (backward compat)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildLegacy() {
    final mode = ((widget.args['scanMode'] as String?) ?? 'freshness').trim();
    final result = (widget.args['result'] as Map<String, dynamic>?) ?? {};

    return Scaffold(
      backgroundColor: _rSurface,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [_rSoftBg, _rSurface]),
                border: Border(
                  bottom: BorderSide(color: _rPrimary.withValues(alpha: 0.2)),
                ),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: _rSoftBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _rPrimary.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: _rDeep,
                        size: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Résultat du scan',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: _rTextTitle,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_imageBytes != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: SizedBox(
                          height: 200,
                          width: double.infinity,
                          child: Image.memory(
                            _imageBytes!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _imageFallback(),
                          ),
                        ),
                      )
                    else if (!kIsWeb && _imageFile != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: SizedBox(
                          height: 200,
                          width: double.infinity,
                          child: Image.file(_imageFile!, fit: BoxFit.cover),
                        ),
                      ),
                    const SizedBox(height: 16),
                    if (mode == 'freshness')
                      _FreshnessCard(result: result)
                    else if (mode == 'waste')
                      _WasteCard(result: result)
                    else
                      _FreshnessCard(result: result),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _rPrimary.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            'Nouveau scan',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _rTextMuted,
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

// ── Summary banner ─────────────────────────────────────────────────────────────
class _SummaryBanner extends StatelessWidget {
  final String status;
  final double compostPct;
  final int detectedItems;
  const _SummaryBanner({
    required this.status,
    required this.compostPct,
    required this.detectedItems,
  });

  @override
  Widget build(BuildContext context) {
    final Color color;
    final String text;

    if (status == 'spoiled') {
      color = _danger;
      text = '⚠️ Produit périmé détecté — retrait recommandé';
    } else if (compostPct > 55) {
      color = _fresh;
      text =
          '✅ ${compostPct.toStringAsFixed(0)}% compostable — excellente gestion';
    } else if (detectedItems > 0) {
      color = _warning;
      text = '📊 $detectedItems déchet(s) identifié(s) — action recommandée';
    } else {
      color = _rPrimary;
      text = '🔍 Analyse 3-en-1 complète — voir le détail ci-dessous';
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section card wrapper ────────────────────────────────────────────────────────
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
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _rPrimary.withValues(alpha: 0.2),
              width: 0.8,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.08),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                  border: Border.all(
                    color: color.withValues(alpha: 0.15),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 20,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: color,
                            ),
                          ),
                          Text(
                            subtitle,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: color.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(padding: const EdgeInsets.all(16), child: child),
            ],
          ),
        )
        .animate()
        .fadeIn(
          delay: Duration(milliseconds: 150 + delay),
          duration: 450.ms,
        )
        .slideY(
          begin: 0.08,
          end: 0,
          delay: Duration(milliseconds: 150 + delay),
          duration: 450.ms,
          curve: Curves.easeOutCubic,
        );
  }
}

// ── Compost card ───────────────────────────────────────────────────────────────
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
        // Overlay image: original photo blended with coloured segmentation
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            height: 210,
            width: double.infinity,
            child: maskPng != null
                ? Image.memory(
                    maskPng!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _MaskFallback(
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

        // Legend
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _Dot(color: _fresh),
            const SizedBox(width: 4),
            Text(
              'Compostable',
              style: GoogleFonts.inter(fontSize: 11, color: _rTextMuted),
            ),
            const SizedBox(width: 14),
            _Dot(color: _danger),
            const SizedBox(width: 4),
            Text(
              'Non-compost.',
              style: GoogleFonts.inter(fontSize: 11, color: _rTextMuted),
            ),
            const SizedBox(width: 14),
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: _rTextMuted.withValues(alpha: 0.25),
                shape: BoxShape.circle,
                border: Border.all(color: _rTextMuted.withValues(alpha: 0.5)),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              'Fond',
              style: GoogleFonts.inter(fontSize: 11, color: _rTextMuted),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Stats
        Row(
          children: [
            _StatBox(
              value: compostPct,
              label: 'Compostable',
              color: _fresh,
              bg: _freshBg,
            ),
            const SizedBox(width: 8),
            _StatBox(
              value: nonCompostPct,
              label: 'Non-compost.',
              color: _danger,
              bg: _dangerBg,
            ),
            const SizedBox(width: 8),
            _StatBox(
              value: bgPct,
              label: 'Fond',
              color: _rTextMuted,
              bg: _rSoftBg,
            ),
          ],
        ),

        if (ms > 0) ...[
          const SizedBox(height: 10),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: _warningBg,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '🌐 SegFormer-B3 via API · $ms ms',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: _warning,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ── Mask fallback: color bar when PNG fails ────────────────────────────────────
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
    final total = compostPct + nonCompostPct + bgPct;
    final c = total > 0 ? compostPct / total : 0.5;
    final n = total > 0 ? nonCompostPct / total : 0.3;
    final b = total > 0 ? bgPct / total : 0.2;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 150,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Row(
              children: [
                Expanded(
                  flex: (c * 100).round(),
                  child: Container(color: _fresh.withValues(alpha: 0.6)),
                ),
                Expanded(
                  flex: (n * 100).round(),
                  child: Container(color: _danger.withValues(alpha: 0.6)),
                ),
                Expanded(
                  flex: (b * 100).round(),
                  child: Container(color: _rSoftBg),
                ),
              ],
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('♻️', style: TextStyle(fontSize: 32)),
                  const SizedBox(height: 4),
                  Text(
                    'Masque de segmentation',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _rTextTitle,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  final Color color;
  const _Dot({required this.color});
  @override
  Widget build(BuildContext context) => Container(
    width: 8,
    height: 8,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}

// ── Animated stat box ──────────────────────────────────────────────────────────
class _StatBox extends StatefulWidget {
  final double value;
  final String label;
  final Color color;
  final Color bg;
  const _StatBox({
    required this.value,
    required this.label,
    required this.color,
    required this.bg,
  });

  @override
  State<_StatBox> createState() => _StatBoxState();
}

class _StatBoxState extends State<_StatBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _val;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _val = Tween<double>(
      begin: 0,
      end: widget.value,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    Future.delayed(200.ms, () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: widget.bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: widget.color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            AnimatedBuilder(
              animation: _val,
              builder: (_, __) => Text(
                '${_val.value.toStringAsFixed(1)}%',
                style: GoogleFonts.inter(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: widget.color,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              widget.label,
              style: GoogleFonts.inter(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: widget.color.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Freshness card ─────────────────────────────────────────────────────────────
class _FreshnessCard extends StatelessWidget {
  final Map<String, dynamic> result;
  const _FreshnessCard({required this.result});

  @override
  Widget build(BuildContext context) {
    final status = ((result['status'] as String?) ?? 'expiring').toLowerCase();
    final confidence = (result['confidence'] as num?)?.toDouble() ?? 0.0;
    final daysLeft = (result['daysLeft'] as num?)?.toInt();
    final isSpoiled = status == 'spoiled';
    final isExpiring = status == 'expiring';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Transform.scale(scale: 1.3, child: FreshnessBadge(status)),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${(confidence * 100).round()}% de confiance',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _rTextTitle,
                  ),
                ),
                if (daysLeft != null)
                  Text(
                    '$daysLeft jour${daysLeft == 1 ? '' : 's'} restant(s)',
                    style: GoogleFonts.inter(fontSize: 12, color: _rTextMuted),
                  ),
              ],
            ),
          ],
        ),
        if (isSpoiled) ...[
          const SizedBox(height: 10),
          _InfoBanner(
            text: '⚠️ Retirer immédiatement du stock',
            color: _danger,
            bg: _dangerBg,
          ),
        ] else if (isExpiring) ...[
          const SizedBox(height: 10),
          _InfoBanner(
            text: daysLeft == null
                ? '⏰ À utiliser très bientôt'
                : '⏰ Utiliser avant $daysLeft jour${daysLeft == 1 ? '' : 's'}',
            color: _warning,
            bg: _warningBg,
          ),
        ] else ...[
          const SizedBox(height: 10),
          _InfoBanner(
            text: '✅ Produit en bon état',
            color: _fresh,
            bg: _freshBg,
          ),
        ],
      ],
    );
  }
}

class _InfoBanner extends StatelessWidget {
  final String text;
  final Color color;
  final Color bg;
  const _InfoBanner({
    required this.text,
    required this.color,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

// ── Waste card ─────────────────────────────────────────────────────────────────
class _WasteCard extends StatelessWidget {
  final Map<String, dynamic> result;
  const _WasteCard({required this.result});

  List<Map<String, dynamic>> get _items {
    final raw = result['detectedItems'];
    if (raw is! List) return [];
    return raw
        .whereType<Map>()
        .map(
          (e) => <String, dynamic>{
            'name': (e['name'] as String?)?.trim() ?? 'Waste',
            'quantityKg': (e['quantityKg'] as num?)?.toDouble() ?? 0.0,
          },
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;
    if (items.isEmpty) {
      return Row(
        children: [
          const Icon(Icons.check_circle_rounded, color: _fresh, size: 20),
          const SizedBox(width: 8),
          Text(
            'Aucun déchet excessif détecté',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _fresh,
            ),
          ),
        ],
      );
    }

    // Find top wasted item
    final top = items.reduce(
      (a, b) =>
          (a['quantityKg'] as double) >= (b['quantityKg'] as double) ? a : b,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top item highlight
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_rDeep, _rPrimary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.trending_up_rounded,
                color: Colors.white70,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Plus gaspillé',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      top['name'] as String,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${(top['quantityKg'] as double).toStringAsFixed(1)} kg',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        if (items.length > 1) ...[
          const SizedBox(height: 10),
          ...items
              .skip(1)
              .map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.remove_circle_outline_rounded,
                        color: _warning,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item['name'] as String,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: _rTextBody,
                          ),
                        ),
                      ),
                      Text(
                        '${(item['quantityKg'] as double).toStringAsFixed(1)} kg',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: _rTextMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
        ],
      ],
    );
  }
}

// ── Smart action button ────────────────────────────────────────────────────────
class _ContaminationCard extends StatelessWidget {
  final FoodAnalysisResult result;
  final Uint8List? imageBytes;

  const _ContaminationCard({required this.result, required this.imageBytes});

  @override
  Widget build(BuildContext context) {
    final color = result.isClean ? _fresh : _danger;
    final bg = result.isClean ? _freshBg : _dangerBg;
    final confidence = result.confidence > 1
        ? result.confidence
        : result.confidence * 100;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (imageBytes != null) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              height: 190,
              width: double.infinity,
              child: AnnotatedContaminationImage(
                imageBytes: imageBytes!,
                detections: result.detections,
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.28)),
          ),
          child: Row(
            children: [
              Icon(
                result.isClean
                    ? Icons.verified_rounded
                    : Icons.warning_amber_rounded,
                color: color,
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  result.isClean
                      ? 'Surface propre detectee'
                      : 'Risque de contamination detecte',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
              Text(
                '${confidence.toStringAsFixed(1)}%',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _MiniPercentBar(label: 'Clean', value: result.cleanPct, color: _fresh),
        const SizedBox(height: 8),
        _MiniPercentBar(
          label: 'Contaminated',
          value: result.contaminatedPct,
          color: _danger,
        ),
        if (result.detections.isNotEmpty) ...[
          const SizedBox(height: 12),
          ...result.detections.map(
            (detection) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  const Icon(
                    Icons.bug_report_outlined,
                    color: _danger,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      detection.label,
                      style: GoogleFonts.inter(fontSize: 12, color: _rTextBody),
                    ),
                  ),
                  Text(
                    '${(detection.confidence * 100).toStringAsFixed(0)}%',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _danger,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _MiniPercentBar extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _MiniPercentBar({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final normalized = (value > 1 ? value / 100 : value)
        .clamp(0.0, 1.0)
        .toDouble();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _rTextMuted,
              ),
            ),
            Text(
              '${value.toStringAsFixed(1)}%',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            minHeight: 8,
            value: normalized,
            backgroundColor: color.withValues(alpha: 0.12),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

class _SmartActionButton extends StatelessWidget {
  final bool isDone;
  final bool isLoading;
  final String status;
  final int detectedCount;
  final VoidCallback onTap;
  const _SmartActionButton({
    required this.isDone,
    required this.isLoading,
    required this.status,
    required this.detectedCount,
    required this.onTap,
  });

  String get _label {
    if (isDone) return 'Actions enregistrées ✓';
    final parts = <String>[];
    if (detectedCount > 0) parts.add('Enregistrer les déchets');
    if (status == 'spoiled') parts.add('Retirer du stock');
    if (parts.isEmpty) return 'Mettre à jour l\'inventaire';
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isDone ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 56,
        decoration: BoxDecoration(
          gradient: isDone
              ? const LinearGradient(colors: [_fresh, Color(0xFF3DB876)])
              : const LinearGradient(colors: [_rDeep, _rPrimary]),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: (isDone ? _fresh : _rPrimary).withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isDone
                          ? Icons.check_circle_rounded
                          : Icons.auto_fix_high_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        _label,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
