import 'dart:io';
import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../../../core/api_config.dart';
import '../../../core/constants.dart';
import '../../restaurant/scan/food_contamination_service.dart';
import '../../restaurant/waste/compost_inference_service.dart';
import '../../restaurant/waste/waste_pipeline_service.dart';

// ── Hotel brand palette ────────────────────────────────────────────────────────
const _kCherry     = Color(0xFF75070C); // hotel cherry red (kept as brand accent)
const _bg          = Color(0xFFF5EFE6); // warm cream background
const _card        = Color(0xFFFFFFFF); // white cards
const _cardSoft    = Color(0xFFFAF6F0); // off-white secondary surface
const _header      = Color(0xFF1A3C34); // dark teal header (matches dashboard)
const _textDark    = Color(0xFF1C1C1E);
const _textMid     = Color(0xFF6B7280);
const _textSoft    = Color(0xFF9CA3AF);
const _accentAmber = Color(0xFFD97706);
const _accentGreen = Color(0xFF2D7A5F);

class HotelScanScreen extends StatefulWidget {
  const HotelScanScreen({super.key});

  @override
  State<HotelScanScreen> createState() => _HotelScanScreenState();
}

class _HotelScanScreenState extends State<HotelScanScreen>
    with TickerProviderStateMixin {
  final _picker               = ImagePicker();
  final _compostService       = CompostInferenceService();
  final _wasteService         = WastePipelineService(baseUrl: ApiConfig.wastePipelineApi);
  final _contaminationService = FoodContaminationService();

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

    _compostService.init();
    _contaminationService.init();
  }

  @override
  void dispose() {
    _scanLine.dispose();
    _pulse.dispose();
    _compostService.dispose();
    _wasteService.dispose();
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

      final imageBytes = await file.readAsBytes();

      setState(() => _step = '4 analyses IA en parallèle…');

      final futures = await Future.wait<dynamic>([
        // 1. Compost segmentation
        _compostService
            .classify(imageBytes)
            .then((r) => r.toMap())
            .catchError((e) {
              debugPrint('[Hotel Scan] Compost API error: $e');
              return <String, dynamic>{
                'compostablePct':    0.0,
                'nonCompostablePct': 0.0,
                'backgroundPct':     100.0,
                'inferenceTimeMs':   0,
              };
            }),

        // 2. Freshness HuggingFace API
        () async {
          try {
            final request = http.MultipartRequest(
              'POST',
              Uri.parse('https://jawher0000-freshness-check.hf.space/predict'),
            );
            request.files.add(
              http.MultipartFile.fromBytes(
                'image',
                imageBytes,
                filename: file.path.split('/').last,
              ),
            );
            final streamed =
                await request.send().timeout(const Duration(seconds: 60));
            final response = await http.Response.fromStream(streamed);
            if (response.statusCode == 200) {
              return jsonDecode(response.body) as Map<String, dynamic>;
            } else {
              debugPrint('[Hotel Scan] Freshness API error: ${response.statusCode}');
              return <String, dynamic>{
                'status': 'unknown',
                'confidence': 0.0,
                'label': 'Non détecté',
              };
            }
          } catch (e) {
            debugPrint('[Hotel Scan] Freshness error: $e');
            return <String, dynamic>{
              'status': 'unknown',
              'confidence': 0.0,
              'label': 'Non détecté',
            };
          }
        }(),

        // 3. Waste pipeline API
        _wasteService.analyze(imageBytes).then((result) {
          final payload = result.toJson();
          payload['detectedItems'] = result.massEstimates
              .map((e) => {
                    'name': e.label,
                    'quantityKg': e.estimatedKg,
                  })
              .toList(growable: false);
          return payload;
        }).catchError((e) {
          debugPrint('[Hotel Scan] Waste pipeline error: $e');
          return <String, dynamic>{'detectedItems': [], 'confidence': 0.0};
        }),

        // 4. Food contamination YOLO model
        _contaminationService
            .analyze(imageBytes)
            .then((result) => result.toJson())
            .catchError((e) {
              debugPrint('[Hotel Scan] Contamination API error: $e');
              return <String, dynamic>{
                'label': 'clean',
                'confidence': 0.0,
                'clean_pct': 100.0,
                'contaminated_pct': 0.0,
                'yolo_overrode': false,
                'detections': const [],
                'detection_count': 0,
              };
            }),
      ]);

      if (!mounted) return;
      setState(() => _isAnalysing = false);

      context.go(
        AppRoutes.hotelScanResult,
        extra: <String, dynamic>{
          'imagePath':           file.path,
          'imageBytes':          imageBytes,
          'compostResult':       futures[0] as Map<String, dynamic>,
          'freshnessResult':     futures[1] as Map<String, dynamic>,
          'wasteResult':         futures[2] as Map<String, dynamic>,
          'contaminationResult': futures[3] as Map<String, dynamic>,
          'isFusion':            true,
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
      backgroundColor: _bg,
      body: Stack(
        children: [
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

  // ── Header ─────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        color: _header,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
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
                  'Fraîcheur · Gaspillage · Compost · Insectes — en parallèle',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.65),
                  ),
                ),
              ],
            ),
          ),
          // Cherry-red hotel brand badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _kCherry,
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

  // ── Viewfinder ─────────────────────────────────────────────────────────────
  Widget _buildViewfinder() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: AspectRatio(
          aspectRatio: 1,
          child: Stack(
            children: [
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
                        decoration: BoxDecoration(
                          color: _card,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: const Color(0xFFE5DDD4),
                            width: 1.5,
                          ),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AnimatedBuilder(
                                animation: _pulse,
                                builder: (_, child) => Transform.scale(
                                  scale: 1.0 + _pulse.value * 0.06,
                                  child: child,
                                ),
                                child: Container(
                                  width: 80, height: 80,
                                  decoration: BoxDecoration(
                                    color: _kCherry.withValues(alpha: 0.08),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.document_scanner_rounded,
                                    size: 38,
                                    color: _kCherry.withValues(alpha: 0.60),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Prenez une photo',
                                style: GoogleFonts.sora(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: _textDark,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'ou importez depuis la galerie',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: _textMid,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
              ),
              // Animated scan line — cherry red accent
              if (!_isAnalysing)
                LayoutBuilder(
                  builder: (context, constraints) {
                    return AnimatedBuilder(
                      animation: _scanLine,
                      builder: (_, __) {
                        return Positioned(
                          top: _scanLine.value * (constraints.maxHeight - 4),
                          left: 20, right: 20,
                          child: Container(
                            height: 2,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.transparent,
                                  _kCherry.withValues(alpha: 0.65),
                                  Colors.transparent,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
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
        _aiChip('🌡️ Fraîcheur', _kCherry),
        _aiChip('🗑️ Gaspillage', _accentAmber),
        _aiChip('🌱 Compost', _accentGreen),
      ],
    );
  }

  Widget _aiChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 6, offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
            fontSize: 10, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }

  // ── Capture dock ───────────────────────────────────────────────────────────
  Widget _buildCaptureDock() {
    return Container(
      decoration: const BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFDDD6CC),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _modeIndicator(Icons.thermostat_rounded, 'Freshness', _kCherry),
                const SizedBox(width: 8),
                _modeIndicator(Icons.delete_rounded,     'Waste',     _accentAmber),
                const SizedBox(width: 8),
                _modeIndicator(Icons.eco_rounded,        'Compost',   _accentGreen),
              ],
            ),
            const SizedBox(height: 20),
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
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _modeIndicator(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
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
          width: 76, height: 76,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: _kCherry.withValues(alpha: 0.4 + _pulse.value * 0.25),
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: _kCherry.withValues(alpha: 0.15 + _pulse.value * 0.10),
                blurRadius: 18 + _pulse.value * 8,
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
              colors: [Color(0xFF9B0C12), _kCherry],
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
              color: _cardSoft,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFDDD6CC)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 6, offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, color: _textMid, size: 22),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              color: _textSoft,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ── Analysing overlay ──────────────────────────────────────────────────────
  Widget _buildAnalysingOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.45),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 40),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 30,
                offset: const Offset(0, 8),
              ),
            ],
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
                  color: _textDark,
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
                    color: _textMid,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _MiniLoader('Freshness', _kCherry),
                  const SizedBox(width: 16),
                  _MiniLoader('Waste',     _accentAmber),
                  const SizedBox(width: 16),
                  _MiniLoader('Compost',   _accentGreen),
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
        width: 56, height: 56,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: SweepGradient(
            colors: [_kCherry, Colors.transparent],
          ),
        ),
        child: Container(
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: _kCherry.withValues(alpha: 0.15),
                blurRadius: 8,
              ),
            ],
          ),
          child: const Icon(Icons.psychology_rounded,
              color: _kCherry, size: 28),
        ),
      ),
    );
  }
}

class _MiniLoader extends StatefulWidget {
  final String label;
  final Color  color;
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
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

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
              fontSize: 9,
              color: widget.color,
              fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}