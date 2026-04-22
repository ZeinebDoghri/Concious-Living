import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'core/constants.dart';
import 'features/auth/customer/customer_forgot_password_screen.dart';
import 'features/auth/customer/customer_login_screen.dart';
import 'features/auth/customer/customer_profile_setup_screen.dart';
import 'features/auth/customer/customer_register_screen.dart';
import 'features/auth/hotel/hotel_forgot_password_screen.dart';
import 'features/auth/hotel/hotel_login_screen.dart';
import 'features/auth/hotel/hotel_register_screen.dart';
import 'features/auth/hotel/hotel_setup_screen.dart';
import 'features/auth/restaurant/restaurant_forgot_password_screen.dart';
import 'features/auth/restaurant/restaurant_login_screen.dart';
import 'features/auth/restaurant/restaurant_register_screen.dart';
import 'features/auth/restaurant/restaurant_setup_screen.dart';
import 'features/customer/allergens/allergen_screen.dart';
import 'features/customer/customer_shell.dart';
import 'features/customer/history/history_detail_screen.dart';
import 'features/customer/history/history_screen.dart';
import 'features/customer/home/home_screen.dart';
import 'features/customer/profile/health_goals_screen.dart';
import 'features/customer/profile/edit_profile_screen.dart';
import 'features/customer/profile/profile_screen.dart';
import 'features/customer/scan/result_screen.dart';
import 'features/customer/scan/scan_screen.dart';
import 'features/hotel/profile/edit_hotel_profile_screen.dart';
import 'features/hotel/profile/hotel_profile_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/restaurant/alerts/alert_detail_screen.dart';
import 'features/restaurant/alerts/alerts_screen.dart';
import 'features/restaurant/dashboard/dashboard_screen.dart';
import 'features/restaurant/inventory/inventory_item_screen.dart';
import 'features/restaurant/inventory/inventory_screen.dart';
import 'features/restaurant/profile/edit_restaurant_profile_screen.dart';
import 'features/restaurant/profile/restaurant_profile_screen.dart';
import 'features/restaurant/restaurant_shell.dart';
import 'features/restaurant/scan/staff_result_screen.dart';
import 'features/restaurant/scan/staff_scan_screen.dart';
import 'features/restaurant/waste/compost_screen.dart';
import 'features/restaurant/waste/waste_screen.dart';
import 'features/role_selector/role_selector_screen.dart';
import 'features/splash/splash_screen.dart';

CustomTransitionPage<T> slidePage<T>({
  required Widget child,
  LocalKey? key,
}) {
  return CustomTransitionPage<T>(
    key: key,
    transitionDuration: const Duration(milliseconds: 350),
    reverseTransitionDuration: const Duration(milliseconds: 350),
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      final tween = Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero);
      return SlideTransition(position: tween.animate(curved), child: child);
    },
  );
}

