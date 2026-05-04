import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/api_config.dart';
import '../../../core/models/waste_pipeline_result.dart';
import 'waste_pipeline_service.dart';

const _ink = Color(0xFF111827);
const _slate = Color(0xFF64748B);
const _fog = Color(0xFFF8FAFC);
const _surface = Color(0xFFFFFFFF);
const _line = Color(0xFFE2E8F0);
const _amber = Color(0xFFF59E0B);
const _amberDark = Color(0xFFD97706);
const _amberLight = Color(0xFFFEF3C7);
const _indigo = Color(0xFF4F46E5);
const _indigoLight = Color(0xFFE0E7FF);
const _rose = Color(0xFFE11D48);
const _roseLight = Color(0xFFFFE4E6);

class WasteScreen extends StatefulWidget {
  const WasteScreen({super.key});

  @override
  State<WasteScreen> createState() => _WasteScreenState();
}

class _WasteScreenState extends State<WasteScreen> {
  final _picker = ImagePicker();
  late final WastePipelineService _wasteService;

  Uint8List? _imageBytes;
  WastePipelineResult? _result;
  String? _error;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _wasteService = WastePipelineService(baseUrl: ApiConfig.wastePipelineApi);
  }

  @override
  void dispose() {
    _wasteService.dispose();
    super.dispose();
  }

  Future<void> _pick(ImageSource source) async {
    if (_loading) return;
    HapticFeedback.mediumImpact();
    setState(() => _error = null);

    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 90,
        maxWidth: 1440,
      );
      if (picked == null) return;

      final bytes = await picked.readAsBytes();
      setState(() {
        _imageBytes = bytes;
        _result = null;
        _loading = true;
      });

      final result = await _wasteService.analyze(bytes);
      if (!mounted) return;
      setState(() {
        _result = result;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = List<WasteMassEstimate>.from(
      _result?.massEstimates ?? const [],
    )..sort((a, b) => b.estimatedKg.compareTo(a.estimatedKg));

    return Scaffold(
      backgroundColor: _fog,
      body: Column(
        children: [
          const _WasteHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _PhotoCard(
                        loading: _loading,
                        onGallery: () => _pick(ImageSource.gallery),
                        onCamera: () => _pick(ImageSource.camera),
                      )
                      .animate()
                      .fadeIn(duration: 350.ms)
                      .slideY(begin: 0.12, end: 0),
                  const SizedBox(height: 16),
                  if (_loading)
                    const _LoadingCard().animate().fadeIn(duration: 250.ms)
                  else if (_error != null)
                    _ErrorCard(
                      message: _error!,
                    ).animate().fadeIn(duration: 250.ms)
                  else if (_imageBytes == null)
                    const _EmptyState()
                        .animate()
                        .fadeIn(duration: 350.ms, delay: 80.ms)
                        .slideY(begin: 0.12, end: 0)
                  else
                    _ResultSection(
                          originalBytes: _imageBytes,
                          overlayBytes: _result?.overlayPng,
                          items: items,
                          totalKg: _result?.totalWasteKg ?? 0,
                          pipelineMs: _result?.pipelineTimeMs ?? 0,
                        )
                        .animate()
                        .fadeIn(duration: 350.ms)
                        .slideY(begin: 0.08, end: 0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WasteHeader extends StatelessWidget {
  const _WasteHeader();

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF312E81), Color(0xFF4338CA), Color(0xFFF59E0B)],
        ),
      ),
      child: Column(
        children: [
          SizedBox(height: topPad + 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.28),
                    ),
                  ),
                  child: const Icon(
                    Icons.analytics_rounded,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Waste AI',
                        style: GoogleFonts.sora(
                          fontSize: 23,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          height: 1.05,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Detection et estimation de masse',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.78),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.28),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: _amber,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'API',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
        ],
      ),
    );
  }
}

class _PhotoCard extends StatelessWidget {
  final bool loading;
  final VoidCallback onGallery;
  final VoidCallback onCamera;

  const _PhotoCard({
    required this.loading,
    required this.onGallery,
    required this.onCamera,
  });

