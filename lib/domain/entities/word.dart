import 'package:flutter/foundation.dart';

import 'cefr_level.dart';
import 'part_of_speech.dart';

/// نوع یک مثال کاربردی.
enum ExampleKind {
  /// مثال خنثی و ساده.
  general,

  /// مثال گفت‌وگویی (مکالمه‌ی روزمره).
  conversation,

  /// جمله‌ی سینمایی/سریالی.
  media,

  /// مثال رسمی یا آکادمیک.
  formal,
}

/// یک مثال انگلیسی همراه با ترجمه‌ی فارسی.
@immutable
class WordExample {
  const WordExample({
    required this.en,
    required this.fa,
    this.kind = ExampleKind.general,
    this.note,
  });

  final String en;
  final String fa;
  final ExampleKind kind;

  /// توضیح کوتاه درباره‌ی کاربرد جمله (اختیاری).
  final String? note;

  /// واژه‌های داخل جمله را پررنگ‌کردن لازم ندارد؛ رابط کاربری بر اساس
  /// خود واژه تصمیم می‌گیرد.

  @override
  bool operator ==(Object other) =>
      other is WordExample && other.en == en && other.fa == fa && other.kind == kind;

  @override
  int get hashCode => Object.hash(en, fa, kind);
}

/// جمله‌ای از فیلم/سریال (یا دیالوگی با حال‌وهوای سینمایی).
@immutable
class MovieLine {
  const MovieLine({
    required this.line,
    required this.fa,
    required this.sourceTitle,
    this.year,
    this.character,
    this.clipUrl,
  });

  final String line;
  final String fa;
  final String sourceTitle;
  final int? year;
  final String? character;

  /// نشانی کلیپ (در صورت وجود محتوای دارای مجوز؛ فعلاً خالی است).
  final String? clipUrl;

  @override
  bool operator ==(Object other) =>
      other is MovieLine && other.line == line && other.sourceTitle == sourceTitle;

  @override
  int get hashCode => Object.hash(line, sourceTitle);
}

/// شکل‌های صرفی واژه (گذشته، اسم مفعول، جمع و…).
@immutable
class WordForm {
  const WordForm({required this.label, required this.value});

  final String label;
  final String value;

  @override
  bool operator ==(Object other) =>
      other is WordForm && other.label == label && other.value == value;

  @override
  int get hashCode => Object.hash(label, value);
}

/// یک لغت کامل با تمام داده‌های آموزشی مورد نیاز فارسی‌زبانان.
@immutable
class Word {
  const Word({
    required this.id,
    required this.term,
    required this.pos,
    required this.level,
    required this.faMeanings,
    required this.faDefinition,
    this.ipa,
    this.ipaUk,
    this.frequencyRank = 0,
    this.difficulty = 3,
    this.examples = const <WordExample>[],
    this.movieLines = const <MovieLine>[],
    this.collocations = const <String>[],
    this.synonyms = const <String>[],
    this.antonyms = const <String>[],
    this.forms = const <WordForm>[],
    this.topics = const <String>[],
    this.persianNote,
    this.mnemonic,
    this.emoji,
    this.imageAsset,
    this.imageUrl,
    this.premium = false,
    this.packIds = const <String>[],
  });

  /// شناسه‌ی یکتای واژه (برای ذخیره‌ی پیشرفت پایدار).
  final String id;

  /// خودِ واژه‌ی انگلیسی.
  final String term;

  final PartOfSpeech pos;
  final CefrLevel level;

  /// تلفظ با الفبای آوانگاری بین‌المللی.
  final String? ipa;
  final String? ipaUk;

  /// رتبه‌ی کاربرد بر اساس پیکره‌ی فرکانس (۱ = پرتکرارترین‌ها، ۰ = نامعلوم).
  final int frequencyRank;

  /// دشواری ۱ تا ۵ (ترکیبی از سطح، فرکانس و پیچیدگی املایی).
  final int difficulty;

  /// معنی‌های فارسی، از رایج‌ترین به کم‌کاربردترین.
  final List<String> faMeanings;

  /// توضیح ساده‌ی فارسی درباره‌ی کاربرد واژه.
  final String faDefinition;

