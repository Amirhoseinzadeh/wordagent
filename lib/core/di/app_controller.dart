import 'dart:math' as math;

import '../../domain/entities/achievement.dart';
import '../../domain/entities/cefr_level.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/pack.dart';
import '../../domain/entities/progress.dart';
import '../../domain/entities/quiz_question.dart';
import '../../domain/entities/review_state.dart';
import '../../domain/entities/settings.dart';
import '../../domain/entities/study_session.dart';
import '../../domain/entities/subscription.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/entities/word.dart';
import '../../domain/engines/achievement_engine.dart';
import '../../domain/engines/ai_tutor_engine.dart';
import '../../domain/engines/level_engine.dart';
import '../../domain/engines/quiz_engine.dart';
import '../../domain/engines/session_builder.dart';
import '../../domain/engines/srs_engine.dart';
import '../../domain/engines/stats_engine.dart';
import '../../domain/engines/streak_engine.dart';
import '../../domain/engines/weakness_engine.dart';
import '../../domain/engines/xp_engine.dart';
import '../../domain/repositories/ai_repository.dart';
import '../../domain/repositories/progress_repository.dart';
import '../../domain/repositories/subscription_repository.dart';
import '../../domain/repositories/word_repository.dart';
import '../services/app_services.dart';
import '../services/audio_service.dart';
import '../state/app_stores.dart';

/// نتیجه‌ی یک جلسه/تمرین از دید انگیزشی.
class LearningOutcome {
  const LearningOutcome({
    required this.xpEarned,
    required this.correct,
    required this.total,
    required this.leveledUp,
    required this.level,
    required this.streakOutcome,
    required this.streak,
    required this.unlockedAchievements,
    required this.dailyGoalReached,
    required this.dailyGoalPercent,
    required this.challengeCompleted,
  });

  final int xpEarned;
  final int correct;
  final int total;
  final bool leveledUp;
  final AppLevel level;
  final StreakOutcome streakOutcome;
  final StreakState streak;
  final List<Achievement> unlockedAchievements;
  final bool dailyGoalReached;
  final int dailyGoalPercent;
  final bool challengeCompleted;

  int get wrong => total - correct;

  double get accuracy => total == 0 ? 0 : correct / total;
}

/// کنترلر اصلی اپلیکیشن.
///
/// همه‌ی «کارها» (اکشن‌ها) یک‌جا در این کلاس‌اند: رابط کاربری هیچ‌گاه
/// مستقیم داده را تغییر نمی‌دهد، بلکه یک متد این‌جا را صدا می‌زند. نتیجه:
/// منطق کسب‌وکار در یک لایه‌ی مستقل و تست‌پذیر متمرکز می‌شود.
class AppController {
  AppController({
    required this.stores,
    required this.progress,
    required this.words,
    required this.subscriptions,
    required this.ai,
    required this.audio,
    required this.haptics,
    required this.clock,
    SessionBuilder sessionBuilder = const SessionBuilder(),
    SpacedRepetitionEngine srsEngine = const SpacedRepetitionEngine(),
    AchievementEngine achievementEngine = const AchievementEngine(),
    StreakEngine streakEngine = const StreakEngine(),
  })  : _sessionBuilder = sessionBuilder,
        _srs = srsEngine,
        _achievements = achievementEngine,
        _streak = streakEngine;

  final AppStores stores;
  final ProgressRepository progress;
  final WordRepository words;
  final SubscriptionRepository subscriptions;
  final AiRepository ai;
  final AudioService audio;
  final Haptics haptics;
  final AppClock clock;

  final SessionBuilder _sessionBuilder;
  final SpacedRepetitionEngine _srs;
  final AchievementEngine _achievements;
  final StreakEngine _streak;

  // --------------------------------------------------------- دسترسی سریع
  List<Word> get allWords => stores.wordsStore.value;

  List<StudyPack> get packs => stores.packsStore.value;

