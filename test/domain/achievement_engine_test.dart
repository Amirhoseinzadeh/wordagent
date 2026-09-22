import 'package:flutter_test/flutter_test.dart';
import 'package:wordagent/domain/entities/achievement.dart';
import 'package:wordagent/domain/engines/achievement_catalog.dart';
import 'package:wordagent/domain/engines/achievement_engine.dart';
import 'package:wordagent/domain/engines/stats_engine.dart';

import '../helpers/fixtures.dart';

void main() {
  const engine = AchievementEngine();

  int _targetOf(String id) => AchievementCatalog.all
      .firstWhere((achievement) => achievement.id == id)
      .target;

  AchievementContext context({
    ProgressStats? stats,
    int totalXp = 0,
    int levelDifficulty = 1,
    int challengesDone = 0,
    int aiChatMessages = 0,
    int perfectSessions = 0,
    int listeningCorrect = 0,
    int typingCorrect = 0,
    int sentenceCorrect = 0,
  }) =>
      AchievementContext(
        stats: stats,
        totalXp: totalXp,
        levelDifficulty: levelDifficulty,
        challengesDone: challengesDone,
        aiChatMessages: aiChatMessages,
        perfectSessions: perfectSessions,
        listeningCorrect: listeningCorrect,
        typingCorrect: typingCorrect,
        sentenceCorrect: sentenceCorrect,
      );

  group('AchievementCatalog', () {
    test('فهرست دستاوردها کامل و یکتاست', () {
      expect(AchievementCatalog.all, isNotEmpty);
      expect(AchievementCatalog.all.length, greaterThanOrEqualTo(20));
      final ids = AchievementCatalog.all.map((item) => item.id).toSet();
      expect(ids.length, AchievementCatalog.all.length);
    });

    test('هر دستاورد هدف مثبت و متن فارسی دارد', () {
      for (final achievement in AchievementCatalog.all) {
        expect(achievement.target, greaterThan(0));
        expect(achievement.title.trim(), isNotEmpty);
        expect(achievement.description.trim(), isNotEmpty);
        expect(achievement.emoji.trim(), isNotEmpty);
        expect(achievement.metric.faTitle.trim(), isNotEmpty);
      }
    });
  });

  group('AchievementEngine.metrics', () {
    test('بدون داده، شاخص‌ها صفر یا بی‌خطر هستند', () {
      final values = engine.metrics(AchievementContext.empty());
      expect(values.keys.toSet(), AchievementMetric.values.toSet());
      for (final value in values.values) {
        expect(value, greaterThanOrEqualTo(0));
      }
      expect(values[AchievementMetric.totalXp], 0);
      expect(values[AchievementMetric.reviewsDone], 0);
    });

    test('شاخص‌ها از آمار و زمینه ساخته می‌شوند', () {
      final stats = ProgressStats.empty();
      final values = engine.metrics(
        context(
          stats: stats,
          totalXp: 2500,
          challengesDone: 4,
          aiChatMessages: 12,
          perfectSessions: 3,
          listeningCorrect: 20,
          typingCorrect: 15,
          sentenceCorrect: 9,
        ),
      );
      expect(values[AchievementMetric.totalXp], 2500);
      expect(values[AchievementMetric.challengesDone], 4);
      expect(values[AchievementMetric.aiChatMessages], 12);
      expect(values[AchievementMetric.perfectSessions], 3);
      expect(values[AchievementMetric.listeningCorrect], 20);
      expect(values[AchievementMetric.typingCorrect], 15);
      expect(values[AchievementMetric.sentenceCorrect], 9);
      expect(values.keys.toSet(), containsAll(AchievementMetric.values.toSet()));
    });
  });

  group('AchievementEngine.evaluate', () {
    test('با پیشرفت کم، هیچ دستاوردی باز نمی‌شود', () {
      final update = engine.evaluate(
        context: context(),
        existing: const <String, AchievementProgress>{},
        now: testNow,
      );
      expect(update.newlyUnlocked, isEmpty);
      expect(update.xpReward, 0);
      expect(update.progress, isNotEmpty);
      expect(update.hasNew, isFalse);
    });

    test('رسیدن به هدف، دستاورد را باز می‌کند', () {
      final update = engine.evaluate(
        context: context(totalXp: 100000),
        existing: const <String, AchievementProgress>{},
        now: testNow,
      );
      expect(update.newlyUnlocked, isNotEmpty);
      expect(update.xpReward, greaterThan(0));
      expect(update.hasNew, isTrue);
    });

    test('دستاورد باز‌شده دوباره باز نمی‌شود', () {
      final first = engine.evaluate(
        context: context(totalXp: 100000),
        existing: const <String, AchievementProgress>{},
        now: testNow,
      );
      final existing = engine.toMap(first.progress);
      final second = engine.evaluate(
        context: context(totalXp: 100000),
        existing: existing,
        now: testNow,
      );
      expect(second.newlyUnlocked, isEmpty);
      expect(second.xpReward, 0);
    });

    test('پیشرفت نیمه‌کاره بدون باز کردن دستاورد نگه داشته می‌شود', () {
      final update = engine.evaluate(
        context: context(totalXp: 30),
        existing: const <String, AchievementProgress>{},
        now: testNow,
      );
      final xpEntry = update.progress.firstWhere(
        (item) => item.id == 'xp_1000',
        orElse: () => const AchievementProgress(id: 'xp_1000', current: 0),
      );
      expect(xpEntry.current, 30);
      expect(xpEntry.unlockedAt, isNull);
      expect(xpEntry.isUnlocked, isFalse);
      expect(xpEntry.current, lessThan(_targetOf('xp_1000')));
    });

    test('clearNewFlags پرچم تازگی را پاک می‌کند', () {
      final update = engine.evaluate(
        context: context(totalXp: 100000),
        existing: const <String, AchievementProgress>{},
        now: testNow,
      );
      expect(update.progress.any((item) => item.isNew), isTrue);
      final cleared = engine.clearNewFlags(update.progress);
      expect(cleared.any((item) => item.isNew), isFalse);
    });

    test('نسبت تکمیل بین ۰ و ۱ می‌ماند', () {
      expect(engine.completionRatio(const <AchievementProgress>[]), 0);
      final all = <AchievementProgress>[
        for (final achievement in AchievementCatalog.all)
          AchievementProgress(id: achievement.id, current: achievement.target),
      ];
      expect(engine.completionRatio(all), 1);
    });

    test('گزارش پیشرفت برای همه‌ی دستاوردهای فهرست ساخته می‌شود', () {
      final update = engine.evaluate(
        context: context(totalXp: 500),
        existing: const <String, AchievementProgress>{},
        now: testNow,
      );
      expect(update.progress.length, AchievementCatalog.all.length);
      for (final item in update.progress) {
        final target = _targetOf(item.id);
        expect(target, greaterThan(0));
        expect(item.current / target, inInclusiveRange(0, 1));
      }
    });
  });
}
