import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/api_service.dart';
import '../../../core/constants.dart';
import '../../../core/models/nutrient_result.dart';
import '../../../shared/widgets/role_scan_experience.dart';
import '../allergens/allergy_service.dart';
import '../nutrition/calorie_inference_service.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final _picker = ImagePicker();

  XFile? _selected;
  Uint8List? _selectedBytes;
  bool _isAnalysing = false;
  String? _calorieError;

  void _snack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _pick(ImageSource source) async {
    if (_isAnalysing) return;

    try {
      final file = await _picker.pickImage(source: source, imageQuality: 90);
      if (file == null) return;

      final imageBytes = await file.readAsBytes();
      if (!mounted) return;

      setState(() {
        _selected = file;
        _selectedBytes = imageBytes;
        _isAnalysing = true;
        _calorieError = null;
      });

      final allergyFuture = AllergyService()
          .detectAllergens(
            imageBytes: imageBytes,
            filename: file.name.isEmpty ? 'image.jpg' : file.name,
          )
          .then<AllergyResult?>((result) => result)
          .catchError((e) {
            debugPrint('[CustomerScan] Allergy model error: $e');
            return null;
          });

      final results = await Future.wait<dynamic>([
        ApiService.predictNutrients(imageBytes),
        allergyFuture,
        CalorieInferenceService()
            .predict(imageBytes)
            .then<NutritionResult?>((result) => result)
            .catchError((e) {
              _calorieError = e.toString();
              debugPrint('[CustomerScan] Calorie model error: $e');
              return null;
            }),
      ]);

      final result = results[0] as NutrientResult;
      final allergyResult = results[1] as AllergyResult?;
      final calorieResult = results[2] as NutritionResult?;
      if (!mounted) return;

      setState(() => _isAnalysing = false);

      context.go(
        AppRoutes.customerResult,
        extra: <String, dynamic>{
          'dishName': 'Dish',
          'imagePath': file.path,
          'imageBytes': imageBytes,
          'allergyResult': allergyResult?.toJson(),
          'calorieResult': calorieResult?.toJson(),
          'calorieError': _calorieError,
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
    return RoleScanExperience(
      role: ScanExperienceRole.customer,
      title: 'Food Label Scan',
      subtitle: 'Nutrition and allergen detection',
      hint: 'Point at a food label...',
      liveTitle: 'Nutrition scan',
      liveSubtitle: 'Calories, allergens, and chronic risk',
      imagePath: _selected?.path,
      imageBytes: _selectedBytes,
      isLoading: _isAnalysing,
      onBack: () =>
          context.canPop() ? context.pop() : context.go(AppRoutes.customerHome),
      onCameraTap: () => _pick(ImageSource.camera),
      onGalleryTap: () => _pick(ImageSource.gallery),
      onInfoTap: () => _snack('Scan a clear food label or meal photo.'),
    );
  }
}
