import 'package:flutter/foundation.dart';

import 'cefr_level.dart';

/// هدف کاربر از یادگیری زبان انگلیسی.
enum LearningGoal {
  travel(faTitle: 'سفر و مکالمه', emoji: '✈️', topics: <String>['travel', 'food', 'daily']),
  work(faTitle: 'کار و مکاتبه', emoji: '💼', topics: <String>['business', 'email', 'daily']),
  exam(faTitle: 'آزمون‌های بین‌المللی', emoji: '🎯', topics: <String>['academic', 'business']),
  media(faTitle: 'فیلم، سریال و کتاب', emoji: '🍿', topics: <String>['media', 'daily', 'feelings']),
  academic(faTitle: 'ادامه‌ی تحصیل', emoji: '🎓', topics: <String>['academic', 'science']);

  const LearningGoal({required this.faTitle, required this.emoji, required this.topics});

  final String faTitle;
  final String emoji;

  /// موضوع‌هایی که با این هدف هم‌خوان‌اند (برای پیشنهاد بسته‌ی محتوا).
  final List<String> topics;
}

/// پروفایل کاربر — کاملاً محلی و بدون نیاز به حساب ابری.
@immutable
class UserProfile {
  const UserProfile({
    required this.name,
    required this.goal,
    required this.level,
    required this.createdAt,
    this.onboarded = false,
    this.placementDone = false,
    this.placementScore = 0,
    this.lastPlacementAt,
  });

  factory UserProfile.guest(DateTime now) => UserProfile(
        name: 'دوست واژه‌یار',
        goal: LearningGoal.travel,
        level: CefrLevel.a1,
        createdAt: now,
      );

  final String name;
  final LearningGoal goal;

  /// سطح برآوردشده‌ی کاربر.
  final CefrLevel level;

  final DateTime createdAt;

  /// آیا مرحله‌ی معرفی (آنبوردینگ) کامل شده است؟
  final bool onboarded;

  /// آیا آزمون تعیین سطح را انجام داده است؟
  final bool placementDone;

  /// امتیاز خام آزمون تعیین سطح (۰ تا ۱۰۰).
  final double placementScore;

  final DateTime? lastPlacementAt;

  /// حرف اول نام برای آواتار (با پشتیبانی از نویسه‌های چندبایتی).
  String get initial {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'و';
    return String.fromCharCode(trimmed.runes.first);
  }

  UserProfile copyWith({
    String? name,
    LearningGoal? goal,
    CefrLevel? level,
    DateTime? createdAt,
    bool? onboarded,
    bool? placementDone,
    double? placementScore,
    DateTime? lastPlacementAt,
  }) {
    return UserProfile(
      name: name ?? this.name,
      goal: goal ?? this.goal,
      level: level ?? this.level,
      createdAt: createdAt ?? this.createdAt,
      onboarded: onboarded ?? this.onboarded,
      placementDone: placementDone ?? this.placementDone,
      placementScore: placementScore ?? this.placementScore,
      lastPlacementAt: lastPlacementAt ?? this.lastPlacementAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is UserProfile &&
      other.name == name &&
      other.goal == goal &&
      other.level == level &&
      other.onboarded == onboarded &&
      other.placementDone == placementDone &&
      other.placementScore == placementScore;

  @override
  int get hashCode =>
      Object.hash(name, goal, level, onboarded, placementDone, placementScore);
}
