import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/models/restaurant.dart';
import '../../../providers/user_provider.dart';
import '../../../services/google_places_service.dart';

// ── Design tokens ─────────────────────────────────────────────────────────────
const _kPrimary = Color(0xFFC4748A);
const _kFresh = Color(0xFF52C98A);
const _kSurface = Color(0xFFFEFAFC);
const _kTextTitle = Color(0xFF26201B);
const _kTextBody = Color(0xFF5C4F48);
const _kTextMuted = Color(0xFF8C7E78);
const _kSoftBg = Color(0xFFF9E9F2);

class FoodMapScreen extends StatefulWidget {
  const FoodMapScreen({super.key});

  @override
  State<FoodMapScreen> createState() => _FoodMapScreenState();
}

class _FoodMapScreenState extends State<FoodMapScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  String _activeFilter = 'All';
  List<Restaurant> _allRestaurants = [];
  List<Restaurant> _filtered = [];
  bool _isLoading = true;
  String? _errorMessage;
  List<String> _userAllergens = [];
  String? _userCity;

  final List<String> _filters = [
    'All',
    'Allergen-safe 🛡️',
    'Low calorie',
    'Gluten-free',
    'Vegan',
    'ORKA ✅',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ── Curated demo restaurants ────────────────────────────────────────────────
  static List<Restaurant> _demoRestaurants() => const [
    Restaurant(
      id: 'r1', name: 'Green Bowl Tunis', address: 'Rue du Lac Windermere, Les Berges du Lac',
      rating: 4.8, cuisineType: 'Vegan & Healthy', priceLevel: 2,
      isOpenNow: true, isOrkaVerified: true, menuAllergens: [],
    ),
    Restaurant(
      id: 'r2', name: 'Dar El Jeld', address: 'Rue Dar El Jeld, Médina, Tunis',
      rating: 4.7, cuisineType: 'Traditional Tunisian', priceLevel: 3,
      isOpenNow: true, isOrkaVerified: true, menuAllergens: ['gluten', 'dairy'],
    ),
    Restaurant(
      id: 'r3', name: 'Sushi Sakura', address: 'Avenue Mohamed V, Tunis',
      rating: 4.6, cuisineType: 'Japanese', priceLevel: 3,
      isOpenNow: true, isOrkaVerified: true, menuAllergens: ['fish', 'soy'],
    ),
    Restaurant(
      id: 'r4', name: 'Le Baroque', address: 'Avenue Habib Bourguiba, Tunis',
      rating: 4.5, cuisineType: 'French-Tunisian Fusion', priceLevel: 3,
      isOpenNow: true, isOrkaVerified: true, menuAllergens: ['gluten', 'dairy', 'eggs'],
    ),
    Restaurant(
      id: 'r5', name: 'Sfax Poisson', address: 'Port de Sfax, Sfax',
      rating: 4.6, cuisineType: 'Fresh Seafood', priceLevel: 2,
      isOpenNow: true, isOrkaVerified: true, menuAllergens: ['fish', 'shellfish'],
    ),
    Restaurant(
      id: 'r6', name: 'La Table Bio', address: 'Rue de Marseille, Tunis',
      rating: 4.4, cuisineType: 'Organic & Gluten-Free', priceLevel: 2,
      isOpenNow: true, isOrkaVerified: false, menuAllergens: ['dairy'],
    ),
    Restaurant(
      id: 'r7', name: 'Hammamet Garden', address: 'Zone Touristique, Hammamet',
      rating: 4.0, cuisineType: 'International Buffet', priceLevel: 2,
      isOpenNow: true, isOrkaVerified: false, menuAllergens: ['gluten', 'dairy', 'peanuts', 'nuts'],
    ),
    Restaurant(
      id: 'r8', name: 'La Marsa Café', address: 'Avenue du 14 Janvier, La Marsa',
      rating: 4.1, cuisineType: 'Mediterranean', priceLevel: 2,
      isOpenNow: false, isOrkaVerified: true, menuAllergens: ['dairy', 'eggs'],
    ),
    Restaurant(
      id: 'r9', name: 'Cactus Burger', address: 'Rue Ibn Khaldoun, Tunis',
      rating: 4.2, cuisineType: 'Burgers & Grill', priceLevel: 1,
      isOpenNow: true, isOrkaVerified: false, menuAllergens: ['gluten', 'dairy', 'eggs', 'sesame'],
    ),
    Restaurant(
      id: 'r10', name: 'Sousse Marina Lounge', address: 'Port El Kantaoui, Sousse',
      rating: 4.3, cuisineType: 'Tapas & Mediterranean', priceLevel: 3,
      isOpenNow: false, isOrkaVerified: false, menuAllergens: ['gluten', 'sulfites'],
    ),
  ];

  // ── Recommendation score (higher = better for user) ──────────────────────
  int _score(Restaurant r) {
    int score = 0;
    final safe = r.isAllergenSafe(_userAllergens);
    if (safe) score += 100;
    if (r.isOrkaVerified) score += 50;
    if (r.isOpenNow) score += 20;
    score += ((r.rating ?? 0) * 10).toInt();
    return score;
  }

  Future<void> _loadData() async {
    final user = context.read<UserProvider>().currentUser;
    if (user == null) return;

    setState(() { _isLoading = true; _errorMessage = null; });

    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.id).get();
      final userData = userDoc.data() ?? {};
      _userAllergens = List<String>.from(userData['allergens'] ?? []);
      _userCity = (userData['city'] as String?)?.trim();
    } catch (_) {}

    // Use curated demo restaurants, sorted by recommendation score
    final restaurants = List<Restaurant>.from(_demoRestaurants())
      ..sort((a, b) => _score(b).compareTo(_score(a)));

    if (mounted) {
      setState(() {
        _allRestaurants = restaurants;
        _isLoading = false;
      });
      _applyFilters();
    }
  }

  void _applyFilters() {
    List<Restaurant> result = List.from(_allRestaurants);

    // Text search
    if (_query.trim().isNotEmpty) {
      final q = _query.toLowerCase();
      result = result.where((r) =>
          r.name.toLowerCase().contains(q) ||
          (r.cuisineType?.toLowerCase().contains(q) ?? false) ||
          r.address.toLowerCase().contains(q)).toList();
    }

    // Chip filter
    switch (_activeFilter) {
      case 'Allergen-safe 🛡️':
        result = result.where((r) => r.isAllergenSafe(_userAllergens)).toList();
        break;
      case 'ORKA ✅':
        result = result.where((r) => r.isOrkaVerified).toList();
        break;
      case 'Gluten-free':
        result = result.where((r) =>
            !r.menuAllergens.any((a) => a.toLowerCase().contains('gluten') || a.toLowerCase().contains('wheat'))).toList();
        break;
      case 'Vegan':
        result = result.where((r) =>
            !r.menuAllergens.any((a) => ['meat', 'dairy', 'eggs', 'fish', 'seafood']
                .any((animal) => a.toLowerCase().contains(animal)))).toList();
        break;
    }

    setState(() { _filtered = result; });
  }

  @override
  Widget build(BuildContext context) {
    final city = _userCity ?? 'your location';

    return Scaffold(
      backgroundColor: _kSurface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.black, size: 20),
          onPressed: () => context.canPop() ? context.pop() : context.go('/customer/home'),
        ),
        title: Text(
          'Find Safe Restaurants',
          style: GoogleFonts.playfairDisplay(
            fontSize: 18, fontWeight: FontWeight.w700, color: _kTextTitle,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // ── Search bar ──────────────────────────────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TextField(
              controller: _searchController,
              onChanged: (val) { _query = val; _applyFilters(); },
              decoration: InputDecoration(
                hintText: 'Search restaurants, cuisines...',
                hintStyle: GoogleFonts.inter(color: _kTextMuted, fontSize: 14),
                prefixIcon: const Icon(Icons.search, color: Color(0xFFC4748A), size: 20),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.tune_rounded, color: Color(0xFFC4748A), size: 20),
                  onPressed: () {}, // future: advanced filter sheet
                ),
                filled: true,
                fillColor: _kSoftBg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),

          // ── Filter chips ────────────────────────────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.only(bottom: 12),
            child: SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _filters.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final f = _filters[i];
                  final active = f == _activeFilter;
                  return GestureDetector(
                    onTap: () { _activeFilter = f; _applyFilters(); },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: active ? _kPrimary : _kSoftBg,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        f,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: active ? Colors.white : _kTextBody,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // ── Location header ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                const Icon(Icons.location_on_rounded, size: 16, color: Color(0xFFC4748A)),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Restaurants near $city',
                    style: GoogleFonts.inter(
                      fontSize: 13, fontWeight: FontWeight.w600, color: _kTextBody,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: _loadData,
                  child: Text(
                    'Refresh',
                    style: GoogleFonts.inter(
                      fontSize: 12, fontWeight: FontWeight.w600, color: _kPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Restaurant list ─────────────────────────────────────────────────
          Expanded(
            child: _isLoading
                ? _buildSkeletonLoader()
                : _errorMessage != null
                    ? _buildError()
                    : _filtered.isEmpty
                        ? _buildEmpty()
                        : RefreshIndicator(
                            onRefresh: _loadData,
                            color: _kPrimary,
                            child: ListView.separated(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                              itemCount: _filtered.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 12),
                              itemBuilder: (_, i) => _RestaurantCard(
                                restaurant: _filtered[i],
                                userAllergens: _userAllergens,
                                onTap: () => context.push('/customer/foodmap/${_filtered[i].id}'),
                              ),
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonLoader() {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: 5,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, __) => _SkeletonCard(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded, size: 48, color: _kTextMuted),
            const SizedBox(height: 16),
            Text(_errorMessage!,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: _kTextBody, fontSize: 14)),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _kPrimary),
              onPressed: _loadData,
              child: Text('Try again', style: GoogleFonts.inter(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.restaurant_menu_rounded, size: 52, color: _kTextMuted),
          const SizedBox(height: 16),
          Text('No restaurants found', style: GoogleFonts.playfairDisplay(
            fontSize: 17, fontWeight: FontWeight.w700, color: _kTextTitle)),
          const SizedBox(height: 8),
          Text('Try a different filter or search term.',
              style: GoogleFonts.inter(fontSize: 13, color: _kTextMuted)),
        ],
      ),
    );
  }
}

