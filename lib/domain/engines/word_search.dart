import '../../core/utils/text_normalizer.dart';
import '../../l10n/labels.dart';
import '../entities/word.dart';

/// جست‌وجو و پالایش واژه‌ها.
///
/// این منطق پیش‌تر در دو صفحه تکرار شده بود؛ این‌جا یک‌جا شده تا رفتار جست‌وجو
/// در همه‌ی صفحه‌ها یکسان باشد و موضوع‌ها هم (که پیش‌تر نادیده می‌ماندند)
/// قابل جست‌وجو شوند.
///
/// چه چیزهایی جست‌وجو می‌شوند:
///  * خود واژه‌ی انگلیسی (`resilient`)
///  * شکل‌های صرفی واژه (`ran`, `children`)
///  * معنی‌های فارسی (`تاب‌آور`)
///  * هم‌معنی انگلیسی (`tough`)
///  * موضوع واژه، هم با برچسب انگلیسی و هم با نام فارسی (`travel`, `سفر`)
abstract final class WordSearch {
  /// آیا این واژه با عبارت جست‌وجو می‌خواند؟
  static bool matches(Word word, String rawQuery) {
    final queryEn = TextNormalizer.normalizeEn(rawQuery);
    final queryFa = TextNormalizer.normalizeFa(rawQuery);
    if (queryEn.isEmpty && queryFa.isEmpty) return true;

    if (queryEn.isNotEmpty) {
      if (TextNormalizer.normalizeEn(word.term).contains(queryEn)) return true;
      for (final form in word.forms) {
        if (TextNormalizer.normalizeEn(form.value).contains(queryEn)) {
          return true;
        }
      }
      for (final synonym in word.synonyms) {
        if (TextNormalizer.normalizeEn(synonym).contains(queryEn)) return true;
      }
      for (final topic in word.topics) {
        if (TextNormalizer.normalizeEn(topic).contains(queryEn)) return true;
      }
      // تایپ فارسی اسم موضوع روی واژه‌های انگلیسی هم جواب می‌دهد.
      if (matchesTopicLabel(word, queryFa)) return true;
    }

    for (final meaning in word.faMeanings) {
      if (TextNormalizer.normalizeFa(meaning).contains(queryFa)) return true;
    }
    return false;
  }

  /// پالایش فهرست واژه‌ها با یک عبارت جست‌وجو.
  static List<Word> filter(List<Word> words, String rawQuery) {
    if (rawQuery.trim().isEmpty) return List<Word>.unmodifiable(words);
    return List<Word>.unmodifiable(
      words.where((word) => matches(word, rawQuery)),
    );
  }

  /// جست‌وجو در نام فارسی موضوع‌ها (مثلاً «سفر» → واژه‌های `travel`).
  static bool matchesTopicLabel(Word word, String normalizedFa) {
    if (normalizedFa.isEmpty) return false;
    for (final topic in word.topics) {
      final label = TextNormalizer.normalizeFa(TopicLabels.fa(topic));
      if (label.contains(normalizedFa)) return true;
    }
    return false;
  }

  /// واژه‌های یک موضوع مشخص.
  static List<Word> byTopic(List<Word> words, String? topic) {
    if (topic == null || topic.isEmpty) return List<Word>.unmodifiable(words);
    return List<Word>.unmodifiable(
      words.where((word) => word.topics.contains(topic)),
    );
  }

  /// شمار واژه‌های هر برچسب موضوعی، از پرتکرار به کم‌تکرار.
  static List<MapEntry<String, int>> topicCounts(List<Word> words) {
    final counts = <String, int>{};
    for (final word in words) {
      for (final topic in word.topics) {
        counts[topic] = (counts[topic] ?? 0) + 1;
      }
    }
    final entries = counts.entries.toList()
      ..sort((a, b) {
        final byCount = b.value.compareTo(a.value);
        if (byCount != 0) return byCount;
        return TopicLabels.fa(a.key).compareTo(TopicLabels.fa(b.key));
      });
    return List<MapEntry<String, int>>.unmodifiable(entries);
  }
}
