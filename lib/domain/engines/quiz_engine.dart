import 'dart:math' as math;

import '../entities/cefr_level.dart';
import '../entities/part_of_speech.dart';
import '../entities/quiz_question.dart';
import '../entities/word.dart';
import '../../core/utils/text_normalizer.dart';

/// کارخانه‌ی ساخت تمرین‌ها.
///
/// همه‌ی تمرین‌ها از داده‌ی واقعی واژه‌ها ساخته می‌شوند (مثال‌ها، کالوکیشن‌ها،
/// مترادف‌ها…) و گزینه‌های نادرست از میان واژه‌های هم‌نقش و هم‌سطح انتخاب
/// می‌شوند تا تمرین، «سنجش دانش» باشد نه «حذف گزینه‌ی بی‌ربط».
class QuizFactory {
  QuizFactory({math.Random? random}) : _random = random ?? math.Random();

  final math.Random _random;

  /// ساخت یک سؤال از واژه بر اساس نوع تمرین.
  QuizQuestion build({
    required Word word,
    required QuizType type,
    required List<Word> pool,
    int seedIndex = 0,
  }) {
    switch (type) {
      case QuizType.meaningChoice:
        return _meaningChoice(word, pool);
      case QuizType.wordChoice:
        return _wordChoice(word, pool);
      case QuizType.fillBlank:
        return _fillBlank(word, pool);
      case QuizType.typeMeaning:
        return _typeMeaning(word);
      case QuizType.typeWord:
        return _typeWord(word);
      case QuizType.listening:
        return _listening(word, pool);
      case QuizType.sentenceBuild:
        return _sentenceBuild(word);
      case QuizType.collocation:
        return _collocation(word, pool);
      case QuizType.synonym:
        return _synonym(word, pool);
      case QuizType.antonym:
        return _antonym(word, pool);
    }
  }

  /// آیا این واژه می‌تواند میزبان این نوع تمرین باشد؟
  bool supports(Word word, QuizType type) {
    switch (type) {
      case QuizType.meaningChoice:
      case QuizType.wordChoice:
      case QuizType.typeMeaning:
      case QuizType.typeWord:
      case QuizType.listening:
        return word.faMeanings.isNotEmpty;
      case QuizType.fillBlank:
        return word.clozeExamples.isNotEmpty;
      case QuizType.sentenceBuild:
        return word.examples.any((e) => TextNormalizer.tokenizeEn(e.en).length >= 4);
      case QuizType.collocation:
        return word.collocations.isNotEmpty;
      case QuizType.synonym:
        return word.synonyms.isNotEmpty;
      case QuizType.antonym:
        return word.antonyms.isNotEmpty;
    }
  }

  /// مجموعه‌ای از تمرین‌ها با تنوع کنترل‌شده.
  ///
  /// [typesPerWord] نقشه‌ی «نوع تمرین ⟶ سهم» است؛ برای هر واژه یک نوع
  /// از میان انواعی که پشتیبانی می‌شود انتخاب می‌شود (چرخشی + تصادفی)،
  /// بنابراین کاربر در یک جلسه هر بار تمرین متفاوتی می‌بیند.
  List<QuizQuestion> buildSet({
    required List<Word> words,
    required List<Word> pool,
    List<QuizType> preferredTypes = const <QuizType>[
      QuizType.meaningChoice,
      QuizType.wordChoice,
      QuizType.fillBlank,
      QuizType.listening,
      QuizType.typeMeaning,
      QuizType.collocation,
      QuizType.sentenceBuild,
      QuizType.synonym,
      QuizType.antonym,
      QuizType.typeWord,
    ],
    bool allowTypedPractice = true,
    int maxQuestions = 30,
  }) {
    final questions = <QuizQuestion>[];
    final usablePool = pool.length >= 4 ? pool : words;
    var index = 0;
    for (final word in words) {
      if (questions.length >= maxQuestions) break;
      final candidates = preferredTypes
          .where((type) => supports(word, type))
          .where((type) => allowTypedPractice || !type.typed)
          .toList(growable: false);
      if (candidates.isEmpty) continue;
      final type = candidates[index % candidates.length];
      questions.add(build(word: word, type: type, pool: usablePool, seedIndex: index));
      index += 1;
    }
    return questions;
  }

