import 'dart:convert';

import '../../domain/entities/achievement.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/cefr_level.dart';
import '../../domain/entities/progress.dart';
import '../../domain/entities/review_state.dart';
import '../../domain/entities/settings.dart';
import '../../domain/entities/study_session.dart';
import '../../domain/entities/subscription.dart';
import '../../domain/entities/user_profile.dart';
import 'json_utils.dart';

/// نگاشت داده‌ی پیشرفت کاربر به JSON و برگشت.
///
/// همه‌ی ورودی‌ها تحمل‌پذیر (tolerant) هستند: فایل قدیمی یا ناقص، اپ را
/// از کار نمی‌اندازد و مقدار پیش‌فرض جایگزین می‌شود.
class ProgressMapper {
  const ProgressMapper._();

  // -------------------------------------------------------------- پروفایل
  static Map<String, dynamic> profileToJson(UserProfile profile) => <String, dynamic>{
        'name': profile.name,
        'goal': profile.goal.name,
        'level': profile.level.code,
        'created': profile.createdAt.millisecondsSinceEpoch,
        'placement_done': profile.placementDone,
        'placement_score': profile.placementScore,
        if (profile.lastPlacementAt != null)
          'placement_at': profile.lastPlacementAt!.millisecondsSinceEpoch,
      };

  static UserProfile profileFromJson(Map<String, dynamic> json, DateTime fallbackNow) {
    final goalName = JsonUtils.asString(json['goal']);
    var goal = LearningGoal.travel;
    for (final candidate in LearningGoal.values) {
      if (candidate.name == goalName) goal = candidate;
    }
    return UserProfile(
      name: JsonUtils.asString(json['name'], fallback: 'دوست واژه‌یار'),
      goal: goal,
      level: CefrLevel.fromCode(JsonUtils.asNullableString(json['level'])),
      createdAt: JsonUtils.asDateTime(json['created']) ?? fallbackNow,
      placementDone: JsonUtils.asBool(json['placement_done']),
      placementScore: JsonUtils.asDouble(json['placement_score']),
      lastPlacementAt: JsonUtils.asDateTime(json['placement_at']),
    );
  }

  // --------------------------------------------------------------- تنظیمات
  static Map<String, dynamic> settingsToJson(AppSettings settings) => <String, dynamic>{
        'theme': settings.themeMode.name,
        'goal_minutes': settings.dailyGoalMinutes,
        'new_words': settings.dailyNewWords,
        'reminders': settings.remindersEnabled,
        'reminder_hour': settings.reminderHour,
        'reminder_minute': settings.reminderMinute,
        'speech_speed': settings.speechSpeed,
        'autoplay': settings.autoPlayAudio,
        'haptics': settings.hapticsEnabled,
        'persian_hints': settings.showPersianHints,
        'free_limit': settings.dailyFreeLimitEnabled,
      };

  static AppSettings settingsFromJson(Map<String, dynamic> json) => AppSettings(
        themeMode: AppThemeMode.fromName(JsonUtils.asNullableString(json['theme'])),
        dailyGoalMinutes: JsonUtils.asInt(json['goal_minutes'], fallback: 15).clamp(5, 60),
        dailyNewWords: JsonUtils.asInt(json['new_words'], fallback: 10).clamp(5, 30),
        remindersEnabled: JsonUtils.asBool(json['reminders'], fallback: true),
        reminderHour: JsonUtils.asInt(json['reminder_hour'], fallback: 20).clamp(0, 23),
        reminderMinute: JsonUtils.asInt(json['reminder_minute'], fallback: 30).clamp(0, 59),
        speechSpeed: JsonUtils.asDouble(json['speech_speed'], fallback: 1).clamp(0.5, 2),
        autoPlayAudio: JsonUtils.asBool(json['autoplay']),
        hapticsEnabled: JsonUtils.asBool(json['haptics'], fallback: true),
        showPersianHints: JsonUtils.asBool(json['persian_hints'], fallback: true),
        dailyFreeLimitEnabled: JsonUtils.asBool(json['free_limit'], fallback: true),
      );