// ── Restaurant Card ───────────────────────────────────────────────────────────
class _RestaurantCard extends StatelessWidget {
  final Restaurant restaurant;
  final List<String> userAllergens;
  final VoidCallback onTap;

  const _RestaurantCard({
    required this.restaurant,
    required this.userAllergens,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isAllergenSafe = restaurant.isAllergenSafe(userAllergens);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10, offset: const Offset(0, 3),
          )],
        ),
        child: Row(
          children: [
            // Photo
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16), bottomLeft: Radius.circular(16),
              ),
              child: SizedBox(
                width: 90,
                height: 90,
                child: restaurant.photoReference != null
                    ? Image.network(
                        GooglePlacesService.getPhotoUrl(restaurant.photoReference!),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _PhotoPlaceholder(),
                      )
                    : _PhotoPlaceholder(),
              ),
            ),
            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            restaurant.name,
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 14, fontWeight: FontWeight.w700, color: _kTextTitle,
                            ),
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (restaurant.isOrkaVerified)
                          Container(
                            margin: const EdgeInsets.only(left: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFC4748A).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text('ORKA ✅',
                                style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w700, color: _kPrimary)),
                          ),
                        Container(
                          margin: const EdgeInsets.only(left: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: (restaurant.isOpenNow
                                    ? const Color(0xFF52C98A)
                                    : const Color(0xFFAAAAAA))
                                .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            restaurant.isOpenNow ? 'Open' : 'Closed',
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: restaurant.isOpenNow
                                  ? const Color(0xFF2D8A56)
                                  : const Color(0xFF888888),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    if (isAllergenSafe && userAllergens.isNotEmpty)
                      Text(
                        '⭐ Recommended for you',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: _kPrimary,
                        ),
                      ),
                    const SizedBox(height: 2),
                    Text(
                      restaurant.address,
                      style: GoogleFonts.inter(fontSize: 11, color: _kTextMuted),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (restaurant.rating != null) ...[
                          const Icon(Icons.star_rounded, size: 14, color: Color(0xFFFFB347)),
                          const SizedBox(width: 3),
                          Text('${restaurant.rating!.toStringAsFixed(1)}',
                              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: _kTextBody)),
                          const SizedBox(width: 8),
                        ],
                        if (restaurant.cuisineType != null)
                          Text(restaurant.cuisineType!,
                              style: GoogleFonts.inter(fontSize: 11, color: _kTextMuted)),
                        const Spacer(),
                        if (restaurant.priceLevelLabel.isNotEmpty)
                          Text(restaurant.priceLevelLabel,
                              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: _kTextBody)),
                      ],
                    ),
                    if (!isAllergenSafe && userAllergens.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        '⚠️ Contains your allergens',
                        style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.orange),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFFD9899F), size: 20),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }
}

// ── Skeleton loader card ──────────────────────────────────────────────────────
class _SkeletonCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 90,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 90, height: 90,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F0F0),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16), bottomLeft: Radius.circular(16),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _Shimmer(width: 140, height: 14),
                  const SizedBox(height: 8),
                  _Shimmer(width: 100, height: 11),
                  const SizedBox(height: 8),
                  _Shimmer(width: 70, height: 11),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Shimmer extends StatelessWidget {
  final double width;
  final double height;
  const _Shimmer({required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width, height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFEEEEEE),
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }
}

class _PhotoPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF9E9F2),
      child: const Icon(Icons.restaurant_rounded, size: 32, color: Color(0xFFD9899F)),
    );
  }
}