  // ------------------------------------------------------------- سازنده‌ها

  QuizQuestion _meaningChoice(Word word, List<Word> pool) {
    final distractors = _distractors(
      word,
      pool,
      (candidate) => candidate.primaryMeaning,
      count: 3,
    );
    final choices = _shuffled([word.primaryMeaning, ...distractors]);
    return QuizQuestion(
      id: 'q_${word.id}_meaning',
      type: QuizType.meaningChoice,
      word: word,
      prompt: word.term,
      instructions: 'معنی درست کدام است؟',
      choices: choices,
      correctAnswer: word.primaryMeaning,
      acceptedAnswers: word.faMeanings,
      feedbackFa: word.faDefinition,
      sentenceFa: null,
      usesPremiumContent: word.premium,
    );
  }

  QuizQuestion _wordChoice(Word word, List<Word> pool) {
    final distractors = _distractors(word, pool, (candidate) => candidate.term, count: 3);
    final choices = _shuffled([word.term, ...distractors]);
    return QuizQuestion(
      id: 'q_${word.id}_word',
      type: QuizType.wordChoice,
      word: word,
      prompt: word.primaryMeaning,
      instructions: 'کدام کلمه با این معنی هم‌خوان است؟',
      choices: choices,
      correctAnswer: word.term,
      acceptedAnswers: <String>[word.term],
      feedbackFa: word.faDefinition,
      usesPremiumContent: word.premium,
    );
  }

  QuizQuestion _fillBlank(Word word, List<Word> pool) {
    final example = word.clozeExamples.first;
    final blanked = _blankOut(example.en, word);
    final distractors = _distractors(word, pool, (candidate) => candidate.term, count: 3);
    final choices = _shuffled([word.term, ...distractors]);
    return QuizQuestion(
      id: 'q_${word.id}_blank',
      type: QuizType.fillBlank,
      word: word,
      prompt: blanked,
      instructions: 'جای خالی را پر کن',
      choices: choices,
      correctAnswer: word.term,
      acceptedAnswers: <String>[word.term],
      feedbackFa: example.fa,
      sentenceFa: example.fa,
      usesPremiumContent: word.premium,
    );
  }

  QuizQuestion _typeMeaning(Word word) {
    return QuizQuestion(
      id: 'q_${word.id}_type_meaning',
      type: QuizType.typeMeaning,
      word: word,
      prompt: word.term,
      instructions: 'معنی فارسی این لغت را بنویس',
      correctAnswer: word.primaryMeaning,
      acceptedAnswers: word.faMeanings,
      feedbackFa: word.faDefinition,
      usesPremiumContent: word.premium,
    );
  }

  QuizQuestion _typeWord(Word word) {
    return QuizQuestion(
      id: 'q_${word.id}_type_word',
      type: QuizType.typeWord,
      word: word,
      prompt: word.primaryMeaning,
      instructions: 'معادل انگلیسی این معنی را بنویس',
      correctAnswer: word.term,
      acceptedAnswers: <String>[
        word.term,
        ...word.forms.map((form) => form.value),
      ],
      feedbackFa: word.faDefinition,
      usesPremiumContent: word.premium,
    );
  }

  QuizQuestion _listening(Word word, List<Word> pool) {
    final distractors = _distractors(word, pool, (candidate) => candidate.term, count: 3);
    final choices = _shuffled([word.term, ...distractors]);
    return QuizQuestion(
      id: 'q_${word.id}_listening',
      type: QuizType.listening,
      word: word,
      audioText: word.term,
      instructions: 'چه کلمه‌ای شنیدی؟',
      choices: choices,
      correctAnswer: word.term,
      acceptedAnswers: <String>[word.term],
      feedbackFa: word.primaryMeaning,
      usesPremiumContent: word.premium,
    );
  }

