import 'package:flutter/material.dart';

import '../../domain/entities/quiz_question.dart';
import '../../domain/entities/study_session.dart';
import '../../domain/entities/word.dart';

/// نام مسیرهای اپلیکیشن.
class AppRoutes {
  const AppRoutes._();

  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String placement = '/placement';
  static const String shell = '/shell';
  static const String wordDetail = '/word';
  static const String learn = '/learn';
  static const String quiz = '/quiz';
  static const String achievements = '/achievements';
  static const String chat = '/chat';
  static const String paywall = '/paywall';
  static const String settings = '/settings';
  static const String wordList = '/list';
  static const String pack = '/pack';
  static const String challenge = '/challenge';
}

/// آرگومان‌های مسیر جلسه‌ی یادگیری/مرور.
class LearnArgs {
  const LearnArgs({
    required this.kind,
    this.words,
    this.title,
    this.subtitle,
    this.isChallenge = false,
  });

  final SessionKind kind;
  final List<Word>? words;
  final String? title;
  final String? subtitle;
  final bool isChallenge;
}

/// آرگومان‌های مسیر تمرین.
class QuizArgs {
  const QuizArgs({
    required this.words,
    this.kind = SessionKind.quiz,
    this.isChallenge = false,
    this.forcedType,
    this.title,
    this.precomputedQuestions,
  });

  final List<Word> words;
  final SessionKind kind;
  final bool isChallenge;
  final QuizType? forcedType;
  final String? title;
  final List<QuizQuestion>? precomputedQuestions;
}

/// آرگومان‌های مسیر تعیین سطح.
class PlacementArgs {
  const PlacementArgs({this.retake = false});

  final bool retake;
}

/// آرگومان‌های مسیر فهرست واژه‌ها.
class WordListArgs {
  const WordListArgs({
    required this.title,
    this.subtitle,
    this.words,
    this.wordIds,
    this.initialLevel,
    this.showFilters = true,
  });

  final String title;
  final String? subtitle;

  /// فهرست آماده (مثلاً واژه‌های یک بسته).
  final List<Word>? words;

  /// شناسه‌های واژه‌ها (مثلاً واژه‌های یک بسته).
  final List<String>? wordIds;

  final String? initialLevel;
  final bool showFilters;
}

/// آرگومان‌های مسیر جزئیات واژه.
class WordDetailArgs {
  const WordDetailArgs({required this.word, this.highlighted = false});

  final Word word;

  /// آیا از جلسه‌ی مطالعه آمده‌ایم؟ (برای نمایش بازگشت به جلسه)
  final bool highlighted;
}

/// ساخت گذرهای صفحه با انیمیشن نرم و یکدست.
class AppRouter {
  const AppRouter._();

  static Route<T> build<T>({
    required WidgetBuilder builder,
    RouteSettings? settings,
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      transitionDuration: const Duration(milliseconds: 300),
      reverseTransitionDuration: const Duration(milliseconds: 240),
      pageBuilder: (context, animation, secondaryAnimation) => builder(context),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(-0.04, 0),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  /// گذر بدون انیمیشن (برای تعویض تب‌ها یا بازگشت به خانه).
  static Route<T> instant<T>(WidgetBuilder builder) => PageRouteBuilder<T>(
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
        pageBuilder: (context, animation, secondaryAnimation) => builder(context),
      );
}

/// خواندن امن آرگومان‌های مسیر.
T? readArgs<T>(RouteSettings? settings) {
  final args = settings?.arguments;
  if (args is T) return args;
  return null;
}
