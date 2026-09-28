import 'package:flutter/material.dart';

class AppTheme {
  // ==============================================================
  // PALET WARNA: "Zamrud & Emas Nusantara" (Royal Emerald Teal & Antique Gold)
  // Palet prestisius, terinspirasi dari julukan "Zamrud Khatulistiwa"
  // dan emas pusaka kemerdekaan. Unik & elegan, jauh dari warna klise.
  // ==============================================================

  // Warna Utama (Deep Royal Emerald Teal)
  static const Color primary = Color(0xFF0F4C5C); // Deep Emerald Teal
  static const Color primaryDark = Color(0xFF09313C);
  static const Color primaryLight = Color(0xFFE2EFF2);
  static const Color primaryContainer = Color(0xFFD3E7EB);

  // Aksen Emas & Amber (Antique Royal Gold)
  static const Color accentGold = Color(0xFFC59B27); // Emas Pusaka
  static const Color lightGold = Color(0xFFFBF5E5);
  static const Color warmAmber = Color(0xFFD97706); // Amber Hangat

  // Netral & Latar Belakang (Alabaster & Obsidian Slate)
  static const Color deepNavy = Color(0xFF0F172A); // Slate Obsidian
  static const Color backgroundLight = Color(0xFFF7F9F9); // Alabaster Halus
  static const Color cardLight = Colors.white;
  static const Color textDark = Color(0xFF0F172A);
  static const Color textMuted = Color(0xFF64748B);

  // Aksen Merah Delima (Subtle Patriotic Ruby)
  static const Color crimsonAccent = Color(0xFFBE123C);

  // Alias kompatibilitas (agar seluruh kode yang memanggil primaryRed tetap berjalan mulus dengan tema baru)
  static const Color primaryRed = primary;
  static const Color darkRed = primaryDark;
  static const Color lightRed = primaryLight;

  static ThemeData get lightTheme {
    final baseScheme = ColorScheme.fromSeed(
      seedColor: primary,
      primary: primary,
      secondary: accentGold,
      surface: backgroundLight,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: baseScheme,
      scaffoldBackgroundColor: backgroundLight,
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: deepNavy,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 1,
        iconTheme: IconThemeData(color: deepNavy),
        titleTextStyle: TextStyle(
          color: deepNavy,
          fontSize: 19,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.3,
        ),
      ),
      cardTheme: CardThemeData(
        color: cardLight,
        elevation: 2,
        shadowColor: primary.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        elevation: 3,
        indicatorColor: primary.withValues(alpha: 0.14),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: primary,
            );
          }
          return const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: textMuted,
          );
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
      ),
    );
  }
}
