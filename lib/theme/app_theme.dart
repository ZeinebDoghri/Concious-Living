import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/constants.dart';

class AppTheme {
  static ThemeData lightTheme() {
    final base = ThemeData.light(useMaterial3: false);

    final textTheme = GoogleFonts.interTextTheme(base.textTheme).copyWith(
      displayLarge: GoogleFonts.dmSerifDisplay(
        fontSize: 32,
        color: AppColors.espresso,
      ),
      headlineLarge: GoogleFonts.dmSerifDisplay(
        fontSize: 24,
        color: AppColors.espresso,
      ),
      headlineMedium: GoogleFonts.dmSerifDisplay(
        fontSize: 20,
        color: AppColors.espresso,
      ),
      titleLarge: GoogleFonts.dmSerifDisplay(
        fontSize: 18,
        color: AppColors.espresso,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: AppColors.espresso,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 15,
        height: 1.6,
        color: AppColors.espresso,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 13,
        height: 1.5,
        color: AppColors.espresso,
      ),
      labelLarge: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.espresso,
      ),
      labelMedium: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: AppColors.cocoa,
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: 10,
        color: AppColors.cocoa,
      ),
    );

    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadii.input),
      borderSide: const BorderSide(color: AppColors.sand, width: 1),
    );

    final focusedBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadii.input),
      borderSide: const BorderSide(color: AppColors.cherry, width: 1.4),
    );

    final errorBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadii.input),
      borderSide: const BorderSide(color: AppColors.cherryBlush, width: 1.4),
    );

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.oat,
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.cherry,
        secondary: AppColors.olive,
        surface: AppColors.parchment,
        onSurface: AppColors.espresso,
        onPrimary: AppColors.butter,
        onSecondary: AppColors.butter,
        error: AppColors.cherry,
      ),
      textTheme: textTheme,
      dividerTheme: const DividerThemeData(
        color: AppColors.sand,
        thickness: 0.5,
        space: 0.5,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.cherry,
        foregroundColor: AppColors.butter,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: textTheme.headlineMedium?.copyWith(
          color: AppColors.cherryHeaderText,
        ),
        iconTheme: const IconThemeData(color: AppColors.butter),
      ),
      cardTheme: CardThemeData(
        color: AppColors.parchment,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.innerCard),
          side: const BorderSide(color: AppColors.sand, width: 0.5),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.cherry,
        contentTextStyle: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.cherryHeaderText,
          height: 1.3,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.button),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.cherry,
          foregroundColor: AppColors.cherryHeaderText,
          elevation: 0,
          minimumSize: const Size.fromHeight(52),
          textStyle: textTheme.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.button),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.cherry,
          minimumSize: const Size.fromHeight(48),
          textStyle: textTheme.labelLarge,
          side: const BorderSide(color: AppColors.sand, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.button),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.cream,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        labelStyle: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: AppColors.cocoa,
        ),
        hintStyle: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: AppColors.fog,
        ),
        errorStyle: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: AppColors.cherry,
          height: 1.2,
        ),
        enabledBorder: inputBorder,
        focusedBorder: focusedBorder,
        errorBorder: errorBorder,
        focusedErrorBorder: errorBorder,
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: AppColors.parchment,
        selectedColor: AppColors.cherry,
        secondarySelectedColor: AppColors.cherry,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.chip),
          side: const BorderSide(color: AppColors.sand, width: 1),
        ),
        labelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.cocoa,
          height: 1.2,
        ),
        secondaryLabelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.butter,
          height: 1.2,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.parchment,
        selectedItemColor: AppColors.cherry,
        unselectedItemColor: AppColors.fog,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.selected)) return AppColors.cherry;
          return AppColors.sand;
        }),
        trackColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.cherry.withValues(alpha: 0.35);
          }
          return AppColors.sand.withValues(alpha: 0.6);
        }),
      ),
    );
  }
}
