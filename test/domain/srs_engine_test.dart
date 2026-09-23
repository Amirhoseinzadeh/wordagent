import 'package:flutter_test/flutter_test.dart';
import 'package:wordagent/domain/entities/review_state.dart';
import 'package:wordagent/domain/engines/srs_engine.dart';

import '../helpers/fixtures.dart';

void main() {
  const engine = SpacedRepetitionEngine();

  group('اولین مرور واژه‌ی تازه', () {
    test('پاسخ درست واژه را وارد چرخه‌ی یادگیری می‌کند', () {
      final state = makeState();
      final next = engine.apply(state: state, grade: ReviewGrade.good, now: testNow);

      expect(next.repetitions, 1);
      expect(next.totalReviews, 1);
      expect(next.correctReviews, 1);
      expect(next.currentStreak, 1);
      expect(next.intervalDays, greaterThan(0));
      expect(next.dueAt!.isAfter(testNow), isTrue);
      expect(next.firstSeenAt, testNow);
    });

    test('سطوح اول با یک بار مرور بازه‌ی کوتاه می‌گیرند', () {
      final good = engine.apply(state: makeState(), grade: ReviewGrade.good, now: testNow);
      final easy = engine.apply(state: makeState(), grade: ReviewGrade.easy, now: testNow);

      expect(good.intervalDays, lessThan(2));
      expect(easy.intervalDays, greaterThan(good.intervalDays));
    });

    test('«فراموش کردم» بازه را کوتاه و لغزش را ثبت می‌کند', () {
      final state = makeState(totalReviews: 3, correctReviews: 3, repetitions: 2);
      final next = engine.apply(state: state, grade: ReviewGrade.forgot, now: testNow);

      expect(next.lapses, 1);
      expect(next.repetitions, 0);
      expect(next.correctReviews, 3, reason: 'پاسخ غلط آمار درست‌ها را بالا نمی‌برد');
      expect(next.intervalDays, lessThan(1));
      expect(next.currentStreak, 0);
      expect(next.dueAt!.difference(testNow).inMinutes, lessThan(30));
    });
  });

  group('پارامترهای فاصله‌دار', () {
    test('سختی، ثبات را کم و آسانی، آن را زیاد می‌کند', () {
      final base = makeState(repetitions: 3, intervalDays: 10);
      final hard = engine.apply(state: base, grade: ReviewGrade.hard, now: testNow);
      final good = engine.apply(state: base, grade: ReviewGrade.good, now: testNow);
      final easy = engine.apply(state: base, grade: ReviewGrade.easy, now: testNow);

      expect(hard.ease, lessThan(base.ease));
      expect(good.ease, base.ease);
      expect(easy.ease, greaterThan(base.ease));
      expect(hard.intervalDays, lessThan(good.intervalDays));
      expect(easy.intervalDays, greaterThan(good.intervalDays));
    });

    test('ease هرگز از کف مجاز پایین‌تر نمی‌رود', () {
      var state = makeState(repetitions: 4, intervalDays: 20, ease: 1.4);
      for (var index = 0; index < 10; index++) {
        state = engine.apply(state: state, grade: ReviewGrade.forgot, now: testNow);
      }
      expect(state.ease, greaterThanOrEqualTo(SpacedRepetitionEngine.minEase));
    });

    test('ease از سقف مجاز بالاتر نمی‌رود', () {
      var state = makeState(repetitions: 4, intervalDays: 20, ease: 2.7);
      for (var index = 0; index < 5; index++) {
        state = engine.apply(state: state, grade: ReviewGrade.easy, now: testNow);
      }
      expect(state.ease, lessThanOrEqualTo(SpacedRepetitionEngine.maxEase));
    });

    test('بازه از سقف یک‌ساله فراتر نمی‌رود', () {
      var state = makeState(repetitions: 8, intervalDays: 300, ease: 2.8);
      for (var index = 0; index < 5; index++) {
        state = engine.apply(state: state, grade: ReviewGrade.easy, now: testNow);
      }
      expect(state.intervalDays, lessThanOrEqualTo(SpacedRepetitionEngine.maxIntervalDays));
    });
  });

  group('ناپایداری تصادفی بازه (fuzz)', () {
    test('واژه‌های یکسان با شناسه‌ی متفاوت بازه‌ی کاملاً یکسان نمی‌گیرند', () {
      final a = engine.apply(
        state: makeState(wordId: 'a', repetitions: 4, intervalDays: 30, ease: 2.5),
        grade: ReviewGrade.good,
        now: testNow,
      );
      final b = engine.apply(
        state: makeState(wordId: 'b', repetitions: 4, intervalDays: 30, ease: 2.5),
        grade: ReviewGrade.good,
        now: testNow,
      );
      expect(a.intervalDays, isNot(b.intervalDays));
      // اختلاف باید کوچک بماند (±۱۰٪ پیرامون مقدار اصلی).
      expect((a.intervalDays - b.intervalDays).abs(), lessThan(75 * 0.12));
    });

    test('محاسبه برای همان وضعیت و همان واژه تکرارپذیر است', () {
      final state = makeState(wordId: 'w1', repetitions: 4, intervalDays: 30);
      final first = engine.apply(state: state, grade: ReviewGrade.good, now: testNow);
      final second = engine.apply(state: state, grade: ReviewGrade.good, now: testNow);
      expect(first.intervalDays, second.intervalDays);
    });
  });

  group('شاخص‌های مشتق‌شده', () {
    test('دقت و درصد تسلط', () {
      final state = makeState(totalReviews: 10, correctReviews: 8, repetitions: 5, intervalDays: 40);
      expect(state.accuracy, 0.8);
      expect(state.masteryPercent, inInclusiveRange(60, 100));
      expect(state.status, WordStatus.mastered);
    });

    test('واژه‌ی تازه وضعیت fresh دارد', () {
      final state = makeState();
      expect(state.status, WordStatus.fresh);
      expect(state.isNew, isTrue);
      expect(state.isActive, isFalse);
      expect(state.masteryPercent, 0);
    });

    test('واژه‌ی پرلغزش به‌عنوان leech علامت می‌خورد', () {
      final state = makeState(lapses: 6, intervalDays: 5, repetitions: 2, totalReviews: 12, correctReviews: 4);
      expect(state.status, WordStatus.leech);
    });

    test('سررسید فقط پس از گذشتن زمان فعال می‌شود', () {
      final later = makeState(dueAt: testNow.add(const Duration(days: 1)));
      final earlier = makeState(dueAt: testNow.subtract(const Duration(minutes: 1)));

      expect(later.isDue(testNow), isFalse);
      expect(earlier.isDue(testNow), isTrue);
      expect(earlier.timeUntilDue(testNow), Duration.zero);
      expect(later.timeUntilDue(testNow).inHours, 24);
      expect(makeState().isDue(testNow), isFalse);
    });
  });

  group('پیش‌نمایش بازه‌ها', () {
    test('برای هر چهار گزینه بازه‌ی مثبت برمی‌گردد', () {
      final preview = engine.previewIntervals(makeState(repetitions: 3, intervalDays: 10));
      expect(preview.keys.toSet(), ReviewGrade.values.toSet());
      for (final value in preview.values) {
        expect(value.inMinutes, greaterThan(0));
      }
    });

    test('ترتیب بازه‌ها با سختی پاسخ هم‌خوان است', () {
      final preview = engine.previewIntervals(makeState(repetitions: 3, intervalDays: 10));
      expect(preview[ReviewGrade.hard]! < preview[ReviewGrade.good]!, isTrue);
      expect(preview[ReviewGrade.good]! < preview[ReviewGrade.easy]!, isTrue);
      expect(preview[ReviewGrade.forgot]! < preview[ReviewGrade.hard]!, isTrue);
    });

    test('وضعیت واژه با پیش‌نمایش تغییر نمی‌کند', () {
      final state = makeState(repetitions: 3, intervalDays: 10);
      engine.previewIntervals(state);
      expect(state.repetitions, 3);
      expect(state.intervalDays, 10);
    });
  });

  group('تشخیص leech', () {
    test('لغزش زیاد با بازه‌ی کوتاه', () {
      expect(engine.isLeech(makeState(lapses: 5, intervalDays: 20)), isTrue);
      expect(engine.isLeech(makeState(lapses: 5, intervalDays: 21)), isFalse);
      expect(engine.isLeech(makeState(lapses: 2, intervalDays: 3)), isFalse);
    });
  });

  group('GradeMapper', () {
    test('پاسخ غلط همیشه «فراموش کردم» است', () {
      expect(
        GradeMapper.fromQuiz(isCorrect: false, elapsedMs: 3000, wasTyped: true),
        ReviewGrade.forgot,
      );
      expect(
        GradeMapper.fromQuiz(isCorrect: false, elapsedMs: 40000, wasTyped: false),
        ReviewGrade.forgot,
      );
    });

    test('پاسخ تایپی سریع نشانه‌ی تسلط بالاست', () {
      expect(
        GradeMapper.fromQuiz(isCorrect: true, elapsedMs: 4000, wasTyped: true),
        ReviewGrade.easy,
      );
    });

    test('پاسخ کند و درنگ‌دار «سخت» شمرده می‌شود', () {
      expect(
        GradeMapper.fromQuiz(isCorrect: true, elapsedMs: 25000, wasTyped: false),
        ReviewGrade.hard,
      );
    });

    test('حالت معمولی «خوب» است', () {
      expect(
        GradeMapper.fromQuiz(isCorrect: true, elapsedMs: 9000, wasTyped: false),
        ReviewGrade.good,
      );
    });
  });

  group('پیش‌بینی بار مرور', () {
    test('شمارش کل با بازه‌ها هم‌خوان است', () {
      const forecast = ReviewForecast(dueNow: 3, dueToday: 4, dueThisWeek: 5, dueLater: 2);
      expect(forecast.total, 14);
    });
  });
}
