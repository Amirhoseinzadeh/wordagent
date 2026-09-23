import 'package:flutter_test/flutter_test.dart';
import 'package:wordagent/domain/engines/ai_tutor_engine.dart';
import 'package:wordagent/domain/engines/weakness_engine.dart';
import 'package:wordagent/domain/entities/cefr_level.dart';
import 'package:wordagent/domain/entities/review_state.dart';
import 'package:wordagent/domain/entities/study_session.dart';
import 'package:wordagent/domain/entities/user_profile.dart';

import '../helpers/fixtures.dart';

void main() {
  final words = makeWords(12);
  final target = words.first; // resilient

  AiTutorEngine engineWith({
    Map<String, ReviewState>? states,
    WeaknessReport? weakness,
  }) =>
      AiTutorEngine(
        words: words,
        states: states ?? <String, ReviewState>{},
        profile: UserProfile(
          name: 'آرش',
          goal: LearningGoal.work,
          level: CefrLevel.b1,
          createdAt: testNow,
          onboarded: true,
        ),
        weakness: weakness,
      );

  group('دستیار آموزشی — پیشنهادها و نیت‌ها', () {
    test('پیشنهادهای پیش‌فرض خالی و تکراری نیستند', () {
      const suggestions = AiTutorEngine.defaultSuggestions;
      expect(suggestions, isNotEmpty);
      expect(suggestions.toSet().length, suggestions.length);
      for (final suggestion in suggestions) {
        expect(suggestion.trim(), isNotEmpty);
      }
    });

    test('سلام با پاسخ احوال‌پرسی و پیشنهادها جواب می‌گیرد', () {
      final reply = engineWith().respond('سلام');
      expect(reply.kind, AiReplyKind.greeting);
      expect(reply.text, contains('آرش'));
      expect(reply.suggestions, isNotEmpty);
    });

    test('تشکر هم در دسته‌ی پاسخ‌های اجتماعی است', () {
      final reply = engineWith().respond('ممنون از راهنمایی‌ات');
      expect(reply.kind, AiReplyKind.greeting);
      expect(reply.text, isNotEmpty);
    });

    test('کوییز درخواست کاربر به بخش تمرین هدایت می‌شود', () {
      final reply = engineWith().respond('از لغت‌های امروزم کوییز بگیر');
      expect(reply.kind, AiReplyKind.quiz);
      expect(reply.text, isNotEmpty);
    });

    test('پرسش روش یادگیری، پاسخ مشاوره‌ای می‌گیرد', () {
      final reply = engineWith().respond('چطور بهتر یاد بگیرم؟');
      expect(reply.kind, AiReplyKind.advice);
      expect(reply.text, contains('B1'));
    });

    test('بدون داده‌ی ضعف، پاسخ تحلیل خالی است اما راهنما دارد', () {
      final reply = engineWith(weakness: WeaknessReport.empty())
          .respond('نقاط ضعف من کجاست؟');
      expect(reply.kind, AiReplyKind.weakness);
      expect(reply.text, isNotEmpty);
      expect(reply.suggestions, isNotEmpty);
    });

    test('پیام نامفهوم به پاسخ راهنما (unknown) می‌رسد', () {
      final reply = engineWith().respond('ژژژژ ژژ ژژژ');
      expect(reply.kind, AiReplyKind.unknown);
      expect(reply.suggestions, isNotEmpty);
    });

    test('پیام خالی هم پاسخ راهنما می‌گیرد', () {
      final reply = engineWith().respond('   ');
      expect(reply.kind, AiReplyKind.unknown);
      expect(reply.wordId, isNull);
    });
  });

  group('دستیار آموزشی — واژه‌ها', () {
    test('واژه‌ی نام‌برده‌شده در متن پیدا و معنی‌اش توضیح داده می‌شود', () {
      final reply = engineWith().respond('معنی resilient چیست؟');
      expect(reply.kind, AiReplyKind.answer);
      expect(reply.wordId, target.id);
      expect(reply.text, contains(target.term));
      expect(reply.suggestions, isNotEmpty);
    });

    test('درخواست مثال، مثال سطح‌بندی‌شده می‌سازد', () {
      final reply = engineWith().respond('برای fragile مثال بساز');
      expect(reply.kind, AiReplyKind.example);
      expect(reply.wordId, words[1].id);
      expect(reply.text, contains('B1'));
    });

    test('درخواست توضیح ساده‌تر، پاسخ simplify می‌دهد', () {
      // بدون واژه‌ی زمینه، موتور نمی‌داند «این لغت» کدام است.
      final reply = engineWith()
          .respond('این لغت را ساده‌تر توضیح بده', contextWord: target);
      expect(reply.kind, AiReplyKind.simplify);
      expect(reply.text, isNotEmpty);
    });

    test('واژه‌ی زمینه (contextWord) مسیر پاسخ را تعیین می‌کند', () {
      final reply = engineWith().respond('یعنی چه؟', contextWord: target);
      expect(reply.kind, AiReplyKind.answer);
      expect(reply.wordId, target.id);
      expect(reply.text, contains(target.term));
    });

    test('پرسش «فرق» روی واژه‌ی زمینه، پاسخ مقایسه‌ای می‌دهد', () {
      final reply = engineWith().respond('فرق این دو لغت چیست؟', contextWord: target);
      expect(reply.kind, AiReplyKind.compare);
      expect(reply.text, isNotEmpty);
    });

    test('واژه‌ی ناموجود در بانک، پاسخ راهنما می‌گیرد', () {
      final reply = engineWith().respond('معنی zzzqqq چیست؟');
      expect(reply.kind, AiReplyKind.unknown);
    });
  });

  group('دستیار آموزشی — تحلیل ضعف', () {
    test('با داده‌ی ضعف، گزارش تحلیلی ساخته می‌شود', () {
      final weakStates = <String, ReviewState>{
        for (var index = 0; index < 4; index++)
          words[index].id: makeState(
            wordId: words[index].id,
            totalReviews: 10,
            correctReviews: 3,
            lapses: 4,
            intervalDays: 1,
            dueAt: testNow.subtract(const Duration(hours: 5)),
          ),
      };
      final weakness = const WeaknessEngine().analyze(
        words: words,
        states: weakStates,
        sessions: <StudySession>[],
        now: testNow,
      );
      final reply = engineWith(states: weakStates, weakness: weakness)
          .respond('نقاط ضعف من کجاست؟');
      expect(reply.kind, AiReplyKind.weakness);
      expect(reply.text, contains('دقت'));
      expect(reply.suggestions, isNotEmpty);
    });
  });
}