  UserProfile get profile => stores.profileStore.value;

  AppSettings get settings => stores.settingsStore.value;

  Map<String, ReviewState> get states => stores.statesStore.value;

  SubscriptionState get subscription => stores.subscriptionStore.value;

  bool get hasPremium => subscription.hasPremiumAccess(clock.now());

  String get todayKey => clock.studyDayKey();

  ProgressStats get stats => stores.statsStore.value;

  WeaknessReport get weakness => stores.weaknessStore.value;

  AppLevel get appLevel => stores.appLevelStore.value;

  /// سقف مرور روزانه‌ی نسخه‌ی رایگان.
  static const int freeDailyReviewLimit = 30;

  int get reviewedToday => stats.todayReviews;

  int get remainingFreeCards {
    if (hasPremium) return 99;
    final left = freeDailyReviewLimit - reviewedToday;
    return left < 0 ? 0 : left;
  }

  bool get canStudyMore => hasPremium || remainingFreeCards > 0;

  bool get isChallengeCompletedToday =>
      stores.challengeStore.value.isCompletedFor(todayKey);

  int get dueCount => _sessionBuilder
      .dueWords(words: allWords, states: states, now: clock.now(), limit: 500)
      .length;

  SessionPlan get reviewPlan => _sessionBuilder.reviewPlan(
        words: allWords,
        states: states,
        now: clock.now(),
      );

  SessionPlan get learnPlan => _sessionBuilder.learnPlan(
        words: allWords,
        states: states,
        profile: profile,
        settings: settings,
        allowPremium: hasPremium,
      );

  SessionPlan get weakPlan => _sessionBuilder.weakPlan(report: weakness);

  SessionPlan get challengePlan => _sessionBuilder.challengePlan(
        words: allWords,
        states: states,
        profile: profile,
        dayKey: todayKey,
      );

  Word? get wordOfTheDay => _sessionBuilder.wordOfTheDay(
        words: allWords,
        states: states,
        profile: profile,
        dayKey: todayKey,
      );

  /// برنامه‌ی تمرین برای مجموعه‌ای از واژه‌ها (استفاده در صفحه‌ی تمرین).
  List<QuizQuestion> buildQuiz(
    List<Word> selected, {
    QuizType? forcedType,
    int? maxQuestions,
  }) {
    final factory = QuizFactory(random: math.Random());
    if (forcedType != null) {
      return selected
          .where((word) => factory.supports(word, forcedType))
          .map((word) => factory.build(word: word, type: forcedType, pool: allWords))
          .take(maxQuestions ?? selected.length)
          .toList(growable: false);
    }
    return factory.buildSet(
      words: selected,
      pool: allWords,
      maxQuestions: maxQuestions ?? selected.length,
    );
  }

  // ------------------------------------------------------------ آنبوردینگ
  Future<void> completeOnboarding({
    required String name,
    required LearningGoal goal,
    required CefrLevel level,
    required AppSettings newSettings,
    bool placementDone = false,
    double placementScore = 0,
  }) async {
    final updated = profile.copyWith(
      name: name.trim().isEmpty ? 'دوست واژه‌یار' : name.trim(),
      goal: goal,
      level: level,
      onboarded: true,
      placementDone: placementDone,
      placementScore: placementScore,
      lastPlacementAt: placementDone ? clock.now() : null,
    );
    stores.profileStore.value = updated;
    stores.settingsStore.value = newSettings;
    haptics.enabled = newSettings.hapticsEnabled;
    await audio.setSpeedFactor(newSettings.speechSpeed);
    await progress.saveProfile(updated);
    await progress.saveSettings(newSettings);
  }

  Future<void> saveProfile(UserProfile updated) async {
    stores.profileStore.value = updated;
    await progress.saveProfile(updated);
  }

