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

const kOat = Color(0xFFF4FAF7);
const kParchment = Color(0xFFFFFFFF);
const kSand = Color(0xFFDFF2E9);
const kCherry = Color(0xFF7DC5A0);
const kCherryMid = Color(0xFF4A8A6A);
const kCherryB = Color(0xFFDFF2E9);
const kButterD = Color(0xFFFFAB5B);
const kOlive = Color(0xFF52C98A);
const kEspresso = Color(0xFF0D2E1E);
const kCocoa = Color(0xFF3A6A52);
const kFog = Color(0xFF7AAA90);
const kViewfinderHotel = Color(0xFFDFF2E9);

class HotelScanScreen extends StatefulWidget {
  const HotelScanScreen({super.key});

  @override
  State<HotelScanScreen> createState() => _HotelScanScreenState();
}

class _HotelScanScreenState extends State<HotelScanScreen>
    with TickerProviderStateMixin {
  final _picker = ImagePicker();
  final _compostService = CompostInferenceService();
  final _wasteService = WastePipelineService(
    baseUrl: ApiConfig.wastePipelineApi,
  );
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
        source: source,
        imageQuality: 90,
        maxWidth: 1440,
      );
      if (file == null || !mounted) return;

      setState(() {
        _lastFile    = file;
        _isAnalysing = true;
        _step = 'Preparing image...';
      });

      final imageBytes = await file.readAsBytes();

      // ── Run 4 models in parallel ─────────────────────────────────────
      setState(() => _step = 'Running 4 AI checks in parallel...');

      final futures = await Future.wait<dynamic>([
        // 1. Compost segmentation
        _compostService.classify(imageBytes).then((r) => r.toMap()).catchError((
          e,
        ) {
          debugPrint('[Hotel Scan] Compost API error: $e');
          return <String, dynamic>{
            'compostablePct': 0.0,
            'nonCompostablePct': 0.0,
            'backgroundPct': 100.0,
            'inferenceTimeMs': 0,
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
            final streamed = await request.send().timeout(
              const Duration(seconds: 60),
            );
            final response = await http.Response.fromStream(streamed);
            if (response.statusCode == 200) {
              return jsonDecode(response.body) as Map<String, dynamic>;
            } else {
              debugPrint(
                '[Hotel Scan] Freshness API error: ${response.statusCode}',
              );
              return <String, dynamic>{
                'status': 'unknown',
                'confidence': 0.0,
                'label': 'Not detected',
              };
            }
          } catch (e) {
            debugPrint('[Hotel Scan] Freshness error: $e');
            return <String, dynamic>{
              'status': 'unknown',
              'confidence': 0.0,
              'label': 'Not detected',
            };
          }
        }(),

        // 3. Waste pipeline API
        _wasteService
            .analyze(imageBytes)
            .then((result) {
              final payload = result.toJson();
              payload['detectedItems'] = result.massEstimates
                  .map((e) => {'name': e.label, 'quantityKg': e.estimatedKg})
                  .toList(growable: false);
              return payload;
            })
            .catchError((e) {
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kOat,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                color: kParchment,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: kSand),
              ),
              child: Icon(Icons.arrow_back_ios_new, color: kFog, size: 16),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Smart Scan',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: kEspresso,
                  ),
                ),
                Text(
                  'Freshness · Waste · Compost · Contamination in parallel',
                  style: GoogleFonts.inter(fontSize: 11, color: kFog),
                ),
              ],
            ),
          ),
          // Cherry-red hotel brand badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [kCherry, kCherryMid]),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'AI',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Viewfinder ─────────────────────────────────────────────────────────────
  Widget _buildViewfinder() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: AspectRatio(
        aspectRatio: 1,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              ColoredBox(
                color: kViewfinderHotel,
                child: _lastFile != null && !kIsWeb
                    ? Image.file(
                        File(_lastFile!.path),
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      )
                    : Center(
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
                                color: Colors.white.withValues(alpha: 0.16),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'Prenez une photo\nou importez depuis la galerie',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: Colors.white70,
                                height: 1.6,
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
              ..._cornerBrackets(kCherry),
              if (!_isAnalysing)
                Positioned.fill(
                  child: LayoutBuilder(
                    builder: (_, box) {
                      return AnimatedBuilder(
                        animation: _scanLine,
                        builder: (_, _) {
                          final maxTop = (box.maxHeight - 24).clamp(
                            0.0,
                            double.infinity,
                          );
                          return Transform.translate(
                            offset: Offset(0, _scanLine.value * maxTop),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              child: Align(
                                alignment: Alignment.topCenter,
                                child: Container(
                                  height: 2,
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.transparent,
                                        kCherry,
                                        Colors.transparent,
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              Positioned(bottom: 14, left: 14, child: _buildAiLabels()),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _cornerBrackets(Color c) {
    const o = 14.0;
    const len = 28.0;
    const w = 3.0;
    final bs = BorderSide(color: c, width: w);
    return [
      Positioned(
        top: o,
        left: o,
        child: Container(
          width: len,
          height: len,
          decoration: BoxDecoration(
            border: Border(left: bs, top: bs),
          ),
        ),
      ),
      Positioned(
        top: o,
        right: o,
        child: Container(
          width: len,
          height: len,
          decoration: BoxDecoration(
            border: Border(right: bs, top: bs),
          ),
        ),
      ),
      Positioned(
        bottom: o,
        left: o,
        child: Container(
          width: len,
          height: len,
          decoration: BoxDecoration(
            border: Border(left: bs, bottom: bs),
          ),
        ),
      ),
      Positioned(
        bottom: o,
        right: o,
        child: Container(
          width: len,
          height: len,
          decoration: BoxDecoration(
            border: Border(right: bs, bottom: bs),
          ),
        ),
      ),
    ];
  }

  Widget _buildAiLabels() {
    return Wrap(
      spacing: 6,
      children: [
        _aiChip('Freshness', kCherry),
        _aiChip('Waste', kButterD),
        _aiChip('🌱 Compost', kOlive),
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
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }

  // ── Capture dock ───────────────────────────────────────────────────────────
  Widget _buildCaptureDock() {
    return Container(
      decoration: BoxDecoration(
        color: kParchment,
        border: Border(top: BorderSide(color: kSand)),
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
                _hotelModeChip(
                  Icons.thermostat_rounded,
                  'Freshness',
                  active: true,
                ),
                const SizedBox(width: 8),
                _hotelModeChip(
                  Icons.event_available_rounded,
                  'Expiry',
                  active: false,
                ),
                const SizedBox(width: 8),
                _hotelModeChip(Icons.delete_rounded, 'Waste', active: false),
                const SizedBox(width: 8),
                _hotelModeChip(Icons.eco_rounded, 'Compost', active: false),
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
                  icon: Icons.event_available_rounded,
                  label: 'Expiry',
                  onTap: () => context.go(AppRoutes.hotelExpiryDate),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _hotelModeChip(IconData icon, String label, {required bool active}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: active ? kCherry : kCherryB.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: kCherry.withValues(alpha: active ? 0.55 : 0.35),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: active ? Colors.white : kCherry),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: active ? Colors.white : kCherry,
            ),
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
              color: kCherry.withValues(alpha: 0.5 + _pulse.value * 0.3),
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: kCherry.withValues(alpha: 0.2 + _pulse.value * 0.15),
                blurRadius: 20 + _pulse.value * 10,
              ),
            ],
          ),
          child: child,
        ),
        child: Container(
          margin: const EdgeInsets.all(6),
          decoration: BoxDecoration(shape: BoxShape.circle, color: kCherry),
          child: const Icon(
            Icons.camera_alt_rounded,
            color: Colors.white,
            size: 30,
          ),
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
          Icon(icon, color: kFog, size: 28),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              color: kFog,
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
      color: kEspresso.withValues(alpha: 0.35),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 40),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: kParchment,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: kSand),
            boxShadow: [
              BoxShadow(
                color: kEspresso.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _AnimatedBrain(),
              const SizedBox(height: 20),
              Text(
                'AI analysis in progress',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: kEspresso,
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
                    color: kCocoa,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _MiniLoader('Freshness', kCherry),
                  const SizedBox(width: 16),
                  _MiniLoader('Waste', kButterD),
                  const SizedBox(width: 16),
                  _MiniLoader('Compost', kOlive),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
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
          gradient: SweepGradient(colors: [kCherry, Colors.transparent]),
        ),
        child: Container(
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: kParchment,
          ),
          child: Icon(Icons.psychology_rounded, color: kCherry, size: 28),
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
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}