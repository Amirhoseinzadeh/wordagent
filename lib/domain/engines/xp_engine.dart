import 'package:flutter/foundation.dart';

import '../entities/cefr_level.dart';
import '../entities/progress.dart';
import '../entities/quiz_question.dart';

/// سطح کاربر در اپلیکیشن (جدا از سطح زبان).
@immutable
class AppLevel {
  const AppLevel({
    required this.index,
    required this.title,
    required this.emoji,
    required this.minXp,
    required this.nextLevelXp,
  });

  final int index;
  final String title;
  final String emoji;

  /// امتیاز لازم برای ورود به این سطح.
  final int minXp;

  /// امتیاز لازم برای رسیدن به سطح بعدی.
  final int nextLevelXp;

  /// پیشرفت ۰ تا ۱ در این سطح.
  double progress(int totalXp) {
    final span = nextLevelXp - minXp;
    if (span <= 0) return 1;
    final value = (totalXp - minXp) / span;
    return value.clamp(0.0, 1.0);
  }

  /// امتیاز باقی‌مانده تا سطح بعد.
  int xpToNext(int totalXp) {
    final remaining = nextLevelXp - totalXp;
    return remaining < 0 ? 0 : remaining;
  }
}

/// نتیجه‌ی محاسبه‌ی امتیاز یک پاسخ.
@immutable
class XpAward {
  const XpAward({required this.amount, this.reason});

  final int amount;

  /// دلیل نمایشی («کمبو ×۳»، «واژه‌ی تازه»).
  final String? reason;
}

/// موتور امتیاز تجربه، سطح و کمبو.
class XpEngine {
  const XpEngine();

  /// حداکثر سطح قابل دستیابی.
  static const int maxLevel = 60;

  /// پاداش رسیدن به هدف روزانه.
  static const int dailyGoalBonus = 40;

  /// پاداش تکمیل چالش روزانه.
  static const int challengeBonus = 60;

  /// امتیاز تجربه‌ی تجمعی لازم برای *بودن* در سطح [level].
  static int xpForLevel(int level) {
    final n = (level - 1).clamp(0, maxLevel);
    return 100 * n + 25 * n * n;
  }

  /// سطح مربوط به یک امتیاز تجربه‌ی تجمعی.
  static AppLevel levelFor(int totalXp) {
    var level = 1;
    while (level < maxLevel && totalXp >= xpForLevel(level + 1)) {
      level += 1;
    }
    final band = _titleFor(level);
    return AppLevel(
      index: level,
      title: band.title,
      emoji: band.emoji,
      minXp: xpForLevel(level),
      nextLevelXp: xpForLevel(level + 1),
    );
  }

  static _LevelTitle _titleFor(int level) {
    if (level >= 35) return const _LevelTitle('اسطوره', '👑');
    if (level >= 25) return const _LevelTitle('افسانه', '🌟');
    if (level >= 19) return const _LevelTitle('استاد', '🏆');
    if (level >= 14) return const _LevelTitle('پیشرو', '🚀');
    if (level >= 10) return const _LevelTitle('ماهر', '⚡');
    if (level >= 7) return const _LevelTitle('واژه‌کاو', '🔎');
    if (level >= 4) return const _LevelTitle('کوشا', '📘');
    return const _LevelTitle('تازه‌کار', '🌱');
  }

  /// امتیاز یک پاسخ به تمرین را حساب می‌کند.
  ///
  /// ورودی‌ها همه صریح‌اند تا تابع کاملاً خالص و تست‌پذیر بماند.
  static XpAward forAnswer({
    required QuizType type,
    required bool isCorrect,
    required int combo,
    required bool isNewWord,
    required bool isChallenge,
    required CefrLevel level,
    required int elapsedMs,
    bool usedHint = false,
    int partialCreditPercent = 100,
  }) {
    if (!isCorrect) {
      // حتی پاسخ نادرست هم بازخورد کوچکی دارد تا کاربر دلسرد نشود.
      return const XpAward(amount: 1);
    }

    var amount = type.baseXp.toDouble();

    // سطح دشوارتر ⇒ پاداش بیشتر.
    amount *= 1 + level.difficulty * 0.06;

    // کمبو (پاسخ‌های درست پشت‌سرهم) تا ۵ پله.
    final comboBonus = combo.clamp(0, 5);
    if (comboBonus > 0) amount += comboBonus;

    // پاسخ سریع و بدون راهنما.
    if (!usedHint && elapsedMs > 0 && elapsedMs < 5000) amount += 2;

    // واژه‌ی تازه دشوارتر است.
    if (isNewWord) amount += 3;

    // چالش روزانه ارزش بیشتری دارد.
    if (isChallenge) amount *= 1.5;

    final credit = partialCreditPercent.clamp(0, 100) / 100;
    final result = (amount * credit).round().clamp(1, 200);

    String? reason;
    if (comboBonus >= 3) {
      reason = 'کمبو ×$comboBonus';
    } else if (isNewWord) {
      reason = 'واژه‌ی تازه';
    } else if (credit < 1) {
      reason = 'پاسخ نزدیک';
    }

    return XpAward(amount: result, reason: reason);
  }

  /// امتیاز را در وضعیت کاربر می‌نویسد و چرخه‌ی روز/هفته را به‌روز می‌کند.
  static XpState apply(
    XpState state,
    int amount, {
    required String dayKey,
    required String weekKey,
    int? combo,
  }) {
    final sameDay = state.dayKey == dayKey;
    final sameWeek = state.weekKey == weekKey;
    final todayCombo = combo ?? state.todayCombo;
    return XpState(
      totalXp: state.totalXp + amount,
      dailyXp: (sameDay ? state.dailyXp : 0) + amount,
      dayKey: dayKey,
      weeklyXp: (sameWeek ? state.weeklyXp : 0) + amount,
      weekKey: weekKey,
      bestCombo: todayCombo > state.bestCombo ? todayCombo : state.bestCombo,
      todayCombo: todayCombo,
    );
  }

  /// آیا با این امتیاز، سطح جدیدی فتح شده است؟ (برای جشن گرفتن)
  static bool leveledUp({required int before, required int after}) =>
      levelFor(before).index < levelFor(after).index;

  /// درصد پیشرفت هدف روزانه (۰ تا ۱۰۰).
  static int dailyGoalPercent({required int dailyXp, required int goalCards}) {
    final target = (goalCards * 8).clamp(40, 2000);
    return ((dailyXp / target) * 100).clamp(0, 100).round();
  }
}

class _LevelTitle {
  const _LevelTitle(this.title, this.emoji);

  final String title;
  final String emoji;
}