  Future<void> updateSettings(AppSettings updated) async {
    stores.settingsStore.value = updated;
    haptics.enabled = updated.hapticsEnabled;
    await audio.setSpeedFactor(updated.speechSpeed);
    await progress.saveSettings(updated);
  }

  Future<void> setThemeMode(AppThemeMode mode) =>
      updateSettings(settings.copyWith(themeMode: mode));

  /// ثبت نتیجه‌ی آزمون تعیین سطح.
  Future<void> applyPlacementResult(PlacementResult result) async {
    final updated = profile.copyWith(
      level: result.level,
      placementDone: true,
      placementScore: result.score.toDouble(),
      lastPlacementAt: clock.now(),
    );
    stores.profileStore.value = updated;
    await progress.saveProfile(updated);
  }

  // ------------------------------------------------------------- یادگیری
  /// ثبت یک واژه در برنامه‌ی یادگیری (بدون پاسخ‌دادن).
  Future<void> startWord(String wordId) async {
    final current = stores.statesStore.value;
    if (current.containsKey(wordId)) return;
    final updated = Map<String, ReviewState>.of(current)
      ..[wordId] = ReviewState(wordId: wordId, firstSeenAt: clock.now());
    stores.statesStore.value = updated;
    await progress.saveStates(updated);
  }

  /// ثبت یک مرور مبتنی بر کارت (فلش‌کارت).
  Future<LearningOutcome> reviewWordByGrade({
    required Word word,
    required ReviewGrade grade,
    int elapsedMs = 0,
  }) async {
    final now = clock.now();
    final current = stores.statesStore.value;
    final state = current[word.id] ?? ReviewState(wordId: word.id);
    final updated = _srs.apply(state: state, grade: grade, now: now);
    final isNew = state.totalReviews == 0;

    final xpAward = XpEngine.forAnswer(
      type: grade == ReviewGrade.forgot ? QuizType.meaningChoice : QuizType.fillBlank,
      isCorrect: !grade.isFailure,
      combo: stores.xpStore.value.todayCombo,
      isNewWord: isNew,
      isChallenge: false,
      level: profile.level,
      elapsedMs: elapsedMs,
    );

    return _finalizeSession(
      kind: SessionKind.review,
      attempts: <QuizAttempt>[
        QuizAttempt(
          question: QuizQuestion(
            id: 'card_${word.id}',
            type: QuizType.meaningChoice,
            word: word,
            correctAnswer: word.primaryMeaning,
          ),
          userAnswer: grade.shortLabel,
          isCorrect: !grade.isFailure,
          elapsedMs: elapsedMs,
        ),
      ],
      precomputedStates: <String, ReviewState>{word.id: updated},
      precomputedXp: xpAward.amount,
      countAsSession: false,
    );
  }

  /// ثبت نتیجه‌ی یک تمرین/جلسه.
  Future<LearningOutcome> submitAttempts({
    required SessionKind kind,
    required List<QuizAttempt> attempts,
    required DateTime startedAt,
    bool isChallenge = false,
    int bonusXp = 0,
  }) async {
    if (attempts.isEmpty) {
      return _noopOutcome();
    }
    return _finalizeSession(
      kind: kind,
      attempts: attempts,
      startedAt: startedAt,
      isChallenge: isChallenge,
      extraBonusXp: bonusXp,
    );
  }

  /// پایان یک جلسه‌ی فلش‌کارت.
  ///
  /// در جلسه‌های کارتی، SRS و امتیاز هر کارت همان لحظه ثبت می‌شود
  /// (`reviewWordByGrade`)؛ این متد فقط پرونده‌ی جلسه، زنجیره و دستاوردها
  /// را نهایی می‌کند تا آمار روزانه و دستاوردها درست به‌روز شوند.
  Future<LearningOutcome> finishSession({
    required SessionKind kind,
    required List<QuizAttempt> attempts,
    required DateTime startedAt,
    Map<String, ReviewState> appliedStates = const <String, ReviewState>{},
    bool isChallenge = false,
    int sessionXp = 0,
  }) async {
    if (attempts.isEmpty) return _noopOutcome();
    return _finalizeSession(
      kind: kind,
      attempts: attempts,
      startedAt: startedAt,
      isChallenge: isChallenge,
      precomputedStates: appliedStates,
      extraRecordedXp: sessionXp,
      recomputeStates: false,
    );
  }

