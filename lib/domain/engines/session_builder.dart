import 'package:flutter/foundation.dart';

import '../entities/cefr_level.dart';
import '../entities/review_state.dart';
import '../entities/settings.dart';
import '../entities/study_session.dart';
import '../entities/user_profile.dart';
import '../entities/word.dart';
import 'weakness_engine.dart';

/// برنامه‌ی یک جلسه‌ی مطالعه.
@immutable
class SessionPlan {
  const SessionPlan({
    required this.kind,
    required this.title,
    required this.subtitle,
    required this.words,
    this.estimatedMinutes = 0,
    this.mixed = false,
  });

  final SessionKind kind;
  final String title;
  final String subtitle;
  final List<Word> words;

  /// زمان تقریبی (هر واژه ≈ ۲۵ ثانیه).
  final int estimatedMinutes;

  /// آیا تمرین‌های این جلسه ترکیبی است؟ (چالش روزانه)
  final bool mixed;

  bool get isEmpty => words.isEmpty;

  int get wordCount => words.length;

  SessionPlan copyWith({
    SessionKind? kind,
    String? title,
    String? subtitle,
    List<Word>? words,
    int? estimatedMinutes,
    bool? mixed,
  }) {
    return SessionPlan(
      kind: kind ?? this.kind,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      words: words ?? this.words,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      mixed: mixed ?? this.mixed,
    );
  }
}

/// سازنده‌ی صف‌های مطالعه: مرور، واژه‌ی تازه، تقویت نقاط ضعف و چالش روزانه.
class SessionBuilder {
  const SessionBuilder();

  /// حداکثر واژه‌ی تازه در یک روز (محافظت در برابر حجم‌زدگی).
  static const int maxNewWordsPerDay = 30;

  /// فاصله‌ی زمانی حداقلی بین دو مرور در یک جلسه (دقیقه).
  static const int relearnGapMinutes = 10;

  /// واژه‌های سررسیده برای مرور، مرتب‌شده بر اساس اولویت.
  ///
  /// اولویت: مرورهای عقب‌افتاده‌ی قدیمی ⟶ واژه‌های سخت‌آموز ⟶ بقیه.
  List<Word> dueWords({
    required List<Word> words,
    required Map<String, ReviewState> states,
    required DateTime now,
    int limit = 40,
  }) {
    final entries = <(Word, ReviewState)>[];
    for (final word in words) {
      final state = states[word.id];
      if (state == null || state.totalReviews == 0) continue;
      if (state.isDue(now)) entries.add((word, state));
    }
    entries.sort((a, b) {
      final overdueA = now.difference(a.$2.dueAt ?? now).inMinutes;
      final overdueB = now.difference(b.$2.dueAt ?? now).inMinutes;
      final leechA = a.$2.lapses >= 5 ? 1 : 0;
      final leechB = b.$2.lapses >= 5 ? 1 : 0;
      if (leechA != leechB) return leechB.compareTo(leechA);
      if (overdueA != overdueB) return overdueB.compareTo(overdueA);
      return a.$1.frequencyRank.compareTo(b.$1.frequencyRank);
    });
    return entries.take(limit).map((entry) => entry.$1).toList(growable: false);
  }

  /// واژه‌های در حال یادگیری که هنوز سررسید نشده‌اند (برای تمرین آزاد).
  List<Word> learningWords({
    required List<Word> words,
    required Map<String, ReviewState> states,
    int limit = 40,
  }) {
    final entries = <(Word, ReviewState)>[];
    for (final word in words) {
      final state = states[word.id];
      if (state == null) continue;
      if (state.status == WordStatus.learning || state.status == WordStatus.leech) {
        entries.add((word, state));
      }
    }
    entries.sort((a, b) => b.$2.lapses.compareTo(a.$2.lapses));
    return entries.take(limit).map((entry) => entry.$1).toList(growable: false);
  }

