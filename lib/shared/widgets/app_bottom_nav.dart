import 'package:flutter/material.dart';
import '../../theme/role_colors.dart';

enum BottomNavRole { customer, restaurant, hotel }

/// Bottom navigation bar for the app
class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final BottomNavRole role;

  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.role,
  });

  List<BottomNavItem> _getNavItems() {
    switch (role) {
      case BottomNavRole.customer:
        return [
          BottomNavItem(
            icon: Icons.home_outlined,
            activeIcon: Icons.home,
            label: 'Home',
            index: 0,
          ),
          BottomNavItem(
            icon: Icons.camera_alt_outlined,
            activeIcon: Icons.camera_alt,
            label: 'Scan',
            index: 1,
          ),
          BottomNavItem(
            icon: Icons.favorite_outline,
            activeIcon: Icons.favorite,
            label: 'Health',
            index: 2,
          ),
          BottomNavItem(
            icon: Icons.person_outline,
            activeIcon: Icons.person,
            label: 'Profile',
            index: 3,
          ),
        ];
      case BottomNavRole.restaurant:
        return [
          BottomNavItem(
            icon: Icons.dashboard_outlined,
            activeIcon: Icons.dashboard,
            label: 'Dashboard',
            index: 0,
          ),
          BottomNavItem(
            icon: Icons.camera_alt_outlined,
            activeIcon: Icons.camera_alt,
            label: 'Scan',
            index: 1,
          ),
          BottomNavItem(
            icon: Icons.delete_outline,
            activeIcon: Icons.delete,
            label: 'Waste',
            index: 2,
          ),
          BottomNavItem(
            icon: Icons.person_outline,
            activeIcon: Icons.person,
            label: 'Profile',
            index: 3,
          ),
        ];
      case BottomNavRole.hotel:
        return [
          BottomNavItem(
            icon: Icons.dashboard_outlined,
            activeIcon: Icons.dashboard,
            label: 'Dashboard',
            index: 0,
          ),
          BottomNavItem(
            icon: Icons.camera_alt_outlined,
            activeIcon: Icons.camera_alt,
            label: 'Scan',
            index: 1,
          ),
          BottomNavItem(
            icon: Icons.people_outline,
            activeIcon: Icons.people,
            label: 'Guests',
            index: 2,
          ),
          BottomNavItem(
            icon: Icons.person_outline,
            activeIcon: Icons.person,
            label: 'Profile',
            index: 3,
          ),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = _getNavItems();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: items.map((item) {
              final isActive = currentIndex == item.index;
              return GestureDetector(
                onTap: () => onTap(item.index),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isActive ? item.activeIcon : item.icon,
                      color: isActive
                          ? AppColors.primary
                          : AppColors.textSecondary,
                      size: 24,
                    ),
                    if (isActive) ...[
                      const SizedBox(height: 2),
                      Text(
                        item.label,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class BottomNavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int index;

  BottomNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.index,
  });
}

/// Floating center scan button positioned above bottom nav
class FloatingCenterScanButtonWithNav extends StatelessWidget {
  final VoidCallback onPressed;
  final Widget? bottomNav;

  const FloatingCenterScanButtonWithNav({
    super.key,
    required this.onPressed,
    this.bottomNav,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ?bottomNav,
        Positioned(
          bottom: 32,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(4),
              child: FloatingActionButton(
                onPressed: onPressed,
                backgroundColor: AppColors.primary,
                elevation: 6,
                shape: const CircleBorder(),
                child: const Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
