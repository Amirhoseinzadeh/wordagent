import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:wordagent/core/services/app_services.dart';
import 'package:wordagent/core/storage/local_store_memory.dart';
import 'package:wordagent/data/repositories/progress_repository_impl.dart';
import 'package:wordagent/domain/entities/achievement.dart';
import 'package:wordagent/domain/entities/cefr_level.dart';
import 'package:wordagent/domain/entities/chat_message.dart';
import 'package:wordagent/domain/entities/progress.dart';
import 'package:wordagent/domain/entities/review_state.dart';
import 'package:wordagent/domain/entities/settings.dart';
import 'package:wordagent/domain/entities/study_session.dart';
import 'package:wordagent/domain/entities/subscription.dart';
import 'package:wordagent/domain/entities/user_profile.dart';

import '../helpers/fixtures.dart';

void main() {
  late MemoryLocalStore store;
  late ProgressRepositoryImpl repository;

  setUp(() {
    store = MemoryLocalStore();
    repository = ProgressRepositoryImpl(store, AppClock(provider: () => testNow));
  });

  group('ProgressRepositoryImpl — وضعیت خالی', () {
    test('نخستین اجرا پیش‌فرض‌های سالم می‌دهد', () async {
      final data = await repository.load();
      expect(data.profile.level, isNotNull);
      expect(data.profile.name, isNotEmpty);
      expect(data.settings.dailyNewWords, greaterThan(0));
      expect(data.states, isEmpty);
      expect(data.sessions, isEmpty);
      expect(data.streak.current, 0);
      expect(data.xp.totalXp, 0);
      expect(data.achievements, isEmpty);
      expect(data.chat, isEmpty);
      expect(data.subscription.tier, SubscriptionTier.free);
    });

    test('داده‌ی خراب در حافظه، اپ را از کار نمی‌اندازد', () async {
      await store.setString('profile', '{خراب');
      await store.setString('settings', '123');
      await store.setString('word_progress', '["نامعتبر"]');
      await store.setString('study_sessions', 'نه-فهرست-نه-نقشه');
      await store.setString('gamification', '###');
      final data = await repository.load();
      expect(data.profile.name, isNotEmpty);
      expect(data.states, isEmpty);
      expect(data.sessions, isEmpty);
      expect(data.xp.totalXp, 0);
    });
  });

  group('ProgressRepositoryImpl — ذخیره و بازیابی', () {
    test('پروفایل و تنظیمات حفظ می‌شوند', () async {
      final profile = UserProfile(
        name: 'نگار',
        goal: LearningGoal.work,
        level: CefrLevel.b2,
        createdAt: testNow.subtract(const Duration(days: 30)),
        placementDone: true,
        placementScore: 72,
      );
      const settings = AppSettings(
        dailyNewWords: 12,
        dailyGoalMinutes: 20,
        speechSpeed: 1.25,
        autoPlayAudio: true,
        remindersEnabled: true,
        reminderHour: 21,
        reminderMinute: 15,
      );
      await repository.saveProfile(profile);
      await repository.saveSettings(settings);

      final data = await repository.load();
      expect(data.profile.name, 'نگار');
      expect(data.profile.goal, LearningGoal.work);
      expect(data.profile.level, CefrLevel.b2);
      expect(data.profile.placementDone, isTrue);
      expect(data.profile.placementScore, closeTo(72, 0.001));
      expect(data.profile.createdAt, profile.createdAt);
      expect(data.settings.dailyNewWords, 12);
      expect(data.settings.reminderHour, 21);
      expect(data.settings.reminderMinute, 15);
      expect(data.settings.speechSpeed, closeTo(1.25, 0.001));
      expect(data.settings.autoPlayAudio, isTrue);
    });

    test('وضعیت مرور واژه‌ها حفظ می‌شود', () async {
      final states = <String, ReviewState>{
        'b1_001': makeState(
          wordId: 'b1_001',
          repetitions: 3,
          intervalDays: 9,
          dueAt: testNow.add(const Duration(days: 2)),
          lapses: 1,
          totalReviews: 8,
          correctReviews: 6,
          bookmarked: true,
        ),
        'b1_002': makeState(wordId: 'b1_002', totalReviews: 1, correctReviews: 1),
      };
      await repository.saveStates(states);
      final restored = (await repository.load()).states;
      expect(restored.length, 2);
      expect(restored['b1_001']!.repetitions, 3);
      expect(restored['b1_001']!.intervalDays, 9);
      expect(restored['b1_001']!.bookmarked, isTrue);
      expect(restored['b1_001']!.dueAt, states['b1_001']!.dueAt);
      expect(restored['b1_002']!.totalReviews, 1);
    });

    test('جلسه‌ها، زنجیره، امتیاز و چالش حفظ می‌شوند', () async {
      await repository.saveSessions(<StudySession>[
        makeSession(total: 10, correct: 8),
        makeSession(
          kind: SessionKind.challenge,
          total: 12,
          correct: 9,
          startedAt: testNow.subtract(const Duration(days: 1)),
        ),
      ]);
      await repository.saveStreak(
        const StreakState(
          current: 5,
          best: 9,
          lastStudyDayKey: '2026-09-22',
          totalStudyDays: 20,
          freezesAvailable: 1,
        ),
      );
      await repository.saveXp(
        XpState(
          totalXp: 320,
          dailyXp: 45,
          dayKey: '2026-09-22',
          weeklyXp: 210,
          weekKey: '2026-W39',
          bestCombo: 6,
          todayCombo: 2,
        ),
      );
      await repository.saveChallenge(
        DailyChallengeState(
          dayKey: '2026-09-22',
          completedAt: testNow,
          correctCount: 9,
          totalCount: 10,
          xpEarned: 70,
          streakDays: 2,
        ),
      );

      final data = await repository.load();
      expect(data.sessions.length, 2);
      expect(data.sessions.first.reviewedCount, 10);
      expect(data.sessions.last.kind, SessionKind.challenge);
      expect(data.streak.current, 5);
      expect(data.streak.best, 9);
      expect(data.streak.freezesAvailable, 1);
      expect(data.xp.totalXp, 320);
      expect(data.xp.weeklyXp, 210);
      expect(data.xp.bestCombo, 6);
      expect(data.challenge.correctCount, 9);
      expect(data.challenge.xpEarned, 70);
      expect(data.challenge.completedAt, testNow);
    });

    test('ذخیره‌ی امتیاز، چالش پیشین را حذف نمی‌کند', () async {
      await repository.saveChallenge(
        DailyChallengeState(dayKey: '2026-09-21', correctCount: 7, totalCount: 10),
      );
      await repository.saveXp(const XpState(totalXp: 100, dailyXp: 30));
      final data = await repository.load();
      expect(data.xp.totalXp, 100);
      expect(data.challenge.correctCount, 7);
    });

    test('دستاوردها، گفت‌وگو و اشتراک حفظ می‌شوند', () async {
      await repository.saveAchievements(<String, AchievementProgress>{
        'first_word': AchievementProgress(id: 'first_word', current: 1, unlockedAt: testNow),
        'streak_7': const AchievementProgress(id: 'streak_7', current: 4),
      });
      await repository.saveChat(<ChatMessage>[
        ChatMessage(id: 'c1', author: ChatAuthor.user, text: 'سلام', createdAt: testNow),
        ChatMessage(
          id: 'c2',
          author: ChatAuthor.tutor,
          text: 'سلام! چطور کمکت کنم؟',
          createdAt: testNow,
          wordId: 'b1_001',
        ),
      ]);
      await repository.saveSubscription(
        SubscriptionState(
          tier: SubscriptionTier.premium,
          plan: SubscriptionPlan.monthly,
          startedAt: testNow,
          expiresAt: testNow.add(const Duration(days: 30)),
          storeId: 'store_ref',
          autoRenew: true,
        ),
      );

      final data = await repository.load();
      expect(data.achievements.length, 2);
      expect(data.achievements['first_word']!.isUnlocked, isTrue);
      expect(data.achievements['streak_7']!.current, 4);
      expect(data.chat.length, 2);
      expect(data.chat.last.author, ChatAuthor.tutor);
      expect(data.chat.last.wordId, 'b1_001');
      expect(data.subscription.tier, SubscriptionTier.premium);
      expect(data.subscription.plan, SubscriptionPlan.monthly);
      expect(data.subscription.autoRenew, isTrue);
    });

    test('پیشرفت پس از بارگذاری تازه در حافظه باقی می‌ماند', () async {
      await repository.saveXp(const XpState(totalXp: 42));
      final another = ProgressRepositoryImpl(store, AppClock(provider: () => testNow));
      expect((await another.load()).xp.totalXp, 42);
    });
  });

  group('ProgressRepositoryImpl — سقف‌ها و پاک‌سازی', () {
    test('تنها ۱۸۰ جلسه‌ی آخر ذخیره می‌شود', () async {
      final sessions = <StudySession>[
        for (var index = 0; index < 200; index++)
          makeSession(
            total: 5,
            correct: 4,
            startedAt: testNow.subtract(Duration(days: index)),
          ),
      ];
      await repository.saveSessions(sessions);
      final stored = (await repository.load()).sessions;
      expect(stored.length, 180);
      expect(stored.first.startedAt, sessions[20].startedAt);
    });

    test('تنها ۱۰۰ پیام آخر گفت‌وگو ذخیره می‌شود', () async {
      final messages = <ChatMessage>[
        for (var index = 0; index < 130; index++)
          ChatMessage(
            id: 'm$index',
            author: ChatAuthor.user,
            text: 'پیام $index',
            createdAt: testNow,
          ),
      ];
      await repository.saveChat(messages);
      final stored = (await repository.load()).chat;
      expect(stored.length, 100);
      expect(stored.first.id, 'm30');
    });

    test('exportJson همه‌ی داده‌ها را برمی‌گرداند', () async {
      await repository.saveXp(const XpState(totalXp: 77));
      await repository.saveStates(<String, ReviewState>{
        'x': makeState(wordId: 'x', totalReviews: 2, correctReviews: 2),
      });
      final raw = await repository.exportJson();
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      expect(decoded['exported_at'], isNotNull);
      expect(decoded['words_started'], 1);
      final data = decoded['data'] as Map<String, dynamic>;
      expect(data.containsKey('word_progress'), isTrue);
      expect(data.containsKey('gamification'), isTrue);
    });

    test('resetAll همه‌چیز را پاک می‌کند', () async {
      await repository.saveXp(const XpState(totalXp: 900));
      await repository.saveStates(<String, ReviewState>{
        'x': makeState(wordId: 'x', totalReviews: 3, correctReviews: 3),
      });
      await repository.resetAll();

      final data = await repository.load();
      expect(data.xp.totalXp, 0);
      expect(data.states, isEmpty);
      expect(store.exportAll(), isEmpty);
    });
  });
}
