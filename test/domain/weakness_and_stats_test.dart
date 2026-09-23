import 'package:flutter_test/flutter_test.dart';
import 'package:wordagent/domain/entities/part_of_speech.dart';
import 'package:wordagent/domain/entities/progress.dart';
import 'package:wordagent/domain/entities/quiz_question.dart';
import 'package:wordagent/domain/entities/review_state.dart';
import 'package:wordagent/domain/entities/study_session.dart';
import 'package:wordagent/domain/engines/stats_engine.dart';
import 'package:wordagent/domain/engines/weakness_engine.dart';
import 'package:wordagent/domain/entities/word.dart';

import '../helpers/fixtures.dart';

void main() {
  const weakness = WeaknessEngine();
  const stats = StatsEngine();

  final words = makeWords(30);

  Map<String, ReviewState> weakStates({int count = 8}) => <String, ReviewState>{
        for (var index = 0; index < count; index++)
          words[index].id: makeState(
            wordId: words[index].id,
            totalReviews: 10,
            correctReviews: 3,
            lapses: 4,
            intervalDays: 1,
            dueAt: testNow.subtract(const Duration(hours: 5)),
          ),
      };

  group('WeaknessEngine — واژه‌های ضعیف', () {
    test('بدون وضعیت، گزارش خالی برمی‌گردد', () {
      final report = weakness.analyze(
        words: words,
        states: const <String, ReviewState>{},
        sessions: const <StudySession>[],
        now: testNow,
      );
      expect(report.hasData, isFalse);
      expect(report.weakWords, isEmpty);
      expect(report.suggestions, isEmpty);
    });

    test('واژه‌های پرخطا در فهرست ضعف می‌آیند', () {
      final report = weakness.analyze(
        words: words,
        states: weakStates(),
        sessions: <StudySession>[makeSession(total: 10, correct: 3)],
        now: testNow,
      );
      expect(report.hasData, isTrue);
      expect(report.weakWords, isNotEmpty);
      expect(report.weakWords.length, lessThanOrEqualTo(8));
      expect(report.weakWords.first.score, greaterThan(0));
      expect(report.weakWords.first.reasonFa, isNotEmpty);
      expect(report.weakWords.first.errorRate, greaterThan(0.5));
    });

    test('واژه‌ی بی‌خطا در فهرست ضعف نمی‌آید', () {
      // توجه: واژه‌ی بی‌خطا باید بیرون از بازه‌ی weakStates باشد، وگرنه
      // وضعیت ضعیف روی همان شناسه نوشته می‌شود.
      final healthyId = words[10].id;
      final states = <String, ReviewState>{
        ...weakStates(count: 3),
        healthyId: makeState(
          wordId: healthyId,
          totalReviews: 5,
          correctReviews: 5,
          repetitions: 4,
          intervalDays: 20,
        ),
      };
      final report = weakness.analyze(
        words: words,
        states: states,
        sessions: const <StudySession>[],
        now: testNow,
      );
      expect(report.weakWords.map((entry) => entry.word.id), isNot(contains(healthyId)));
    });

    test('ترتیب ضعف با امتیاز نزولی است', () {
      final report = weakness.analyze(
        words: words,
        states: weakStates(count: 10),
        sessions: const <StudySession>[],
        now: testNow,
      );
      final scores = report.weakWords.map((entry) => entry.score).toList();
      for (var index = 1; index < scores.length; index++) {
        expect(scores[index - 1], greaterThanOrEqualTo(scores[index]));
      }
    });

    test('تفکیک بر اساس نقش دستوری و موضوع', () {
      final mixed = <Word>[
        makeWord(id: 'n1', term: 'n1', pos: PartOfSpeech.noun, topics: <String>['travel']),
        makeWord(id: 'n2', term: 'n2', pos: PartOfSpeech.noun, topics: <String>['travel']),
        makeWord(id: 'v1', term: 'v1', pos: PartOfSpeech.verb, topics: <String>['work']),
        makeWord(id: 'v2', term: 'v2', pos: PartOfSpeech.verb, topics: <String>['work']),
      ];
      final states = <String, ReviewState>{
        'n1': makeState(wordId: 'n1', totalReviews: 6, correctReviews: 5),
        'n2': makeState(wordId: 'n2', totalReviews: 6, correctReviews: 5),
        'v1': makeState(wordId: 'v1', totalReviews: 6, correctReviews: 1, lapses: 3),
        'v2': makeState(wordId: 'v2', totalReviews: 6, correctReviews: 1, lapses: 3),
      };
      final report = weakness.analyze(
        words: mixed,
        states: states,
        sessions: const <StudySession>[],
        now: testNow,
      );
      expect(report.byPartOfSpeech, isNotEmpty);
      expect(report.byPartOfSpeech.first.label, PartOfSpeech.verb.faLabel);
      expect(report.byPartOfSpeech.first.accuracy, lessThan(0.5));
      expect(report.byTopic, isNotEmpty);
      expect(report.weakestArea, isNotNull);
    });

    test('دسته‌های کم‌داده کنار گذاشته می‌شوند', () {
      final states = <String, ReviewState>{
        'n1': makeState(wordId: 'n1', totalReviews: 1, correctReviews: 0),
      };
      final report = weakness.analyze(
        words: words,
        states: states,
        sessions: const <StudySession>[],
        now: testNow,
      );
      expect(report.byPartOfSpeech, isEmpty, reason: 'آستانه‌ی کمتر از ۳ پاسخ');
    });

    test('شمارش خطا بر اساس نوع تمرین', () {
      final states = <String, ReviewState>{
        words[0].id: ReviewState(
          wordId: words[0].id,
          totalReviews: 6,
          correctReviews: 2,
          errorsByType: const <String, int>{'meaningChoice': 3, 'listening': 1},
        ),
      };
      final report = weakness.analyze(
        words: words,
        states: states,
        sessions: const <StudySession>[],
        now: testNow,
      );
      expect(report.errorByType['meaningChoice'], 3);
      expect(report.errorByType['listening'], 1);
      expect(report.mostCommonMistake, QuizType.meaningChoice.faTitle);
    });

    test('سقف تعداد واژه‌های ضعیف با limit کنترل می‌شود', () {
      final report = weakness.analyze(
        words: words,
        states: weakStates(count: 20),
        sessions: const <StudySession>[],
        now: testNow,
        limit: 5,
      );
      expect(report.weakWords.length, 5);
    });

    test('روند دقت از جلسه‌ها محاسبه می‌شود', () {
      final sessions = <StudySession>[
        makeSession(
          total: 10,
          correct: 6,
          startedAt: testNow.subtract(const Duration(days: 20)),
        ),
        makeSession(
          total: 10,
          correct: 9,
          startedAt: testNow.subtract(const Duration(days: 2)),
        ),
      ];
      final report = weakness.analyze(
        words: words,
        states: weakStates(count: 3),
        sessions: sessions,
        now: testNow,
      );
      expect(report.recentAccuracy, greaterThan(report.previousAccuracy));
      expect(report.accuracyDelta, greaterThan(0));
    });

    test('پیشنهادها بر پایه‌ی گزارش ساخته می‌شوند', () {
      final report = weakness.analyze(
        words: words,
        states: weakStates(count: 12),
        sessions: <StudySession>[makeSession(total: 12, correct: 3)],
        now: testNow,
      );
      expect(report.suggestions, isNotEmpty);
      for (final suggestion in report.suggestions) {
        expect(suggestion.trim(), isNotEmpty);
      }
    });
  });

  group('StatsEngine — آمار پیشرفت', () {
    test('بدون داده، آمار صفر برمی‌گردد', () {
      final result = stats.compute(
        states: const <String, ReviewState>{},
        sessions: const <StudySession>[],
        streak: const StreakState(),
        now: testNow,
      );
      expect(result.wordsStarted, 0);
      expect(result.totalReviews, 0);
      expect(result.accuracy, 0);
      expect(result.last30Days.length, 30, reason: 'نمودار ۳۰ روزه همیشه پر است');
      expect(result.last30Days.every((day) => day.reviews == 0), isTrue);
      expect(result.activeDays, 0);
      expect(result.averageReviewsPerActiveDay, 0);
    });

    test('واژه‌های یادگرفته و مسلط شمرده می‌شوند', () {
      final states = <String, ReviewState>{
        'a': makeState(wordId: 'a', totalReviews: 6, correctReviews: 6, repetitions: 5, intervalDays: 40),
        'b': makeState(wordId: 'b', totalReviews: 4, correctReviews: 3, repetitions: 2, intervalDays: 3),
        'c': makeState(wordId: 'c', totalReviews: 5, correctReviews: 1, lapses: 6, intervalDays: 2),
        'd': makeState(wordId: 'd', bookmarked: true, totalReviews: 1, correctReviews: 1),
      };
      final result = stats.compute(
        states: states,
        sessions: const <StudySession>[],
        streak: const StreakState(current: 4, best: 9),
        now: testNow,
      );
      expect(result.wordsStarted, 4);
      expect(result.wordsMastered, 1);
      expect(result.wordsLeech, 1);
      expect(result.wordsBookmarked, 1);
      expect(result.totalReviews, 16);
      expect(result.totalCorrect, 11);
      expect(result.accuracy, closeTo(11 / 16, 0.001));
      expect(result.streak.current, 4);
    });

    test('جلسه‌ها در مجموع زمان و میانگین روزانه اثر می‌گذارند', () {
      final sessions = <StudySession>[
        makeSession(total: 10, correct: 8, startedAt: testNow.subtract(const Duration(days: 1))),
        makeSession(total: 12, correct: 6, startedAt: testNow.subtract(const Duration(days: 2))),
        makeSession(total: 8, correct: 8, startedAt: testNow.subtract(const Duration(days: 2))),
      ];
      final states = <String, ReviewState>{
        for (var index = 0; index < 4; index++)
          words[index].id: makeState(
            wordId: words[index].id,
            totalReviews: 5,
            correctReviews: 4,
            repetitions: 3,
            intervalDays: 12,
            dueAt: testNow,
          ),
      };
      final result = stats.compute(
        states: states,
        sessions: sessions,
        streak: const StreakState(),
        now: testNow,
      );
      expect(result.totalSessions, 3);
      expect(result.totalReviews, 20);
      expect(result.totalMinutes, greaterThan(0));
      expect(result.longestSessionMinutes, greaterThan(0));
      expect(result.last30Days, isNotEmpty);
      final activeDays = result.last30Days.where((day) => day.hasActivity).length;
      expect(activeDays, 2);
      expect(result.averageReviewsPerActiveDay, greaterThan(0));
    });

    test('روزهای خارج از بازه‌ی ۳۰ روز شمرده نمی‌شوند', () {
      final sessions = <StudySession>[
        makeSession(startedAt: testNow.subtract(const Duration(days: 120))),
      ];
      final result = stats.compute(
        states: const <String, ReviewState>{},
        sessions: sessions,
        streak: const StreakState(),
        now: testNow,
      );
      expect(result.last30Days.where((day) => day.reviews > 0), isEmpty);
    });

    test('روند دقت و سطل‌های تسلط ساخته می‌شوند', () {
      final states = <String, ReviewState>{
        for (var index = 0; index < 10; index++)
          'w$index': makeState(
            wordId: 'w$index',
            totalReviews: 4,
            correctReviews: 2 + (index % 3),
            repetitions: index % 5,
            intervalDays: index * 4,
          ),
      };
      final result = stats.compute(
        states: states,
        sessions: <StudySession>[makeSession(), makeSession(startedAt: testNow.subtract(const Duration(days: 3)))],
        streak: const StreakState(),
        now: testNow,
      );
      expect(result.masteryBuckets, isNotEmpty);
      expect(result.statusCounts, isNotEmpty);
      expect(result.accuracyTrend.length, greaterThan(0));
      for (final value in result.accuracyTrend) {
        expect(value, inInclusiveRange(0, 1));
      }
    });

    test('کمک‌تابع‌های هفتگی و روزانه', () {
      final days = <DailyActivity>[
        DailyActivity(
          dayKey: '2026-09-20',
          date: DateTime(2026, 9, 20),
          reviews: 10,
          xp: 60,
          minutes: 5,
          correct: 8,
          wrong: 2,
        ),
        DailyActivity(
          dayKey: '2026-09-21',
          date: DateTime(2026, 9, 21),
          reviews: 4,
          xp: 20,
          minutes: 3,
          correct: 2,
          wrong: 2,
        ),
      ];
      final weekly = stats.weeklyMinutes(days);
      expect(weekly.values.reduce((a, b) => a + b), 8);
      expect(stats.reviewsOn(days, DateTime(2026, 9, 20)), 10);
      expect(stats.reviewsOn(days, DateTime(2026, 1, 1)), 0);
    });
  });
}