  @override
  Widget build(BuildContext context) {
    return _Card(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _IconBox(
                icon: Icons.add_a_photo_rounded,
                color: _amberDark,
                bg: _amberLight,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nouvelle analyse',
                      style: GoogleFonts.sora(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _ink,
                      ),
                    ),
                    Text(
                      'Importez une assiette pour identifier les pertes.',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: _slate,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  icon: Icons.photo_library_rounded,
                  label: 'Galerie',
                  onTap: loading ? null : onGallery,
                  filled: false,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ActionButton(
                  icon: Icons.photo_camera_rounded,
                  label: 'Camera',
                  onTap: loading ? null : onCamera,
                  filled: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool filled;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.filled,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: filled ? _amber : _indigoLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: filled ? _amber : _indigo.withValues(alpha: 0.18),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: filled ? Colors.white : _indigo, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: filled ? Colors.white : _indigo,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return _Card(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2.5, color: _amber),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Analyse en cours...',
                  style: GoogleFonts.sora(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _ink,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Le modele segmente l image et calcule le poids estime.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: _slate,
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

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _Card(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              const _IconBox(
                icon: Icons.restaurant_menu_rounded,
                color: _indigo,
                bg: _indigoLight,
                size: 54,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pret pour le controle de pertes',
                      style: GoogleFonts.sora(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Prenez une photo claire, de haut, avec toute l assiette visible.',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: _slate,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: const [
            Expanded(
              child: _HintCard(
                icon: Icons.center_focus_strong_rounded,
                title: 'Cadrage net',
                color: _indigo,
                bg: _indigoLight,
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: _HintCard(
                icon: Icons.scale_rounded,
                title: 'Masse estimee',
                color: _amberDark,
                bg: _amberLight,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _HintCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final Color bg;

  const _HintCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return _Card(
      height: 86,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _IconBox(icon: icon, color: color, bg: bg, size: 30),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: _ink,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _roseLight,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _rose.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_rounded, color: _rose, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _rose,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultSection extends StatelessWidget {
  final Uint8List? originalBytes;
  final Uint8List? overlayBytes;
  final List<WasteMassEstimate> items;
  final double totalKg;
  final int pipelineMs;

  const _ResultSection({
    required this.originalBytes,
    required this.overlayBytes,
    required this.items,
    required this.totalKg,
    required this.pipelineMs,
  });

  @override
  Widget build(BuildContext context) {
    final topItems = items.take(6).toList(growable: false);
    final maxKg = topItems.isEmpty ? 1.0 : topItems.first.estimatedKg;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ImageResultCard(
          originalBytes: originalBytes,
          overlayBytes: overlayBytes,
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _MetricTile(
                icon: Icons.monitor_weight_rounded,
                label: 'Total detecte',
                value: '${totalKg.toStringAsFixed(2)} kg',
                color: _amberDark,
                bg: _amberLight,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricTile(
                icon: Icons.speed_rounded,
                label: 'Pipeline',
                value: '$pipelineMs ms',
                color: _indigo,
                bg: _indigoLight,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _Card(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Categories detectees',
                    style: GoogleFonts.sora(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _ink,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _fog,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${items.length}',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: _slate,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (topItems.isEmpty)
                Text(
                  'Aucun aliment detecte dans l assiette.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: _slate,
                  ),
                )
              else
                for (final item in topItems)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _WasteItemRow(item: item, maxKg: maxKg),
                  ),
              if (items.length > topItems.length) ...[
                const SizedBox(height: 2),
                Text(
                  '${items.length - topItems.length} autres categories detectees',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _slate,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ImageResultCard extends StatelessWidget {
  final Uint8List? originalBytes;
  final Uint8List? overlayBytes;

  const _ImageResultCard({
    required this.originalBytes,
    required this.overlayBytes,
  });

  @override
  Widget build(BuildContext context) {
    final bytes = overlayBytes ?? originalBytes;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _line),
        boxShadow: [
          BoxShadow(
            color: _ink.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          if (bytes != null)
            Image.memory(
              bytes,
              height: 248,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          Positioned(
            left: 12,
            top: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.46),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    overlayBytes != null
                        ? Icons.layers_rounded
                        : Icons.image_rounded,
                    color: Colors.white,
                    size: 15,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    overlayBytes != null ? 'Masque IA' : 'Image originale',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
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

class _MetricTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final Color bg;

  const _MetricTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return _Card(
      height: 104,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _IconBox(icon: icon, color: color, bg: bg, size: 32),
          const Spacer(),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.sora(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: _ink,
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: _slate,
            ),
          ),
        ],
      ),
    );
  }
}

class _WasteItemRow extends StatelessWidget {
  final WasteMassEstimate item;
  final double maxKg;

  const _WasteItemRow({required this.item, required this.maxKg});

  @override
  Widget build(BuildContext context) {
    final ratio = maxKg <= 0
        ? 0.0
        : (item.estimatedKg / maxKg).clamp(0.06, 1.0);

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _ink,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${item.estimatedKg.toStringAsFixed(2)} kg',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: _amberDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 7,
            backgroundColor: _fog,
            valueColor: const AlwaysStoppedAnimation<Color>(_amber),
          ),
        ),
      ],
    );
  }
}

class _IconBox extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color bg;
  final double size;

  const _IconBox({
    required this.icon,
    required this.color,
    required this.bg,
    this.size = 38,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(size >= 50 ? 16 : 10),
      ),
      child: Icon(icon, color: color, size: size * 0.55),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double? height;

  const _Card({required this.child, required this.padding, this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _line),
        boxShadow: [
          BoxShadow(
            color: _ink.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}
