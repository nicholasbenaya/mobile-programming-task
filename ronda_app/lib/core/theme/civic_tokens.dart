import 'package:flutter/material.dart';
import 'package:ronda_app/core/theme/app_colors.dart';

/// Semantic Civic Operational design tokens exposed via [ThemeExtension].
@immutable
class CivicTokens extends ThemeExtension<CivicTokens> {
  const CivicTokens({
    required this.canvas,
    required this.surface,
    required this.surfaceSubtle,
    required this.surfaceElevated,
    required this.inkPrimary,
    required this.inkSecondary,
    required this.brandPrimary,
    required this.onBrandPrimary,
    required this.accentOperational,
    required this.accentFill,
    required this.onAccentFill,
    required this.borderHairline,
    required this.borderInteractive,
    required this.statusVerified,
    required this.statusVerifiedTint,
    required this.statusFlagged,
    required this.statusFlaggedTint,
    required this.statusEmergency,
    required this.onStatusEmergency,
    required this.statusEmergencyText,
    required this.statusEmergencyTint,
    required this.statusOffline,
    required this.statusOfflineTint,
    required this.photoScrim,
    required this.forensicMono,
  });

  // Spacing scale from DESIGN.md section 4.1.
  static const double spaceXs = 4;
  static const double spaceSm = 8;
  static const double spaceMd = 12;
  static const double spaceLg = 16;
  static const double spaceXl = 20;
  static const double spaceSection = 24;
  static const double space2xl = 32;

  // Radius hierarchy from DESIGN.md section 4.1 (no uniform pill-everything).
  static const double radiusChip = 6;
  static const double radiusControl = 10;
  static const double radiusCard = 14;
  static const double radiusSheet = 20;
  static const double radiusFull = 999;

  // Minimum mobile tap target sizes from DESIGN.md section 4.2.
  static const double minTapTarget = 48;
  static const double minCompactTapTarget = 44;

  static const String monoFontFamily = 'JetBrains Mono';

  final Color canvas;
  final Color surface;
  final Color surfaceSubtle;
  final Color surfaceElevated;
  final Color inkPrimary;
  final Color inkSecondary;
  final Color brandPrimary;
  final Color onBrandPrimary;
  final Color accentOperational;
  final Color accentFill;
  final Color onAccentFill;
  final Color borderHairline;
  final Color borderInteractive;
  final Color statusVerified;
  final Color statusVerifiedTint;
  final Color statusFlagged;
  final Color statusFlaggedTint;
  final Color statusEmergency;
  final Color onStatusEmergency;
  final Color statusEmergencyText;
  final Color statusEmergencyTint;
  final Color statusOffline;
  final Color statusOfflineTint;
  final Color photoScrim;
  final TextStyle forensicMono;

  static const CivicTokens light = CivicTokens(
    canvas: AppColors.lightCanvas,
    surface: AppColors.lightSurface,
    surfaceSubtle: AppColors.lightSurfaceSubtle,
    surfaceElevated: AppColors.lightSurface,
    inkPrimary: AppColors.lightInkPrimary,
    inkSecondary: AppColors.lightInkSecondary,
    brandPrimary: AppColors.lightBrandPrimary,
    onBrandPrimary: AppColors.lightOnBrandPrimary,
    accentOperational: AppColors.lightAccentOperational,
    accentFill: AppColors.lightAccentFill,
    onAccentFill: AppColors.lightInkPrimary,
    borderHairline: AppColors.lightBorderHairline,
    borderInteractive: AppColors.lightBorderInteractive,
    statusVerified: AppColors.lightStatusVerified,
    statusVerifiedTint: AppColors.lightStatusVerifiedTint,
    statusFlagged: AppColors.lightStatusFlagged,
    statusFlaggedTint: AppColors.lightStatusFlaggedTint,
    statusEmergency: AppColors.lightStatusEmergency,
    onStatusEmergency: AppColors.onEmergencySolid,
    statusEmergencyText: AppColors.lightStatusEmergencyText,
    statusEmergencyTint: AppColors.lightStatusEmergencyTint,
    statusOffline: AppColors.lightInkSecondary,
    statusOfflineTint: AppColors.lightSurfaceSubtle,
    photoScrim: AppColors.photoScrim,
    forensicMono: TextStyle(
      fontFamily: monoFontFamily,
      fontSize: 12.5,
      fontWeight: FontWeight.w400,
      height: 1.35,
      color: AppColors.lightInkPrimary,
      fontFeatures: [FontFeature.tabularFigures()],
    ),
  );