  QuizQuestion _sentenceBuild(Word word) {
    final candidate = word.examples
        .firstWhere(
          (e) => TextNormalizer.tokenizeEn(e.en).length >= 4,
          orElse: () => word.examples.first,
        );
    final tokens = TextNormalizer.tokenizeEn(candidate.en);
    final correct = tokens.join(' ');
    var shuffled = List<String>.from(tokens)..shuffle(_random);
    var attempts = 0;
    while (shuffled.join(' ') == correct && attempts < 8) {
      shuffled = List<String>.from(tokens)..shuffle(_random);
      attempts += 1;
    }
    return QuizQuestion(
      id: 'q_${word.id}_sentence',
      type: QuizType.sentenceBuild,
      word: word,
      prompt: candidate.fa,
      instructions: 'جمله را مرتب کن',
      tokens: shuffled,
      correctAnswer: correct,
      acceptedAnswers: <String>[correct],
      feedbackFa: candidate.en,
      sentenceFa: candidate.fa,
      usesPremiumContent: word.premium,
    );
  }

  QuizQuestion _collocation(Word word, List<Word> pool) {
    final correct = word.collocations.first;
    final others = <String>[];
    final shuffledPool = List<Word>.from(pool)..shuffle(_random);
    for (final candidate in shuffledPool) {
      if (candidate.id == word.id || candidate.collocations.isEmpty) continue;
      others.add(candidate.collocations.first);
      if (others.length >= 3) break;
    }
    final choices = _shuffled([correct, ...others]);
    return QuizQuestion(
      id: 'q_${word.id}_collocation',
      type: QuizType.collocation,
      word: word,
      prompt: word.term,
      instructions: 'کدام ترکیب با این واژه درست است؟',
      choices: choices,
      correctAnswer: correct,
      acceptedAnswers: <String>[correct],
      feedbackFa: word.faDefinition,
      usesPremiumContent: word.premium,
    );
  }

  QuizQuestion _synonym(Word word, List<Word> pool) {
    final correct = word.synonyms.first;
    final others = _distractors(word, pool, (candidate) => candidate.term, count: 3);
    final choices = _shuffled([correct, ...others]);
    return QuizQuestion(
      id: 'q_${word.id}_synonym',
      type: QuizType.synonym,
      word: word,
      prompt: word.term,
      instructions: 'مترادف این کلمه کدام است؟',
      choices: choices,
      correctAnswer: correct,
      acceptedAnswers: <String>[correct],
      feedbackFa: word.primaryMeaning,
      usesPremiumContent: word.premium,
    );
  }

  QuizQuestion _antonym(Word word, List<Word> pool) {
    final correct = word.antonyms.first;
    final others = _distractors(word, pool, (candidate) => candidate.term, count: 3);
    final choices = _shuffled([correct, ...others]);
    return QuizQuestion(
      id: 'q_${word.id}_antonym',
      type: QuizType.antonym,
      word: word,
      prompt: word.term,
      instructions: 'متضاد این کلمه کدام است؟',
      choices: choices,
      correctAnswer: correct,
      acceptedAnswers: <String>[correct],
      feedbackFa: word.primaryMeaning,
      usesPremiumContent: word.premium,
    );
  }

  // ---------------------------------------------------------------- کمکی‌ها

  /// انتخاب گزینه‌های نادرست «هوشمندانه»: ترجیح هم‌نقش و هم‌سطح.
  List<String> _distractors(
    Word word,
    List<Word> pool,
    String Function(Word) selector, {
    required int count,
  }) {
    final correctValue = selector(word);
    final samePos = <Word>[];
    final sameLevel = <Word>[];
    final others = <Word>[];

    for (final candidate in pool) {
      if (candidate.id == word.id) continue;
      final value = selector(candidate);
      if (value.trim().isEmpty || value.trim() == correctValue.trim()) continue;
      if (candidate.pos == word.pos && candidate.level == word.level) {
        samePos.add(candidate);
      } else if (candidate.level == word.level || candidate.pos == word.pos) {
        sameLevel.add(candidate);
      } else {
        others.add(candidate);
      }
    }

    samePos.shuffle(_random);
    sameLevel.shuffle(_random);
    others.shuffle(_random);

    final picked = <String>[];
    void take(List<Word> source) {
      for (final candidate in source) {
        if (picked.length >= count) return;
        final value = selector(candidate);
        if (picked.contains(value)) continue;
        picked.add(value);
      }
    }

    take(samePos);
    take(sameLevel);
    take(others);
    return picked;
  }