GoRouter createAppRouter() {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        pageBuilder: (context, state) => slidePage(child: const SplashScreen()),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        pageBuilder: (context, state) => slidePage(child: const OnboardingScreen()),
      ),
      GoRoute(
        path: AppRoutes.roleSelector,
        pageBuilder: (context, state) => slidePage(child: const RoleSelectorScreen()),
      ),

      GoRoute(
        path: AppRoutes.customerLogin,
        pageBuilder: (context, state) =>
            slidePage(child: const CustomerLoginScreen()),
      ),
      GoRoute(
        path: AppRoutes.customerRegister,
        pageBuilder: (context, state) =>
            slidePage(child: const CustomerRegisterScreen()),
      ),
      GoRoute(
        path: AppRoutes.customerForgot,
        pageBuilder: (context, state) =>
            slidePage(child: const CustomerForgotPasswordScreen()),
      ),
      GoRoute(
        path: AppRoutes.customerProfileSetup,
        pageBuilder: (context, state) {
          final extra = state.extra;
          final args = extra is Map<String, dynamic> ? extra : <String, dynamic>{};
          return slidePage(child: CustomerProfileSetupScreen(args: args));
        },
      ),

      GoRoute(
        path: AppRoutes.restaurantProfileEdit,
        pageBuilder: (context, state) => slidePage(child: const EditRestaurantProfileScreen()),
      ),
      GoRoute(
        path: AppRoutes.hotelProfileEdit,
        pageBuilder: (context, state) => slidePage(child: const EditHotelProfileScreen()),
      ),

      GoRoute(
        path: AppRoutes.restaurantLogin,
        pageBuilder: (context, state) =>
            slidePage(child: const RestaurantLoginScreen()),
      ),
      GoRoute(
        path: AppRoutes.restaurantRegister,
        pageBuilder: (context, state) =>
            slidePage(child: const RestaurantRegisterScreen()),
      ),
      GoRoute(
        path: AppRoutes.restaurantForgot,
        pageBuilder: (context, state) =>
            slidePage(child: const RestaurantForgotPasswordScreen()),
      ),
      GoRoute(
        path: AppRoutes.restaurantSetup,
        pageBuilder: (context, state) {
          final extra = state.extra;
          final args = extra is Map<String, dynamic> ? extra : <String, dynamic>{};
          return slidePage(child: RestaurantSetupScreen(args: args));
        },
      ),

      GoRoute(
        path: AppRoutes.hotelLogin,
        pageBuilder: (context, state) => slidePage(child: const HotelLoginScreen()),
      ),
      GoRoute(
        path: AppRoutes.hotelRegister,
        pageBuilder: (context, state) => slidePage(child: const HotelRegisterScreen()),
      ),
      GoRoute(
        path: AppRoutes.hotelForgotPassword,
        pageBuilder: (context, state) =>
            slidePage(child: const HotelForgotPasswordScreen()),
      ),
      GoRoute(
        path: AppRoutes.hotelSetup,
        pageBuilder: (context, state) {
          final extra = state.extra;
          final args = extra is Map<String, dynamic> ? extra : <String, dynamic>{};
          return slidePage(child: HotelSetupScreen(args: args));
        },
      ),

      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return CustomerShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.customerHome,
                pageBuilder: (context, state) =>
                    slidePage(child: const HomeScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.customerScan,
                pageBuilder: (context, state) =>
                    slidePage(child: const ScanScreen()),
              ),
              GoRoute(
                path: AppRoutes.customerResult,
                pageBuilder: (context, state) {
                  final extra = state.extra;
                  final args = extra is Map<String, dynamic> ? extra : <String, dynamic>{};
                  return slidePage(child: ResultScreen(args: args));
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.customerHistory,
                pageBuilder: (context, state) =>
                    slidePage(child: const HistoryScreen()),
              ),
              GoRoute(
                path: '/customer/history/:id',
                pageBuilder: (context, state) {
                  final id = state.pathParameters['id'] ?? '';
                  return slidePage(child: HistoryDetailScreen(id: id));
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.customerAllergens,
                pageBuilder: (context, state) =>
                    slidePage(child: const AllergenScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.customerProfile,
                pageBuilder: (context, state) =>
                    slidePage(child: const ProfileScreen()),
              ),
              GoRoute(
                path: AppRoutes.customerEditProfile,
                pageBuilder: (context, state) => slidePage(child: const EditProfileScreen()),
              ),
              GoRoute(
                path: AppRoutes.nutritionGoals,
                pageBuilder: (context, state) =>
                    slidePage(child: const HealthGoalsScreen()),
              ),
              GoRoute(
                path: AppRoutes.nutritionProgress,
                pageBuilder: (context, state) =>
                    slidePage(child: const HealthGoalsScreen()),
              ),
              GoRoute(
                path: AppRoutes.healthGoals,
                pageBuilder: (context, state) =>
                    slidePage(child: const HealthGoalsScreen()),
              ),
            ],
          ),
        ],
      ),

      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return RestaurantShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.restaurantDashboard,
                pageBuilder: (context, state) =>
                    slidePage(child: const DashboardScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.restaurantScan,
                pageBuilder: (context, state) =>
                    slidePage(child: const StaffScanScreen()),
              ),
              GoRoute(
                path: AppRoutes.restaurantScanResult,
                pageBuilder: (context, state) {
                  final extra = state.extra;
                  final args = extra is Map<String, dynamic>
                      ? extra
                      : <String, dynamic>{};
                  return slidePage(child: StaffResultScreen(args: args));
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.restaurantAlerts,
                pageBuilder: (context, state) =>
                    slidePage(child: const AlertsScreen()),
              ),
              GoRoute(
                path: '/restaurant/alert/:id',
                pageBuilder: (context, state) {
                  final id = state.pathParameters['id'] ?? '';
                  return slidePage(child: AlertDetailScreen(id: id));
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.restaurantWaste,
                pageBuilder: (context, state) =>
                    slidePage(child: const WasteScreen()),
              ),
              GoRoute(
                path: AppRoutes.restaurantCompost,
                pageBuilder: (context, state) =>
                    slidePage(child: const CompostScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.restaurantInventory,
                pageBuilder: (context, state) =>
                    slidePage(child: const InventoryScreen()),
              ),
              GoRoute(
                path: '/restaurant/inventory/:id',
                pageBuilder: (context, state) {
                  final id = state.pathParameters['id'] ?? '';
                  return slidePage(child: InventoryItemScreen(id: id));
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.restaurantProfile,
                pageBuilder: (context, state) =>
                    slidePage(child: const RestaurantProfileScreen()),
              ),
              GoRoute(
                path: AppRoutes.hotelProfile,
                pageBuilder: (context, state) =>
                    slidePage(child: const HotelProfileScreen()),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
