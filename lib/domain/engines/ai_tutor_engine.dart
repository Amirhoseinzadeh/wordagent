import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../../core/utils/fa_format.dart';
import '../../core/utils/text_normalizer.dart';
import '../entities/cefr_level.dart';
import '../entities/part_of_speech.dart';
import '../entities/review_state.dart';
import '../entities/user_profile.dart';
import '../entities/word.dart';
import 'weakness_engine.dart';

/// پاسخ دستیار آموزشی.
@immutable
class AiReply {
  const AiReply({
    required this.text,
    this.suggestions = const <String>[],
    this.wordId,
    this.kind = AiReplyKind.answer,
  });

  final String text;
  final List<String> suggestions;
  final String? wordId;
  final AiReplyKind kind;
}

enum AiReplyKind { answer, greeting, example, simplify, compare, quiz, weakness, advice, unknown }

/// موتور دستیار آموزشی روی دستگاه.
///
/// طراحی دو لایه دارد:
///  ۱) همین موتور محلی که با تحلیل داده‌ی واژه‌ها و پیشرفت کاربر پاسخ
///     می‌سازد (آفلاین، بدون هزینه، بدون ارسال داده‌ی کاربر به سرور)؛
///  ۲) قرارداد `AiRepository` که در فاز بک‌اند به یک مدل زبانی ابری وصل
///     می‌شود و خروجی همان ساختار را برمی‌گرداند.
class AiTutorEngine {
  AiTutorEngine({
    required List<Word> words,
    required Map<String, ReviewState> states,
    required UserProfile profile,
    WeaknessReport? weakness,
    math.Random? random,
  })  : _words = words,
        _states = states,
        _profile = profile,
        _weakness = weakness ?? WeaknessReport.empty(),
        _random = random ?? math.Random();

  final List<Word> _words;
  final Map<String, ReviewState> _states;
  final UserProfile _profile;
  final WeaknessReport _weakness;
  final math.Random _random;

  static const List<String> defaultSuggestions = <String>[
    'برای این لغت مثال بساز',
    'این لغت را ساده‌تر توضیح بده',
    'نقاط ضعف من کجاست؟',
    'از لغت‌های امروزم کوییز بگیر',
  ];

  /// پاسخ به پیام کاربر.
  AiReply respond(String message, {Word? contextWord}) {
    final text = message.trim();
    if (text.isEmpty) return _helpReply();

    if (_matches(text, const ['سلام', 'درود', 'hi', 'hello', 'hey'])) {
      return AiReply(
        text: 'سلام ${_profile.name}! 👋\n'
            'من دستیار واژه‌یار هستم. اسم یک لغت را بنویس تا معنی، مثال و نکته‌هایش '
            'را بگویم؛ یا بپرس «نقاط ضعف من کجاست؟».',
        suggestions: defaultSuggestions,
        kind: AiReplyKind.greeting,
      );
    }

    if (_matches(text, const ['ممنون', 'مرسی', 'سپاس', 'thanks', 'thank you'])) {
      return const AiReply(
        text: 'خواهش می‌کنم! هر وقت سؤالی داشتی همین‌جا بپرس. 💜',
        suggestions: <String>['یک لغت تازه یادم بده', 'کوییز بگیر'],
        kind: AiReplyKind.greeting,
      );
    }

    if (_matches(text, const ['ضعف', 'اشتباه', 'خطا', 'weakness'])) {
      return _weaknessReply();
    }

    if (_matches(text, const ['کوییز', 'آزمون', 'تمرین', 'سؤال', 'quiz'])) {
      return AiReply(
        text: 'حتماً! از بخش «تمرین» می‌توانی یک کوییز ترکیبی بگیری.\n'
            'اگر می‌خواهی روی همان لغتی که الان می‌بینی تمرکز کنیم، دکمه‌ی '
            '«تمرین همین لغت» را بزن.',
        suggestions: <String>['چالش روزانه چیست؟', 'برنامه‌ی امروزم چیست؟'],
        kind: AiReplyKind.quiz,
      );
    }

    if (_matches(text, const ['چطور', 'چگونه', 'روش', 'بهتر یاد', 'حفظ کنم'])) {
      return _adviceReply();
    }

    // مقایسه‌ی دو واژه: «فرق X و Y»
    if (_matches(text, const ['فرق', 'تفاوت', 'difference', 'vs'])) {
      final pair = _extractPair(text);
      if (pair != null) return _compareReply(pair.$1, pair.$2);
    }

    final target = _resolveWord(text, contextWord: contextWord);
    if (target != null) {
      if (_matches(text, const ['مثال', 'جمله', 'example', 'sentence'])) {
        return _exampleReply(target);
      }
      if (_matches(text, const ['ساده', 'ساده‌تر', 'راحت‌تر', 'simplify'])) {
        return _simplifyReply(target);
      }
      if (_matches(text, const ['فرق', 'تفاوت'])) {
        return _compareReply(target, null);
      }
      return _meaningReply(target);
    }

    if (contextWord != null) {
      if (_matches(text, const ['مثال', 'جمله'])) return _exampleReply(contextWord);
      if (_matches(text, const ['ساده'])) return _simplifyReply(contextWord);
      return _meaningReply(contextWord);
    }

    return _helpReply();
  }

