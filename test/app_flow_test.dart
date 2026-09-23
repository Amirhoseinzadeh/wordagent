import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wordagent/app.dart';
import 'package:wordagent/core/di/app_container.dart';
import 'package:wordagent/core/routing/app_router.dart';
import 'package:wordagent/core/services/app_services.dart';
import 'package:wordagent/core/services/audio_service.dart';
import 'package:wordagent/core/storage/local_store_memory.dart';
import 'package:wordagent/core/theme/app_dimens.dart';
import 'package:wordagent/core/theme/app_theme.dart';
import 'package:wordagent/domain/entities/word.dart';
import 'package:wordagent/features/explore/explore_screen.dart';
import 'package:wordagent/features/home/home_screen.dart';
import 'package:wordagent/features/shell/home_shell.dart';
import 'package:wordagent/features/word_detail/word_detail_screen.dart';
import 'package:wordagent/features/word_list/word_list_screen.dart';
import 'package:wordagent/l10n/strings.dart';
import 'package:wordagent/widgets/app_button.dart';
import 'package:wordagent/widgets/word_image.dart';
import 'package:wordagent/widgets/word_tile.dart';

import 'helpers/fixtures.dart';

/// سرویس صوتی ساکت — تست‌ها به TTS دستگاه وابسته نیستند.
class _SilentAudio implements AudioService {
  @override
  Future<void> warmUp() async {}

  @override
  Future<bool> isAvailable() async => false;

  @override
  Future<void> speak(String text, {double? speedFactor}) async {}

  @override
  Future<void> setSpeedFactor(double factor) async {}

  @override
  Future<void> stop() async {}

  @override
  void dispose() {}
}

/// مانیفست دارایی‌ها با همان قالب دودویی‌ای که ابزار فلاتر می‌سازد
/// (کلید دارایی ⟶ فهرست گونه‌ها). بدون آن، `Image.asset` در تست نمی‌تواند
/// دارایی‌ها را پیدا کند و «Unable to load asset: AssetManifest.bin» می‌دهد.
ByteData _assetManifest() {
  final entries = <String, Object?>{};
  for (final entity in Directory('assets').listSync(recursive: true)) {
    if (entity is! File) continue;
    final key = entity.path.replaceAll('\\', '/');
    entries[key] = <Object?>[
      <Object?, Object?>{'asset': key, 'dpr': 1.0},
    ];
  }
  return const StandardMessageCodec().encodeMessage(entries)!;
}

/// باندل دارایی‌های واقعی مخزن (همان محتوایی که کاربر می‌بیند) + مانیفست.
void _serveRealAssets() {
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final manifest = _assetManifest();
  messenger.setMockMessageHandler('flutter/assets', (message) async {
    final key = utf8.decode(message!.buffer.asUint8List());
    if (key == 'AssetManifest.bin') return manifest;
    final file = File(key);
    if (!file.existsSync()) return null;
    return ByteData.sublistView(Uint8List.fromList(file.readAsBytesSync()));
  });
}

/// صفحه‌ی آزمایشی بلند (عرض پیش‌فرض، ارتفاع بلند).
///
/// فهرست‌های اپ از ویجت‌های تنبل ساخته می‌شوند؛ با ارتفاع بلند همه‌ی
/// بخش‌های یک صفحه ساخته می‌شود و تست به اسکرول وابسته نمی‌ماند.
/// عرض را باریک نمی‌کنیم چون فونت پیش‌فرض محیط تست عرض هر نویسه را برابر
/// اندازه‌ی فونت می‌گیرد و متن‌های فارسی پهن‌تر از حالت واقعی می‌شوند.
void useTallSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

/// چند قاب پشت‌سرهم می‌زند تا انیمیشن‌ها و کارهای async جا بیفتند.
///
/// عمداً از `pumpAndSettle` استفاده نمی‌شود: در اپ چند انیمیشن تکرارشونده
/// (مثل افکت کارت‌ها) هست و settle هرگز تمام نمی‌شود.
Future<void> settle(
  WidgetTester tester, {
  int frames = 4,
  Duration step = const Duration(milliseconds: 150),
}) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(step);
  }
}

/// چند قاب می‌زند تا ویجت موردنظر پیدا شود.
Future<bool> pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  int tries = 40,
  Duration step = const Duration(milliseconds: 150),
}) async {
  for (var i = 0; i < tries; i++) {
    if (finder.evaluate().isNotEmpty) return true;
    await tester.pump(step);
  }
  return finder.evaluate().isNotEmpty;
}

