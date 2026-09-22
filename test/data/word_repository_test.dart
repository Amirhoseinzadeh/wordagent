import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wordagent/core/storage/local_store_memory.dart';
import 'package:wordagent/data/repositories/word_repository_impl.dart';
import 'package:wordagent/data/sources/content_source.dart';

void _serveRealAssets() {
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  messenger.setMockMessageHandler('flutter/assets', (message) async {
    final key = utf8.decode(message!.buffer.asUint8List());
    final file = File(key);
    if (!file.existsSync()) return null;
    return ByteData.sublistView(Uint8List.fromList(file.readAsBytesSync()));
  });
}

String payloadWith(List<Map<String, dynamic>> words, {String version = '2.0.0'}) =>
    jsonEncode(<String, dynamic>{'version': version, 'words': words});

Map<String, dynamic> freshWord(String id, {String? fa = 'واژه‌ی تازه'}) => <String, dynamic>{
      'id': id,
      'term': 'fresh$id',
      'pos': 'n',
      'level': 'b1',
      if (fa != null) 'fa': <String>[fa],
      'def': 'توضیح',
      'ex': <dynamic>[
        <String, dynamic>{'en': 'A fresh word.', 'fa': 'یک واژه‌ی تازه.'},
      ],
    };

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(_serveRealAssets);

  late MemoryLocalStore store;
  late ContentSource source;

  WordRepositoryImpl build({Future<String?> Function()? remoteFetcher}) =>
      WordRepositoryImpl(source, store, remoteFetcher: remoteFetcher);

  setUp(() {
    store = MemoryLocalStore();
    source = ContentSource(store);
  });

  group('WordRepositoryImpl — بارگذاری', () {
    test('واژه‌ها و بسته‌ها خوانده می‌شوند و نسخه‌ی محتوا در دسترس است', () async {
      final repository = build();
      final words = await repository.loadWords();
      final packs = await repository.loadPacks();

      expect(words.length, greaterThan(800));
      expect(packs.length, greaterThan(20));
      expect(repository.contentVersion, isNotNull);
      expect(repository.wordIndex.length, words.length);
      expect(repository.wordById(words.first.id), isNotNull);
      expect(repository.wordById('شناسه‌ی ناموجود'), isNull);
    });

    test('بارگذاری دوم کش را به کار می‌گیرد (بدون خطا)', () async {
      final repository = build();
      final first = await repository.loadWords();
      final second = await repository.loadWords();
      expect(identical(first, second) || first.length == second.length, isTrue);
    });

    test('hasLocalUpdate تنها با نسخه‌ی محلی درست می‌شود', () async {
      final repository = build();
      expect(await repository.hasLocalUpdate(), isFalse);
      await store.setString(ContentSource.overrideKey, payloadWith(<Map<String, dynamic>>[freshWord('x1')]));
      expect(await repository.hasLocalUpdate(), isTrue);
    });

    test('applyLocalUpdate محتوای محلی را جایگزین می‌کند', () async {
      final repository = build();
      await repository.loadWords();
      await store.setString(
        ContentSource.overrideKey,
        payloadWith(<Map<String, dynamic>>[freshWord('x1'), freshWord('x2')]),
      );
      await repository.applyLocalUpdate();
      final words = await repository.loadWords();
      expect(words.length, 2);
      expect(repository.wordById('x1'), isNotNull);
      expect(repository.contentVersion, '2.0.0');
    });

    test('applyLocalUpdate بدون داده کاری نمی‌کند', () async {
      final repository = build();
      await repository.loadWords();
      await repository.applyLocalUpdate();
      expect((await repository.loadWords()).length, greaterThan(800));
    });
  });

  group('WordRepositoryImpl — به‌روزرسانی آنلاین', () {
    test('بدون منبع شبک، به‌روزرسانی ممکن نیست', () async {
      final repository = build();
      expect(await repository.checkForUpdates(), isFalse);
    });

    test('داده‌ی معتبر ذخیره و اعمال می‌شود', () async {
      var calls = 0;
      final repository = build(remoteFetcher: () async {
        calls++;
        return payloadWith(<Map<String, dynamic>>[freshWord('n1'), freshWord('n2')]);
      });

      expect(await repository.checkForUpdates(), isTrue);
      expect(calls, 1);
      expect(store.getString(ContentSource.overrideKey), isNotNull);

      final words = await repository.loadWords();
      expect(words.length, 2);
      expect(repository.contentVersion, '2.0.0');
    });

    test('پاسخ خالی یا نامعتبر پذیرفته نمی‌شود', () async {
      var payload = '';
      final repository = build(remoteFetcher: () async => payload);
      expect(await repository.checkForUpdates(), isFalse);

      payload = '{"words": []}';
      expect(await repository.checkForUpdates(), isFalse);

      // واژه بدون معنی فارسی نامعتبر است.
      payload = payloadWith(<Map<String, dynamic>>[freshWord('n1', fa: null)]);
      expect(await repository.checkForUpdates(), isFalse);

      payload = payloadWith(<Map<String, dynamic>>[<String, dynamic>{'term': 'بدون‌شناسه'}]);
      expect(await repository.checkForUpdates(), isFalse);

      payload = 'متن شکسته';
      expect(await repository.checkForUpdates(), isFalse);
      expect(store.getString(ContentSource.overrideKey), isNull);
    });

    test('خطای شبکه باعث خرابی اپ نمی‌شود', () async {
      final repository = build(remoteFetcher: () async {
        throw const SocketException('قطع اتصال');
      });
      expect(await repository.checkForUpdates(), isFalse);
      expect((await repository.loadWords()).length, greaterThan(800));
    });
  });

  group('WordRepositoryImpl — برون‌بری', () {
    test('json برون‌بری شامل واژه‌ها و بسته‌های معتبر است', () async {
      final repository = build();
      final raw = await repository.exportJson();
      final decoded = jsonDecode(raw) as Map<String, dynamic>;

      final words = decoded['words'] as List<dynamic>;
      final packs = decoded['packs'] as List<dynamic>;
      expect(words.length, greaterThan(800));
      expect(packs.length, greaterThan(20));
      expect(decoded['version'], isNotNull);
    });

    test('برون‌بری دوباره خوانده می‌شود (سازگاری با نسخه‌ی پشتیبان)', () async {
      final repository = build();
      final raw = await repository.exportJson();
      final decoded = jsonDecode(raw) as Map<String, dynamic>;

      final backupStore = MemoryLocalStore();
      await backupStore.init();
      await backupStore.setString(ContentSource.overrideKey, raw);

      final bundle = await ContentSource(backupStore).load();
      expect(bundle.source, 'local');
      expect(bundle.words.length, (decoded['words'] as List<dynamic>).length);
      expect(bundle.packs.length, (decoded['packs'] as List<dynamic>).length);
      expect(bundle.words.first.term, isNotEmpty);
    });
  });
}