  final List<WordExample> examples;
  final List<MovieLine> movieLines;
  final List<String> collocations;
  final List<String> synonyms;
  final List<String> antonyms;
  final List<WordForm> forms;
  final List<String> topics;

  /// نکته‌ی مخصوص فارسی‌زبانان (حرف اضافه‌ی درست، دام ترجمه‌ی تحت‌اللفظی و…).
  final String? persianNote;

  /// ترفند حافظه‌سازی.
  final String? mnemonic;

  /// ایموجی/تصویر کوچک برای کارت واژه.
  final String? emoji;
  final String? imageAsset;
  final String? imageUrl;

  /// آیا این واژه بخشی از محتوای نسخه‌ی ویژه است؟
  final bool premium;

  /// بسته‌های موضوعی که این واژه در آن‌ها حضور دارد.
  final List<String> packIds;

  /// رایج‌ترین معنی.
  String get primaryMeaning => faMeanings.isNotEmpty ? faMeanings.first : faDefinition;

  /// معنای «فهرست‌شده» برای مقایسه‌ی پاسخ‌ها.
  List<String> get acceptableMeanings => faMeanings;

  /// مثال‌های گفت‌وگویی.
  List<WordExample> get conversationExamples =>
      examples.where((e) => e.kind == ExampleKind.conversation).toList(growable: false);

  /// مثال‌های ساده/عمومی.
  List<WordExample> get sampleExamples =>
      examples.where((e) => e.kind == ExampleKind.general).toList(growable: false);

  /// مثال‌های مناسب تمرین جای‌خالی (دارای واژه‌ی هدف در متن).
  List<WordExample> get clozeExamples => examples
      .where((e) => e.en.toLowerCase().contains(term.toLowerCase()))
      .toList(growable: false);

  Word copyWith({
    String? id,
    String? term,
    PartOfSpeech? pos,
    CefrLevel? level,
    String? ipa,
    String? ipaUk,
    int? frequencyRank,
    int? difficulty,
    List<String>? faMeanings,
    String? faDefinition,
    List<WordExample>? examples,
    List<MovieLine>? movieLines,
    List<String>? collocations,
    List<String>? synonyms,
    List<String>? antonyms,
    List<WordForm>? forms,
    List<String>? topics,
    String? persianNote,
    String? mnemonic,
    String? emoji,
    String? imageAsset,
    String? imageUrl,
    bool? premium,
    List<String>? packIds,
  }) {
    return Word(
      id: id ?? this.id,
      term: term ?? this.term,
      pos: pos ?? this.pos,
      level: level ?? this.level,
      ipa: ipa ?? this.ipa,
      ipaUk: ipaUk ?? this.ipaUk,
      frequencyRank: frequencyRank ?? this.frequencyRank,
      difficulty: difficulty ?? this.difficulty,
      faMeanings: faMeanings ?? this.faMeanings,
      faDefinition: faDefinition ?? this.faDefinition,
      examples: examples ?? this.examples,
      movieLines: movieLines ?? this.movieLines,
      collocations: collocations ?? this.collocations,
      synonyms: synonyms ?? this.synonyms,
      antonyms: antonyms ?? this.antonyms,
      forms: forms ?? this.forms,
      topics: topics ?? this.topics,
      persianNote: persianNote ?? this.persianNote,
      mnemonic: mnemonic ?? this.mnemonic,
      emoji: emoji ?? this.emoji,
      imageAsset: imageAsset ?? this.imageAsset,
      imageUrl: imageUrl ?? this.imageUrl,
      premium: premium ?? this.premium,
      packIds: packIds ?? this.packIds,
    );
  }

  /// برچسب کوتاه سطح دشواری برای نمایش.
  String get difficultyLabelFa {
    switch (difficulty) {
      case 1:
        return 'خیلی آسان';
      case 2:
        return 'آسان';
      case 3:
        return 'متوسط';
      case 4:
        return 'دشوار';
      default:
        return 'خیلی دشوار';
    }
  }

  @override
  bool operator ==(Object other) => other is Word && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Word($term)';
}
