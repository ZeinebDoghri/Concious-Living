import 'package:flutter/material.dart';

enum AppRole { customer, restaurant, hotel }

/// Unified color system for the entire Conscious Living app
class AppColors {
  // Background
  static const Color backgroundColor = Color(0xFFF5F0E8);

  // Primary accent
  static const Color primary = Color(0xFF8B1A1A);

  // Secondary accent
  static const Color secondary = Color(0xFFE8A020);

  // Card backgrounds
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color cardBackgroundAlt = Color(0xFFFAF7F2);

  // Text colors
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B6B6B);

  // Status colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color danger = Color(0xFFD32F2F);

  // Borders and dividers
  static const Color borderLight = Color(0xFFE0E0E0);
  static const Color divider = Color(0xFFE8DDD2);
}

class RoleColorScheme {
  final AppRole role;
  final Color primary;
  final Color primaryDark;
  final Color secondary;
  final Color accent;
  final Color surface;
  final Color textDark;
  final Color textMuted;

  const RoleColorScheme({
    required this.role,
    required this.primary,
    required this.primaryDark,
    required this.secondary,
    required this.accent,
    required this.surface,
    required this.textDark,
    required this.textMuted,
  });

  // All roles now use the unified color scheme
  static const customer = RoleColorScheme(
    role: AppRole.customer,
    primary: AppColors.primary,
    primaryDark: Color(0xFF6B1515),
    secondary: AppColors.backgroundColor,
    accent: AppColors.secondary,
    surface: AppColors.cardBackground,
    textDark: AppColors.textPrimary,
    textMuted: AppColors.textSecondary,
  );

  static const restaurant = RoleColorScheme(
    role: AppRole.restaurant,
    primary: AppColors.primary,
    primaryDark: Color(0xFF6B1515),
    secondary: AppColors.backgroundColor,
    accent: AppColors.secondary,
    surface: AppColors.cardBackground,
    textDark: AppColors.textPrimary,
    textMuted: AppColors.textSecondary,
  );

  static const hotel = RoleColorScheme(
    role: AppRole.hotel,
    primary: AppColors.primary,
    primaryDark: Color(0xFF6B1515),
    secondary: AppColors.backgroundColor,
    accent: AppColors.secondary,
    surface: AppColors.cardBackground,
    textDark: AppColors.textPrimary,
    textMuted: AppColors.textSecondary,
  );

  static RoleColorScheme of(AppRole role) {
    switch (role) {
      case AppRole.customer:
        return customer;
      case AppRole.restaurant:
        return restaurant;
      case AppRole.hotel:
        return hotel;
    }
  }

  LinearGradient get gradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryDark],
  );

  BoxShadow get softShadow => BoxShadow(
    color: Colors.black12,
    blurRadius: 8,
    offset: const Offset(0, 2),
  );

  BoxShadow get raisedShadow => BoxShadow(
    color: Colors.black12,
    blurRadius: 12,
    offset: const Offset(0, 4),
  );

  BoxShadow get glowShadow => BoxShadow(
    color: primary.withValues(alpha: 0.20),
    blurRadius: 16,
    offset: const Offset(0, 4),
  );
}

class RoleDecorations {
  static const sand = Color(0xFFE8DDD2);
  static const chipBg = Color(0xFFF7F2EC);
  static const error = Color(0xFFD32F2F);

  static BoxDecoration card(
    RoleColorScheme colors, {
    bool raised = false,
    Border? border,
    Color? color,
  }) {
    return BoxDecoration(
      color: color ?? colors.surface,
      borderRadius: BorderRadius.circular(16),
      border: border ?? Border.all(color: sand, width: 0.5),
      boxShadow: [raised ? colors.raisedShadow : colors.softShadow],
    );
  }

  static InputDecoration input(RoleColorScheme colors, {String? hintText}) {
    OutlineInputBorder border(Color color, double width) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: color, width: width),
    );

    return InputDecoration(
      hintText: hintText,
      filled: true,
      fillColor: colors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: border(sand, 0.8),
      enabledBorder: border(sand, 0.8),
      focusedBorder: border(colors.primary, 1.5),
      errorBorder: border(error, 1),
      focusedErrorBorder: border(error, 1),
    );
  }
}

class RoleColors {
  static const customerPrimary = Color(0xFF4A7C59);
  static const customerPrimaryDark = Color(0xFF2F5C3A);
  static const customerSecondary = Color(0xFFF5EFE0);
  static const customerAccent = Color(0xFFE8A87C);
  static const customerSurface = Color(0xFFFDFAF5);
  static const customerTextDark = Color(0xFF2C3E2D);
  static const customerTextMuted = Color(0xFF8A9E8B);

  static const restaurantPrimary = Color(0xFF8B1A1F);
  static const restaurantPrimaryDark = Color(0xFF6B1215);
  static const restaurantSecondary = Color(0xFFFDF6EC);
  static const restaurantAccent = Color(0xFFD4956A);
  static const restaurantSurface = Color(0xFFFFFEF9);
  static const restaurantTextDark = Color(0xFF2C1A1B);
  static const restaurantTextMuted = Color(0xFF9E7E7F);

  static const hotelPrimary = Color(0xFF5A7A18);
  static const hotelPrimaryDark = Color(0xFF3D5510);
  static const hotelSecondary = Color(0xFFF4F1E8);
  static const hotelAccent = Color(0xFFB8A96A);
  static const hotelSurface = Color(0xFFFEFDF8);
  static const hotelTextDark = Color(0xFF2A2E1A);
  static const hotelTextMuted = Color(0xFF8A8E6A);

  static const cardBorder = RoleDecorations.sand;
  static const divider = RoleDecorations.sand;
  static const errorBorder = RoleDecorations.error;
  static const riskModerate = Color(0xFFB7791F);

  static const customerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [customerPrimary, customerPrimaryDark],
  );

  static const restaurantGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [restaurantPrimary, restaurantPrimaryDark],
  );

  static const hotelGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [hotelPrimary, hotelPrimaryDark],
  );
}
