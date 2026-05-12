import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/constants.dart';
import 'brand_palette.dart';

final kLoraDisplay = GoogleFonts.lora(
  fontWeight: FontWeight.w700,
  color: const Color(0xFF5A4E6E),
);
final kLoraSemi = GoogleFonts.lora(fontWeight: FontWeight.w600, color: kText2);
final kInterBody = GoogleFonts.inter(
  fontWeight: FontWeight.w400,
  color: kText2,
);
final kInterMedium = GoogleFonts.inter(
  fontWeight: FontWeight.w500,
  color: const Color(0xFF5A5050),
);
final kInterSemi = GoogleFonts.inter(
  fontWeight: FontWeight.w600,
  color: const Color(0xFF4A4040),
);

class AppTheme {
  static ThemeData lightTheme({String role = 'customer'}) {
    final base = ThemeData.light(useMaterial3: true);
    final colors = themeColors(role);

    final textTheme = GoogleFonts.interTextTheme(base.textTheme).copyWith(
      displayLarge: GoogleFonts.playfairDisplay(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: colors.textTitle,
        height: 1.2,
      ),
      headlineLarge: GoogleFonts.playfairDisplay(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: colors.textTitle,
        height: 1.2,
      ),
      headlineMedium: GoogleFonts.playfairDisplay(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: colors.textTitle,
        height: 1.2,
      ),
      titleLarge: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: colors.textTitle,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: colors.textTitle,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        height: 1.5,
        color: colors.textBody,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        height: 1.5,
        color: colors.textBody,
      ),
      labelLarge: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: colors.textTitle,
      ),
      labelMedium: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: colors.textMuted,
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        color: colors.textMuted,
        letterSpacing: 0.3,
      ),
    );

    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadii.input),
      borderSide: BorderSide(
        color: colors.primary.withValues(alpha: 0.0),
        width: 0,
      ),
    );
    final focusedBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadii.input),
      borderSide: BorderSide(color: colors.primary, width: 1.5),
    );
    final errorBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadii.input),
      borderSide: BorderSide(color: ORKATheme.danger, width: 1.5),
    );

    return base.copyWith(
      scaffoldBackgroundColor: colors.surface,
      colorScheme: base.colorScheme.copyWith(
        primary: colors.primary,
        secondary: colors.deep,
        surface: colors.cardBg,
        onSurface: colors.textTitle,
        onPrimary: Colors.white,
        error: ORKATheme.danger,
      ),
      textTheme: textTheme,

      dividerTheme: DividerThemeData(
        color: colors.primary.withValues(alpha: 0.08),
        thickness: 0.6,
        space: 0.6,
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: colors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.playfairDisplay(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        shadowColor: Colors.transparent,
      ),

      cardTheme: CardThemeData(
        color: colors.cardBg,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.innerCard),
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: colors.textTitle,
        contentTextStyle: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
        insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.all(colors.primary),
          foregroundColor: WidgetStateProperty.all(Colors.white),
          overlayColor: WidgetStateProperty.all(
            Colors.white.withValues(alpha: 0.12),
          ),
          elevation: WidgetStateProperty.all(0),
          minimumSize: WidgetStateProperty.all(const Size.fromHeight(52)),
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          ),
          textStyle: WidgetStateProperty.all(
            GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.pill),
            ),
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.primary,
          minimumSize: const Size.fromHeight(52),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          side: BorderSide(
            color: colors.primary.withValues(alpha: 0.2),
            width: 1.2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.pill),
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colors.primary,
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.pill),
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.softBg,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        labelStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: colors.textMuted,
        ),
        hintStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: colors.textMuted,
        ),
        floatingLabelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: colors.primary,
        ),
        errorStyle: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: ORKATheme.danger,
        ),
        enabledBorder: inputBorder,
        focusedBorder: focusedBorder,
        errorBorder: errorBorder,
        focusedErrorBorder: errorBorder,
        border: inputBorder,
      ),

      chipTheme: base.chipTheme.copyWith(
        backgroundColor: colors.softBg,
        selectedColor: colors.primary,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.pill),
        ),
        labelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: colors.textBody,
        ),
        secondaryLabelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        elevation: 0,
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: colors.primary,
        unselectedItemColor: colors.textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.selected)) return colors.primary;
          return colors.textMuted.withValues(alpha: 0.5);
        }),
        trackColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.selected)) {
            return colors.primary.withValues(alpha: 0.3);
          }
          return colors.textMuted.withValues(alpha: 0.15);
        }),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.xl),
        ),
        titleTextStyle: GoogleFonts.playfairDisplay(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: colors.textTitle,
        ),
        contentTextStyle: GoogleFonts.inter(
          fontSize: 14,
          height: 1.6,
          color: colors.textBody,
        ),
      ),

      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        iconColor: colors.textBody,
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(color: colors.primary),

      sliderTheme: SliderThemeData(
        activeTrackColor: colors.primary,
        inactiveTrackColor: colors.softBg,
        thumbColor: colors.primary,
        overlayColor: colors.primary.withValues(alpha: 0.12),
      ),
    );
  }

  static RoleColors themeColors(String role) {
    switch (role) {
      case 'restaurant':
        return const RoleColors(
          primary: ORKATheme.restaurantPrimary,
          deep: ORKATheme.restaurantDeep,
          surface: ORKATheme.restaurantSurface,
          cardBg: ORKATheme.restaurantCardBg,
          softBg: ORKATheme.restaurantSoftPink,
          cream: ORKATheme.restaurantCream,
          textTitle: ORKATheme.restaurantTextTitle,
          textBody: ORKATheme.restaurantTextBody,
          textMuted: ORKATheme.restaurantTextMuted,
          aiDark: ORKATheme.restaurantAiDark,
          aiLight: ORKATheme.restaurantAiLight,
          heroBlob1: ORKATheme.restaurantHeroBlob1,
          heroBlob2: ORKATheme.restaurantHeroBlob2,
        );
      case 'hotel':
        return const RoleColors(
          primary: ORKATheme.hotelPrimary,
          deep: ORKATheme.hotelDeep,
          surface: ORKATheme.hotelSurface,
          cardBg: ORKATheme.hotelCardBg,
          softBg: ORKATheme.hotelSoftGreen,
          cream: ORKATheme.hotelMint,
          textTitle: ORKATheme.hotelTextTitle,
          textBody: ORKATheme.hotelTextBody,
          textMuted: ORKATheme.hotelTextMuted,
          aiDark: ORKATheme.hotelAiDark,
          aiLight: ORKATheme.hotelAiLight,
          heroBlob1: ORKATheme.hotelHeroBlob1,
          heroBlob2: ORKATheme.hotelHeroBlob2,
        );
      default:
        return const RoleColors(
          primary: ORKATheme.customerPrimary,
          deep: ORKATheme.customerDeep,
          surface: ORKATheme.customerSurface,
          cardBg: ORKATheme.customerCardBg,
          softBg: ORKATheme.customerSoftLavender,
          cream: ORKATheme.customerLilac,
          textTitle: ORKATheme.customerTextTitle,
          textBody: ORKATheme.customerTextBody,
          textMuted: ORKATheme.customerTextMuted,
          aiDark: ORKATheme.customerAiDark,
          aiLight: ORKATheme.customerAiLight,
          heroBlob1: ORKATheme.customerHeroBlob1,
          heroBlob2: ORKATheme.customerHeroBlob2,
        );
    }
  }
}

class RoleColors {
  final Color primary;
  final Color deep;
  final Color surface;
  final Color cardBg;
  final Color softBg;
  final Color cream;
  final Color textTitle;
  final Color textBody;
  final Color textMuted;
  final Color aiDark;
  final Color aiLight;
  final Color heroBlob1;
  final Color heroBlob2;

  const RoleColors({
    required this.primary,
    required this.deep,
    required this.surface,
    required this.cardBg,
    required this.softBg,
    required this.cream,
    required this.textTitle,
    required this.textBody,
    required this.textMuted,
    required this.aiDark,
    required this.aiLight,
    required this.heroBlob1,
    required this.heroBlob2,
  });
}