  /// هسته‌ی مشترک همه‌ی جلسه‌ها: به‌روزرسانی SRS، امتیاز، زنجیره،
  /// دستاوردها، ثبت جلسه و ذخیره‌سازی.
  Future<LearningOutcome> _finalizeSession({
    required SessionKind kind,
    required List<QuizAttempt> attempts,
    DateTime? startedAt,
    bool isChallenge = false,
    int bonusXp = 0,
    bool countAsSession = true,
    Map<String, ReviewState>? precomputedStates,
    int precomputedXp = 0,
    int extraRecordedXp = 0,
    bool recomputeStates = true,
  }) async {
    final now = clock.now();
    final dayKey = clock.studyDayKey(now);
    final weekKey = clock.weekKey(now);

    final states = Map<String, ReviewState>.of(stores.statesStore.value);
    var xpState = stores.xpStore.value;
    var combo = xpState.dayKey == dayKey ? xpState.todayCombo : 0;
    var earnedXp = precomputedXp + bonusXp;
    // امتیازی که فقط برای پرونده‌ی جلسه ثبت می‌شود (در جلسه‌های کارتی،
    // امتیاز هر کارت همان لحظه به کیف اضافه شده است).
    var recordedXp = earnedXp + extraRecordedXp;
    var correct = 0;

    for (final attempt in attempts) {
      final wordId = attempt.wordId;
      if (attempt.isCorrect) correct += 1;

      // در جلسه‌های کارتی، وضعیت و امتیاز هر واژه پیش‌تر ثبت شده است.
      if (!recomputeStates) continue;

      var state = precomputedStates?[wordId] ?? states[wordId] ?? ReviewState(wordId: wordId);

      if (precomputedStates == null || !precomputedStates.containsKey(wordId)) {
        final grade = GradeMapper.fromQuiz(
          isCorrect: attempt.isCorrect,
          elapsedMs: attempt.elapsedMs,
          wasTyped: attempt.type.typed,
        );
        state = _srs.apply(state: state, grade: grade, now: now);
      }

      final errors = Map<String, int>.of(state.errorsByType);
      final corrects = Map<String, int>.of(state.correctByType);
      if (attempt.isCorrect) {
        corrects[attempt.type.name] = (corrects[attempt.type.name] ?? 0) + 1;
      } else {
        errors[attempt.type.name] = (errors[attempt.type.name] ?? 0) + 1;
      }

      final previousReviews = state.totalReviews - 1;
      final averageMs = previousReviews <= 0
          ? attempt.elapsedMs
          : ((state.averageResponseMs * previousReviews + attempt.elapsedMs) /
                  state.totalReviews)
              .round();

      state = state.copyWith(
        errorsByType: errors,
        correctByType: corrects,
        averageResponseMs: averageMs,
        note: state.note,
      );
      states[wordId] = state;

      combo = attempt.isCorrect ? combo + 1 : 0;

      if (precomputedStates == null) {
        final award = XpEngine.forAnswer(
          type: attempt.type,
          isCorrect: attempt.isCorrect,
          combo: combo,
          isNewWord: previousReviews <= 0,
          isChallenge: isChallenge,
          level: profile.level,
          elapsedMs: attempt.elapsedMs,
        );
        earnedXp += award.amount;
      }

      // نشان‌گذاری واژه‌ی در حال یادگیری (اگر تازه وارد شده باشد).
      if (state.firstSeenAt == null) {
        state = state.copyWith(firstSeenAt: now);
        states[wordId] = state;
      }
    }

    // امتیاز، کمبو و پاداش‌ها
    xpState = XpEngine.apply(
      xpState,
      earnedXp,
      dayKey: dayKey,
      weekKey: weekKey,
      combo: combo,
    );

    final goalPercentBefore = XpEngine.dailyGoalPercent(
      dailyXp: xpState.dailyXp - earnedXp,
      goalCards: settings.dailyGoalCards,
    );
    final goalPercentAfter = XpEngine.dailyGoalPercent(
      dailyXp: xpState.dailyXp,
      goalCards: settings.dailyGoalCards,
    );
    var dailyGoalReached = false;
    if (goalPercentAfter >= 100 && goalPercentBefore < 100 && xpState.dayKey != null) {
      xpState = XpEngine.apply(
        xpState,
        XpEngine.dailyGoalBonus,
        dayKey: dayKey,
        weekKey: weekKey,
        combo: combo,
      );
      earnedXp += XpEngine.dailyGoalBonus;
      recordedXp += XpEngine.dailyGoalBonus;
      dailyGoalReached = true;
    }

    // چالش روزانه
    var challengeState = stores.challengeStore.value;
    var challengeCompleted = false;
    if (isChallenge && attempts.length >= 5) {
      final sameDayStreak = challengeState.dayKey != null &&
          StreakEngine.dayGap(challengeState.dayKey!, dayKey) == 1;
      final nextStreak = sameDayStreak ? challengeState.streakDays + 1 : 1;
      challengeState = challengeState.copyWith(
        dayKey: dayKey,
        completedAt: now,
        correctCount: correct,
        totalCount: attempts.length,
        xpEarned: earnedXp,
        streakDays: nextStreak,
        bestStreak: nextStreak > challengeState.bestStreak
            ? nextStreak
            : challengeState.bestStreak,
      );
      challengeCompleted = true;
      xpState = XpEngine.apply(
        xpState,
        XpEngine.challengeBonus,
        dayKey: dayKey,
        weekKey: weekKey,
        combo: combo,
      );
      earnedXp += XpEngine.challengeBonus;
      recordedXp += XpEngine.challengeBonus;
    }

    // زنجیره‌ی مطالعه (حداقل سه پاسخ = مطالعه‌ی امروز)
    var streakState = stores.streakStore.value;
    var streakOutcome = StreakOutcome.alreadyCounted;
    if (attempts.length >= 3) {
      final result = _streak.registerDay(streakState, dayKey: dayKey);
      streakState = result.$1;
      streakOutcome = result.$2;
    }

    // ذخیره‌ی وضعیت‌ها پیش از ارزیابی دستاوردها (آمار از همین‌ها می‌آید)
    final sessions = countAsSession
        ? <StudySession>[
            ...stores.sessionsStore.value,
            StudySession(
              id: 's_${now.millisecondsSinceEpoch}',
              kind: kind,
              startedAt: startedAt ?? now,
              finishedAt: now,
              reviewedCount: attempts.length,
              correctCount: correct,
              wrongCount: attempts.length - correct,
              xpEarned: recordedXp,
              wordIds: attempts.map((a) => a.wordId).toSet().toList(growable: false),
            ),
          ]
        : stores.sessionsStore.value;

    stores.statesStore.value = states;
    stores.sessionsStore.value = sessions;
    stores.streakStore.value = streakState;
    stores.xpStore.value = xpState;
    if (challengeCompleted) stores.challengeStore.value = challengeState;

    final levelBefore = XpEngine.levelFor(xpState.totalXp - earnedXp);
    final levelAfter = XpEngine.levelFor(xpState.totalXp);

    // دستاوردها (با آمار به‌روزشده)
    final progressStats = const StatsEngine().compute(
      states: states,
      sessions: sessions,
      streak: streakState,
      now: now,
    );
    final perfectSessions = sessions
        .where((session) => session.wrongCount == 0 && session.correctCount >= 5)
        .length;
    final context = AchievementContext(
      stats: progressStats,
      totalXp: xpState.totalXp,
      levelDifficulty: profile.level.difficulty,
      challengesDone: challengeState.completedAt == null ? 0 : challengeState.streakDays,
      aiChatMessages: stores.chatStore.value.where((m) => m.isUser).length,
      perfectSessions: perfectSessions,
      listeningCorrect: _sumByType(states, QuizType.listening.name),
      typingCorrect: _sumByType(states, QuizType.typeMeaning.name) +
          _sumByType(states, QuizType.typeWord.name),
      sentenceCorrect: _sumByType(states, QuizType.sentenceBuild.name),
    );
    final update = _achievements.evaluate(
      context: context,
      existing: stores.achievementsStore.value,
      now: now,
    );
    final achievementsMap = _achievements.toMap(update.progress);
    if (update.xpReward > 0) {
      xpState = XpEngine.apply(
        xpState,
        update.xpReward,
        dayKey: dayKey,
        weekKey: weekKey,
        combo: combo,
      );
      earnedXp += update.xpReward;
      recordedXp += update.xpReward;
      stores.xpStore.value = xpState;
    }
    stores.achievementsStore.value = achievementsMap;

    // ذخیره‌سازی
    await progress.saveStates(states);
    await progress.saveXp(xpState);
    await progress.saveStreak(streakState);
    if (challengeCompleted) await progress.saveChallenge(challengeState);
    if (countAsSession) await progress.saveSessions(sessions);
    await progress.saveAchievements(achievementsMap);

    return LearningOutcome(
      xpEarned: recordedXp,
      correct: correct,
      total: attempts.length,
      leveledUp: levelAfter.index > levelBefore.index,
      level: levelAfter,
      streakOutcome: streakOutcome,
      streak: streakState,
      unlockedAchievements: update.newlyUnlocked,
      dailyGoalReached: dailyGoalReached,
      dailyGoalPercent: goalPercentAfter,
      challengeCompleted: challengeCompleted,
    );
  }

