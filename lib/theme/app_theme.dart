import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/constants.dart';

class AppTheme {
  static ThemeData lightTheme() {
    final base = ThemeData.light(useMaterial3: false);

    // ── Typography — Sora for display, Inter for everything else ────────────
    final textTheme = GoogleFonts.interTextTheme(base.textTheme).copyWith(
      displayLarge: GoogleFonts.sora(
        fontSize: 34,
        fontWeight: FontWeight.w800,
        color: AppColors.espresso,
        letterSpacing: -0.5,
      ),
      headlineLarge: GoogleFonts.sora(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        color: AppColors.espresso,
        letterSpacing: -0.3,
      ),
      headlineMedium: GoogleFonts.sora(
        fontSize: 21,
        fontWeight: FontWeight.w700,
        color: AppColors.espresso,
        letterSpacing: -0.2,
      ),
      titleLarge: GoogleFonts.sora(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.espresso,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.espresso,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 15,
        height: 1.65,
        color: AppColors.espresso,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 13,
        height: 1.55,
        color: AppColors.espresso,
      ),
      labelLarge: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: AppColors.espresso,
        letterSpacing: 0.1,
      ),
      labelMedium: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.cocoa,
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        color: AppColors.cocoa,
        letterSpacing: 0.3,
      ),
    );

    // ── Input borders ────────────────────────────────────────────────────────
    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadii.input),
      borderSide: const BorderSide(color: AppColors.sand, width: 1),
    );
    final focusedBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadii.input),
      borderSide: const BorderSide(color: AppColors.cherry, width: 1.6),
    );
    final errorBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadii.input),
      borderSide: const BorderSide(color: AppColors.cherryBlush, width: 1.6),
    );

    return base.copyWith(
      scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      colorScheme: base.colorScheme.copyWith(
        primary:    AppColors.cherry,
        secondary:  AppColors.olive,
        surface:    Colors.white,
        onSurface:  AppColors.espresso,
        onPrimary:  AppColors.butter,
        onSecondary: AppColors.butter,
        error:      AppColors.cherry,
      ),
      textTheme: textTheme,

      // ── Divider ──────────────────────────────────────────────────────────
      dividerTheme: DividerThemeData(
        color: const Color(0xFFE2E8F0),
        thickness: 0.6,
        space: 0.6,
      ),

      // ── AppBar — richer gradient feel via colour only ─────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.cherry,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.sora(
          fontSize: 19,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          letterSpacing: -0.1,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actionsIconTheme: const IconThemeData(color: Colors.white),
        shadowColor: Colors.transparent,
      ),

      // ── Cards — glass-inspired with depth ─────────────────────────────────
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFFE8EDF2), width: 0.8),
        ),
        shadowColor: const Color(0xFF1E293B),
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
          backgroundColor: WidgetStateProperty.all(AppColors.cherry),
          foregroundColor: WidgetStateProperty.all(Colors.white),
          overlayColor: WidgetStateProperty.all(
              Colors.white.withValues(alpha: 0.12)),
          elevation: WidgetStateProperty.all(0),
          minimumSize: WidgetStateProperty.all(const Size.fromHeight(54)),
          padding: WidgetStateProperty.all(
              const EdgeInsets.symmetric(horizontal: 24, vertical: 14)),
          textStyle: WidgetStateProperty.all(
            GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700),
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
          minimumSize: const Size.fromHeight(52),
          textStyle: GoogleFonts.inter(
              fontSize: 14, fontWeight: FontWeight.w600),
          side: const BorderSide(color: Color(0xFFDDE1E7), width: 1.2),
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
              fontSize: 14, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ),
      ),

      // ── Input decoration ──────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 18, vertical: 16),
        labelStyle: GoogleFonts.inter(
            fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.cocoa),
        hintStyle: GoogleFonts.inter(
            fontSize: 14, fontWeight: FontWeight.w400,
            color: const Color(0xFFB0BAC8)),
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
        backgroundColor: Colors.white,
        selectedColor: AppColors.cherry,
        secondarySelectedColor: AppColors.cherry,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.chip),
          side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
        labelStyle: GoogleFonts.inter(
            fontSize: 13, fontWeight: FontWeight.w500,
            color: AppColors.cocoa),
        secondaryLabelStyle: GoogleFonts.inter(
            fontSize: 13, fontWeight: FontWeight.w600,
            color: Colors.white),
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