  /// واژه‌های تازه‌ی مناسب سطح کاربر.
  ///
  /// معیار انتخاب: نزدیک‌ترین دشواری به سطح کاربر، پرتکرارتر، و هم‌راستا با
  /// هدف یادگیری (موضوع‌های دلخواه کاربر امتیاز بیشتری می‌گیرند).
  List<Word> newWords({
    required List<Word> words,
    required Map<String, ReviewState> states,
    required CefrLevel level,
    required LearningGoal goal,
    int limit = 10,
    bool allowPremium = false,
  }) {
    final count = limit.clamp(1, maxNewWordsPerDay);
    final candidates = <(Word, double)>[];
    // نقش‌های دستوری‌ای که کاربر در هفته‌ی گذشته کار کرده است (برای
    // یادگیری خوشه‌ای). یک‌بار حساب می‌شود تا حلقه سبک بماند.
    final recentPos = _recentPartsOfSpeech(states, words);

    for (final word in words) {
      if (states.containsKey(word.id)) continue;
      if (word.premium && !allowPremium) continue;

      final levelGap = (word.level.difficulty - level.difficulty).abs();
      if (levelGap > 1) continue;

      var score = 10.0 - levelGap * 3.5;

      // واژه‌های پرتکرار زودتر می‌آیند (رتبه‌ی کمتر = پرکاربردتر).
      if (word.frequencyRank > 0) {
        score += (1 - (word.frequencyRank / 5000).clamp(0.0, 1.0)) * 4;
      }

      // هم‌راستایی با هدف کاربر.
      for (final topic in word.topics) {
        if (goal.topics.contains(topic)) {
          score += 1.4;
          break;
        }
      }

      // واژه‌های هم‌نقش با آنچه کاربر تازه یاد گرفته، زودتر می‌آیند
      // (یادگیری خوشه‌ای مؤثرتر است).
      if (recentPos.contains(word.pos.code)) score += 1.2;

      candidates.add((word, score));
    }

    candidates.sort((a, b) => b.$2.compareTo(a.$2));
    return candidates.take(count).map((entry) => entry.$1).toList(growable: false);
  }

  /// واژه‌های ضعیف کاربر (خروجی تحلیل نقاط ضعف).
  List<Word> weakWords({
    required WeaknessReport report,
    int limit = 20,
  }) =>
      report.weakWords.take(limit).map((entry) => entry.word).toList(growable: false);

  /// برنامه‌ی مرور امروز.
  SessionPlan reviewPlan({
    required List<Word> words,
    required Map<String, ReviewState> states,
    required DateTime now,
    bool includeLearning = true,
    int limit = 30,
  }) {
    final due = dueWords(words: words, states: states, now: now, limit: limit);
    final plan = due.isNotEmpty
        ? due
        : (includeLearning ? learningWords(words: words, states: states, limit: limit) : <Word>[]);
    return SessionPlan(
      kind: SessionKind.review,
      title: 'مرور هوشمند',
      subtitle: due.isNotEmpty
          ? '${due.length} واژه‌ی سررسیده'
          : 'چیزی برای مرور نیست؛ تمرین آزاد',
      words: plan,
      estimatedMinutes: _estimate(plan.length),
    );
  }

  /// برنامه‌ی یادگیری واژه‌های تازه.
  SessionPlan learnPlan({
    required List<Word> words,
    required Map<String, ReviewState> states,
    required UserProfile profile,
    required AppSettings settings,
    bool allowPremium = false,
  }) {
    final fresh = newWords(
      words: words,
      states: states,
      level: profile.level,
      goal: profile.goal,
      limit: settings.dailyNewWords,
      allowPremium: allowPremium,
    );
    return SessionPlan(
      kind: SessionKind.learn,
      title: 'واژه‌های تازه',
      subtitle: '${fresh.length} واژه در سطح ${profile.level.code}',
      words: fresh,
      estimatedMinutes: _estimate(fresh.length),
    );
  }

  /// برنامه‌ی تقویت نقاط ضعف.
  SessionPlan weakPlan({required WeaknessReport report, int limit = 16}) {
    final words = weakWords(report: report, limit: limit);
    return SessionPlan(
      kind: SessionKind.weak,
      title: 'تقویت نقاط ضعف',
      subtitle: '${words.length} واژه‌ی دشوار برای تمرین',
      words: words,
      estimatedMinutes: _estimate(words.length),
    );
  }

