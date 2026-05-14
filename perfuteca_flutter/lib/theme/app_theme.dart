import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';
import 'app_spacing.dart';

abstract class AppTheme {
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.light(
      primary:          AppColors.primary,
      onPrimary:        Colors.white,
      primaryContainer: AppColors.primaryLight,
      secondary:        AppColors.gold,
      onSecondary:      Colors.white,
      surface:          AppColors.surface,
      onSurface:        AppColors.textPrimary,
      background:       AppColors.background,
      onBackground:     AppColors.textPrimary,
      error:            AppColors.error,
    ),
    scaffoldBackgroundColor: AppColors.background,

    // AppBar
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      scrolledUnderElevation: 1,
      shadowColor: AppColors.shadowColor,
      titleTextStyle: AppTextStyles.heading2,
      centerTitle: false,
    ),

    // Cards
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        side: const BorderSide(color: AppColors.primaryLight, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
    ),

    // Botones primarios
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        textStyle: AppTextStyles.button,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.md,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
      ),
    ),

    // Search bar
    searchBarTheme: SearchBarThemeData(
      backgroundColor: WidgetStateProperty.all(AppColors.surfaceVariant),
      elevation: WidgetStateProperty.all(0),
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        ),
      ),
    ),

    // Navigation bar inferior
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.surface,
      indicatorColor: AppColors.primaryLight,
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: AppColors.primaryDark);
        }
        return const IconThemeData(color: AppColors.textMuted);
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppTextStyles.bodySmall.copyWith(
            color: AppColors.primaryDark,
            fontWeight: FontWeight.w600,
          );
        }
        return AppTextStyles.bodySmall;
      }),
    ),

    // Chip (marcas, perfil olfativo)
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.primaryPale,
      labelStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusXxl),
      ),
      side: BorderSide.none,
    ),

    // Dividers
    dividerTheme: const DividerThemeData(
      color: AppColors.primaryLight,
      thickness: 1,
      space: 1,
    ),

    textTheme: const TextTheme(
      headlineLarge:  AppTextStyles.heading1,
      headlineMedium: AppTextStyles.heading2,
      titleMedium:    AppTextStyles.perfumeName,
      bodyMedium:     AppTextStyles.body,
      bodySmall:      AppTextStyles.bodySmall,
      labelSmall:     AppTextStyles.marca,
    ),
  );
}
