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
      error:            AppColors.error,
    ),
    scaffoldBackgroundColor: AppColors.background,

    // AppBar — sin const porque titleTextStyle usa GoogleFonts (no const)
    appBarTheme: AppBarTheme(
      backgroundColor:        AppColors.surface,
      foregroundColor:        AppColors.textPrimary,
      elevation:              0,
      scrolledUnderElevation: 1,
      shadowColor:            AppColors.shadowColor,
      titleTextStyle:         AppTextStyles.heading2,
      centerTitle:            false,
    ),

    // Cards
    cardTheme: CardThemeData(
      color:     AppColors.surface,
      elevation: 2,
      shadowColor: AppColors.primary.withValues(alpha: 0.10),
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
          vertical:   AppSpacing.md,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
      ),
    ),

    // Search bar
    searchBarTheme: SearchBarThemeData(
      backgroundColor: WidgetStateProperty.all(AppColors.surfaceVariant),
      elevation:       WidgetStateProperty.all(0),
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        ),
      ),
    ),

    // Navigation bar
    navigationBarTheme: NavigationBarThemeData(
      height:           72,
      backgroundColor:  AppColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation:        0,
      indicatorColor:   AppColors.primaryLight,
      indicatorShape:   RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: AppColors.primaryDark, size: 22);
        }
        return const IconThemeData(color: AppColors.textFaint, size: 22);
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppTextStyles.bodySmall.copyWith(
            color:      AppColors.primaryDark,
            fontWeight: FontWeight.w700,
            fontSize:   11,
          );
        }
        return AppTextStyles.bodySmall.copyWith(
          color:    AppColors.textFaint,
          fontSize: 11,
        );
      }),
    ),

    // Chip (marcas, perfil olfativo)
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.primaryPale,
      labelStyle:      AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical:   AppSpacing.xs,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusXxl),
      ),
      side: BorderSide.none,
    ),

    // Dividers
    dividerTheme: const DividerThemeData(
      color:     AppColors.primaryLight,
      thickness: 1,
      space:     1,
    ),

    // TextTheme — sin const porque heading1/2/perfumeName usan GoogleFonts
    textTheme: TextTheme(
      headlineLarge:  AppTextStyles.heading1,
      headlineMedium: AppTextStyles.heading2,
      titleMedium:    AppTextStyles.perfumeName,
      bodyMedium:     AppTextStyles.body,
      bodySmall:      AppTextStyles.bodySmall,
      labelSmall:     AppTextStyles.marca,
    ),
  );
}