/// بالا آوردن اپ با ساعت ثابت، حافظه‌ی موقت و محتوای واقعی.
Future<AppContainer> bootApp(WidgetTester tester) async {
  useTallSurface(tester);
  // خواندن فایل‌های محتوا کار واقعی (I/O) است و در ناحیه‌ی زمان جعلی تست
  // ویجت هرگز کامل نمی‌شود؛ پس با runAsync اجرا می‌شود.
  final container = (await tester.runAsync(
    () => AppContainer.boot(
      store: MemoryLocalStore(),
      clock: AppClock(provider: () => testNow),
      audio: _SilentAudio(),
    ),
  ))!;
  addTearDown(container.dispose);
  // کاربر آنبوردینگ‌شده تا اسپلش مستقیم به پوسته‌ی اصلی برود.
  container.stores.profileStore.value = container.controller.profile.copyWith(
    onboarded: true,
    name: 'سارا',
  );
  return container;
}

/// بالا آوردن اپ کامل تا رسیدن به پوسته‌ی اصلی (بعد از اسپلش).
Future<void> pumpApp(WidgetTester tester, AppContainer container) async {
  await tester.pumpWidget(WordAgentApp(container: container));
  final reached = await pumpUntilFound(tester, find.byType(HomeShell));
  expect(reached, isTrue, reason: 'اپ به پوسته‌ی اصلی نرسید (اسپلش/آنبوردینگ).');
  await settle(tester, frames: 5);
}

/// پوشش یک صفحه‌ی مستقل با همان اسکوپ/تم اپ.
Widget wrapScreen(AppContainer container, Widget child) => AppScope(
      container: container,
      child: MaterialApp(
        theme: AppTheme.light(),
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: child,
        ),
      ),
    );

/// تب جاری پوسته‌ی اپ (اندیس IndexedStack درون HomeShell).
///
/// همه‌ی تب‌ها در IndexedStack ساخته می‌شوند؛ تنها راه تشخیص تب فعال،
/// همین اندیس است نه وجود متن‌ها در درخت.
int currentTab(WidgetTester tester) {
  final stack = find.descendant(
    of: find.byType(HomeShell),
    matching: find.byType(IndexedStack),
  );
  expect(stack, findsWidgets, reason: 'پوسته‌ی اصلی در درخت ویجت‌ها نیست.');
  final index = tester.widget<IndexedStack>(stack.first).index;
  expect(index, isNotNull, reason: 'اندیس تب جاری خالی است.');
  return index!;
}

/// رفتن به تب شماره‌ی `index` از نوار ناوبری پایین و بررسی باز شدن آن.
Future<void> openTab(WidgetTester tester, String label, int index) async {
  final shell = tester.getSize(find.byType(HomeShell));
  await tester.tapAt(
    Offset(
      shell.width * (index + 0.5) / 5,
      shell.height - AppSizes.bottomNavHeight / 2,
    ),
  );
  await settle(tester, frames: 2);
  if (currentTab(tester) != index) {
    // جایگزین: لمس برچسب تب (اگر چیدمان نوار پایین تغییر کند).
    await tester.tap(find.text(label).last, warnIfMissed: false);
    await settle(tester, frames: 2);
  }
  expect(currentTab(tester), index, reason: 'تب «$label» باز نشد.');
}

/// تایپ در کادر جست‌وجوی صفحه‌ی کاوش.
Future<void> searchInExplore(WidgetTester tester, String query) async {
  final field = find
      .descendant(
        of: find.byType(ExploreScreen),
        matching: find.byType(TextField),
      )
      .first;
  await tester.enterText(field, query);
  await settle(tester, frames: 3);
}

