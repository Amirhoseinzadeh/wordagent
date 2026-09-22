import 'package:flutter/foundation.dart';

import '../entities/progress.dart';
import '../entities/review_state.dart';
import '../entities/study_session.dart';

/// فعالیت یک روز (برای نمودارها و نقشه‌ی حرارتی).
@immutable
class DailyActivity {
  const DailyActivity({
    required this.dayKey,
    required this.date,
    required this.reviews,
    required this.xp,
    required this.minutes,
    required this.correct,
    required this.wrong,
  });

  final String dayKey;
  final DateTime date;
  final int reviews;
  final int xp;
  final int minutes;
  final int correct;
  final int wrong;

  double get accuracy {
    final total = correct + wrong;
    return total == 0 ? 0 : correct / total;
  }

  bool get hasActivity => reviews > 0 || xp > 0;
}

/// همه‌ی آمار محاسبه‌شده‌ی کاربر.
@immutable
class ProgressStats {
  const ProgressStats({
    required this.wordsStarted,
    required this.wordsMastered,
    required this.wordsLearning,
    required this.wordsReviewing,
    required this.wordsLeech,
    required this.wordsBookmarked,
    required this.totalReviews,
    required this.totalCorrect,
    required this.totalSessions,
    required this.totalMinutes,
    required this.longestSessionMinutes,
    required this.last30Days,
    required this.accuracyTrend,
    required this.statusCounts,
    required this.masteryBuckets,
    required this.streak,
  });

  factory ProgressStats.empty() => ProgressStats(
        wordsStarted: 0,
        wordsMastered: 0,
        wordsLearning: 0,
        wordsReviewing: 0,
        wordsLeech: 0,
        wordsBookmarked: 0,
        totalReviews: 0,
        totalCorrect: 0,
        totalSessions: 0,
        totalMinutes: 0,
        longestSessionMinutes: 0,
        last30Days: const <DailyActivity>[],
        accuracyTrend: const <double>[],
        statusCounts: const <WordStatus, int>{},
        masteryBuckets: const <int, int>{},
        streak: const StreakState(),
      );

  final int wordsStarted;
  final int wordsMastered;
  final int wordsLearning;
  final int wordsReviewing;
  final int wordsLeech;
  final int wordsBookmarked;

  final int totalReviews;
  final int totalCorrect;
  final int totalSessions;
  final int totalMinutes;
  final int longestSessionMinutes;

  /// فعالیت ۳۰ روز گذشته (از قدیم به جدید).
  final List<DailyActivity> last30Days;

  /// دقت روزهای گذشته برای نمودار روند (۱۴ روز).
  final List<double> accuracyTrend;

  final Map<WordStatus, int> statusCounts;

  /// توزیع واژه‌ها در سبدهای تسلط (۰، ۲۵، ۵۰، ۷۵، ۱۰۰ درصد).
  final Map<int, int> masteryBuckets;

  final StreakState streak;

  double get accuracy => totalReviews == 0 ? 0 : totalCorrect / totalReviews;

  int get activeDays => last30Days.where((day) => day.hasActivity).length;

  /// میانگین واژه‌ی مرورشده در روزهای فعال.
  double get averageReviewsPerActiveDay =>
      activeDays == 0 ? 0 : totalReviews / activeDays;

  int get todayReviews {
    if (last30Days.isEmpty) return 0;
    return last30Days.last.reviews;
  }

  int get todayXp => last30Days.isEmpty ? 0 : last30Days.last.xp;
}

/// موتور محاسبه‌ی آمار و نمودارها.
class StatsEngine {
  const StatsEngine();

