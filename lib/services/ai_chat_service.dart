import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../config/api_keys.dart';

class AIChatService {
  static const List<String> _modelFallbacks = [
    'gemini-1.5-flash',
    'gemini-1.5-pro',
    'gemini-2.0-flash',
  ];

  static Future<String> askNora({
    required String uid,
    required String userMessage,
    required List<Map<String, String>> history,
  }) async {
    var ctx = '''
You are Nora, an expert AI nutritionist in the FreshGuard app.
You are warm, precise, and health-focused. Answer in the same language the user writes in.
''';

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      final todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final logDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('daily_logs')
          .doc(todayKey)
          .get();
      final userData = userDoc.data() ?? const <String, dynamic>{};
      final logData = logDoc.data() ?? const <String, dynamic>{};
      final allergens =
          (userData['allergens'] as List?)?.join(', ') ?? 'none';
      final calorieGoal = userData['calorieGoal'] ?? 2000;
      final limits = userData['nutrientLimits'] ?? const <String, dynamic>{};
      final todayCalories = logData['calories'] ?? 0;
      final todaySodium = logData['sodium_mg'] ?? 0;
      final todaySugar = logData['sugar_g'] ?? 0;

      ctx = '''
You are Nora, an expert AI nutritionist in the FreshGuard app.
You are warm, precise, and health-focused. Answer in the same language the user writes in.

USER PROFILE:
- Allergens: $allergens
- Daily calorie goal: $calorieGoal kcal
- Cholesterol limit: ${limits['cholesterol_mg'] ?? 300} mg
- Sodium limit: ${limits['sodium_mg'] ?? 2300} mg
- Sugar limit: ${limits['sugar_g'] ?? 50} g
- Saturated fat limit: ${limits['saturated_fat_g'] ?? 20} g

TODAY'S INTAKE:
- Calories: $todayCalories kcal
- Sodium: $todaySodium mg
- Sugar: $todaySugar g

Give specific, actionable advice based on this real data.
''';
    } catch (_) {}

