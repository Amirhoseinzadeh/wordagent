import '../../domain/entities/cefr_level.dart';
import '../../domain/entities/part_of_speech.dart';
import '../../domain/entities/word.dart';
import 'json_utils.dart';

/// نگاشت داده‌ی محتوای واژه‌ها (JSON) به موجودیت دامنه.
///
/// قالب کوتاه فایل محتوا (برای کم‌حجم ماندن بسته‌ی اپ):
/// ```json
/// {
///   "id": "w1", "term": "resilient", "pos": "adj", "level": "c1",
///   "ipa": "/rɪˈzɪliənt/", "rank": 4211, "diff": 5,
///   "fa": ["تاب‌آور", "انعطاف‌پذیر"],
///   "def": "توانایی بازگشت به حالت اولیه پس از سختی",
///   "ex": [{"en": "...", "fa": "...", "k": "conversation"}],
///   "col": ["resilient economy"], "syn": ["tough"], "ant": ["fragile"],
///   "forms": [{"label": "قید", "value": "resiliently"}],
///   "topics": ["business"], "emoji": "🌱", "note": "...", "mnemonic": "..."
/// }
/// ```
class WordMapper {
  const WordMapper._();

  static Word fromJson(Map<String, dynamic> json, {List<String> packIds = const <String>[]}) {
    return Word(
      id: JsonUtils.asString(json['id']),
      term: JsonUtils.asString(json['term']),
      pos: PartOfSpeech.fromCode(JsonUtils.asNullableString(json['pos'])),
      level: CefrLevel.fromCode(JsonUtils.asNullableString(json['level'])),
      ipa: JsonUtils.asNullableString(json['ipa']),
      ipaUk: JsonUtils.asNullableString(json['ipa_uk']),
      frequencyRank: JsonUtils.asInt(json['rank']),
      difficulty: JsonUtils.asInt(json['diff'], fallback: 3).clamp(1, 5),
      faMeanings: JsonUtils.asStringList(json['fa']),
      faDefinition: JsonUtils.asString(json['def']),
      examples: examplesFromJson(json['ex']),
      movieLines: movieLinesFromJson(json['media']),
      collocations: JsonUtils.asStringList(json['col']),
      synonyms: JsonUtils.asStringList(json['syn']),
      antonyms: JsonUtils.asStringList(json['ant']),
      forms: formsFromJson(json['forms']),
      topics: JsonUtils.asStringList(json['topics']),
      persianNote: JsonUtils.asNullableString(json['note']),
      mnemonic: JsonUtils.asNullableString(json['mnemonic']),
      emoji: JsonUtils.asNullableString(json['emoji']),
      imageAsset: JsonUtils.asNullableString(json['image']),
      imageUrl: JsonUtils.asNullableString(json['image_url']),
      premium: JsonUtils.asBool(json['premium']),
      packIds: packIds,
    );
  }

  static List<WordExample> examplesFromJson(dynamic value) {
    final items = JsonUtils.asMapList(value);
    final result = <WordExample>[];
    for (final item in items) {
      var en = JsonUtils.asString(item['en']);
      var fa = JsonUtils.asString(item['fa']);
      if (en.isEmpty) continue;
      en = en.replaceAll('\\n', '\n');
      fa = fa.replaceAll('\\n', '\n');
      result.add(
        WordExample(
          en: en,
          fa: fa,
          kind: _kindFromCode(JsonUtils.asString(item['k'])),
          note: JsonUtils.asNullableString(item['n']),
        ),
      );
    }
    return result;
  }

  static List<MovieLine> movieLinesFromJson(dynamic value) {
    final unique = <String, MovieLine>{};
    for (final item in JsonUtils.asMapList(value)) {
      final line = JsonUtils.asString(item['line']);
      if (line.isEmpty) continue;
      final title = JsonUtils.asString(item['title'], fallback: 'دیالوگ سینمایی');
      unique['$line|$title'] = MovieLine(
        line: line,
        fa: JsonUtils.asString(item['fa']),
        sourceTitle: title,
        year: item['year'] == null ? null : JsonUtils.asInt(item['year']),
        character: JsonUtils.asNullableString(item['who']),
        clipUrl: JsonUtils.asNullableString(item['clip']),
      );
    }
    return unique.values.toList(growable: false);
  }

  static List<WordForm> formsFromJson(dynamic value) {
    final result = <WordForm>[];
    for (final item in JsonUtils.asMapList(value)) {
      final label = JsonUtils.asString(item['label']);
      final formValue = JsonUtils.asString(item['value']);
      if (label.isEmpty || formValue.isEmpty) continue;
      result.add(WordForm(label: label, value: formValue));
    }
    return result;
  }

  static ExampleKind _kindFromCode(String code) {
    switch (code.toLowerCase()) {
      case 'conv':
      case 'conversation':
      case 'c':
        return ExampleKind.conversation;
      case 'media':
      case 'movie':
      case 'm':
        return ExampleKind.media;
      case 'formal':
      case 'f':
        return ExampleKind.formal;
      default:
        return ExampleKind.general;
    }
  }

  /// نگاشت واژه به JSON (برای برون‌بری محتوا و آزمون‌ها).
  static Map<String, dynamic> toJson(Word word) => <String, dynamic>{
        'id': word.id,
        'term': word.term,
        'pos': word.pos.code,
        'level': word.level.code,
        if (word.ipa != null) 'ipa': word.ipa,
        'rank': word.frequencyRank,
        'diff': word.difficulty,
        'fa': word.faMeanings,
        'def': word.faDefinition,
        'ex': word.examples
            .map((example) => <String, dynamic>{
                  'en': example.en,
                  'fa': example.fa,
                  'k': _kindToCode(example.kind),
                })
            .toList(growable: false),
        if (word.movieLines.isNotEmpty)
          'media': word.movieLines
              .map((line) => <String, dynamic>{
                    'line': line.line,
                    'fa': line.fa,
                    'title': line.sourceTitle,
                    if (line.year != null) 'year': line.year,
                  })
              .toList(growable: false),
        if (word.collocations.isNotEmpty) 'col': word.collocations,
        if (word.synonyms.isNotEmpty) 'syn': word.synonyms,
        if (word.antonyms.isNotEmpty) 'ant': word.antonyms,
        if (word.forms.isNotEmpty)
          'forms': word.forms
              .map((form) => <String, dynamic>{'label': form.label, 'value': form.value})
              .toList(growable: false),
        if (word.topics.isNotEmpty) 'topics': word.topics,
        if (word.persianNote != null) 'note': word.persianNote,
        if (word.mnemonic != null) 'mnemonic': word.mnemonic,
        if (word.emoji != null) 'emoji': word.emoji,
        if (word.premium) 'premium': true,
      };

  static String _kindToCode(ExampleKind kind) {
    switch (kind) {
      case ExampleKind.conversation:
        return 'conv';
      case ExampleKind.media:
        return 'media';
      case ExampleKind.formal:
        return 'formal';
      case ExampleKind.general:
        return 'gen';
    }
  }
}
