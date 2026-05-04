import 'dart:math';
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants.dart';
import '../core/firebase_service.dart';
import '../core/models/user_model.dart';

class UserProvider extends ChangeNotifier {
  UserModel? currentUser;
  bool isLoading = false;

  StreamSubscription<User?>? _authSub;

  double cholesterolGoal = AppLimits.cholesterol;
  double saturatedFatGoal = AppLimits.saturatedFat;
  double sodiumGoal = AppLimits.sodium;
  double sugarGoal = AppLimits.sugar;

  UserProvider() {
    _authSub = FirebaseAuth.instance.authStateChanges().listen(_onAuthChanged);
  }

  void _logError(String context, Object error, [StackTrace? stackTrace]) {
    if (!kDebugMode) return;

    if (error is FirebaseException) {
      debugPrint(
        '[$context] FirebaseException(plugin=${error.plugin}, code=${error.code}): ${error.message}',
      );
    } else {
      debugPrint('[$context] $error');
    }
    if (stackTrace != null) {
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<String> _roleFallbackFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final venueType = prefs.getString(PrefKeys.venueType) ?? '';
      if (venueType == 'restaurant' || venueType == 'hotel') return venueType;
    } catch (_) {
      // Ignore prefs failures and fall back to customer.
    }
    return 'customer';
  }

  bool _isProbablyTransientFirestoreError(Object error) {
    if (error is TimeoutException) return true;
    if (error is FirebaseException && error.plugin == 'cloud_firestore') {
      return error.code == 'unavailable' || error.code == 'deadline-exceeded';
    }
    return false;
  }

  void _saveUserInBackground(UserModel user) {
    () async {
      try {
        await FirebaseService.saveUser(user);
      } catch (e, st) {
        _logError('UserProvider.background saveUser failed', e, st);
      }
    }();
  }

  void _loadUserInBackground(String uid) {
    () async {
      try {
        final loaded = await FirebaseService.getUser(uid);
        if (loaded == null) return;
        currentUser = loaded;
        notifyListeners();
      } catch (e, st) {
        _logError('UserProvider.background getUser failed', e, st);
      }
    }();
  }