    return _callGemini(
      systemCtx: ctx,
      userMessage: userMessage,
      history: history,
    );
  }

  static Future<String> askChefAI({
    required String restaurantId,
    required String userMessage,
    required List<Map<String, String>> history,
  }) async {
    var ctx = '''
You are Chef AI, a restaurant operations assistant in FreshGuard.
Reply in the same language the user writes in.
Give actionable kitchen, freshness, waste, and food-safety recommendations.
''';

    try {
      final restDoc = await FirebaseFirestore.instance
          .collection('restaurants')
          .doc(restaurantId)
          .get();
      final alerts = await FirebaseFirestore.instance
          .collection('restaurants')
          .doc(restaurantId)
          .collection('alerts')
          .where('resolved', isEqualTo: false)
          .limit(5)
          .get();
      final scans = await FirebaseFirestore.instance
          .collection('restaurants')
          .doc(restaurantId)
          .collection('scans')
          .orderBy('timestamp', descending: true)
          .limit(5)
          .get();
      final restaurantData = restDoc.data() ?? const <String, dynamic>{};
      final recentZones = scans.docs
          .map((doc) => (doc.data()['zone'] ?? 'Kitchen').toString())
          .toSet()
          .join(', ');
      final alertSummary = alerts.docs
          .map((d) => '[${d.data()['severity'] ?? 'medium'}] ${d.data()['message'] ?? 'Alert'}')
          .join(' | ');

      ctx = '''
You are Chef AI, a restaurant operations assistant in FreshGuard.
Reply in the same language the user writes in.

RESTAURANT CONTEXT:
- Name: ${restaurantData['profile']?['name'] ?? restaurantData['name'] ?? 'Restaurant'}
- Cuisine: ${restaurantData['profile']?['cuisineType'] ?? restaurantData['cuisineType'] ?? 'Unknown'}
- Recent scan zones: ${recentZones.isEmpty ? 'none' : recentZones}
- Active alerts: ${alertSummary.isEmpty ? 'none' : alertSummary}

Focus on food safety, waste reduction, kitchen workflow, and practical next steps.
''';
    } catch (_) {}

    return _callGemini(
      systemCtx: ctx,
      userMessage: userMessage,
      history: history,
    );
  }

  static Future<String> askSage({
    required String hotelId,
    required String userMessage,
    required List<Map<String, String>> history,
  }) async {
    var ctx = '''
You are Sage, a hotel sustainability consultant in FreshGuard.
Reply in the same language the user writes in.
Give professional hospitality, HACCP, waste, and guest-safety recommendations.
''';

    try {
      final hotelDoc = await FirebaseFirestore.instance
          .collection('hotels')
          .doc(hotelId)
          .get();
      final depts = await FirebaseFirestore.instance
          .collection('hotels')
          .doc(hotelId)
          .collection('departments')
          .get();
      final scans = await FirebaseFirestore.instance
          .collection('hotels')
          .doc(hotelId)
          .collection('scans')
          .orderBy('timestamp', descending: true)
          .limit(5)
          .get();
      final hotelData = hotelDoc.data() ?? const <String, dynamic>{};
      final departments = depts.docs
          .map((d) => (d.data()['name'] ?? d.id).toString())
          .join(', ');
      final recentRisks = scans.docs
          .map((d) => (d.data()['riskLevel'] ?? 'safe').toString())
          .join(', ');

      ctx = '''
You are Sage, a hotel sustainability consultant in FreshGuard.
Reply in the same language the user writes in.

HOTEL CONTEXT:
- Name: ${hotelData['profile']?['name'] ?? hotelData['name'] ?? 'Hotel'}
- Departments: ${departments.isEmpty ? 'none' : departments}
- Recent scan risk levels: ${recentRisks.isEmpty ? 'none' : recentRisks}

Focus on hospitality operations, HACCP, sustainability, and guest safety.
''';
    } catch (_) {}

    return _callGemini(
      systemCtx: ctx,
      userMessage: userMessage,
      history: history,
    );
  }

  static Future<String> _callGemini(
    {
    required String systemCtx,
    required String userMessage,
    required List<Map<String, String>> history,
  }
  ) async {
    if (geminiApiKey.trim().isEmpty ||
        geminiApiKey.contains('YOUR_') ||
        geminiApiKey.contains('PLACEHOLDER')) {
      throw Exception('Gemini API key is missing or invalid.');
    }

    final contents = <Map<String, dynamic>>[];
    for (final msg in history) {
      contents.add({
        'role': msg['role'] == 'assistant' ? 'model' : 'user',
        'parts': [
          {'text': msg['content'] ?? ''},
        ],
      });
    }
    contents.add({
      'role': 'user',
      'parts': [
        {'text': userMessage},
      ],
    });

    return _callGeminiWithFallback({
      'contents': contents,
      'systemInstruction': {
        'parts': [
          {'text': systemCtx},
        ],
      },
      'generationConfig': {'maxOutputTokens': 1024, 'temperature': 0.7},
    });
  }

  static Future<String> _callGeminiWithFallback(
    Map<String, dynamic> body,
  ) async {
    Object? lastError;

    for (final model in _modelFallbacks) {
      final url =
          'https://generativelanguage.googleapis.com/v1beta/models/'
          '$model:generateContent?key=$geminiApiKey';
      try {
        final response = await http.post(
          Uri.parse(url),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        );
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          final candidates = data['candidates'] as List?;
          if (candidates == null || candidates.isEmpty) {
            throw Exception('Gemini returned no candidates for $model.');
          }
          final content = candidates.first as Map<String, dynamic>;
          final contentBody = content['content'] as Map<String, dynamic>?;
          final parts = contentBody?['parts'] as List?;
          final text = parts != null && parts.isNotEmpty
              ? (parts.first as Map<String, dynamic>)['text'] as String?
              : null;
          if (text == null || text.trim().isEmpty) {
            throw Exception('Gemini returned an empty response for $model.');
          }
          return text;
        }
        if (response.statusCode == 404) {
          lastError = Exception('Gemini model not found: $model');
          continue;
        }
        if (response.statusCode == 429) {
          lastError = Exception('Quota API dépassé, veuillez vérifier votre clé Google Gemini.');
          continue;
        }
        throw Exception('Gemini ${response.statusCode}: ${response.body}');
      } catch (error) {
        lastError = error;
        if (model == _modelFallbacks.last) rethrow;
      }
    }

    throw Exception('All Gemini models failed: $lastError');
  }
}
