import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/models/restaurant.dart';
import '../../../providers/user_provider.dart';
import '../../../services/google_places_service.dart';

// ── Design tokens ─────────────────────────────────────────────────────────────
const _kPrimary = Color(0xFFC4748A);
const _kFresh = Color(0xFF52C98A);
const _kDanger = Color(0xFFFF7070);
const _kSurface = Color(0xFFFEFAFC);
const _kTextTitle = Color(0xFF26201B);
const _kTextBody = Color(0xFF5C4F48);
const _kTextMuted = Color(0xFF8C7E78);
const _kSoftBg = Color(0xFFF9E9F2);

class RestaurantDetailScreen extends StatefulWidget {
  final String restaurantId;
  const RestaurantDetailScreen({super.key, required this.restaurantId});

  @override
  State<RestaurantDetailScreen> createState() => _RestaurantDetailScreenState();
}

class _RestaurantDetailScreenState extends State<RestaurantDetailScreen> {
  Map<String, dynamic>? _placeDetails;
  bool _isVerified = false;
  bool _loadingMenu = true;
  List<MenuItem> _menu = [];
  List<String> _userAllergens = [];
  bool _isFavorite = false;
  Restaurant? _restaurant;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    final user = context.read<UserProvider>().currentUser;
    if (user == null) return;

