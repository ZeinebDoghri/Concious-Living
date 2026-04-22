import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/api_service.dart';
import '../../../core/constants.dart';
import '../../../shared/widgets/animated_button.dart';
import '../../../shared/widgets/cherry_header.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen>
    with SingleTickerProviderStateMixin {
  final _picker = ImagePicker();

  XFile? _selected;
  bool _isAnalysing = false;

  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
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

      final result = await ApiService.predictNutrients(File(file.path));
      if (!mounted) return;

      setState(() => _isAnalysing = false);

      context.go(
        AppRoutes.customerResult,
        extra: <String, dynamic>{
          'dishName': 'Dish',
          'imagePath': file.path,
          'result': result.toJson(),
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
      backgroundColor: AppColors.oat,
      body: SafeArea(
        child: Column(
          children: [
            CherryHeader(
              title: AppStrings.scanYourDish,
              subtitle: AppStrings.centerDishHint,
              showBack: false,
            ),
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
                child: Stack(
                  children: [
                    SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppStrings.takePhotoOrUpload,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                              color: AppColors.cocoa,
                              height: 1.6,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _PreviewFrame(
                            imagePath: image?.path,
                            pulse: _pulseController,
                          ),
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              Expanded(
                                child: AnimatedButton(
                                  label: AppStrings.scanYourDish,
                                  color: AppColors.cherry,
                                  textColor: AppColors.butter,
                                  onTap: () => _pick(ImageSource.camera),
                                  height: 52,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: () => _pick(ImageSource.gallery),
                            icon: const Icon(Icons.photo_library_outlined),
                            label: Text(AppStrings.uploadFromGallery),
                          ),
                        ],
                      ),
                    ),
                    if (_isAnalysing)
                      _AnalysingOverlay(
                        pulse: _pulseController,
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

class _PreviewFrame extends StatelessWidget {
  final String? imagePath;
  final Animation<double> pulse;

  const _PreviewFrame({
    required this.imagePath,
    required this.pulse,
  });

  @override
  Widget build(BuildContext context) {
    final path = imagePath;

    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.oat,
          borderRadius: BorderRadius.circular(AppRadii.screenCard),
          border: Border.all(color: AppColors.sand, width: 1),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadii.screenCard),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (path != null)
                Image.file(
                  File(path),
                  fit: BoxFit.cover,
                )
              else
                Container(
                  color: AppColors.oat,
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.camera_alt_outlined,
                    size: 56,
                    color: AppColors.cocoa,
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(18),
                child: AnimatedBuilder(
                  animation: pulse,
                  builder: (context, _) {
                    final v = (0.35 + (pulse.value * 0.35)).clamp(0.0, 1.0);
                    return Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppRadii.innerCard),
                        border: Border.all(
                          color: AppColors.butter.withValues(alpha: v),
                          width: 2,
                        ),
                      ),
                    );
                  },
                ),
              ),
              Align(
                alignment: Alignment.topCenter,
                child: Container(
                  margin: const EdgeInsets.only(top: 14),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.espresso.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(AppRadii.badge),
                  ),
                  child: Text(
                    AppStrings.centerDishHint,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.cream,
                      height: 1.2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnalysingOverlay extends StatelessWidget {
  final Animation<double> pulse;

  const _AnalysingOverlay({required this.pulse});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.espresso.withValues(alpha: 0.45),
      child: Center(
        child: AnimatedBuilder(
          animation: pulse,
          builder: (context, _) {
            final scale = 0.95 + (pulse.value * 0.03);
            return Transform.scale(
              scale: scale,
              child: Container(
                width: 240,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.parchment,
                  borderRadius: BorderRadius.circular(AppRadii.screenCard),
                  border: Border.all(color: AppColors.sand, width: 0.5),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 4),
                    const CircularProgressIndicator(
                      color: AppColors.cherry,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      AppStrings.analysingDish,
                      style: GoogleFonts.dmSerifDisplay(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.espresso,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      AppStrings.takePhotoOrUpload,
                      textAlign: TextAlign.center,
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
            );
          },
        ),
      ),
    );
  }
}