  // ------------------------------------------------------------ پاسخ‌ها

  AiReply _meaningReply(Word word) {
    final buffer = StringBuffer();
    buffer.writeln('«${word.term}» ${word.pos.faLabel} است و به معنی:');
    for (final meaning in word.faMeanings.take(3)) {
      buffer.writeln('• $meaning');
    }
    if (word.ipa != null) buffer.writeln('تلفظ: ${word.ipa}');
    if (word.faDefinition.isNotEmpty) buffer.writeln('\n${word.faDefinition}');
    final example = _bestExample(word);
    if (example != null) {
      buffer.writeln('\nمثال:');
      buffer.writeln('“${example.en}”');
      buffer.writeln('«${example.fa}»');
    }
    if (word.collocations.isNotEmpty) {
      buffer.writeln('\nترکیب‌های رایج: ${word.collocations.take(3).join(' • ')}');
    }
    if (word.persianNote != null && word.persianNote!.isNotEmpty) {
      buffer.writeln('\nنکته برای فارسی‌زبانان: ${word.persianNote}');
    }
    return AiReply(
      text: buffer.toString().trim(),
      wordId: word.id,
      suggestions: <String>[
        'برای «${word.term}» مثال بساز',
        'مترادف‌هایش چیست؟',
        'این لغت را ساده‌تر توضیح بده',
      ],
    );
  }

  AiReply _exampleReply(Word word) {
    final generated = _generateExample(word);
    return AiReply(
      text: 'برای «${word.term}» یک مثال در سطح ${word.level.code} (${word.level.faTitle}) می‌سازم:\n\n'
          '“${generated.$1}”\n\n${generated.$2}',
      wordId: word.id,
      kind: AiReplyKind.example,
      suggestions: <String>[
        'یک مثال دیگر بساز',
        'این لغت را ساده‌تر توضیح بده',
        'مترادف‌هایش چیست؟',
      ],
    );
  }

  AiReply _simplifyReply(Word word) {
    final buffer = StringBuffer();
    buffer.writeln('به زبان ساده:');
    buffer.writeln('«${word.term}» یعنی «${word.primaryMeaning}».');
    if (word.synonyms.isNotEmpty) {
      buffer.writeln('اگر بخواهی تقریباً همین معنی را با واژه‌ی دیگری بگویی: ${word.synonyms.take(2).join('، ')}.');
    }
    if (word.antonyms.isNotEmpty) {
      buffer.writeln('نقطه‌ی مقابلش: ${word.antonyms.take(2).join('، ')}.');
    }
    final simple = word.sampleExamples.isNotEmpty
        ? word.sampleExamples.first
        : (word.examples.isNotEmpty ? word.examples.first : null);
    if (simple != null) {
      buffer.writeln('\nیک جمله‌ی کوتاه: “${simple.en}” — «${simple.fa}»');
    }
    if (word.mnemonic != null) {
      buffer.writeln('\nترفند حفظ: ${word.mnemonic}');
    }
    return AiReply(
      text: buffer.toString().trim(),
      wordId: word.id,
      kind: AiReplyKind.simplify,
      suggestions: <String>['برای این لغت مثال بساز', 'یک لغت مرتبط یادم بده'],
    );
  }

