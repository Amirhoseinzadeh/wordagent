import 'package:flutter/foundation.dart';

import 'word.dart';

/// نوع تمرین.
enum QuizType {
  meaningChoice(faTitle: 'انتخاب معنی', baseXp: 6, typed: false),
  wordChoice(faTitle: 'انتخاب واژه', baseXp: 6, typed: false),
  fillBlank(faTitle: 'جای خالی', baseXp: 8, typed: false),
  typeMeaning(faTitle: 'نوشتن معنی', baseXp: 10, typed: true),
  typeWord(faTitle: 'نوشتن واژه', baseXp: 10, typed: true),
  listening(faTitle: 'تمرین شنیداری', baseXp: 10, typed: true),
  sentenceBuild(faTitle: 'جمله‌سازی', baseXp: 12, typed: false),
  collocation(faTitle: 'کالوکیشن', baseXp: 8, typed: false),
  synonym(faTitle: 'مترادف', baseXp: 7, typed: false),
  antonym(faTitle: 'متضاد', baseXp: 7, typed: false);

  const QuizType({
    required this.faTitle,
    required this.baseXp,
    required this.typed,
  });

  final String faTitle;
  final int baseXp;

  /// آیا پاسخ این تمرین با تایپ‌کردن داده می‌شود؟
  final bool typed;
}

/// یک سؤال تولیدشده برای تمرین/جلسه‌ی مرور.
@immutable
class QuizQuestion {
  const QuizQuestion({
    required this.id,
    required this.type,
    required this.word,
    required this.correctAnswer,
    this.prompt,
    this.instructions,
    this.choices = const <String>[],
    this.acceptedAnswers = const <String>[],
    this.audioText,
    this.tokens = const <String>[],
    this.feedbackFa,
    this.sentenceFa,
    this.usesPremiumContent = false,
  });

  final String id;
  final QuizType type;
  final Word word;

  /// متن اصلی سؤال (مثلاً جمله‌ی جای‌خالی‌دار یا معنی فارسی).
  final String? prompt;

  /// راهنمای سؤال (مثلاً «جای خالی را پر کن»).
  final String? instructions;

  /// گزینه‌ها برای انواع چندگزینه‌ای.
  final List<String> choices;

  /// پاسخ درست.
  final String correctAnswer;

  /// پاسخ‌های جایگزینی که درست شمرده می‌شوند.
  final List<String> acceptedAnswers;

  /// متنی که برای تمرین شنیداری خوانده می‌شود.
  final String? audioText;

  /// قطعه‌های جمله برای تمرین جمله‌سازی (به‌هم‌ریخته).
  final List<String> tokens;

  /// توضیح آموزشی که بعد از پاسخ نمایش داده می‌شود.
  final String? feedbackFa;

  /// ترجمه‌ی جمله‌ی سؤال (برای نمایش پس از پاسخ).
  final String? sentenceFa;

  /// آیا این سؤال به محتوای ویژه وابسته است؟
  final bool usesPremiumContent;

  bool get hasChoices => choices.isNotEmpty;

  bool get isTyped => type.typed;

  /// آیا پاسخ دادن به این سؤال نیاز به ورودی صوتی دارد؟
  bool get needsAudio => audioText != null;

  @override
  bool operator ==(Object other) => other is QuizQuestion && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'QuizQuestion(${type.name}, ${word.term})';
}

/// نتیجه‌ی پاسخ کاربر به یک سؤال.
@immutable
class QuizAttempt {
  const QuizAttempt({
    required this.question,
    required this.userAnswer,
    required this.isCorrect,
    this.elapsedMs = 0,
  });

  final QuizQuestion question;
  final String userAnswer;
  final bool isCorrect;
  final int elapsedMs;

  String get wordId => question.word.id;

  QuizType get type => question.type;
}

/// خلاصه‌ی یک تمرین.
@immutable
class QuizSummary {
  const QuizSummary({
    required this.total,
    required this.correct,
    required this.xpEarned,
    required this.attempts,
    this.perfect = false,
  });

  factory QuizSummary.fromAttempts(List<QuizAttempt> attempts, {int xpEarned = 0}) {
    final correct = attempts.where((a) => a.isCorrect).length;
    return QuizSummary(
      total: attempts.length,
      correct: correct,
      xpEarned: xpEarned,
      attempts: attempts,
      perfect: attempts.isNotEmpty && correct == attempts.length,
    );
  }

  final int total;
  final int correct;
  final int xpEarned;
  final List<QuizAttempt> attempts;
  final bool perfect;

  int get wrong => total - correct;

  double get accuracy => total == 0 ? 0 : correct / total;

  List<QuizAttempt> get mistakes =>
      attempts.where((a) => !a.isCorrect).toList(growable: false);
}
