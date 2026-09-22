import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wordagent/core/storage/local_store_memory.dart';
import 'package:wordagent/data/sources/content_source.dart';
import 'package:wordagent/domain/entities/user_profile.dart';
import 'package:wordagent/domain/entities/word.dart';
import 'package:wordagent/l10n/labels.dart';

/// پاسخ‌دهی بسته‌ی دارایی‌ها از فایل‌های واقعی مخزن؛ پس این تست‌ها همان
/// داده‌ای را می‌سنجند که اپ در دست کاربر می‌خواند.
void _serveRealAssets() {
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  messenger.setMockMessageHandler('flutter/assets', (message) async {
    final key = utf8.decode(message!.buffer.asUint8List());
    final file = File(key);
    if (!file.existsSync()) return null;
    return ByteData.sublistView(Uint8List.fromList(file.readAsBytesSync()));
  });
}

/// برچسب‌های صرفی مجاز؛ اگر بیلدر برچسب تازه‌ای اضافه کند، این تست
/// یادآوری می‌کند که نمایش آن در رابط کاربری هم باید بررسی شود.
const Set<String> allowedFormLabels = <String>{
  'جمع',
  'گذشته',
  'اسم مفعول',
  'حال استمراری',
  'سوم‌شخص مفرد',
  'برتر',
  'برترین',
};

List<String> _valuesOf(Word word, String label) => word.forms
    .where((form) => form.label == label)
    .map((form) => form.value)
    .toList(growable: false);

Word _word(ContentBundle bundle, String term) =>
    bundle.words.firstWhere((word) => word.term == term);

