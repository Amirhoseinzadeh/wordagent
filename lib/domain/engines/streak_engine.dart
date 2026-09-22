import '../entities/progress.dart';

/// نتیجه‌ی ثبت مطالعه‌ی امروز از دید زنجیره.
enum StreakOutcome {
  /// زنجیره ادامه یافت.
  continued,

  /// زنجیره شکست و از یک شروع شد.
  reset,

  /// زنجیره با کمک «سپر» حفظ شد.
  savedByFreeze,

  /// امروز قبلاً ثبت شده بود.
  alreadyCounted,
}

/// موتور زنجیره‌ی مطالعه‌ی روزانه.
///
/// قوانین:
///  * هر روز مطالعه = یک پله؛ بیش از یک بار در روز تغییری نمی‌دهد؛
///  * یک روز تعطیلی، در صورت داشتن «سپر زنجیره»، جبران می‌شود
///    (کاربر ایرانی سفر و مهمانی دارد؛ سخت‌گیری بی‌جا باعث رهاکردن اپ می‌شود)؛
///  * هر ۷ روز زنجیره، یک سپر (حداکثر ۳ عدد) داده می‌شود.
class StreakEngine {
  const StreakEngine();

  /// حداکثر سپرهای قابل نگهداری.
  static const int maxFreezes = 3;

  /// هر چند روز یک سپر داده می‌شود.
  static const int freezeEveryDays = 7;

  /// مطالعه‌ی امروز را ثبت می‌کند و وضعیت جدید زنجیره را برمی‌گرداند.
  (StreakState, StreakOutcome) registerDay(
    StreakState state, {
    required String dayKey,
  }) {
    if (state.lastStudyDayKey == dayKey) {
      return (state, StreakOutcome.alreadyCounted);
    }

    final previousKey = state.lastStudyDayKey;
    var current = state.current;
    var freezes = state.freezesAvailable;
    var freezesUsed = state.freezesUsed;
    var outcome = StreakOutcome.continued;

    if (previousKey == null) {
      current = 1;
    } else {
      final gap = dayGap(previousKey, dayKey);
      if (gap == 1) {
        current += 1;
      } else if (gap == 2 && freezes > 0) {
        freezes -= 1;
        freezesUsed += 1;
        current += 1;
        outcome = StreakOutcome.savedByFreeze;
      } else {
        current = 1;
        outcome = StreakOutcome.reset;
      }
    }

    if (current > 0 && current % freezeEveryDays == 0 && freezes < maxFreezes) {
      freezes += 1;
    }

    final next = state.copyWith(
      current: current,
      best: current > state.best ? current : state.best,
      lastStudyDayKey: dayKey,
      totalStudyDays: state.totalStudyDays + 1,
      freezesAvailable: freezes,
      freezesUsed: freezesUsed,
    );
    return (next, outcome);
  }

  /// اختلاف روز بین دو کلید روز (قالب yyyy-MM-dd).
  static int dayGap(String fromKey, String toKey) {
    final from = _parseKey(fromKey);
    final to = _parseKey(toKey);
    if (from == null || to == null) return 1;
    return to.difference(from).inDays;
  }

  static DateTime? _parseKey(String key) {
    final parts = key.split('-');
    if (parts.length != 3) return null;
    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final day = int.tryParse(parts[2]);
    if (year == null || month == null || day == null) return null;
    // از زمان UTC استفاده می‌کنیم تا تغییر ساعت، اختلاف روز را جابه‌جا نکند.
    return DateTime.utc(year, month, day);
  }

  /// آیا زنجیره‌ی کاربر در معرض شکستن است؟ (برای کارت هشدار در خانه)
  bool isAtRisk(StreakState state, {required String todayKey}) {
    final last = state.lastStudyDayKey;
    if (last == null) return false;
    return dayGap(last, todayKey) >= 1 && state.current > 0;
  }

  /// پیام مناسب زنجیره برای نمایش در صفحه‌ی خانه.
  String messageFor(StreakOutcome outcome) {
    switch (outcome) {
      case StreakOutcome.continued:
        return 'زنجیره‌ات ادامه یافت!';
      case StreakOutcome.savedByFreeze:
        return 'سپر زنجیره خرج شد و زنجیره‌ات حفظ شد!';
      case StreakOutcome.reset:
        return 'زنجیره‌ی تازه‌ای از امروز شروع شد.';
      case StreakOutcome.alreadyCounted:
        return 'امروز ثبت شده است.';
    }
  }
}