  AiReply _compareReply(Word? first, Word? second) {
    if (first == null) {
      return const AiReply(
        text: 'کدام دو واژه را مقایسه کنم؟ مثلاً بنویس: «فرق affect و effect».',
        kind: AiReplyKind.compare,
      );
    }
    if (second == null) {
      final related = _relatedWord(first);
      if (related == null) {
        return _simplifyReply(first);
      }
      second = related;
    }
    final buffer = StringBuffer();
    buffer.writeln('مقایسه‌ی «${first.term}» و «${second.term}»:');
    buffer.writeln('\n${first.term} (${first.pos.faLabel}): ${first.primaryMeaning}');
    buffer.writeln('${second.term} (${second.pos.faLabel}): ${second.primaryMeaning}');
    if (first.persianNote != null) buffer.writeln('\nنکته‌ی ${first.term}: ${first.persianNote}');
    if (second.persianNote != null) buffer.writeln('نکته‌ی ${second.term}: ${second.persianNote}');
    final exampleFirst = _bestExample(first);
    final exampleSecond = _bestExample(second);
    if (exampleFirst != null) buffer.writeln('\n«${first.term}» در جمله: “${exampleFirst.en}”');
    if (exampleSecond != null) buffer.writeln('«${second.term}» در جمله: “${exampleSecond.en}”');
    return AiReply(
      text: buffer.toString().trim(),
      wordId: first.id,
      kind: AiReplyKind.compare,
      suggestions: <String>[
        'برای «${first.term}» مثال بساز',
        'برای «${second.term}» مثال بساز',
      ],
    );
  }

  AiReply _weaknessReply() {
    if (!_weakness.hasData) {
      return const AiReply(
        text: 'هنوز داده‌ی کافی ندارم. چند تمرین انجام بده تا بتوانم نقاط ضعفت را دقیق تحلیل کنم. 📊',
        suggestions: <String>['یک کوییز بگیر', 'برنامه‌ی امروزم چیست؟'],
        kind: AiReplyKind.weakness,
      );
    }
    final buffer = StringBuffer();
    buffer.writeln('تحلیل کوتاه وضعیتت:');
    buffer.writeln('• دقت ۷ روز گذشته: ${FaFormat.percent(_weakness.recentAccuracy * 100)}');
    final area = _weakness.weakestArea;
    if (area != null) {
      buffer.writeln('• ضعیف‌ترین حوزه: ${area.label} (${FaFormat.percent(area.accuracy * 100)})');
    }
    final mistake = _weakness.mostCommonMistake;
    if (mistake != null) {
      buffer.writeln('• پرتکرارترین خطا: تمرین «$mistake»');
    }
    if (_weakness.weakWords.isNotEmpty) {
      buffer.writeln('\nسخت‌ترین واژه‌های تو:');
      for (final entry in _weakness.weakWords.take(5)) {
        buffer.writeln('• ${entry.word.term} — ${entry.reasonFa}');
      }
    }
    if (_weakness.suggestions.isNotEmpty) {
      buffer.writeln('\nپیشنهاد: ${_weakness.suggestions.first}');
    }
    return AiReply(
      text: buffer.toString().trim(),
      kind: AiReplyKind.weakness,
      suggestions: <String>['مرور نقاط ضعف را شروع کن', 'از لغت‌های امروزم کوییز بگیر'],
    );
  }

  AiReply _adviceReply() {
    final level = _profile.level;
    final buffer = StringBuffer();
    buffer.writeln('روش پیشنهادی من برای سطح ${level.code} (${level.faTitle}):');
    buffer.writeln('۱) روزی ۱۵ دقیقه، همان ساعت مشخص — مغز با نظم بهتر یاد می‌گیرد.');
    buffer.writeln('۲) واژه‌ها را در جمله یاد بگیر، نه تنها معنی؛ برای همین هر کارت مثال دارد.');
    buffer.writeln('۳) هرگز مرورهای سررسیده را عقب نینداز؛ الگوریتم ما فاصله‌ها را بر اساس فراموشی تو تنظیم می‌کند.');
    buffer.writeln('۴) خودت را با لغت‌های بسیار سخت‌تر از سطحت خسته نکن؛ ${level.next?.code ?? 'C2'} هدف بعدی توست.');
    buffer.writeln('۵) صدای لغت را بلند تکرار کن؛ تلفظ، حافظه را تقویت می‌کند.');
    return AiReply(
      text: buffer.toString().trim(),
      kind: AiReplyKind.advice,
      suggestions: <String>['برنامه‌ی امروزم چیست؟', 'نقاط ضعف من کجاست؟'],
    );
  }

  AiReply _helpReply() => AiReply(
        text: 'درباره‌ی لغت‌ها هر سؤالی داری بپرس. چند مثال از کارهایی که می‌توانم انجام دهم:',
        suggestions: defaultSuggestions,
        kind: AiReplyKind.unknown,
      );

  // ------------------------------------------------------------ کمکی‌ها

