import 'package:flutter/foundation.dart';

import '../../domain/entities/achievement.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/pack.dart';
import '../../domain/entities/progress.dart';
import '../../domain/entities/review_state.dart';
import '../../domain/entities/settings.dart';
import '../../domain/entities/study_session.dart';
import '../../domain/entities/subscription.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/entities/word.dart';
import '../../domain/engines/stats_engine.dart';
import '../../domain/engines/weakness_engine.dart';
import '../../domain/engines/xp_engine.dart';
import 'value_store.dart';

/// همه‌ی وضعیت‌های زنده‌ی اپلیکیشن در یک‌جا.
///
/// هر Store یک `ValueListenable` است؛ ویجت‌ها با `StoreBuilder` یا `Watch`
/// دقیقاً همان بخشی را که به داده وابسته است بازسازی می‌کنند. مقادیر مشتق
/// (آمار، نقاط ضعف، سطح) خودکار و بدون محاسبه‌ی تکراری به‌روز می‌شوند.
class AppStores {
  AppStores({
    required UserProfile profile,
    required AppSettings settings,
    required Map<String, ReviewState> states,
    required List<StudySession> sessions,
    required StreakState streak,
    required XpState xp,
    required DailyChallengeState challenge,
    required Map<String, AchievementProgress> achievements,
    required List<ChatMessage> chat,
    required SubscriptionState subscription,
    required List<Word> words,
    required List<StudyPack> packs,
    StatsEngine statsEngine = const StatsEngine(),
    WeaknessEngine weaknessEngine = const WeaknessEngine(),
  })  : profileStore = ValueStore<UserProfile>(profile, debugLabel: 'profile'),
        settingsStore = ValueStore<AppSettings>(settings, debugLabel: 'settings'),
        statesStore = ValueStore<Map<String, ReviewState>>(
          states,
          debugLabel: 'reviewStates',
        ),
        sessionsStore = ValueStore<List<StudySession>>(sessions, debugLabel: 'sessions'),
        streakStore = ValueStore<StreakState>(streak, debugLabel: 'streak'),
        xpStore = ValueStore<XpState>(xp, debugLabel: 'xp'),
        challengeStore =
            ValueStore<DailyChallengeState>(challenge, debugLabel: 'challenge'),
        achievementsStore = ValueStore<Map<String, AchievementProgress>>(
          achievements,
          debugLabel: 'achievements',
        ),
        chatStore = ValueStore<List<ChatMessage>>(chat, debugLabel: 'chat'),
        subscriptionStore =
            ValueStore<SubscriptionState>(subscription, debugLabel: 'subscription'),
        wordsStore = ValueStore<List<Word>>(words, debugLabel: 'words'),
        packsStore = ValueStore<List<StudyPack>>(packs, debugLabel: 'packs') {
    wordIndexStore = DerivedStore<Map<String, Word>>(
      <Listenable>[wordsStore],
      () => <String, Word>{for (final word in wordsStore.value) word.id: word},
      debugLabel: 'wordIndex',
    );
    statsStore = DerivedStore<ProgressStats>(
      <Listenable>[statesStore, sessionsStore, streakStore],
      () => statsEngine.compute(
        states: statesStore.value,
        sessions: sessionsStore.value,
        streak: streakStore.value,
        now: DateTime.now(),
      ),
      debugLabel: 'stats',
    );
    weaknessStore = DerivedStore<WeaknessReport>(
      <Listenable>[statesStore, sessionsStore, wordsStore],
      () => weaknessEngine.analyze(
        words: wordsStore.value,
        states: statesStore.value,
        sessions: sessionsStore.value,
        now: DateTime.now(),
      ),
      debugLabel: 'weakness',
    );
    appLevelStore = DerivedStore<AppLevel>(
      <Listenable>[xpStore],
      () => XpEngine.levelFor(xpStore.value.totalXp),
      debugLabel: 'appLevel',
    );
  }

  // ------------------------------------------------------- وضعیت‌های پایه
  final ValueStore<UserProfile> profileStore;
  final ValueStore<AppSettings> settingsStore;
  final ValueStore<Map<String, ReviewState>> statesStore;
  final ValueStore<List<StudySession>> sessionsStore;
  final ValueStore<StreakState> streakStore;
  final ValueStore<XpState> xpStore;
  final ValueStore<DailyChallengeState> challengeStore;
  final ValueStore<Map<String, AchievementProgress>> achievementsStore;
  final ValueStore<List<ChatMessage>> chatStore;
  final ValueStore<SubscriptionState> subscriptionStore;
  final ValueStore<List<Word>> wordsStore;
  final ValueStore<List<StudyPack>> packsStore;

  // ------------------------------------------------------ مقادیر مشتق‌شده
  late final DerivedStore<Map<String, Word>> wordIndexStore;
  late final DerivedStore<ProgressStats> statsStore;
  late final DerivedStore<WeaknessReport> weaknessStore;
  late final DerivedStore<AppLevel> appLevelStore;

  // -------------------------------------------------------------- کمکی‌ها
  ReviewState stateFor(String wordId) =>
      statesStore.value[wordId] ?? ReviewState(wordId: wordId);

  ReviewState? existingStateFor(String wordId) => statesStore.value[wordId];

  Word? wordById(String id) => wordIndexStore.value[id];

  /// آیا امروز چالش انجام شده است؟
  bool isChallengeDone(String todayKey) =>
      challengeStore.value.isCompletedFor(todayKey);

  void dispose() {
    profileStore.dispose();
    settingsStore.dispose();
    statesStore.dispose();
    sessionsStore.dispose();
    streakStore.dispose();
    xpStore.dispose();
    challengeStore.dispose();
    achievementsStore.dispose();
    chatStore.dispose();
    subscriptionStore.dispose();
    wordsStore.dispose();
    packsStore.dispose();
    wordIndexStore.dispose();
    statsStore.dispose();
    weaknessStore.dispose();
    appLevelStore.dispose();
  }
}