  int _sumByType(Map<String, ReviewState> states, String type) {
    var total = 0;
    for (final state in states.values) {
      total += state.correctByType[type] ?? 0;
    }
    return total;
  }

  LearningOutcome _noopOutcome() {
    final level = appLevel;
    return LearningOutcome(
      xpEarned: 0,
      correct: 0,
      total: 0,
      leveledUp: false,
      level: level,
      streakOutcome: StreakOutcome.alreadyCounted,
      streak: stores.streakStore.value,
      unlockedAchievements: const <Achievement>[],
      dailyGoalReached: false,
      dailyGoalPercent: XpEngine.dailyGoalPercent(
        dailyXp: stores.xpStore.value.dailyXp,
        goalCards: settings.dailyGoalCards,
      ),
      challengeCompleted: false,
    );
  }

  // ------------------------------------------------------------- نشان‌ها
  Future<void> toggleBookmark(String wordId) async {
    final states = Map<String, ReviewState>.of(stores.statesStore.value);
    final state = states[wordId] ?? ReviewState(wordId: wordId);
    final updated = state.copyWith(bookmarked: !state.bookmarked);
    states[wordId] = updated;
    stores.statesStore.value = states;
    haptics.tap();
    await progress.saveStates(states);
  }

  Future<void> saveWordNote(String wordId, String note) async {
    final states = Map<String, ReviewState>.of(stores.statesStore.value);
    final state = states[wordId] ?? ReviewState(wordId: wordId);
    final trimmed = note.trim();
    final updated = trimmed.isEmpty
        ? state.copyWith(clearNote: true)
        : state.copyWith(note: trimmed);
    states[wordId] = updated;
    stores.statesStore.value = states;
    await progress.saveStates(states);
  }

