import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../data/repositories/ai_repository_impl.dart';
import '../../data/repositories/progress_repository_impl.dart';
import '../../data/repositories/subscription_repository_impl.dart';
import '../../data/repositories/word_repository_impl.dart';
import '../../data/sources/content_source.dart';
import '../../domain/entities/pack.dart';
import '../../domain/entities/word.dart';
import '../../domain/repositories/ai_repository.dart';
import '../../domain/repositories/progress_repository.dart';
import '../../domain/repositories/subscription_repository.dart';
import '../../domain/repositories/word_repository.dart';
import '../services/app_services.dart';
import '../services/audio_service.dart';
import '../state/app_stores.dart';
import '../storage/local_store.dart';
import '../storage/local_store_factory.dart';
import 'app_controller.dart';

/// ریشه‌ی وابستگی‌های اپلیکیشن (Composition Root).
///
/// همه‌ی سرویس‌ها، مخزن‌ها و وضعیت‌ها یک‌جا ساخته و به هم وصل می‌شوند؛
/// هیچ بخشی از رابط کاربری، وابستگی خود را خودش نمی‌سازد. این کار تست‌پذیری
/// و جای‌گزینی (مثلاً اتصال به بک‌اند در آینده) را ساده می‌کند.
class AppContainer {
  AppContainer._({
    required this.localStore,
    required this.clock,
    required this.audio,
    required this.haptics,
    required this.progressRepository,
    required this.wordRepository,
    required this.subscriptionRepository,
    required this.aiRepository,
    required this.stores,
    required this.controller,
    required this.contentVersion,
  });

  final LocalStore localStore;
  final AppClock clock;
  final AudioService audio;
  final Haptics haptics;
  final ProgressRepository progressRepository;
  final WordRepository wordRepository;
  final SubscriptionRepository subscriptionRepository;
  final AiRepository aiRepository;
  final AppStores stores;
  final AppController controller;
  final String? contentVersion;

  /// راه‌اندازی کامل اپ.
  ///
  /// پارامترها همه اختیاری‌اند تا در تست‌ها بتوان نسخه‌های جعلی تزریق کرد.
  static Future<AppContainer> boot({
    LocalStore? store,
    AppClock? clock,
    AudioService? audio,
    Future<String?> Function()? remoteContentFetcher,
  }) async {
    final localStore = store ?? createLocalStore();
    if (!localStore.isReady) {
      await localStore.init();
    }
    final appClock = clock ?? AppClock();
    final audioService = audio ?? TtsAudioService();
    final haptics = Haptics();

    final progressRepository = ProgressRepositoryImpl(localStore, appClock);
    final progress = await progressRepository.load();

    final contentSource = ContentSource(localStore);
    final wordRepository = WordRepositoryImpl(
      contentSource,
      localStore,
      remoteFetcher: remoteContentFetcher,
    );
    List<Word> words = const <Word>[];
    List<StudyPack> packs = const <StudyPack>[];
    try {
      words = await wordRepository.loadWords();
      packs = await wordRepository.loadPacks();
    } catch (_) {
      // اگر محتوا بارگذاری نشد، اپ با حالت خالی بالا می‌آید و کاربر
      // می‌تواند از تنظیمات، بازیابی محتوا را امتحان کند.
      words = const <Word>[];
      packs = const <StudyPack>[];
    }

    final stores = AppStores(
      profile: progress.profile,
      settings: progress.settings,
      states: progress.states,
      sessions: progress.sessions,
      streak: progress.streak,
      xp: progress.xp,
      challenge: progress.challenge,
      achievements: progress.achievements,
      chat: progress.chat,
      subscription: progress.subscription,
      words: words,
      packs: packs,
    );

    final subscriptionRepository = SubscriptionRepositoryImpl(
      progressRepository,
      appClock,
    );
    final aiRepository = LocalAiRepository(
      words: words,
      states: progress.states,
      profile: progress.profile,
      weakness: stores.weaknessStore.value,
    );

    final controller = AppController(
      stores: stores,
      progress: progressRepository,
      words: wordRepository,
      subscriptions: subscriptionRepository,
      ai: aiRepository,
      audio: audioService,
      haptics: haptics,
      clock: appClock,
    );

    // آماده‌سازی تنبل موتور تلفظ و اعمال تنظیمات صوتی کاربر.
    unawaited(audioService.setSpeedFactor(stores.settingsStore.value.speechSpeed));
    unawaited(audioService.warmUp());

    return AppContainer._(
      localStore: localStore,
      clock: appClock,
      audio: audioService,
      haptics: haptics,
      progressRepository: progressRepository,
      wordRepository: wordRepository,
      subscriptionRepository: subscriptionRepository,
      aiRepository: aiRepository,
      stores: stores,
      controller: controller,
      contentVersion: wordRepository.contentVersion,
    );
  }

  /// آیا کاربر دسترسی ویژه دارد؟
  bool get hasPremium => stores.subscriptionStore.value.hasPremiumAccess(clock.now());

  /// بازگرداندن همه‌ی داده‌ها (برای تست‌ها و خروج از حساب).
  Future<void> resetEverything() async {
    await controller.resetProgress();
  }

  void dispose() {
    audio.dispose();
    stores.dispose();
    controller.dispose();
  }
}

/// دسترسی به کانتینر از هر جای درخت ویجت‌ها.
class AppScope extends InheritedWidget {
  const AppScope({
    super.key,
    required this.container,
    required super.child,
  });

  final AppContainer container;

  static AppContainer of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope در بالای درخت ویجت‌ها پیدا نشد.');
    return scope!.container;
  }

  static AppContainer? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()?.container;

  @override
  bool updateShouldNotify(AppScope oldWidget) => oldWidget.container != container;
}