/// واژه‌های رندرشده در یک صفحه‌ی مشخص (نه کل اپ؛ چون IndexedStack همه‌ی
/// تب‌ها را در درخت نگه می‌دارد).
List<Word> wordsIn(WidgetTester tester, Type screen) => tester
    .widgetList<WordTile>(
      find.descendant(of: find.byType(screen), matching: find.byType(WordTile)),
    )
    .map((tile) => tile.word)
    .toList(growable: false);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(_serveRealAssets);

  group('مسیرهای اصلی اپ', () {
    testWidgets('پنج تب ناوبری دارد و هر تب باز می‌شود', (tester) async {
      final container = await bootApp(tester);
      await pumpApp(tester, container);

      for (final label in <String>[
        S.navHome,
        S.navLearn,
        S.navExplore,
        S.navProgress,
        S.navProfile,
      ]) {
        expect(find.text(label), findsWidgets, reason: 'برچسب تب «$label» نیست');
      }
      expect(currentTab(tester), 0, reason: 'اپ باید روی تب خانه باز شود');

      // تب‌ها به ترتیب: خانه، یادگیری، کاوش، پیشرفت، پروفایل.
      await openTab(tester, S.navLearn, 1);
      await openTab(tester, S.navExplore, 2);
      expect(
        find.descendant(
          of: find.byType(ExploreScreen),
          matching: find.byType(TextField),
        ),
        findsWidgets,
        reason: 'کادر جست‌وجوی کاوش نیست',
      );
      expect(find.byType(TagChip), findsWidgets);
      await openTab(tester, S.navProgress, 3);
      await openTab(tester, S.navProfile, 4);
      await openTab(tester, S.navHome, 0);
    });

    testWidgets('صفحه‌ی خانه واژه‌ی روز و پیشنهاد هدف‌محور دارد',
        (tester) async {
      final container = await bootApp(tester);
      await pumpApp(tester, container);

      expect(find.text(S.wordOfTheDay), findsWidgets);
      expect(find.text(S.goalWordsTitle), findsWidgets);
      expect(wordsIn(tester, HomeScreen), isNotEmpty);
    });
  });

  group('جست‌وجو در صفحه‌ی کاوش', () {
    testWidgets('جست‌وجوی واژه‌ی انگلیسی نتیجه می‌دهد', (tester) async {
      final container = await bootApp(tester);
      await pumpApp(tester, container);
      await openTab(tester, S.navExplore, 2);

      await searchInExplore(tester, 'water');
      expect(
        wordsIn(tester, ExploreScreen).map((word) => word.term),
        contains('water'),
      );
    });

    testWidgets('جست‌وجوی معنی فارسی نتیجه می‌دهد', (tester) async {
      final container = await bootApp(tester);
      await pumpApp(tester, container);
      await openTab(tester, S.navExplore, 2);

      await searchInExplore(tester, 'کودک');
      expect(
        wordsIn(tester, ExploreScreen).map((word) => word.term),
        contains('child'),
      );
    });

    testWidgets('جست‌وجوی موضوعی با نام فارسی کار می‌کند', (tester) async {
      final container = await bootApp(tester);
      await pumpApp(tester, container);
      await openTab(tester, S.navExplore, 2);

      await searchInExplore(tester, 'سفر');
      final words = wordsIn(tester, ExploreScreen);
      expect(words, isNotEmpty);
      for (final word in words) {
        final relevant = word.topics.contains('travel') ||
            word.faMeanings.any((meaning) => meaning.contains('سفر'));
        expect(relevant, isTrue, reason: '${word.term} با «سفر» بی‌ربط است');
      }
    });

    testWidgets('جست‌وجوی بی‌نتیجه، پیام خالی نشان می‌دهد', (tester) async {
      final container = await bootApp(tester);
      await pumpApp(tester, container);
      await openTab(tester, S.navExplore, 2);

      await searchInExplore(tester, 'zzzqqq');
      expect(wordsIn(tester, ExploreScreen), isEmpty);
      expect(
        find.descendant(
          of: find.byType(ExploreScreen),
          matching: find.text(S.noResult),
        ),
        findsWidgets,
      );
    });
  });

  group('فهرست واژه‌ها و جزئیات واژه', () {
    testWidgets('فهرست با فیلتر موضوع فقط واژه‌های همان موضوع را می‌دهد',
        (tester) async {
      final container = await bootApp(tester);
      await tester.pumpWidget(
        wrapScreen(
          container,
          WordListScreen(
            args: WordListArgs(
              title: 'سفر و مکان',
              subtitle: 'واژه‌های موضوع سفر',
              topic: 'travel',
            ),
          ),
        ),
      );
      await settle(tester, frames: 3);

      final words = wordsIn(tester, WordListScreen);
      expect(words, isNotEmpty);
      for (final word in words) {
        expect(word.topics.contains('travel'), isTrue,
            reason: '${word.term} در فیلتر سفر نیامده است');
      }
      // چیپ موضوع فعال در نوار فیلترها دیده می‌شود.
      expect(find.textContaining('موضوع:'), findsWidgets);
    });

    testWidgets('صفحه‌ی جزئیات واژه بخش‌های اصلی را نشان می‌دهد',
        (tester) async {
      final container = await bootApp(tester);
      final word = container.controller.allWords
          .firstWhere((item) => item.term == 'water');

      await tester.pumpWidget(
        wrapScreen(
          container,
          WordDetailScreen(args: WordDetailArgs(word: word)),
        ),
      );
      await settle(tester, frames: 4);

      expect(find.text('water'), findsWidgets);
      expect(find.text(S.imageSection), findsWidgets);
      expect(find.byType(WordImageCard), findsOneWidget);
      expect(find.text(S.meaningSection), findsWidgets);
      expect(find.text(S.collocationsSection), findsWidgets);
    });
  });
}