  // ----------------------------------------------------------- وضعیت مرور
  static Map<String, dynamic> reviewStateToJson(ReviewState state) => <String, dynamic>{
        'id': state.wordId,
        'rep': state.repetitions,
        'ease': state.ease,
        'iv': state.intervalDays,
        if (state.dueAt != null) 'due': state.dueAt!.millisecondsSinceEpoch,
        if (state.lastReviewedAt != null) 'last': state.lastReviewedAt!.millisecondsSinceEpoch,
        if (state.firstSeenAt != null) 'first': state.firstSeenAt!.millisecondsSinceEpoch,
        'lapses': state.lapses,
        'total': state.totalReviews,
        'correct': state.correctReviews,
        'streak': state.currentStreak,
        'best': state.bestStreak,
        if (state.bookmarked) 'bm': true,
        if (state.note != null && state.note!.isNotEmpty) 'note': state.note,
        if (state.errorsByType.isNotEmpty) 'err': state.errorsByType,
        if (state.correctByType.isNotEmpty) 'ok': state.correctByType,
        if (state.averageResponseMs > 0) 'ms': state.averageResponseMs,
      };

  static ReviewState reviewStateFromJson(Map<String, dynamic> json) {
    final id = JsonUtils.asString(json['id']);
    return ReviewState(
      wordId: id,
      repetitions: JsonUtils.asInt(json['rep']),
      ease: JsonUtils.asDouble(json['ease'], fallback: 2.5).clamp(1.3, 2.8),
      intervalDays: JsonUtils.asDouble(json['iv']),
      dueAt: JsonUtils.asDateTime(json['due']),
      lastReviewedAt: JsonUtils.asDateTime(json['last']),
      firstSeenAt: JsonUtils.asDateTime(json['first']),
      lapses: JsonUtils.asInt(json['lapses']),
      totalReviews: JsonUtils.asInt(json['total']),
      correctReviews: JsonUtils.asInt(json['correct']),
      currentStreak: JsonUtils.asInt(json['streak']),
      bestStreak: JsonUtils.asInt(json['best']),
      bookmarked: JsonUtils.asBool(json['bm']),
      note: JsonUtils.asNullableString(json['note']),
      errorsByType: JsonUtils.asIntMap(json['err']),
      correctByType: JsonUtils.asIntMap(json['ok']),
      averageResponseMs: JsonUtils.asInt(json['ms']),
    );
  }

  /// همه‌ی وضعیت‌ها به شکل فهرست فشرده (برای کم‌حجم ماندن فایل).
  static List<Map<String, dynamic>> reviewStatesToJson(Map<String, ReviewState> states) =>
      states.values.map(reviewStateToJson).toList(growable: false);

  static Map<String, ReviewState> reviewStatesFromJson(dynamic value) {
    final result = <String, ReviewState>{};
    if (value is! List) return result;
    for (final item in value) {
      final map = JsonUtils.asMap(item);
      if (map.isEmpty) continue;
      final state = reviewStateFromJson(map);
      if (state.wordId.isEmpty) continue;
      result[state.wordId] = state;
    }
    return result;
  }

  // ----------------------------------------------------- زنجیره و امتیاز
  static Map<String, dynamic> streakToJson(StreakState streak) => <String, dynamic>{
        'current': streak.current,
        'best': streak.best,
        if (streak.lastStudyDayKey != null) 'last_day': streak.lastStudyDayKey,
        'total_days': streak.totalStudyDays,
        'freezes': streak.freezesAvailable,
        'freezes_used': streak.freezesUsed,
      };

  static StreakState streakFromJson(Map<String, dynamic> json) => StreakState(
        current: JsonUtils.asInt(json['current']),
        best: JsonUtils.asInt(json['best']),
        lastStudyDayKey: JsonUtils.asNullableString(json['last_day']),
        totalStudyDays: JsonUtils.asInt(json['total_days']),
        freezesAvailable: JsonUtils.asInt(json['freezes']),
        freezesUsed: JsonUtils.asInt(json['freezes_used']),
      );

