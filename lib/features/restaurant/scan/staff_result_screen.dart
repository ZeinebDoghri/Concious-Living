import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/constants.dart';
import '../../../core/firebase_service.dart';
import '../../../core/models/waste_item_model.dart';
import '../../../providers/inventory_provider.dart';
import '../../../providers/user_provider.dart';
import '../../../shared/widgets/freshness_badge.dart';

// ── Design tokens ─────────────────────────────────────────────────────────────
const _kEmerald  = Color(0xFF10B981);
const _kEmeraldD = Color(0xFF059669);
const _kEmeraldL = Color(0xFFD1FAE5);
const _kRose     = Color(0xFFEF4444);
const _kRoseL    = Color(0xFFFEE2E2);
const _kAmber    = Color(0xFFD97706);
const _kAmberL   = Color(0xFFFEF3C7);
const _kCherry   = Color(0xFF8B1A1F);
const _kSlate    = Color(0xFF64748B);
const _kSlateL   = Color(0xFFF1F5F9);
const _kInk      = Color(0xFF1E293B);
const _kSurface  = Color(0xFFF8FAFC);
const _kCard     = Colors.white;
const _kBorder   = Color(0xFFE2E8F0);

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

  void _snack(String msg, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          Icon(success ? Icons.check_circle_rounded : Icons.info_rounded,
              color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(msg)),
        ]),
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
        final name = (entry['name'] as String?)?.trim() ?? 'Déchet';
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
      final status =
          ((_freshnessResult['status'] as String?) ?? '').toLowerCase();
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
    final status =
        ((_freshnessResult['status'] as String?) ?? 'fresh').toLowerCase();
    final detectedCount =
        ((_wasteResult['detectedItems'] as List?)?.length ?? 0);
    final maskPng = _compostResult['maskPng'] as Uint8List?;
    final ms = (_compostResult['inferenceTimeMs'] as num?)?.toInt() ?? 920;

    return Scaffold(
      backgroundColor: _kSurface,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Hero image header ──────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            automaticallyImplyLeading: false,
            backgroundColor: _kInk,
            leading: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                context.pop();
              },
              child: Container(
                margin: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black38,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white, size: 16),
              ),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.fromLTRB(0, 10, 12, 10),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _kEmerald.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: _kEmerald.withValues(alpha: 0.5), width: 0.8),
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
                  if (_imageBytes != null)
                    Image.memory(_imageBytes!, fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => _imageFallback())
                  else if (!kIsWeb && _imageFile != null)
                    Image.file(_imageFile!, fit: BoxFit.cover)
                  else
                    _imageFallback(),
                  // Gradient overlay
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Color(0xDD1E293B)],
                        stops: [0.4, 1.0],
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
                          style: GoogleFonts.sora(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          '3 IA · fraîcheur · déchets · compost',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.65),
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
                  color: _kEmerald,
                  delay: 0,
                  child: _CompostCard(
                    maskPng: maskPng,
                    compostPct: compostPct,
                    nonCompostPct: (_compostResult['nonCompostablePct'] as num?)
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
                  title: '🌡️ Fraîcheur',
                  subtitle: _freshnessStatusLabel(status),
                  color: _freshnessColor(status),
                  delay: 100,
                  child: _FreshnessCard(result: _freshnessResult),
                ),

                const SizedBox(height: 12),

                // ── Waste card ─────────────────────────────────────────────
                _SectionCard(
                  title: '🗑️ Déchets détectés',
                  subtitle: '$detectedCount article(s) identifié(s)',
                  color: _kAmber,
                  delay: 200,
                  child: _WasteCard(result: _wasteResult),
                ),

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
                      color: _kCard,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _kBorder),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.camera_alt_outlined,
                            size: 18, color: _kSlate),
                        const SizedBox(width: 8),
                        Text(
                          'Nouveau scan',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _kSlate,
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
    if (s == 'fresh') return _kEmerald;
    if (s == 'expiring') return _kAmber;
    return _kRose;
  }

  Widget _imageFallback() => Container(
        color: const Color(0xFF0D1524),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.image_search_rounded,
                  size: 48, color: Colors.white24),
              const SizedBox(height: 8),
              Text('Image non disponible sur web',
                  style: GoogleFonts.inter(
                      fontSize: 12, color: Colors.white30)),
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
      backgroundColor: _kSurface,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
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
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white, size: 16),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Résultat du scan',
                    style: GoogleFonts.sora(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
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
                          child: Image.memory(_imageBytes!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => _imageFallback()),
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
                          color: _kCard,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: _kBorder),
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
  const _SummaryBanner(
      {required this.status,
      required this.compostPct,
      required this.detectedItems});

  @override
  Widget build(BuildContext context) {
    final Color color;
    final String text;

    if (status == 'spoiled') {
      color = _kRose;
      text  = '⚠️ Produit périmé détecté — retrait recommandé';
    } else if (compostPct > 55) {
      color = _kEmerald;
      text  = '✅ ${compostPct.toStringAsFixed(0)}% compostable — excellente gestion';
    } else if (detectedItems > 0) {
      color = _kAmber;
      text  = '📊 $detectedItems déchet(s) identifié(s) — action recommandée';
    } else {
      color = const Color(0xFF6366F1);
      text  = '🔍 Analyse 3-en-1 complète — voir le détail ci-dessous';
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
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
        color: _kCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kBorder, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.06),
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
              color: color.withValues(alpha: 0.07),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
              border: Border(
                bottom:
                    BorderSide(color: color.withValues(alpha: 0.15), width: 0.8),
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
                        style: GoogleFonts.sora(
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
          Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
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

        // Legend
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
          const SizedBox(width: 14),
          Container(
            width: 8, height: 8,
            decoration: BoxDecoration(
              color: _kSlate.withValues(alpha: 0.25),
              shape: BoxShape.circle,
              border: Border.all(color: _kSlate.withValues(alpha: 0.5)),
            ),
          ),
          const SizedBox(width: 4),
          Text('Fond',
              style: GoogleFonts.inter(fontSize: 11, color: _kSlate)),
        ]),

        const SizedBox(height: 12),

        // Stats
        Row(
          children: [
            _StatBox(
                value: compostPct, label: 'Compostable',
                color: _kEmerald, bg: _kEmeraldL),
            const SizedBox(width: 8),
            _StatBox(
                value: nonCompostPct, label: 'Non-compost.',
                color: _kRose, bg: _kRoseL),
            const SizedBox(width: 8),
            _StatBox(value: bgPct, label: 'Fond',
                color: _kSlate, bg: _kSlateL),
          ],
        ),

        if (ms > 0) ...[
          const SizedBox(height: 10),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: _kAmberL,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '🌐 SegFormer-B3 via API · $ms ms',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF92400E),
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
  const _MaskFallback(
      {required this.compostPct,
      required this.nonCompostPct,
      required this.bgPct});

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
                Expanded(flex: (c * 100).round(),
                    child: Container(color: _kEmerald.withValues(alpha: 0.6))),
                Expanded(flex: (n * 100).round(),
                    child: Container(color: _kRose.withValues(alpha: 0.6))),
                Expanded(flex: (b * 100).round(),
                    child: Container(color: _kSlate.withValues(alpha: 0.3))),
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
                      color: Colors.white,
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
  const _StatBox(
      {required this.value,
      required this.label,
      required this.color,
      required this.bg});

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
        vsync: this, duration: const Duration(milliseconds: 900));
    _val = Tween<double>(begin: 0, end: widget.value).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    Future.delayed(200.ms, () { if (mounted) _ctrl.forward(); });
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
              builder: (_, _) => Text(
                '${_val.value.toStringAsFixed(1)}%',
                style: GoogleFonts.sora(
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
            Transform.scale(
              scale: 1.3,
              child: FreshnessBadge(status),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${(confidence * 100).round()}% de confiance',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _kInk,
                  ),
                ),
                if (daysLeft != null)
                  Text(
                    '$daysLeft jour${daysLeft == 1 ? '' : 's'} restant(s)',
                    style: GoogleFonts.inter(fontSize: 12, color: _kSlate),
                  ),
              ],
            ),
          ],
        ),
        if (isSpoiled) ...[
          const SizedBox(height: 10),
          _InfoBanner(
            text: '⚠️ Retirer immédiatement du stock',
            color: _kRose,
            bg: _kRoseL,
          ),
        ] else if (isExpiring) ...[
          const SizedBox(height: 10),
          _InfoBanner(
            text: daysLeft == null
                ? '⏰ À utiliser très bientôt'
                : '⏰ Utiliser avant $daysLeft jour${daysLeft == 1 ? '' : 's'}',
            color: _kAmber,
            bg: _kAmberL,
          ),
        ] else ...[
          const SizedBox(height: 10),
          _InfoBanner(
            text: '✅ Produit en bon état',
            color: _kEmerald,
            bg: _kEmeraldL,
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
  const _InfoBanner(
      {required this.text, required this.color, required this.bg});

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
    return raw.whereType<Map>().map((e) => <String, dynamic>{
          'name': (e['name'] as String?)?.trim() ?? 'Déchet',
          'quantityKg': (e['quantityKg'] as num?)?.toDouble() ?? 0.0,
        }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;
    if (items.isEmpty) {
      return Row(
        children: [
          const Icon(Icons.check_circle_rounded, color: _kEmerald, size: 20),
          const SizedBox(width: 8),
          Text(
            'Aucun déchet excessif détecté',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _kEmerald,
            ),
          ),
        ],
      );
    }

    // Find top wasted item
    final top = items.reduce((a, b) =>
        (a['quantityKg'] as double) >= (b['quantityKg'] as double) ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top item highlight
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF7C2D12), Color(0xFF9A3412)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.trending_up_rounded,
                  color: Colors.white70, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Plus gaspillé',
                      style: GoogleFonts.inter(
                          fontSize: 10,
                          color: Colors.white60,
                          fontWeight: FontWeight.w500),
                    ),
                    Text(
                      top['name'] as String,
                      style: GoogleFonts.sora(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white),
                    ),
                  ],
                ),
              ),
              Text(
                '${(top['quantityKg'] as double).toStringAsFixed(1)} kg',
                style: GoogleFonts.sora(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white),
              ),
            ],
          ),
        ),
        if (items.length > 1) ...[
          const SizedBox(height: 10),
          ...items.skip(1).map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    const Icon(Icons.remove_circle_outline_rounded,
                        color: _kAmber, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(item['name'] as String,
                            style: GoogleFonts.inter(
                                fontSize: 13, color: _kInk))),
                    Text(
                      '${(item['quantityKg'] as double).toStringAsFixed(1)} kg',
                      style: GoogleFonts.inter(
                          fontSize: 12, color: _kSlate),
                    ),
                  ],
                ),
              )),
        ],
      ],
    );
  }
}

// ── Smart action button ────────────────────────────────────────────────────────
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
              ? const LinearGradient(
                  colors: [Color(0xFF059669), Color(0xFF10B981)])
              : const LinearGradient(
                  colors: [Color(0xFF1E293B), Color(0xFF334155)]),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: (isDone ? _kEmerald : _kInk).withValues(alpha: 0.3),
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
                      strokeWidth: 2, color: Colors.white),
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