  String _friendlyFirebaseError(Object error) {
    if (error is TimeoutException) {
      return 'Request timed out. This is usually a network/CORS/firewall issue on Web. Check your connection, disable ad blockers for localhost, and verify Firebase authorized domains.';
    }
    if (error is FirebaseAuthException) {
      return _friendlyAuthError(error);
    }
    if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
          return 'Permission denied. Check your Firestore security rules to allow creating/updating `users/{uid}` for the signed-in user.';
        case 'unauthenticated':
          return 'You are not authenticated. Please sign in again.';
        case 'unavailable':
          return 'Firebase is temporarily unavailable. Please try again.';
        case 'failed-precondition':
          return 'Firebase is not ready for this operation (failed precondition). For Firestore, ensure the database is created and in the correct mode.';
        case 'not-found':
          return 'Requested Firebase resource was not found.';
        case 'invalid-argument':
          return 'Invalid data sent to Firebase.';
        default:
          return error.message ?? 'Firebase error: ${error.code}';
      }
    }

    final message = error.toString();
    if (message.contains('Failed to fetch') ||
        message.contains('XMLHttpRequest')) {
      return 'Network error. Please check your connection and try again.';
    }
    return message;
  }

  String _friendlyAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-api-key':
        return 'Invalid Firebase API key for this app. Re-run FlutterFire config and ensure your `firebase_options.dart` matches the correct Firebase project.';
      case 'app-not-authorized':
        return 'This app is not authorized to use Firebase. For Web, verify your `authDomain` and make sure the domain is listed in Firebase Console → Authentication → Settings → Authorized domains.';
      case 'configuration-not-found':
        return 'Firebase Authentication is not configured for this project. In Firebase Console → Authentication → Get started → Sign-in method, enable Email/Password. For Web, also ensure the correct project is selected and localhost is an authorized domain.';
      case 'operation-not-allowed':
        return 'Email/Password sign-in is disabled for this Firebase project. Enable it in Firebase Console → Authentication → Sign-in method.';
      case 'unauthorized-domain':
        return 'This domain is not authorized for Firebase Auth. In Firebase Console → Authentication → Settings → Authorized domains, add your dev domain (e.g. localhost).';
      case 'email-already-in-use':
        return 'This email is already in use.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password is too weak (minimum 6 characters).';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Please check your connection and try again.';
      default:
        return e.message ?? 'Authentication error: ${e.code}';
    }
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  Future<void> _onAuthChanged(User? user) async {
    if (user == null) {
      currentUser = null;
      notifyListeners();
      return;
    }

    if (kIsWeb) {
      UserModel? loaded;
      try {
        loaded = await FirebaseService.getUser(user.uid);
      } catch (e, st) {
        _logError('UserProvider._onAuthChanged web getUser failed', e, st);
        loaded = null;
      }

      if (loaded != null) {
        currentUser = loaded;
      } else {
        final role = await _roleFallbackFromPrefs();
        currentUser = UserModel(
          id: user.uid,
          name:
              user.displayName ??
              (role == 'restaurant'
                  ? 'Restaurant Manager'
                  : role == 'hotel'
                  ? 'Hotel Manager'
                  : ''),
          email: user.email ?? '',
          conditions: const <String>[],
          allergens: const <String>[],
          calorieGoal: 2200,
          role: role,
          notifyDailyIntake: true,
          notifyAllergens: true,
          notifyWeeklyReport: true,
        );
      }
      notifyListeners();

      return;
    }

    UserModel? loaded;
    try {
      loaded = await FirebaseService.getUser(user.uid);
    } catch (e, st) {
      _logError('UserProvider._onAuthChanged getUser failed', e, st);
      loaded = null;
    }
    if (loaded != null) {
      currentUser = loaded;
    } else {
      final role = await _roleFallbackFromPrefs();
      currentUser = UserModel(
        id: user.uid,
        name:
            user.displayName ??
            (role == 'restaurant'
                ? 'Restaurant Manager'
                : role == 'hotel'
                ? 'Hotel Manager'
                : ''),
        email: user.email ?? '',
        conditions: const <String>[],
        allergens: const <String>[],
        calorieGoal: 2200,
        role: role,
        notifyDailyIntake: true,
        notifyAllergens: true,
        notifyWeeklyReport: true,
      );
    }

    notifyListeners();
  }

  Future<UserModel> login({
    required String email,
    required String password,
    required String role,
  }) async {
    isLoading = true;
    notifyListeners();

    late final UserCredential cred;
    try {
      cred = await FirebaseService.loginWithEmail(email, password);
    } on FirebaseAuthException catch (e, st) {
      _logError(
        'UserProvider.login auth error: ${e.code}: ${e.message ?? ''}',
        e,
        st,
      );
      isLoading = false;
      notifyListeners();
      throw Exception(_friendlyAuthError(e));
    } catch (e, st) {
      _logError('UserProvider.login auth failed', e, st);
      isLoading = false;
      notifyListeners();
      throw Exception(_friendlyFirebaseError(e));
    }
    final uid = cred.user?.uid;
    if (uid == null) {
      isLoading = false;
      notifyListeners();
      throw StateError('Login failed: missing user id');
    }

    if (kIsWeb) {
      final user = UserModel(
        id: uid,
        name: role == 'restaurant'
            ? 'Restaurant Manager'
            : role == 'hotel'
            ? 'Hotel Manager'
            : '',
        email: email,
        conditions: const <String>[],
        allergens: const <String>[],
        calorieGoal: 2200,
        role: role,
        notifyDailyIntake: true,
        notifyAllergens: true,
        notifyWeeklyReport: true,
      );

      currentUser = user;
      isLoading = false;
      notifyListeners();

      _loadUserInBackground(uid);
      return user;
    }

    UserModel? loaded;
    try {
      loaded = await FirebaseService.getUser(uid);
    } catch (e, st) {
      _logError('UserProvider.login getUser failed', e, st);
      loaded = null;
    }
    final user =
        loaded ??
        UserModel(
          id: uid,
          name: role == 'restaurant'
              ? 'Restaurant Manager'
              : role == 'hotel'
              ? 'Hotel Manager'
              : '',
          email: email,
          conditions: const <String>[],
          allergens: const <String>[],
          calorieGoal: 2200,
          role: role,
          notifyDailyIntake: true,
          notifyAllergens: true,
          notifyWeeklyReport: true,
        );

    currentUser = user;
    if (loaded == null) {
      try {
        await FirebaseService.saveUser(user);
      } catch (e, st) {
        _logError('UserProvider.login saveUser failed', e, st);
        // On Web, allow login to continue even if Firestore is temporarily unreachable.
        if (!_isProbablyTransientFirestoreError(e)) {
          isLoading = false;
          notifyListeners();
          throw Exception(_friendlyFirebaseError(e));
        }
      }
    }

    isLoading = false;
    notifyListeners();
    return user;
  }

  Future<UserModel> registerCustomer({
    required String name,
    required String email,
    required String password,
  }) async {
    isLoading = true;
    notifyListeners();

    late final UserCredential cred;
    try {
      cred = await FirebaseService.registerWithEmail(email, password);
    } on FirebaseAuthException catch (e, st) {
      _logError(
        'UserProvider.registerCustomer auth error: ${e.code}: ${e.message ?? ''}',
        e,
        st,
      );
      isLoading = false;
      notifyListeners();
      throw Exception(_friendlyAuthError(e));
    } catch (e, st) {
      _logError('UserProvider.registerCustomer auth failed', e, st);
      isLoading = false;
      notifyListeners();
      throw Exception(_friendlyFirebaseError(e));
    }
    final uid = cred.user?.uid;
    if (uid == null) {
      isLoading = false;
      notifyListeners();
      throw StateError('Registration failed: missing user id');
    }

    final user = UserModel(
      id: uid,
      name: name,
      email: email,
      conditions: const <String>[],
      allergens: const <String>[],
      calorieGoal: 2200,
      role: 'customer',
      notifyDailyIntake: true,
      notifyAllergens: true,
      notifyWeeklyReport: true,
    );

    if (kIsWeb) {
      currentUser = user;
      isLoading = false;
      notifyListeners();
      _saveUserInBackground(user);
      return user;
    }

    try {
      await FirebaseService.saveUser(user);
    } catch (e, st) {
      _logError('UserProvider.registerCustomer saveUser failed', e, st);
      // Allow account creation to proceed even if Firestore profile sync fails.
      if (!_isProbablyTransientFirestoreError(e)) {
        isLoading = false;
        notifyListeners();
        throw Exception(_friendlyFirebaseError(e));
      }
    }
    currentUser = user;

    isLoading = false;
    notifyListeners();
    return user;
  }

  Future<UserModel> registerRestaurant({
    required String restaurantName,
    required String managerName,
    required String email,
    required String phone,
    required String password,
  }) async {
    isLoading = true;
    notifyListeners();

    late final UserCredential cred;
    try {
      cred = await FirebaseService.registerWithEmail(email, password);
    } on FirebaseAuthException catch (e, st) {
      _logError(
        'UserProvider.registerRestaurant auth error: ${e.code}: ${e.message ?? ''}',
        e,
        st,
      );
      isLoading = false;
      notifyListeners();
      throw Exception(_friendlyAuthError(e));
    } catch (e, st) {
      _logError('UserProvider.registerRestaurant auth failed', e, st);
      isLoading = false;
      notifyListeners();
      throw Exception(_friendlyFirebaseError(e));
    }
    final uid = cred.user?.uid;
    if (uid == null) {
      isLoading = false;
      notifyListeners();
      throw StateError('Registration failed: missing user id');
    }

    final user = UserModel(
      id: uid,
      name: managerName,
      email: email,
      conditions: const <String>[],
      allergens: const <String>[],
      calorieGoal: 2200,
      role: 'restaurant',
      notifyDailyIntake: true,
      notifyAllergens: true,
      notifyWeeklyReport: true,
      restaurantName: restaurantName,
      cuisineType: null,
      teamSize: null,
    );

    if (kIsWeb) {
      currentUser = user;
      isLoading = false;
      notifyListeners();
      _saveUserInBackground(user);
      return user;
    }

    try {
      await FirebaseService.saveUser(user);
    } catch (e, st) {
      _logError('UserProvider.registerRestaurant saveUser failed', e, st);
      // Allow account creation to proceed even if Firestore profile sync fails.
      if (!_isProbablyTransientFirestoreError(e)) {
        isLoading = false;
        notifyListeners();
        throw Exception(_friendlyFirebaseError(e));
      }
    }
    currentUser = user;

    isLoading = false;
    notifyListeners();
    return user;
  }

  Future<UserModel> registerHotel({
    required String hotelName,
    required String managerName,
    required String email,
    required String phone,
    required String password,
  }) async {
    isLoading = true;
    notifyListeners();

    late final UserCredential cred;
    try {
      cred = await FirebaseService.registerWithEmail(email, password);
    } on FirebaseAuthException catch (e, st) {
      _logError(
        'UserProvider.registerHotel auth error: ${e.code}: ${e.message ?? ''}',
        e,
        st,
      );
      isLoading = false;
      notifyListeners();
      throw Exception(_friendlyAuthError(e));
    } catch (e, st) {
      _logError('UserProvider.registerHotel auth failed', e, st);
      isLoading = false;
      notifyListeners();
      throw Exception(_friendlyFirebaseError(e));
    }
    final uid = cred.user?.uid;
    if (uid == null) {
      isLoading = false;
      notifyListeners();
      throw StateError('Registration failed: missing user id');
    }

    final user = UserModel(
      id: uid,
      name: managerName,
      email: email,
      conditions: const <String>[],
      allergens: const <String>[],
      calorieGoal: 2200,
      role: 'hotel',
      notifyDailyIntake: true,
      notifyAllergens: true,
      notifyWeeklyReport: true,
      hotelName: hotelName,
    );

    if (kIsWeb) {
      currentUser = user;
      isLoading = false;
      notifyListeners();
      _saveUserInBackground(user);
      return user;
    }

    try {
      await FirebaseService.saveUser(user);
    } catch (e, st) {
      _logError('UserProvider.registerHotel saveUser failed', e, st);
      // Allow account creation to proceed even if Firestore profile sync fails.
      if (!_isProbablyTransientFirestoreError(e)) {
        isLoading = false;
        notifyListeners();
        throw Exception(_friendlyFirebaseError(e));
      }
    }
    currentUser = user;

    isLoading = false;
    notifyListeners();
    return user;
  }

  Future<void> saveProfile(UserModel user) async {
    currentUser = user;
    notifyListeners();

    // Web: don't block the UI on Firestore.
    if (kIsWeb) {
      _saveUserInBackground(user);
      return;
    }

    await FirebaseService.saveUser(user);
  }

  Future<void> updateNutrientGoals({
    required double cholesterol,
    required double saturatedFat,
    required double sodium,
    required double sugar,
  }) async {
    cholesterolGoal = cholesterol;
    saturatedFatGoal = saturatedFat;
    sodiumGoal = sodium;
    sugarGoal = sugar;

    notifyListeners();
  }

  Future<void> logout() async {
    await FirebaseService.signOut();
    currentUser = null;
    notifyListeners();
  }

  Map<String, double> get mockDailyIntakePct {
    // MOCK DATA: deterministic daily values based on day + user id
    final daySeed = DateTime.now().day;
    final userSeed = (currentUser?.id.hashCode ?? 17);
    final rnd = Random(daySeed * 997 + userSeed);

    double pct(double min, double max) => min + rnd.nextDouble() * (max - min);

    return {
      'cholesterol': pct(18, 78),
      'saturatedFat': pct(12, 85),
      'sodium': pct(22, 92),
      'sugar': pct(15, 88),
    };
  }
}
