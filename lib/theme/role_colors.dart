import 'package:flutter/material.dart';

import 'brand_palette.dart';

export '../core/constants.dart' show AppColors, AppRadii, AppSpacing;

enum AppRole { customer, restaurant, hotel }

class RoleColorScheme {
  final AppRole role;
  final Color primary;
  final Color primaryDark;
  final Color secondary;
  final Color accent;
  final Color surface;
  final Color textDark;
  final Color textMuted;
  /// Bottom navigation selected item tint.
  final Color navSelected;

  const RoleColorScheme({
    required this.role,
    required this.primary,
    required this.primaryDark,
    required this.secondary,
    required this.accent,
    required this.surface,
    required this.textDark,
    required this.textMuted,
    required this.navSelected,
  });

  static const customer = RoleColorScheme(
    role: AppRole.customer,
    primary: kButterD,
    primaryDark: kButterDeep,
    secondary: kButter,
    accent: kButterDeep,
    surface: kOat,
    textDark: kEspresso,
    textMuted: kFog,
    navSelected: kButterD,
  );

  static const restaurant = RoleColorScheme(
    role: AppRole.restaurant,
    primary: kOlive,
    primaryDark: kOliveMid,
    secondary: kOliveM,
    accent: kOlive,
    surface: kOat,
    textDark: kEspresso,
    textMuted: kFog,
    navSelected: kOlive,
  );

  static const hotel = RoleColorScheme(
    role: AppRole.hotel,
    primary: kCherry,
    primaryDark: kCherryMid,
    secondary: kCherryB,
    accent: kCherryMid,
    surface: kOat,
    textDark: kEspresso,
    textMuted: kFog,
    navSelected: kCherry,
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

  LinearGradient get gradient {
    switch (role) {
      case AppRole.customer:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF8B6914),
            Color(0xFFB8860B),
            Color(0xFF5C4A1A),
          ],
        );
      case AppRole.restaurant:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF3A5010),
            Color(0xFF4F6815),
            Color(0xFF2D3D0F),
          ],
        );
      case AppRole.hotel:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF75070C),
            Color(0xFF9E1A21),
            Color(0xFF5C3D3F),
          ],
        );
    }
  }

  BoxShadow get softShadow => BoxShadow(
    color: kEspresso.withValues(alpha: 0.06),
    blurRadius: 12,
    offset: const Offset(0, 4),
  );

  BoxShadow get raisedShadow => BoxShadow(
    color: kEspresso.withValues(alpha: 0.08),
    blurRadius: 14,
    offset: const Offset(0, 6),
  );

  BoxShadow get glowShadow => BoxShadow(
    color: primary.withValues(alpha: 0.20),
    blurRadius: 16,
    offset: const Offset(0, 4),
  );
}

class RoleDecorations {
  static const sand = kSand;
  static const chipBg = kButter;
  static const error = kCherry;

  static BoxDecoration card(
    RoleColorScheme colors, {
    bool raised = false,
    Border? border,
    Color? color,
  }) {
    return BoxDecoration(
      color: color ?? kParchment,
      borderRadius: BorderRadius.circular(18),
      border: border ?? Border.all(color: kSand),
      boxShadow: [
        raised ? colors.raisedShadow : colors.softShadow,
      ],
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
      fillColor: kParchment,
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
