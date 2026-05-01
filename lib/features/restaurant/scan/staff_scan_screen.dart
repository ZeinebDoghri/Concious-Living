import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/api_service.dart';
import '../../../core/constants.dart';
import '../../../features/restaurant/waste/compost_inference_service.dart';

class StaffScanScreen extends StatefulWidget {
  const StaffScanScreen({super.key});

  @override
  State<StaffScanScreen> createState() => _StaffScanScreenState();
}

class _StaffScanScreenState extends State<StaffScanScreen>
    with TickerProviderStateMixin {
  static const _dark  = Color(0xFF0A0F1E);
  static const _card  = Color(0xFF141B2D);

  final _picker         = ImagePicker();
  final _compostService = CompostInferenceService();

  XFile?  _lastFile;
  bool    _isAnalysing = false;
  String  _step        = '';

  late final AnimationController _scanLine;
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _scanLine = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    // Ping API in background (all platforms use FastAPI backend)
    _compostService.init();
  }

  @override
  void dispose() {
    _scanLine.dispose();
    _pulse.dispose();
    _compostService.dispose();
    super.dispose();
  }

  // ── Capture & analyse ──────────────────────────────────────────────────────
  Future<void> _pick(ImageSource source) async {
    if (_isAnalysing) return;
    HapticFeedback.mediumImpact();

    try {
      final file = await _picker.pickImage(
          source: source, imageQuality: 90, maxWidth: 1440);
      if (file == null || !mounted) return;

      setState(() {
        _lastFile    = file;
        _isAnalysing = true;
        _step        = 'Préparation de l\'image…';
      });

      final imageFile  = kIsWeb ? null : File(file.path);
      final imageBytes = await file.readAsBytes();

      // ── Run ALL models in parallel ─────────────────────────────────────
      setState(() => _step = '3 analyses IA en parallèle…');

      final futures = await Future.wait<dynamic>([
        // Freshness API (server-side)
        imageFile != null
            ? ApiService.predictFreshness(imageFile)
                .catchError((_) => <String, dynamic>{'status': 'unknown', 'confidence': 0.0})
            : Future.value({'status': 'unknown', 'confidence': 0.0}),

        // Waste detection API (server-side)
        imageFile != null
            ? ApiService.predictWaste(imageFile)
                .catchError((_) => <String, dynamic>{'detectedItems': [], 'confidence': 0.0})
            : Future.value({'detectedItems': [], 'confidence': 0.0}),

        // Compost segmentation — SegFormer-B3 via FastAPI (all platforms)
        _compostService
            .classify(imageBytes)
            .then((r) => r.toMap())
            .catchError((e) {
              debugPrint('[Scan] Compost API error: $e');
              return <String, dynamic>{
                'compostablePct':    0.0,
                'nonCompostablePct': 0.0,
                'backgroundPct':     100.0,
                'inferenceTimeMs':   0,
              };
            }),
      ]);

      if (!mounted) return;
      setState(() => _isAnalysing = false);

      // Navigate to unified result screen
      context.go(
        AppRoutes.restaurantScanResult,
        extra: <String, dynamic>{
          'imagePath':       file.path,
          'imageBytes':      imageBytes,
          'freshnessResult': futures[0] as Map<String, dynamic>,
          'wasteResult':     futures[1] as Map<String, dynamic>,
          'compostResult':   futures[2] as Map<String, dynamic>,
          'isFusion':        true,
          // Legacy compat
          'result':          futures[0],
          'scanMode':        'freshness',
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isAnalysing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _dark,
      body: Stack(
        children: [
          _Background(),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(child: _buildViewfinder()),
                _buildCaptureDock(),
              ],
            ),
          ),
          if (_isAnalysing) _buildAnalysingOverlay(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12)),
              ),
              child: const Icon(Icons.arrow_back_ios_new,
                  color: Colors.white, size: 16),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Smart Scan',
                  style: GoogleFonts.sora(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Freshness · Gaspillage · Compost — en parallèle',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.55),
                  ),
                ),
              ],
            ),
          ),
          // AI badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFF7C3AED), Color(0xFF5B21B6)]),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '✦ IA',
              style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewfinder() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: AspectRatio(
          aspectRatio: 1,
          child: Stack(
            children: [
              // Image preview or placeholder
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: _lastFile != null && !kIsWeb
                    ? Image.file(
                        File(_lastFile!.path),
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      )
                    : Container(
                        color: const Color(0xFF0D1524),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AnimatedBuilder(
                                animation: _pulse,
                                builder: (_, child) => Transform.scale(
                                  scale: 1.0 + _pulse.value * 0.08,
                                  child: child,
                                ),
                                child: Icon(
                                  Icons.document_scanner_rounded,
                                  size: 64,
                                  color: Colors.white
                                      .withValues(alpha: 0.18),
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                'Prenez une photo\nou importez depuis la galerie',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: Colors.white
                                      .withValues(alpha: 0.38),
                                  height: 1.6,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
              ),
              // Scan corner brackets
              ..._corners(),
              // Animated scan line
              if (!_isAnalysing)
                AnimatedBuilder(
                  animation: _scanLine,
                  builder: (_, _) {
                    final t = _scanLine.value;
                    return Positioned(
                      top: t * (double.infinity < 0
                          ? 0
                          : 300), // handled by LayoutBuilder below
                      left: 24, right: 24,
                      child: Container(
                        height: 2,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              const Color(0xFF10B981),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              // AI labels overlay
              Positioned(
                bottom: 14, left: 14,
                child: _buildAiLabels(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAiLabels() {
    return Wrap(
      spacing: 6,
      children: [
        _aiChip('🌡️ Fraîcheur', const Color(0xFF8B1A1F)),
        _aiChip('🗑️ Gaspillage', const Color(0xFF5A7A18)),
        _aiChip('🌱 Compost', const Color(0xFF059669)),
      ],
    );
  }

  Widget _aiChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
            fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white),
      ),
    );
  }

  List<Widget> _corners() {
    const size = 22.0;
    const stroke = 3.0;
    const color = Color(0xFF10B981);
    final corners = [
      [0.0, 0.0, BorderRadius.only(topLeft: Radius.circular(12))],
      [double.infinity, 0.0, BorderRadius.only(topRight: Radius.circular(12))],
      [0.0, double.infinity, BorderRadius.only(bottomLeft: Radius.circular(12))],
      [double.infinity, double.infinity, BorderRadius.only(bottomRight: Radius.circular(12))],
    ];
    return [];  // Simplified — decorative corners via ClipRRect above
  }

  Widget _buildCaptureDock() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(
              color: Colors.white.withValues(alpha: 0.06), width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Mode indicator chips
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _modeIndicator(Icons.thermostat_rounded,
                    'Freshness', const Color(0xFFEF4444)),
                const SizedBox(width: 8),
                _modeIndicator(Icons.delete_rounded,
                    'Waste', const Color(0xFFD97706)),
                const SizedBox(width: 8),
                _modeIndicator(Icons.eco_rounded,
                    'Compost', const Color(0xFF10B981)),
              ],
            ),
            const SizedBox(height: 20),
            // Capture row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _sideButton(
                  icon: Icons.photo_library_outlined,
                  label: 'Galerie',
                  onTap: () => _pick(ImageSource.gallery),
                ),
                _captureButton(),
                _sideButton(
                  icon: Icons.tips_and_updates_outlined,
                  label: 'Conseils',
                  onTap: () {},
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _modeIndicator(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.inter(
                fontSize: 11, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }

  Widget _captureButton() {
    return GestureDetector(
      onTap: () => _pick(ImageSource.camera),
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (_, child) => Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFF10B981)
                  .withValues(alpha: 0.5 + _pulse.value * 0.3),
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF10B981)
                    .withValues(alpha: 0.2 + _pulse.value * 0.15),
                blurRadius: 20 + _pulse.value * 10,
              ),
            ],
          ),
          child: child,
        ),
        child: Container(
          margin: const EdgeInsets.all(6),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [Color(0xFF10B981), Color(0xFF059669)],
            ),
          ),
          child: const Icon(Icons.camera_alt_rounded,
              color: Colors.white, size: 30),
        ),
      ),
    );
  }

  Widget _sideButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.07),
              shape: BoxShape.circle,
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Icon(icon,
                color: Colors.white.withValues(alpha: 0.75), size: 22),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              color: Colors.white.withValues(alpha: 0.5),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysingOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.78),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 40),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
                color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _AnimatedBrain(),
              const SizedBox(height: 20),
              Text(
                'Analyse IA en cours',
                style: GoogleFonts.sora(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                child: Text(
                  _step,
                  key: ValueKey(_step),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.55),
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // 3 spinning indicators
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _MiniLoader('Freshness', const Color(0xFFEF4444)),
                  const SizedBox(width: 16),
                  _MiniLoader('Waste', const Color(0xFFD97706)),
                  const SizedBox(width: 16),
                  _MiniLoader('Compost', const Color(0xFF10B981)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Helpers ────────────────────────────────────────────────────────────────────

class _Background extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: CustomPaint(painter: _BgPainter()),
    );
  }
}