  bool _matches(String text, List<String> keywords) {
    final normalized = TextNormalizer.normalizeFa(text);
    for (final keyword in keywords) {
      if (normalized.contains(TextNormalizer.normalizeFa(keyword))) return true;
    }
    return false;
  }

  /// تلاش برای پیدا کردن واژه‌ی موردنظر کاربر در متن پیام.
  Word? _resolveWord(String text, {Word? contextWord}) {
    // ۱) تطابق دقیق واژه‌ها (با پشتیبانی از واژه‌های چندبخشی).
    final lower = text.toLowerCase();
    final byLength = List<Word>.from(_words)
      ..sort((a, b) => b.term.length.compareTo(a.term.length));
    for (final word in byLength) {
      final term = word.term.toLowerCase();
      if (term.length < 3) continue;
      final regex = RegExp('(?<![a-z])${RegExp.escape(term)}(?![a-z])');
      if (regex.hasMatch(lower)) return word;
    }

    // ۲) جست‌وجو در معنی‌های فارسی.
    final normalized = TextNormalizer.normalizeFa(text);
    for (final word in _words) {
      for (final meaning in word.faMeanings) {
        final candidate = TextNormalizer.normalizeFa(meaning);
        if (candidate.length >= 3 && normalized.contains(candidate)) return word;
      }
    }

    // ۳) اگر واژه‌ی مرجعی در گفت‌وگو بود.
    if (contextWord != null) return contextWord;
    return null;
  }

  /// استخراج دو واژه از جمله‌ی «فرق X و Y».
  (Word, Word?)? _extractPair(String text) {
    final cleaned = TextNormalizer
        .normalizeFa(text)
        .replaceAll('فرق', ' ')
        .replaceAll('تفاوت', ' ')
        .replaceAll('چیست', ' ')
        .replaceAll('است', ' ')
        .replaceAll('difference', ' ')
        .replaceAll('between', ' ');
    final parts = cleaned.split(RegExp(r'\s+و\s+|\s+با\s+|\s+and\s+|\s+vs\s+'));
    if (parts.length < 2) {
      final single = _resolveWord(text);
      return single == null ? null : (single, null);
    }
    final first = _resolveWord(parts[0]);
    final second = _resolveWord(parts[1]);
    if (first == null && second == null) return null;
    if (first == null) return (second!, null);
    return (first, second);
  }

  /// نزدیک‌ترین واژه‌ی مرتبط با یک واژه (هم‌نقش و نزدیک در معنی/موضوع).
  Word? _relatedWord(Word word) {
    if (word.synonyms.isNotEmpty) {
      final synonym = _words.firstWhere(
        (candidate) =>
            TextNormalizer.normalizeFa(candidate.term) ==
            TextNormalizer.normalizeFa(word.synonyms.first),
        orElse: () => word,
      );
      if (synonym.id != word.id) return synonym;
    }
    Word? best;
    var bestScore = 0.0;
    for (final candidate in _words) {
      if (candidate.id == word.id || candidate.pos != word.pos) continue;
      var score = 0.0;
      for (final topic in candidate.topics) {
        if (word.topics.contains(topic)) score += 1;
      }
      if (candidate.level == word.level) score += 0.5;
      if (score > bestScore) {
        bestScore = score;
        best = candidate;
      }
    }
    return bestScore > 0 ? best : null;
  }

  WordExample? _bestExample(Word word) {
    for (final example in word.examples) {
      if (example.kind == ExampleKind.conversation) return example;
    }
    if (word.examples.isNotEmpty) return word.examples.first;
    return null;
  }

  /// ساخت مثال تازه در سطح کاربر.
  ///
  /// الگوها به شکل «جمله‌ی انگلیسی||ترجمه‌ی فارسی» تعریف شده‌اند. برای افعال
  /// ترجمه‌ی ماشینی *ساخته نمی‌شود* (چون در فارسی بی‌معنی از آب درمی‌آید)؛
  /// به‌جایش توضیح می‌دهیم واژه در جمله چه معنایی دارد.
  (String, String) _generateExample(Word word) {
    final examples = word.examples;
    if (examples.isNotEmpty && _random.nextDouble() < 0.45) {
      final example = examples[_random.nextInt(examples.length)];
      return (example.en, 'ترجمه: «${example.fa}»');
    }

    final frames = _framesFor(word);
    final frame = frames[_random.nextInt(frames.length)];
    final parts = frame.split('||');
    final sentence = parts[0].replaceAll('{w}', word.term);
    if (parts.length > 1 && parts[1].contains('{m}')) {
      final persian = parts[1].replaceAll('{m}', word.primaryMeaning);
      return (sentence, 'معنی جمله: «$persian»');
    }
    return (
      sentence,
      '«${word.term}» در این جمله به معنی «${word.primaryMeaning}» است '
          '(${word.pos.faLabel} — ${word.level.code}).',
    );
  }