  static Map<String, dynamic> xpToJson(XpState xp) => <String, dynamic>{
        'total': xp.totalXp,
        'daily': xp.dailyXp,
        if (xp.dayKey != null) 'day': xp.dayKey,
        'weekly': xp.weeklyXp,
        if (xp.weekKey != null) 'week': xp.weekKey,
        'best_combo': xp.bestCombo,
        'combo': xp.todayCombo,
      };

  static XpState xpFromJson(Map<String, dynamic> json) => XpState(
        totalXp: JsonUtils.asInt(json['total']),
        dailyXp: JsonUtils.asInt(json['daily']),
        dayKey: JsonUtils.asNullableString(json['day']),
        weeklyXp: JsonUtils.asInt(json['weekly']),
        weekKey: JsonUtils.asNullableString(json['week']),
        bestCombo: JsonUtils.asInt(json['best_combo']),
        todayCombo: JsonUtils.asInt(json['combo']),
      );

  static Map<String, dynamic> challengeToJson(DailyChallengeState challenge) => <String, dynamic>{
        if (challenge.dayKey != null) 'day': challenge.dayKey,
        if (challenge.completedAt != null)
          'done_at': challenge.completedAt!.millisecondsSinceEpoch,
        'correct': challenge.correctCount,
        'total': challenge.totalCount,
        'xp': challenge.xpEarned,
        'streak_days': challenge.streakDays,
      };

  static DailyChallengeState challengeFromJson(Map<String, dynamic> json) =>
      DailyChallengeState(
        dayKey: JsonUtils.asNullableString(json['day']),
        completedAt: JsonUtils.asDateTime(json['done_at']),
        correctCount: JsonUtils.asInt(json['correct']),
        totalCount: JsonUtils.asInt(json['total']),
        xpEarned: JsonUtils.asInt(json['xp']),
        streakDays: JsonUtils.asInt(json['streak_days']),
      );

  // ---------------------------------------------------------------- جلسه
  static Map<String, dynamic> sessionToJson(StudySession session) => <String, dynamic>{
        'id': session.id,
        'kind': session.kind.name,
        'start': session.startedAt.millisecondsSinceEpoch,
        'end': session.finishedAt.millisecondsSinceEpoch,
        'reviewed': session.reviewedCount,
        'correct': session.correctCount,
        'wrong': session.wrongCount,
        'xp': session.xpEarned,
      };

  static StudySession sessionFromJson(Map<String, dynamic> json) {
    final kindName = JsonUtils.asString(json['kind']);
    var kind = SessionKind.review;
    for (final candidate in SessionKind.values) {
      if (candidate.name == kindName) kind = candidate;
    }
    final start = JsonUtils.asDateTime(json['start']) ?? DateTime.now();
    final end = JsonUtils.asDateTime(json['end']) ?? start;
    return StudySession(
      id: JsonUtils.asString(json['id']),
      kind: kind,
      startedAt: start,
      finishedAt: end,
      reviewedCount: JsonUtils.asInt(json['reviewed']),
      correctCount: JsonUtils.asInt(json['correct']),
      wrongCount: JsonUtils.asInt(json['wrong']),
      xpEarned: JsonUtils.asInt(json['xp']),
    );
  }

  static List<Map<String, dynamic>> sessionsToJson(List<StudySession> sessions) =>
      sessions.map(sessionToJson).toList(growable: false);

  static List<StudySession> sessionsFromJson(dynamic value) {
    if (value is! List) return <StudySession>[];
    final result = <StudySession>[];
    for (final item in value) {
      final map = JsonUtils.asMap(item);
      if (map.isEmpty) continue;
      final session = sessionFromJson(map);
      if (session.id.isEmpty) continue;
      result.add(session);
    }
    return result;
  }

  // ------------------------------------------------------------ دستاوردها
  static Map<String, dynamic> achievementToJson(AchievementProgress progress) =>
      <String, dynamic>{
        'id': progress.id,
        'current': progress.current,
        if (progress.unlockedAt != null)
          'at': progress.unlockedAt!.millisecondsSinceEpoch,
        if (progress.isNew) 'new': true,
      };

