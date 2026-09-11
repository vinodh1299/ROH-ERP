// lib/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';
import 'app_spacing.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.background,
        fontFamily: AppTypography.fontFamily,
        colorScheme: const ColorScheme.light(
          primary: AppColors.primary,
          primaryContainer: AppColors.primaryLight,
          secondary: AppColors.primaryDark,
          surface: AppColors.surface,
          error: AppColors.error,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: AppColors.textPrimary,
          onError: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.surface,
          elevation: 0,
          scrolledUnderElevation: 0,
          titleTextStyle: AppTypography.titleLarge,
          iconTheme: IconThemeData(color: AppColors.textPrimary),
        ),
        cardTheme: CardThemeData(
          color: AppColors.surface,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            side: const BorderSide(color: AppColors.border, width: 1),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surface,
          labelStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
          hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textDisabled),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: const BorderSide(color: AppColors.border, width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: const BorderSide(color: AppColors.border, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: const BorderSide(color: AppColors.error, width: 1),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 14),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 14),
            textStyle: AppTypography.titleMedium.copyWith(color: Colors.white),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textPrimary,
            side: const BorderSide(color: AppColors.border, width: 1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 14),
            textStyle: AppTypography.titleMedium,
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            textStyle: AppTypography.titleMedium,
          ),
        ),
        tabBarTheme: const TabBarThemeData(
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          indicatorSize: TabBarIndicatorSize.label,
          labelStyle: TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
        ),
        dividerTheme: const DividerThemeData(
          color: AppColors.border,
          thickness: 1,
          space: 1,
        ),
      );
}