  /// جایگزینی واژه در جمله با جای خالی.
  String _blankOut(String sentence, Word word) {
    final patterns = <String>[
      word.term,
      ...word.forms.map((form) => form.value),
    ];
    for (final pattern in patterns) {
      final regex = RegExp(
        '(?<![A-Za-z])${RegExp.escape(pattern)}(?![A-Za-z])',
        caseSensitive: false,
      );
      if (regex.hasMatch(sentence)) {
        return sentence.replaceFirst(regex, '_____');
      }
    }
    final fallback = sentence.replaceFirst(
      RegExp(RegExp.escape(word.term), caseSensitive: false),
      '_____',
    );
    return fallback;
  }

  /// برهم‌زدن گزینه‌ها (با حفظ یکتا بودن).
  List<String> _shuffled(List<String> values) {
    final unique = <String>[];
    for (final value in values) {
      final trimmed = value.trim();
      if (trimmed.isEmpty || unique.contains(trimmed)) continue;
      unique.add(trimmed);
    }
    unique.shuffle(_random);
    return unique;
  }

  /// اعتبارسنجی پاسخ کاربر برای انواع مختلف تمرین.
  static bool isAnswerCorrect(
    QuizQuestion question,
    String userAnswer, {
    double tolerance = 0.85,
  }) {
    final normalizedUser = userAnswer.trim();
    if (normalizedUser.isEmpty) return false;

    switch (question.type) {
      case QuizType.sentenceBuild:
        return TextNormalizer.sameWordOrder(
          TextNormalizer.tokenizeEn(normalizedUser),
          TextNormalizer.tokenizeEn(question.correctAnswer),
        );
      case QuizType.typeMeaning:
        return TextNormalizer.matchesFa(
          normalizedUser,
          question.acceptedAnswers.isEmpty
              ? <String>[question.correctAnswer]
              : question.acceptedAnswers,
          threshold: tolerance,
        );
      case QuizType.typeWord:
      case QuizType.listening:
        return TextNormalizer.matchesEn(
          normalizedUser,
          question.acceptedAnswers.isEmpty
              ? <String>[question.correctAnswer]
              : question.acceptedAnswers,
        );
      case QuizType.meaningChoice:
        return TextNormalizer.matchesFa(
          normalizedUser,
          <String>[question.correctAnswer],
          threshold: 0.99,
        );
      case QuizType.wordChoice:
      case QuizType.fillBlank:
      case QuizType.collocation:
      case QuizType.synonym:
      case QuizType.antonym:
        return TextNormalizer.normalizeEn(normalizedUser) ==
            TextNormalizer.normalizeEn(question.correctAnswer);
    }
  }

  /// بررسی «نزدیک به پاسخ» برای دادن بازخورد مهربان‌تر.
  static bool isNearlyCorrect(QuizQuestion question, String userAnswer) {
    if (question.type != QuizType.typeMeaning) return false;
    final accepted = question.acceptedAnswers.isEmpty
        ? <String>[question.correctAnswer]
        : question.acceptedAnswers;
    final normalizedUser = TextNormalizer.normalizeFa(userAnswer);
    for (final value in accepted) {
      for (final variant in TextNormalizer.expandVariants(value)) {
        if (variant.length < 3) continue;
        if (TextNormalizer.similarity(normalizedUser, variant) >= 0.65) return true;
      }
    }
    return false;
  }

  /// میانگین دشواری مجموعه‌ای از واژه‌ها (برای برچسب جلسه).
  static CefrLevel averageLevel(List<Word> words) {
    if (words.isEmpty) return CefrLevel.a1;
    var total = 0;
    for (final word in words) {
      total += word.level.difficulty;
    }
    return CefrLevel.fromDifficulty(total / words.length);
  }

  /// آیا واژه در فهرست بسته‌های ویژه است؟
  static bool isPremiumOnly(Word word) => word.premium;

  /// نسبت واژه‌های هم‌نقش در یک مجموعه (برای گزارش کیفیت تمرین).
  static double samePosRatio(List<Word> words) {
    if (words.length < 2) return 1;
    final counts = <PartOfSpeech, int>{};
    for (final word in words) {
      counts[word.pos] = (counts[word.pos] ?? 0) + 1;
    }
    final max = counts.values.reduce(math.max);
    return max / words.length;
  }
}
