import 'package:flutter/foundation.dart';

/// نوع جلسه‌ی مطالعه.
enum SessionKind {
  placement(faTitle: 'تعیین سطح', emoji: '🧭'),
  learn(faTitle: 'یادگیری لغت تازه', emoji: '🌱'),
  review(faTitle: 'مرور هوشمند', emoji: '🔁'),
  quiz(faTitle: 'تمرین', emoji: '📝'),
  challenge(faTitle: 'چالش روزانه', emoji: '🔥'),
  weak(faTitle: 'تقویت نقاط ضعف', emoji: '🎯');

  const SessionKind({required this.faTitle, required this.emoji});

  final String faTitle;
  final String emoji;
}

/// یک جلسه‌ی مطالعه‌ی ثبت‌شده (مبنای نمودارها و آمار).
@immutable
class StudySession {
  const StudySession({
    required this.id,
    required this.kind,
    required this.startedAt,
    required this.finishedAt,
    this.reviewedCount = 0,
    this.correctCount = 0,
    this.wrongCount = 0,
    this.xpEarned = 0,
    this.wordIds = const <String>[],
  });

  final String id;
  final SessionKind kind;
  final DateTime startedAt;
  final DateTime finishedAt;
  final int reviewedCount;
  final int correctCount;
  final int wrongCount;
  final int xpEarned;
  final List<String> wordIds;

  Duration get duration {
    final diff = finishedAt.difference(startedAt);
    return diff.isNegative ? Duration.zero : diff;
  }

  double get accuracy {
    final total = correctCount + wrongCount;
    if (total == 0) return 0;
    return correctCount / total;
  }

  /// کلید روز مطالعه برای گروه‌بندی در نمودارها.
  String get dayKey {
    final value = startedAt.subtract(const Duration(hours: 4));
    final month = value.month < 10 ? '0${value.month}' : '${value.month}';
    final day = value.day < 10 ? '0${value.day}' : '${value.day}';
    return '${value.year}-$month-$day';
  }

  StudySession copyWith({
    String? id,
    SessionKind? kind,
    DateTime? startedAt,
    DateTime? finishedAt,
    int? reviewedCount,
    int? correctCount,
    int? wrongCount,
    int? xpEarned,
    List<String>? wordIds,
  }) {
    return StudySession(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      startedAt: startedAt ?? this.startedAt,
      finishedAt: finishedAt ?? this.finishedAt,
      reviewedCount: reviewedCount ?? this.reviewedCount,
      correctCount: correctCount ?? this.correctCount,
      wrongCount: wrongCount ?? this.wrongCount,
      xpEarned: xpEarned ?? this.xpEarned,
      wordIds: wordIds ?? this.wordIds,
    );
  }

  @override
  bool operator ==(Object other) => other is StudySession && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
