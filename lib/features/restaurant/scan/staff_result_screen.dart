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
import '../../../shared/widgets/animated_button.dart';
import '../../../shared/widgets/freshness_badge.dart';
import '../../../shared/widgets/olive_header.dart';

class StaffResultScreen extends StatefulWidget {
  final Map<String, dynamic> args;

  const StaffResultScreen({super.key, required this.args});

  @override
  State<StaffResultScreen> createState() => _StaffResultScreenState();
}

class _StaffResultScreenState extends State<StaffResultScreen> {
  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _scanMode() {
    final raw = widget.args['scanMode'];
    if (raw is String && raw.trim().isNotEmpty) return raw.trim();
    return 'freshness';
  }

  Map<String, dynamic> _result() {
    final raw = widget.args['result'];
    if (raw is Map<String, dynamic>) return raw;
    return <String, dynamic>{};
  }

  File? _imageFile() {
    if (kIsWeb) return null;
    final raw = widget.args['imageFile'];
    if (raw is File) return raw;
    final path = widget.args['imagePath'];
    if (path is String && path.trim().isNotEmpty) return File(path);
    return null;
  }

  Uint8List? _imageBytes() {
    final raw = widget.args['imageBytes'];
    if (raw is Uint8List) return raw;
    return null;
  }

  bool get _isFusion =>
      widget.args['isFusion'] == true &&
      widget.args.containsKey('freshnessResult');

  @override
  Widget build(BuildContext context) {
    if (_isFusion) return _buildFusionView(context);
    return _buildLegacyView(context);
  }

