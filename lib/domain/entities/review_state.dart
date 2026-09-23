import 'package:flutter/foundation.dart';

/// وضعیت یادگیری یک واژه از دید کاربر.
enum WordStatus {
  /// هنوز هیچ‌گاه مطالعه نشده.
  fresh,

  /// در مرحله‌ی یادگیری اولیه (چند ساعت تا چند روز).
  learning,

  /// در چرخه‌ی مرور بلندمدت.
  reviewing,

  /// مرورهای متعدد موفق؛ فاصله‌ی مرور بیش از یک ماه.
  mastered,

  /// واژه‌ای که کاربر بارها فراموشش کرده (نیازمند ترفند حافظه).
  leech;

  bool get isActive => this != WordStatus.fresh;
}

/// وضعیت تکرار فاصله‌دار (Spaced Repetition) برای یک واژه.
@immutable
class ReviewState {
  const ReviewState({
    required this.wordId,
    this.repetitions = 0,
    this.ease = 2.5,
    this.intervalDays = 0,
    this.dueAt,
    this.lastReviewedAt,
    this.lapses = 0,
    this.totalReviews = 0,
    this.correctReviews = 0,
    this.currentStreak = 0,
    this.bestStreak = 0,
    this.bookmarked = false,
    this.note,
    this.errorsByType = const <String, int>{},
    this.correctByType = const <String, int>{},
    this.averageResponseMs = 0,
    this.firstSeenAt,
  });

  final String wordId;

  /// تعداد مرورهای موفق پشت‌سرهم (شاخص اصلی SRS).
  final int repetitions;

  /// ضریب آسانی (۱٫۳ تا ۲٫۸).
  final double ease;

  /// فاصله‌ی فعلی تا مرور بعدی (روز).
  final double intervalDays;

  /// زمان مرور بعدی.
  final DateTime? dueAt;
  final DateTime? lastReviewedAt;
  final DateTime? firstSeenAt;

  /// تعداد فراموشی‌ها.
  final int lapses;

  final int totalReviews;
  final int correctReviews;

  /// پاسخ‌های درست پشت‌سرهم.
  final int currentStreak;
  final int bestStreak;

  final bool bookmarked;
  final String? note;

  /// تعداد خطا به تفکیک نوع تمرین (کلید: نام `QuizType`).
  final Map<String, int> errorsByType;
  final Map<String, int> correctByType;

  /// میانگین زمان پاسخ‌دهی (میلی‌ثانیه).
  final int averageResponseMs;

  bool get isNew => totalReviews == 0;

  /// آیا واژه وارد چرخه‌ی یادگیری شده است؟
  bool get isActive => totalReviews > 0 || firstSeenAt != null;

  double get accuracy => totalReviews == 0 ? 0 : correctReviews / totalReviews;

  /// وضعیت مشتق‌شده از داده‌های SRS.
  WordStatus get status {
    if (totalReviews == 0) return WordStatus.fresh;
    if (lapses >= 5 && intervalDays < 21) return WordStatus.leech;
    if (intervalDays >= 30 && repetitions >= 4) return WordStatus.mastered;
    if (repetitions <= 1 || intervalDays < 2) return WordStatus.learning;
    return WordStatus.reviewing;
  }

  /// درصد تسلط (۰ تا ۱۰۰) برای نمودارها و نوار پیشرفت.
  int get masteryPercent {
    if (totalReviews == 0) return 0;
    final intervalScore = (intervalDays / 60).clamp(0.0, 1.0);
    final repetitionScore = (repetitions / 6).clamp(0.0, 1.0);
    final accuracyScore = accuracy;
    final value = (intervalScore * 0.5 + repetitionScore * 0.3 + accuracyScore * 0.2) * 100;
    return value.round().clamp(0, 100);
  }

  /// آیا زمان مرورش رسیده است؟
  bool isDue(DateTime now) => dueAt != null && !dueAt!.isAfter(now);

  /// فاصله تا موعد مرور.
  Duration timeUntilDue(DateTime now) {
    final due = dueAt;
    if (due == null) return Duration.zero;
    final diff = due.difference(now);
    return diff.isNegative ? Duration.zero : diff;
  }

  ReviewState copyWith({
    String? wordId,
    int? repetitions,
    double? ease,
    double? intervalDays,
    DateTime? dueAt,
    DateTime? lastReviewedAt,
    DateTime? firstSeenAt,
    int? lapses,
    int? totalReviews,
    int? correctReviews,
    int? currentStreak,
    int? bestStreak,
    bool? bookmarked,
    String? note,
    Map<String, int>? errorsByType,
    Map<String, int>? correctByType,
    int? averageResponseMs,
    bool clearNote = false,
  }) {
    return ReviewState(
      wordId: wordId ?? this.wordId,
      repetitions: repetitions ?? this.repetitions,
      ease: ease ?? this.ease,
      intervalDays: intervalDays ?? this.intervalDays,
      dueAt: dueAt ?? this.dueAt,
      lastReviewedAt: lastReviewedAt ?? this.lastReviewedAt,
      firstSeenAt: firstSeenAt ?? this.firstSeenAt,
      lapses: lapses ?? this.lapses,
      totalReviews: totalReviews ?? this.totalReviews,
      correctReviews: correctReviews ?? this.correctReviews,
      currentStreak: currentStreak ?? this.currentStreak,
      bestStreak: bestStreak ?? this.bestStreak,
      bookmarked: bookmarked ?? this.bookmarked,
      note: clearNote ? null : (note ?? this.note),
      errorsByType: errorsByType ?? this.errorsByType,
      correctByType: correctByType ?? this.correctByType,
      averageResponseMs: averageResponseMs ?? this.averageResponseMs,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ReviewState &&
      other.wordId == wordId &&
      other.repetitions == repetitions &&
      other.ease == ease &&
      other.intervalDays == intervalDays &&
      other.dueAt == dueAt &&
      other.totalReviews == totalReviews &&
      other.correctReviews == correctReviews &&
      other.bookmarked == bookmarked &&
      other.note == note;

  @override
  int get hashCode => Object.hash(
        wordId,
        repetitions,
        ease,
        intervalDays,
        dueAt,
        totalReviews,
        correctReviews,
        bookmarked,
        note,
      );
}
