import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/api_service.dart';
import '../../../core/constants.dart';

enum _StaffScanMode {
  freshness,
  waste,
  compost,
}

class StaffScanScreen extends StatefulWidget {
  const StaffScanScreen({super.key});

  @override
  State<StaffScanScreen> createState() => _StaffScanScreenState();
}

class _StaffScanScreenState extends State<StaffScanScreen>
    with SingleTickerProviderStateMixin {
  static const _dark = Color(0xFF1A1A1A);

  final _picker = ImagePicker();

  _StaffScanMode _mode = _StaffScanMode.freshness;
  XFile? _selected;
  bool _isAnalysing = false;
  bool _flashOn = false;

  late final AnimationController _dotsController;

  @override
  void initState() {
    super.initState();
    _dotsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _dotsController.dispose();
    super.dispose();
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _pick(ImageSource source) async {
    if (_isAnalysing) return;

    try {
      final file = await _picker.pickImage(source: source, imageQuality: 90);
      if (file == null) return;
      if (!mounted) return;

      setState(() {
        _selected = file;
        _isAnalysing = true;
      });

      final imageFile = File(file.path);
      final Map<String, dynamic> result;
      if (_mode == _StaffScanMode.freshness) {
        result = await ApiService.predictFreshness(imageFile);
      } else if (_mode == _StaffScanMode.waste) {
        result = await ApiService.predictWaste(imageFile);
      } else {
        result = await ApiService.predictCompost(imageFile);
      }

      if (!mounted) return;
      setState(() => _isAnalysing = false);

      context.go(
        AppRoutes.restaurantScanResult,
        extra: <String, dynamic>{
          'result': result,
          'imageFile': imageFile,
          'imagePath': file.path,
          'scanMode': _mode.name,
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isAnalysing = false);
      _snack(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final image = _selected;

    return Scaffold(
      backgroundColor: _dark,
      appBar: AppBar(
        backgroundColor: AppColors.olive,
        foregroundColor: AppColors.butter,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios_new),
          color: AppColors.butter,
        ),
        title: Text(
          'Scan food item',
          style: GoogleFonts.dmSerifDisplay(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.butter,
            height: 1.2,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 22),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 460),
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: _Viewfinder(
                          imagePath: image?.path,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _ModeChip(
                      label: 'Freshness check',
                      selected: _mode == _StaffScanMode.freshness,
                      onTap: () => setState(() => _mode = _StaffScanMode.freshness),
                    ),
                    const SizedBox(width: 10),
                    _ModeChip(
                      label: 'Waste recognition',
                      selected: _mode == _StaffScanMode.waste,
                      onTap: () => setState(() => _mode = _StaffScanMode.waste),
                    ),
                    const SizedBox(width: 10),
                    _ModeChip(
                      label: 'Compost check',
                      selected: _mode == _StaffScanMode.compost,
                      onTap: () => setState(() => _mode = _StaffScanMode.compost),
                    ),
                  ],
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
                decoration: const BoxDecoration(
                  color: _dark,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _CircleIconButton(
                            tooltip: 'Gallery',
                            icon: Icons.photo_library_outlined,
                            onTap: () => _pick(ImageSource.gallery),
                          ),
                          _CaptureButton(
                            onTap: () => _pick(ImageSource.camera),
                          ),
                          _CircleIconButton(
                            tooltip: _flashOn ? 'Flash on' : 'Flash off',
                            icon: _flashOn
                                ? Icons.flash_on_rounded
                                : Icons.flash_off_rounded,
                            onTap: () => setState(() => _flashOn = !_flashOn),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () => _pick(ImageSource.gallery),
                        icon: const Icon(Icons.photo_library_outlined),
                        label: const Text('Upload from gallery'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.butter,
                          side: BorderSide(
                            color: AppColors.butter.withValues(alpha: 0.45),
                            width: 1,
                          ),
                          padding:
                              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadii.input),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: () => context.go(AppRoutes.restaurantExpiryDate),
                        icon: const Icon(Icons.calendar_today_outlined),
                        label: const Text('Check Expiry Date'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.butter,
                          side: BorderSide(
                            color: AppColors.butter.withValues(alpha: 0.45),
                            width: 1,
                          ),
                          padding:
                              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadii.input),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: () => context.go(AppRoutes.restaurantFreshnessCheck),
                        icon: const Icon(Icons.favorite_outline),
                        label: const Text('Freshness Check'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.butter,
                          side: BorderSide(
                            color: AppColors.butter.withValues(alpha: 0.45),
                            width: 1,
                          ),
                          padding:
                              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadii.input),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (_isAnalysing)
            _AnalysingOverlay(
              controller: _dotsController,
            ),
        ],
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ModeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.chip),
      splashColor: AppColors.olive.withValues(alpha: 0.18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.olive
              : AppColors.espresso.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(AppRadii.chip),
          border: Border.all(
            color: selected
                ? AppColors.olive
                : AppColors.butter.withValues(alpha: 0.18),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? AppColors.butter : AppColors.cream,
            height: 1.2,
          ),
        ),
      ),
    );
  }
}

class _CaptureButton extends StatelessWidget {
  final VoidCallback onTap;

  const _CaptureButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 64,
        height: 64,
        decoration: const BoxDecoration(
          color: AppColors.butter,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Container(
          width: 50,
          height: 50,
          decoration: const BoxDecoration(
            color: AppColors.olive,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.camera_alt, color: AppColors.butter),
        ),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;

  const _CircleIconButton({
    required this.icon,
    required this.onTap,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.espresso.withValues(alpha: 0.35),
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.butter.withValues(alpha: 0.18),
              width: 1,
            ),
          ),
          child: Icon(icon, color: AppColors.butter),
        ),
      ),
    );
  }
}

