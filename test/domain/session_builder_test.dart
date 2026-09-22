import 'package:flutter_test/flutter_test.dart';
import 'package:wordagent/domain/entities/cefr_level.dart';
import 'package:wordagent/domain/entities/review_state.dart';
import 'package:wordagent/domain/entities/settings.dart';
import 'package:wordagent/domain/entities/study_session.dart';
import 'package:wordagent/domain/entities/user_profile.dart';
import 'package:wordagent/domain/entities/word.dart';
import 'package:wordagent/domain/engines/session_builder.dart';
import 'package:wordagent/domain/engines/weakness_engine.dart';

import '../helpers/fixtures.dart';

void main() {
  const builder = SessionBuilder();
  final words = makeWords(40);
  final profile = UserProfile(
    name: 'تست',
    goal: LearningGoal.travel,
    level: CefrLevel.b1,
    createdAt: testNow,
  );

  Map<String, ReviewState> statesWith(
    ReviewState Function(int index) build,
  ) =>
      <String, ReviewState>{
        for (var index = 0; index < words.length; index++)
          words[index].id: build(index),
      };

  group('dueWords — صف مرور', () {
    test('فقط واژه‌های سررسیده را برمی‌گرداند', () {
      final states = <String, ReviewState>{
        words[0].id: makeState(
          wordId: words[0].id,
          totalReviews: 3,
          correctReviews: 3,
          dueAt: testNow.subtract(const Duration(hours: 2)),
        ),
        words[1].id: makeState(
          wordId: words[1].id,
          totalReviews: 3,
          correctReviews: 3,
          dueAt: testNow.add(const Duration(days: 2)),
        ),
        words[2].id: makeState(wordId: words[2].id, dueAt: testNow),
      };

      final due = builder.dueWords(words: words, states: states, now: testNow);
      expect(due.map((w) => w.id), contains(words[0].id));
      expect(due.map((w) => w.id), isNot(contains(words[1].id)));
      expect(
        due.map((w) => w.id),
        isNot(contains(words[2].id)),
        reason: 'واژه‌ی تازه وارد صف مرور نمی‌شود',
      );
    });

    test('واژه‌های عقب‌افتاده‌تر اول می‌آیند', () {
      final states = <String, ReviewState>{
        words[0].id: makeState(
          wordId: words[0].id,
          totalReviews: 2,
          correctReviews: 2,
          dueAt: testNow.subtract(const Duration(minutes: 30)),
        ),
        words[1].id: makeState(
          wordId: words[1].id,
          totalReviews: 2,
          correctReviews: 2,
          dueAt: testNow.subtract(const Duration(days: 3)),
        ),
      };
      final due = builder.dueWords(words: words, states: states, now: testNow);
      expect(due.first.id, words[1].id);
    });

    test('واژه‌های سخت‌آموز (leech) اولویت می‌گیرند', () {
      final states = <String, ReviewState>{
        words[0].id: makeState(
          wordId: words[0].id,
          totalReviews: 4,
          correctReviews: 1,
          lapses: 6,
          dueAt: testNow.subtract(const Duration(minutes: 10)),
        ),
        words[1].id: makeState(
          wordId: words[1].id,
          totalReviews: 4,
          correctReviews: 4,
          dueAt: testNow.subtract(const Duration(days: 1)),
        ),
      };
      final due = builder.dueWords(words: words, states: states, now: testNow);
      expect(due.first.id, words[0].id);
    });

    test('سقف تعداد رعایت می‌شود', () {
      final states = statesWith(
        (index) => makeState(
          wordId: words[index].id,
          totalReviews: 2,
          correctReviews: 2,
          dueAt: testNow.subtract(const Duration(days: 1)),
        ),
      );
      final due = builder.dueWords(words: words, states: states, now: testNow, limit: 7);
      expect(due.length, 7);
    });
  });

  group('reviewPlan', () {
    test('با مرور سررسید، همان‌ها را پیشنهاد می‌دهد', () {
      final states = statesWith(
        (index) => makeState(
          wordId: words[index].id,
          totalReviews: 2,
          correctReviews: 2,
          dueAt: testNow.subtract(const Duration(hours: 1)),
        ),
      );
      final plan = builder.reviewPlan(words: words, states: states, now: testNow, limit: 12);
      expect(plan.kind, SessionKind.review);
      expect(plan.wordCount, 12);
      expect(plan.subtitle, contains('سررسیده'));
      expect(plan.estimatedMinutes, greaterThan(0));
      expect(plan.mixed, isFalse);
      expect(plan.isEmpty, isFalse);
    });

    test('بدون مرور سررسید، واژه‌های در حال یادگیری را می‌دهد', () {
      final states = <String, ReviewState>{
        words[0].id: makeState(
          wordId: words[0].id,
          totalReviews: 2,
          correctReviews: 2,
          repetitions: 1,
          intervalDays: 1,
          dueAt: testNow.add(const Duration(days: 3)),
        ),
        words[1].id: makeState(
          wordId: words[1].id,
          totalReviews: 2,
          correctReviews: 2,
          repetitions: 1,
          intervalDays: 1,
          dueAt: testNow.add(const Duration(days: 4)),
        ),
      };
      final plan = builder.reviewPlan(words: words, states: states, now: testNow);
      expect(plan.wordCount, 2);
      expect(plan.subtitle, contains('تمرین آزاد'));
    });

    test('حالت بدون یادگیری، برنامه‌ی خالی می‌دهد', () {
      final plan = builder.reviewPlan(
        words: words,
        states: const <String, ReviewState>{},
        now: testNow,
        includeLearning: false,
      );
      expect(plan.isEmpty, isTrue);
    });
  });

  group('learnPlan — واژه‌ی تازه', () {
    test('تعداد واژه‌ها از تنظیمات کاربر می‌آید', () {
      final plan = builder.learnPlan(
        words: words,
        states: const <String, ReviewState>{},
        profile: profile,
        settings: const AppSettings(dailyNewWords: 8),
      );
      expect(plan.kind, SessionKind.learn);
      expect(plan.wordCount, 8);
      expect(plan.subtitle, contains('B1'));
    });

    test('واژه‌های هزینه‌دار برای کاربر رایگان کنار گذاشته می‌شوند', () {
      final premiumWord = makeWord(
        id: 'premium1',
        term: 'ephemeral',
        premium: true,
        level: CefrLevel.b1,
        frequencyRank: 1,
      );
      final plan = builder.learnPlan(
        words: <Word>[premiumWord, ...words],
        states: const <String, ReviewState>{},
        profile: profile,
        settings: const AppSettings(dailyNewWords: 10),
      );
      expect(plan.words.map((w) => w.id), isNot(contains('premium1')));
    });

    test('سقف روزانه از حداکثر مجاز بیشتر نمی‌شود', () {
      final plan = builder.learnPlan(
        words: words,
        states: const <String, ReviewState>{},
        profile: profile,
        settings: const AppSettings(dailyNewWords: 999),
      );
      expect(plan.wordCount, lessThanOrEqualTo(SessionBuilder.maxNewWordsPerDay));
    });

    test('واژه‌های قبلاً دیده‌شده تکرار نمی‌شوند', () {
      final states = <String, ReviewState>{
        for (var index = 0; index < 10; index++)
          words[index].id: makeState(
            wordId: words[index].id,
            totalReviews: 1,
            correctReviews: 1,
            dueAt: testNow.add(const Duration(days: 5)),
          ),
      };
      final plan = builder.learnPlan(
        words: words,
        states: states,
        profile: profile,
        settings: const AppSettings(dailyNewWords: 5),
      );
      final learned = states.keys.toSet();
      for (final word in plan.words) {
        expect(learned.contains(word.id), isFalse);
      }
    });
  });

  group('challengePlan — چالش روزانه', () {
    test('اندازه، عنوان و ترکیبی بودن چالش', () {
      final plan = builder.challengePlan(
        words: words,
        states: const <String, ReviewState>{},
        profile: profile,
        dayKey: '2026-09-22',
        size: 10,
      );
      expect(plan.kind, SessionKind.challenge);
      expect(plan.wordCount, 10);
      expect(plan.mixed, isTrue);
      expect(plan.isEmpty, isFalse);
      expect(plan.subtitle, contains('سؤال ترکیبی'));
    });

    test('واژه‌های چالش یکتا هستند و از مجموعه‌ی محتوا می‌آیند', () {
      final plan = builder.challengePlan(
        words: words,
        states: const <String, ReviewState>{},
        profile: profile,
        dayKey: '2026-09-22',
        size: 12,
      );
      final ids = plan.words.map((w) => w.id).toList();
      expect(ids.toSet().length, ids.length);
      final all = words.map((w) => w.id).toSet();
      for (final id in ids) {
        expect(all.contains(id), isTrue);
      }
    });

    test('در همان روز تکرارپذیر است', () {
      final first = builder.challengePlan(
        words: words,
        states: const <String, ReviewState>{},
        profile: profile,
        dayKey: '2026-09-22',
      );
      final again = builder.challengePlan(
        words: words,
        states: const <String, ReviewState>{},
        profile: profile,
        dayKey: '2026-09-22',
      );
      expect(first.words.map((w) => w.id).toList(), again.words.map((w) => w.id).toList());
    });

    test('روزهای مختلف چالش متفاوت می‌سازند', () {
      // همه‌ی واژه‌ها یاد گرفته و سررسید‌نشده‌اند؛ پس انتخاب از استخر
      // برپایه‌ی هش روز انجام می‌شود.
      final states = statesWith(
        (index) => makeState(
          wordId: words[index].id,
          totalReviews: 4,
          correctReviews: 4,
          repetitions: 4,
          intervalDays: 30,
          dueAt: testNow.add(const Duration(days: 30)),
        ),
      );
      final baseline = builder.challengePlan(
        words: words,
        states: states,
        profile: profile,
        dayKey: '2026-09-22',
        size: 10,
      ).words.map((w) => w.id).toList();

      final variants = <String>[
        for (final day in <String>['2026-09-23', '2026-09-24', '2026-10-01', '2026-12-31'])
          builder.challengePlan(
            words: words,
            states: states,
            profile: profile,
            dayKey: day,
            size: 10,
          ).words.map((w) => w.id).join(','),
      ];
      expect(
        variants.any((value) => value != baseline.join(',')),
        isTrue,
        reason: 'چالش هر روز باید تازه باشد',
      );
    });

    test('بدون محتوا، برنامه‌ی خالی برمی‌گردد', () {
      final plan = builder.challengePlan(
        words: const <Word>[],
        states: const <String, ReviewState>{},
        profile: profile,
        dayKey: '2026-09-22',
      );
      expect(plan.isEmpty, isTrue);
      expect(plan.subtitle, isNotEmpty);
    });
  });

  group('wordOfTheDay — واژه‌ی امروز', () {
    test('برای یک روز پاسخ ثابت می‌دهد', () {
      final first = builder.wordOfTheDay(
        words: words,
        states: const <String, ReviewState>{},
        profile: profile,
        dayKey: '2026-09-22',
      );
      final again = builder.wordOfTheDay(
        words: words,
        states: const <String, ReviewState>{},
        profile: profile,
        dayKey: '2026-09-22',
      );
      expect(first, isNotNull);
      expect(first!.id, again!.id);
      expect(first.id, isNotEmpty);
    });

    test('واژه‌ی سررسیده اولویت دارد', () {
      final states = <String, ReviewState>{
        words[5].id: makeState(
          wordId: words[5].id,
          totalReviews: 3,
          correctReviews: 2,
          dueAt: testNow.subtract(const Duration(days: 1)),
        ),
      };
      final word = builder.wordOfTheDay(
        words: words,
        states: states,
        profile: profile,
        dayKey: '2026-09-22',
      );
      expect(word!.id, words[5].id);
    });

    test('بدون واژه، null برمی‌گرداند', () {
      expect(
        builder.wordOfTheDay(
          words: const <Word>[],
          states: const <String, ReviewState>{},
          profile: profile,
          dayKey: '2026-09-22',
        ),
        isNull,
      );
    });
  });

  group('goalWords — پیشنهاد بر اساس هدف', () {
    /// واژه‌های آزمون با موضوع‌های مشخص و رتبه‌ی کاربرد متفاوت.
    List<Word> goalPool() => <Word>[
          makeWord(id: 'g1', term: 'journey', topics: <String>['travel'])
              .copyWith(frequencyRank: 900),
          makeWord(id: 'g2', term: 'hotel', topics: <String>['travel'],
                  level: CefrLevel.a2)
              .copyWith(frequencyRank: 300),
          makeWord(id: 'g3', term: 'invoice', topics: <String>['business'])
              .copyWith(frequencyRank: 100),
          makeWord(id: 'g4', term: 'sunset', topics: <String>['nature'])
              .copyWith(frequencyRank: 50),
          makeWord(id: 'g5', term: 'airport', topics: <String>['travel'])
              .copyWith(frequencyRank: 1200),
        ];

    test('فقط واژه‌های هم‌موضوع با هدف را برمی‌گرداند', () {
      final result = builder.goalWords(
        words: goalPool(),
        states: const <String, ReviewState>{},
        profile: profile, // هدف: سفر و مکالمه
        limit: 6,
      );
      expect(result.map((word) => word.id), contains('g1'));
      expect(result.map((word) => word.id), contains('g2'));
      expect(
        result.map((word) => word.id),
        isNot(contains('g3')),
        reason: 'واژه‌ی کسب‌وکار با هدف سفر هم‌موضوع نیست',
      );
    });

    test('پرکاربردترها اول می‌آیند', () {
      final result = builder.goalWords(
        words: goalPool(),
        states: const <String, ReviewState>{},
        profile: profile,
        limit: 3,
      );
      expect(result.first.id, 'g2', reason: 'رتبه‌ی ۳۰۰ از ۹۰۰ و ۱۲۰۰ کمتر است');
      expect(result.map((word) => word.id).toList(),
          <String>['g2', 'g1', 'g5']);
    });

    test('واژه‌های شروع‌شده پیشنهاد نمی‌شوند', () {
      final states = <String, ReviewState>{
        'g2': makeState(wordId: 'g2', totalReviews: 2),
      };
      final result = builder.goalWords(
        words: goalPool(),
        states: states,
        profile: profile,
        limit: 6,
      );
      expect(result.map((word) => word.id), isNot(contains('g2')));
    });

    test('واژه‌های ویژه فقط با اجازه می‌آیند', () {
      final pool = <Word>[
        makeWord(id: 'p1', term: 'voyage', topics: <String>['travel'],
            premium: true),
      ];
      expect(
        builder.goalWords(
          words: pool,
          states: const <String, ReviewState>{},
          profile: profile,
        ),
        isEmpty,
      );
      expect(
        builder
            .goalWords(
              words: pool,
              states: const <String, ReviewState>{},
              profile: profile,
              allowPremium: true,
            )
            .map((word) => word.id),
        <String>['p1'],
      );
    });

    test('اگر واژه‌ی هم‌موضوع کم بود، از هم‌سطح‌ها تکمیل می‌کند', () {
      final pool = <Word>[
        makeWord(id: 't1', term: 'trip', topics: <String>['travel']),
        makeWord(id: 'f1', term: 'talent', topics: <String>['work']),
        makeWord(id: 'f2', term: 'method', topics: <String>['study']),
      ];
      final result = builder.goalWords(
        words: pool,
        states: const <String, ReviewState>{},
        profile: profile,
        limit: 3,
      );
      expect(result, hasLength(3));
      expect(result.first.id, 't1');
      expect(result.map((word) => word.id), containsAll(<String>['f1', 'f2']));
    });

    test('بدون موضوع یا با limit صفر، خالی برمی‌گرداند', () {
      expect(
        builder.goalWords(
          words: goalPool(),
          states: const <String, ReviewState>{},
          profile: profile,
          limit: 0,
        ),
        isEmpty,
      );
      expect(
        builder.goalWords(
          words: const <Word>[],
          states: const <String, ReviewState>{},
          profile: profile,
        ),
        isEmpty,
      );
    });
  });

  group('weakPlan', () {
    test('واژه‌های ضعیف را به جلسه‌ی تقویت تبدیل می‌کند', () async {
      final states = <String, ReviewState>{
        for (var index = 0; index < 10; index++)
          words[index].id: makeState(
            wordId: words[index].id,
            totalReviews: 6,
            correctReviews: 2,
            lapses: 4,
            intervalDays: 1,
            dueAt: testNow.subtract(const Duration(hours: 3)),
          ),
      };
      final report = WeaknessEngine().analyze(
        words: words,
        states: states,
        sessions: <StudySession>[makeSession(total: 10, correct: 4)],
        now: testNow,
      );
      final plan = builder.weakPlan(report: report, limit: 6);
      expect(plan.kind, SessionKind.weak);
      expect(plan.wordCount, lessThanOrEqualTo(6));
      expect(plan.title, isNotEmpty);
    });
  });
}
