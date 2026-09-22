import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../domain/entities/achievement.dart';
import '../domain/entities/cefr_level.dart';
import '../domain/entities/part_of_speech.dart';
import '../domain/entities/quiz_question.dart';
import '../domain/entities/review_state.dart';
import '../domain/entities/settings.dart';
import '../domain/entities/study_session.dart';
import '../domain/entities/subscription.dart';
import '../domain/entities/word.dart';
import 'strings.dart';

/// برچسب‌های فارسی مشترک.
///
/// همه‌ی متن‌های کوتاه رابط کاربری در `strings.dart` و برچسب‌های
/// وابسته به داده (سطح، نقش دستوری، وضعیت یادگیری…) این‌جا متمرکز شده‌اند
/// تا هیچ متن انگلیسی/تکراری داخل ویجت‌ها پخش نشود.
extension WordStatusLabel on WordStatus {
  String get faLabel {
    switch (this) {
      case WordStatus.fresh:
        return S.statusNew;
      case WordStatus.learning:
        return S.statusLearning;
      case WordStatus.reviewing:
        return S.statusReviewing;
      case WordStatus.mastered:
        return S.statusMastered;
      case WordStatus.leech:
        return S.statusLeech;
    }
  }

  int get rank {
    switch (this) {
      case WordStatus.fresh:
        return 0;
      case WordStatus.learning:
        return 1;
      case WordStatus.reviewing:
        return 2;
      case WordStatus.mastered:
        return 3;
      case WordStatus.leech:
        return 4;
    }
  }
}

/// رنگ هر وضعیت یادگیری (برای نشان‌ها و نمودارها).
extension WordStatusColor on WordStatus {
  int get colorValue {
    switch (this) {
      case WordStatus.fresh:
        return 0xFF8B91A7;
      case WordStatus.learning:
        return 0xFFF79009;
      case WordStatus.reviewing:
        return 0xFF2E90FA;
      case WordStatus.mastered:
        return 0xFF17B26A;
      case WordStatus.leech:
        return 0xFFF04438;
    }
  }
}

extension PartOfSpeechLabel on PartOfSpeech {
  /// آیا این نقش دستوری نیاز به توضیح بیشتری برای فارسی‌زبان‌ها دارد؟
  bool get trickyForPersian =>
      this == PartOfSpeech.phrasalVerb || this == PartOfSpeech.idiom;
}

extension CefrLabel on CefrLevel {
  /// رنگ اختصاصی هر سطح CEFR.
  Color get color => switch (this) {
        CefrLevel.a1 => AppColors.accent,
        CefrLevel.a2 => AppColors.info,
        CefrLevel.b1 => AppColors.brand,
        CefrLevel.b2 => AppColors.pink,
        CefrLevel.c1 => AppColors.gold,
        CefrLevel.c2 => AppColors.brandDark,
      };
}

extension QuizTypeLabel on QuizType {
  String get faLabel => faTitle;

  /// راهنمای کوتاه «چرا این تمرین؟» برای صفحه‌ی انتخاب تمرین.
  String get hintFa {
    switch (this) {
      case QuizType.meaningChoice:
        return 'سرعت تشخیص معنی را بالا می‌برد';
      case QuizType.wordChoice:
        return 'بازیابی فعال واژه از حافظه';
      case QuizType.fillBlank:
        return 'کاربرد واژه در جمله را تثبیت می‌کند';
      case QuizType.typeMeaning:
        return 'عمیق‌ترین نوع تمرین برای معنی';
      case QuizType.typeWord:
        return 'املای واژه را حرفه‌ای می‌کند';
      case QuizType.listening:
        return 'گوش را برای مکالمه آماده می‌کند';
      case QuizType.sentenceBuild:
        return 'ساختار جمله را ملکه‌ی ذهن می‌کند';
      case QuizType.collocation:
        return 'ترکیب‌های طبیعی زبان را یاد می‌دهد';
      case QuizType.synonym:
        return 'دامنه‌ی واژگان را گسترش می‌دهد';
      case QuizType.antonym:
        return 'تفاوت‌های ظریف معنی را روشن می‌کند';
    }
  }
}

extension SessionKindLabel on SessionKind {
  String get faLabel => faTitle;
}

extension ExampleKindLabel on ExampleKind {
  String get faLabel {
    switch (this) {
      case ExampleKind.general:
        return 'مثال کاربردی';
      case ExampleKind.conversation:
        return S.conversationSection;
      case ExampleKind.media:
        return S.mediaSection;
      case ExampleKind.formal:
        return 'کاربرد رسمی';
    }
  }
}

extension AchievementMetricLabel on AchievementMetric {
  String get faLabel => faTitle;

  /// واحد نمایش پیشرفت (برای نوار پیشرفت در صفحه‌ی دستاوردها).
  String get unitFa {
    switch (this) {
      case AchievementMetric.wordsStarted:
        return 'واژه';
      case AchievementMetric.wordsMastered:
        return 'واژه‌ی مسلط';
      case AchievementMetric.reviewsDone:
      case AchievementMetric.correctAnswers:
        return 'مرور';
      case AchievementMetric.streakDays:
        return 'روز';
      case AchievementMetric.totalXp:
        return 'امتیاز';
      case AchievementMetric.challengesDone:
        return 'چالش';
      case AchievementMetric.perfectSessions:
        return 'جلسه';
      case AchievementMetric.listeningCorrect:
      case AchievementMetric.typingCorrect:
      case AchievementMetric.sentenceCorrect:
        return 'پاسخ درست';
      case AchievementMetric.bookmarkedWords:
        return 'واژه';
      case AchievementMetric.aiChatMessages:
        return 'پیام';
      case AchievementMetric.levelReached:
        return 'سطح';
      case AchievementMetric.wordsInOneDay:
        return 'واژه در یک روز';
      case AchievementMetric.studyMinutes:
        return 'دقیقه';
    }
  }
}

extension SubscriptionTierLabel on SubscriptionTier {
  String get faLabel {
    switch (this) {
      case SubscriptionTier.free:
        return S.subscriptionFree;
      case SubscriptionTier.trial:
        return 'دوره‌ی آزمایشی';
      case SubscriptionTier.premium:
        return S.subscriptionPremium;
    }
  }
}

extension AppThemeModeLabel on AppThemeMode {
  String get faLabel {
    switch (this) {
      case AppThemeMode.system:
        return S.themeSystem;
      case AppThemeMode.light:
        return S.themeLight;
      case AppThemeMode.dark:
        return S.themeDark;
    }
  }
}

extension WordLevelLabel on CefrLevel {
  String get shortFa => '${code} • $faTitle';
}
