import 'dart:convert';

import 'package:http/http.dart' as http;

class AllergenLookupResult {
  final List<String> ingredients;
  final List<String> allergens;
  final String source;

  const AllergenLookupResult({
    required this.ingredients,
    required this.allergens,
    required this.source,
  });
}

class AllergenLookupService {
  static final Map<String, AllergenLookupResult> _cache =
      <String, AllergenLookupResult>{};

  static Future<AllergenLookupResult> fetch(String dishName) async {
    final query = _normalizeDishName(dishName);
    if (query.isEmpty) {
      return const AllergenLookupResult(
        ingredients: <String>[],
        allergens: <String>[],
        source: 'empty',
      );
    }

    final cached = _cache[query];
    if (cached != null) return cached;

    final apiResult = await _fetchFromApi(query);
    final result = apiResult ?? _fallback(query);
    _cache[query] = result;
    return result;
  }

  static Set<String> matchAgainstProfile({
    required Iterable<String> profileAllergens,
    required Iterable<String> detectedAllergens,
  }) {
    final profile = profileAllergens
        .map(_normalizeAllergen)
        .where((e) => e.isNotEmpty)
        .toSet();
    final detected = detectedAllergens
        .map(_normalizeAllergen)
        .where((e) => e.isNotEmpty)
        .toSet();
    return profile.intersection(detected);
  }

  static Future<AllergenLookupResult?> _fetchFromApi(String query) async {
    final uri = Uri.https('world.openfoodfacts.org', '/cgi/search.pl', <String, String>{
      'search_terms': query,
      'search_simple': '1',
      'action': 'process',
      'json': '1',
      'page_size': '1',
      'fields': 'product_name,ingredients_text,allergens_tags',
    });

    try {
      final response = await http.get(
        uri,
        headers: <String, String>{
          'User-Agent': 'FoodAllergenDetector/1.0 (Flutter app)',
        },
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return null;
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) return null;

      final products = decoded['products'];
      if (products is! List || products.isEmpty) return null;

      final first = products.first;
      if (first is! Map<String, dynamic>) return null;

      final ingredientsRaw = (first['ingredients_text'] ?? '') as String;
      final ingredients = ingredientsRaw
          .split(',')
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .take(15)
          .toList(growable: false);

      final allergensRaw = first['allergens_tags'];
      final allergens = <String>[];
      if (allergensRaw is List) {
        for (final tag in allergensRaw) {
          if (tag is String && tag.trim().isNotEmpty) {
            allergens.add(_normalizeAllergen(tag));
          }
        }
      }

      return AllergenLookupResult(
        ingredients: ingredients,
        allergens: allergens,
        source: allergens.isEmpty ? 'api-no-allergens' : 'api',
      );
    } catch (_) {
      return null;
    }
  }

  static AllergenLookupResult _fallback(String query) {
    final key = query.toLowerCase();
    final ingredients = <String>[];
    final allergens = <String>{};

    void addIngredients(List<String> items) => ingredients.addAll(items);
    void addAllergens(List<String> items) => allergens.addAll(items.map(_normalizeAllergen));
    bool hasAny(List<String> needles) => needles.any(key.contains);

    if (hasAny(const ['pizza', 'pasta', 'bread', 'burger', 'sandwich', 'taco', 'quesadilla', 'wrap', 'ramen', 'noodle', 'lasagna', 'gnocchi'])) {
      addAllergens(const ['gluten', 'milk', 'eggs']);
    }
    if (hasAny(const ['cake', 'pie', 'pastry', 'cookie', 'donut', 'muffin', 'waffle', 'pancake', 'french_toast', 'french toast'])) {
      addAllergens(const ['gluten', 'milk', 'eggs']);
    }
    if (hasAny(const ['ice_cream', 'ice cream', 'cheesecake', 'tiramisu', 'crepe'])) {
      addAllergens(const ['milk', 'eggs', 'gluten']);
    }
    if (hasAny(const ['salmon', 'tuna', 'sushi', 'sashimi', 'fish', 'crab', 'lobster', 'shrimp', 'prawn', 'octopus'])) {
      addAllergens(const ['fish', 'shellfish', 'soybeans']);
    }
    if (hasAny(const ['chicken', 'beef', 'pork', 'lamb', 'steak', 'hot_dog', 'hot dog', 'wings'])) {
      addAllergens(const ['soybeans', 'gluten']);
    }
    if (hasAny(const ['fried_rice', 'fried rice', 'rice bowl', 'stir fry', 'stir-fry'])) {
      addAllergens(const ['soybeans', 'eggs', 'gluten']);
    }
    if (hasAny(const ['salad', 'caesar', 'slaw'])) {
      addAllergens(const ['eggs', 'milk', 'fish', 'gluten']);
    }
    if (hasAny(const ['almond', 'nut', 'macaron', 'trail', 'peanut'])) {
      addAllergens(const ['tree nuts', 'peanuts']);
    }
    if (hasAny(const ['chocolate', 'milkshake', 'smoothie', 'yogurt'])) {
      addAllergens(const ['milk']);
    }
    if (hasAny(const ['omelette', 'egg', 'eggs', 'frittata'])) {
      addAllergens(const ['eggs', 'milk']);
    }

    if (allergens.isEmpty) {
      addAllergens(const ['gluten', 'milk', 'eggs']);
    }

    if (hasAny(const ['pizza'])) {
      addIngredients(const ['dough', 'tomato sauce', 'mozzarella', 'olive oil', 'basil']);
    } else if (hasAny(const ['burger', 'hot dog', 'sandwich'])) {
      addIngredients(const ['bun', 'protein', 'lettuce', 'tomato', 'sauce']);
    } else if (hasAny(const ['sushi', 'sashimi'])) {
      addIngredients(const ['rice', 'nori', 'fish', 'soy sauce']);
    } else if (hasAny(const ['pasta', 'ramen', 'noodle'])) {
      addIngredients(const ['noodles', 'sauce', 'seasoning', 'cheese']);
    } else if (hasAny(const ['cake', 'pie', 'cookie', 'donut', 'muffin'])) {
      addIngredients(const ['flour', 'sugar', 'butter', 'eggs', 'milk']);
    } else {
      addIngredients(const ['ingredient data unavailable']);
    }

    return AllergenLookupResult(
      ingredients: ingredients.take(15).toList(growable: false),
      allergens: allergens.toList(growable: false)..sort(),
      source: 'fallback',
    );
  }

  static String _normalizeDishName(String value) {
    return value.trim().replaceAll(RegExp(r'[_-]+'), ' ');
  }

  static String _normalizeAllergen(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll('en:', '')
        .replaceAll('-', ' ')
        .replaceAll('_', ' ');
  }
}