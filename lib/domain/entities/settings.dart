import 'package:flutter/foundation.dart';

/// حالت ظاهری اپلیکیشن.
enum AppThemeMode {
  system,
  light,
  dark;

  static AppThemeMode fromName(String? name, {AppThemeMode fallback = AppThemeMode.system}) {
    if (name == null) return fallback;
    for (final mode in AppThemeMode.values) {
      if (mode.name == name) return mode;
    }
    return fallback;
  }
}

/// تنظیمات کاربر.
@immutable
class AppSettings {
  const AppSettings({
    this.themeMode = AppThemeMode.system,
    this.dailyGoalMinutes = 15,
    this.dailyNewWords = 10,
    this.remindersEnabled = true,
    this.reminderHour = 20,
    this.reminderMinute = 30,
    this.speechSpeed = 1,
    this.autoPlayAudio = false,
    this.hapticsEnabled = true,
    this.showPersianHints = true,
    this.dailyFreeLimitEnabled = true,
  });

  final AppThemeMode themeMode;

  /// هدف روزانه بر حسب دقیقه (۵ تا ۶۰).
  final int dailyGoalMinutes;

  /// تعداد واژه‌ی تازه در هر روز (۵ تا ۳۰).
  final int dailyNewWords;

  final bool remindersEnabled;
  final int reminderHour;
  final int reminderMinute;

  /// ضریب سرعت تلفظ (۰٫۷۵ / ۱ / ۱٫۲۵).
  final double speechSpeed;

  /// پخش خودکار تلفظ هنگام نمایش کارت واژه.
  final bool autoPlayAudio;

  /// بازخورد لمسی.
  final bool hapticsEnabled;

  /// نمایش نکته‌های مخصوص فارسی‌زبانان در کارت واژه.
  final bool showPersianHints;

  /// اعمال سهمیه‌ی روزانه‌ی نسخه‌ی رایگان.
  final bool dailyFreeLimitEnabled;

  /// هدف روزانه بر حسب تعداد واژه، برای نمایش در خانه.
  int get dailyGoalCards => (dailyGoalMinutes * 1.4).round().clamp(5, 90);

  String get reminderLabel {
    final hour = reminderHour < 10 ? '0$reminderHour' : '$reminderHour';
    final minute = reminderMinute < 10 ? '0$reminderMinute' : '$reminderMinute';
    return '$hour:$minute';
  }

  AppSettings copyWith({
    AppThemeMode? themeMode,
    int? dailyGoalMinutes,
    int? dailyNewWords,
    bool? remindersEnabled,
    int? reminderHour,
    int? reminderMinute,
    double? speechSpeed,
    bool? autoPlayAudio,
    bool? hapticsEnabled,
    bool? showPersianHints,
    bool? dailyFreeLimitEnabled,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      dailyGoalMinutes: dailyGoalMinutes ?? this.dailyGoalMinutes,
      dailyNewWords: dailyNewWords ?? this.dailyNewWords,
      remindersEnabled: remindersEnabled ?? this.remindersEnabled,
      reminderHour: reminderHour ?? this.reminderHour,
      reminderMinute: reminderMinute ?? this.reminderMinute,
      speechSpeed: speechSpeed ?? this.speechSpeed,
      autoPlayAudio: autoPlayAudio ?? this.autoPlayAudio,
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
      showPersianHints: showPersianHints ?? this.showPersianHints,
      dailyFreeLimitEnabled: dailyFreeLimitEnabled ?? this.dailyFreeLimitEnabled,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is AppSettings &&
      other.themeMode == themeMode &&
      other.dailyGoalMinutes == dailyGoalMinutes &&
      other.dailyNewWords == dailyNewWords &&
      other.remindersEnabled == remindersEnabled &&
      other.reminderHour == reminderHour &&
      other.reminderMinute == reminderMinute &&
      other.speechSpeed == speechSpeed &&
      other.autoPlayAudio == autoPlayAudio &&
      other.hapticsEnabled == hapticsEnabled &&
      other.showPersianHints == showPersianHints &&
      other.dailyFreeLimitEnabled == dailyFreeLimitEnabled;

  @override
  int get hashCode => Object.hash(
        themeMode,
        dailyGoalMinutes,
        dailyNewWords,
        remindersEnabled,
        reminderHour,
        reminderMinute,
        speechSpeed,
        autoPlayAudio,
        hapticsEnabled,
        showPersianHints,
        dailyFreeLimitEnabled,
      );
}