  // ── Fusion view — unified results ──────────────────────────────────────────
  Widget _buildFusionView(BuildContext context) {
    final freshnessResult =
        (widget.args['freshnessResult'] as Map<String, dynamic>?) ?? {};
    final wasteResult =
        (widget.args['wasteResult'] as Map<String, dynamic>?) ?? {};
    final compostResult =
        (widget.args['compostResult'] as Map<String, dynamic>?) ?? {};
    final imageBytes = _imageBytes();
    final imageFile  = _imageFile();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          _FusionSliverHeader(
            imageBytes: imageBytes,
            imageFile: imageFile,
            onBack: () => context.pop(),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 16),
                // ── AI summary banner ──────────────────────────────────────
                _AISummaryBanner(
                  freshness: freshnessResult,
                  waste: wasteResult,
                  compost: compostResult,
                ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
                const SizedBox(height: 16),
                // ── Freshness card ─────────────────────────────────────────
                _FusionCard(
                  title: '🌡️ Analyse Fraîcheur',
                  color: const Color(0xFF8B1A1F),
                  child: _FreshnessResult(
                    result: freshnessResult,
                    onUpdateInventory: () async =>
                        context.go(AppRoutes.restaurantInventory),
                    onLogRemoval: () async =>
                        _logRemovalFromInventory(freshnessResult),
                  ),
                ).animate().fadeIn(duration: 400.ms, delay: 80.ms)
                  .slideY(begin: 0.1, end: 0),
                const SizedBox(height: 12),
                // ── Waste card ─────────────────────────────────────────────
                _FusionCard(
                  title: '🗑️ Gaspillage détecté',
                  color: const Color(0xFFD97706),
                  child: _WasteResult(
                    result: wasteResult,
                    onLogWaste: () async => _logWasteItems(wasteResult),
                    onViewWasteReport: () =>
                        context.go(AppRoutes.restaurantWaste),
                  ),
                ).animate().fadeIn(duration: 400.ms, delay: 160.ms)
                  .slideY(begin: 0.1, end: 0),
                const SizedBox(height: 12),
                // ── Compost card ───────────────────────────────────────────
                _FusionCard(
                  title: '🌱 Segmentation Compost IA',
                  color: const Color(0xFF059669),
                  child: _CompostFusionResult(data: compostResult),
                ).animate().fadeIn(duration: 400.ms, delay: 240.ms)
                  .slideY(begin: 0.1, end: 0),
                const SizedBox(height: 20),
                // ── Scan again button ──────────────────────────────────────
                GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    context.pop();
                  },
                  child: Container(
                    height: 54,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF059669), Color(0xFF10B981)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF10B981).withValues(alpha: 0.3),
                          blurRadius: 16, offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.camera_alt_rounded,
                              color: Colors.white, size: 20),
                          const SizedBox(width: 10),
                          Text(
                            'Nouveau scan',
                            style: GoogleFonts.sora(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ).animate().fadeIn(duration: 350.ms, delay: 320.ms),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // ── Legacy single-mode view (backward compat) ─────────────────────────────
  Widget _buildLegacyView(BuildContext context) {
    final mode      = _scanMode();
    final result    = _result();
    final imageFile = _imageFile();
    final imgBytes  = _imageBytes();

    return Scaffold(
      backgroundColor: AppColors.oat,
      body: SafeArea(
        child: Column(
          children: [
            const OliveHeader(
                title: 'Scan result', subtitle: null,
                showBack: true, height: 170),
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
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (imgBytes != null) ...[
                        ClipRRect(
                          borderRadius:
                              BorderRadius.circular(AppRadii.screenCard),
                          child: SizedBox(
                            height: 200, width: double.infinity,
                            child: Image.memory(imgBytes, fit: BoxFit.cover),
                          ),
                        ),
                        const SizedBox(height: 14),
                      ] else if (!kIsWeb && imageFile != null) ...[
                        ClipRRect(
                          borderRadius:
                              BorderRadius.circular(AppRadii.screenCard),
                          child: SizedBox(
                            height: 200, width: double.infinity,
                            child: Image.file(imageFile, fit: BoxFit.cover),
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],
                      if (mode == 'freshness')
                        _FreshnessResult(
                          result: result,
                          onUpdateInventory: () async =>
                              context.go(AppRoutes.restaurantInventory),
                          onLogRemoval: () async =>
                              _logRemovalFromInventory(result),
                        )
                      else if (mode == 'waste')
                        _WasteResult(
                          result: result,
                          onLogWaste: () async => _logWasteItems(result),
                          onViewWasteReport: () =>
                              context.go(AppRoutes.restaurantWaste),
                        )
                      else if (mode == 'compost')
                        _CompostResult(
                          result: result,
                          onLogWaste: () async => _logWaste(result),
                        )
                      else
                        _FreshnessResult(
                          result: result,
                          onUpdateInventory: () async =>
                              context.go(AppRoutes.restaurantInventory),
                          onLogRemoval: () async =>
                              _logRemovalFromInventory(result),
                        ),
                      const SizedBox(height: 14),
                      Align(
                        alignment: Alignment.center,
                        child: TextButton(
                          onPressed: () => context.pop(),
                          child: Text(
                            'Scan another item',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.olive,
                            ),
                          ),
                        ),
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

  Future<void> _logWaste(Map<String, dynamic> result) async {
    final user = context.read<UserProvider>().currentUser;
    final venueId = user?.id ?? '';
    if (venueId.isEmpty) {
      _snack('Missing venue id.');
      return;
    }

    final isCompostable = (result['isCompostable'] as bool?) ?? false;
    final category = (result['category'] as String?)?.trim();

    final item = WasteItemModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: category?.isNotEmpty == true
          ? category!
          : (isCompostable ? 'Compostable item' : 'Non-compostable item'),
      quantityKg: 0.0,
      category: category ?? '',
      isCompostable: isCompostable,
      trend: 'up',
    );

    try {
      await FirebaseService.logWaste(venueId, item);
      if (!mounted) return;
      _snack(AppStrings.ok);
    } catch (e) {
      if (!mounted) return;
      _snack(e.toString());
    }
  }

  Future<void> _logRemovalFromInventory(Map<String, dynamic> result) async {
    final status = ((result['status'] as String?) ?? '').toLowerCase();
    if (status != 'spoiled') {
      _snack('Removal is only available for spoiled items.');
      return;
    }

    final inventory = context.read<InventoryProvider>();

    // Best-effort: remove the most urgent item (spoiled first, else expiring).
    final items = inventory.items;
    final candidate = items
        .where((e) => e.status == 'spoiled')
        .followedBy(items.where((e) => e.status == 'expiring'))
        .cast()
        .toList();

    if (candidate.isEmpty) {
      _snack('No inventory items available to remove.');
      return;
    }

    final id = candidate.first.id;

    try {
      await inventory.removeItem(id);
      if (!mounted) return;
      _snack('Removed from inventory');
    } catch (e) {
      if (!mounted) return;
      _snack(e.toString());
    }
  }

  Future<void> _logWasteItems(Map<String, dynamic> result) async {
    final user = context.read<UserProvider>().currentUser;
    final venueId = user?.id ?? '';
    if (venueId.isEmpty) {
      _snack('Missing venue id.');
      return;
    }

    final rawItems = result['detectedItems'];
    final items = rawItems is List
        ? rawItems.whereType<Map>().toList()
        : const <Map>[];

    if (items.isEmpty) {
      _snack('No waste items detected.');
      return;
    }

    try {
      for (final entry in items) {
        final name = (entry['name'] as String?)?.trim() ?? 'Waste item';
        final quantityKg = (entry['quantityKg'] as num?)?.toDouble() ?? 0.0;

        await FirebaseService.logWaste(
          venueId,
          WasteItemModel(
            id: '${DateTime.now().millisecondsSinceEpoch}-$name',
            name: name,
            quantityKg: quantityKg,
            category: name,
            isCompostable: false,
            trend: 'up',
          ),
        );
      }

      if (!mounted) return;
      _snack('Waste logged');
    } catch (e) {
      if (!mounted) return;
      _snack(e.toString());
    }
  }
}

// ── Fusion-specific widgets ───────────────────────────────────────────────────

class _FusionSliverHeader extends StatelessWidget {
  final Uint8List? imageBytes;
  final File? imageFile;
  final VoidCallback onBack;
  const _FusionSliverHeader(
      {required this.imageBytes,
      required this.imageFile,
      required this.onBack});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 240,
      pinned: true,
      automaticallyImplyLeading: false,
      backgroundColor: const Color(0xFF0A0F1E),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (imageBytes != null)
              Image.memory(imageBytes!, fit: BoxFit.cover)
            else if (!kIsWeb && imageFile != null)
              Image.file(imageFile!, fit: BoxFit.cover)
            else
              Container(
                color: const Color(0xFF0D1524),
                child: const Icon(Icons.image_outlined,
                    size: 60, color: Colors.white24),
              ),
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0xCC0A0F1E)],
                ),
              ),
            ),
            Positioned(
              bottom: 16, left: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Smart Scan — Résultats',
                    style: GoogleFonts.sora(
                      fontSize: 18, fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    '3 analyses IA fusionnées',
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
      leading: GestureDetector(
        onTap: onBack,
        child: Container(
          margin: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.arrow_back_ios_new,
              color: Colors.white, size: 16),
        ),
      ),
    );
  }
}

