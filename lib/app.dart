import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/di/app_container.dart';
import 'core/routing/app_router.dart';
import 'core/state/value_store.dart';
import 'core/theme/app_theme.dart';
import 'domain/entities/settings.dart';
import 'domain/engines/session_builder.dart';
import 'features/achievements/achievements_screen.dart';
import 'features/challenge/challenge_screen.dart';
import 'features/chat/chat_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/pack/pack_detail_screen.dart';
import 'features/paywall/paywall_screen.dart';
import 'features/placement/placement_screen.dart';
import 'features/quiz/quiz_screen.dart';
import 'features/review/learn_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/shell/home_shell.dart';
import 'features/splash/splash_screen.dart';
import 'features/word_detail/word_detail_screen.dart';
import 'features/word_list/word_list_screen.dart';
import 'l10n/strings.dart';
import 'widgets/app_scaffold.dart';
import 'widgets/states.dart';

/// ریشه‌ی اپلیکیشن: تم، زبان، مسیرها و دسترسی به کانتینر.
class WordAgentApp extends StatelessWidget {
  const WordAgentApp({super.key, required this.container});

  final AppContainer container;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      container: container,
      child: StoreBuilder<AppSettings>(
        store: container.stores.settingsStore,
        builder: (context, settings) {
          return MaterialApp(
            title: S.appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: _themeModeOf(settings.themeMode),
            locale: const Locale('fa', 'IR'),
            supportedLocales: const <Locale>[Locale('fa', 'IR')],
            localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            initialRoute: AppRoutes.splash,
            onGenerateRoute: _onGenerateRoute,
            builder: (context, child) {
              // تثبیت اندازه‌ی فونت متن‌ها؛ کاربر می‌تواند از تنظیمات
              // سیستم بزرگ‌ترش کند اما چیدمان اپ به‌هم نمی‌ریزد.
              final media = MediaQuery.of(context);
              final scale = media.textScaler.clamp(
                minScaleFactor: 0.9,
                maxScaleFactor: 1.3,
              );
              return MediaQuery(
                data: media.copyWith(textScaler: scale),
                child: child ?? const SizedBox.shrink(),
              );
            },
          );
        },
      ),
    );
  }

  static ThemeMode _themeModeOf(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.system:
        return ThemeMode.system;
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
    }
  }

  /// مسیرهای نام‌دار اپ.
  ///
  /// صفحه‌های جریانی (مثل جلسه‌ی مطالعه) مستقیم و با آرگومان ساخته می‌شوند؛
  /// این نقشه برای پرش‌های ساده و لینک‌های داخلی است.
  static Route<dynamic>? _onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.splash:
        return AppRouter.instant((_) => const SplashScreen());
      case AppRoutes.onboarding:
        return AppRouter.build(builder: (_) => const OnboardingScreen());
      case AppRoutes.placement:
        final args = readArgs<PlacementArgs>(settings) ?? const PlacementArgs();
        return AppRouter.build(builder: (_) => PlacementScreen(args: args));
      case AppRoutes.shell:
        return AppRouter.instant(
          (_) => HomeShell(initialIndex: readArgs<int>(settings) ?? 0),
        );
      case AppRoutes.learn:
        final args = readArgs<LearnArgs>(settings);
        if (args == null) return null;
        return AppRouter.build(builder: (_) => LearnScreen(args: args));
      case AppRoutes.quiz:
        final args = readArgs<QuizArgs>(settings);
        if (args == null) return null;
        return AppRouter.build(builder: (_) => QuizScreen(args: args));
      case AppRoutes.wordDetail:
        final args = readArgs<WordDetailArgs>(settings);
        if (args == null) return null;
        return AppRouter.build(builder: (_) => WordDetailScreen(args: args));
      case AppRoutes.wordList:
        final args = readArgs<WordListArgs>(settings) ??
            const WordListArgs(title: S.allWords);
        return AppRouter.build(builder: (_) => WordListScreen(args: args));
      case AppRoutes.pack:
        final args = readArgs<PackArgs>(settings);
        if (args == null) return null;
        return AppRouter.build(builder: (_) => PackDetailScreen(args: args));
      case AppRoutes.achievements:
        return AppRouter.build(builder: (_) => const AchievementsScreen());
      case AppRoutes.chat:
        return AppRouter.build(builder: (_) => const ChatScreen());
      case AppRoutes.paywall:
        return AppRouter.build(builder: (_) => const PaywallScreen());
      case AppRoutes.settings:
        return AppRouter.build(builder: (_) => const SettingsScreen());
      case AppRoutes.challenge:
        final plan = readArgs<SessionPlan>(settings);
        if (plan == null) return null;
        return AppRouter.build(builder: (_) => ChallengeScreen(plan: plan));
      default:
        return AppRouter.build(builder: (_) => const _NotFoundScreen());
    }
  }
}

/// صفحه‌ی جایگزین برای مسیرهای ناشناس.
class _NotFoundScreen extends StatelessWidget {
  const _NotFoundScreen();

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'صفحه پیدا نشد',
      showBack: true,
      body: EmptyStateView(
        title: 'این مسیر وجود ندارد',
        message: 'به صفحه‌ی اصلی برگرد و ادامه بده.',
        emoji: '🧭',
        actionLabel: S.continueLabel,
        onAction: () => Navigator.of(context).maybePop(),
      ),
    );
  }
}