class _Viewfinder extends StatelessWidget {
  final String? imagePath;

  const _Viewfinder({required this.imagePath});

  @override
  Widget build(BuildContext context) {
    final path = imagePath;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadii.screenCard),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            color: Colors.black,
            alignment: Alignment.center,
            child: path == null
                ? const Icon(
                    Icons.document_scanner_outlined,
                    size: 64,
                    color: AppColors.butter,
                  )
                : Hero(
                    tag: 'scan_image',
                    child: Image.file(
                      File(path),
                      fit: BoxFit.cover,
                    ),
                  ),
          ),
          Positioned.fill(
            child: CustomPaint(
              painter: _ViewfinderPainter(),
            ),
          ),
        ],
      ),
    );
  }
}

class _ViewfinderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(20));

    final dashedPaint = Paint()
      ..color = AppColors.butter.withValues(alpha: 0.65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final path = Path()..addRRect(rrect);
    const dash = 10.0;
    const gap = 8.0;
    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final next = distance + dash;
        canvas.drawPath(
          metric.extractPath(distance, next.clamp(0, metric.length)),
          dashedPaint,
        );
        distance = next + gap;
      }
    }

    final cornerPaint = Paint()
      ..color = AppColors.oliveMist.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    const inset = 14.0;
    const len = 22.0;
    final left = rect.left + inset;
    final top = rect.top + inset;
    final right = rect.right - inset;
    final bottom = rect.bottom - inset;

    // top-left
    canvas.drawLine(Offset(left, top), Offset(left + len, top), cornerPaint);
    canvas.drawLine(Offset(left, top), Offset(left, top + len), cornerPaint);
    // top-right
    canvas.drawLine(Offset(right, top), Offset(right - len, top), cornerPaint);
    canvas.drawLine(Offset(right, top), Offset(right, top + len), cornerPaint);
    // bottom-left
    canvas.drawLine(
        Offset(left, bottom), Offset(left + len, bottom), cornerPaint);
    canvas.drawLine(
        Offset(left, bottom), Offset(left, bottom - len), cornerPaint);
    // bottom-right
    canvas.drawLine(
        Offset(right, bottom), Offset(right - len, bottom), cornerPaint);
    canvas.drawLine(
        Offset(right, bottom), Offset(right, bottom - len), cornerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _AnalysingOverlay extends StatelessWidget {
  final Animation<double> controller;

  const _AnalysingOverlay({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.62),
      child: Center(
        child: Container(
          width: 260,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.parchment,
            borderRadius: BorderRadius.circular(AppRadii.screenCard),
            border: Border.all(color: AppColors.sand, width: 0.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Analysing food item…',
                style: GoogleFonts.dmSerifDisplay(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.espresso,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 10),
              _Dots(controller: controller),
              const SizedBox(height: 8),
              Text(
                'Hold still for best results.',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: AppColors.cocoa,
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

class _Dots extends StatelessWidget {
  final Animation<double> controller;

  const _Dots({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final t = controller.value;

        double dotOpacity(int i) {
          final phase = (t * 3 - i) % 3;
          final v = 1.0 - (phase - 1.0).abs();
          return (0.25 + (v * 0.75)).clamp(0.25, 1.0);
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (int i = 0; i < 3; i++)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: AppColors.olive.withValues(alpha: dotOpacity(i)),
                  shape: BoxShape.circle,
                ),
              ),
          ],
        );
      },
    );
  }
}
