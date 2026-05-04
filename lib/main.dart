import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';

import 'app_router.dart';
import 'core/constants.dart';
import 'firebase_options.dart';
import 'providers/alerts_provider.dart';
import 'providers/compost_provider.dart';
import 'providers/inventory_provider.dart';
import 'providers/scan_history_provider.dart';
import 'providers/user_provider.dart';
import 'providers/venue_type_provider.dart';
import 'theme/app_theme.dart';
import 'features/customer/allergens/allergy_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // On Web, IndexedDB persistence can hang/fail depending on browser settings,
  // extensions, or storage policies. Disable it to avoid infinite spinners.
  if (kIsWeb) {
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: false,
    );
  }

  // Wake up the HuggingFace Space early so it's ready when user scans
  AllergyService().warmUpApi();

  runApp(const ConsciousLivingApp());
}

class ConsciousLivingApp extends StatefulWidget {
  const ConsciousLivingApp({super.key});

  @override
  State<ConsciousLivingApp> createState() => _ConsciousLivingAppState();
}

class _ConsciousLivingAppState extends State<ConsciousLivingApp> {
  late final router = createAppRouter();

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => VenueTypeProvider()..load()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => ScanHistoryProvider()),
        ChangeNotifierProvider(create: (_) => AlertsProvider()),
        ChangeNotifierProvider(create: (_) => InventoryProvider()),
        ChangeNotifierProvider(create: (_) => CompostProvider()),
      ],
      child: MaterialApp.router(
        title: AppStrings.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme(),
        routerConfig: router,
      ),
    );
  }
}