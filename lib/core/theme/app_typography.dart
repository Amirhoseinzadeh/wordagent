import 'package:flutter/material.dart';

import 'app_colors.dart';

/// تایپوگرافی اپلیکیشن بر پایه‌ی فونت وزیرمتن.
///
/// نکته‌های طراحی برای متن فارسی:
/// * ارتفاع خط بازتر (۱٫۶ تا ۱٫۹) چون فارسی کشیدگی و اعراب دارد؛
/// * بدون فاصله‌ی حروف (letterSpacing = 0) چون اتصال حروف را می‌شکند؛
/// * وزن‌های ۵۰۰/۶۰۰ برای تیترها تا در حالت تیره هم خوانا بمانند.
class AppTypography {
  const AppTypography._();

  static const String fontFamily = 'Vazirmatn';

  /// فونت جایگزین برای نمایش واژه‌ی انگلیسی (هنگام نبود فونت اصلی).
  static const String englishFallback = 'Vazirmatn';

  static const TextTheme textTheme = TextTheme(
    displayLarge: TextStyle(
      fontFamily: fontFamily,
      fontSize: 40,
      height: 1.35,
      fontWeight: FontWeight.w800,
      letterSpacing: 0,
    ),
    displayMedium: TextStyle(
      fontFamily: fontFamily,
      fontSize: 34,
      height: 1.35,
      fontWeight: FontWeight.w800,
    ),
    displaySmall: TextStyle(
      fontFamily: fontFamily,
      fontSize: 28,
      height: 1.4,
      fontWeight: FontWeight.w700,
    ),
    headlineLarge: TextStyle(
      fontFamily: fontFamily,
      fontSize: 26,
      height: 1.45,
      fontWeight: FontWeight.w700,
    ),
    headlineMedium: TextStyle(
      fontFamily: fontFamily,
      fontSize: 23,
      height: 1.45,
      fontWeight: FontWeight.w700,
    ),
    headlineSmall: TextStyle(
      fontFamily: fontFamily,
      fontSize: 20,
      height: 1.5,
      fontWeight: FontWeight.w700,
    ),
    titleLarge: TextStyle(
      fontFamily: fontFamily,
      fontSize: 18,
      height: 1.5,
      fontWeight: FontWeight.w700,
    ),
    titleMedium: TextStyle(
      fontFamily: fontFamily,
      fontSize: 16,
      height: 1.5,
      fontWeight: FontWeight.w600,
    ),
    titleSmall: TextStyle(
      fontFamily: fontFamily,
      fontSize: 14,
      height: 1.5,
      fontWeight: FontWeight.w600,
    ),
    bodyLarge: TextStyle(
      fontFamily: fontFamily,
      fontSize: 16,
      height: 1.8,
      fontWeight: FontWeight.w400,
    ),
    bodyMedium: TextStyle(
      fontFamily: fontFamily,
      fontSize: 14.5,
      height: 1.8,
      fontWeight: FontWeight.w400,
    ),
    bodySmall: TextStyle(
      fontFamily: fontFamily,
      fontSize: 13,
      height: 1.75,
      fontWeight: FontWeight.w400,
    ),
    labelLarge: TextStyle(
      fontFamily: fontFamily,
      fontSize: 14.5,
      height: 1.4,
      fontWeight: FontWeight.w600,
    ),
    labelMedium: TextStyle(
      fontFamily: fontFamily,
      fontSize: 12.5,
      height: 1.4,
      fontWeight: FontWeight.w600,
    ),
    labelSmall: TextStyle(
      fontFamily: fontFamily,
      fontSize: 11.5,
      height: 1.4,
      fontWeight: FontWeight.w600,
    ),
  );

  /// استایل نمایش خود واژه‌ی انگلیسی (کمی بزرگ‌تر و با فاصله‌ی حروف استاندارد لاتین).
  static const TextStyle wordDisplay = TextStyle(
    fontFamily: englishFallback,
    fontSize: 34,
    height: 1.25,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.2,
  );

  static const TextStyle wordTitle = TextStyle(
    fontFamily: englishFallback,
    fontSize: 22,
    height: 1.3,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle ipa = TextStyle(
    fontFamily: englishFallback,
    fontSize: 15,
    height: 1.4,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.3,
    color: AppColors.brand,
  );

  /// متنی که کاربر باید تایپ کند یا با آن پاسخ می‌دهد.
  static const TextStyle answer = TextStyle(
    fontFamily: englishFallback,
    fontSize: 18,
    height: 1.6,
    fontWeight: FontWeight.w500,
  );
}
