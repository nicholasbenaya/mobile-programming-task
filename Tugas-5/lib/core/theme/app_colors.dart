import 'package:flutter/material.dart';

/// Palet Warna Resmi Siskamling Ronda Digital (Prinsip Antislop-UI)
/// Desain berbasis civic security: Slate/Navy yang otoritatif dan tenang,
/// Amber sebagai penanda shift patroli, Emerald untuk verifikasi pos aman,
/// dan Crimson Red yang dicadangkan secara eksklusif untuk insiden darurat SOS.
class AppColors {
  const AppColors._();

  // Core Identity (Slate / Navy)
  static const primary = Color(0xFF0F172A); // Slate 900
  static const primaryLight = Color(0xFF1E293B); // Slate 800
  static const primaryContainer = Color(0xFF334155); // Slate 700

  // Secondary / Civics
  static const secondary = Color(0xFF0284C7); // Sky 600
  static const secondaryContainer = Color(0xFFE0F2FE); // Sky 100

  // Accents Berdasarkan Makna Nyata
  static const patrolAccent = Color(0xFFD97706); // Amber 600 (Waktu Tugas / Check-in)
  static const patrolAccentLight = Color(0xFFFEF3C7); // Amber 100
  static const verified = Color(0xFF059669); // Emerald 600 (Pos Terverifikasi / Selesai)
  static const verifiedLight = Color(0xFFD1FAE5); // Emerald 100
  static const emergency = Color(0xFFDC2626); // Red 600 (Eksklusif SOS & Terlewat)
  static const emergencyLight = Color(0xFFFEE2E2); // Red 100

  // Neutral Surfaces
  static const surfaceLight = Color(0xFFFFFFFF);
  static const backgroundLight = Color(0xFFF8FAFC); // Slate 50
  static const borderLight = Color(0xFFE2E8F0); // Slate 200
  static const textPrimaryLight = Color(0xFF0F172A); // Slate 900
  static const textSecondaryLight = Color(0xFF64748B); // Slate 500

  // Dark Mode Surfaces
  static const surfaceDark = Color(0xFF111827); // Gray 900
  static const backgroundDark = Color(0xFF0B0F19); // Deep Midnight
  static const borderDark = Color(0xFF1F2937); // Gray 800
  static const textPrimaryDark = Color(0xFFF8FAFC);
  static const textSecondaryDark = Color(0xFF94A3B8);
  // Legacy SensorLog compatibility
  static const observasi = Color(0xFF2563EB);
  static const lingkungan = Color(0xFF16A34A);
  static const infrastruktur = Color(0xFFEA580C);
  static const lainnya = Color(0xFF7C3AED);
}
