import 'package:flutter/foundation.dart';

import '../entities/part_of_speech.dart';
import '../entities/quiz_question.dart';
import '../entities/review_state.dart';
import '../entities/study_session.dart';
import '../entities/word.dart';

/// یک واژه‌ی ضعیف همراه با دلیل.
@immutable
class WeakWordEntry {
  const WeakWordEntry({
    required this.word,
    required this.state,
    required this.errorRate,
    required this.score,
    required this.reasonFa,
  });

  final Word word;
  final ReviewState state;

  /// نسبت پاسخ‌های نادرست.
  final double errorRate;

  /// امتیاز ضعف (بزرگ‌تر = ضعیف‌تر).
  final double score;

  /// دلیل فارسی برای نمایش.
  final String reasonFa;
}

/// عملکرد کاربر در یک حوزه (نقش دستوری یا موضوع).
@immutable
class AreaScore {
  const AreaScore({
    required this.label,
    required this.total,
    required this.correct,
  });

  final String label;
  final int total;
  final int correct;

  double get accuracy => total == 0 ? 0 : correct / total;

  int get errorCount => total - correct;
}

/// گزارش تحلیلی نقاط ضعف کاربر.
@immutable
class WeaknessReport {
  const WeaknessReport({
    required this.weakWords,
    required this.byPartOfSpeech,
    required this.byTopic,
    required this.errorByType,
    required this.recentAccuracy,
    required this.previousAccuracy,
    required this.totalTracked,
    required this.suggestions,
  });

  factory WeaknessReport.empty() => const WeaknessReport(
        weakWords: <WeakWordEntry>[],
        byPartOfSpeech: <AreaScore>[],
        byTopic: <AreaScore>[],
        errorByType: <String, int>{},
        recentAccuracy: 0,
        previousAccuracy: 0,
        totalTracked: 0,
        suggestions: <String>[],
      );

  final List<WeakWordEntry> weakWords;
  final List<AreaScore> byPartOfSpeech;
  final List<AreaScore> byTopic;

  /// تعداد خطا به تفکیک نوع تمرین.
  final Map<String, int> errorByType;

  /// دقت ۷ روز گذشته.
  final double recentAccuracy;

  /// دقت ۷ روز پیش از آن (برای نمایش روند).
  final double previousAccuracy;

  /// چند واژه وضعیت ثبت‌شده دارند.
  final int totalTracked;

  final List<String> suggestions;

  bool get hasData => totalTracked >= 3;

  /// تغییر دقت نسبت به دوره‌ی قبل (مثبت = بهبود).
  double get accuracyDelta => recentAccuracy - previousAccuracy;

  /// ضعیف‌ترین حوزه‌ی دستوری.
  AreaScore? get weakestArea {
    if (byPartOfSpeech.isEmpty) return null;
    final sorted = [...byPartOfSpeech]..sort((a, b) => a.accuracy.compareTo(b.accuracy));
    return sorted.first.total >= 3 ? sorted.first : null;
  }

  /// پرتکرارترین نوع خطا.
  String? get mostCommonMistake {
    if (errorByType.isEmpty) return null;
    final entries = errorByType.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = entries.first;
    if (top.value < 2) return null;
    final type = QuizType.values.firstWhere(
      (t) => t.name == top.key,
      orElse: () => QuizType.meaningChoice,
    );
    return type.faTitle;
  }
}

/// موتور تحلیل نقاط ضعف و پیشنهاد تمرین.
///
/// ورودی: وضعیت مرور واژه‌ها و جلسه‌های ثبت‌شده.
/// خروجی: فهرست واژه‌های ضعیف، حوزه‌های ضعیف و پیشنهادهای عملی فارسی.
class WeaknessEngine {
  const WeaknessEngine();

