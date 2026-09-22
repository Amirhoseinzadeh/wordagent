import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wordagent/app.dart';
import 'package:wordagent/core/di/app_container.dart';
import 'package:wordagent/core/services/app_services.dart';
import 'package:wordagent/core/services/audio_service.dart';
import 'package:wordagent/core/storage/local_store_memory.dart';
import 'package:wordagent/core/theme/app_theme.dart';
import 'package:wordagent/domain/entities/cefr_level.dart';
import 'package:wordagent/widgets/app_button.dart';
import 'package:wordagent/widgets/badges.dart';
import 'package:wordagent/widgets/word_tile.dart';

import 'helpers/fixtures.dart';

/// سرویس صوتی بی‌اثر؛ تست‌ها به موتور TTS دستگاه وابسته نیستند.
class FakeAudioService implements AudioService {
  final List<String> spoken = <String>[];

  @override
  Future<void> warmUp() async {}

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<void> speak(String text, {double? speedFactor}) async => spoken.add(text);

  @override
  Future<void> setSpeedFactor(double factor) async {}

  @override
  Future<void> stop() async {}

  @override
  void dispose() {}
}

void _serveRealAssets() {
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  messenger.setMockMessageHandler('flutter/assets', (message) async {
    final key = utf8.decode(message!.buffer.asUint8List());
    final file = File(key);
    if (!file.existsSync()) return null;
    return ByteData.sublistView(Uint8List.fromList(file.readAsBytesSync()));
  });
}

/// پوشش استاندارد ویجت‌ها: تم اپ + جهت راست‌به‌چپ فارسی.
Widget wrap(Widget child) => MaterialApp(
      theme: AppTheme.light(),
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(body: child),
      ),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(_serveRealAssets);

  group('AppButton', () {
    testWidgets('برچسب را نشان می‌دهد و لمس را می‌پذیرد', (tester) async {
      var taps = 0;
      await tester.pumpWidget(wrap(AppButton(label: 'شروع یادگیری', onPressed: () => taps++)));

      expect(find.text('شروع یادگیری'), findsOneWidget);
      await tester.tap(find.text('شروع یادگیری'));
      await tester.pump();
      expect(taps, 1);
    });

    testWidgets('دکمه‌ی غیرفعال لمس نمی‌شود', (tester) async {
      await tester.pumpWidget(wrap(const AppButton(label: 'غیرفعال')));
      await tester.tap(find.text('غیرفعال'));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('حالت بارگذاری نشانگر پیشرفت دارد', (tester) async {
      await tester.pumpWidget(wrap(AppButton(label: 'در حال ذخیره', loading: true, onPressed: () {})));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  group('WordTile', () {
    testWidgets('واژه، معنی و برچسب‌ها را نشان می‌دهد', (tester) async {
      final word = makeWord(
        id: 'b1_001',
        term: 'resilient',
        level: CefrLevel.b1,
        faMeanings: const <String>['تاب‌آور'],
      );
      await tester.pumpWidget(wrap(WordTile(word: word)));

      expect(find.text('resilient'), findsOneWidget);
      expect(find.text('تاب‌آور'), findsOneWidget);
      expect(find.text(word.pos.faLabel), findsOneWidget);
      expect(find.text(word.level.code), findsOneWidget, reason: 'نشان سطح در حالت فشرده فقط کد را می‌نویسد');
    });

    testWidgets('وضعیت یادگیری و نوار نشان ذخیره نمایش داده می‌شود', (tester) async {
      final word = makeWord(id: 'b1_002', term: 'fragile');
      await tester.pumpWidget(
        wrap(WordTile(word: word, state: makeState(wordId: 'b1_002', totalReviews: 2, correctReviews: 2))),
      );
      expect(find.text('fragile'), findsOneWidget);
      expect(find.byType(StatusPill), findsOneWidget);
    });

    testWidgets('لمس واژه رویداد می‌دهد', (tester) async {
      final word = makeWord(id: 'b1_003', term: 'diligent');
      var opened = 0;
      await tester.pumpWidget(wrap(WordTile(word: word, onTap: () => opened++)));
      await tester.tap(find.text('diligent'));
      await tester.pump();
      expect(opened, 1);
    });
  });

  group('نشان‌ها', () {
    testWidgets('نشان سطح CEFR کد و عنوان را نشان می‌دهد', (tester) async {
      await tester.pumpWidget(
        wrap(
          CefrBadge(
            code: CefrLevel.c1.code,
            title: CefrLevel.c1.faTitle,
          ),
        ),
      );
      expect(find.text(CefrLevel.c1.code), findsOneWidget);
      expect(find.text(CefrLevel.c1.faTitle), findsOneWidget);
    });

    testWidgets('نشان ویژه برای محتوای پرمیوم دیده می‌شود', (tester) async {
      await tester.pumpWidget(wrap(const PremiumBadge()));
      expect(find.byType(PremiumBadge), findsOneWidget);
      expect(find.byIcon(Icons.workspace_premium_rounded), findsOneWidget);
    });
  });

  group('راه‌اندازی کامل اپ', () {
    testWidgets('اپ با محتوای واقعی بدون خطا بالا می‌آید و راست‌به‌چپ است', (tester) async {
      // خواندن فایل‌های محتوا کار واقعی (I/O) است و در ناحیه‌ی زمان جعلی
      // تست‌های ویجت هرگز کامل نمی‌شود؛ پس با runAsync اجرا می‌شود.
      final container = (await tester.runAsync(
        () => AppContainer.boot(
          store: MemoryLocalStore(),
          clock: AppClock(provider: () => testNow),
          audio: FakeAudioService(),
        ),
      ))!;
      expect(container.contentVersion, isNotNull);

      await tester.pumpWidget(WordAgentApp(container: container));
      await tester.pump();
      await tester.pump(const Duration(seconds: 3));

      expect(tester.takeException(), isNull);
      expect(find.byType(MaterialApp), findsOneWidget);

      final direction = tester.widget<Directionality>(find.byType(Directionality).first);
      expect(direction.textDirection, TextDirection.rtl);
    });

    testWidgets('تم روشن و تیره هر دو ساخته می‌شوند', (tester) async {
      final light = AppTheme.light();
      final dark = AppTheme.dark();
      expect(light.brightness, Brightness.light);
      expect(dark.brightness, Brightness.dark);
      expect(light.colorScheme.secondary, isNotNull);
      expect(dark.colorScheme.secondary, isNotNull);
    });
  });

  group('مدل‌های نمایشی', () {
    testWidgets('واژه‌ی نمونه همه‌ی داده‌های لازم تمرین را دارد', (tester) async {
      final word = makeWord(id: 'w1', term: 'resilient');
      expect(word.primaryMeaning, isNotEmpty);
      expect(word.clozeExamples, isNotEmpty);
      expect(word.difficultyLabelFa, isNotEmpty);
      expect(word.acceptableMeanings, isNotEmpty);
    });
  });
}
