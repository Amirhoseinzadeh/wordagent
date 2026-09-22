import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// ساعت مرکزی اپلیکیشن.
///
/// همه‌ی محاسبات زمانی (مرور، زنجیره، چالش روزانه) از این‌جا عبور می‌کنند تا
/// تست‌ها بتوانند زمان را جعل کنند.
class AppClock {
  AppClock({DateTime Function()? provider}) : _provider = provider ?? DateTime.now;

  final DateTime Function() _provider;

  DateTime now() => _provider();

  DateTime get today {
    final current = now();
    return DateTime(current.year, current.month, current.day);
  }

  /// ساعت شروع «روز مطالعه»؛ کسی که نیمه‌شب تا ۴ صبح درس بخواند،
  /// زنجیره‌اش نمی‌شکند و کارِ همان روز حساب می‌شود.
  static const int studyDayStartHour = 4;

  /// شماره‌ی روزهای مطلق (برای محاسبه‌ی اختلاف روزها).
  int dayNumber(DateTime moment) =>
      DateTime(moment.year, moment.month, moment.day).millisecondsSinceEpoch ~/
      Duration.millisecondsPerDay;

  /// روز مطالعه‌ی جاری به شکل رشته‌ی یکتا: «2026-09-22».
  String studyDayKey([DateTime? moment]) {
    final value = (moment ?? now()).subtract(
      const Duration(hours: studyDayStartHour),
    );
    final month = value.month < 10 ? '0${value.month}' : '${value.month}';
    final day = value.day < 10 ? '0${value.day}' : '${value.day}';
    return '${value.year}-$month-$day';
  }

  /// شماره‌ی هفته‌ی سال (برای محاسبه‌ی امتیاز هفتگی).
  String weekKey([DateTime? moment]) {
    final value = moment ?? now();
    final thursday = value.add(Duration(days: 4 - ((value.weekday + 1) % 7)));
    final firstOfYear = DateTime(thursday.year, 1, 1);
    final week = ((thursday.difference(firstOfYear).inDays) / 7).floor() + 1;
    return '${thursday.year}-W${week < 10 ? '0$week' : week}';
  }
}

/// بازخورد لمسی (هپتیک).
class Haptics {
  Haptics({this.enabled = true});

  bool enabled;

  void tap() {
    if (!enabled) return;
    unawaited(HapticFeedback.selectionClick());
  }

  void light() {
    if (!enabled) return;
    unawaited(HapticFeedback.lightImpact());
  }

  void success() {
    if (!enabled) return;
    unawaited(HapticFeedback.mediumImpact());
  }

  void celebrate() {
    if (!enabled) return;
    unawaited(HapticFeedback.heavyImpact());
  }
}

/// فراخوانی بیرون‌از‌نوبت یک Future را گویا می‌کند.
void unawaited(Future<void> future) {
  future.catchError((Object error) {
    if (kDebugMode) {
      debugPrint('unawaited error: $error');
    }
  });
}