  static const CivicTokens dark = CivicTokens(
    canvas: AppColors.darkCanvas,
    surface: AppColors.darkSurface,
    surfaceSubtle: AppColors.darkSurfaceElevated,
    surfaceElevated: AppColors.darkSurfaceElevated,
    inkPrimary: AppColors.darkInkPrimary,
    inkSecondary: AppColors.darkInkSecondary,
    brandPrimary: AppColors.darkBrandPrimary,
    onBrandPrimary: AppColors.darkOnBrandPrimary,
    accentOperational: AppColors.darkAccentOperational,
    accentFill: AppColors.darkAccentFill,
    onAccentFill: AppColors.darkOnBrandPrimary,
    borderHairline: AppColors.darkBorderHairline,
    borderInteractive: AppColors.darkBorderInteractive,
    statusVerified: AppColors.darkStatusVerified,
    statusVerifiedTint: AppColors.darkStatusVerifiedTint,
    statusFlagged: AppColors.darkStatusFlagged,
    statusFlaggedTint: AppColors.darkStatusFlaggedTint,
    statusEmergency: AppColors.darkStatusEmergency,
    onStatusEmergency: AppColors.onEmergencySolid,
    statusEmergencyText: AppColors.darkStatusEmergencyText,
    statusEmergencyTint: AppColors.darkStatusEmergencyTint,
    statusOffline: AppColors.darkInkSecondary,
    statusOfflineTint: AppColors.darkSurfaceElevated,
    photoScrim: AppColors.photoScrim,
    forensicMono: TextStyle(
      fontFamily: monoFontFamily,
      fontSize: 12.5,
      fontWeight: FontWeight.w400,
      height: 1.35,
      color: AppColors.darkInkPrimary,
      fontFeatures: [FontFeature.tabularFigures()],
    ),
  );

  @override
  CivicTokens copyWith({
    Color? canvas,
    Color? surface,
    Color? surfaceSubtle,
    Color? surfaceElevated,
    Color? inkPrimary,
    Color? inkSecondary,
    Color? brandPrimary,
    Color? onBrandPrimary,
    Color? accentOperational,
    Color? accentFill,
    Color? onAccentFill,
    Color? borderHairline,
    Color? borderInteractive,
    Color? statusVerified,
    Color? statusVerifiedTint,
    Color? statusFlagged,
    Color? statusFlaggedTint,
    Color? statusEmergency,
    Color? onStatusEmergency,
    Color? statusEmergencyText,
    Color? statusEmergencyTint,
    Color? statusOffline,
    Color? statusOfflineTint,
    Color? photoScrim,
    TextStyle? forensicMono,
  }) {
    return CivicTokens(
      canvas: canvas ?? this.canvas,
      surface: surface ?? this.surface,
      surfaceSubtle: surfaceSubtle ?? this.surfaceSubtle,
      surfaceElevated: surfaceElevated ?? this.surfaceElevated,
      inkPrimary: inkPrimary ?? this.inkPrimary,
      inkSecondary: inkSecondary ?? this.inkSecondary,
      brandPrimary: brandPrimary ?? this.brandPrimary,
      onBrandPrimary: onBrandPrimary ?? this.onBrandPrimary,
      accentOperational: accentOperational ?? this.accentOperational,
      accentFill: accentFill ?? this.accentFill,
      onAccentFill: onAccentFill ?? this.onAccentFill,
      borderHairline: borderHairline ?? this.borderHairline,
      borderInteractive: borderInteractive ?? this.borderInteractive,
      statusVerified: statusVerified ?? this.statusVerified,
      statusVerifiedTint: statusVerifiedTint ?? this.statusVerifiedTint,
      statusFlagged: statusFlagged ?? this.statusFlagged,
      statusFlaggedTint: statusFlaggedTint ?? this.statusFlaggedTint,
      statusEmergency: statusEmergency ?? this.statusEmergency,
      onStatusEmergency: onStatusEmergency ?? this.onStatusEmergency,
      statusEmergencyText: statusEmergencyText ?? this.statusEmergencyText,
      statusEmergencyTint: statusEmergencyTint ?? this.statusEmergencyTint,
      statusOffline: statusOffline ?? this.statusOffline,
      statusOfflineTint: statusOfflineTint ?? this.statusOfflineTint,
      photoScrim: photoScrim ?? this.photoScrim,
      forensicMono: forensicMono ?? this.forensicMono,
    );
  }

