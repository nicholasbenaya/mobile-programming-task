import 'package:flutter/material.dart';
import 'package:ronda_app/core/theme/app_colors.dart';
import 'package:ronda_app/core/theme/civic_tokens.dart';

/// Builds Material 3 Light and Dark themes for the RondaDigital Civic Operational system.
abstract final class AppTheme {
  static const String sansFontFamily = 'Plus Jakarta Sans';
  static const String monoFontFamily = CivicTokens.monoFontFamily;

  static ThemeData light() => _buildTheme(
        brightness: Brightness.light,
        tokens: CivicTokens.light,
        colorScheme: const ColorScheme(
          brightness: Brightness.light,
          primary: AppColors.lightBrandPrimary,
          onPrimary: AppColors.lightOnBrandPrimary,
          primaryContainer: AppColors.lightSurfaceSubtle,
          onPrimaryContainer: AppColors.lightBrandPrimary,
          secondary: AppColors.lightAccentOperational,
          onSecondary: AppColors.lightOnBrandPrimary,
          secondaryContainer: AppColors.lightStatusFlaggedTint,
          onSecondaryContainer: AppColors.lightStatusFlagged,
          tertiary: AppColors.lightStatusVerified,
          onTertiary: AppColors.lightOnBrandPrimary,
          tertiaryContainer: AppColors.lightStatusVerifiedTint,
          onTertiaryContainer: AppColors.lightStatusVerified,
          error: AppColors.lightStatusEmergency,
          onError: AppColors.onEmergencySolid,
          errorContainer: AppColors.lightStatusEmergencyTint,
          onErrorContainer: AppColors.lightStatusEmergencyText,
          surface: AppColors.lightSurface,
          onSurface: AppColors.lightInkPrimary,
          onSurfaceVariant: AppColors.lightInkSecondary,
          outline: AppColors.lightBorderInteractive,
          outlineVariant: AppColors.lightBorderHairline,
          shadow: Color(0x140F172A),
          scrim: AppColors.photoScrim,
          inverseSurface: AppColors.darkSurface,
          onInverseSurface: AppColors.darkInkPrimary,
          inversePrimary: AppColors.darkBrandPrimary,
          surfaceContainerLowest: AppColors.lightSurface,
          surfaceContainerLow: AppColors.lightCanvas,
          surfaceContainer: AppColors.lightSurfaceSubtle,
          surfaceContainerHigh: AppColors.lightSurfaceSubtle,
          surfaceContainerHighest: AppColors.lightSurfaceSubtle,
        ),
      );

  static ThemeData dark() => _buildTheme(
        brightness: Brightness.dark,
        tokens: CivicTokens.dark,
        colorScheme: const ColorScheme(
          brightness: Brightness.dark,
          primary: AppColors.darkBrandPrimary,
          onPrimary: AppColors.darkOnBrandPrimary,
          primaryContainer: AppColors.darkSurfaceElevated,
          onPrimaryContainer: AppColors.darkInkPrimary,
          secondary: AppColors.darkAccentOperational,
          onSecondary: AppColors.darkOnBrandPrimary,
          secondaryContainer: AppColors.darkStatusFlaggedTint,
          onSecondaryContainer: AppColors.darkStatusFlagged,
          tertiary: AppColors.darkStatusVerified,
          onTertiary: AppColors.darkOnBrandPrimary,
          tertiaryContainer: AppColors.darkStatusVerifiedTint,
          onTertiaryContainer: AppColors.darkStatusVerified,
          error: AppColors.darkStatusEmergency,
          onError: AppColors.onEmergencySolid,
          errorContainer: AppColors.darkStatusEmergencyTint,
          onErrorContainer: AppColors.darkStatusEmergencyText,
          surface: AppColors.darkSurface,
          onSurface: AppColors.darkInkPrimary,
          onSurfaceVariant: AppColors.darkInkSecondary,
          outline: AppColors.darkBorderInteractive,
          outlineVariant: AppColors.darkBorderHairline,
          shadow: Color(0x33000000),
          scrim: AppColors.photoScrim,
          inverseSurface: AppColors.lightSurface,
          onInverseSurface: AppColors.lightInkPrimary,
          inversePrimary: AppColors.lightBrandPrimary,
          surfaceContainerLowest: AppColors.darkCanvas,
          surfaceContainerLow: AppColors.darkCanvas,
          surfaceContainer: AppColors.darkSurface,
          surfaceContainerHigh: AppColors.darkSurfaceElevated,
          surfaceContainerHighest: AppColors.darkSurfaceElevated,
        ),
      );

