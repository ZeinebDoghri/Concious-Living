import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_router.dart';
import 'core/constants.dart';
import 'firebase_options.dart';
import 'providers/alerts_provider.dart';
import 'providers/compost_provider.dart';
import 'providers/contamination_provider.dart';
import 'providers/hotel_expiry_alerts_provider.dart';
import 'providers/inventory_provider.dart';
import 'providers/scan_history_provider.dart';
import 'providers/user_provider.dart';
import 'providers/venue_type_provider.dart';
import 'shared/animations/role_animated_background.dart';
import 'theme/app_theme.dart';

const bool _seedData = false; // ← set to false after first run

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  if (kIsWeb) {
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: false,
    );
  }

  if (_seedData) await _seedRestaurants();

  runApp(const ConsciousLivingApp());
}

Future<void> _seedRestaurants() async {
  final col = FirebaseFirestore.instance.collection('restaurants');
  final existing = await col.limit(1).get();
  if (existing.docs.isNotEmpty) return;

  final restaurants = [
    {
      'name': 'Le Baroque',
      'cuisine': 'French-Tunisian Fusion',
      'address': 'Avenue Habib Bourguiba, Tunis',
      'city': 'Tunis',
      'lat': 36.8190, 'lng': 10.1658,
      'rating': 4.5, 'priceLevel': 3,
      'isOrkaVerified': true,
      'allergens': ['gluten', 'dairy'],
      'phone': '+216 71 000 001',
      'openNow': true,
      'photoUrl': '',
    },
    {
      'name': 'Dar El Jeld',
      'cuisine': 'Traditional Tunisian',
      'address': 'Rue Dar El Jeld, Médina, Tunis',
      'city': 'Tunis',
      'lat': 36.7992, 'lng': 10.1706,
      'rating': 4.8, 'priceLevel': 3,
      'isOrkaVerified': true,
      'allergens': ['nuts', 'gluten'],
      'phone': '+216 71 000 002',
      'openNow': true,
      'photoUrl': '',
    },
    {
      'name': 'Sidi Bou Grill',
      'cuisine': 'Grillades & Seafood',
      'address': 'Rue de la Plage, Sidi Bou Said',
      'city': 'Sidi Bou Said',
      'lat': 36.8699, 'lng': 10.3417,
      'rating': 4.3, 'priceLevel': 2,
      'isOrkaVerified': false,
      'allergens': ['shellfish', 'fish'],
      'phone': '+216 71 000 003',
      'openNow': true,
      'photoUrl': '',
    },
    {
      'name': 'La Marsa Café',
      'cuisine': 'Mediterranean',
      'address': 'Avenue du 14 Janvier, La Marsa',
      'city': 'La Marsa',
      'lat': 36.8779, 'lng': 10.3249,
      'rating': 4.1, 'priceLevel': 2,
      'isOrkaVerified': true,
      'allergens': ['dairy', 'eggs'],
      'phone': '+216 71 000 004',
      'openNow': false,
      'photoUrl': '',
    },
    {
      'name': 'Hammamet Garden',
      'cuisine': 'International Buffet',
      'address': 'Zone Touristique, Hammamet',
      'city': 'Hammamet',
      'lat': 36.3996, 'lng': 10.6126,
      'rating': 4.0, 'priceLevel': 2,
      'isOrkaVerified': false,
      'allergens': ['gluten', 'dairy', 'nuts'],
      'phone': '+216 72 000 001',
      'openNow': true,
      'photoUrl': '',
    },
    {
      'name': 'Sfax Poisson',
      'cuisine': 'Fresh Seafood',
      'address': 'Port de Sfax, Sfax',
      'city': 'Sfax',
      'lat': 34.7377, 'lng': 10.7601,
      'rating': 4.6, 'priceLevel': 2,
      'isOrkaVerified': true,
      'allergens': ['fish', 'shellfish'],
      'phone': '+216 74 000 001',
      'openNow': true,
      'photoUrl': '',
    },
    {
      'name': 'Green Bowl Tunis',
      'cuisine': 'Vegan & Healthy',
      'address': 'Rue du Lac Windermere, Les Berges du Lac, Tunis',
      'city': 'Tunis',
      'lat': 36.8399, 'lng': 10.2351,
      'rating': 4.4, 'priceLevel': 2,
      'isOrkaVerified': true,
      'allergens': <String>[],
      'phone': '+216 71 000 005',
      'openNow': true,
      'photoUrl': '',
    },
    {
      'name': 'Sousse Marina Lounge',
      'cuisine': 'Tapas & Cocktails',
      'address': 'Port El Kantaoui, Sousse',
      'city': 'Sousse',
      'lat': 35.8954, 'lng': 10.5956,
      'rating': 4.2, 'priceLevel': 3,
      'isOrkaVerified': false,
      'allergens': ['gluten', 'sulfites'],
      'phone': '+216 73 000 001',
      'openNow': false,
      'photoUrl': '',
    },
  ];

  for (final r in restaurants) {
    await col.add(r);
  }
}

