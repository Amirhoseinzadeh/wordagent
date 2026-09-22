import 'package:flutter/material.dart';

/// پالت رنگ برند «واژه‌یار».
///
/// همه‌ی رنگ‌ها به‌صورت ثابت (const) تعریف شده‌اند تا رنگ‌های نیمه‌شفاف
/// به‌جای محاسبه‌ی زمان اجرا، در همان پالت مشخص باشند؛ نتیجه: سازگاری کامل
/// با حالت روشن/تیره و جلوگیری از دوباره‌رسمی‌های بی‌مورد.
class AppColors {
  const AppColors._();

  // ------------------------------------------------------------ رنگ برند
  /// بنفش-نیلی اصلی برند.
  static const brand = Color(0xFF6C4CF1);
  static const brandDark = Color(0xFF5638D8);
  static const brandLight = Color(0xFF9E8BFF);
  static const brandSoft = Color(0x1F6C4CF1);
  static const brandSoftStrong = Color(0x336C4CF1);

  /// سبزآبی مکمل (برای وضعیت «درست»، پیشرفت و گراف‌ها).
  static const accent = Color(0xFF00BFA5);
  static const accentDark = Color(0xFF00907D);
  static const accentLight = Color(0xFF5CE0CC);
  static const accentSoft = Color(0x1F00BFA5);

  /// طلایی — ویژه‌ی زنجیره، امتیاز و نسخه‌ی premium.
  static const gold = Color(0xFFF5A524);
  static const goldDeep = Color(0xFFD97B06);
  static const goldSoft = Color(0x24F5A524);

  /// سرخابی برای حالت‌های احساسی و جشن‌ها.
  static const pink = Color(0xFFF04492);
  static const pinkSoft = Color(0x1FF04492);

  static const success = Color(0xFF17B26A);
  static const successSoft = Color(0x1F17B26A);
  static const warning = Color(0xFFF79009);
  static const warningSoft = Color(0x1FF79009);
  static const danger = Color(0xFFF04438);
  static const dangerSoft = Color(0x1FF04438);
  static const info = Color(0xFF2E90FA);
  static const infoSoft = Color(0x1F2E90FA);

  // -------------------------------------------------------- سطح روشن
  static const lightBackground = Color(0xFFF6F7FC);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightSurfaceAlt = Color(0xFFF0F1F8);
  static const lightBorder = Color(0xFFE4E6F0);
  static const lightTextPrimary = Color(0xFF111629);
  static const lightTextSecondary = Color(0xFF5A6178);
  static const lightTextTertiary = Color(0xFF8B91A7);

  // -------------------------------------------------------- سطح تیره
  static const darkBackground = Color(0xFF0A0D16);
  static const darkSurface = Color(0xFF141926);
  static const darkSurfaceAlt = Color(0xFF1C2233);
  static const darkBorder = Color(0xFF272E42);
  static const darkTextPrimary = Color(0xFFF4F6FB);
  static const darkTextSecondary = Color(0xFFA8B0C4);
  static const darkTextTertiary = Color(0xFF6F7789);

  // ------------------------------------------------------------- گرادیان
  static const brandGradient = LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [Color(0xFF7B5CFF), Color(0xFF5B3BE0)],
  );

  static const accentGradient = LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [Color(0xFF19D3B4), Color(0xFF00907D)],
  );

  static const goldGradient = LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [Color(0xFFFFC948), Color(0xFFEC8E00)],
  );

  static const sunsetGradient = LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [Color(0xFFF04492), Color(0xFF7B5CFF)],
  );

  static const darkHeaderGradient = LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [Color(0xFF241A4D), Color(0xFF0A0D16)],
  );
}

/// کمکی‌های رنگ — بدون استفاده از API‌های منسوخ‌شده.
extension AppColorX on Color {
  /// نسخه‌ی نیمه‌شفاف همین رنگ با شفافیت دلخواه (۰ تا ۱).
  Color fade(double opacity) {
    final argb = toARGB32();
    final alpha = (opacity.clamp(0.0, 1.0) * 255).round();
    return Color.fromARGB(
      alpha,
      (argb >> 16) & 0xFF,
      (argb >> 8) & 0xFF,
      argb & 0xFF,
    );
  }

  /// روشن‌تر کردن رنگ برای حالت هاور/انتخاب.
  Color lighten([double amount = 0.12]) => Color.lerp(this, Colors.white, amount) ?? this;

  /// تیره‌تر کردن رنگ.
  Color darken([double amount = 0.12]) => Color.lerp(this, Colors.black, amount) ?? this;
}