  static ThemeData _buildTheme({
    required Brightness brightness,
    required CivicTokens tokens,
    required ColorScheme colorScheme,
  }) {
    final textTheme = _buildTextTheme(tokens);
    final controlShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(CivicTokens.radiusControl),
    );
    final focusSide = BorderSide(color: tokens.brandPrimary, width: 2);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: sansFontFamily,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: tokens.canvas,
      canvasColor: tokens.canvas,
      textTheme: textTheme,
      extensions: <ThemeExtension<dynamic>>[tokens],
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        backgroundColor: tokens.surface,
        foregroundColor: tokens.inkPrimary,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: textTheme.titleLarge,
        shape: Border(
          bottom: BorderSide(color: tokens.borderHairline, width: 1),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: tokens.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(CivicTokens.radiusCard),
          side: BorderSide(color: tokens.borderHairline, width: 1),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: tokens.borderHairline,
        thickness: 1,
        space: 1,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(
            Size(CivicTokens.minTapTarget, CivicTokens.minTapTarget),
          ),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          ),
          shape: WidgetStatePropertyAll(controlShape),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return tokens.borderHairline;
            }
            return tokens.brandPrimary;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return tokens.inkSecondary;
            }
            return tokens.onBrandPrimary;
          }),
          side: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.focused)) {
              return BorderSide(color: tokens.accentFill, width: 2);
            }
            return BorderSide.none;
          }),
          textStyle: WidgetStatePropertyAll(textTheme.labelLarge),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          minimumSize: const Size(
            CivicTokens.minTapTarget,
            CivicTokens.minTapTarget,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: controlShape,
          backgroundColor: tokens.brandPrimary,
          foregroundColor: tokens.onBrandPrimary,
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(
            Size(CivicTokens.minTapTarget, CivicTokens.minTapTarget),
          ),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          shape: WidgetStatePropertyAll(controlShape),
          foregroundColor: WidgetStatePropertyAll(tokens.inkPrimary),
          side: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.focused)) {
              return focusSide;
            }
            return BorderSide(color: tokens.borderInteractive, width: 1.25);
          }),
          textStyle: WidgetStatePropertyAll(textTheme.labelLarge),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(
            CivicTokens.minCompactTapTarget,
            CivicTokens.minCompactTapTarget,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          shape: controlShape,
          foregroundColor: tokens.brandPrimary,
          textStyle: textTheme.labelLarge,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(
            CivicTokens.minCompactTapTarget,
            CivicTokens.minCompactTapTarget,
          ),
          foregroundColor: tokens.inkPrimary,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: tokens.surfaceSubtle,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        labelStyle: textTheme.bodyMedium?.copyWith(color: tokens.inkSecondary),
        hintStyle: textTheme.bodyMedium?.copyWith(color: tokens.inkSecondary),
        errorStyle: textTheme.labelSmall?.copyWith(
          color: tokens.statusEmergencyText,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(CivicTokens.radiusControl),
          borderSide: BorderSide(color: tokens.borderInteractive, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(CivicTokens.radiusControl),
          borderSide: BorderSide(color: tokens.borderInteractive, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(CivicTokens.radiusControl),
          borderSide: focusSide,
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(CivicTokens.radiusControl),
          borderSide: BorderSide(color: tokens.statusEmergency, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(CivicTokens.radiusControl),
          borderSide: BorderSide(color: tokens.statusEmergency, width: 2),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: tokens.surfaceElevated,
        surfaceTintColor: Colors.transparent,
        elevation: 4,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(CivicTokens.radiusSheet),
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: tokens.surfaceElevated,
        surfaceTintColor: Colors.transparent,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(CivicTokens.radiusCard),
          side: BorderSide(color: tokens.borderHairline, width: 1),
        ),
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyLarge,
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        backgroundColor: tokens.surfaceElevated,
        surfaceTintColor: Colors.transparent,
        indicatorColor: tokens.statusFlaggedTint,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(CivicTokens.radiusControl),
        ),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: 24,
            color: isSelected ? tokens.statusFlagged : tokens.inkSecondary,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return textTheme.labelSmall?.copyWith(
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? tokens.statusFlagged : tokens.inkSecondary,
          );
        }),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(
            Size(CivicTokens.minCompactTapTarget, CivicTokens.minTapTarget),
          ),
          shape: WidgetStatePropertyAll(controlShape),
          side: WidgetStatePropertyAll(
            BorderSide(color: tokens.borderInteractive, width: 1),
          ),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return tokens.brandPrimary;
            }
            return tokens.surface;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return tokens.onBrandPrimary;
            }
            return tokens.inkPrimary;
          }),
          textStyle: WidgetStatePropertyAll(textTheme.labelLarge),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: tokens.surfaceSubtle,
        selectedColor: tokens.statusFlaggedTint,
        side: BorderSide(color: tokens.borderHairline, width: 1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(CivicTokens.radiusChip),
        ),
        labelStyle: textTheme.labelSmall?.copyWith(color: tokens.inkPrimary),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: colorScheme.inverseSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onInverseSurface,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(CivicTokens.radiusControl),
        ),
      ),
    );
  }

  static TextTheme _buildTextTheme(CivicTokens tokens) {
    return TextTheme(
      headlineMedium: TextStyle(
        fontFamily: sansFontFamily,
        fontSize: 22,
        fontWeight: FontWeight.w700,
        height: 1.25,
        color: tokens.inkPrimary,
      ),
      titleLarge: TextStyle(
        fontFamily: sansFontFamily,
        fontSize: 18,
        fontWeight: FontWeight.w700,
        height: 1.30,
        color: tokens.inkPrimary,
      ),
      titleMedium: TextStyle(
        fontFamily: sansFontFamily,
        fontSize: 15,
        fontWeight: FontWeight.w700,
        height: 1.35,
        color: tokens.inkPrimary,
      ),
      bodyLarge: TextStyle(
        fontFamily: sansFontFamily,
        fontSize: 15,
        fontWeight: FontWeight.w400,
        height: 1.45,
        color: tokens.inkPrimary,
      ),
      bodyMedium: TextStyle(
        fontFamily: sansFontFamily,
        fontSize: 13.5,
        fontWeight: FontWeight.w400,
        height: 1.45,
        color: tokens.inkSecondary,
      ),
      bodySmall: TextStyle(
        fontFamily: sansFontFamily,
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.35,
        color: tokens.inkSecondary,
      ),
      labelLarge: TextStyle(
        fontFamily: sansFontFamily,
        fontSize: 14,
        fontWeight: FontWeight.w700,
        height: 1.20,
        color: tokens.inkPrimary,
      ),
      labelMedium: TextStyle(
        fontFamily: sansFontFamily,
        fontSize: 12.5,
        fontWeight: FontWeight.w500,
        height: 1.25,
        color: tokens.inkPrimary,
      ),
      labelSmall: TextStyle(
        fontFamily: sansFontFamily,
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 1.25,
        color: tokens.inkSecondary,
      ),
    );
  }
}