  @override
  CivicTokens lerp(covariant ThemeExtension<CivicTokens>? other, double t) {
    if (other is! CivicTokens) {
      return this;
    }
    return CivicTokens(
      canvas: Color.lerp(canvas, other.canvas, t) ?? canvas,
      surface: Color.lerp(surface, other.surface, t) ?? surface,
      surfaceSubtle: Color.lerp(surfaceSubtle, other.surfaceSubtle, t) ?? surfaceSubtle,
      surfaceElevated:
          Color.lerp(surfaceElevated, other.surfaceElevated, t) ?? surfaceElevated,
      inkPrimary: Color.lerp(inkPrimary, other.inkPrimary, t) ?? inkPrimary,
      inkSecondary: Color.lerp(inkSecondary, other.inkSecondary, t) ?? inkSecondary,
      brandPrimary: Color.lerp(brandPrimary, other.brandPrimary, t) ?? brandPrimary,
      onBrandPrimary:
          Color.lerp(onBrandPrimary, other.onBrandPrimary, t) ?? onBrandPrimary,
      accentOperational:
          Color.lerp(accentOperational, other.accentOperational, t) ??
              accentOperational,
      accentFill: Color.lerp(accentFill, other.accentFill, t) ?? accentFill,
      onAccentFill: Color.lerp(onAccentFill, other.onAccentFill, t) ?? onAccentFill,
      borderHairline:
          Color.lerp(borderHairline, other.borderHairline, t) ?? borderHairline,
      borderInteractive:
          Color.lerp(borderInteractive, other.borderInteractive, t) ??
              borderInteractive,
      statusVerified:
          Color.lerp(statusVerified, other.statusVerified, t) ?? statusVerified,
      statusVerifiedTint:
          Color.lerp(statusVerifiedTint, other.statusVerifiedTint, t) ??
              statusVerifiedTint,
      statusFlagged: Color.lerp(statusFlagged, other.statusFlagged, t) ?? statusFlagged,
      statusFlaggedTint:
          Color.lerp(statusFlaggedTint, other.statusFlaggedTint, t) ??
              statusFlaggedTint,
      statusEmergency:
          Color.lerp(statusEmergency, other.statusEmergency, t) ?? statusEmergency,
      onStatusEmergency:
          Color.lerp(onStatusEmergency, other.onStatusEmergency, t) ??
              onStatusEmergency,
      statusEmergencyText:
          Color.lerp(statusEmergencyText, other.statusEmergencyText, t) ??
              statusEmergencyText,
      statusEmergencyTint:
          Color.lerp(statusEmergencyTint, other.statusEmergencyTint, t) ??
              statusEmergencyTint,
      statusOffline: Color.lerp(statusOffline, other.statusOffline, t) ?? statusOffline,
      statusOfflineTint:
          Color.lerp(statusOfflineTint, other.statusOfflineTint, t) ??
              statusOfflineTint,
      photoScrim: Color.lerp(photoScrim, other.photoScrim, t) ?? photoScrim,
      forensicMono:
          TextStyle.lerp(forensicMono, other.forensicMono, t) ?? forensicMono,
    );
  }
}

extension CivicTokensBuildContext on BuildContext {
  CivicTokens get civicTokens {
    final extension = Theme.of(this).extension<CivicTokens>();
    if (extension != null) {
      return extension;
    }
    return Theme.of(this).brightness == Brightness.dark
        ? CivicTokens.dark
        : CivicTokens.light;
  }
}
