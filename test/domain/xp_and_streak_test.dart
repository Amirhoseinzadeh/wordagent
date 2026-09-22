import 'package:flutter_test/flutter_test.dart';
import 'package:wordagent/domain/entities/cefr_level.dart';
import 'package:wordagent/domain/entities/progress.dart';
import 'package:wordagent/domain/entities/quiz_question.dart';
import 'package:wordagent/domain/engines/streak_engine.dart';
import 'package:wordagent/domain/engines/xp_engine.dart';

void main() {
  group('XpEngine — پاداش پاسخ', () {
    test('پاسخ درست، امتیاز پایه‌ی نوع تمرین را می‌دهد', () {
      final award = XpEngine.forAnswer(
        type: QuizType.meaningChoice,
        isCorrect: true,
        combo: 0,
        isNewWord: false,
        isChallenge: false,
        level: CefrLevel.a1,
        elapsedMs: 12000,
      );
      expect(award.amount, greaterThanOrEqualTo(QuizType.meaningChoice.baseXp));
    });

    test('پاسخ غلط هم امتیاز کوچک دلداری دارد', () {
      final award = XpEngine.forAnswer(
        type: QuizType.meaningChoice,
        isCorrect: false,
        combo: 4,
        isNewWord: true,
        isChallenge: true,
        level: CefrLevel.c2,
        elapsedMs: 1000,
      );
      expect(award.amount, 1);
    });

    test('واژه‌ی تازه و سطح سخت‌تر امتیاز بیشتری می‌دهند', () {
      int amount({required bool isNew, required CefrLevel level}) => XpEngine.forAnswer(
            type: QuizType.fillBlank,
            isCorrect: true,
            combo: 0,
            isNewWord: isNew,
            isChallenge: false,
            level: level,
            elapsedMs: 12000,
          ).amount;

      expect(amount(isNew: true, level: CefrLevel.b1), greaterThan(amount(isNew: false, level: CefrLevel.b1)));
      expect(amount(isNew: false, level: CefrLevel.c2), greaterThan(amount(isNew: false, level: CefrLevel.a1)));
    });

    test('کمبو امتیاز را پله‌پله بالا می‌برد', () {
      int amount(int combo) => XpEngine.forAnswer(
            type: QuizType.meaningChoice,
            isCorrect: true,
            combo: combo,
            isNewWord: false,
            isChallenge: false,
            level: CefrLevel.b1,
            elapsedMs: 12000,
          ).amount;

      expect(amount(3), greaterThan(amount(0)));
      expect(amount(5), greaterThan(amount(3)));
      expect(amount(50), amount(5), reason: 'کمبو از ۵ پله بیشتر اثر ندارد');
    });

    test('پاسخ سریع و بدون راهنما پاداش دارد', () {
      final fast = XpEngine.forAnswer(
        type: QuizType.typeWord,
        isCorrect: true,
        combo: 1,
        isNewWord: false,
        isChallenge: false,
        level: CefrLevel.b1,
        elapsedMs: 3000,
      );
      final slowWithHint = XpEngine.forAnswer(
        type: QuizType.typeWord,
        isCorrect: true,
        combo: 1,
        isNewWord: false,
        isChallenge: false,
        level: CefrLevel.b1,
        elapsedMs: 30000,
        usedHint: true,
      );
      expect(fast.amount, greaterThan(slowWithHint.amount));
    });

    test('چالش روزانه ضریب ۱٫۵ دارد', () {
      final normal = XpEngine.forAnswer(
        type: QuizType.listening,
        isCorrect: true,
        combo: 0,
        isNewWord: false,
        isChallenge: false,
        level: CefrLevel.b2,
        elapsedMs: 9000,
      );
      final challenge = XpEngine.forAnswer(
        type: QuizType.listening,
        isCorrect: true,
        combo: 0,
        isNewWord: false,
        isChallenge: true,
        level: CefrLevel.b2,
        elapsedMs: 9000,
      );
      expect(challenge.amount, greaterThan(normal.amount));
    });

    test('اعتبار جزئی (پاسخ نزدیک) امتیاز را کم می‌کند', () {
      final full = XpEngine.forAnswer(
        type: QuizType.typeMeaning,
        isCorrect: true,
        combo: 0,
        isNewWord: false,
        isChallenge: false,
        level: CefrLevel.b1,
        elapsedMs: 9000,
      );
      final partial = XpEngine.forAnswer(
        type: QuizType.typeMeaning,
        isCorrect: true,
        combo: 0,
        isNewWord: false,
        isChallenge: false,
        level: CefrLevel.b1,
        elapsedMs: 9000,
        partialCreditPercent: 50,
      );
      expect(partial.amount, lessThan(full.amount));
      expect(partial.reason, 'پاسخ نزدیک');
    });

    test('امتیاز همیشه بین ۱ تا ۲۰۰ می‌ماند', () {
      final award = XpEngine.forAnswer(
        type: QuizType.sentenceBuild,
        isCorrect: true,
        combo: 5,
        isNewWord: true,
        isChallenge: true,
        level: CefrLevel.c2,
        elapsedMs: 1000,
      );
      expect(award.amount, inInclusiveRange(1, 200));
      expect(award.reason, isNotNull);
    });
  });

  group('XpEngine — چرخه‌ی روز و هفته', () {
    test('روز جدید امتیاز روز را صفر می‌کند اما کل را نگه می‌دارد', () {
      const start = XpState(totalXp: 500, dailyXp: 60, dayKey: '2026-09-21', weeklyXp: 200, weekKey: '2026-W38');
      final sameDay = XpEngine.apply(start, 20, dayKey: '2026-09-21', weekKey: '2026-W38');
      expect(sameDay.totalXp, 520);
      expect(sameDay.dailyXp, 80);
      expect(sameDay.weeklyXp, 220);

      final nextDay = XpEngine.apply(start, 20, dayKey: '2026-09-22', weekKey: '2026-W38');
      expect(nextDay.totalXp, 520);
      expect(nextDay.dailyXp, 20);
      expect(nextDay.weeklyXp, 220);
      expect(nextDay.dayKey, '2026-09-22');
    });

    test('هفته‌ی جدید امتیاز هفتگی را صفر می‌کند', () {
      const start = XpState(totalXp: 500, dailyXp: 60, dayKey: '2026-09-21', weeklyXp: 200, weekKey: '2026-W38');
      final nextWeek = XpEngine.apply(start, 30, dayKey: '2026-09-28', weekKey: '2026-W39');
      expect(nextWeek.weeklyXp, 30);
      expect(nextWeek.totalXp, 530);
    });

    test('بهترین کمبو فقط بالا می‌رود', () {
      const start = XpState(bestCombo: 7, todayCombo: 2);
      final update = XpEngine.apply(start, 10, dayKey: 'd', weekKey: 'w', combo: 4);
      expect(update.todayCombo, 4);
      expect(update.bestCombo, 7);

      final lower = XpEngine.apply(update, 10, dayKey: 'd', weekKey: 'w', combo: 1);
      expect(lower.todayCombo, 1);
      expect(lower.bestCombo, 7);
    });
  });

  group('XpEngine — سطح و هدف روزانه', () {
    test('سطح با امتیاز بیشتر بالا می‌رود', () {
      final low = XpEngine.levelFor(0);
      final high = XpEngine.levelFor(5000);
      expect(high.index, greaterThan(low.index));
      expect(high.minXp, greaterThan(low.minXp));
      expect(high.title, isNotEmpty);
      expect(high.emoji, isNotEmpty);
    });

    test('سطح هرگز از سقف بازی فراتر نمی‌رود', () {
      final top = XpEngine.levelFor(10000000);
      expect(top.index, lessThanOrEqualTo(XpEngine.maxLevel));
      expect(top.index, XpEngine.maxLevel,
          reason: 'با امتیاز بسیار زیاد باید دقیقاً روی سقف بایستد');
      expect(XpEngine.levelFor(XpEngine.xpForLevel(5)).index, lessThanOrEqualTo(5));
    });

    test('xpForLevel صعودی است و سطح اول از صفر شروع می‌شود', () {
      expect(XpEngine.xpForLevel(1), 0);
      expect(XpEngine.xpForLevel(2), greaterThan(0));
      expect(XpEngine.xpForLevel(10), greaterThan(XpEngine.xpForLevel(2)));
      expect(XpEngine.xpForLevel(0), 0, reason: 'سطح صفر بی‌معنی است اما خطا نمی‌دهد');
    });

    test('درصد پیشرفت سطح بین ۰ و ۱ می‌ماند', () {
      final level = XpEngine.levelFor(1200);
      expect(level.progress(1200), inInclusiveRange(0, 1));
      expect(level.progress(level.minXp), inInclusiveRange(0, 1));
      expect(level.xpToNext(level.minXp), greaterThanOrEqualTo(0));
    });

    test('تشخیص بالا رفتن سطح', () {
      expect(XpEngine.leveledUp(before: 0, after: 100000), isTrue);
      expect(XpEngine.leveledUp(before: 100, after: 110), isFalse);
      expect(XpEngine.leveledUp(before: 120, after: 130), isTrue, reason: '۱۲۵ امتیاز = سطح ۲');
    });

    test('درصد هدف روزانه با تعداد کارت تعیین می‌شود', () {
      expect(XpEngine.dailyGoalPercent(dailyXp: 0, goalCards: 10), 0);
      expect(XpEngine.dailyGoalPercent(dailyXp: 10000, goalCards: 10), 100);
      final partial = XpEngine.dailyGoalPercent(dailyXp: 40, goalCards: 10);
      expect(partial, inInclusiveRange(1, 99));
    });
  });

  group('StreakEngine — ثبت روز', () {
    test('نخستین مطالعه زنجیره را از یک شروع می‌کند', () {
      final (state, outcome) = const StreakEngine().registerDay(
        const StreakState(),
        dayKey: '2026-09-22',
      );
      expect(state.current, 1);
      expect(state.totalStudyDays, 1);
      expect(state.lastStudyDayKey, '2026-09-22');
      expect(outcome, StreakOutcome.continued);
    });

    test('روز پشت‌سرهم زنجیره را بالا می‌برد', () {
      const engine = StreakEngine();
      final (first, _) = engine.registerDay(const StreakState(), dayKey: '2026-09-21');
      final (second, outcome) = engine.registerDay(first, dayKey: '2026-09-22');
      expect(second.current, 2);
      expect(second.best, 2);
      expect(outcome, StreakOutcome.continued);
    });

    test('ثبت دوباره در همان روز تغییری نمی‌دهد', () {
      const engine = StreakEngine();
      final (first, _) = engine.registerDay(const StreakState(), dayKey: '2026-09-22');
      final (again, outcome) = engine.registerDay(first, dayKey: '2026-09-22');
      expect(again.current, first.current);
      expect(again.totalStudyDays, first.totalStudyDays);
      expect(outcome, StreakOutcome.alreadyCounted);
    });

    test('یک روز فاصله با سپر جبران می‌شود', () {
      const engine = StreakEngine();
      const before = StreakState(current: 5, best: 5, lastStudyDayKey: '2026-09-20', freezesAvailable: 1);
      final (after, outcome) = engine.registerDay(before, dayKey: '2026-09-22');
      expect(outcome, StreakOutcome.savedByFreeze);
      expect(after.current, 6);
      expect(after.freezesAvailable, 0);
      expect(after.freezesUsed, 1);
    });

    test('بدون سپر زنجیره می‌شکند و از یک شروع می‌شود', () {
      const engine = StreakEngine();
      const before = StreakState(current: 12, best: 12, lastStudyDayKey: '2026-09-18', freezesAvailable: 0);
      final (after, outcome) = engine.registerDay(before, dayKey: '2026-09-22');
      expect(outcome, StreakOutcome.reset);
      expect(after.current, 1);
      expect(after.best, 12, reason: 'رکورد شخصی حفظ می‌شود');
    });

    test('هر ۷ روز یک سپر داده می‌شود', () {
      const engine = StreakEngine();
      final (after, _) = engine.registerDay(
        const StreakState(current: 6, best: 6, lastStudyDayKey: '2026-09-21'),
        dayKey: '2026-09-22',
      );
      expect(after.current, 7);
      expect(after.freezesAvailable, 1);
    });

    test('تعداد سپرها از سقف بیشتر نمی‌شود', () {
      const engine = StreakEngine();
      final (after, _) = engine.registerDay(
        const StreakState(
          current: 13,
          best: 13,
          lastStudyDayKey: '2026-09-21',
          freezesAvailable: StreakEngine.maxFreezes,
        ),
        dayKey: '2026-09-22',
      );
      expect(after.freezesAvailable, StreakEngine.maxFreezes);
      expect(after.current, 14);
    });

    test('چند روز غیبت هم با سپر جبران نمی‌شود', () {
      const engine = StreakEngine();
      const before = StreakState(current: 9, best: 9, lastStudyDayKey: '2026-09-18', freezesAvailable: 3);
      final (after, outcome) = engine.registerDay(before, dayKey: '2026-09-22');
      expect(outcome, StreakOutcome.reset);
      expect(after.current, 1);
      expect(after.freezesAvailable, 3, reason: 'سپر بی‌دلیل مصرف نمی‌شود');
    });
  });

  group('StreakEngine — محاسبات جانبی', () {
    test('شکاف روزها درست حساب می‌شود', () {
      expect(StreakEngine.dayGap('2026-09-21', '2026-09-22'), 1);
      expect(StreakEngine.dayGap('2026-09-22', '2026-09-22'), 0);
      expect(StreakEngine.dayGap('2026-09-18', '2026-09-22'), 4);
      expect(StreakEngine.dayGap('کلید نامعتبر', '2026-09-22'), 1);
    });

    test('شکاف روزها از تغییر ماه و سال عبور می‌کند', () {
      expect(StreakEngine.dayGap('2026-08-31', '2026-09-01'), 1);
      expect(StreakEngine.dayGap('2025-12-31', '2026-01-01'), 1);
    });

    test('هشدار خطر شکستن زنجیره', () {
      const engine = StreakEngine();
      const atRisk = StreakState(current: 4, best: 4, lastStudyDayKey: '2026-09-20');
      expect(engine.isAtRisk(atRisk, todayKey: '2026-09-23'), isTrue);
      expect(engine.isAtRisk(atRisk, todayKey: '2026-09-20'), isFalse);
      expect(engine.isAtRisk(const StreakState(), todayKey: '2026-09-23'), isFalse);
    });

    test('برای هر نتیجه پیام فارسی وجود دارد', () {
      const engine = StreakEngine();
      for (final outcome in StreakOutcome.values) {
        expect(engine.messageFor(outcome), isNotEmpty);
      }
    });
  });
}
