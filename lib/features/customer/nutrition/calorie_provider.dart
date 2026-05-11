// lib/features/customer/nutrition/calorie_provider.dart
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/foundation.dart';
import 'calorie_inference_service.dart';

enum CalorieStatus { idle, loading, success, error }

class CalorieProvider extends ChangeNotifier {
  final _svc = CalorieInferenceService();

  CalorieStatus   _status  = CalorieStatus.idle;
  NutritionResult? _result;
  String          _error   = '';
  bool            _apiReady = false;

  CalorieStatus    get status   => _status;
  NutritionResult? get result   => _result;
  String           get error    => _error;
  bool             get apiReady => _apiReady;

  /// Warm up the API by sending a health check.
  Future<void> warmUpApi() async {
    _apiReady = await _svc.init();
    notifyListeners();
  }

  /// Predict from RGB bytes only (depth = grey fallback on server).
  Future<void> predict(Uint8List imageBytes) async {
    _status = CalorieStatus.loading;
    _error  = '';
    notifyListeners();

    try {
      _result = await _svc.predict(imageBytes);
      _status = CalorieStatus.success;
    } on NutritionApiException catch (e) {
      _error  = e.message;
      _status = CalorieStatus.error;
    } catch (e) {
      _error  = 'Unexpected error: $e';
      _status = CalorieStatus.error;
    }
    notifyListeners();
  }

  /// Predict from RGB + depth bytes.
  Future<void> predictWithDepth(
      Uint8List imageBytes, Uint8List depthBytes) async {
    _status = CalorieStatus.loading;
    _error  = '';
    notifyListeners();

    try {
      _result = await _svc.predictWithDepth(imageBytes, depthBytes);
      _status = CalorieStatus.success;
    } on NutritionApiException catch (e) {
      _error  = e.message;
      _status = CalorieStatus.error;
    } catch (e) {
      _error  = 'Unexpected error: $e';
      _status = CalorieStatus.error;
    }
    notifyListeners();
  }

  void reset() {
    _status = CalorieStatus.idle;
    _result = null;
    _error  = '';
    notifyListeners();
  }
}