  WeaknessReport analyze({
    required List<Word> words,
    required Map<String, ReviewState> states,
    required List<StudySession> sessions,
    required DateTime now,
    int limit = 24,
  }) {
    if (states.isEmpty) return WeaknessReport.empty();

    final wordById = <String, Word>{for (final word in words) word.id: word};
    final entries = <WeakWordEntry>[];
    final posTotals = <PartOfSpeech, List<int>>{};
    final topicTotals = <String, List<int>>{};
    final errorByType = <String, int>{};

    for (final state in states.values) {
      final total = state.totalReviews;
      if (total == 0) continue;
      final word = wordById[state.wordId];
      if (word == null) continue;

      final correct = state.correctReviews;
      final errors = total - correct;

      for (final entry in state.errorsByType.entries) {
        errorByType[entry.key] = (errorByType[entry.key] ?? 0) + entry.value;
      }

      final posBucket = posTotals.putIfAbsent(word.pos, () => <int>[0, 0]);
      posBucket[0] += total;
      posBucket[1] += correct;

      for (final topic in word.topics) {
        final bucket = topicTotals.putIfAbsent(topic, () => <int>[0, 0]);
        bucket[0] += total;
        bucket[1] += correct;
      }

      if (errors == 0 && state.lapses == 0) continue;

      final errorRate = errors / total;
      final recency = state.lastReviewedAt == null
          ? 0.5
          : (1 - (now.difference(state.lastReviewedAt!).inDays / 30)).clamp(0.0, 1.0);
      final score = errors * 2.2 +
          state.lapses * 2.6 +
          errorRate * 6 +
          recency * 2 -
          state.masteryPercent / 25;

      if (score <= 0) continue;

      entries.add(
        WeakWordEntry(
          word: word,
          state: state,
          errorRate: errorRate,
          score: score,
          reasonFa: _reasonFor(state, errorRate, errors),
        ),
      );

      // نگه‌داشتن سبک‌ترین حالت برای پرهیز از تکرار کد.
    }

    entries.sort((a, b) => b.score.compareTo(a.score));
    final limited = entries.take(limit).toList(growable: false);

    final byPos = posTotals.entries
        .map((entry) => AreaScore(
              label: entry.key.faLabel,
              total: entry.value[0],
              correct: entry.value[1],
            ))
        .where((area) => area.total >= 3)
        .toList(growable: false)
      ..sort((a, b) => a.accuracy.compareTo(b.accuracy));

    final byTopic = topicTotals.entries
        .map((entry) => AreaScore(
              label: entry.key,
              total: entry.value[0],
              correct: entry.value[1],
            ))
        .where((area) => area.total >= 3)
        .toList(growable: false)
      ..sort((a, b) => a.accuracy.compareTo(b.accuracy));

    final (recent, previous) = _accuracyWindows(sessions, now);

    final report = WeaknessReport(
      weakWords: limited,
      byPartOfSpeech: byPos,
      byTopic: byTopic.take(6).toList(growable: false),
      errorByType: errorByType,
      recentAccuracy: recent,
      previousAccuracy: previous,
      totalTracked: states.length,
      suggestions: const <String>[],
    );

    return WeaknessReport(
      weakWords: report.weakWords,
      byPartOfSpeech: report.byPartOfSpeech,
      byTopic: report.byTopic,
      errorByType: report.errorByType,
      recentAccuracy: report.recentAccuracy,
      previousAccuracy: report.previousAccuracy,
      totalTracked: report.totalTracked,
      suggestions: buildSuggestions(report),
    );
  }

  /// پیشنهادهای عملی بر پایه‌ی گزارش.
  List<String> buildSuggestions(WeaknessReport report) {
    final suggestions = <String>[];
    final area = report.weakestArea;
    if (area != null && area.accuracy < 0.65) {
      suggestions.add(
        'در «${area.label}ها» دقت کمتری داری؛ تمرین همین حوزه را در صف مرور بگذار.',
      );
    }
    final mistake = report.mostCommonMistake;
    if (mistake != null) {
      suggestions.add('بیشترین خطاهایت در تمرین «$mistake» رخ داده است. کمی آهسته‌تر پاسخ بده.');
    }
    if (report.accuracyDelta < -0.05) {
      suggestions.add('دقتت نسبت به هفته‌ی قبل کمی افت کرده؛ جلسه‌ها را کوتاه‌تر اما روزانه کن.');
    } else if (report.accuracyDelta > 0.05) {
      suggestions.add('دقتت بهتر شده؛ همین روش را ادامه بده 👌');
    }
    if (report.weakWords.length >= 5) {
      suggestions.add('${report.weakWords.length} واژه‌ی دشوار داری؛ با «مرور نقاط ضعف» شروع کن.');
    }
    if (suggestions.isEmpty) {
      suggestions.add('وضعیتت متعادل است؛ با واژه‌های تازه ادامه بده.');
    }
    return suggestions;
  }

  (double, double) _accuracyWindows(List<StudySession> sessions, DateTime now) {
    var recentTotal = 0;
    var recentCorrect = 0;
    var previousTotal = 0;
    var previousCorrect = 0;

    for (final session in sessions) {
      final daysAgo = now.difference(session.finishedAt).inDays;
      if (daysAgo < 0) continue;
      if (daysAgo <= 7) {
        recentTotal += session.correctCount + session.wrongCount;
        recentCorrect += session.correctCount;
      } else if (daysAgo <= 14) {
        previousTotal += session.correctCount + session.wrongCount;
        previousCorrect += session.correctCount;
      }
    }

    final recent = recentTotal == 0 ? 0.0 : recentCorrect / recentTotal;
    final previous = previousTotal == 0 ? 0.0 : previousCorrect / previousTotal;
    return (recent, previous);
  }

  String _reasonFor(ReviewState state, double errorRate, int errors) {
    if (state.lapses >= 4) return '${state.lapses} بار فراموشش کرده‌ای';
    if (errorRate >= 0.5) return 'کمتر از نیمی از پاسخ‌ها درست بوده';
    if (errors >= 3) return '$errors پاسخ نادرست';
    return 'نیاز به مرور بیشتر';
  }
}
