import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';

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

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  if (kIsWeb) {
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: false,
    );
  }

  runApp(const ConsciousLivingApp());
}

class ConsciousLivingApp extends StatefulWidget {
  const ConsciousLivingApp({super.key});

  @override
  State<ConsciousLivingApp> createState() => _ConsciousLivingAppState();
}

class _ConsciousLivingAppState extends State<ConsciousLivingApp> {
  late final router = createAppRouter();

  // ✅ Providers instanciés une seule fois pour y accéder dans initState
  final _venueTypeProvider     = VenueTypeProvider()..load();
  final _userProvider          = UserProvider();
  final _scanHistoryProvider   = ScanHistoryProvider();
  final _alertsProvider        = AlertsProvider();
  final _inventoryProvider     = InventoryProvider();
  final _compostProvider       = CompostProvider();
  final _contaminationProvider = ContaminationProvider();
  final _hotelExpiryAlertsProvider = HotelExpiryAlertsProvider();

  @override
  void initState() {
    super.initState();

    // ✅ Démarre / arrête les streams Firestore selon l'état d'auth
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        // Inventory : stream temps réel sur users/{uid}/inventory/
        _inventoryProvider.listenToUserInventory(user.uid);
        // Alerts : stream temps réel sur les alertes du venue
        _alertsProvider.setVenueId(user.uid);
      } else {
        // Déconnexion → vide tout
        _inventoryProvider.clear();
        _alertsProvider.setVenueId(null);
      }
    });
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
        ChangeNotifierProvider.value(value: _venueTypeProvider),
        ChangeNotifierProvider.value(value: _userProvider),
        ChangeNotifierProvider.value(value: _scanHistoryProvider),
        ChangeNotifierProvider.value(value: _alertsProvider),
        ChangeNotifierProvider.value(value: _inventoryProvider),
        ChangeNotifierProvider.value(value: _compostProvider),
        ChangeNotifierProvider.value(value: _contaminationProvider),
        ChangeNotifierProvider.value(value: _hotelExpiryAlertsProvider),
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
