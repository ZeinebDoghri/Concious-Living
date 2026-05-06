import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/constants.dart';

class AppTheme {
  static ThemeData lightTheme() {
    final base = ThemeData.light(useMaterial3: false);
    const regularCardShadow = BoxShadow(
      color: Color(0x0F2C1A1B),
      blurRadius: 12,
      offset: Offset(0, 4),
    );
    const elevatedCardShadow = BoxShadow(
      color: Color(0x1A8B1A1F),
      blurRadius: 20,
      offset: Offset(0, 6),
    );

    // ── Typography — DM Serif for display, Inter for body ───────────────────
    final textTheme = GoogleFonts.interTextTheme(base.textTheme).copyWith(
      displayLarge: GoogleFonts.dmSerifDisplay(
        fontSize: 34,
        fontWeight: FontWeight.w400,
        color: AppColors.espresso,
        letterSpacing: 0.3,
      ),
      headlineLarge: GoogleFonts.dmSerifDisplay(
        fontSize: 26,
        fontWeight: FontWeight.w400,
        color: AppColors.espresso,
        letterSpacing: 0.2,
      ),
      headlineMedium: GoogleFonts.dmSerifDisplay(
        fontSize: 20,
        fontWeight: FontWeight.w400,
        color: AppColors.espresso,
        letterSpacing: 0.2,
      ),
      titleLarge: GoogleFonts.dmSerifDisplay(
        fontSize: 17,
        fontWeight: FontWeight.w400,
        color: AppColors.espresso,
        letterSpacing: 0.15,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: AppColors.espresso,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 14,
        height: 1.6,
        color: AppColors.espresso,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 13,
        height: 1.5,
        color: AppColors.espresso,
      ),
      labelLarge: GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: AppColors.espresso,
        letterSpacing: 0.1,
      ),
      labelMedium: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.fog,
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        color: AppColors.fog,
        letterSpacing: 0.3,
      ),
    );

    // ── Input borders ────────────────────────────────────────────────────────
    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadii.input),
      borderSide: const BorderSide(color: AppColors.sand, width: 0.8),
    );
    final focusedBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadii.input),
      borderSide: const BorderSide(color: AppColors.cherry, width: 1.5),
    );
    final errorBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadii.input),
      borderSide: const BorderSide(color: AppColors.cherryLight, width: 1),
    );

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.oat,
      colorScheme: base.colorScheme.copyWith(
        primary:    AppColors.cherry,
        secondary:  AppColors.olive,
        surface:    AppColors.parchment,
        onSurface:  AppColors.espresso,
        onPrimary:  AppColors.butter,
        onSecondary: AppColors.butter,
        error:      AppColors.cherry,
      ),
      textTheme: textTheme,

      // ── Divider ──────────────────────────────────────────────────────────
      dividerTheme: DividerThemeData(
        color: AppColors.sand,
        thickness: 0.5,
        space: 1,
      ),

      // ── AppBar — richer gradient feel via colour only ─────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.butter,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.dmSerifDisplay(
          fontSize: 20,
          fontWeight: FontWeight.w400,
          color: AppColors.butter,
          letterSpacing: 0.3,
        ),
        iconTheme: const IconThemeData(color: AppColors.butter, size: 20),
        actionsIconTheme: const IconThemeData(color: AppColors.butter),
        shadowColor: Colors.transparent,
      ),

      // ── Cards — warm parchment ────────────────────────────────────────────
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.sand, width: 0.5),
        ),
        shadowColor: regularCardShadow.color,
      ),

      // ── Snackbar ──────────────────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF1E293B),
        contentTextStyle: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          height: 1.3,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ),

      // ── Elevated button — richer, more inviting ───────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.all(Colors.transparent),
          foregroundColor: WidgetStateProperty.all(AppColors.butter),
          overlayColor: WidgetStateProperty.all(
            Colors.white.withValues(alpha: 0.08),
          ),
          shadowColor: WidgetStateProperty.all(elevatedCardShadow.color),
          elevation: WidgetStateProperty.all(0),
          minimumSize: WidgetStateProperty.all(const Size.fromHeight(52)),
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          ),
          textStyle: WidgetStateProperty.all(
            GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.button),
            ),
          ),
        ),
      ),

      // ── Outlined button ───────────────────────────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.cherry,
          minimumSize: const Size.fromHeight(48),
          textStyle: GoogleFonts.inter(
              fontSize: 14, fontWeight: FontWeight.w600),
          side: const BorderSide(color: AppColors.sand, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.button),
          ),
        ),
      ),

      // ── Text button ───────────────────────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.cherry,
          textStyle: GoogleFonts.inter(
              fontSize: 13, fontWeight: FontWeight.w500),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ),
      ),

      // ── Input decoration ──────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.cream,
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 14),
        labelStyle: GoogleFonts.inter(
            fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.cocoa),
        hintStyle: GoogleFonts.inter(
            fontSize: 14, fontWeight: FontWeight.w400,
            color: AppColors.fog),
        floatingLabelStyle: GoogleFonts.inter(
            fontSize: 13, fontWeight: FontWeight.w600,
            color: AppColors.cherry),
        errorStyle: GoogleFonts.inter(
            fontSize: 11, fontWeight: FontWeight.w500,
            color: AppColors.cherry, height: 1.3),
        enabledBorder:  inputBorder,
        focusedBorder:  focusedBorder,
        errorBorder:    errorBorder,
        focusedErrorBorder: errorBorder,
        border: inputBorder,
      ),

      // ── Chip ─────────────────────────────────────────────────────────────
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: AppColors.oat,
        selectedColor: AppColors.cherry,
        secondarySelectedColor: AppColors.cherry,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.sand, width: 0.8),
        ),
        labelStyle: GoogleFonts.inter(
            fontSize: 12, fontWeight: FontWeight.w500,
            color: AppColors.cocoa),
        secondaryLabelStyle: GoogleFonts.inter(
            fontSize: 12, fontWeight: FontWeight.w500,
            color: AppColors.butter),
        elevation: 0,
        shadowColor: Colors.transparent,
      ),

      // ── Bottom nav (kept for compatibility, shell uses custom) ─────────────
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.cherry,
        unselectedItemColor: Color(0xFFCBD5E1),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),

      // ── Switch ────────────────────────────────────────────────────────────
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.selected)) return AppColors.cherry;
          return const Color(0xFFCBD5E1);
        }),
        trackColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.cherry.withValues(alpha: 0.32);
          }
          return const Color(0xFFE2E8F0);
        }),
      ),

      // ── Dialog ───────────────────────────────────────────────────────────
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        titleTextStyle: GoogleFonts.sora(
          fontSize: 18, fontWeight: FontWeight.w700,
          color: AppColors.espresso,
        ),
        contentTextStyle: GoogleFonts.inter(
          fontSize: 14, height: 1.6, color: AppColors.cocoa,
        ),
      ),

      // ── ListTile ─────────────────────────────────────────────────────────
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 4),
        iconColor: AppColors.cocoa,
      ),

      // ── Progress indicator ────────────────────────────────────────────────
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.cherry,
      ),
    );
  }
}
