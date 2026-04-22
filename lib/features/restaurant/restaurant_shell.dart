import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../providers/venue_type_provider.dart';

class RestaurantShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const RestaurantShell({super.key, required this.navigationShell});

  void _onTap(BuildContext context, int index) {
    if (index == 5) {
      final venueType = context.read<VenueTypeProvider>().venueType;
      context.go(venueType == 'hotel' ? AppRoutes.hotelProfile : AppRoutes.restaurantProfile);
      return;
    }

    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final index = navigationShell.currentIndex;
    final venueType = context.watch<VenueTypeProvider>().venueType;
    final isHotel = venueType == 'hotel';

    return Scaffold(
      backgroundColor: AppColors.oat,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeOutCubic,
        transitionBuilder: (child, anim) {
          return FadeTransition(opacity: anim, child: child);
        },
        child: KeyedSubtree(
          key: ValueKey(index),
          child: navigationShell,
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: index,
        onTap: (value) => _onTap(context, value),
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.parchment,
        selectedItemColor: AppColors.olive,
        unselectedItemColor: AppColors.cocoa,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: AppStrings.dashboard,
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.document_scanner_outlined),
            activeIcon: Icon(Icons.document_scanner),
            label: 'Scan',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.notifications_none),
            activeIcon: Icon(Icons.notifications),
            label: AppStrings.alerts,
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.delete_outline),
            activeIcon: Icon(Icons.delete),
            label: AppStrings.waste,
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2_outlined),
            activeIcon: Icon(Icons.inventory_2),
            label: AppStrings.inventory,
          ),
          BottomNavigationBarItem(
            icon: Icon(isHotel ? Icons.apartment_outlined : Icons.person_outline),
            activeIcon: Icon(isHotel ? Icons.apartment : Icons.person),
            label: isHotel ? AppStrings.hotel : AppStrings.profile,
          ),
        ],
      ),
    );
  }
}
