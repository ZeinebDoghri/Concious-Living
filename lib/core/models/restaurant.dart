class Restaurant {
  final String id;
  final String name;
  final String address;
  final double? rating;
  final double? lat;
  final double? lng;
  final String? photoReference;
  final String? cuisineType;
  final int? priceLevel;
  final bool isOpenNow;
  final bool isOrkaVerified;
  final List<String> menuAllergens; // allergens across all menu items

  const Restaurant({
    required this.id,
    required this.name,
    required this.address,
    this.rating,
    this.lat,
    this.lng,
    this.photoReference,
    this.cuisineType,
    this.priceLevel,
    this.isOpenNow = false,
    this.isOrkaVerified = false,
    this.menuAllergens = const [],
  });

  /// Distance label from user (placeholder — real distance needs user coords)
  String get priceLevelLabel {
    switch (priceLevel) {
      case 1: return 'DT';
      case 2: return 'DT DT';
      case 3: return 'DT DT DT';
      case 4: return 'DT DT DT DT';
      default: return '';
    }
  }

  bool isAllergenSafe(List<String> userAllergens) {
    if (userAllergens.isEmpty) return true;
    final lower = menuAllergens.map((a) => a.toLowerCase()).toList();
    return !userAllergens.any((a) => lower.contains(a.toLowerCase()));
  }

  factory Restaurant.fromGooglePlaces(Map<String, dynamic> r) {
    final geo = r['geometry']?['location'];
    final photos = r['photos'] as List?;
    final types = (r['types'] as List?)?.cast<String>() ?? [];
    final cuisine = types.firstWhere(
      (t) => t != 'restaurant' && t != 'food' && t != 'point_of_interest' && t != 'establishment',
      orElse: () => 'Restaurant',
    ).replaceAll('_', ' ');

    return Restaurant(
      id: (r['place_id'] ?? '') as String,
      name: (r['name'] ?? 'Unknown') as String,
      address: (r['vicinity'] ?? r['formatted_address'] ?? '') as String,
      rating: (r['rating'] as num?)?.toDouble(),
      lat: (geo?['lat'] as num?)?.toDouble(),
      lng: (geo?['lng'] as num?)?.toDouble(),
      photoReference: photos != null && photos.isNotEmpty
          ? (photos[0]['photo_reference'] as String?)
          : null,
      cuisineType: cuisine,
      priceLevel: r['price_level'] as int?,
      isOpenNow: r['opening_hours']?['open_now'] as bool? ?? false,
      isOrkaVerified: false,
      menuAllergens: const [],
    );
  }

  factory Restaurant.fromFirestore(Map<String, dynamic> data, String id) {
    final profile = data['profile'] as Map<String, dynamic>? ?? {};
    return Restaurant(
      id: id,
      name: (data['name'] ?? profile['name'] ?? profile['restaurantName'] ?? '') as String,
      address: (data['address'] ?? profile['address'] ?? profile['location'] ?? '') as String,
      rating: (data['rating'] as num?)?.toDouble() ?? (profile['rating'] as num?)?.toDouble(),
      lat: (data['lat'] as num?)?.toDouble() ?? (data['latitude'] as num?)?.toDouble(),
      lng: (data['lng'] as num?)?.toDouble() ?? (data['longitude'] as num?)?.toDouble(),
      cuisineType: (data['cuisine'] ?? data['cuisineType'] ?? profile['cuisineType'] ?? profile['cuisine']) as String?,
      priceLevel: (data['priceLevel'] ?? profile['priceLevel']) as int?,
      isOpenNow: (data['openNow'] ?? data['isOpen'] ?? false) as bool,
      isOrkaVerified: (data['isOrkaVerified'] ?? data['orkaVerified'] ?? false) as bool,
      menuAllergens: List<String>.from(data['allergens'] ?? profile['allergens'] ?? []),
    );
  }
}

class MenuItem {
  final String id;
  final String name;
  final double price;
  final double? calories;
  final double? protein;
  final double? carbs;
  final double? fat;
  final List<String> allergens;
  final String section; // Starters / Mains / Desserts / Drinks
  final String? imageUrl;

  const MenuItem({
    required this.id,
    required this.name,
    required this.price,
    this.calories,
    this.protein,
    this.carbs,
    this.fat,
    this.allergens = const [],
    this.section = 'Mains',
    this.imageUrl,
  });

  bool isSafeFor(List<String> userAllergens) {
    if (userAllergens.isEmpty) return true;
    final lower = allergens.map((a) => a.toLowerCase()).toList();
    return !userAllergens.any((a) => lower.contains(a.toLowerCase()));
  }

  factory MenuItem.fromFirestore(Map<String, dynamic> data, String id) {
    return MenuItem(
      id: id,
      name: (data['name'] ?? '') as String,
      price: (data['price'] as num?)?.toDouble() ?? 0,
      calories: (data['calories'] as num?)?.toDouble(),
      protein: (data['protein_g'] as num?)?.toDouble(),
      carbs: (data['carbs_g'] as num?)?.toDouble(),
      fat: (data['fat_g'] as num?)?.toDouble(),
      allergens: List<String>.from(data['allergens'] ?? []),
      section: (data['section'] ?? 'Mains') as String,
      imageUrl: data['imageUrl'] as String?,
    );
  }
}
