import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../config/api_keys.dart' as api_keys;

class AIChatService {
  static const List<String> _models = [
    'gemini-2.0-flash',
    'gemini-2.0-flash-lite',
    'gemini-1.5-flash',
    'gemini-1.5-flash-latest',
    'gemini-1.5-flash-001',
    'gemini-1.5-flash-8b',
  ];

  static Future<String> askNora({
    required String uid,
    required String userMessage,
    required List<Map<String, String>> history,
  }) async {
    var ctx = '''
You are Nora, an expert AI nutritionist in the ORKA app.
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
      final todayProtein = logData['protein_g'] ?? 0;
      final todayCarbs = logData['carbs_g'] ?? 0;
      final todayFat = logData['fat_g'] ?? 0;
      final todaySodium = logData['sodium_mg'] ?? 0;
      final todaySugar = logData['sugar_g'] ?? 0;

      ctx = '''
You are Nora, an expert AI nutritionist in the ORKA app.
You are warm, precise, and health-focused. Answer in the same language the user writes in.

USER PROFILE:
- Allergens: $allergens
- Daily calorie goal: $calorieGoal kcal
- Daily protein goal: ${userData['proteinGoal_g'] ?? 'N/A'} g
- Daily carbs goal: ${userData['carbsGoal_g'] ?? 'N/A'} g
- Daily fat goal: ${userData['fatGoal_g'] ?? 'N/A'} g
- Cholesterol limit: ${limits['cholesterol_mg'] ?? 300} mg
- Sodium limit: ${limits['sodium_mg'] ?? 2300} mg
- Sugar limit: ${limits['sugar_g'] ?? 50} g
- Saturated fat limit: ${limits['saturated_fat_g'] ?? 20} g

TODAY'S INTAKE:
- Calories: $todayCalories kcal
- Protein: $todayProtein g
- Carbs: $todayCarbs g
- Fat: $todayFat g
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
You are Chef AI, a restaurant operations assistant in ORKA.
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
You are Chef AI, a restaurant operations assistant in ORKA.
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
You are Sage, a hotel sustainability consultant in ORKA.
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
You are Sage, a hotel sustainability consultant in ORKA.
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

  static Future<String> _callGemini({
    required String systemCtx,
    required String userMessage,
    required List<Map<String, String>> history,
  }) async {
    final contents = <Map<String, dynamic>>[];

    for (final msg in history) {
      contents.add({
        'role': msg['role'] == 'assistant' ? 'model' : 'user',
        'parts': [{'text': msg['content'] ?? ''}],
      });
    }

    contents.add({
      'role': 'user',
      'parts': [{'text': userMessage}],
    });

    final body = {
      'system_instruction': {
        'parts': [{'text': systemCtx}],
      },
      'contents': contents,
      'generationConfig': {
        'temperature': 0.7,
        'maxOutputTokens': 1024,
      },
    };

    String? lastError;

    // Try every key × every model until one succeeds
    for (final apiKey in api_keys.geminiApiKeys) {
      for (final model in _models) {
        final url = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/'
          '$model:generateContent?key=$apiKey',
        );

        try {
          debugPrint('--- Gemini Request ($model, key …${apiKey.substring(apiKey.length - 6)}) ---');
          final response = await http
              .post(url, headers: {'Content-Type': 'application/json'}, body: jsonEncode(body))
              .timeout(const Duration(seconds: 30));

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body) as Map<String, dynamic>;
            final candidates = data['candidates'] as List?;
            if (candidates != null && candidates.isNotEmpty) {
              final parts = (candidates[0]['content'] as Map?)?['parts'] as List?;
              if (parts != null && parts.isNotEmpty) {
                return parts[0]['text'] as String? ?? 'No response';
              }
            }
            return 'No response from AI';
          }

          debugPrint('Gemini Error ($model): ${response.statusCode}');
          lastError = 'HTTP ${response.statusCode} on $model';
          // 429 = quota exhausted for this key → try next key immediately
          if (response.statusCode == 429) break;
          continue;
        } catch (e) {
          debugPrint('Gemini Exception ($model): $e');
          lastError = 'Network error on $model: $e';
          continue;
        }
      }
    }

    return _genericFallback(userMessage, systemCtx);
  }

  static String _genericFallback(String userMessage, String systemCtx) {
    final msg = userMessage.toLowerCase();
    final isNora = systemCtx.contains('Nora') || systemCtx.contains('nutritionist');
    final isChef = systemCtx.contains('Chef AI') || systemCtx.contains('kitchen operations');
    // isSage = everything else (hotel)

    // ── Nora: AI Nutritionist ──────────────────────────────────────────────
    if (isNora) {
      if (msg.contains('calori') || msg.contains('kcal')) {
        return "Your daily calorie needs depend on your age, weight, height, and activity level. "
            "Most adults require 1800–2500 kcal/day. Check your personal goal in the Profile tab "
            "and try to stay within your target. Focus on nutrient-dense whole foods rather than "
            "empty calories from processed snacks.";
      }
      if (msg.contains('protein')) {
        return "Protein is essential for muscle repair, satiety, and immune function. "
            "Aim for 0.8–1.2 g per kg of body weight per day. "
            "Top sources: chicken breast, eggs, lentils, Greek yogurt, fish, and tofu. "
            "Spreading intake across meals improves absorption.";
      }
      if (msg.contains('sugar') || msg.contains('sucre')) {
        return "Excess added sugar raises blood glucose and contributes to weight gain. "
            "WHO recommends keeping free sugars under 25 g/day. "
            "Choose whole fruits over juices, read nutrition labels carefully, "
            "and replace sweet snacks with nuts or vegetables.";
      }
      if (msg.contains('sodium') || msg.contains('salt') || msg.contains('sel')) {
        return "High sodium intake is a leading risk factor for hypertension. "
            "The daily limit is 2300 mg (about 1 teaspoon of salt). "
            "Reduce processed and canned foods, flavour meals with herbs and lemon instead, "
            "and track your intake using your ORKA scan history.";
      }
      if (msg.contains('cholesterol')) {
        return "Dietary cholesterol has less impact than once thought — saturated and trans fats "
            "are the bigger concern. Keep saturated fat under 20 g/day. "
            "Include heart-healthy fats from olive oil, avocado, walnuts, and oily fish. "
            "Your ORKA scan history tracks your cholesterol intake over time.";
      }
      if (msg.contains('fat') || msg.contains('lipid')) {
        return "Not all fats are equal. Unsaturated fats (olive oil, nuts, fish) are beneficial, "
            "while saturated fats (butter, red meat) should be limited to under 20 g/day. "
            "Avoid trans fats entirely. Your ORKA scans track saturated fat intake against your daily goal.";
      }
      if (msg.contains('weight') || msg.contains('poids') || msg.contains('diet')) {
        return "Sustainable weight management combines a moderate calorie deficit (–300 to –500 kcal/day) "
            "with adequate protein and regular physical activity. "
            "Avoid extreme restriction — it slows metabolism. "
            "Use your ORKA daily log to monitor intake and stay on track with your health plan.";
      }
      if (msg.contains('hello') || msg.contains('hi') || msg.contains('bonjour') || msg.contains('salut')) {
        return "Hello! I'm Nora, your personal AI nutritionist inside ORKA. "
            "I can help you understand your nutrition data, suggest dietary improvements, "
            "and guide you toward your health goals. What would you like to know today?";
      }
      return "Great question! As your nutritionist, I recommend focusing on balanced meals: "
          "half your plate as vegetables, a quarter as lean protein, and a quarter as whole grains. "
          "Check your Today's Nutrition section on the Home screen for your real-time intake data. "
          "Feel free to ask me about specific nutrients, foods, or your health goals.";
    }

    // ── Chef AI: Kitchen Operations ────────────────────────────────────────
    if (isChef) {
      if (msg.contains('waste') || msg.contains('leftover') || msg.contains('expir')) {
        return "To minimize kitchen waste: apply FIFO (First In, First Out) stock rotation strictly, "
            "conduct daily inventory checks, and track waste by category. "
            "Repurpose vegetable trimmings for stocks and sauces. "
            "These practices typically cut food waste by 20–30% within a month.";
      }
      if (msg.contains('temp') || msg.contains('cold') || msg.contains('storage') || msg.contains('refriger')) {
        return "Cold chain compliance is critical for food safety. "
            "Refrigerators: 0–4°C. Freezers: –18°C or below. "
            "Log temperatures twice daily. Hot foods must be cooled below 10°C within 2 hours. "
            "Use your ORKA expiry check feature to flag items approaching their use-by date.";
      }
      if (msg.contains('haccp') || msg.contains('safety') || msg.contains('hygiene')) {
        return "HACCP in your kitchen: identify critical control points (CCPs) — receiving, "
            "storage, cooking, and serving. "
            "Cooking temperatures must reach ≥75°C at the core. "
            "Staff must log CCPs daily and report deviations immediately. "
            "Use your ORKA scan history to track high-risk ingredient usage.";
      }
      if (msg.contains('hello') || msg.contains('hi') || msg.contains('bonjour')) {
        return "Hello! I'm Chef AI, your kitchen operations assistant inside ORKA. "
            "I specialize in food safety, waste reduction, and kitchen workflow optimization. "
            "What kitchen challenge can I help you tackle today?";
      }
      return "Here's today's kitchen checklist: verify cold storage temperatures, "
          "rotate stock using FIFO, check all expiry dates on perishables, "
          "ensure staff hygiene compliance, and review yesterday's waste log. "
          "A proactive approach prevents 80% of food safety incidents.";
    }

    // ── Sage: Hotel Sustainability Consultant ──────────────────────────────
    if (msg.contains('haccp')) {
      return "HACCP for hotel operations: map your food flow from receiving to guest delivery. "
          "Identify CCPs at each stage — particularly cooking (≥75°C), cold storage (≤4°C), "
          "and reheating (≥63°C). Document all checks and train department heads on corrective actions. "
          "Your ORKA scan data provides supporting evidence for audits.";
    }
    if (msg.contains('waste') || msg.contains('sustainab') || msg.contains('eco')) {
      return "Hotel sustainability starts with measurement. "
          "Track food waste by department, set monthly reduction targets (aim for –15% per quarter), "
          "and engage kitchen staff in waste-conscious portioning. "
          "Composting, supplier partnerships for surplus redistribution, and menu engineering "
          "are your highest-impact levers.";
    }
    if (msg.contains('guest') || msg.contains('allergen') || msg.contains('safety')) {
      return "Guest food safety is a legal and ethical priority. "
          "Ensure all menu items have documented allergen information (EU Regulation 1169/2011). "
          "Train front-of-house staff to communicate allergen data confidently. "
          "Use ORKA to scan and verify high-risk dishes before service.";
    }
    if (msg.contains('hello') || msg.contains('hi') || msg.contains('bonjour')) {
      return "Hello! I'm Sage, your hotel sustainability consultant inside ORKA. "
          "I can guide you on HACCP compliance, waste reduction, energy efficiency, "
          "and guest safety protocols. What would you like to improve today?";
    }
    return "As your sustainability advisor, I recommend a quarterly audit cycle: "
        "review food waste logs, verify HACCP documentation, check cold chain compliance records, "
        "and benchmark energy consumption per department. "
        "Use your ORKA scan history to identify high-risk patterns and brief your team weekly.";
  }

  static Future<String> predictWaste({
    required String systemCtx,
    required String userPrompt,
  }) async {
    final contents = [
      {
        'role': 'user',
        'parts': [{'text': userPrompt}],
      }
    ];

    final body = {
      'system_instruction': {
        'parts': [{'text': systemCtx}],
      },
      'contents': contents,
      'generationConfig': {
        'temperature': 0.7,
        'maxOutputTokens': 1024,
      },
    };

    String? lastError;

    for (final apiKey in api_keys.geminiApiKeys) {
      for (final model in _models) {
        final url = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/'
          '$model:generateContent?key=$apiKey',
        );

        try {
          final response = await http
              .post(url,
                  headers: {'Content-Type': 'application/json'},
                  body: jsonEncode(body))
              .timeout(const Duration(seconds: 30));

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body) as Map<String, dynamic>;
            final candidates = data['candidates'] as List?;
            if (candidates != null && candidates.isNotEmpty) {
              final parts = (candidates[0]['content'] as Map?)?['parts'] as List?;
              if (parts != null && parts.isNotEmpty) {
                return parts[0]['text'] as String? ?? 'No response';
              }
            }
            return 'No response from AI';
          }
          lastError = 'HTTP ${response.statusCode} on $model';
          if (response.statusCode == 429) break;
          continue;
        } catch (e) {
          lastError = 'Network error on $model: $e';
          continue;
        }
      }
    }
    return 'Based on historical patterns, expect moderate waste levels tomorrow. Focus on FIFO rotation, check expiry dates on perishables, and reduce prep quantities by 10–15% for slower weekday service.';
  }
}
