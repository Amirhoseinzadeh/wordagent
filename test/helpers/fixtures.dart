import 'package:flutter_test/flutter_test.dart';
import 'package:wordagent/domain/entities/cefr_level.dart';
import 'package:wordagent/domain/entities/part_of_speech.dart';
import 'package:wordagent/domain/entities/quiz_question.dart';
import 'package:wordagent/domain/entities/review_state.dart';
import 'package:wordagent/domain/entities/study_session.dart';
import 'package:wordagent/domain/entities/word.dart';

/// ساعت ثابت تست‌ها؛ همه‌ی محاسبات زمانی از این‌جا عبور می‌کنند.
final DateTime testNow = DateTime(2026, 9, 22, 9);

/// یک واژه‌ی قابل‌استفاده در تست‌ها با مقادیر پیش‌فرض معقول.
Word makeWord({
  String id = 'w1',
  String term = 'resilient',
  String? ipa = '/rɪˈzɪliənt/',
  PartOfSpeech pos = PartOfSpeech.adjective,
  CefrLevel level = CefrLevel.b1,
  List<String> faMeanings = const <String>['تاب‌آور'],
  String faDefinition = 'توان بازگشت به حالت اولیه پس از سختی',
  int frequencyRank = 4211,
  int difficulty = 3,
  List<WordExample> examples = const <WordExample>[
    WordExample(
      en: 'She is resilient after every failure.',
      fa: 'او بعد از هر شکستی تاب‌آور است.',
    ),
  ],
  List<String> collocations = const <String>['resilient economy'],
  List<String> synonyms = const <String>['tough'],
  List<String> antonyms = const <String>['fragile'],
  List<String> topics = const <String>['character'],
  bool premium = false,
  List<String> packIds = const <String>[],
}) {
  return Word(
    id: id,
    term: term,
    pos: pos,
    level: level,
    ipa: ipa,
    frequencyRank: frequencyRank,
    difficulty: difficulty,
    faMeanings: faMeanings,
    faDefinition: faDefinition,
    examples: examples,
    collocations: collocations,
    synonyms: synonyms,
    antonyms: antonyms,
    topics: topics,
    premium: premium,
    packIds: packIds,
  );
}

/// واژه‌های نمونه برای تست‌ها؛ مثال هر واژه شامل خودِ واژه است تا تمرین
/// «جای خالی» و «جمله‌سازی» هم قابل ساخت باشد.
const List<String> sampleTerms = <String>[
  'resilient', 'fragile', 'diligent', 'curious', 'generous',
  'honest', 'patient', 'confident', 'ancient', 'modern',
  'efficient', 'flexible', 'reliable', 'sincere', 'vigilant',
  'courageous', 'thoughtful', 'creative', 'accurate', 'consistent',
  'ambitious', 'careful', 'cheerful', 'eloquent', 'fearless',
  'graceful', 'humble', 'insightful', 'joyful', 'kindhearted',
];

/// چند واژه‌ی پشت‌سرهم برای تست صف‌های مطالعه و تمرین.
List<Word> makeWords(int count, {CefrLevel level = CefrLevel.b1}) {
  return <Word>[
    for (var index = 0; index < count; index++)
      _sampleWord(index, level),
  ];
}

Word _sampleWord(int index, CefrLevel level) {
  final term = sampleTerms[index % sampleTerms.length];
  final unique = index < sampleTerms.length ? term : '$term$index';
  return makeWord(
    id: 'w$index',
    term: unique,
    level: level,
    frequencyRank: 100 + index,
    faMeanings: <String>['معنی $index'],
    faDefinition: 'توضیح ساده‌ی واژه‌ی $unique',
    examples: <WordExample>[
      WordExample(
        en: 'I want to be $unique today.',
        fa: 'امروز می‌خواهم $unique باشم.',
      ),
      WordExample(
        en: 'She stays $unique in hard times.',
        fa: 'او در روزهای سخت $unique می‌ماند.',
        kind: ExampleKind.conversation,
      ),
    ],
  );
}

/// وضعیت مرور یک واژه با پارامترهای دلخواه.
ReviewState makeState({
  String wordId = 'w1',
  int repetitions = 0,
  double ease = 2.5,
  double intervalDays = 0,
  DateTime? dueAt,
  int lapses = 0,
  int totalReviews = 0,
  int correctReviews = 0,
  bool bookmarked = false,
}) {
  return ReviewState(
    wordId: wordId,
    repetitions: repetitions,
    ease: ease,
    intervalDays: intervalDays,
    dueAt: dueAt,
    lapses: lapses,
    totalReviews: totalReviews,
    correctReviews: correctReviews,
    bookmarked: bookmarked,
  );
}

/// یک جلسه‌ی مطالعه‌ی ساده برای آمار و تشخیص نقاط ضعف.
StudySession makeSession({
  SessionKind kind = SessionKind.review,
  int total = 10,
  int correct = 7,
  DateTime? startedAt,
  int xp = 40,
}) {
  final start = startedAt ?? testNow.subtract(const Duration(minutes: 6));
  return StudySession(
    id: 's-${start.millisecondsSinceEpoch}',
    kind: kind,
    startedAt: start,
    finishedAt: start.add(const Duration(minutes: 5)),
    reviewedCount: total,
    correctCount: correct,
    wrongCount: total - correct,
    xpEarned: xp,
  );
}

/// یک سؤال تمرینی دستی (برای تست اعتبارسنجی پاسخ‌ها).
QuizQuestion makeQuestion({
  QuizType type = QuizType.meaningChoice,
  Word? word,
  String correctAnswer = 'تاب‌آور',
  List<String> choices = const <String>['تاب‌آور', 'شکننده', 'سریع'],
  List<String> acceptedAnswers = const <String>[],
}) {
  return QuizQuestion(
    id: 'q1',
    type: type,
    word: word ?? makeWord(),
    correctAnswer: correctAnswer,
    choices: choices,
    acceptedAnswers: acceptedAnswers,
  );
}

/// انتظار موفقیت یک محاسبه‌ی عددی با تلورانس.
void expectClose(double actual, double expected, {double tolerance = 0.0001}) {
  expect(
    (actual - expected).abs() <= tolerance,
    isTrue,
    reason: 'انتظار $expected بود اما $actual دریافت شد.',
  );
}

/// اعتبارسنجی سریع فهرست واژه‌ها (یکتا بودن شناسه و وجود معنی).
void expectValidWords(List<Word> words) {
  final ids = <String>{};
  for (final word in words) {
    expect(word.id, isNotEmpty);
    expect(ids.add(word.id), isTrue, reason: 'شناسه‌ی تکراری: ${word.id}');
    expect(word.term.trim(), isNotEmpty);
    expect(word.faMeanings, isNotEmpty, reason: 'واژه‌ی ${word.term} معنی فارسی ندارد');
  }
}