/// آیا این ترکیب، خودِ واژه را در بر دارد؟
///
/// همان سنجشی که موتور تمرین برای انتخاب پاسخ درست کالوکیشن به کار می‌برد
/// (`contains`): پس «bedroom» برای «room»، «go swimming» برای «swim» و
/// «the storm abates» برای «abate» هم پذیرفته می‌شوند.
bool _containsTerm(String phrase, String term) =>
    phrase.toLowerCase().contains(term.toLowerCase());

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ContentBundle bundle;

  setUpAll(() async {
    _serveRealAssets();
    bundle = await ContentSource(MemoryLocalStore()).load(preferLocal: false);
  });

  group('برچسب موضوعی محتوا', () {
    test('همه‌ی واژه‌ها دست‌کم یک برچسب موضوعی دارند', () {
      expect(bundle.words.length, greaterThan(800));
      final untagged = bundle.words
          .where((word) => word.topics.isEmpty)
          .map((word) => word.id)
          .toList(growable: false);
      expect(untagged, isEmpty, reason: 'واژه‌های بدون برچسب: $untagged');
    });

    test('هیچ برچسب ناشناخته‌ای در محتوا نیست', () {
      final unknown = <String>{};
      for (final word in bundle.words) {
        for (final topic in word.topics) {
          if (!TopicLabels.isKnown(topic)) unknown.add(topic);
        }
      }
      expect(
        unknown,
        isEmpty,
        reason: 'برچسب‌های بی‌برچسب فارسی در محتوا: $unknown',
      );
    });

    test('هر برچسب فارسیِ خوانا دارد و متن خام نمایش داده نمی‌شود', () {
      for (final tag in TopicLabels.tags) {
        expect(TopicLabels.fa(tag), isNot(tag), reason: 'برچسب بی‌ترجمه: $tag');
        expect(TopicLabels.fa(tag).trim(), isNotEmpty);
      }
    });

    test('برچسب‌ها بین واژه‌ها پخش شده‌اند (تحلیل موضوعی معنا دارد)', () {
      final counts = <String, int>{};
      for (final word in bundle.words) {
        for (final topic in word.topics) {
          counts[topic] = (counts[topic] ?? 0) + 1;
        }
      }
      expect(counts.length, greaterThanOrEqualTo(15));
      // هیچ برچسبی نباید آن‌قدر کم‌واژه باشد که تحلیل ضعف بی‌معنی شود.
      final thin = counts.entries.where((entry) => entry.value < 8).toList();
      expect(thin, isEmpty, reason: 'برچسب‌های کم‌واژه: $thin');
    });

    test('هدف یادگیری کاربر با محتوا هم‌راستا است', () {
      for (final goal in LearningGoal.values) {
        for (final topic in goal.topics) {
          expect(
            TopicLabels.isKnown(topic),
            isTrue,
            reason: 'هدف ${goal.faTitle} برچسب ناشناخته دارد: $topic',
          );
        }
        final matching = bundle.words
            .where((word) => word.topics.any(goal.topics.contains))
            .length;
        expect(
          matching,
          greaterThanOrEqualTo(30),
          reason: 'هدف ${goal.faTitle} فقط $matching واژه‌ی هم‌موضوع دارد',
        );
      }
    });
  });

  group('شکل‌های صرفی واژه', () {
    test('نسبت بالایی از واژه‌های محتوایی شکل صرفی دارند', () {
      final contentWords = bundle.words
          .where((word) => const <String>{'n', 'v', 'adj'}
              .contains(word.pos.code))
          .toList(growable: false);
      final withForms =
          contentWords.where((word) => word.forms.isNotEmpty).length;
      expect(contentWords, isNotEmpty);
      expect(
        withForms / contentWords.length,
        greaterThan(0.8),
        reason: 'فقط $withForms از ${contentWords.length} واژه شکل دارد',
      );
    });

    test('برچسب‌ها و مقدارها درست و بی‌تکرارند', () {
      for (final word in bundle.words) {
        final seen = <String>{word.term.toLowerCase()};
        for (final form in word.forms) {
          expect(allowedFormLabels, contains(form.label),
              reason: 'برچسب ناشناخته در ${word.term}: ${form.label}');
          expect(form.value.trim(), isNotEmpty,
              reason: 'مقدار خالی در ${word.term}');
          expect(RegExp(r'^[A-Za-z][A-Za-z ]*$').hasMatch(form.value), isTrue,
              reason: 'مقدار غیرانگلیسی در ${word.term}: ${form.value}');
          expect(seen.add(form.value.toLowerCase()), isTrue,
              reason: 'شکل تکراری در ${word.term}: ${form.value}');
        }
      }
    });

    test('نقش هر بخش دستوری شکل درست خودش را دارد', () {
      for (final word in bundle.words) {
        switch (word.pos.code) {
          case 'v':
            expect(_valuesOf(word, 'حال استمراری'), hasLength(1),
                reason: 'فعل بدون حال استمراری: ${word.term}');
            expect(_valuesOf(word, 'سوم‌شخص مفرد'), hasLength(1),
                reason: 'فعل بدون سوم‌شخص: ${word.term}');
          case 'n':
            for (final form in word.forms) {
              expect(form.label, 'جمع', reason: 'اسم با برچسب ${form.label}');
            }
          case 'adj':
            for (final form in word.forms) {
              expect(const <String>{'برتر', 'برترین'}, contains(form.label),
                  reason: 'صفت با برچسب ${form.label}');
            }
        }
      }
    });

    test('صرف فعل‌های قاعده‌ای و بی‌قاعده درست ساخته می‌شود', () {
      const expected = <String, List<String>>{
        'run': <String>['ran', 'running', 'runs'],
        'stop': <String>['stopped', 'stopping', 'stops'],
        'swim': <String>['swam', 'swum', 'swimming', 'swims'],
        'study': <String>['studied', 'studying', 'studies'],
        'apply': <String>['applied', 'applying', 'applies'],
        'get': <String>['got', 'getting', 'gets'],
        'forbid': <String>['forbade', 'forbidden', 'forbidding', 'forbids'],
        'deter': <String>['deterred', 'deterring', 'deters'],
        'focus': <String>['focused', 'focusing', 'focuses'],
        'travel': <String>['traveled', 'traveling', 'travels'],
        'read': <String>['reading', 'reads'],
      };
      expected.forEach((term, values) {
        final word = _word(bundle, term);
        expect(
          word.forms.map((form) => form.value).toList(growable: false),
          values,
          reason: 'صرف $term',
        );
      });
    });

    test('جمع اسم‌ها و درجه‌ی صفت‌ها درست ساخته می‌شود', () {
      const expected = <String, List<String>>{
        'man': <String>['men'],
        'child': <String>['children'],
        'bus': <String>['buses'],
        'photo': <String>['photos'],
        'city': <String>['cities'],
        'good': <String>['better', 'best'],
        'bad': <String>['worse', 'worst'],
        'big': <String>['bigger', 'biggest'],
        'happy': <String>['happier', 'happiest'],
        'simple': <String>['simpler', 'simplest'],
      };
      expected.forEach((term, values) {
        final word = _word(bundle, term);
        expect(
          word.forms.map((form) => form.value).toList(growable: false),
          values,
          reason: 'شکل‌های $term',
        );
      });
    });

    test('اسم‌های غیرقابل‌شمارش و صفت‌های درجه‌ناپذیر شکل نمی‌گیرند', () {
      const noForms = <String>['water', 'money', 'series', 'people', 'same'];
      for (final term in noForms) {
        expect(_word(bundle, term).forms, isEmpty, reason: 'شکل اضافی برای $term');
      }
    });
  });

  group('کالوکیشن‌ها', () {
    test('هر واژه دست‌کم یک کالوکیشن حاوی خودش دارد', () {
      final offenders = <String>[];
      for (final word in bundle.words) {
        final hasOwn = word.collocations
            .any((item) => _containsTerm(item, word.term));
        if (!hasOwn) offenders.add('${word.term} → ${word.collocations}');
      }
      expect(
        offenders,
        isEmpty,
        reason: 'واژه‌های بدون کالوکیشن مرتبط: $offenders',
      );
    });

    test('کالوکیشن‌ها تکراری نیستند', () {
      for (final word in bundle.words) {
        final unique = word.collocations.toSet();
        expect(unique.length, word.collocations.length,
            reason: 'کالوکیشن تکراری در ${word.term}');
      }
    });

    test('واژه‌های پرکاربرد دست‌کم دو کالوکیشن دارند', () {
      final rich =
          bundle.words.where((word) => word.collocations.length >= 2).length;
      expect(
        rich,
        greaterThanOrEqualTo(350),
        reason: 'فقط $rich واژه دو کالوکیشن یا بیشتر دارد',
      );
    });
  });

  group('تلفظ واژه‌ها', () {
    test('هر واژه تلفظ IPA دارد', () {
      final missing = bundle.words
          .where((word) => (word.ipa ?? '').trim().isEmpty)
          .map((word) => word.term)
          .toList(growable: false);
      expect(missing, isEmpty, reason: 'واژه‌های بدون تلفظ: $missing');
    });

    test('تلفظ‌ها با اسلش محاط شده‌اند', () {
      for (final word in bundle.words) {
        expect(word.ipa, startsWith('/'), reason: word.term);
        expect(word.ipa, endsWith('/'), reason: word.term);
      }
    });
  });
}
