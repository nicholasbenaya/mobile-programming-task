import 'package:flutter/material.dart';

/// Civic Operational color tokens matching `ronda_app/DESIGN.md` for Light and Dark modes.
abstract final class AppColors {
  // Light Mode tokens (daytime admin & resident readability).
  static const Color lightCanvas = Color(0xFFF4F6F8);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceSubtle = Color(0xFFE9EEF3);
  static const Color lightInkPrimary = Color(0xFF0F172A);
  static const Color lightInkSecondary = Color(0xFF475569);
  static const Color lightBrandPrimary = Color(0xFF153243);
  static const Color lightOnBrandPrimary = Color(0xFFFFFFFF);
  static const Color lightAccentOperational = Color(0xFFB45309);
  static const Color lightAccentFill = Color(0xFFF59E0B);
  static const Color lightBorderHairline = Color(0xFFCBD5E1);
  static const Color lightBorderInteractive = Color(0xFF64748B);
  static const Color lightStatusVerified = Color(0xFF047857);
  static const Color lightStatusVerifiedTint = Color(0xFFECFDF5);
  static const Color lightStatusFlagged = Color(0xFF92400E);
  static const Color lightStatusFlaggedTint = Color(0xFFFEF3C7);
  static const Color lightStatusEmergency = Color(0xFFB91C1C);
  static const Color lightStatusEmergencyText = Color(0xFF991B1B);
  static const Color lightStatusEmergencyTint = Color(0xFFFEE2E2);

  // Dark Mode tokens (low-glare night-shift patrol readability).
  static const Color darkCanvas = Color(0xFF0B111A);
  static const Color darkSurface = Color(0xFF131C2A);
  static const Color darkSurfaceElevated = Color(0xFF1B273A);
  static const Color darkInkPrimary = Color(0xFFF1F5F9);
  static const Color darkInkSecondary = Color(0xFFA3B3C6);
  static const Color darkBrandPrimary = Color(0xFF5FA8D3);
  static const Color darkOnBrandPrimary = Color(0xFF0B111A);
  static const Color darkAccentOperational = Color(0xFFF59E0B);
  static const Color darkAccentFill = Color(0xFFF59E0B);
  static const Color darkBorderHairline = Color(0xFF263449);
  static const Color darkBorderInteractive = Color(0xFF6E829B);
  static const Color darkStatusVerified = Color(0xFF34D399);
  static const Color darkStatusVerifiedTint = Color(0xFF0B2E26);
  static const Color darkStatusFlagged = Color(0xFFFBBF24);
  static const Color darkStatusFlaggedTint = Color(0xFF332207);
  static const Color darkStatusEmergency = Color(0xFFDC2626);
  static const Color darkStatusEmergencyText = Color(0xFFFCA5A5);
  static const Color darkStatusEmergencyTint = Color(0xFF3B1219);

  // Shared high-contrast invariants.
  static const Color onEmergencySolid = Color(0xFFFFFFFF);
  static const Color photoScrim = Color(0xC70B111A);
}
