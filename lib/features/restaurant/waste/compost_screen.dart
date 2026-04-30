import 'dart:math' as math;
import 'dart:typed_data';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/models/compost_session_model.dart';
import '../../../providers/compost_provider.dart';
import '../../../providers/user_provider.dart';

// ── Design tokens (compost feature palette) ───────────────────────────────────
const _emerald = Color(0xFF10B981);
const _emeraldDark = Color(0xFF059669);
const _emeraldLight = Color(0xFFD1FAE5);
const _emeraldMid = Color(0xFF6EE7B7);
const _rose = Color(0xFFEF4444);
const _roseLight = Color(0xFFFEE2E2);
const _slate = Color(0xFF64748B);
const _slateLight = Color(0xFFF1F5F9);
const _amber = Color(0xFFF59E0B);
const _amberLight = Color(0xFFFEF3C7);
const _ink = Color(0xFF0F172A);
const _fog2 = Color(0xFF94A3B8);
const _surface = Color(0xFFFFFFFF);

// ── Entry point ───────────────────────────────────────────────────────────────
class CompostScreen extends StatefulWidget {
  const CompostScreen({super.key});

  @override
  State<CompostScreen> createState() => _CompostScreenState();
}

class _CompostScreenState extends State<CompostScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = context.read<UserProvider>().currentUser?.id;
      if (uid != null) context.read<CompostProvider>().init(uid);
    });
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0FDF4),
      body: Column(
        children: [
          _CompostHeader(tab: _tab),
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: const [_ClassifyTab(), _HistoryTab()],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────
class _CompostHeader extends StatelessWidget {
  final TabController tab;
  const _CompostHeader({required this.tab});

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final isLoaded = context.watch<CompostProvider>().isModelLoaded;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF064E3B), Color(0xFF065F46), Color(0xFF047857)],
        ),
      ),
      child: Column(
        children: [
          SizedBox(height: topPad + 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                // Compost AI icon badge
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3)),
                  ),
                  child: const Icon(Icons.eco_rounded,
                      color: Colors.white, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Compost AI',
                        style: GoogleFonts.sora(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          height: 1.1,
                        ),
                      ),
                      Text(
                        'Classification intelligente des déchets',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.75),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isLoaded
                        ? _emerald.withValues(alpha: 0.25)
                        : Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isLoaded
                          ? _emeraldMid.withValues(alpha: 0.6)
                          : Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isLoaded ? _emeraldMid : _amber,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        isLoaded ? 'Hors ligne ✓' : 'Démo',
                        style: GoogleFonts.inter(
                          fontSize: 11,
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
          const SizedBox(height: 16),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: tab,
              indicator: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: _emeraldDark,
              unselectedLabelColor: Colors.white.withValues(alpha: 0.8),
              labelStyle: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              tabs: const [
                Tab(text: '🔬  Classifier'),
                Tab(text: '📊  Historique'),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ── Classify Tab ──────────────────────────────────────────────────────────────
class _ClassifyTab extends StatelessWidget {
  const _ClassifyTab();

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<CompostProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!prov.hasImage && !prov.hasResult) ...[
            _TodayOverviewCard(prov: prov)
                .animate()
                .fadeIn(duration: 400.ms)
                .slideY(begin: 0.15, end: 0),
            const SizedBox(height: 16),
            _PhotoCard(prov: prov)
                .animate()
                .fadeIn(duration: 400.ms, delay: 80.ms)
                .slideY(begin: 0.15, end: 0),
            const SizedBox(height: 16),
            const _EducationCards()
                .animate()
                .fadeIn(duration: 400.ms, delay: 160.ms)
                .slideY(begin: 0.15, end: 0),
          ] else if (prov.isAnalyzing) ...[
            _AnalyzingCard().animate().fadeIn(duration: 300.ms),
          ] else if (prov.hasResult) ...[
            _ResultSection(prov: prov)
                .animate()
                .fadeIn(duration: 400.ms)
                .slideY(begin: 0.1, end: 0),
          ] else if (prov.state == CompostState.error) ...[
            _ErrorCard(message: prov.errorMessage ?? 'Erreur inconnue')
                .animate()
                .fadeIn(duration: 300.ms),
            const SizedBox(height: 12),
            _retakeButton(context, prov),
          ] else if (prov.hasImage) ...[
            _ImagePreviewCard(prov: prov)
                .animate()
                .fadeIn(duration: 350.ms)
                .scale(begin: const Offset(0.95, 0.95)),
            const SizedBox(height: 16),
            _ClassifyButton(prov: prov)
                .animate()
                .fadeIn(duration: 350.ms, delay: 100.ms),
            const SizedBox(height: 10),
            _retakeButton(context, prov),
          ],
        ],
      ),
    );
  }

  Widget _retakeButton(BuildContext ctx, CompostProvider prov) {
    return OutlinedButton.icon(
      onPressed: prov.reset,
      icon: const Icon(Icons.refresh_rounded, size: 18),
      label: const Text('Nouvelle photo'),
      style: OutlinedButton.styleFrom(
        foregroundColor: _slate,
        side: const BorderSide(color: _fog2),
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }
}

// ── Today overview card ───────────────────────────────────────────────────────
class _TodayOverviewCard extends StatelessWidget {
  final CompostProvider prov;
  const _TodayOverviewCard({required this.prov});

  @override
  Widget build(BuildContext context) {
    final count = prov.todaySessionCount;
    final compost = prov.todayCompostablePct;
    final nonCompost = prov.todayNonCompostablePct;
    final bg = math.max(0.0, 100.0 - compost - nonCompost);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _emerald.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _emeraldLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.eco_rounded,
                    color: _emeraldDark, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Aujourd'hui",
                      style: GoogleFonts.sora(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _ink,
                      ),
                    ),
                    Text(
                      count == 0
                          ? 'Aucune analyse'
                          : '$count analyse${count > 1 ? 's' : ''}',
                      style: GoogleFonts.inter(fontSize: 12, color: _fog2),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (count > 0) ...[
            const SizedBox(height: 16),
            SizedBox(
              height: 120,
              child: Row(
                children: [
                  Expanded(
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 32,
                        sections: [
                          PieChartSectionData(
                            value: compost,
                            color: _emerald,
                            radius: 28,
                            showTitle: false,
                          ),
                          PieChartSectionData(
                            value: nonCompost,
                            color: _rose,
                            radius: 28,
                            showTitle: false,
                          ),
                          PieChartSectionData(
                            value: bg,
                            color: _slateLight,
                            radius: 28,
                            showTitle: false,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Legend(
                        color: _emerald,
                        label: 'Compostable',
                        value: '${compost.toStringAsFixed(1)}%',
                      ),
                      const SizedBox(height: 8),
                      _Legend(
                        color: _rose,
                        label: 'Non-compost.',
                        value: '${nonCompost.toStringAsFixed(1)}%',
                      ),
                      const SizedBox(height: 8),
                      _Legend(
                        color: _slateLight,
                        label: 'Fond',
                        value: '${bg.toStringAsFixed(1)}%',
                        borderColor: _fog2,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ] else ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: _emeraldLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  'Prenez votre première photo pour commencer',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: _emeraldDark,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  final String value;
  final Color? borderColor;
  const _Legend({
    required this.color,
    required this.label,
    required this.value,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: borderColor != null
                ? Border.all(color: borderColor!)
                : null,
          ),
        ),
        const SizedBox(width: 7),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: GoogleFonts.inter(fontSize: 11, color: _slate)),
            Text(value,
                style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _ink)),
          ],
        ),
      ],
    );
  }
}

// ── Photo action card ─────────────────────────────────────────────────────────
class _PhotoCard extends StatelessWidget {
  final CompostProvider prov;
  const _PhotoCard({required this.prov});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF064E3B), Color(0xFF065F46)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _emerald.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          _PulsingIcon(),
          const SizedBox(height: 14),
          Text(
            'Analyser vos déchets',
            style: GoogleFonts.sora(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "L'IA segmente automatiquellement\ncompostable vs non-compostable",
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.75),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _ActionChip(
                  icon: Icons.camera_alt_rounded,
                  label: 'Caméra',
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    prov.pickFromCamera();
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ActionChip(
                  icon: Icons.photo_library_rounded,
                  label: 'Galerie',
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    prov.pickFromGallery();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PulsingIcon extends StatefulWidget {
  @override
  State<_PulsingIcon> createState() => _PulsingIconState();
}

class _PulsingIconState extends State<_PulsingIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.15),
        ),
        child: const Icon(Icons.eco_rounded, color: Colors.white, size: 34),
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(height: 5),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Education cards ───────────────────────────────────────────────────────────
class _EducationCards extends StatelessWidget {
  const _EducationCards();

  static const _composable = [
    ('🥦', 'Légumes & fruits'),
    ('☕', 'Marc de café'),
    ('🥚', "Coquilles d'œufs"),
    ('🌿', 'Herbes fraîches'),
    ('🍞', 'Pain rassis'),
    ('🍂', 'Feuilles mortes'),
  ];

  static const _nonComposable = [
    ('🥩', 'Viandes cuites'),
    ('🧴', 'Emballages plastique'),
    ('🪟', 'Verre'),
    ('🥫', 'Métal / canettes'),
    ('🛢️', 'Huile de cuisson'),
    ('🧻', 'Papier gras'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '✅  Compostable',
          style: GoogleFonts.sora(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: _emeraldDark,
          ),
        ),
        const SizedBox(height: 10),
        _list(_composable, _emeraldLight, _emeraldDark),
        const SizedBox(height: 16),
        Text(
          '❌  Non-compostable',
          style: GoogleFonts.sora(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: _rose,
          ),
        ),
        const SizedBox(height: 10),
        _list(_nonComposable, _roseLight, _rose),
      ],
    );
  }

  Widget _list(
      List<(String, String)> items, Color bg, Color textColor) {
    return SizedBox(
      height: 78,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          return Container(
            width: 90,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(items[i].$1,
                    style: const TextStyle(fontSize: 22)),
                const SizedBox(height: 4),
                Text(
                  items[i].$2,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Image preview ─────────────────────────────────────────────────────────────
class _ImagePreviewCard extends StatelessWidget {
  final CompostProvider prov;
  const _ImagePreviewCard({required this.prov});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 260,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (prov.selectedImageBytes != null)
              Image.memory(prov.selectedImageBytes!, fit: BoxFit.cover)
            else if (!kIsWeb && prov.selectedImageFile != null)
              // ignore: avoid_web_libraries_in_flutter
              Image.file(prov.selectedImageFile!, fit: BoxFit.cover),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.4),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 14,
              left: 14,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Image prête pour analyse',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Classify button ───────────────────────────────────────────────────────────
class _ClassifyButton extends StatelessWidget {
  final CompostProvider prov;
  const _ClassifyButton({required this.prov});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        prov.classify();
      },
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF059669), Color(0xFF10B981)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _emerald.withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.biotech_rounded,
                  color: Colors.white, size: 22),
              const SizedBox(width: 10),
              Text(
                "Lancer l'analyse IA",
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
    );
  }
}

// ── Analyzing card ────────────────────────────────────────────────────────────
class _AnalyzingCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _emerald.withValues(alpha: 0.08),
            blurRadius: 20,
          ),
        ],
      ),
      child: Column(
        children: [
          const _SpinningLoader(),
          const SizedBox(height: 20),
          Text(
            'Analyse en cours…',
            style: GoogleFonts.sora(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: _ink,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Segmentation pixel par pixel\ncompostable · non-compostable · fond',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: _fog2,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          _AnimatedSteps(),
        ],
      ),
    );
  }
}

