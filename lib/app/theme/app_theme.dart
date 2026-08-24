import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

/// ShirBrax Material 3 Theme
abstract class AppTheme {
  // ─── Light Theme ──────────────────────────────────────────
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: const ColorScheme(
          brightness: Brightness.light,
          primary: AppColors.primary,
          onPrimary: AppColors.onPrimary,
          primaryContainer: AppColors.primaryContainer,
          onPrimaryContainer: AppColors.onPrimaryContainer,
          secondary: AppColors.secondary,
          onSecondary: AppColors.onSecondary,
          secondaryContainer: AppColors.secondaryContainer,
          onSecondaryContainer: AppColors.onSecondaryContainer,
          tertiary: AppColors.accent,
          onTertiary: AppColors.onAccent,
          tertiaryContainer: AppColors.accentContainer,
          onTertiaryContainer: AppColors.onAccentContainer,
          error: AppColors.error,
          onError: AppColors.onError,
          surface: AppColors.surface,
          onSurface: AppColors.onSurface,
          surfaceContainerHighest: AppColors.surfaceVariant,
          onSurfaceVariant: AppColors.onSurfaceVariant,
          outline: AppColors.border,
          outlineVariant: AppColors.divider,
          scrim: Color(0x99000000),
          inverseSurface: Color(0xFF1A0C10),
          onInverseSurface: Color(0xFFF8E4E7),
          inversePrimary: AppColors.secondary,
        ),
        scaffoldBackgroundColor: AppColors.background,
        textTheme: _buildTextTheme(AppColors.onSurface),
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.onSurface,
          elevation: 0,
          scrolledUnderElevation: 1,
          centerTitle: true,
          titleTextStyle: AppTextStyles.titleLarge,
        ),
        cardTheme: CardThemeData(
          color: AppColors.surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.border, width: 1),
          ),
          margin: EdgeInsets.zero,
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.onPrimary,
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: AppTextStyles.labelLarge,
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            minimumSize: const Size(double.infinity, 52),
            side: const BorderSide(color: AppColors.primary, width: 1.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: AppTextStyles.labelLarge,
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            textStyle: AppTextStyles.labelLarge,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.muted,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: AppColors.primary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.error),
          ),
          hintStyle: AppTextStyles.bodyMedium
              .copyWith(color: AppColors.mutedForeground),
          labelStyle: AppTextStyles.bodyMedium,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: AppColors.surface,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.mutedForeground,
          elevation: 8,
          type: BottomNavigationBarType.fixed,
        ),
        navigationRailTheme: const NavigationRailThemeData(
          backgroundColor: AppColors.surface,
          selectedIconTheme: IconThemeData(color: AppColors.primary),
          unselectedIconTheme:
              IconThemeData(color: AppColors.mutedForeground),
          selectedLabelTextStyle:
              TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
          indicatorColor: AppColors.primaryContainer,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          elevation: 4,
          shape: CircleBorder(),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: AppColors.muted,
          selectedColor: AppColors.primaryContainer,
          labelStyle: AppTextStyles.labelMedium,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        dividerTheme: const DividerThemeData(
          color: AppColors.divider,
          thickness: 1,
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: AppColors.onSurface,
          contentTextStyle:
              AppTextStyles.bodyMedium.copyWith(color: AppColors.surface),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );

  // ─── Dark Theme ───────────────────────────────────────────
  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: const ColorScheme(
          brightness: Brightness.dark,
          primary: AppColors.secondary,
          onPrimary: AppColors.onSecondary,
          primaryContainer: Color(0xFF881337),
          onPrimaryContainer: AppColors.primaryContainer,
          secondary: AppColors.primary,
          onSecondary: AppColors.onPrimary,
          secondaryContainer: Color(0xFF4A0820),
          onSecondaryContainer: AppColors.secondaryContainer,
          tertiary: Color(0xFF60A5FA),
          onTertiary: Color(0xFF1D4ED8),
          tertiaryContainer: Color(0xFF1D4ED8),
          onTertiaryContainer: AppColors.accentContainer,
          error: Color(0xFFF87171),
          onError: Color(0xFF7F1D1D),
          surface: AppColors.darkSurface,
          onSurface: AppColors.darkOnSurface,
          surfaceContainerHighest: AppColors.darkSurfaceVariant,
          onSurfaceVariant: AppColors.darkOnSurfaceVariant,
          outline: Color(0xFF4A2030),
          outlineVariant: Color(0xFF2D1520),
          scrim: Color(0xCC000000),
          inverseSurface: AppColors.surface,
          onInverseSurface: AppColors.onSurface,
          inversePrimary: AppColors.primary,
        ),
        scaffoldBackgroundColor: AppColors.darkBackground,
        textTheme: _buildTextTheme(AppColors.darkOnSurface),
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.darkSurface,
          foregroundColor: AppColors.darkOnSurface,
          elevation: 0,
          scrolledUnderElevation: 1,
          centerTitle: true,
          titleTextStyle: AppTextStyles.titleLarge
              .copyWith(color: AppColors.darkOnSurface),
        ),
        cardTheme: CardThemeData(
          color: AppColors.darkSurface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFF4A2030), width: 1),
          ),
          margin: EdgeInsets.zero,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: AppColors.darkSurface,
          selectedItemColor: AppColors.secondary,
          unselectedItemColor: AppColors.darkOnSurfaceVariant,
          type: BottomNavigationBarType.fixed,
        ),
        navigationRailTheme: const NavigationRailThemeData(
          backgroundColor: AppColors.darkSurface,
          selectedIconTheme: IconThemeData(color: AppColors.secondary),
          unselectedIconTheme:
              IconThemeData(color: AppColors.darkOnSurfaceVariant),
          indicatorColor: Color(0xFF881337),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          shape: CircleBorder(),
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: AppColors.darkSurfaceVariant,
          contentTextStyle: AppTextStyles.bodyMedium
              .copyWith(color: AppColors.darkOnSurface),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );

  // ─── Helper ───────────────────────────────────────────────
  static TextTheme _buildTextTheme(Color baseColor) => TextTheme(
        displayLarge: AppTextStyles.displayLarge.copyWith(color: baseColor),
        displayMedium: AppTextStyles.displayMedium.copyWith(color: baseColor),
        displaySmall: AppTextStyles.displaySmall.copyWith(color: baseColor),
        headlineLarge: AppTextStyles.headlineLarge.copyWith(color: baseColor),
        headlineMedium:
            AppTextStyles.headlineMedium.copyWith(color: baseColor),
        headlineSmall: AppTextStyles.headlineSmall.copyWith(color: baseColor),
        titleLarge: AppTextStyles.titleLarge.copyWith(color: baseColor),
        titleMedium: AppTextStyles.titleMedium.copyWith(color: baseColor),
        titleSmall: AppTextStyles.titleSmall.copyWith(color: baseColor),
        bodyLarge: AppTextStyles.bodyLarge.copyWith(color: baseColor),
        bodyMedium: AppTextStyles.bodyMedium.copyWith(color: baseColor),
        bodySmall: AppTextStyles.bodySmall,
        labelLarge: AppTextStyles.labelLarge.copyWith(color: baseColor),
        labelMedium: AppTextStyles.labelMedium.copyWith(color: baseColor),
        labelSmall: AppTextStyles.labelSmall,
      );
}