  static List<Map<String, dynamic>> achievementsToJson(
    Map<String, AchievementProgress> items,
  ) =>
      items.values.map(achievementToJson).toList(growable: false);

  static Map<String, AchievementProgress> achievementsFromJson(dynamic value) {
    final result = <String, AchievementProgress>{};
    if (value is! List) return result;
    for (final item in value) {
      final map = JsonUtils.asMap(item);
      final id = JsonUtils.asString(map['id']);
      if (id.isEmpty) continue;
      result[id] = AchievementProgress(
        id: id,
        current: JsonUtils.asInt(map['current']),
        unlockedAt: JsonUtils.asDateTime(map['at']),
        isNew: JsonUtils.asBool(map['new']),
      );
    }
    return result;
  }

  // -------------------------------------------------------------- اشتراک
  static Map<String, dynamic> subscriptionToJson(SubscriptionState state) =>
      <String, dynamic>{
        'tier': state.tier.name,
        'plan': state.plan.name,
        if (state.startedAt != null) 'start': state.startedAt!.millisecondsSinceEpoch,
        if (state.expiresAt != null) 'expires': state.expiresAt!.millisecondsSinceEpoch,
        if (state.storeId != null) 'store_id': state.storeId,
        'auto_renew': state.autoRenew,
        'trial_used': state.trialUsed,
      };

  static SubscriptionState subscriptionFromJson(Map<String, dynamic> json) {
    final tierName = JsonUtils.asString(json['tier']);
    var tier = SubscriptionTier.free;
    for (final candidate in SubscriptionTier.values) {
      if (candidate.name == tierName) tier = candidate;
    }
    return SubscriptionState(
      tier: tier,
      plan: SubscriptionPlan.fromName(JsonUtils.asNullableString(json['plan'])),
      startedAt: JsonUtils.asDateTime(json['start']),
      expiresAt: JsonUtils.asDateTime(json['expires']),
      storeId: JsonUtils.asNullableString(json['store_id']),
      autoRenew: JsonUtils.asBool(json['auto_renew'], fallback: true),
      trialUsed: JsonUtils.asBool(json['trial_used']),
    );
  }

  // --------------------------------------------------------------- گفت‌وگو
  static Map<String, dynamic> chatToJson(ChatMessage message) => <String, dynamic>{
        'id': message.id,
        'from': message.author.name,
        'text': message.text,
        'at': message.createdAt.millisecondsSinceEpoch,
        if (message.wordId != null) 'word': message.wordId,
      };

  static List<Map<String, dynamic>> chatsToJson(List<ChatMessage> messages) =>
      messages.map(chatToJson).toList(growable: false);

  static List<ChatMessage> chatsFromJson(dynamic value) {
    if (value is! List) return <ChatMessage>[];
    final result = <ChatMessage>[];
    for (final item in value) {
      final map = JsonUtils.asMap(item);
      final text = JsonUtils.asString(map['text']);
      if (text.isEmpty) continue;
      result.add(
        ChatMessage(
          id: JsonUtils.asString(map['id']),
          author: JsonUtils.asString(map['from']) == ChatAuthor.tutor.name
              ? ChatAuthor.tutor
              : ChatAuthor.user,
          text: text,
          createdAt: JsonUtils.asDateTime(map['at']) ?? DateTime.now(),
          wordId: JsonUtils.asNullableString(map['word']),
        ),
      );
    }
    return result;
  }

  // ------------------------------------------------------------------ کلی
  static Map<String, dynamic> decodeMap(String? raw) {
    if (raw == null || raw.isEmpty) return <String, dynamic>{};
    final decoded = _tryDecode(raw);
    return JsonUtils.asMap(decoded);
  }

  static dynamic decodeAny(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    return _tryDecode(raw);
  }

  static dynamic _tryDecode(String raw) {
    try {
      return jsonDecode(raw);
    } catch (_) {
      return null;
    }
  }
}