class ConsciousLivingApp extends StatefulWidget {
  const ConsciousLivingApp({super.key});

  @override
  State<ConsciousLivingApp> createState() => _ConsciousLivingAppState();
}

class _ConsciousLivingAppState extends State<ConsciousLivingApp>
    with WidgetsBindingObserver {
  late final router = createAppRouter();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshOpenDate();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshOpenDate();
    }
  }

  Future<void> _refreshOpenDate() async {
    final prefs = await SharedPreferences.getInstance();
    final lastDate = prefs.getString('last_open_date');
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    if (lastDate != today) {
      await prefs.setString('last_open_date', today);
    }
  }

  AmbientRole _ambientRole(String role) {
    return switch (role) {
      'restaurant' => AmbientRole.restaurant,
      'hotel'      => AmbientRole.hotel,
      _            => AmbientRole.customer,
    };
  }

  int _ambientSeed(String role) {
    return switch (role) {
      'restaurant' => 2,
      'hotel'      => 4,
      _            => 1,
    };
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => VenueTypeProvider()..load()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProxyProvider<UserProvider, ScanHistoryProvider>(
          create: (_) => ScanHistoryProvider(),
          update: (_, userProvider, scanProvider) {
            final provider = scanProvider ?? ScanHistoryProvider();
            final authUid = FirebaseAuth.instance.currentUser?.uid;
            final userId = (userProvider.currentUser?.id ?? '').trim();
            provider.setUser(userId.isEmpty ? authUid : userId);
            return provider;
          },
        ),
        ChangeNotifierProxyProvider<UserProvider, AlertsProvider>(
          create: (_) => AlertsProvider(),
          update: (_, userProvider, alertsProvider) {
            final provider = alertsProvider ?? AlertsProvider();
            final user = userProvider.currentUser;
            if (user == null) {
              provider.setUserContext(role: 'customer', id: null);
              return provider;
            }

            final rawRole = user.role.trim().toLowerCase();
            final role = rawRole.isEmpty
              ? 'customer'
              : (rawRole == 'restaurant' || rawRole == 'hotel'
                  ? rawRole
                  : 'customer');
            final authUid = FirebaseAuth.instance.currentUser?.uid;
            final fallbackUserId = user.id.trim().isEmpty ? authUid : user.id;
            final scopeId = role == 'customer'
                ? fallbackUserId
                : (user.entityId ??
                      (role == 'restaurant' ? user.restaurantId : user.hotelId) ??
                      fallbackUserId);
            final normalizedScopeId = (scopeId ?? '').trim();
            provider.setUserContext(
              role: role,
              id: normalizedScopeId.isEmpty ? null : normalizedScopeId,
            );
            return provider;
          },
        ),
        ChangeNotifierProvider(create: (_) => InventoryProvider()),
        ChangeNotifierProvider(create: (_) => CompostProvider()),
        ChangeNotifierProvider(create: (_) => ContaminationProvider()),
        ChangeNotifierProvider(create: (_) => HotelExpiryAlertsProvider()),
      ],
      child: Consumer<VenueTypeProvider>(
        builder: (context, venueType, _) {
          final role = venueType.venueType.isEmpty
              ? 'customer'
              : venueType.venueType;
          return MaterialApp.router(
            title: AppStrings.appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme(role: role),
            routerConfig: router,
            builder: (context, child) => RoleAnimatedBackground(
              role: _ambientRole(role),
              activeIndex: _ambientSeed(role),
              intensity: 1.45,
              child: child ?? const SizedBox.shrink(),
            ),
          );
        },
      ),
    );
  }
}
