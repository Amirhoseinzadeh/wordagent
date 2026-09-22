import '../entities/achievement.dart';
import '../entities/chat_message.dart';
import '../entities/progress.dart';
import '../entities/review_state.dart';
import '../entities/settings.dart';
import '../entities/study_session.dart';
import '../entities/subscription.dart';
import '../entities/user_profile.dart';

/// تصویر کامل پیشرفت کاربر در یک لحظه.
class ProgressData {
  const ProgressData({
    required this.profile,
    required this.settings,
    required this.states,
    required this.sessions,
    required this.streak,
    required this.xp,
    required this.challenge,
    required this.achievements,
    required this.chat,
    required this.subscription,
  });

  final UserProfile profile;
  final AppSettings settings;
  final Map<String, ReviewState> states;
  final List<StudySession> sessions;
  final StreakState streak;
  final XpState xp;
  final DailyChallengeState challenge;
  final Map<String, AchievementProgress> achievements;
  final List<ChatMessage> chat;
  final SubscriptionState subscription;
}

/// قرارداد ذخیره‌سازی پیشرفت کاربر.
abstract class ProgressRepository {
  /// خواندن همه‌ی داده‌ها از حافظه‌ی محلی.
  Future<ProgressData> load();

  Future<void> saveProfile(UserProfile profile);

  Future<void> saveSettings(AppSettings settings);

  Future<void> saveStates(Map<String, ReviewState> states);

  Future<void> saveSessions(List<StudySession> sessions);

  Future<void> saveStreak(StreakState streak);

  Future<void> saveXp(XpState xp);

  Future<void> saveChallenge(DailyChallengeState challenge);

  Future<void> saveAchievements(Map<String, AchievementProgress> achievements);

  Future<void> saveChat(List<ChatMessage> chat);

  Future<void> saveSubscription(SubscriptionState subscription);

  /// پاک‌کردن همه‌ی داده‌های کاربر.
  Future<void> resetAll();

  /// برون‌بری همه‌ی داده‌ها (JSON) برای پشتیبان‌گیری.
  Future<String> exportJson();

  /// نوشتن فوری داده‌های معلق.
  Future<void> flush();
}
