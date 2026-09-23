import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wordagent/app.dart';
import 'package:wordagent/core/di/app_container.dart';
import 'package:wordagent/core/routing/app_router.dart';
import 'package:wordagent/core/services/app_services.dart';
import 'package:wordagent/core/services/audio_service.dart';
import 'package:wordagent/core/storage/local_store_memory.dart';
import 'package:wordagent/core/theme/app_theme.dart';
import 'package:wordagent/domain/entities/word.dart';
import 'package:wordagent/features/explore/explore_screen.dart';
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

/// باندل دارایی‌های واقعی مخزن (همان محتوایی که کاربر می‌بیند).
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

/// بالا آوردن اپ با ساعت ثابت، حافظه‌ی موقت و محتوای واقعی.
Future<AppContainer> bootApp(WidgetTester tester) async {
  final container = (await tester.runAsync(
    () => AppContainer.boot(
      store: MemoryLocalStore(),
      clock: AppClock(provider: () => testNow),
      audio: _SilentAudio(),
    ),
  ))!;
  addTearDown(container.dispose);
  return container;
}

/// بالا آوردن اپ کامل و رسیدن به نخستین قاب تصویرشده.
Future<void> pumpApp(WidgetTester tester, AppContainer container) async {
  await tester.pumpWidget(WordAgentApp(container: container));
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
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
int currentTab(WidgetTester tester) => tester
    .widget<IndexedStack>(
      find.descendant(
        of: find.byType(HomeShell),
        matching: find.byType(IndexedStack),
      ).first,
    )
    .index;

/// رفتن به یک تب ناوبری و اطمینان از این‌که واقعاً باز شد.
Future<void> openTab(WidgetTester tester, String label, int index) async {
  await tester.tap(find.text(label).last);
  await tester.pump(const Duration(milliseconds: 400));
  expect(currentTab(tester), index, reason: 'تب «$label» باز نشد');
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
  await tester.pump(const Duration(milliseconds: 400));
}

/// واژه‌هایی که در حال حاضر در درخت ویجت رندر شده‌اند.
List<Word> renderedWords(WidgetTester tester) => tester
    .widgetList<WordTile>(find.byType(WordTile))
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
        expect(find.text(label), findsWidgets, reason: 'تب $label نیست');
      }

      // تب «کاوش» ⟶ کادر جست‌وجو و چیپ‌های موضوع.
      await openTab(tester, S.navExplore, 2);
      expect(find.text(S.searchHint), findsOneWidget);
      expect(find.byType(TagChip), findsWidgets);

      // تب «یادگیری» ⟶ کارت‌های برنامه‌ی امروز.
      await openTab(tester, S.navLearn, 1);
      expect(find.text(S.dueReviews), findsWidgets);
      expect(find.text(S.newWords), findsWidgets);
      expect(find.text(S.dailyChallenge), findsWidgets);

      // تب «پیشرفت» ⟶ بخش نقاط ضعف.
      await openTab(tester, S.navProgress, 3);
      expect(find.text(S.weakWordsTitle), findsWidgets);

      // بازگشت به خانه.
      await openTab(tester, S.navHome, 0);
      expect(find.text(S.wordOfTheDay), findsWidgets);
    });

    testWidgets('صفحه‌ی خانه واژه‌ی روز و پیشنهاد هدف‌محور دارد', (tester) async {
      final container = await bootApp(tester);
      await pumpApp(tester, container);

      expect(find.text(S.wordOfTheDay), findsWidgets);
      expect(find.text(S.goalWordsTitle), findsWidgets);
      expect(renderedWords(tester), isNotEmpty);
    });
  });

  group('جست‌وجو در صفحه‌ی کاوش', () {
    testWidgets('جست‌وجوی واژه‌ی انگلیسی نتیجه می‌دهد', (tester) async {
      final container = await bootApp(tester);
      await pumpApp(tester, container);
      await openTab(tester, S.navExplore, 2);

      await searchInExplore(tester, 'water');
      expect(renderedWords(tester).map((word) => word.term), contains('water'));
    });

    testWidgets('جست‌وجوی معنی فارسی نتیجه می‌دهد', (tester) async {
      final container = await bootApp(tester);
      await pumpApp(tester, container);
      await openTab(tester, S.navExplore, 2);

      await searchInExplore(tester, 'کودک');
      expect(renderedWords(tester).map((word) => word.term), contains('child'));
    });

    testWidgets('جست‌وجوی موضوعی با نام فارسی کار می‌کند', (tester) async {
      final container = await bootApp(tester);
      await pumpApp(tester, container);
      await openTab(tester, S.navExplore, 2);

      await searchInExplore(tester, 'سفر');
      final words = renderedWords(tester);
      expect(words, isNotEmpty);
      for (final word in words) {
        expect(
          word.topics.contains('travel'),
          isTrue,
          reason: '${word.term} واژه‌ی موضوع سفر نیست',
        );
      }
    });

    testWidgets('جست‌وجوی بی‌نتیجه، پیام خالی نشان می‌دهد', (tester) async {
      final container = await bootApp(tester);
      await pumpApp(tester, container);
      await openTab(tester, S.navExplore, 2);

      await searchInExplore(tester, 'zzzqqq');
      expect(renderedWords(tester), isEmpty);
      expect(find.text(S.noResult), findsWidgets);
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
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      final words = renderedWords(tester);
      expect(words, isNotEmpty);
      for (final word in words) {
        expect(word.topics.contains('travel'), isTrue,
            reason: '${word.term} در فیلتر سفر نیامده است');
      }
      // چیپ موضوع در نوار فیلترها دیده می‌شود.
      expect(find.textContaining('موضوع:'), findsOneWidget);
    });

    testWidgets('صفحه‌ی جزئیات واژه بخش‌های اصلی را نشان می‌دهد',
        (tester) async {
      final container = await bootApp(tester);
      final word = container.allWords.firstWhere((item) => item.term == 'water');

      await tester.pumpWidget(
        wrapScreen(
          container,
          WordDetailScreen(args: WordDetailArgs(word: word)),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('water'), findsWidgets);
      expect(find.text(S.imageSection), findsWidgets);
      expect(find.byType(WordImageCard), findsOneWidget);
      expect(find.text(S.meaningSection), findsWidgets);
      expect(find.text(S.collocationsSection), findsWidgets);
    });
  });
}