  ProgressStats compute({
    required Map<String, ReviewState> states,
    required List<StudySession> sessions,
    required StreakState streak,
    required DateTime now,
    int days = 30,
  }) {
    if (states.isEmpty && sessions.isEmpty) {
      return ProgressStats(
        wordsStarted: 0,
        wordsMastered: 0,
        wordsLearning: 0,
        wordsReviewing: 0,
        wordsLeech: 0,
        wordsBookmarked: 0,
        totalReviews: 0,
        totalCorrect: 0,
        totalSessions: 0,
        totalMinutes: 0,
        longestSessionMinutes: 0,
        last30Days: _emptyDays(now, days),
        accuracyTrend: List<double>.filled(14, 0),
        statusCounts: const <WordStatus, int>{},
        masteryBuckets: const <int, int>{},
        streak: streak,
      );
    }

    var totalReviews = 0;
    var totalCorrect = 0;
    var bookmarked = 0;
    final statusCounts = <WordStatus, int>{};
    final masteryBuckets = <int, int>{0: 0, 25: 0, 50: 0, 75: 0, 100: 0};

    for (final state in states.values) {
      totalReviews += state.totalReviews;
      totalCorrect += state.correctReviews;
      if (state.bookmarked) bookmarked += 1;
      final status = state.status;
      statusCounts[status] = (statusCounts[status] ?? 0) + 1;

      final bucket = (state.masteryPercent ~/ 25) * 25;
      masteryBuckets[bucket] = (masteryBuckets[bucket] ?? 0) + 1;
    }

    final activities = _buildActivity(sessions, now, days);
    final trend = _buildAccuracyTrend(sessions, now, 14);
    final totalSessions = sessions.length;
    var totalMinutes = 0;
    var longest = 0;
    for (final session in sessions) {
      final minutes = session.duration.inMinutes;
      totalMinutes += minutes;
      if (minutes > longest) longest = minutes;
    }

    return ProgressStats(
      wordsStarted: states.length,
      wordsMastered: statusCounts[WordStatus.mastered] ?? 0,
      wordsLearning: statusCounts[WordStatus.learning] ?? 0,
      wordsReviewing: statusCounts[WordStatus.reviewing] ?? 0,
      wordsLeech: statusCounts[WordStatus.leech] ?? 0,
      wordsBookmarked: bookmarked,
      totalReviews: totalReviews,
      totalCorrect: totalCorrect,
      totalSessions: totalSessions,
      totalMinutes: totalMinutes,
      longestSessionMinutes: longest,
      last30Days: activities,
      accuracyTrend: trend,
      statusCounts: statusCounts,
      masteryBuckets: masteryBuckets,
      streak: streak,
    );
  }

  List<DailyActivity> _buildActivity(
    List<StudySession> sessions,
    DateTime now,
    int days,
  ) {
    final byDay = <String, List<StudySession>>{};
    for (final session in sessions) {
      byDay.putIfAbsent(session.dayKey, () => <StudySession>[]).add(session);
    }

    final result = <DailyActivity>[];
    final today = DateTime(now.year, now.month, now.day);
    for (var offset = days - 1; offset >= 0; offset--) {
      final date = today.subtract(Duration(days: offset));
      final key = _dayKey(date);
      final daySessions = byDay[key] ?? const <StudySession>[];
      var reviews = 0;
      var xp = 0;
      var minutes = 0;
      var correct = 0;
      var wrong = 0;
      for (final session in daySessions) {
        reviews += session.reviewedCount;
        xp += session.xpEarned;
        minutes += session.duration.inMinutes;
        correct += session.correctCount;
        wrong += session.wrongCount;
      }
      result.add(
        DailyActivity(
          dayKey: key,
          date: date,
          reviews: reviews,
          xp: xp,
          minutes: minutes,
          correct: correct,
          wrong: wrong,
        ),
      );
    }
    return result;
  }

  List<double> _buildAccuracyTrend(
    List<StudySession> sessions,
    DateTime now,
    int days,
  ) {
    final byDay = <String, List<int>>{};
    for (final session in sessions) {
      final bucket = byDay.putIfAbsent(session.dayKey, () => <int>[0, 0]);
      bucket[0] += session.correctCount;
      bucket[1] += session.correctCount + session.wrongCount;
    }

    final today = DateTime(now.year, now.month, now.day);
    final trend = <double>[];
    for (var offset = days - 1; offset >= 0; offset--) {
      final date = today.subtract(Duration(days: offset));
      final bucket = byDay[_dayKey(date)];
      if (bucket == null || bucket[1] == 0) {
        trend.add(trend.isEmpty ? 0 : trend.last);
      } else {
        trend.add(bucket[0] / bucket[1]);
      }
    }
    return trend;
  }

  List<DailyActivity> _emptyDays(DateTime now, int days) {
    final today = DateTime(now.year, now.month, now.day);
    return List<DailyActivity>.generate(days, (index) {
      final date = today.subtract(Duration(days: days - 1 - index));
      return DailyActivity(
        dayKey: _dayKey(date),
        date: date,
        reviews: 0,
        xp: 0,
        minutes: 0,
        correct: 0,
        wrong: 0,
      );
    });
  }

  String _dayKey(DateTime date) {
    final month = date.month < 10 ? '0${date.month}' : '${date.month}';
    final day = date.day < 10 ? '0${date.day}' : '${date.day}';
    return '${date.year}-$month-$day';
  }

  /// آمار سبک برای پیشرفت هفتگی (نگاشت روز ⟶ دقیقه مطالعه).
  Map<String, int> weeklyMinutes(List<DailyActivity> days) {
    final result = <String, int>{};
    for (final day in days) {
      result[day.dayKey] = day.minutes;
    }
    return result;
  }

  /// تعداد واژه‌های مرورشده در یک روز مشخص.
  int reviewsOn(List<DailyActivity> days, DateTime date) {
    final key = _dayKey(date);
    for (final day in days) {
      if (day.dayKey == key) return day.reviews;
    }
    return 0;
  }
}
