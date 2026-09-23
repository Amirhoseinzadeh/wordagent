import 'dart:convert';

import '../../core/services/app_services.dart';
import '../../core/storage/local_store.dart';
import '../../domain/entities/achievement.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/progress.dart';
import '../../domain/entities/review_state.dart';
import '../../domain/entities/settings.dart';
import '../../domain/entities/study_session.dart';
import '../../domain/entities/subscription.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/progress_repository.dart';
import '../mappers/json_utils.dart';
import '../mappers/progress_mapper.dart';

/// پیاده‌سازی ذخیره‌سازی پیشرفت روی حافظه‌ی محلی.
///
/// همه‌ی داده‌ها به شکل رشته‌ی JSON ذخیره می‌شوند؛ نوشتن فیزیکی توسط
/// `LocalStore` با تأخیر و به‌صورت اتمیک انجام می‌گیرد.
class ProgressRepositoryImpl implements ProgressRepository {
  ProgressRepositoryImpl(this._store, this._clock);

  final LocalStore _store;
  final AppClock _clock;

  @override
  Future<ProgressData> load() async {
    final now = _clock.now();
    final profile = _read(
      StoreKeys.profile,
      (map) => ProgressMapper.profileFromJson(map, now),
    );
    final settings = _read(StoreKeys.settings, ProgressMapper.settingsFromJson);
    final states = ProgressMapper.reviewStatesFromJson(
      ProgressMapper.decodeAny(_store.getString(StoreKeys.progress)),
    );
    final sessions = ProgressMapper.sessionsFromJson(
      ProgressMapper.decodeAny(_store.getString(StoreKeys.sessions)),
    );
    final streak = _read(StoreKeys.streak, ProgressMapper.streakFromJson);
    final achievements = ProgressMapper.achievementsFromJson(
      ProgressMapper.decodeAny(_store.getString(StoreKeys.achievements)),
    );
    final chat = ProgressMapper.chatsFromJson(
      ProgressMapper.decodeAny(_store.getString(StoreKeys.chat)),
    );
    final subscription = _read(StoreKeys.subscription, ProgressMapper.subscriptionFromJson);

    // زنجیره و امتیاز و چالش در یک کلید با هم نگه داشته می‌شوند.
    final progressBlob = ProgressMapper.decodeMap(_store.getString('gamification'));
    final xpMap = JsonUtils.asMap(progressBlob['xp']);
    final challengeMap = JsonUtils.asMap(progressBlob['challenge']);
    final xp = xpMap.isEmpty ? const XpState() : ProgressMapper.xpFromJson(xpMap);
    final challenge = challengeMap.isEmpty
        ? const DailyChallengeState()
        : ProgressMapper.challengeFromJson(challengeMap);

    return ProgressData(
      profile: profile ??
          UserProfile.guest(now),
      settings: settings ?? const AppSettings(),
      states: states,
      sessions: sessions,
      streak: streak ?? const StreakState(),
      xp: xp,
      challenge: challenge,
      achievements: achievements,
      chat: chat,
      subscription: subscription ?? const SubscriptionState(),
    );
  }

  @override
  Future<void> saveProfile(UserProfile profile) =>
      _write(StoreKeys.profile, ProgressMapper.profileToJson(profile));

  @override
  Future<void> saveSettings(AppSettings settings) =>
      _write(StoreKeys.settings, ProgressMapper.settingsToJson(settings));

  @override
  Future<void> saveStates(Map<String, ReviewState> states) async {
    final encoded = jsonEncode(ProgressMapper.reviewStatesToJson(states));
    await _store.setString(StoreKeys.progress, encoded);
  }

  @override
  Future<void> saveSessions(List<StudySession> sessions) async {
    // فقط ۱۸۰ جلسه‌ی آخر نگه داشته می‌شود تا فایل بی‌نهایت رشد نکند.
    final trimmed = sessions.length > 180
        ? sessions.sublist(sessions.length - 180)
        : sessions;
    await _store.setString(StoreKeys.sessions, jsonEncode(ProgressMapper.sessionsToJson(trimmed)));
  }

  @override
  Future<void> saveStreak(StreakState streak) async {
    await _write(StoreKeys.streak, ProgressMapper.streakToJson(streak));
  }

  @override
  Future<void> saveXp(XpState xp) async {
    final current = ProgressMapper.decodeMap(_store.getString('gamification'));
    final payload = <String, dynamic>{
      'xp': ProgressMapper.xpToJson(xp),
      if (current['challenge'] != null) 'challenge': current['challenge'],
    };
    await _store.setString('gamification', jsonEncode(payload));
  }

  @override
  Future<void> saveChallenge(DailyChallengeState challenge) async {
    final current = ProgressMapper.decodeMap(_store.getString('gamification'));
    final payload = <String, dynamic>{
      if (current['xp'] != null) 'xp': current['xp'],
      'challenge': ProgressMapper.challengeToJson(challenge),
    };
    await _store.setString('gamification', jsonEncode(payload));
  }

  @override
  Future<void> saveAchievements(Map<String, AchievementProgress> achievements) async {
    final encoded = jsonEncode(ProgressMapper.achievementsToJson(achievements));
    await _store.setString(StoreKeys.achievements, encoded);
  }

  @override
  Future<void> saveChat(List<ChatMessage> chat) async {
    // فقط ۱۰۰ پیام آخر نگه داشته می‌شود.
    final trimmed = chat.length > 100 ? chat.sublist(chat.length - 100) : chat;
    await _store.setString(StoreKeys.chat, jsonEncode(ProgressMapper.chatsToJson(trimmed)));
  }

  @override
  Future<void> saveSubscription(SubscriptionState subscription) =>
      _write(StoreKeys.subscription, ProgressMapper.subscriptionToJson(subscription));

  @override
  Future<void> resetAll() async {
    await _store.clear();
    await _store.flush();
  }

  @override
  Future<String> exportJson() async {
    final tracked = ProgressMapper.decodeAny(_store.getString(StoreKeys.progress));
    final payload = <String, dynamic>{
      'exported_at': _clock.now().toIso8601String(),
      'words_started': tracked is List ? tracked.length : 0,
      'data': _store.exportAll(),
    };
    return jsonEncode(payload);
  }

  @override
  Future<void> flush() => _store.flush();

  // ---------------------------------------------------------------- کمکی

  T? _read<T extends Object>(String key, T Function(Map<String, dynamic>) decode) {
    final raw = _store.getString(key);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      return decode(ProgressMapper.decodeMap(jsonEncode(decoded)));
    } catch (_) {
      return null;
    }
  }

  Future<void> _write(String key, Map<String, dynamic> value) async {
    await _store.setString(key, jsonEncode(value));
  }
}
