import 'package:flutter_test/flutter_test.dart';
import 'package:wordagent/data/mappers/progress_mapper.dart';
import 'package:wordagent/data/mappers/word_mapper.dart';
import 'package:wordagent/domain/entities/achievement.dart';
import 'package:wordagent/domain/entities/cefr_level.dart';
import 'package:wordagent/domain/entities/part_of_speech.dart';
import 'package:wordagent/domain/entities/progress.dart';
import 'package:wordagent/domain/entities/review_state.dart';
import 'package:wordagent/domain/entities/study_session.dart';
import 'package:wordagent/domain/entities/subscription.dart';
import 'package:wordagent/domain/entities/word.dart';

void main() {
  group('WordMapper — خواندن محتوا', () {
    test('همه‌ی فیلدهای واژه از JSON خوانده می‌شوند', () {
      final word = WordMapper.fromJson(<String, dynamic>{
        'id': 'b1_042',
        'term': 'resilient',
        'pos': 'adj',
        'level': 'b1',
        'ipa': '/rɪˈzɪliənt/',
        'rank': 3120,
        'diff': 4,
        'fa': <String>['تاب‌آور', 'سازگار'],
        'def': 'توان بازگشت به حالت اولیه بعد از سختی',
        'ex': <dynamic>[
          <String, dynamic>{'en': 'She is resilient.', 'fa': 'او تاب‌آور است.', 'k': 'conv'},
          <String, dynamic>{'en': 'یک جمله بدون ترجمه', 'fa': '...', 'k': 'gen'},
        ],
        'media': <dynamic>[
          <String, dynamic>{
            'line': 'Stay resilient, kid.',
            'fa': 'مقاوم باش، بچه.',
            'title': 'Rocky',
            'year': 1976,
            'who': 'Rocky',
          },
        ],
        'col': <String>['resilient economy'],
        'syn': <String>['tough'],
        'ant': <String>['fragile'],
        'forms': <dynamic>[
          <String, dynamic>{'label': 'قید', 'value': 'resiliently'},
        ],
        'topics': <String>['character', 'business'],
        'note': 'در فارسی informal کمتر استفاده می‌شود.',
        'mnemonic': 'ریزیلیانت = ریزی + لیانت',
        'emoji': '🌱',
        'premium': true,
      }, packIds: <String>['pack_character']);

      expect(word.id, 'b1_042');
      expect(word.term, 'resilient');
      expect(word.pos, PartOfSpeech.adjective);
      expect(word.level, CefrLevel.b1);
      expect(word.ipa, '/rɪˈzɪliənt/');
      expect(word.frequencyRank, 3120);
      expect(word.difficulty, 4);
      expect(word.faMeanings, <String>['تاب‌آور', 'سازگار']);
      expect(word.faDefinition, isNotEmpty);
      expect(word.examples.length, 2);
      expect(word.examples.first.kind, ExampleKind.conversation);
      expect(word.examples.last.kind, ExampleKind.general);
      expect(word.movieLines.length, 1);
      expect(word.movieLines.first.sourceTitle, 'Rocky');
      expect(word.movieLines.first.year, 1976);
      expect(word.movieLines.first.character, 'Rocky');
      expect(word.collocations, <String>['resilient economy']);
      expect(word.synonyms, <String>['tough']);
      expect(word.antonyms, <String>['fragile']);
      expect(word.forms.single.value, 'resiliently');
      expect(word.topics, <String>['character', 'business']);
      expect(word.persianNote, isNotNull);
      expect(word.mnemonic, isNotNull);
      expect(word.emoji, '🌱');
      expect(word.premium, isTrue);
      expect(word.packIds, <String>['pack_character']);
    });

    test('فیلدهای ناقص یا نامعتبر باعث خطا نمی‌شوند', () {
      final word = WordMapper.fromJson(<String, dynamic>{
        'id': 'a1_001',
        'term': 'apple',
        'diff': 99,
      });
      expect(word.term, 'apple');
      expect(word.pos, isNotNull);
      expect(word.level, isNotNull);
      expect(word.difficulty, 5, reason: 'سختی به بازه‌ی ۱ تا ۵ محدود می‌شود');
      expect(word.faMeanings, isEmpty);
      expect(word.examples, isEmpty);
      expect(word.premium, isFalse);
      expect(word.ipa, isNull);
    });

    test('مثال بدون متن انگلیسی حذف می‌شود', () {
      final examples = WordMapper.examplesFromJson(<dynamic>[
        <String, dynamic>{'en': '  ', 'fa': 'بی‌متن'},
        <String, dynamic>{'fa': 'بدون انگلیسی'},
        <String, dynamic>{'en': 'Valid one.', 'fa': 'معتبر'},
      ]);
      expect(examples.length, 1);
      expect(examples.single.en, 'Valid one.');
    });

    test('خطوط سینمایی تکراری حذف می‌شوند و عنوان پیش‌فرض دارند', () {
      final lines = WordMapper.movieLinesFromJson(<dynamic>[
        <String, dynamic>{'line': 'I will be back.', 'fa': 'برمی‌گردم.'},
        <String, dynamic>{'line': 'I will be back.', 'fa': 'برمی‌گردم.'},
        <String, dynamic>{'line': '', 'fa': 'خالی'},
      ]);
      expect(lines.length, 1);
      expect(lines.single.sourceTitle, isNotEmpty);
    });

    test('فرم‌های واژه ناقص نادیده گرفته می‌شوند', () {
      final forms = WordMapper.formsFromJson(<dynamic>[
        <String, dynamic>{'label': 'قید'},
        <String, dynamic>{'value': 'resiliently'},
        <String, dynamic>{'label': 'قید', 'value': 'resiliently'},
      ]);
      expect(forms.length, 1);
      expect(forms.single.label, 'قید');
    });

    test('رفت‌وبرگشت کامل واژه حفظ می‌شود', () {
      final original = Word(
        id: 'w9',
        term: 'resilient',
        pos: PartOfSpeech.adjective,
        level: CefrLevel.b2,
        ipa: '/rɪˈzɪliənt/',
        frequencyRank: 3120,
        difficulty: 4,
        faMeanings: const <String>['تاب‌آور'],
        faDefinition: 'توضیح',
        examples: const <WordExample>[
          WordExample(
            en: 'She is resilient.',
            fa: 'او تاب‌آور است.',
            kind: ExampleKind.conversation,
          ),
        ],
        movieLines: const <MovieLine>[
          MovieLine(line: 'Stay resilient.', fa: 'مقاوم باش.', sourceTitle: 'Rocky', year: 1976),
        ],
        collocations: const <String>['resilient economy'],
        synonyms: const <String>['tough'],
        antonyms: const <String>['fragile'],
        forms: const <WordForm>[WordForm(label: 'قید', value: 'resiliently')],
        topics: const <String>['character'],
        persianNote: 'یادداشت',
        mnemonic: 'یادیار',
        emoji: '🌱',
        premium: true,
      );
      final restored = WordMapper.fromJson(WordMapper.toJson(original));
      expect(restored.id, original.id);
      expect(restored.term, original.term);
      expect(restored.level, original.level);
      expect(restored.pos, original.pos);
      expect(restored.difficulty, original.difficulty);
      expect(restored.faMeanings, original.faMeanings);
      expect(restored.examples.length, 1);
      expect(restored.examples.single.kind, ExampleKind.conversation);
      expect(restored.movieLines.single.sourceTitle, 'Rocky');
      expect(restored.forms.single.value, 'resiliently');
      expect(restored.synonyms, original.synonyms);
      expect(restored.premium, isTrue);
    });
  });

  group('ProgressMapper — رفت‌وبرگشت وضعیت مرور', () {
    test('وضعیت مرور کامل ذخیره و بازیابی می‌شود', () {
      final state = ReviewState(
        wordId: 'b1_042',
        repetitions: 4,
        ease: 2.35,
        intervalDays: 12.5,
        dueAt: DateTime(2026, 10, 1, 8),
        lastReviewedAt: DateTime(2026, 9, 22, 9),
        firstSeenAt: DateTime(2026, 9, 1, 9),
        lapses: 2,
        totalReviews: 9,
        correctReviews: 7,
        currentStreak: 3,
        bestStreak: 4,
        bookmarked: true,
        note: 'یادداشت شخصی',
        errorsByType: const <String, int>{'meaningChoice': 2},
        correctByType: const <String, int>{'typing': 3},
        averageResponseMs: 4200,
      );
      final json = ProgressMapper.reviewStateToJson(state);
      final restored = ProgressMapper.reviewStateFromJson(json);

      expect(restored.wordId, 'b1_042');
      expect(restored.repetitions, 4);
      expect(restored.ease, closeTo(2.35, 0.001));
      expect(restored.intervalDays, closeTo(12.5, 0.001));
      expect(restored.dueAt, state.dueAt);
      expect(restored.lastReviewedAt, state.lastReviewedAt);
      expect(restored.firstSeenAt, state.firstSeenAt);
      expect(restored.lapses, 2);
      expect(restored.totalReviews, 9);
      expect(restored.correctReviews, 7);
      expect(restored.currentStreak, 3);
      expect(restored.bestStreak, 4);
      expect(restored.bookmarked, isTrue);
      expect(restored.note, 'یادداشت شخصی');
      expect(restored.errorsByType['meaningChoice'], 2);
      expect(restored.correctByType['typing'], 3);
      expect(restored.averageResponseMs, 4200);
    });

    test('فهرست وضعیت‌ها به نقشه تبدیل می‌شود و رکورد بی‌شناسه حذف می‌گردد', () {
      final states = <String, ReviewState>{
        'a': ReviewState(wordId: 'a', totalReviews: 2, correctReviews: 1),
        'b': ReviewState(wordId: 'b', totalReviews: 1, correctReviews: 1),
      };
      final restored = ProgressMapper.reviewStatesFromJson(
        ProgressMapper.reviewStatesToJson(states),
      );
      expect(restored.keys.toSet(), <String>{'a', 'b'});
      expect(ProgressMapper.reviewStatesFromJson(null), isEmpty);
      expect(
        ProgressMapper.reviewStatesFromJson(<dynamic>[
          <String, dynamic>{'total': 3},
          <String, dynamic>{'id': 'c', 'total': 3},
        ]).keys,
        <String>['c'],
      );
    });
  });

  group('ProgressMapper — زنجیره، امتیاز و چالش', () {
    test('زنجیره‌ی مطالعه', () {
      const streak = StreakState(
        current: 6,
        best: 11,
        lastStudyDayKey: '2026-09-22',
        totalStudyDays: 40,
        freezesAvailable: 2,
        freezesUsed: 1,
      );
      final restored = ProgressMapper.streakFromJson(ProgressMapper.streakToJson(streak));
      expect(restored.current, 6);
      expect(restored.best, 11);
      expect(restored.lastStudyDayKey, '2026-09-22');
      expect(restored.totalStudyDays, 40);
      expect(restored.freezesAvailable, 2);
      expect(restored.freezesUsed, 1);
    });

    test('امتیاز تجربه', () {
      final xp = XpState(
        totalXp: 5400,
        dailyXp: 120,
        dayKey: '2026-09-22',
        weeklyXp: 700,
        weekKey: '2026-W39',
        bestCombo: 14,
        todayCombo: 5,
      );
      final restored = ProgressMapper.xpFromJson(ProgressMapper.xpToJson(xp));
      expect(restored.totalXp, 5400);
      expect(restored.dailyXp, 120);
      expect(restored.dayKey, '2026-09-22');
      expect(restored.weeklyXp, 700);
      expect(restored.weekKey, '2026-W39');
      expect(restored.bestCombo, 14);
      expect(restored.todayCombo, 5);
    });

    test('چالش روزانه', () {
      final challenge = DailyChallengeState(
        dayKey: '2026-09-22',
        completedAt: DateTime(2026, 9, 22, 21, 30),
        correctCount: 9,
        totalCount: 10,
        xpEarned: 80,
        streakDays: 3,
      );
      final restored =
          ProgressMapper.challengeFromJson(ProgressMapper.challengeToJson(challenge));
      expect(restored.dayKey, '2026-09-22');
      expect(restored.completedAt, challenge.completedAt);
      expect(restored.correctCount, 9);
      expect(restored.totalCount, 10);
      expect(restored.xpEarned, 80);
      expect(restored.streakDays, 3);
    });
  });

  group('ProgressMapper — جلسه، دستاورد و اشتراک', () {
    test('جلسه‌ی مطالعه', () {
      final session = StudySession(
        id: 's1',
        kind: SessionKind.learn,
        startedAt: DateTime(2026, 9, 22, 9),
        finishedAt: DateTime(2026, 9, 22, 9, 12),
        reviewedCount: 12,
        correctCount: 10,
        wrongCount: 2,
        xpEarned: 65,
      );
      final restored = ProgressMapper.sessionFromJson(ProgressMapper.sessionToJson(session));
      expect(restored.id, 's1');
      expect(restored.kind, SessionKind.learn);
      expect(restored.startedAt, session.startedAt);
      expect(restored.finishedAt, session.finishedAt);
      expect(restored.reviewedCount, 12);
      expect(restored.correctCount, 10);
      expect(restored.wrongCount, 2);
      expect(restored.xpEarned, 65);

      final all = ProgressMapper.sessionsFromJson(
        ProgressMapper.sessionsToJson(<StudySession>[session]),
      );
      expect(all.length, 1);
      expect(ProgressMapper.sessionsFromJson('بدون داده'), isEmpty);
    });

    test('دستاوردها', () {
      final items = <String, AchievementProgress>{
        'first_word': AchievementProgress(
          id: 'first_word',
          current: 1,
          unlockedAt: DateTime(2026, 9, 1, 10),
          isNew: true,
        ),
        'xp_1000': const AchievementProgress(id: 'xp_1000', current: 640),
      };
      final restored = ProgressMapper.achievementsFromJson(
        ProgressMapper.achievementsToJson(items),
      );
      expect(restored.keys.toSet(), <String>{'first_word', 'xp_1000'});
      expect(restored['first_word']!.isUnlocked, isTrue);
      expect(restored['first_word']!.isNew, isTrue);
      expect(restored['xp_1000']!.current, 640);
      expect(restored['xp_1000']!.isUnlocked, isFalse);
    });

    test('اشتراک', () {
      final state = SubscriptionState(
        tier: SubscriptionTier.premium,
        plan: SubscriptionPlan.yearly,
        startedAt: DateTime(2026, 1, 1),
        expiresAt: DateTime(2027, 1, 1),
        storeId: 'store_1',
        autoRenew: true,
        trialUsed: true,
      );
      final restored =
          ProgressMapper.subscriptionFromJson(ProgressMapper.subscriptionToJson(state));
      expect(restored.tier, SubscriptionTier.premium);
      expect(restored.plan, SubscriptionPlan.yearly);
      expect(restored.expiresAt, state.expiresAt);
      expect(restored.autoRenew, isTrue);
      expect(restored.trialUsed, isTrue);

      final free = ProgressMapper.subscriptionFromJson(<String, dynamic>{});
      expect(free.tier, SubscriptionTier.free);
    });
  });

  group('ProgressMapper — خواندن متن خام', () {
    test('decodeMap برای متن خراب نقشه‌ی خالی می‌دهد', () {
      expect(ProgressMapper.decodeMap('{"a":1}')['a'], 1);
      expect(ProgressMapper.decodeMap('{خراب'), isEmpty);
      expect(ProgressMapper.decodeMap(null), isEmpty);
      expect(ProgressMapper.decodeMap(''), isEmpty);
    });

    test('decodeAny هم فهرست و هم نقشه را می‌فهمد', () {
      expect(ProgressMapper.decodeAny('[1,2]'), <dynamic>[1, 2]);
      expect(ProgressMapper.decodeAny(null), isNull);
    });
  });
}
