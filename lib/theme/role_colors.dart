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
    primary: kCust1,
    primaryDark: kCust2,
    secondary: kCust4,
    accent: kCust2,
    surface: kCust3,
    textDark: kCustText,
    textMuted: Color(0xFF8C7E78),
    navSelected: kCust2,
  );

  static const restaurant = RoleColorScheme(
    role: AppRole.restaurant,
    primary: kRest1,
    primaryDark: kRest2,
    secondary: kRest4,
    accent: kRest2,
    surface: kRest3,
    textDark: kRestText,
    textMuted: Color(0xFF8C7E78),
    navSelected: kRest2,
  );

  static const hotel = RoleColorScheme(
    role: AppRole.hotel,
    primary: kHotel1,
    primaryDark: kHotel2,
    secondary: kHotel4,
    accent: kHotel2,
    surface: kHotel3,
    textDark: kHotelText,
    textMuted: Color(0xFF8C7E78),
    navSelected: kHotel2,
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
          colors: [Color(0xFFC4748A), Color(0xFFFF8FAB), Color(0xFFFFD6E0)],
        );
      case AppRole.restaurant:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF5C7A3E), Color(0xFF8FD14F), Color(0xFFD4EBC0)],
        );
      case AppRole.hotel:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4A7FA5), Color(0xFF56B4E9), Color(0xFFC8E3F2)],
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
  static const customerPrimary = kCust1;
  static const customerPrimaryDark = kCust2;
  static const customerSecondary = kCust4;
  static const customerAccent = kCust2;
  static const customerSurface = kCust3;
  static const customerTextDark = kCustText;
  static const customerTextMuted = Color(0xFF8C7E78);

  static const restaurantPrimary = kRest1;
  static const restaurantPrimaryDark = kRest2;
  static const restaurantSecondary = kRest4;
  static const restaurantAccent = kRest2;
  static const restaurantSurface = kRest3;
  static const restaurantTextDark = kRestText;
  static const restaurantTextMuted = Color(0xFF8C7E78);

  static const hotelPrimary = kHotel1;
  static const hotelPrimaryDark = kHotel2;
  static const hotelSecondary = kHotel4;
  static const hotelAccent = kHotel2;
  static const hotelSurface = kHotel3;
  static const hotelTextDark = kHotelText;
  static const hotelTextMuted = Color(0xFF8C7E78);

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