class _AISummaryBanner extends StatelessWidget {
  final Map<String, dynamic> freshness;
  final Map<String, dynamic> waste;
  final Map<String, dynamic> compost;
  const _AISummaryBanner(
      {required this.freshness, required this.waste, required this.compost});

  @override
  Widget build(BuildContext context) {
    final status       = (freshness['status'] as String? ?? 'fresh').toLowerCase();
    final compostPct   = (compost['compostablePct'] as num?)?.toDouble() ?? 0.0;
    final detectedItems = (waste['detectedItems'] as List?)?.length ?? 0;

    String headline;
    Color  headlineColor;
    if (status == 'spoiled') {
      headline      = '⚠️ Article périmé détecté — retrait immédiat recommandé';
      headlineColor = const Color(0xFFDC2626);
    } else if (compostPct > 60) {
      headline      = '✅ Majoritairement compostable — bonne gestion des déchets';
      headlineColor = const Color(0xFF059669);
    } else if (detectedItems > 0) {
      headline      = '📊 $detectedItems article(s) gaspillé(s) identifié(s)';
      headlineColor = const Color(0xFFD97706);
    } else {
      headline      = '🔍 Analyse complète — voir le détail ci-dessous';
      headlineColor = const Color(0xFF6366F1);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: headlineColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: headlineColor.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 4, height: 48,
            decoration: BoxDecoration(
              color: headlineColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              headline,
              style: GoogleFonts.inter(
                fontSize: 13, fontWeight: FontWeight.w600,
                color: headlineColor, height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FusionCard extends StatelessWidget {
  final String title;
  final Color  color;
  final Widget child;
  const _FusionCard(
      {required this.title, required this.color, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8EDF2), width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12, offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header stripe
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
              border: Border(
                bottom: BorderSide(
                    color: color.withValues(alpha: 0.15), width: 0.8),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 4, height: 18,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: GoogleFonts.sora(
                    fontSize: 14, fontWeight: FontWeight.w700,
                    color: color,
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
    );
  }
}

class _CompostFusionResult extends StatelessWidget {
  final Map<String, dynamic> data;
  const _CompostFusionResult({required this.data});

  @override
  Widget build(BuildContext context) {
    final compostPct    = (data['compostablePct']    as num?)?.toDouble() ?? 0.0;
    final nonCompostPct = (data['nonCompostablePct'] as num?)?.toDouble() ?? 0.0;
    final bgPct         = (data['backgroundPct']     as num?)?.toDouble() ?? 0.0;
    final ms            = (data['inferenceTimeMs']   as num?)?.toInt() ?? 0;
    final maskPng       = data['maskPng'] as Uint8List?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Mask preview
        if (maskPng != null) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: 140, width: double.infinity,
              child: Image.memory(maskPng, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(height: 12),
        ],
        // Stats row
        Row(
          children: [
            _CompostMiniStat(
              label: 'Compostable',
              value: compostPct,
              color: const Color(0xFF10B981),
              bg: const Color(0xFFD1FAE5),
            ),
            const SizedBox(width: 8),
            _CompostMiniStat(
              label: 'Non-compost.',
              value: nonCompostPct,
              color: const Color(0xFFEF4444),
              bg: const Color(0xFFFEE2E2),
            ),
            const SizedBox(width: 8),
            _CompostMiniStat(
              label: 'Fond',
              value: bgPct,
              color: const Color(0xFF64748B),
              bg: const Color(0xFFF1F5F9),
            ),
          ],
        ),
        if (ms > 0) ...[
          const SizedBox(height: 8),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '⚡ On-device ONNX · $ms ms',
                style: GoogleFonts.inter(
                  fontSize: 10, fontWeight: FontWeight.w600,
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

class _CompostMiniStat extends StatelessWidget {
  final String label;
  final double value;
  final Color  color;
  final Color  bg;
  const _CompostMiniStat(
      {required this.label, required this.value,
       required this.color, required this.bg});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          children: [
            Text(
              '${value.toStringAsFixed(1)}%',
              style: GoogleFonts.sora(
                fontSize: 16, fontWeight: FontWeight.w800, color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 9, fontWeight: FontWeight.w600,
                color: color.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Legacy widgets (kept for backward compat) ─────────────────────────────────

class _FreshnessResult extends StatelessWidget {
  final Map<String, dynamic> result;
  final Future<void> Function()? onUpdateInventory;
  final Future<void> Function()? onLogRemoval;

  const _FreshnessResult({
    required this.result,
    required this.onUpdateInventory,
    required this.onLogRemoval,
  });

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
        Center(
          child: Transform.scale(
            scale: 1.4,
            child: FreshnessBadge(status),
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: Text(
            '${(confidence * 100).round()}% confidence',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.cocoa,
            ),
          ),
        ),
        if (daysLeft != null) ...[
          const SizedBox(height: 6),
          Center(
            child: Text(
              '$daysLeft day${daysLeft == 1 ? '' : 's'} left (estimate)',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.cocoa,
              ),
            ),
          ),
        ],
        const SizedBox(height: 14),
        if (isSpoiled)
          _Banner(
            background: AppColors.cherryBlush,
            borderColor: AppColors.cherry,
            borderWidth: 2,
            text: 'Remove from stock immediately',
            textColor: AppColors.cherry,
          )
        else if (isExpiring)
          _Banner(
            background: AppColors.butter,
            borderColor: AppColors.sand,
            borderWidth: 1,
            text: daysLeft == null
                ? 'Use soon'
                : 'Use within $daysLeft day${daysLeft == 1 ? '' : 's'}',
            textColor: AppColors.riskModerateText,
          ),
        const SizedBox(height: 14),
        AnimatedButton(
          label: 'Update inventory',
          color: AppColors.olive,
          textColor: AppColors.butter,
          onTap: onUpdateInventory,
          height: 52,
        ),
        if (isSpoiled) ...[
          const SizedBox(height: 10),
          AnimatedButton(
            label: 'Log removal',
            color: AppColors.cherry,
            textColor: AppColors.butter,
            onTap: onLogRemoval,
            height: 52,
          ),
        ],
      ],
    );
  }
}

class _WasteResult extends StatelessWidget {
  final Map<String, dynamic> result;
  final Future<void> Function()? onLogWaste;
  final VoidCallback onViewWasteReport;

  const _WasteResult({
    required this.result,
    required this.onLogWaste,
    required this.onViewWasteReport,
  });

  List<Map<String, dynamic>> _detectedItems() {
    final raw = result['detectedItems'];
    if (raw is! List) return const <Map<String, dynamic>>[];

    return raw
        .whereType<Map>()
        .map(
          (entry) => <String, dynamic>{
            'name': (entry['name'] as String?)?.trim() ?? 'Waste item',
            'quantityKg': (entry['quantityKg'] as num?)?.toDouble() ?? 0.0,
          },
        )
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final items = _detectedItems();
    final mostWasted = items.isEmpty
        ? <String, dynamic>{'name': 'Waste item', 'quantityKg': 0.0}
        : items.reduce(
            (a, b) => (a['quantityKg'] as double) >= (b['quantityKg'] as double)
                ? a
                : b,
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          color: AppColors.parchment,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.innerCard),
            side: const BorderSide(color: AppColors.sand, width: 0.5),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Text(
              'Waste detected',
              style: GoogleFonts.dmSerifDisplay(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.espresso,
                height: 1.2,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final item = items[index];
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.parchment,
                borderRadius: BorderRadius.circular(AppRadii.innerCard),
                border: Border.all(color: AppColors.sand, width: 0.5),
              ),
              child: Row(
                children: [
                  const Icon(Icons.delete_outline, color: AppColors.cherry),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item['name'] as String,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.espresso,
                        height: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${(item['quantityKg'] as double).toStringAsFixed(1)} kg',
                    textAlign: TextAlign.right,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: AppColors.cocoa,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.cherry,
            borderRadius: BorderRadius.circular(AppRadii.innerCard),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Most wasted item',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.butter,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                mostWasted['name'] as String,
                style: GoogleFonts.dmSerifDisplay(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.butter,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${(mostWasted['quantityKg'] as double).toStringAsFixed(1)} kg',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFFF5C0C2),
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        AnimatedButton(
          label: 'Log waste',
          color: AppColors.olive,
          textColor: AppColors.butter,
          onTap: onLogWaste,
          height: 52,
        ),
        const SizedBox(height: 10),
        TextButton(
          onPressed: onViewWasteReport,
          child: Text(
            'View waste report',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.olive,
            ),
          ),
        ),
      ],
    );
  }
}

class _CompostResult extends StatelessWidget {
  final Map<String, dynamic> result;
  final Future<void> Function()? onLogWaste;

  const _CompostResult({
    required this.result,
    required this.onLogWaste,
  });

  @override
  Widget build(BuildContext context) {
    final isCompostable = (result['isCompostable'] as bool?) ?? false;
    final confidence = (result['confidence'] as num?)?.toDouble() ?? 0.0;

    final badgeBg = isCompostable ? AppColors.oliveMist : AppColors.cherryBlush;
    final badgeText = isCompostable ? AppColors.olive : AppColors.cherry;

    final explanation = isCompostable
        ? 'This item can go in the compost bin.'
        : 'Dispose in general waste.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppColors.sand, width: 0.5),
            ),
            child: Text(
              isCompostable ? 'Compostable' : 'Non-compostable',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: badgeText,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Center(
          child: Text(
            '${(confidence * 100).round()}% confidence',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.cocoa,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          explanation,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: AppColors.cocoa,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 14),
        AnimatedButton(
          label: 'Log to waste record',
          color: AppColors.olive,
          textColor: AppColors.butter,
          onTap: onLogWaste,
          height: 52,
        ),
      ],
    );
  }
}

class _Banner extends StatelessWidget {
  final Color background;
  final Color borderColor;
  final double borderWidth;
  final String text;
  final Color textColor;

  const _Banner({
    required this.background,
    required this.borderColor,
    required this.borderWidth,
    required this.text,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadii.innerCard),
        border: Border.all(color: borderColor, width: borderWidth),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: textColor,
          height: 1.2,
        ),
      ),
    );
  }
}
