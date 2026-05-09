import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants.dart' hide AppColors;
import '../../theme/role_colors.dart';

class GlobalBackButtonOverlay extends StatefulWidget {
  final GoRouter router;
  final Widget child;

  const GlobalBackButtonOverlay({
    super.key,
    required this.router,
    required this.child,
  });

  @override
  State<GlobalBackButtonOverlay> createState() =>
      _GlobalBackButtonOverlayState();
}

class _GlobalBackButtonOverlayState extends State<GlobalBackButtonOverlay> {
  late String _path = _currentPath();
  bool _pathUpdateScheduled = false;

  @override
  void initState() {
    super.initState();
    widget.router.routerDelegate.addListener(_handleRouterChanged);
  }

  @override
  void didUpdateWidget(covariant GlobalBackButtonOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.router == widget.router) return;

    oldWidget.router.routerDelegate.removeListener(_handleRouterChanged);
    widget.router.routerDelegate.addListener(_handleRouterChanged);
    _handleRouterChanged();
  }

  @override
  void dispose() {
    widget.router.routerDelegate.removeListener(_handleRouterChanged);
    super.dispose();
  }

  String _currentPath() {
    return widget.router.routerDelegate.currentConfiguration.uri.path;
  }

  void _handleRouterChanged() {
    if (_pathUpdateScheduled) return;

    _pathUpdateScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pathUpdateScheduled = false;
      if (!mounted) return;

      final nextPath = _currentPath();
      if (nextPath == _path) return;

      setState(() => _path = nextPath);
    });
  }

  @override
  Widget build(BuildContext context) {
    final visible = !_hideOn(_path);

    return Stack(
      children: [
        widget.child,
        if (visible)
          Positioned(
            top: MediaQuery.paddingOf(context).top + 8,
            left: 12,
            child: _BackButton(onPressed: () => _goBack(_path)),
          ),
      ],
    );
  }

  bool _hideOn(String path) {
    return path == AppRoutes.splash || path == AppRoutes.onboarding;
  }

  void _goBack(String path) {
    if (widget.router.canPop()) {
      widget.router.pop();
      return;
    }

    widget.router.go(_fallbackFor(path));
  }

  String _fallbackFor(String path) {
    if (path == AppRoutes.roleSelector) {
      return AppRoutes.onboarding;
    }

    if (path.startsWith('/auth/customer')) {
      if (path == AppRoutes.customerLogin) {
        return AppRoutes.roleSelector;
      }
      if (path == AppRoutes.customerRegister) {
        return AppRoutes.customerLogin;
      }
      if (path == AppRoutes.customerForgot) {
        return AppRoutes.customerLogin;
      }
      if (path == AppRoutes.customerProfileSetup) {
        return AppRoutes.customerRegister;
      }
    }

    if (path.startsWith('/auth/restaurant')) {
      if (path == AppRoutes.restaurantLogin) {
        return AppRoutes.roleSelector;
      }
      if (path == AppRoutes.restaurantRegister) {
        return AppRoutes.restaurantLogin;
      }
      if (path == AppRoutes.restaurantForgot) {
        return AppRoutes.restaurantLogin;
      }
      if (path == AppRoutes.restaurantSetup) {
        return AppRoutes.restaurantRegister;
      }
    }

    if (path.startsWith('/auth/hotel')) {
      if (path == AppRoutes.hotelLogin) {
        return AppRoutes.roleSelector;
      }
      if (path == AppRoutes.hotelRegister) {
        return AppRoutes.hotelLogin;
      }
      if (path == AppRoutes.hotelForgotPassword) {
        return AppRoutes.hotelLogin;
      }
      if (path == AppRoutes.hotelSetup) {
        return AppRoutes.hotelRegister;
      }
    }

    if (path.startsWith('/customer/history/') &&
        path != AppRoutes.customerHistory) {
      return AppRoutes.customerHistory;
    }
    if (path == AppRoutes.customerResult) {
      return AppRoutes.customerScan;
    }
    if (path == AppRoutes.customerScan ||
        path == AppRoutes.customerHistory ||
        path == AppRoutes.customerAllergens ||
        path == AppRoutes.nutritionGoals ||
        path == AppRoutes.nutritionProgress ||
        path == AppRoutes.healthGoals) {
      return AppRoutes.customerHome;
    }
    if (path == AppRoutes.customerEditProfile) {
      return AppRoutes.customerProfile;
    }
    if (path.startsWith('/customer')) {
      return AppRoutes.roleSelector;
    }

    if (path.startsWith('/restaurant/alert/') &&
        path != AppRoutes.restaurantAlerts) {
      return AppRoutes.restaurantAlerts;
    }
    if (path.startsWith('/restaurant/inventory/') &&
        path != AppRoutes.restaurantInventory) {
      return AppRoutes.restaurantInventory;
    }
    if (path == AppRoutes.restaurantScanResult) {
      return AppRoutes.restaurantScan;
    }
    if (path == AppRoutes.restaurantContaminationResult) {
      return AppRoutes.restaurantContaminationScan;
    }
    if (path == AppRoutes.restaurantProfileEdit) {
      return AppRoutes.restaurantProfile;
    }
    if (path == AppRoutes.restaurantCompost) {
      return AppRoutes.restaurantWaste;
    }
    if (path == AppRoutes.restaurantDashboard) {
      return AppRoutes.roleSelector;
    }
    if (path == AppRoutes.restaurantExpiryDate ||
        path == AppRoutes.restaurantFreshnessCheck ||
        path == AppRoutes.restaurantContaminationScan) {
      return AppRoutes.restaurantScan;
    }
    if (path.startsWith('/restaurant') ||
        path == AppRoutes.restaurantExpiryDate) {
      return AppRoutes.restaurantDashboard;
    }

    if (path == AppRoutes.hotelScanResult) {
      return AppRoutes.hotelScan;
    }
    if (path == AppRoutes.hotelContaminationResult) {
      return AppRoutes.hotelContaminationScan;
    }
    if (path == AppRoutes.hotelProfileEdit) {
      return AppRoutes.hotelProfile;
    }
    if (path == AppRoutes.hotelScan ||
        path == AppRoutes.hotelContaminationScan ||
        path == AppRoutes.hotelExpiryDate) {
      return AppRoutes.hotelDashboard;
    }
    if (path.startsWith('/hotel')) {
      return AppRoutes.roleSelector;
    }

    return AppRoutes.roleSelector;
  }
}

class _BackButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _BackButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Retour',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.cardBackground.withValues(alpha: 0.94),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.borderLight),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.10),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: const Icon(
              Icons.arrow_back_rounded,
              color: AppColors.primary,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }
}