  /// پاک‌کردن علامت «جدید» دستاوردها هنگام بازدید.
  Future<void> markAchievementsSeen() async {
    final current = stores.achievementsStore.value;
    final cleared = _achievements.toMap(_achievements.clearNewFlags(current.values.toList()));
    stores.achievementsStore.value = cleared;
    await progress.saveAchievements(cleared);
  }

  // ---------------------------------------------------------- دستیار هوشمند
  Future<AiReply> sendChatMessage(String text, {Word? contextWord}) async {
    final message = text.trim();
    if (message.isEmpty) {
      return const AiReply(text: '');
    }
    final now = clock.now();
    final userMessage = ChatMessage(
      id: 'm_${now.microsecondsSinceEpoch}',
      author: ChatAuthor.user,
      text: message,
      createdAt: now,
      wordId: contextWord?.id,
    );
    var chat = <ChatMessage>[...stores.chatStore.value, userMessage];
    stores.chatStore.value = chat;

    final reply = await ai.ask(
      message: message,
      contextWord: contextWord,
      history: chat,
    );

    chat = <ChatMessage>[
      ...chat,
      ChatMessage(
        id: 'm_${clock.now().microsecondsSinceEpoch}_t',
        author: ChatAuthor.tutor,
        text: reply.text,
        createdAt: clock.now(),
        wordId: reply.wordId,
        suggestions: reply.suggestions,
        isFallback: true,
      ),
    ];
    stores.chatStore.value = chat;
    await progress.saveChat(chat);
    return reply;
  }

