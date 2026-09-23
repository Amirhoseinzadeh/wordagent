import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_dimens.dart';
import 'app_palette.dart';
import 'app_typography.dart';

/// تم اپلیکیشن (روشن و تیره).
///
/// فلسفه‌ی طراحی: هیچ‌کدام از جزءهای Material به‌صورت سراسری تغییر نمی‌کنند
/// مگر چیزهایی که در تمام نسخه‌های پایدار Flutter ثابت مانده‌اند. بقیه‌ی
/// ظاهر (کارت، دکمه، فیلد ورودی، بج) با ویجت‌های اختصاصی پوشه‌ی widgets
/// ساخته می‌شود؛ نتیجه: کنترل کامل طراحی و پایداری در برابر تغییرات SDK.
class AppTheme {
  const AppTheme._();

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.brand,
      brightness: Brightness.light,
    ).copyWith(
      primary: AppColors.brand,
      onPrimary: Colors.white,
      primaryContainer: AppColors.brandSoftStrong,
      onPrimaryContainer: AppColors.brandDark,
      secondary: AppColors.accentDark,
      onSecondary: Colors.white,
      tertiary: AppColors.goldDeep,
      surface: AppColors.lightSurface,
      onSurface: AppColors.lightTextPrimary,
      error: AppColors.danger,
      onError: Colors.white,
    );
    return _build(scheme, AppPalette.light);
  }

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.brand,
      brightness: Brightness.dark,
    ).copyWith(
      primary: AppColors.brandLight,
      onPrimary: const Color(0xFF191043),
      primaryContainer: const Color(0xFF2C2350),
      onPrimaryContainer: const Color(0xFFE4DEFF),
      secondary: AppColors.accentLight,
      onSecondary: const Color(0xFF00302A),
      tertiary: AppColors.gold,
      surface: AppColors.darkSurface,
      onSurface: AppColors.darkTextPrimary,
      error: const Color(0xFFF97066),
      onError: const Color(0xFF3B0A06),
    );
    return _build(scheme, AppPalette.dark);
  }

  static ThemeData _build(ColorScheme scheme, AppPalette palette) {
    final isDark = palette.isDark;
    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      colorScheme: scheme,
      scaffoldBackgroundColor: palette.background,
      canvasColor: palette.surface,
      fontFamily: AppTypography.fontFamily,
      splashFactory: InkRipple.splashFactory,
      visualDensity: VisualDensity.standard,
      textTheme: AppTypography.textTheme.apply(
        bodyColor: palette.textPrimary,
        displayColor: palette.textPrimary,
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: AppColors.brand,
        selectionColor: AppColors.brandSoftStrong,
        selectionHandleColor: AppColors.brand,
      ),
      dividerTheme: DividerThemeData(
        color: palette.border,
        thickness: 1,
        space: 1,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: palette.textSecondary,
        textColor: palette.textPrimary,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.card),
      ),
      extensions: <ThemeExtension<dynamic>>[palette],
    );
  }
}
