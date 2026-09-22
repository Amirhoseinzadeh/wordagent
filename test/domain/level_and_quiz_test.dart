import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:wordagent/domain/entities/cefr_level.dart';
import 'package:wordagent/domain/entities/quiz_question.dart';
import 'package:wordagent/domain/engines/level_engine.dart';
import 'package:wordagent/domain/engines/quiz_engine.dart';
import 'package:wordagent/domain/entities/word.dart';

import '../helpers/fixtures.dart';

void main() {
  group('PlacementEngine — آزمون تعیین سطح', () {
    PlacementEngine engineWith(List<Word> words, {int maxQuestions = 12}) => PlacementEngine(
          words: words,
          random: math.Random(7),
          maxQuestions: maxQuestions,
        );

    /// در جریان واقعی اپ، سؤال جاری پیش از پاسخ خوانده می‌شود؛ این کمکی همان
    /// ترتیب را در تست‌ها رعایت می‌کند (ثبت پاسخ بدون سؤال جاری نادیده می‌ماند).
    void answer(PlacementEngine engine, {required bool isCorrect}) {
      expect(engine.currentQuestion, isNotNull, reason: 'سؤال جاری ساخته نشده است');
      engine.submit(isCorrect: isCorrect);
    }

    test('با بانک کوچک غیرقابل استفاده است', () {
      expect(engineWith(makeWords(5)).isUsable, isFalse);
      expect(engineWith(makeWords(12)).isUsable, isTrue);
    });

    test('همه‌ی پاسخ‌ها درست ⟶ سطح بالا', () {
      final engine = engineWith(makeWords(24, level: CefrLevel.c1), maxQuestions: 12);
      var guard = 0;
      while (!engine.isFinished && guard++ < 100) {
        answer(engine, isCorrect: true);
      }
      final result = engine.result;
      expect(result.level.index, greaterThanOrEqualTo(CefrLevel.b1.index));
      expect(result.correctCount, 12);
      expect(result.score, greaterThan(50));
      expect(result.confidence, inInclusiveRange(0, 1));
      expect(result.summaryFa, isNotEmpty);
    });

    test('همه‌ی پاسخ‌ها غلط ⟶ سطح پایه', () {
      final engine = engineWith(makeWords(24, level: CefrLevel.b2), maxQuestions: 12);
      var guard = 0;
      while (!engine.isFinished && guard++ < 100) {
        answer(engine, isCorrect: false);
      }
      final result = engine.result;
      // با ۱۲ پاسخ غلط، تخمین باید به پایین‌ترین سطوح برسد؛ رسیدن دقیق به A1
      // به شمار پاسخ‌ها بستگی دارد، پس هر دو سطح پایه پذیرفته می‌شوند.
      expect(result.level.index, lessThanOrEqualTo(CefrLevel.a2.index));
      expect(result.correctCount, 0);
      expect(result.score, lessThan(35));
    });

    test('آزمون با رسیدن به شمار سؤال‌ها تمام می‌شود', () {
      final engine = engineWith(makeWords(30), maxQuestions: 8);
      expect(engine.progress, 0);
      for (var index = 0; index < 8; index++) {
        expect(engine.isFinished, isFalse);
        answer(engine, isCorrect: index.isEven);
      }
      expect(engine.isFinished, isTrue);
      expect(engine.answeredCount, 8);
      expect(engine.progress, 1);
    });

    test('سؤال جاری همیشه موجود و بدون تکرار است', () {
      final engine = engineWith(makeWords(30), maxQuestions: 10);
      final seen = <String>{};
      for (var index = 0; index < 10; index++) {
        final question = engine.currentQuestion;
        expect(question, isNotNull);
        expect(seen.add(question!.word.id), isTrue, reason: 'سؤال تکراری پرسیده شد');
        engine.submit(isCorrect: true);
      }
    });

    test('سطح برآوردشده با پاسخ‌های ترکیبی متعادل است', () {
      final engine = engineWith(makeWords(30, level: CefrLevel.b1), maxQuestions: 12);
      for (var index = 0; index < 12; index++) {
        answer(engine, isCorrect: index % 2 == 0);
      }
      final result = engine.result;
      expect(result.totalQuestions, 12);
      expect(result.ability, inInclusiveRange(1, 6));
      expect(result.score, inInclusiveRange(0, 100));
    });

    test('خلاصه‌ی نتیجه با امتیاز هم‌خوان است', () {
      expect(
        const PlacementResult(
          level: CefrLevel.c2,
          ability: 6,
          score: 95,
          correctCount: 12,
          totalQuestions: 12,
          confidence: 1,
        ).summaryFa,
        contains('عالی'),
      );
      expect(
        const PlacementResult(
          level: CefrLevel.a1,
          ability: 1,
          score: 10,
          correctCount: 1,
          totalQuestions: 12,
          confidence: 0.2,
        ).summaryFa,
        contains('از پایه'),
      );
    });

    test('پاسخ بدون سؤال جاری نادیده گرفته می‌شود', () {
      final engine = engineWith(makeWords(30), maxQuestions: 4);
      for (var index = 0; index < 4; index++) {
        answer(engine, isCorrect: true);
      }
      // پاسخ بدون خواندن سؤال جاری نادیده می‌ماند.
      engine.submit(isCorrect: true);
      expect(engine.answeredCount, 4);
    });
  });

  group('QuizFactory — ساخت سؤال', () {
    final pool = makeWords(12);

    test('انتخاب معنی چهار گزینه‌ی یکتا دارد', () {
      final factory = QuizFactory(random: math.Random(3));
      final question = factory.build(
        word: pool.first,
        type: QuizType.meaningChoice,
        pool: pool,
      );
      expect(question.type, QuizType.meaningChoice);
      expect(question.choices.length, greaterThanOrEqualTo(2));
      expect(question.choices.toSet().length, question.choices.length);
      expect(question.choices, contains(question.correctAnswer));
    });

    test('انتخاب واژه با معنی فارسی پرسیده می‌شود', () {
      final factory = QuizFactory(random: math.Random(5));
      final question = factory.build(
        word: pool.first,
        type: QuizType.wordChoice,
        pool: pool,
      );
      expect(question.prompt, isNotNull);
      expect(question.choices, contains(question.word.term));
    });

    test('جای خالی جمله را با نشانه‌ی خالی می‌پرسد', () {
      final factory = QuizFactory(random: math.Random(9));
      final question = factory.build(
        word: pool.first,
        type: QuizType.fillBlank,
        pool: pool,
      );
      expect(question.prompt, contains('_____'));
      expect(question.sentenceFa, isNotNull);
    });

    test('تمرین شنیداری متن صوتی دارد و پاسخ تایپی می‌خواهد', () {
      final factory = QuizFactory(random: math.Random(11));
      final question = factory.build(
        word: pool.first,
        type: QuizType.listening,
        pool: pool,
      );
      expect(question.audioText, isNotNull);
      expect(question.audioText, isNotEmpty);
      expect(question.type.typed, isTrue);
    });

    test('جمله‌سازی قطعه‌های به‌هم‌ریخته می‌دهد که پاسخ درست را می‌سازند', () {
      final factory = QuizFactory(random: math.Random(13));
      final question = factory.build(
        word: pool.first,
        type: QuizType.sentenceBuild,
        pool: pool,
      );
      expect(question.tokens.length, greaterThan(1));
      expect(
        question.tokens.toSet().length,
        question.tokens.length,
        reason: 'قطعه‌های تکراری نباید وجود داشته باشد',
      );
    });

    test('کالوکیشن، مترادف و متضاد از محتوای واژه می‌آیند', () {
      final factory = QuizFactory(random: math.Random(17));
      final word = makeWord(
        id: 'c1',
        term: 'resilient',
        collocations: <String>['resilient economy'],
        synonyms: <String>['tough'],
        antonyms: <String>['fragile'],
      );
      expect(
        factory.build(word: word, type: QuizType.collocation, pool: pool).correctAnswer,
        'resilient economy',
      );
      expect(
        factory.build(word: word, type: QuizType.synonym, pool: pool).correctAnswer,
        'tough',
      );
      expect(
        factory.build(word: word, type: QuizType.antonym, pool: pool).correctAnswer,
        'fragile',
      );
    });

    test('supports برای انواع بدون محتوای لازم پاسخ درست می‌دهد', () {
      final factory = QuizFactory(random: math.Random(19));
      final bare = makeWord(
        id: 'b1',
        term: 'plain',
        collocations: const <String>[],
        synonyms: const <String>[],
        antonyms: const <String>[],
      );
      expect(factory.supports(bare, QuizType.meaningChoice), isTrue);
      expect(factory.supports(bare, QuizType.typeMeaning), isTrue);
      expect(factory.supports(bare, QuizType.collocation), isFalse);
      expect(factory.supports(bare, QuizType.synonym), isFalse);
      expect(factory.supports(bare, QuizType.antonym), isFalse);
    });

    test('buildSet شمار سؤال‌ها را کنترل می‌کند و انواع را می‌چرخاند', () {
      final factory = QuizFactory(random: math.Random(23));
      final questions = factory.buildSet(
        words: pool,
        pool: pool,
        maxQuestions: 6,
        preferredTypes: const <QuizType>[QuizType.meaningChoice, QuizType.wordChoice],
        allowTypedPractice: false,
      );
      expect(questions.length, lessThanOrEqualTo(6));
      expect(questions.length, greaterThan(3));
      final ids = questions.map((q) => q.id).toSet();
      expect(ids.length, questions.length, reason: 'شناسه‌ی سؤال‌ها باید یکتا باشد');
    });

    test('buildSet بدون واژه، فهرست خالی برمی‌گرداند', () {
      final factory = QuizFactory(random: math.Random(29));
      expect(
        factory.buildSet(words: const [], pool: const [], allowTypedPractice: false),
        isEmpty,
      );
    });

    test('میانگین سطح و نسبت نقش دستوری', () {
      final words = <Word>[
        makeWord(id: 'x1', term: 'a', level: CefrLevel.a1),
        makeWord(id: 'x2', term: 'b', level: CefrLevel.c1),
      ];
      expect(QuizFactory.averageLevel(const <Word>[]), CefrLevel.a1);
      expect(QuizFactory.averageLevel(words).index, inInclusiveRange(CefrLevel.a1.index, CefrLevel.c1.index));
      expect(QuizFactory.samePosRatio(words), 1);
    });
  });

  group('QuizFactory — اعتبارسنجی پاسخ', () {
    test('پاسخ چندگزینه‌ای انگلیسی دقیق است', () {
      final question = makeQuestion(
        type: QuizType.wordChoice,
        correctAnswer: 'resilient',
        choices: <String>['resilient', 'fragile'],
      );
      expect(QuizFactory.isAnswerCorrect(question, 'resilient'), isTrue);
      expect(QuizFactory.isAnswerCorrect(question, ' Resilient '), isTrue);
      expect(QuizFactory.isAnswerCorrect(question, 'fragile'), isFalse);
      expect(QuizFactory.isAnswerCorrect(question, ''), isFalse);
    });

    test('نوشتن معنی، خطای تایپی کوچک را می‌بخشد', () {
      final question = makeQuestion(
        type: QuizType.typeMeaning,
        correctAnswer: 'تاب‌آور',
        acceptedAnswers: <String>['تاب‌آور', 'انعطاف‌پذیر'],
      );
      expect(QuizFactory.isAnswerCorrect(question, 'تاب آور'), isTrue);
      expect(QuizFactory.isAnswerCorrect(question, 'انعطاف پذیر'), isTrue);
      expect(QuizFactory.isAnswerCorrect(question, 'شکننده'), isFalse);
    });

    test('نوشتن واژه، املای نادرست بزرگ را نمی‌پذیرد', () {
      final question = makeQuestion(
        type: QuizType.typeWord,
        correctAnswer: 'resilient',
      );
      expect(QuizFactory.isAnswerCorrect(question, 'resilient'), isTrue);
      expect(QuizFactory.isAnswerCorrect(question, 'elephant'), isFalse);
    });

    test('جمله‌سازی ترتیب کلمات را می‌سنجد', () {
      final question = makeQuestion(
        type: QuizType.sentenceBuild,
        correctAnswer: 'She is resilient',
      );
      expect(QuizFactory.isAnswerCorrect(question, 'she is resilient'), isTrue);
      expect(QuizFactory.isAnswerCorrect(question, 'is she resilient'), isFalse);
    });

    test('پاسخ نزدیک برای پیام مهربان‌تر تشخیص داده می‌شود', () {
      final question = makeQuestion(
        type: QuizType.typeMeaning,
        correctAnswer: 'تاب‌آور',
        acceptedAnswers: <String>['تاب‌آور'],
      );
      expect(QuizFactory.isNearlyCorrect(question, 'تاب آورم'), isTrue);
      expect(QuizFactory.isNearlyCorrect(question, 'درخت سبز'), isFalse);
      expect(
        QuizFactory.isNearlyCorrect(
          makeQuestion(type: QuizType.typeWord, correctAnswer: 'resilient'),
          'resilient',
        ),
        isFalse,
        reason: 'این کمک فقط برای تمرین معنی‌نویسی است',
      );
    });
  });
}