  Future<void> clearChat() async {
    stores.chatStore.value = const <ChatMessage>[];
    await progress.saveChat(const <ChatMessage>[]);
  }

  // --------------------------------------------------------------- اشتراک
  Future<PurchaseResult> startTrial() async {
    final result = await subscriptions.startTrial();
    stores.subscriptionStore.value = result.state;
    return result;
  }

  Future<PurchaseResult> purchase(SubscriptionPlan plan) async {
    final result = await subscriptions.purchase(plan);
    stores.subscriptionStore.value = result.state;
    return result;
  }

  Future<PurchaseResult> restorePurchases() async {
    final result = await subscriptions.restore();
    stores.subscriptionStore.value = result.state;
    return result;
  }

  Future<void> cancelAutoRenew() async {
    final updated = await subscriptions.cancelAutoRenew();
    stores.subscriptionStore.value = updated;
  }

  // --------------------------------------------------------------- محتوا
  Future<bool> checkContentUpdates() async {
    final updated = await words.checkForUpdates();
    if (updated) {
      final list = await words.loadWords(forceReload: true);
      final packsList = await words.loadPacks();
      stores.wordsStore.value = list;
      stores.packsStore.value = packsList;
    }
    return updated;
  }

  // ---------------------------------------------------------------- داده
  Future<String> exportData() => progress.exportJson();

  Future<void> resetProgress() async {
    await progress.resetAll();
    final now = clock.now();
    stores.profileStore.value = UserProfile.guest(now);
    stores.settingsStore.value = const AppSettings();
    stores.statesStore.value = <String, ReviewState>{};
    stores.sessionsStore.value = const <StudySession>[];
    stores.streakStore.value = const StreakState();
    stores.xpStore.value = const XpState();
    stores.challengeStore.value = const DailyChallengeState();
    stores.achievementsStore.value = <String, AchievementProgress>{};
    stores.chatStore.value = const <ChatMessage>[];
    stores.subscriptionStore.value = const SubscriptionState();
  }

  /// نوشتن فوری داده‌های معلق (هنگام رفتن اپ به پس‌زمینه).
  Future<void> persistNow() => progress.flush();

  // ------------------------------------------------------------------ صدا
  Future<void> speak(String text) => audio.speak(text, speedFactor: settings.speechSpeed);

  Future<void> stopSpeaking() => audio.stop();

  void dispose() {
    // سرویس صوتی توسط کانتینر آزاد می‌شود.
  }
}
