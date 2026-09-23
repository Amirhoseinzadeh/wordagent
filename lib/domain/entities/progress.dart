import 'package:flutter/foundation.dart';

/// وضعیت زنجیره‌ی مطالعه‌ی روزانه (Streak).
@immutable
class StreakState {
  const StreakState({
    this.current = 0,
    this.best = 0,
    this.lastStudyDayKey,
    this.totalStudyDays = 0,
    this.freezesAvailable = 0,
    this.freezesUsed = 0,
  });

  final int current;
  final int best;

  /// کلید روز آخرین مطالعه («2026-09-22»).
  final String? lastStudyDayKey;

  /// تعداد کل روزهایی که مطالعه شده است.
  final int totalStudyDays;

  /// تعداد «سپر زنجیره» باقی‌مانده (هر ۷ روز یک عدد).
  final int freezesAvailable;
  final int freezesUsed;

  bool get isActive => current > 0;

  /// آیا این هفته یک روز تعطیلی داشته که با سپر جبران شده است؟
  bool get usedFreeze => freezesUsed > 0;

  StreakState copyWith({
    int? current,
    int? best,
    String? lastStudyDayKey,
    int? totalStudyDays,
    int? freezesAvailable,
    int? freezesUsed,
  }) {
    return StreakState(
      current: current ?? this.current,
      best: best ?? this.best,
      lastStudyDayKey: lastStudyDayKey ?? this.lastStudyDayKey,
      totalStudyDays: totalStudyDays ?? this.totalStudyDays,
      freezesAvailable: freezesAvailable ?? this.freezesAvailable,
      freezesUsed: freezesUsed ?? this.freezesUsed,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is StreakState &&
      other.current == current &&
      other.best == best &&
      other.lastStudyDayKey == lastStudyDayKey &&
      other.totalStudyDays == totalStudyDays &&
      other.freezesAvailable == freezesAvailable &&
      other.freezesUsed == freezesUsed;

  @override
  int get hashCode => Object.hash(current, best, lastStudyDayKey, totalStudyDays,
      freezesAvailable, freezesUsed);
}

/// وضعیت امتیاز تجربه و سطح کاربر.
@immutable
class XpState {
  const XpState({
    this.totalXp = 0,
    this.dailyXp = 0,
    this.dayKey,
    this.weeklyXp = 0,
    this.weekKey,
    this.bestCombo = 0,
    this.todayCombo = 0,
  });

  final int totalXp;
  final int dailyXp;

  /// روزی که `dailyXp` به آن تعلق دارد.
  final String? dayKey;

  final int weeklyXp;
  final String? weekKey;

  /// بیشترین زنجیره‌ی پاسخ درست پشت‌سرهم (کمبو).
  final int bestCombo;
  final int todayCombo;

  XpState copyWith({
    int? totalXp,
    int? dailyXp,
    String? dayKey,
    int? weeklyXp,
    String? weekKey,
    int? bestCombo,
    int? todayCombo,
  }) {
    return XpState(
      totalXp: totalXp ?? this.totalXp,
      dailyXp: dailyXp ?? this.dailyXp,
      dayKey: dayKey ?? this.dayKey,
      weeklyXp: weeklyXp ?? this.weeklyXp,
      weekKey: weekKey ?? this.weekKey,
      bestCombo: bestCombo ?? this.bestCombo,
      todayCombo: todayCombo ?? this.todayCombo,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is XpState &&
      other.totalXp == totalXp &&
      other.dailyXp == dailyXp &&
      other.dayKey == dayKey &&
      other.weeklyXp == weeklyXp &&
      other.weekKey == weekKey &&
      other.bestCombo == bestCombo &&
      other.todayCombo == todayCombo;

  @override
  int get hashCode =>
      Object.hash(totalXp, dailyXp, dayKey, weeklyXp, weekKey, bestCombo, todayCombo);
}

/// وضعیت چالش روزانه.
@immutable
class DailyChallengeState {
  const DailyChallengeState({
    this.dayKey,
    this.completedAt,
    this.correctCount = 0,
    this.totalCount = 0,
    this.xpEarned = 0,
    this.streakDays = 0,
    this.bestStreak = 0,
  });

  /// روزی که این چالش به آن تعلق دارد.
  final String? dayKey;
  final DateTime? completedAt;
  final int correctCount;
  final int totalCount;
  final int xpEarned;

  /// چند روز پشت‌سرهم چالش انجام شده است.
  final int streakDays;

  /// بهترین رکورد زنجیره‌ی چالش.
  final int bestStreak;

  double get completionRate => totalCount == 0 ? 0 : correctCount / totalCount;

  bool isCompletedFor(String dayKey) => completedAt != null && this.dayKey == dayKey;

  double get accuracy => totalCount == 0 ? 0 : correctCount / totalCount;

  DailyChallengeState copyWith({
    String? dayKey,
    DateTime? completedAt,
    int? correctCount,
    int? totalCount,
    int? xpEarned,
    int? streakDays,
    int? bestStreak,
  }) {
    return DailyChallengeState(
      dayKey: dayKey ?? this.dayKey,
      completedAt: completedAt ?? this.completedAt,
      correctCount: correctCount ?? this.correctCount,
      totalCount: totalCount ?? this.totalCount,
      xpEarned: xpEarned ?? this.xpEarned,
      streakDays: streakDays ?? this.streakDays,
      bestStreak: bestStreak ?? this.bestStreak,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is DailyChallengeState &&
      other.dayKey == dayKey &&
      other.completedAt == completedAt &&
      other.correctCount == correctCount &&
      other.totalCount == totalCount &&
      other.xpEarned == xpEarned &&
      other.streakDays == streakDays;

  @override
  int get hashCode =>
      Object.hash(dayKey, completedAt, correctCount, totalCount, xpEarned, streakDays);
}
