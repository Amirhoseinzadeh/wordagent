import 'package:flutter/material.dart';

import 'app_colors.dart';

/// ابعاد، شعاع‌ها، فاصله‌ها و زمان‌بندی انیمیشن‌ها.
class AppSpacing {
  const AppSpacing._();

  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 44;

  /// حاشیه‌ی افقی استاندارد صفحات.
  static const EdgeInsets page = EdgeInsets.symmetric(horizontal: md);

  /// حاشیه‌ی کامل صفحه با فضای امن پایین برای نوار ناوبری.
  static const EdgeInsets pageWithBottomNav = EdgeInsets.only(
    left: md,
    right: md,
    bottom: 96,
  );
}

class AppRadius {
  const AppRadius._();

  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 26;
  static const double pill = 999;

  static const BorderRadius card = BorderRadius.all(Radius.circular(md));
  static const BorderRadius cardLarge = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius sheet = BorderRadius.vertical(top: Radius.circular(xl));
  static const BorderRadius chip = BorderRadius.all(Radius.circular(pill));
}

class AppDurations {
  const AppDurations._();

  static const Duration instant = Duration(milliseconds: 90);
  static const Duration fast = Duration(milliseconds: 160);
  static const Duration normal = Duration(milliseconds: 260);
  static const Duration slow = Duration(milliseconds: 420);
  static const Duration page = Duration(milliseconds: 320);
  static const Duration celebration = Duration(milliseconds: 1200);

  static const Curve standardCurve = Curves.easeOutCubic;
  static const Curve emphasizedCurve = Curves.easeOutBack;
  static const Curve smoothCurve = Curves.easeInOutCubic;
}

/// سایه‌های اپلیکیشن — حساس به حالت تیره.
class AppShadows {
  const AppShadows._();

  static List<BoxShadow> soft(bool isDark) => [
        BoxShadow(
          color: isDark ? Colors.black.fade(0.35) : AppColors.lightTextPrimary.fade(0.06),
          blurRadius: 18,
          offset: const Offset(0, 6),
        ),
      ];

  static List<BoxShadow> floating(bool isDark) => [
        BoxShadow(
          color: isDark ? Colors.black.fade(0.48) : AppColors.lightTextPrimary.fade(0.10),
          blurRadius: 28,
          offset: const Offset(0, 12),
        ),
      ];

  static List<BoxShadow> brandGlow() => [
        BoxShadow(
          color: AppColors.brand.fade(0.28),
          blurRadius: 26,
          offset: const Offset(0, 12),
        ),
      ];

  static List<BoxShadow> goldGlow() => [
        BoxShadow(
          color: AppColors.gold.fade(0.32),
          blurRadius: 24,
          offset: const Offset(0, 10),
        ),
      ];
}

/// ابعاد مشترک تصویری.
class AppSizes {
  const AppSizes._();

  static const double iconSm = 16;
  static const double icon = 20;
  static const double iconLg = 26;
  static const double avatar = 44;
  static const double buttonHeight = 52;
  static const double bottomNavHeight = 66;
  static const double cardMinHeight = 96;
  static const double progressRing = 108;
}