  /// الگوهای جمله بر اساس نقش دستوری و سطح دشواری واژه.
  List<String> _framesFor(Word word) {
    final level = word.level.difficulty;
    switch (word.pos) {
      case PartOfSpeech.noun:
        if (level <= 2) {
          return <String>[
            'This {w} is really important to me.||{m} برایم خیلی مهم است.',
            'I need to talk about the {w} with you.||باید درباره‌ی {m} با تو حرف بزنم.',
            'Where can I find a good {w}?||از کجا می‌توانم {m} خوبی پیدا کنم؟',
          ];
        }
        if (level <= 4) {
          return <String>[
            'We had a long discussion about the {w}.||درباره‌ی {m} بحث طولانی داشتیم.',
            'It turned out to be a bigger {w} than we expected.||{m} بزرگ‌تر از تصورمان بود.',
            'The report focuses on the {w} of the project.||گزارش روی {m} پروژه تمرکز دارد.',
          ];
        }
        return <String>[
          'Even after all these years, the {w} still fascinates me.||حتی بعد از این همه سال، {m} هنوز برایم جذاب است.',
          'What he said revealed a surprising {w} in his character.||حرف او {m} غافلگیرکننده‌ای در شخصیتش را نشان داد.',
        ];
      case PartOfSpeech.verb:
      case PartOfSpeech.phrasalVerb:
        if (level <= 2) {
          return <String>[
            'I usually {w} after work.',
            'She wants to {w} before the meeting starts.',
            'Do you {w} every day?',
          ];
        }
        if (level <= 4) {
          return <String>[
            'We should {w} as soon as the results arrive.',
            'He pretended to {w}, but nobody believed him.',
            'If you {w} now, it will be much easier later.',
          ];
        }
        return <String>[
          'They had to {w} under enormous pressure, which is why it took weeks.',
          'What she chose to {w} says a lot about her priorities.',
        ];
      case PartOfSpeech.adjective:
        if (level <= 2) {
          return <String>[
            'The weather today is really {w}.||هوای امروز واقعاً {m} است.',
            'This book is {w} and easy to read.||این کتاب {m} و خواندنش آسان است.',
          ];
        }
        if (level <= 4) {
          return <String>[
            'The results were {w}, so we repeated the test.||نتایج {m} بود، پس آزمون را تکرار کردیم.',
            'She gave a {w} answer that satisfied everyone.||او پاسخی {m} داد که همه را راضی کرد.',
          ];
        }
        return <String>[
          'His argument was {w} yet surprisingly convincing.||استدلالش {m} بود، اما غافلگیرکننده قانع‌کننده.',
          'The critics described the film as {w} but deeply moving.||منتقدان فیلم را {m} اما عمیقاً تأثیرگذار توصیف کردند.',
        ];
      case PartOfSpeech.adverb:
        if (level <= 2) {
          return <String>[
            'He speaks English {w}.||او انگلیسی را {m} صحبت می‌کند.',
            'She finished the work {w}.||او کار را {m} تمام کرد.',
          ];
        }
        return <String>[
          'The team responded {w}, which saved the project.||تیم {m} واکنش نشان داد و پروژه نجات پیدا کرد.',
          'She explained the theory {w} enough for beginners to follow.||او نظریه را آن‌قدر {m} توضیح داد که تازه‌کارها هم بفهمند.',
        ];
      case PartOfSpeech.idiom:
      case PartOfSpeech.phrase:
        return <String>[
          'I did not expect to hear "{w}" in that conversation.',
          'People often say "{w}" when they are under stress.',
        ];
      default:
        return <String>[
          'Here is "{w}" used in a simple sentence.',
          'Try using "{w}" in your own sentence today.',
        ];
    }
  }

  /// تعداد واژه‌های در دسترس موتور (برای نمایش وضعیت).
  int get vocabularySize => _words.length;

  /// چند واژه‌ی کاربر در وضعیت سخت‌آموز است.
  int get leechCount => _states.values.where((state) => state.status.isActive && state.lapses >= 5).length;

  CefrLevel get level => _profile.level;
}