class _SpinningLoader extends StatefulWidget {
  const _SpinningLoader();

  @override
  State<_SpinningLoader> createState() => _SpinningLoaderState();
}

class _SpinningLoaderState extends State<_SpinningLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _ctrl,
      child: Container(
        width: 64,
        height: 64,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: SweepGradient(
            colors: [_emerald, Colors.transparent],
          ),
        ),
        child: Container(
          margin: const EdgeInsets.all(4),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: _surface,
          ),
          child: const Icon(Icons.eco_rounded, color: _emerald, size: 28),
        ),
      ),
    );
  }
}

class _AnimatedSteps extends StatefulWidget {
  @override
  State<_AnimatedSteps> createState() => _AnimatedStepsState();
}

class _AnimatedStepsState extends State<_AnimatedSteps> {
  int _step = 0;
  static const _steps = [
    "Décodage de l'image…",
    'LongestMaxSize + padding 512×512…',
    'Inférence Mask2Former (mask2former_fp32)…',
    "Génération de l'overlay coloré…",
  ];

  @override
  void initState() {
    super.initState();
    _advance();
  }

  Future<void> _advance() async {
    for (int i = 0; i < _steps.length; i++) {
      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      setState(() => _step = i);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Text(
        _steps[_step],
        key: ValueKey(_step),
        style: GoogleFonts.inter(
          fontSize: 12,
          color: _emeraldDark,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

// ── Result section ────────────────────────────────────────────────────────────
class _ResultSection extends StatelessWidget {
  final CompostProvider prov;
  const _ResultSection({required this.prov});

  @override
  Widget build(BuildContext context) {
    final result = prov.result!;
    // Safe on both web (selectedImageBytes) and native (file read)
    final Uint8List? originalBytes = prov.selectedImageBytes ??
        (!kIsWeb && prov.selectedImageFile != null
            ? prov.selectedImageFile!.readAsBytesSync()
            : null);
    if (originalBytes == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ImageComparisonSlider(
          originalBytes: originalBytes,  // non-null guaranteed above
          maskBytes: result.maskPng,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _AnimatedStatCard(
                label: 'Compostable',
                value: result.compostablePct,
                color: _emerald,
                bgColor: _emeraldLight,
                icon: Icons.eco_rounded,
                delay: 0,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _AnimatedStatCard(
                label: 'Non-compost.',
                value: result.nonCompostablePct,
                color: _rose,
                bgColor: _roseLight,
                icon: Icons.cancel_outlined,
                delay: 120,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _AnimatedStatCard(
                label: 'Fond',
                value: result.backgroundPct,
                color: _slate,
                bgColor: _slateLight,
                icon: Icons.layers_outlined,
                delay: 240,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: _amberLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '⚡ Inférence en ${result.inferenceTimeMs} ms',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF92400E),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (!prov.isSaved)
          GestureDetector(
            onTap: () {
              HapticFeedback.mediumImpact();
              prov.saveSession();
            },
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF059669), Color(0xFF10B981)],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: _emerald.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: prov.state == CompostState.saving
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
                          const Icon(Icons.save_alt_rounded,
                              color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Sauvegarder la session',
                            style: GoogleFonts.sora(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          )
        else
          Container(
            height: 52,
            decoration: BoxDecoration(
              color: _emeraldLight,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _emeraldMid),
            ),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle_rounded,
                      color: _emeraldDark, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Session sauvegardée !',
                    style: GoogleFonts.sora(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _emeraldDark,
                    ),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: () {
            HapticFeedback.selectionClick();
            prov.reset();
          },
          icon: const Icon(Icons.camera_alt_outlined, size: 18),
          label: const Text('Nouvelle analyse'),
          style: OutlinedButton.styleFrom(
            foregroundColor: _slate,
            side: const BorderSide(color: _fog2),
            minimumSize: const Size.fromHeight(48),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ],
    );
  }
}

// ── Split-view comparison slider ──────────────────────────────────────────────
class _ImageComparisonSlider extends StatefulWidget {
  final Uint8List? originalBytes;
  final Uint8List maskBytes;
  const _ImageComparisonSlider({
    required this.originalBytes,
    required this.maskBytes,
  });

  @override
  State<_ImageComparisonSlider> createState() =>
      _ImageComparisonSliderState();
}

class _ImageComparisonSliderState extends State<_ImageComparisonSlider>
    with TickerProviderStateMixin {
  double _splitX = 0.5;
  bool _hasInteracted = false;
  late final AnimationController _maskAnim;
  late final Animation<double> _maskOpacity;
  late final AnimationController _hintAnim;

  @override
  void initState() {
    super.initState();
    _maskAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    _maskOpacity =
        CurvedAnimation(parent: _maskAnim, curve: Curves.easeOut);

    // Animate hint arrow left-right after reveal
    _hintAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) _hintAnim.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _maskAnim.dispose();
    _hintAnim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final W = constraints.maxWidth;
            final H = constraints.maxHeight;
            return GestureDetector(
              onPanUpdate: (d) {
                setState(() {
                  _splitX =
                      (_splitX + d.delta.dx / W).clamp(0.05, 0.95);
                  if (!_hasInteracted) {
                    _hasInteracted = true;
                    _hintAnim.stop();
                  }
                });
              },
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (widget.originalBytes != null)
                    Image.memory(widget.originalBytes!, fit: BoxFit.cover)
                  else
                    Container(color: const Color(0xFF1B4332)),
                  FadeTransition(
                    opacity: _maskOpacity,
                    child: ClipRect(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        widthFactor: _splitX,
                        child: SizedBox(
                          width: W,
                          height: H,
                          child: Image.memory(
                            widget.maskBytes,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: _emerald.withValues(alpha: 0.35),
                              child: const Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.eco_rounded,
                                        color: Colors.white, size: 32),
                                    SizedBox(height: 8),
                                    Text(
                                      'Masque IA',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: _splitX * W - 1.5,
                    top: 0,
                    bottom: 0,
                    child: SizedBox(
                      width: 3,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // White divider line
                          Container(width: 3, color: Colors.white),
                          // Handle circle
                          Align(
                            alignment: Alignment.center,
                            child: AnimatedBuilder(
                              animation: _hintAnim,
                              builder: (_, child) {
                                final offset = _hasInteracted
                                    ? 0.0
                                    : (_hintAnim.value - 0.5) * 14;
                                return Transform.translate(
                                  offset: Offset(offset, 0),
                                  child: child,
                                );
                              },
                              child: Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.22),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                    Icons.compare_arrows_rounded,
                                    size: 20,
                                    color: _emeraldDark),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    left: 10,
                    child: _overlayLabel('🟢 Segmentation IA'),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: _overlayLabel('📷 Original'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _overlayLabel(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }
}

// ── Animated stat card ────────────────────────────────────────────────────────
class _AnimatedStatCard extends StatefulWidget {
  final String label;
  final double value;
  final Color color;
  final Color bgColor;
  final IconData icon;
  final int delay;

  const _AnimatedStatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.bgColor,
    required this.icon,
    required this.delay,
  });

  @override
  State<_AnimatedStatCard> createState() => _AnimatedStatCardState();
}

class _AnimatedStatCardState extends State<_AnimatedStatCard>
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
    _val = Tween<double>(begin: 0, end: widget.value).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
    );
    Future.delayed(Duration(milliseconds: widget.delay), () {
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      decoration: BoxDecoration(
        color: widget.bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.color.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        children: [
          Icon(widget.icon, color: widget.color, size: 22),
          const SizedBox(height: 6),
          AnimatedBuilder(
            animation: _val,
            builder: (_, __) => Text(
              '${_val.value.toStringAsFixed(1)}%',
              style: GoogleFonts.sora(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: widget.color,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            widget.label,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: widget.color.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Error card ────────────────────────────────────────────────────────────────
class _ErrorCard extends StatelessWidget {
  final String message;
  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _roseLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _rose.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: _rose, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(message,
                style: GoogleFonts.inter(fontSize: 13, color: _rose)),
          ),
        ],
      ),
    );
  }
}

// ── History Tab ───────────────────────────────────────────────────────────────
class _HistoryTab extends StatelessWidget {
  const _HistoryTab();

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<CompostProvider>();
    final sessions = prov.sessions;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _WeeklyChart(weekly: prov.weeklyCompostPct)
              .animate()
              .fadeIn(duration: 400.ms)
              .slideY(begin: 0.1, end: 0),
          const SizedBox(height: 20),
          if (sessions.isEmpty)
            _EmptyHistory().animate().fadeIn(duration: 400.ms, delay: 100.ms)
          else ...[
            Text(
              'Sessions récentes',
              style: GoogleFonts.sora(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: _ink,
              ),
            ),
            const SizedBox(height: 12),
            ...sessions.asMap().entries.map((e) {
              return _SessionCard(session: e.value)
                  .animate()
                  .fadeIn(
                    duration: 350.ms,
                    delay: Duration(milliseconds: 60 * e.key),
                  )
                  .slideX(begin: 0.05, end: 0);
            }),
          ],
        ],
      ),
    );
  }
}

class _WeeklyChart extends StatelessWidget {
  final List<double> weekly;
  const _WeeklyChart({required this.weekly});

  @override
  Widget build(BuildContext context) {
    const days = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _emerald.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _emeraldLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.show_chart_rounded,
                    color: _emeraldDark, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Tendance hebdomadaire',
                style: GoogleFonts.sora(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: _ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 140,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, _) {
                        final i = value.toInt();
                        if (i < 0 || i >= days.length) {
                          return const SizedBox.shrink();
                        }
                        return Text(days[i],
                            style: GoogleFonts.inter(
                                fontSize: 11,
                                color: _fog2,
                                fontWeight: FontWeight.w500));
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: weekly.asMap().entries.map((e) {
                      return FlSpot(e.key.toDouble(), e.value);
                    }).toList(),
                    isCurved: true,
                    color: _emerald,
                    barWidth: 2.5,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, pct, bar, idx) =>
                          FlDotCirclePainter(
                        radius: 4,
                        color: _emerald,
                        strokeWidth: 2,
                        strokeColor: _surface,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          _emerald.withValues(alpha: 0.2),
                          _emerald.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ],
                minY: 0,
                maxY: 100,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: BoxDecoration(
        color: _emeraldLight.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _emerald.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          const Text('🌱', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          Text(
            'Aucune session enregistrée',
            style: GoogleFonts.sora(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _emeraldDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Analysez vos déchets dans l\'onglet\n"Classifier" pour voir votre historique',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: _slate,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  final CompostSession session;
  const _SessionCard({required this.session});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd/MM/yyyy HH:mm');

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: _emeraldLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: session.imageUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      session.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.eco_rounded,
                        color: _emeraldDark,
                        size: 26,
                      ),
                    ),
                  )
                : const Icon(Icons.eco_rounded,
                    color: _emeraldDark, size: 26),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fmt.format(session.timestamp),
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: _fog2,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Row(
                    children: [
                      Expanded(
                        flex: session.compostablePct.round(),
                        child: Container(height: 6, color: _emerald),
                      ),
                      Expanded(
                        flex: session.nonCompostablePct.round(),
                        child: Container(height: 6, color: _rose),
                      ),
                      Expanded(
                        flex: session.backgroundPct.round(),
                        child: Container(height: 6, color: _slateLight),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    _pctBadge(
                      '${session.compostablePct.toStringAsFixed(0)}%',
                      _emeraldLight,
                      _emeraldDark,
                    ),
                    const SizedBox(width: 6),
                    _pctBadge(
                      '${session.nonCompostablePct.toStringAsFixed(0)}%',
                      _roseLight,
                      _rose,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${session.inferenceTimeMs}ms',
            style: GoogleFonts.inter(
              fontSize: 10,
              color: _fog2,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _pctBadge(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }
}
