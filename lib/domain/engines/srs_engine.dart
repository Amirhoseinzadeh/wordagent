import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../entities/review_state.dart';

/// کیفیت یادآوری که کاربر پس از دیدن کارت انتخاب می‌کند.
enum ReviewGrade {
  forgot(faLabel: 'فراموش کردم', shortLabel: 'فراموش', quality: 0),
  hard(faLabel: 'سخت بود', shortLabel: 'سخت', quality: 2),
  good(faLabel: 'خوب بود', shortLabel: 'خوب', quality: 3),
  easy(faLabel: 'آسان بود', shortLabel: 'آسان', quality: 5);

  const ReviewGrade({
    required this.faLabel,
    required this.shortLabel,
    required this.quality,
  });

  final String faLabel;
  final String shortLabel;

  /// کیفیت استاندارد SM-2 (۰ تا ۵).
  final int quality;

  bool get isFailure => this == ReviewGrade.forgot;
}

/// موتور تکرار فاصله‌دار.
///
/// الگوریتم: نسخه‌ی توسعه‌یافته‌ی SM-2 با اصلاح‌های تجربی:
///  * مراحل کوتاه‌مدت برای واژه‌های تازه (۱۰ دقیقه → ۱ روز → ۳ روز)؛
///  * ضریب آسانی پویا بین ۱٫۳ و ۲٫۸؛
///  * پاداش/جریمه‌ی ملایم برای پاسخ‌های سخت و آسان؛
///  * لرزش تصادفیِ *قطعی* روی فاصله‌های بلند تا مرورها در یک روز تلنبار نشوند
///    (قطعی بودن یعنی خروجی برای ورودی یکسان همیشه یکسان است و تست‌پذیر می‌ماند)؛
///  * شناسایی واژه‌های «سخت‌آموز» (leech) پس از ۵ فراموشی.
class SpacedRepetitionEngine {
  const SpacedRepetitionEngine();

  /// حداقل ضریب آسانی.
  static const double minEase = 1.3;

  /// حداکثر ضریب آسانی.
  static const double maxEase = 2.8;

  /// سقف فاصله‌ی مرور (روز).
  static const double maxIntervalDays = 365;

  /// مرحله‌ی کوتاه‌مدت پس از فراموشی (دقیقه).
  static const int relearnMinutes = 10;

  /// نتیجه‌ی یک مرور را روی وضعیت واژه اعمال می‌کند.
  ReviewState apply({
    required ReviewState state,
    required ReviewGrade grade,
    required DateTime now,
  }) {
    var ease = state.ease;
    var repetitions = state.repetitions;
    var interval = state.intervalDays;
    var lapses = state.lapses;
    var currentStreak = state.currentStreak;

    if (grade.isFailure) {
      lapses += 1;
      repetitions = 0;
      ease = math.max(minEase, ease - 0.2);
      interval = relearnMinutes / (60 * 24);
      currentStreak = 0;
    } else {
      ease = grade == ReviewGrade.hard
          ? math.max(minEase, ease - 0.15)
          : grade == ReviewGrade.easy
              ? math.min(maxEase, ease + 0.15)
              : ease;

      if (repetitions == 0) {
        interval = _firstInterval(grade);
      } else if (repetitions == 1) {
        interval = _secondInterval(grade);
      } else {
        switch (grade) {
          case ReviewGrade.hard:
            interval = math.max(1, interval * 1.2);
          case ReviewGrade.good:
            interval = interval * ease;
          case ReviewGrade.easy:
            interval = interval * ease * 1.25;
          case ReviewGrade.forgot:
            interval = relearnMinutes / (60 * 24);
        }
      }

      repetitions += 1;
      currentStreak += 1;
    }

    // ترتیب مهم است: اول لرزش، بعد محدودسازی؛ وگرنه لرزش می‌تواند
    // فاصله را کمی از سقف یک‌ساله بالاتر ببرد.
    if (interval > 2) {
      interval = _fuzz(interval, state.wordId, state.totalReviews + 1);
    }
    interval = interval.clamp(relearnMinutes / (60 * 24), maxIntervalDays);

    final dueAt = now.add(_durationFromDays(interval));
    final totalReviews = state.totalReviews + 1;
    final correctReviews = state.correctReviews + (grade.isFailure ? 0 : 1);
    final responseMs = state.averageResponseMs;

    return state.copyWith(
      repetitions: repetitions,
      ease: ease,
      intervalDays: interval,
      dueAt: dueAt,
      lastReviewedAt: now,
      firstSeenAt: state.firstSeenAt ?? now,
      lapses: lapses,
      totalReviews: totalReviews,
      correctReviews: correctReviews,
      currentStreak: currentStreak,
      bestStreak: math.max(state.bestStreak, currentStreak),
      averageResponseMs: responseMs,
    );
  }

