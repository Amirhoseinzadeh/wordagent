import 'package:flutter/foundation.dart';

/// سنجه‌ای که پیشرفت یک دستاورد را می‌سنجد.
enum AchievementMetric {
  wordsStarted(faTitle: 'لغت شروع‌شده', target: 1),
  wordsMastered(faTitle: 'لغت مسلط', target: 1),
  reviewsDone(faTitle: 'مرور انجام‌شده', target: 1),
  correctAnswers(faTitle: 'پاسخ درست', target: 1),
  perfectSessions(faTitle: 'جلسه‌ی بی‌غلط', target: 1),
  streakDays(faTitle: 'روز زنجیره', target: 1),
  totalXp(faTitle: 'امتیاز تجربه', target: 1),
  levelReached(faTitle: 'سطح زبان', target: 1),
  challengesDone(faTitle: 'چالش روزانه', target: 1),
  listeningCorrect(faTitle: 'پاسخ درست شنیداری', target: 1),
  typingCorrect(faTitle: 'پاسخ درست تایپی', target: 1),
  sentenceCorrect(faTitle: 'جمله‌سازی درست', target: 1),
  studyMinutes(faTitle: 'دقیقه مطالعه', target: 1),
  bookmarkedWords(faTitle: 'لغت نشان‌شده', target: 1),
  aiChatMessages(faTitle: 'پیام با دستیار', target: 1),
  wordsInOneDay(faTitle: 'لغت در یک روز', target: 1);

  const AchievementMetric({required this.faTitle, required this.target});

  final String faTitle;

  /// مقدار پیش‌فرض هدف (هر دستاورد هدف خود را از داده‌ی محتوا می‌گیرد).
  final int target;
}

/// یک دستاورد (نشان).
@immutable
class Achievement {
  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.metric,
    required this.target,
    required this.emoji,
    this.xpReward = 0,
    this.premium = false,
    this.tier = 1,
  });

  final String id;
  final String title;
  final String description;
  final AchievementMetric metric;
  final int target;
  final String emoji;
  final int xpReward;
  final bool premium;

  /// رده‌ی سختی ۱ تا ۳ (برای رنگ نشان).
  final int tier;

  String get progressLabel => '$target';

  @override
  bool operator ==(Object other) => other is Achievement && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// پیشرفت کاربر در یک دستاورد.
@immutable
class AchievementProgress {
  const AchievementProgress({
    required this.id,
    this.current = 0,
    this.unlockedAt,
    this.isNew = false,
  });

  final String id;
  final int current;
  final DateTime? unlockedAt;

  /// آیا از آخرین بازدید کاربر تا حالا باز شده است؟ (برای نشان «جدید»)
  final bool isNew;

  bool get isUnlocked => unlockedAt != null;

  AchievementProgress copyWith({
    String? id,
    int? current,
    DateTime? unlockedAt,
    bool? isNew,
  }) {
    return AchievementProgress(
      id: id ?? this.id,
      current: current ?? this.current,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      isNew: isNew ?? this.isNew,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is AchievementProgress &&
      other.id == id &&
      other.current == current &&
      other.unlockedAt == unlockedAt &&
      other.isNew == isNew;

  @override
  int get hashCode => Object.hash(id, current, unlockedAt, isNew);
}