  /// برنامه‌ی چالش روزانه — ترکیبی و *قطعی* برای هر تاریخ.
  ///
  /// چون انتخاب واژه‌ها بر پایه‌ی هش روز انجام می‌شود، چالش هر روز تازه است
  /// اما در همان روز برای همه یکسان می‌ماند.
  SessionPlan challengePlan({
    required List<Word> words,
    required Map<String, ReviewState> states,
    required UserProfile profile,
    required String dayKey,
    int size = 10,
  }) {
    if (words.isEmpty) {
      return const SessionPlan(
        kind: SessionKind.challenge,
        title: 'چالش روزانه',
        subtitle: 'هنوز واژه‌ای بارگذاری نشده',
        words: <Word>[],
      );
    }

    final seed = dayKey.hashCode.abs();
    final picked = <Word>[];
    final used = <String>{};

    void addAll(List<Word> source) {
      for (final word in source) {
        if (picked.length >= size) return;
        if (used.add(word.id)) picked.add(word);
      }
    }

    addAll(dueWords(words: words, states: states, now: DateTime.now(), limit: size));
    addAll(weakWords(
      report: WeaknessEngine().analyze(
        words: words,
        states: states,
        sessions: const [],
        now: DateTime.now(),
        limit: size,
      ),
      limit: size,
    ));
    addAll(newWords(
      words: words,
      states: states,
      level: profile.level,
      goal: profile.goal,
      limit: size,
    ));

    // پرکردن ظرفیت باقی‌مانده با واژه‌های هم‌سطح (قطعی و قابل تکرار).
    if (picked.length < size) {
      final pool = words
          .where((word) => !used.contains(word.id) && !word.premium)
          .toList(growable: false);
      if (pool.isNotEmpty) {
        var cursor = seed % pool.length;
        while (picked.length < size) {
          final word = pool[cursor % pool.length];
          if (used.add(word.id)) picked.add(word);
          cursor += 7;
          if (picked.length >= pool.length) break;
        }
      }
    }

    return SessionPlan(
      kind: SessionKind.challenge,
      title: 'چالش روزانه',
      subtitle: '${picked.length} سؤال ترکیبی',
      words: picked,
      estimatedMinutes: _estimate(picked.length),
      mixed: true,
    );
  }

  /// پیشنهاد «واژه‌ی امروز» برای کارت صفحه‌ی خانه.
  ///
  /// ابتدا سررسیده‌ها، سپس واژه‌های نزدیک به سطح کاربر.
  Word? wordOfTheDay({
    required List<Word> words,
    required Map<String, ReviewState> states,
    required UserProfile profile,
    required String dayKey,
  }) {
    if (words.isEmpty) return null;
    final due = dueWords(words: words, states: states, now: DateTime.now(), limit: 5);
    if (due.isNotEmpty) return due.first;
    final fresh = newWords(
      words: words,
      states: states,
      level: profile.level,
      goal: profile.goal,
      limit: 12,
    );
    if (fresh.isEmpty) return words.first;
    return fresh[dayKey.hashCode.abs() % fresh.length];
  }

  int _estimate(int wordCount) => (wordCount * 0.4).ceil().clamp(1, 60);

  /// نقش‌های دستوری که کاربر در ۷ روز گذشته روی آن‌ها کار کرده است.
  Set<String> _recentPartsOfSpeech(
    Map<String, ReviewState> states,
    List<Word> words,
  ) {
    final byId = <String, Word>{for (final word in words) word.id: word};
    final result = <String>{};
    for (final state in states.values) {
      final lastReviewed = state.lastReviewedAt;
      if (state.totalReviews == 0 || lastReviewed == null) continue;
      if (DateTime.now().difference(lastReviewed).inDays > 7) continue;
      final word = byId[state.wordId];
      if (word != null) result.add(word.pos.code);
    }
    return result;
  }
}