  /// فاصله‌ی حاصل از هر گزینه را *بدون* تغییر وضعیت برمی‌گرداند
  /// (برای نمایش «۳ روز» روی دکمه‌های کارت مرور).
  Map<ReviewGrade, Duration> previewIntervals(ReviewState state) {
    final result = <ReviewGrade, Duration>{};
    for (final grade in ReviewGrade.values) {
      final next = apply(state: state, grade: grade, now: DateTime(2000));
      result[grade] = _durationFromDays(next.intervalDays);
    }
    return result;
  }

  /// آیا این واژه به ترفند حفظ و تمرین ویژه نیاز دارد؟
  bool isLeech(ReviewState state) => state.lapses >= 5 && state.intervalDays < 21;

  double _firstInterval(ReviewGrade grade) {
    switch (grade) {
      case ReviewGrade.hard:
        return 0.5;
      case ReviewGrade.good:
        return 1;
      case ReviewGrade.easy:
        return 4;
      case ReviewGrade.forgot:
        return relearnMinutes / (60 * 24);
    }
  }

  double _secondInterval(ReviewGrade grade) {
    switch (grade) {
      case ReviewGrade.hard:
        return 2;
      case ReviewGrade.good:
        return 3;
      case ReviewGrade.easy:
        return 7;
      case ReviewGrade.forgot:
        return relearnMinutes / (60 * 24);
    }
  }

  /// لرزش قطعی ±۵٪ بر پایه‌ی شناسه‌ی واژه و شماره‌ی مرور.
  double _fuzz(double interval, String wordId, int reviewIndex) {
    final seed = wordId.hashCode.abs() % 1000 + reviewIndex * 37;
    final pseudo = ((seed * 9301 + 49297) % 233280) / 233280; // بازه‌ی ۰ تا ۱
    final factor = 0.95 + pseudo * 0.1;
    return interval * factor;
  }

  Duration _durationFromDays(double days) {
    final minutes = (days * 24 * 60).round();
    if (minutes <= 0) return const Duration(minutes: relearnMinutes);
    return Duration(minutes: minutes);
  }
}

/// نگاشت نتیجه‌ی تمرین‌های تعاملی به کیفیت مرور (برای به‌روزرسانی SRS).
class GradeMapper {
  const GradeMapper._();

  static ReviewGrade fromQuiz({
    required bool isCorrect,
    required int elapsedMs,
    required bool wasTyped,
  }) {
    if (!isCorrect) return ReviewGrade.forgot;
    // پاسخ سریع به سؤال تایپی یعنی تسلط بالا.
    if (wasTyped && elapsedMs > 0 && elapsedMs < 6000) return ReviewGrade.easy;
    if (elapsedMs > 0 && elapsedMs > 20000) return ReviewGrade.hard;
    return ReviewGrade.good;
  }
}

/// خلاصه‌ی زمان‌بندی صف مرور (برای نمایش در صفحه‌ی خانه).
@immutable
class ReviewForecast {
  const ReviewForecast({
    required this.dueNow,
    required this.dueToday,
    required this.dueThisWeek,
    required this.dueLater,
  });

  final int dueNow;
  final int dueToday;
  final int dueThisWeek;
  final int dueLater;

  int get total => dueNow + dueToday + dueThisWeek + dueLater;
}
