import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../core/constants.dart';
import '../../../providers/contamination_provider.dart';
import '../../restaurant/scan/food_contamination_service.dart';

class HotelContaminationScanScreen extends StatefulWidget {
  const HotelContaminationScanScreen({super.key});

  @override
  State<HotelContaminationScanScreen> createState() =>
      _HotelContaminationScanScreenState();
}

class _HotelContaminationScanScreenState extends State<HotelContaminationScanScreen>
    with TickerProviderStateMixin {
  static const _dark = Color(0xFF0A0F1E);
  static const _card = Color(0xFF141B2D);
  static const _hotelCherry = Color(0xFF75070C);

  final _picker = ImagePicker();
  XFile? _lastFile;

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
  }

  @override
  void dispose() {
    _scanLine.dispose();
    _pulse.dispose();
    super.dispose();
  }

  Future<void> _pick(ImageSource source) async {
    final provider = context.read<ContaminationProvider>();
    if (provider.isLoading) return;

    HapticFeedback.mediumImpact();

    try {
      final file = await _picker.pickImage(
          source: source, imageQuality: 90, maxWidth: 1440);
      if (file == null || !mounted) return;

      setState(() => _lastFile = file);

      final imageBytes = await file.readAsBytes();

      // Call the provider's analyze method
      await provider.analyze(imageBytes);

      if (!mounted) return;

      // Check if there was an error
      if (provider.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(provider.error!)),
        );
        return;
      }

      // Navigate to result screen with the result
      if (provider.result != null) {
        context.push(
          AppRoutes.hotelContaminationResult,
          extra: ContaminationScanResultPayload(
            result: provider.result!,
            imageBytes: imageBytes,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

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
          Consumer<ContaminationProvider>(
            builder: (_, provider, __) =>
                provider.isLoading ? _buildAnalysingOverlay() : const SizedBox(),
          ),
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
              width: 38,
              height: 38,
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
                  'Hotel Food Scan',
                  style: GoogleFonts.sora(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Detect food contamination & insects',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.55),
                  ),
                ),
              ],
            ),
          ),
          // AI badge with hotel color
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: [_hotelCherry, const Color(0xFF5A0508)]),
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
                                'Take a photo\nor import from gallery',
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
              // Animated scan line
              AnimatedBuilder(
                animation: _scanLine,
                builder: (_, _) {
                  final t = _scanLine.value;
                  return Positioned(
                    top: t * 240,
                    left: 24,
                    right: 24,
                    child: Container(
                      height: 2,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            _hotelCherry,
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              // AI label
              Positioned(
                bottom: 14,
                left: 14,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _hotelCherry.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '🦠 Contamination',
                    style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
            Text(
              'Contamination Detection',
              style: GoogleFonts.sora(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _sideButton(
                  icon: Icons.photo_library_outlined,
                  label: 'Gallery',
                  onTap: () => _pick(ImageSource.gallery),
                ),
                _captureButton(),
                _sideButton(
                  icon: Icons.info_outline,
                  label: 'Info',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            'Scan food to detect contamination and insects'),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
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
              color: _hotelCherry
                  .withValues(alpha: 0.5 + _pulse.value * 0.3),
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: _hotelCherry
                    .withValues(alpha: 0.2 + _pulse.value * 0.15),
                blurRadius: 20 + _pulse.value * 10,
              ),
            ],
          ),
          child: child,
        ),
        child: Container(
          margin: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [_hotelCherry, const Color(0xFF5A0508)],
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
            width: 52,
            height: 52,
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
            border:
                Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 60,
                height: 60,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _hotelCherry.withValues(alpha: 0.8),
                  ),
                  strokeWidth: 3,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Analyzing...',
                style: GoogleFonts.sora(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Scanning for contamination & insects',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.55),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Background ────────────────────────────────────────────────────────────────────
class _Background extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0A0F1E), Color(0xFF141B2D)],
        ),
      ),
    );
  }
}