    // Load user allergens
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.id).get();
    _userAllergens = List<String>.from(userDoc.data()?['allergens'] ?? []);

    // Check if favorite
    final favDoc = await FirebaseFirestore.instance
        .collection('users').doc(user.id)
        .collection('favorites').doc(widget.restaurantId).get();
    if (mounted) setState(() => _isFavorite = favDoc.exists);

    // Check ORKA verified
    final verifiedDoc = await FirebaseFirestore.instance
        .collection('verified_restaurants').doc(widget.restaurantId).get();
    if (mounted) setState(() => _isVerified = verifiedDoc.exists);

    // Load Google Places details
    final details = await GooglePlacesService.getPlaceDetails(widget.restaurantId);
    if (mounted) setState(() => _placeDetails = details);

    // Load menu if verified
    if (_isVerified) {
      final menu = await GooglePlacesService.getRestaurantMenu(widget.restaurantId);
      if (mounted) setState(() { _menu = menu; _loadingMenu = false; });
    } else {
      if (mounted) setState(() => _loadingMenu = false);
    }
  }

  Future<void> _toggleFavorite() async {
    final user = context.read<UserProvider>().currentUser;
    if (user == null) return;

    final ref = FirebaseFirestore.instance
        .collection('users').doc(user.id)
        .collection('favorites').doc(widget.restaurantId);

    if (_isFavorite) {
      await ref.delete();
    } else {
      await ref.set({
        'restaurantId': widget.restaurantId,
        'name': _placeDetails?['name'] ?? widget.restaurantId,
        'savedAt': FieldValue.serverTimestamp(),
      });
    }
    if (mounted) setState(() => _isFavorite = !_isFavorite);
  }

  bool get _isAllergenSafe {
    if (_userAllergens.isEmpty) return true;
    final details = _placeDetails;
    if (details == null) return true;
    // For verified restaurants check menu allergens
    if (_isVerified) {
      final allMenuAllergens = _menu.expand((m) => m.allergens).map((a) => a.toLowerCase()).toSet();
      return !_userAllergens.any((a) => allMenuAllergens.contains(a.toLowerCase()));
    }
    return true; // non-verified: can't check
  }

  @override
  Widget build(BuildContext context) {
    final name = _placeDetails?['name'] ?? 'Restaurant';
    final address = _placeDetails?['formatted_address'] ?? '';
    final rating = (_placeDetails?['rating'] as num?)?.toDouble();
    final photos = _placeDetails?['photos'] as List?;
    final photoRef = photos != null && photos.isNotEmpty
        ? photos[0]['photo_reference'] as String?
        : null;
    final hours = _placeDetails?['opening_hours']?['weekday_text'] as List?;

    return Scaffold(
      backgroundColor: _kSurface,
      body: CustomScrollView(
        slivers: [
          // ── Hero image app bar ───────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: _kPrimary,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
              onPressed: () => context.canPop() ? context.pop() : context.go('/customer/foodmap'),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  _isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  color: _isFavorite ? Colors.red : Colors.white,
                ),
                onPressed: _toggleFavorite,
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: photoRef != null
                  ? Image.network(
                      GooglePlacesService.getPhotoUrl(photoRef),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: _kPrimary,
                        child: const Icon(Icons.restaurant_rounded, color: Colors.white, size: 60),
                      ),
                    )
                  : Container(
                      color: _kPrimary,
                      child: const Icon(Icons.restaurant_rounded, color: Colors.white, size: 60),
                    ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Name + rating row ──────────────────────────────────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 22, fontWeight: FontWeight.w700, color: _kTextTitle,
                          ),
                        ),
                      ),
                      if (rating != null) ...[
                        const Icon(Icons.star_rounded, size: 18, color: Color(0xFFFFB347)),
                        const SizedBox(width: 4),
                        Text(rating.toStringAsFixed(1),
                            style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: _kTextBody)),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),

                  // ── ORKA Verified badge ────────────────────────────────
                  if (_isVerified)
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFC4748A), Color(0xFFFF8FAB)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('ORKA Verified ✅',
                          style: GoogleFonts.inter(
                            fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white,
                          )),
                    ),

                  // ── Address ────────────────────────────────────────────
                  if (address.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.location_on_rounded, size: 16, color: Color(0xFFC4748A)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(address,
                                style: GoogleFonts.inter(fontSize: 13, color: _kTextBody)),
                          ),
                        ],
                      ),
                    ),

                  // ── Opening hours ──────────────────────────────────────
                  if (hours != null && hours.isNotEmpty) ...[
                    Row(
                      children: [
                        const Icon(Icons.schedule_rounded, size: 16, color: Color(0xFFC4748A)),
                        const SizedBox(width: 6),
                        Text('Opening hours', style: GoogleFonts.inter(
                          fontSize: 13, fontWeight: FontWeight.w600, color: _kTextBody,
                        )),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ...hours.map((h) => Padding(
                      padding: const EdgeInsets.only(left: 22, bottom: 2),
                      child: Text(h.toString(),
                          style: GoogleFonts.inter(fontSize: 12, color: _kTextMuted)),
                    )),
                    const SizedBox(height: 12),
                  ],

                  // ── Allergen banner ────────────────────────────────────
                  if (_userAllergens.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _isAllergenSafe
                            ? const Color(0xFFD4F7F2)
                            : const Color(0xFFFFE5E5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _isAllergenSafe ? Icons.shield_rounded : Icons.warning_rounded,
                            color: _isAllergenSafe ? _kFresh : _kDanger,
                            size: 22,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            _isAllergenSafe
                                ? '✅ Safe for your allergies'
                                : '⚠️ Contains your allergens',
                            style: GoogleFonts.inter(
                              fontSize: 13, fontWeight: FontWeight.w600,
                              color: _isAllergenSafe ? _kFresh : _kDanger,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // ── Menu / Not verified section ────────────────────────
                  if (_isVerified)
                    _buildMenu()
                  else
                    _buildNotVerified(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenu() {
    if (_loadingMenu) {
      return const Center(child: Padding(
        padding: EdgeInsets.all(32),
        child: CircularProgressIndicator(),
      ));
    }

    if (_menu.isEmpty) {
      return Center(child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text('No menu items available yet.',
            style: GoogleFonts.inter(color: _kTextMuted)),
      ));
    }

    final sections = ['Starters', 'Mains', 'Desserts', 'Drinks'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: sections.map((section) {
        final items = _menu.where((m) => m.section == section).toList();
        if (items.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(section, style: GoogleFonts.playfairDisplay(
                fontSize: 16, fontWeight: FontWeight.w700, color: _kTextTitle,
              )),
            ),
            ...items.map((item) => _MenuItemCard(item: item, userAllergens: _userAllergens)),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildNotVerified() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _kSoftBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kPrimary.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          const Icon(Icons.verified_outlined, size: 40, color: Color(0xFFC4748A)),
          const SizedBox(height: 12),
          Text('This restaurant is not yet ORKA verified.',
              textAlign: TextAlign.center,
              style: GoogleFonts.playfairDisplay(
                fontSize: 15, fontWeight: FontWeight.w700, color: _kTextTitle,
              )),
          const SizedBox(height: 8),
          Text('ORKA verified restaurants have full nutritional information and allergen tracking.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 13, color: _kTextBody)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: _kPrimary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.share_rounded, color: Colors.white, size: 18),
            label: Text('Share ORKA with them',
                style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
            onPressed: () async {
              await Clipboard.setData(const ClipboardData(text: 'https://orka-app.com/join'));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Link copied to clipboard!')),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}

// ── Menu Item Card ────────────────────────────────────────────────────────────
class _MenuItemCard extends StatelessWidget {
  final MenuItem item;
  final List<String> userAllergens;

  const _MenuItemCard({required this.item, required this.userAllergens});

  @override
  Widget build(BuildContext context) {
    final safe = item.isSafeFor(userAllergens);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: safe ? Colors.transparent : _kDanger.withValues(alpha: 0.3)),
        boxShadow: [BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 6, offset: const Offset(0, 2),
        )],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(item.name, style: GoogleFonts.inter(
                  fontSize: 14, fontWeight: FontWeight.w600, color: _kTextTitle,
                )),
              ),
              Text('${item.price.toStringAsFixed(2)} TND',
                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: _kPrimary)),
            ],
          ),
          if (item.calories != null) ...[
            const SizedBox(height: 6),
            Row(children: [
              _MacroChip(label: '${item.calories!.toInt()} kcal', color: const Color(0xFFFF6B8A)),
              if (item.protein != null) _MacroChip(label: '${item.protein!.toStringAsFixed(0)}g protein', color: const Color(0xFF45C4B0)),
              if (item.carbs != null) _MacroChip(label: '${item.carbs!.toStringAsFixed(0)}g carbs', color: const Color(0xFFFFB347)),
            ]),
          ],
          if (item.allergens.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(safe ? Icons.shield_rounded : Icons.warning_amber_rounded,
                    size: 14, color: safe ? _kFresh : _kDanger),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    safe ? 'Safe for you' : 'Contains: ${item.allergens.join(', ')}',
                    style: GoogleFonts.inter(
                      fontSize: 11, fontWeight: FontWeight.w500,
                      color: safe ? _kFresh : _kDanger,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _MacroChip extends StatelessWidget {
  final String label;
  final Color color;
  const _MacroChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label, style: GoogleFonts.inter(
        fontSize: 10, fontWeight: FontWeight.w600, color: color,
      )),
    );
  }
}
