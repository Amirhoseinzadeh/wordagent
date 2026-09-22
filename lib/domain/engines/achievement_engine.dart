import 'package:flutter/foundation.dart';

import '../entities/achievement.dart';
import 'achievement_catalog.dart';
import 'stats_engine.dart';

/// داده‌های لازم برای سنجش دستاوردها.
@immutable
class AchievementContext {
  const AchievementContext({
    required this.stats,
    required this.totalXp,
    required this.levelDifficulty,
    required this.challengesDone,
    required this.aiChatMessages,
    required this.perfectSessions,
    required this.listeningCorrect,
    required this.typingCorrect,
    required this.sentenceCorrect,
  });

  factory AchievementContext.empty() => const AchievementContext(
        stats: null,
        totalXp: 0,
        levelDifficulty: 1,
        challengesDone: 0,
        aiChatMessages: 0,
        perfectSessions: 0,
        listeningCorrect: 0,
        typingCorrect: 0,
        sentenceCorrect: 0,
      );

  final ProgressStats? stats;
  final int totalXp;
  final int levelDifficulty;
  final int challengesDone;
  final int aiChatMessages;
  final int perfectSessions;
  final int listeningCorrect;
  final int typingCorrect;
  final int sentenceCorrect;
}

/// نتیجه‌ی ارزیابی دستاوردها.
@immutable
class AchievementUpdate {
  const AchievementUpdate({
    required this.progress,
    required this.newlyUnlocked,
    required this.xpReward,
  });

  final List<AchievementProgress> progress;
  final List<Achievement> newlyUnlocked;

  /// مجموع پاداش امتیازی دستاوردهای تازه.
  final int xpReward;

  bool get hasNew => newlyUnlocked.isNotEmpty;
}

/// موتور ارزیابی دستاوردها.
///
/// هر بار که آمار کاربر تغییر می‌کند (پایان جلسه، پایان تمرین) این موتور
/// فراخوانی می‌شود؛ ارزیابی کاملاً محلی و بدون سرور انجام می‌شود.
class AchievementEngine {
  const AchievementEngine();

  /// مقدار جاری سنجه‌ها را از آمار کاربر می‌سازد.
  Map<AchievementMetric, int> metrics(AchievementContext context) {
    final stats = context.stats ?? ProgressStats.empty();
    var maxWordsInDay = 0;
    for (final day in stats.last30Days) {
      if (day.reviews > maxWordsInDay) maxWordsInDay = day.reviews;
    }
    return <AchievementMetric, int>{
      AchievementMetric.wordsStarted: stats.wordsStarted,
      AchievementMetric.wordsMastered: stats.wordsMastered,
      AchievementMetric.reviewsDone: stats.totalReviews,
      AchievementMetric.correctAnswers: stats.totalCorrect,
      AchievementMetric.perfectSessions: context.perfectSessions,
      AchievementMetric.streakDays: stats.streak.best,
      AchievementMetric.totalXp: context.totalXp,
      AchievementMetric.levelReached: context.levelDifficulty,
      AchievementMetric.challengesDone: context.challengesDone,
      AchievementMetric.listeningCorrect: context.listeningCorrect,
      AchievementMetric.typingCorrect: context.typingCorrect,
      AchievementMetric.sentenceCorrect: context.sentenceCorrect,
      AchievementMetric.studyMinutes: stats.totalMinutes,
      AchievementMetric.bookmarkedWords: stats.wordsBookmarked,
      AchievementMetric.aiChatMessages: context.aiChatMessages,
      AchievementMetric.wordsInOneDay: maxWordsInDay,
    };
  }

  /// همه‌ی دستاوردها را ارزیابی می‌کند و تازه‌ها را برمی‌گرداند.
  AchievementUpdate evaluate({
    required AchievementContext context,
    required Map<String, AchievementProgress> existing,
    required DateTime now,
    List<Achievement> catalog = AchievementCatalog.all,
    bool countRewards = true,
  }) {
    final values = metrics(context);
    final result = <AchievementProgress>[];
    final unlocked = <Achievement>[];
    var reward = 0;

    for (final achievement in catalog) {
      final current = values[achievement.metric] ?? 0;
      final previous = existing[achievement.id];
      var progress = AchievementProgress(
        id: achievement.id,
        current: current,
        unlockedAt: previous?.unlockedAt,
        isNew: previous?.isNew ?? false,
      );

      final justUnlocked = progress.unlockedAt == null && current >= achievement.target;
      if (justUnlocked) {
        progress = progress.copyWith(unlockedAt: now, isNew: true);
        unlocked.add(achievement);
        if (countRewards) reward += achievement.xpReward;
      } else if (progress.unlockedAt != null && progress.isNew) {
        // نشان «جدید» تا اولین بازدید از صفحه‌ی دستاوردها می‌ماند.
        progress = progress.copyWith(isNew: true);
      }

      result.add(progress);
    }

    return AchievementUpdate(
      progress: result,
      newlyUnlocked: unlocked,
      xpReward: reward,
    );
  }

  /// حذف علامت «جدید» پس از بازدید کاربر.
  List<AchievementProgress> clearNewFlags(List<AchievementProgress> items) => items
      .map((item) => item.isNew ? item.copyWith(isNew: false) : item)
      .toList(growable: false);

  /// دستاوردهای بازشده در یک نقشه‌ی شناسه‌محور.
  Map<String, AchievementProgress> toMap(List<AchievementProgress> items) =>
      <String, AchievementProgress>{for (final item in items) item.id: item};

  /// درصد تکمیل مجموعه (برای نوار پیشرفت صفحه‌ی دستاوردها).
  double completionRatio(List<AchievementProgress> items) {
    if (items.isEmpty) return 0;
    final unlocked = items.where((item) => item.isUnlocked).length;
    return unlocked / items.length;
  }

  /// دستاوردهای نزدیک به باز شدن (برای نمایش انگیزشی).
  List<(Achievement, AchievementProgress)> nextUp({
    required List<AchievementProgress> items,
    int limit = 3,
  }) {
    final candidates = <(Achievement, AchievementProgress, double)>[];
    for (final progress in items) {
      if (progress.isUnlocked) continue;
      final achievement = AchievementCatalog.byId(progress.id);
      if (achievement == null) continue;
      final ratio = achievement.target == 0
          ? 0.0
          : (progress.current / achievement.target).clamp(0.0, 1.0);
      candidates.add((achievement, progress, ratio));
    }
    candidates.sort((a, b) => b.$3.compareTo(a.$3));
    return candidates.take(limit).map((entry) => (entry.$1, entry.$2)).toList(growable: false);
  }
}
