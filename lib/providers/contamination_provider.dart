import 'package:flutter/foundation.dart';
import 'package:conscious_living/features/restaurant/scan/food_contamination_service.dart';

class ContaminationProvider extends ChangeNotifier {
  final FoodContaminationService _service = FoodContaminationService();

  FoodAnalysisResult? _result;
  bool _isLoading = false;
  String? _error;

  FoodAnalysisResult? get result => _result;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> analyze(Uint8List imageBytes) async {
    _isLoading = true;
    _error = null;
    _result = null;
    notifyListeners();

    try {
      _result = await _service.analyze(imageBytes);
      _isLoading = false;
    } catch (e) {
      _error = 'Analysis failed: $e';
      _isLoading = false;
    }

    notifyListeners();
  }

  void reset() {
    _result = null;
    _error = null;
    _isLoading = false;
    notifyListeners();
  }
}
