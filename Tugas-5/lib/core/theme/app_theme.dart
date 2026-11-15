import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Tema Antarmuka Ronda Digital (Siskamling RT/RW)
/// Menerapkan standar Antislop-UI: kontras tinggi, elevasi terukur,
/// radius yang proporsional, dan tipografi yang tajam.
class AppTheme {
  const AppTheme._();

  static ThemeData light() => _buildTheme(Brightness.light);
  static ThemeData dark() => _buildTheme(Brightness.dark);

  static ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: isDark ? const Color(0xFF94A3B8) : AppColors.primary,
      onPrimary: isDark ? const Color(0xFF0F172A) : Colors.white,
      primaryContainer: isDark ? AppColors.primaryContainer : AppColors.primaryLight,
      onPrimaryContainer: Colors.white,
      secondary: isDark ? const Color(0xFF38BDF8) : AppColors.secondary,
      onSecondary: Colors.white,
      secondaryContainer: isDark ? const Color(0xFF0369A1) : AppColors.secondaryContainer,
      onSecondaryContainer: isDark ? Colors.white : const Color(0xFF0C4A6E),
      error: AppColors.emergency,
      onError: Colors.white,
      surface: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      onSurface: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
      surfaceContainerLowest: isDark ? const Color(0xFF030712) : Colors.white,
      surfaceContainerLow: isDark ? const Color(0xFF111827) : const Color(0xFFF1F5F9),
      surfaceContainer: isDark ? const Color(0xFF1F2937) : const Color(0xFFE2E8F0),
      surfaceContainerHigh: isDark ? const Color(0xFF374151) : const Color(0xFFCBD5E1),
      surfaceContainerHighest: isDark ? const Color(0xFF4B5563) : const Color(0xFF94A3B8),
      outline: isDark ? AppColors.borderDark : AppColors.borderLight,
      outlineVariant: isDark ? const Color(0xFF374151) : const Color(0xFFE2E8F0),
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: brightness,
      scaffoldBackgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
    );

    return base.copyWith(
      textTheme: GoogleFonts.plusJakartaSansTextTheme(base.textTheme),
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        foregroundColor: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: isDark ? AppColors.surfaceDark : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? const Color(0xFF1F2937) : const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        labelStyle: TextStyle(
          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
          fontSize: 14,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 44),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 44),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          side: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dividerTheme: DividerThemeData(
        color: isDark ? AppColors.borderDark : AppColors.borderLight,
        thickness: 1,
        space: 24,
      ),
    );
  }
}
