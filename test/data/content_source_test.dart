import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wordagent/core/storage/local_store_memory.dart';
import 'package:wordagent/data/sources/content_source.dart';
import 'package:wordagent/domain/entities/cefr_level.dart';
import 'package:wordagent/domain/entities/word.dart';

/// پاسخ‌دهی بسته‌ی دارایی‌ها از فایل‌های واقعی مخزن تا محتوای تولیدشده
/// همان‌طور که اپ می‌خواند، آزموده شود.
void _serveRealAssets() {
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  messenger.setMockMessageHandler('flutter/assets', (message) async {
    final key = utf8.decode(message!.buffer.asUint8List());
    final file = File(key);
    if (!file.existsSync()) return null;
    return ByteData.sublistView(Uint8List.fromList(file.readAsBytesSync()));
  });
}

/// حروف فارسی/عربی برای سنجش ترجمه‌ها.
final RegExp persianLetters = RegExp(r'[\u0600-\u06FF]');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(_serveRealAssets);

  late ContentSource source;
  late MemoryLocalStore store;

  setUp(() {
    store = MemoryLocalStore();
    source = ContentSource(store);
  });

  group('ContentSource — بارگذاری بسته‌ی محتوا', () {
    test('نسخه و فایل‌های سطح از مانیفست خوانده می‌شوند', () {
      expect(ContentSource.levelFiles.length, CefrLevel.values.length);
      expect(ContentSource.levelFiles, contains('words_b1.json'));
    });

    test('همه‌ی واژه‌های محتوا بارگذاری می‌شوند', () async {
      final bundle = await source.load(preferLocal: false);
      expect(bundle.source, 'assets');
      expect(bundle.isEmpty, isFalse);
      expect(bundle.version, isNotNull);
      expect(bundle.words.length, greaterThan(800));

      for (final level in CefrLevel.values) {
        expect(
          bundle.countFor(level),
          greaterThan(0),
          reason: 'هر سطح CEFR باید واژه داشته باشد: ${level.code}',
        );
      }

      final ids = bundle.words.map((word) => word.id).toList();
      expect(ids.toSet().length, ids.length, reason: 'شناسه‌ی واژه‌ها باید یکتا باشد');
    });

    test('هر واژه معنی، توضیح و مثال فارسی دارد', () async {
      final bundle = await source.load(preferLocal: false);
      for (final word in bundle.words) {
        expect(word.term.trim(), isNotEmpty);
        expect(word.id.trim(), isNotEmpty);
        expect(
          word.faMeanings,
          isNotEmpty,
          reason: 'واژه‌ی ${word.term} بدون معنی فارسی است',
        );
        expect(word.faDefinition.trim(), isNotEmpty);
        expect(word.examples, isNotEmpty);
        expect(word.difficulty, inInclusiveRange(1, 5));
        expect(word.frequencyRank, greaterThan(-1));

        for (final meaning in word.faMeanings) {
          expect(meaning.trim(), isNotEmpty);
          expect(persianLetters.hasMatch(meaning), isTrue, reason: 'معنی غیر‌فارسی: $meaning');
        }
        expect(persianLetters.hasMatch(word.faDefinition), isTrue);
        for (final example in word.examples) {
          expect(example.en.trim(), isNotEmpty);
          expect(persianLetters.hasMatch(example.fa), isTrue, reason: example.fa);
        }
      }
    });

    test('مثال‌های مکالمه‌ای و دیالوگ‌های سینمایی وجود دارند', () async {
      final bundle = await source.load(preferLocal: false);
      final withMovie = bundle.words.where((word) => word.movieLines.isNotEmpty);
      final withConversation = bundle.words.where(
        (word) => word.examples.any((example) => example.kind == ExampleKind.conversation),
      );
      expect(withMovie.length, greaterThanOrEqualTo(20));
      expect(withConversation.length, greaterThan(300));

      for (final word in withMovie) {
        for (final line in word.movieLines) {
          expect(line.line.trim(), isNotEmpty);
          expect(line.sourceTitle.trim(), isNotEmpty);
          expect(persianLetters.hasMatch(line.fa), isTrue);
        }
      }
    });

    test('بسته‌های موضوعی معتبر و متصل به واژه‌ها هستند', () async {
      final bundle = await source.load(preferLocal: false);
      expect(bundle.packs.length, greaterThanOrEqualTo(20));

      final packIds = bundle.packs.map((pack) => pack.id).toSet();
      expect(packIds.length, bundle.packs.length, reason: 'شناسه‌ی بسته‌ها یکتاست');

      final wordIds = bundle.words.map((word) => word.id).toSet();
      final connected = <String>{};
      for (final pack in bundle.packs) {
        expect(pack.title.trim(), isNotEmpty);
        expect(pack.description.trim(), isNotEmpty);
        expect(pack.emoji.trim(), isNotEmpty);
        expect(pack.level, isNotNull);
        expect(pack.wordIds.length, greaterThanOrEqualTo(2));
        for (final id in pack.wordIds) {
          expect(wordIds.contains(id), isTrue, reason: 'واژه‌ی ناموجود در بسته: $id');
          connected.add(id);
        }
      }
      expect(connected.length, greaterThan(200));

      final linkedBack = bundle.words.where((word) => word.packIds.isNotEmpty);
      expect(linkedBack.length, greaterThan(200));
      for (final word in linkedBack) {
        for (final packId in word.packIds) {
          expect(packIds.contains(packId), isTrue);
        }
      }
    });

    test('محتوای رایگان و ویژه هر دو وجود دارند', () async {
      final bundle = await source.load(preferLocal: false);
      final premiumPacks = bundle.packs.where((pack) => pack.premium).toList();
      expect(premiumPacks, isNotEmpty, reason: 'مدل کسب‌وکار به محتوای ویژه نیاز دارد');
      expect(premiumPacks.length, lessThan(bundle.packs.length));

      final premiumWords = bundle.words.where((word) => word.premium).length;
      expect(premiumWords, lessThan(bundle.words.length ~/ 2));

      final freeWordIds = bundle.packs
          .where((pack) => !pack.premium)
          .expand((pack) => pack.wordIds)
          .toSet();
      expect(freeWordIds.length, greaterThan(100), reason: 'کاربر رایگان باید محتوای کافی داشته باشد');
    });

    test('واژه‌های سطح بالاتر سخت‌تر شمرده می‌شوند', () async {
      final bundle = await source.load(preferLocal: false);
      double averageDifficulty(CefrLevel level) {
        final list = bundle.words.where((word) => word.level == level).toList();
        final sum = list.fold<int>(0, (total, word) => total + word.difficulty);
        return sum / list.length;
      }

      expect(averageDifficulty(CefrLevel.a1), lessThan(averageDifficulty(CefrLevel.c1)));
    });
  });

  group('ContentSource — به‌روزرسانی محلی', () {
    test('بدون نسخه‌ی محلی، محتوای بسته استفاده می‌شود', () async {
      final bundle = await source.load();
      expect(bundle.source, 'assets');
    });

    test('نسخه‌ی محلی بر بسته‌ی اپ اولویت دارد', () async {
      await store.setString(
        ContentSource.overrideKey,
        jsonEncode(<String, dynamic>{
          'version': '9.9.9',
          'words': <dynamic>[
            <String, dynamic>{
              'id': 'x1',
              'term': 'newword',
              'pos': 'n',
              'level': 'b1',
              'fa': <String>['واژه‌ی تازه'],
              'def': 'توضیح تازه',
              'ex': <dynamic>[
                <String, dynamic>{'en': 'A fresh word.', 'fa': 'یک واژه‌ی تازه.'},
              ],
            },
          ],
          'packs': <dynamic>[
            <String, dynamic>{
              'id': 'pack_x',
              'title': 'بسته‌ی تازه',
              'desc': 'توضیح',
              'emoji': '🧪',
              'words': <String>['x1'],
              'level': 'b1',
            },
          ],
        }),
      );

      final bundle = await source.load();
      expect(bundle.source, 'local');
      expect(bundle.version, '9.9.9');
      expect(bundle.words.length, 1);
      expect(bundle.words.single.term, 'newword');
      expect(bundle.packs.single.id, 'pack_x');

      // با preferLocal: false دوباره محتوای بسته خوانده می‌شود.
      final fromAssets = await source.load(preferLocal: false);
      expect(fromAssets.source, 'assets');
      expect(fromAssets.words.length, greaterThan(800));
    });

    test('نسخه‌ی محلی خراب نادیده گرفته می‌شود', () async {
      await store.setString(ContentSource.overrideKey, '{این متن JSON نیست');
      final bundle = await source.load();
      expect(bundle.source, 'assets');
    });

    test('نسخه‌ی محلی بدون واژه معتبر، نادیده گرفته می‌شود', () async {
      await store.setString(
        ContentSource.overrideKey,
        jsonEncode(<String, dynamic>{'version': '2.0.0', 'words': <dynamic>[]}),
      );
      final bundle = await source.load();
      expect(bundle.source, 'assets');
    });
  });
}
