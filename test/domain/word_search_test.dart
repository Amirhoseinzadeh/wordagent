import 'package:flutter_test/flutter_test.dart';
import 'package:wordagent/domain/engines/word_search.dart';
import 'package:wordagent/domain/entities/word.dart';
import 'package:wordagent/l10n/labels.dart';

import '../helpers/fixtures.dart';

void main() {
  final words = <Word>[
    makeWord(
      id: 'w1',
      term: 'travel',
      faMeanings: const <String>['سفر کردن'],
      synonyms: const <String>['journey'],
    ).copyWith(
      forms: const <WordForm>[WordForm(label: 'گذشته', value: 'travelled')],
      topics: const <String>['travel', 'daily'],
    ),
    makeWord(
      id: 'w2',
      term: 'child',
      faMeanings: const <String>['کودک'],
      topics: const <String>['people', 'home'],
    ).copyWith(
      forms: const <WordForm>[WordForm(label: 'جمع', value: 'children')],
    ),
    makeWord(
      id: 'w3',
      term: 'resilient',
      faMeanings: const <String>['تاب‌آور'],
      topics: const <String>['feelings'],
    ),
  ];

  group('WordSearch.matches', () {
    test('با عبارت خالی همه‌ی واژه‌ها می‌خوانند', () {
      for (final word in words) {
        expect(WordSearch.matches(word, ''), isTrue);
        expect(WordSearch.matches(word, '   '), isTrue);
      }
    });

    test('جست‌وجوی انگلیسی روی خود واژه کار می‌کند', () {
      expect(WordSearch.matches(words[0], 'trav'), isTrue);
      expect(WordSearch.matches(words[0], 'TRAVEL'), isTrue);
      expect(WordSearch.matches(words[0], 'zzz'), isFalse);
    });

    test('شکل‌های صرفی هم پیدا می‌شوند', () {
      expect(WordSearch.matches(words[0], 'travelled'), isTrue);
      expect(WordSearch.matches(words[1], 'children'), isTrue);
    });

    test('هم‌معنی انگلیسی نتیجه می‌دهد', () {
      expect(WordSearch.matches(words[0], 'journey'), isTrue);
    });

    test('معنی فارسی با یکدست‌سازی «ی/ک» پیدا می‌شود', () {
      expect(WordSearch.matches(words[1], 'کودک'), isTrue);
      expect(WordSearch.matches(words[0], 'سفر'), isTrue);
      expect(WordSearch.matches(words[2], 'تاب‌آور'), isTrue);
    });

    test('موضوع با برچسب انگلیسی و نام فارسی جست‌وجو می‌شود', () {
      expect(WordSearch.matches(words[0], 'travel'), isTrue);
      expect(WordSearch.matches(words[0], 'سفر'), isTrue);
      expect(WordSearch.matches(words[2], TopicLabels.fa('feelings')), isTrue);
      expect(WordSearch.matches(words[2], 'سفر'), isFalse);
    });
  });

  group('WordSearch.filter و byTopic', () {
    test('پالایش فهرست، ترتیب را حفظ می‌کند', () {
      final result = WordSearch.filter(words, 'سفر');
      expect(result.map((word) => word.id), <String>['w1']);
    });

    test('فهرست پالایش‌شده تغییرناپذیر است', () {
      final result = WordSearch.filter(words, '');
      expect(() => result.add(words.first), throwsUnsupportedError);
    });

    test('فیلتر موضوع فقط واژه‌های همان موضوع را می‌دهد', () {
      expect(
        WordSearch.byTopic(words, 'people').map((word) => word.id),
        <String>['w2'],
      );
      expect(WordSearch.byTopic(words, null).length, words.length);
      expect(WordSearch.byTopic(words, 'ناشناخته'), isEmpty);
    });

    test('شمارش موضوع‌ها از پرتکرار به کم‌تکرار مرتب است', () {
      final counts = WordSearch.topicCounts(words);
      expect(counts.first.value, greaterThanOrEqualTo(counts.last.value));
      final total = counts.fold<int>(0, (sum, entry) => sum + entry.value);
      expect(total, 5);
    });
  });
}
