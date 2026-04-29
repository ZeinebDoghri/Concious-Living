import 'dart:io';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class TFLitePrediction {
  final String className;
  final double confidence;
  final int classIndex;

  const TFLitePrediction({
    required this.className,
    required this.confidence,
    required this.classIndex,
  });
}

class TFLiteService {
  static final TFLiteService _instance = TFLiteService._internal();
  late Interpreter _interpreter;
  bool _isInitialized = false;

  static const List<String> _classNames = [
    'apple_pie', 'baby_back_ribs', 'baklava', 'beef_carpaccio', 'beef_tartare',
    'beet_salad', 'beignets', 'bibimbap', 'bread_pudding', 'breakfast_burrito',
    'bruschetta', 'caesar_salad', 'cannoli', 'caprese_salad', 'carrot_cake',
    'ceviche', 'cheese_plate', 'cheesecake', 'chicken_curry', 'chicken_quesadilla',
    'chicken_wings', 'chocolate_cake', 'chocolate_mousse', 'churros', 'clam_chowder',
    'club_sandwich', 'crab_cakes', 'creme_brulee', 'croque_madame', 'cup_cakes',
    'deviled_eggs', 'donuts', 'dumplings', 'edamame', 'eggs_benedict',
    'escargots', 'falafel', 'filet_mignon', 'fish_and_chips', 'foie_gras',
    'french_fries', 'french_onion_soup', 'french_toast', 'fried_calamari', 'fried_rice',
    'frozen_yogurt', 'garlic_bread', 'gnocchi', 'greek_salad', 'grilled_cheese_sandwich',
    'grilled_salmon', 'guacamole', 'gyoza', 'hamburger', 'hot_and_sour_soup',
    'hot_dog', 'huevos_rancheros', 'hummus', 'ice_cream', 'lasagna',
    'lobster_bisque', 'lobster_roll_sandwich', 'macaroni_and_cheese', 'macarons', 'miso_soup',
    'mussels', 'nachos', 'omelette', 'onion_rings', 'oysters',
    'pad_thai', 'paella', 'pancakes', 'panna_cotta', 'peking_duck',
    'pho', 'pizza', 'pork_chop', 'poutine', 'prime_rib',
    'pulled_pork_sandwich', 'ramen', 'ravioli', 'red_velvet_cake', 'risotto',
    'samosa', 'sashimi', 'scallops', 'seaweed_salad', 'shrimp_and_grits',
    'spaghetti_bolognese', 'spaghetti_carbonara', 'spring_rolls', 'steak', 'strawberry_shortcake',
    'sushi', 'tacos', 'takoyaki', 'tiramisu', 'tuna_tartare',
    'waffles',
  ];

  TFLiteService._internal();

  factory TFLiteService() {
    return _instance;
  }

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      const platform = MethodChannel('com.conscious_living/tflite');
      final String modelPath = await platform.invokeMethod('getModelPath');
      _interpreter = await Interpreter.fromAsset(modelPath);
      _isInitialized = true;
    } catch (e) {
      throw Exception('Failed to load TFLite model: $e');
    }
  }

  Future<TFLitePrediction?> predict(File imageFile) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      final imageData = imageFile.readAsBytesSync();
      final input = _preprocessImage(imageData);
      final output = List<double>.filled(101, 0.0);

      _interpreter.run(input, output);

      int maxIndex = 0;
      double maxConfidence = output[0];

      for (int i = 1; i < output.length; i++) {
        if (output[i] > maxConfidence) {
          maxConfidence = output[i];
          maxIndex = i;
        }
      }

      final confidence = (maxConfidence * 100).clamp(0.0, 100.0);

      return TFLitePrediction(
        className: _classNames[maxIndex],
        confidence: confidence,
        classIndex: maxIndex,
      );
    } catch (e) {
      return null;
    }
  }

  List<List<List<List<double>>>> _preprocessImage(List<int> imageBytes) {
    const int imageSize = 224;
    const int channels = 3;

    final List<List<List<List<double>>>> input =
        List.generate(1, (_) => List.generate(imageSize, (_) => List.generate(imageSize, (_) => List.filled(channels, 0.0))));

    for (int i = 0; i < imageSize; i++) {
      for (int j = 0; j < imageSize; j++) {
        for (int c = 0; c < channels; c++) {
          final byte = imageBytes.isNotEmpty ? imageBytes[0] : 0;
          input[0][i][j][c] = byte / 255.0;
        }
      }
    }

    return input;
  }

  void dispose() {
    if (_isInitialized) {
      _interpreter.close();
      _isInitialized = false;
    }
  }
}