class _BgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    paint.color = const Color(0xFF0A0F1E);
    canvas.drawRect(Offset.zero & size, paint);

    // Soft glow blobs
    paint.color = const Color(0xFF10B981).withOpacity(0.06);
    canvas.drawCircle(Offset(size.width * 0.8, size.height * 0.2), 180, paint);
    paint.color = const Color(0xFF7C3AED).withOpacity(0.05);
    canvas.drawCircle(Offset(size.width * 0.1, size.height * 0.7), 160, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _AnimatedBrain extends StatefulWidget {
  @override
  State<_AnimatedBrain> createState() => _AnimatedBrainState();
}

class _AnimatedBrainState extends State<_AnimatedBrain>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _ctrl,
      child: Container(
        width: 56, height: 56,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: SweepGradient(
            colors: [Color(0xFF10B981), Colors.transparent],
          ),
        ),
        child: Container(
          margin: const EdgeInsets.all(4),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFF141B2D),
          ),
          child: const Icon(Icons.psychology_rounded,
              color: Color(0xFF10B981), size: 28),
        ),
      ),
    );
  }
}

class _MiniLoader extends StatefulWidget {
  final String label;
  final Color color;
  const _MiniLoader(this.label, this.color);

  @override
  State<_MiniLoader> createState() => _MiniLoaderState();
}

class _MiniLoaderState extends State<_MiniLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 20, height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: widget.color,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          widget.label,
          style: GoogleFonts.inter(
              fontSize: 9, color: widget.color, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
