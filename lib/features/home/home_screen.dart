import 'package:flutter/material.dart';

import '../../core/di/app_container.dart';
import '../../core/routing/app_router.dart';
import '../../core/state/value_store.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_palette.dart';
import '../../core/utils/fa_format.dart';
import '../../domain/engines/session_builder.dart';
import '../../domain/engines/stats_engine.dart';
import '../../domain/entities/word.dart';
import '../../l10n/strings.dart';
import '../../widgets/ad_slot.dart';
import '../../widgets/animations.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/badges.dart';
import '../../widgets/progress_views.dart';
import '../../widgets/states.dart';
import '../../widgets/word_tile.dart';
import '../achievements/achievements_screen.dart';
import '../challenge/challenge_screen.dart';
import '../chat/chat_screen.dart';
import '../paywall/paywall_screen.dart';
import '../quiz/quiz_screen.dart';
import '../review/learn_screen.dart';
import '../settings/settings_screen.dart';
import '../word_detail/word_detail_screen.dart';

/// خانه‌ی اپ: خلاصه‌ی امروز، برنامه‌ی مطالعه و میان‌برهای مهم.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.onOpenTab});

  /// تعویض تب از داخل خانه (۰: خانه، ۱: یادگیری، ۲: کاوش، ۳: پیشرفت، ۴: پروفایل).
  final ValueChanged<int> onOpenTab;

  @override
  Widget build(BuildContext context) {
    final container = AppScope.of(context);
    final controller = container.controller;

    return Watch(
      listenables: <Listenable>[
        container.stores.statesStore,
        container.stores.xpStore,
        container.stores.streakStore,
        container.stores.sessionsStore,
        container.stores.profileStore,
        container.stores.settingsStore,
        container.stores.challengeStore,
        container.stores.subscriptionStore,
        container.stores.wordsStore,
      ],
      builder: (context) {
        final profile = controller.profile;
        final stats = controller.stats;
        final xp = container.stores.xpStore.value;
        final level = controller.appLevel;
        final dueCount = controller.dueCount;
        final reviewPlan = controller.reviewPlan;
        final learnPlan = controller.learnPlan;
        final challengePlan = controller.challengePlan;
        final wordOfDay = controller.wordOfTheDay;
        final goalPercent = xp.dailyXp == 0
            ? 0
            : ((xp.dailyXp / (controller.settings.dailyGoalMinutes * 8).clamp(40, 2000)) *
                    100)
                .clamp(0, 100)
                .round();

        return AppScaffold(
          padding: EdgeInsets.zero,
          body: ListView(
            padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
            children: <Widget>[
              _HomeHeader(
                name: profile.name,
                initial: profile.initial,
                streakDays: container.stores.streakStore.value.current,
                level: level.title,
                levelEmoji: level.emoji,
                xpToday: xp.dailyXp,
                onProfile: () => onOpenTab(4),
                onAchievements: () => Navigator.of(context).push(
                  AppRouter.build<void>(
                    settings: const RouteSettings(name: AppRoutes.achievements),
                    builder: (_) => const AchievementsScreen(),
                  ),
                ),
              ),
              Transform.translate(
                offset: const Offset(0, -AppSpacing.lg),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: Column(
                    children: <Widget>[
                      _DailyGoalCard(
                        percent: goalPercent,
                        xpToday: xp.dailyXp,
                        goalMinutes: controller.settings.dailyGoalMinutes,
                        goalCards: controller.settings.dailyGoalCards,
                        reviewedToday: stats.todayReviews,
                        onTap: () => onOpenTab(3),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _TodayPlanCard(
                        dueCount: dueCount,
                        newWords: learnPlan.wordCount,
                        challengeReady: !controller.isChallengeCompletedToday,
                        onReview: reviewPlan.isEmpty
                            ? null
                            : () => Navigator.of(context).push(
                                  AppRouter.build<void>(
                                    settings:
                                        const RouteSettings(name: AppRoutes.learn),
                                    builder: (_) => LearnScreen(
                                      args: LearnArgs(
                                        kind: reviewPlan.kind,
                                        words: reviewPlan.words,
                                        title: reviewPlan.title,
                                        subtitle: reviewPlan.subtitle,
                                      ),
                                    ),
                                  ),
                                ),
                        onLearn: learnPlan.isEmpty
                            ? null
                            : () => Navigator.of(context).push(
                                  AppRouter.build<void>(
                                    settings:
                                        const RouteSettings(name: AppRoutes.learn),
                                    builder: (_) => LearnScreen(
                                      args: LearnArgs(
                                        kind: learnPlan.kind,
                                        words: learnPlan.words,
                                        title: learnPlan.title,
                                        subtitle: learnPlan.subtitle,
                                      ),
                                    ),
                                  ),
                                ),
                        onChallenge: challengePlan.isEmpty
                            ? null
                            : () => Navigator.of(context).push(
                                  AppRouter.build<void>(
                                    settings: const RouteSettings(
                                      name: AppRoutes.challenge,
                                    ),
                                    builder: (_) =>
                                        ChallengeScreen(plan: challengePlan),
                                  ),
                                ),
                      ),
                      if (_streakAtRisk(container))
                        const SizedBox(height: AppSpacing.sm),
                      if (_streakAtRisk(container))
                        InfoBanner(
                          text: 'زنجیره‌ی ${FaFormat.digits(container.stores.streakStore.value.current)} روزه‌ات در خطره! '
                              'با یک جلسه‌ی کوتاه امروز حفظش کن.',
                          icon: Icons.local_fire_department_rounded,
                          color: AppColors.danger,
                          actionLabel: S.startReview,
                          onTap: reviewPlan.isEmpty
                              ? null
                              : () => onOpenTab(1),
                        ),
                      const SizedBox(height: AppSpacing.md),
                      SectionHeader(
                        title: S.quickActions,
                        icon: Icons.bolt_rounded,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      _QuickActions(
                        onReview: () => onOpenTab(1),
                        onQuiz: () => _openMixedQuiz(context, reviewPlan, learnPlan),
                        onChat: () => Navigator.of(context).push(
                          AppRouter.build<void>(
                            settings: const RouteSettings(name: AppRoutes.chat),
                            builder: (_) => const ChatScreen(),
                          ),
                        ),
                        onExplore: () => onOpenTab(2),
                        onAchievements: () => Navigator.of(context).push(
                          AppRouter.build<void>(
                            settings:
                                const RouteSettings(name: AppRoutes.achievements),
                            builder: (_) => const AchievementsScreen(),
                          ),
                        ),
                        onSettings: () => Navigator.of(context).push(
                          AppRouter.build<void>(
                            settings: const RouteSettings(name: AppRoutes.settings),
                            builder: (_) => const SettingsScreen(),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      if (wordOfDay != null) ...<Widget>[
                        SectionHeader(
                          title: S.wordOfTheDay,
                          subtitle: 'هر روز یک واژه‌ی تازه برای کشف',
                          icon: Icons.auto_awesome_rounded,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        _WordOfDayCard(word: wordOfDay),
                        const SizedBox(height: AppSpacing.md),
                      ],
                      _StatsRow(
                        wordsStarted: stats.wordsStarted,
                        reviewedToday: stats.todayReviews,
                        accuracy: stats.totalReviews == 0
                            ? 0
                            : stats.totalCorrect / stats.totalReviews,
                        streak: container.stores.streakStore.value.current,
                        onTap: () => onOpenTab(3),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _WeeklyActivityCard(activities: stats.last30Days),
                      const SizedBox(height: AppSpacing.md),
                      if (!controller.hasPremium) ...<Widget>[
                        PremiumBanner(
                          title: 'نسخه‌ی ویژه',
                          subtitle: 'واژه‌های سطح بالا، تمرین‌های نامحدود و بدون تبلیغ.',
                          onTap: () => Navigator.of(context).push(
                            AppRouter.build<void>(
                              settings:
                                  const RouteSettings(name: AppRoutes.paywall),
                              builder: (_) => const PaywallScreen(),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        const AdSlot(placement: 'home_footer'),
                      ],
                      const SizedBox(height: AppSpacing.md),
                      _ReviewReminder(dueCount: dueCount, reviewedToday: stats.todayReviews),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static bool _streakAtRisk(AppContainer container) {
    final streak = container.stores.streakStore.value;
    if (streak.current <= 0) return false;
    return streak.lastStudyDayKey != container.clock.studyDayKey();
  }

  void _openMixedQuiz(
    BuildContext context,
    SessionPlan reviewPlan,
    SessionPlan learnPlan,
  ) {
    final words = reviewPlan.words.isNotEmpty ? reviewPlan.words : learnPlan.words;
    if (words.isEmpty) {
      showToast(context, 'اول چند واژه یاد بگیر تا تمرین بسازم.');
      return;
    }
    Navigator.of(context).push(
      AppRouter.build<void>(
        settings: const RouteSettings(name: AppRoutes.quiz),
        builder: (_) => QuizLauncherScreen(words: words),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.name,
    required this.initial,
    required this.streakDays,
    required this.level,
    required this.levelEmoji,
    required this.xpToday,
    required this.onProfile,
    required this.onAchievements,
  });

  final String name;
  final String initial;
  final int streakDays;
  final String level;
  final String levelEmoji;
  final int xpToday;
  final VoidCallback onProfile;
  final VoidCallback onAchievements;

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 5) return 'شب بخیر';
    if (hour < 12) return 'صبح بخیر';
    if (hour < 17) return 'ظهر بخیر';
    if (hour < 21) return 'عصر بخیر';
    return 'شب بخیر';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        MediaQuery.of(context).padding.top + AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.xxl,
      ),
      decoration: const BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(AppRadius.xl),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              ScaleTap(
                onTap: onProfile,
                child: Container(
                  width: AppSizes.avatar,
                  height: AppSizes.avatar,
                  decoration: BoxDecoration(
                    color: Colors.white.fade(0.22),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.fade(0.5), width: 1.6),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    initial,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      '$_greeting،',
                      style: TextStyle(
                        color: Colors.white.fade(0.85),
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              ScaleTap(
                onTap: onAchievements,
                child: Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: Colors.white.fade(0.18),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: const Icon(
                    Icons.emoji_events_rounded,
                    color: Colors.white,
                    size: 21,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: <Widget>[
              _HeaderChip(
                emoji: '🔥',
                value: FaFormat.digits(streakDays),
                label: 'روز پیاپی',
              ),
              const SizedBox(width: AppSpacing.xs),
              _HeaderChip(
                emoji: levelEmoji,
                value: level,
                label: S.levelLabel,
              ),
              const SizedBox(width: AppSpacing.xs),
              _HeaderChip(
                emoji: '⚡',
                value: FaFormat.digits(xpToday),
                label: 'امتیاز امروز',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderChip extends StatelessWidget {
  const _HeaderChip({
    required this.emoji,
    required this.value,
    required this.label,
  });

  final String emoji;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs, horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.white.fade(0.16),
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Column(
          children: <Widget>[
            Text(emoji, style: const TextStyle(fontSize: 15)),
            const SizedBox(height: 2),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.white.fade(0.85), fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}

class _DailyGoalCard extends StatelessWidget {
  const _DailyGoalCard({
    required this.percent,
    required this.xpToday,
    required this.goalMinutes,
    required this.goalCards,
    required this.reviewedToday,
    required this.onTap,
  });

  final int percent;
  final int xpToday;
  final int goalMinutes;
  final int goalCards;
  final int reviewedToday;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return AppCard(
      onTap: onTap,
      elevated: true,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: <Widget>[
          ProgressRing(
            progress: percent / 100,
            size: 74,
            strokeWidth: 8,
            center: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  FaFormat.percent(percent),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: palette.textPrimary,
                  ),
                ),
                Text(
                  'هدف',
                  style: TextStyle(fontSize: 9, color: palette.textTertiary),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  S.dailyGoal,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: palette.textPrimary,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${FaFormat.digits(goalCards)} کارت ≈ ${FaFormat.digits(goalMinutes)} دقیقه مطالعه',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: palette.textTertiary,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  xpToday >= goalCards * 8
                      ? 'هدف امروز کامل شد! 🎉'
                      : '${FaFormat.digits(xpToday)} از ${FaFormat.digits(goalCards * 8)} امتیاز • '
                          '${FaFormat.digits(reviewedToday)} مرور امروز',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: xpToday >= goalCards * 8
                            ? palette.success
                            : palette.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TodayPlanCard extends StatelessWidget {
  const _TodayPlanCard({
    required this.dueCount,
    required this.newWords,
    required this.challengeReady,
    required this.onReview,
    required this.onLearn,
    required this.onChallenge,
  });

  final int dueCount;
  final int newWords;
  final bool challengeReady;
  final VoidCallback? onReview;
  final VoidCallback? onLearn;
  final VoidCallback? onChallenge;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SectionHeader(
            title: S.todayPlan,
            icon: Icons.event_available_rounded,
          ),
          const SizedBox(height: AppSpacing.xs),
          _PlanRow(
            icon: Icons.autorenew_rounded,
            color: AppColors.brand,
            title: S.dueReviews,
            subtitle: dueCount > 0
                ? '${FaFormat.digits(dueCount)} واژه منتظر مرور است'
                : 'همه‌ی مرورهای امروز انجام شد',
            done: dueCount == 0,
            actionLabel: dueCount > 0 ? S.startReview : null,
            onAction: onReview,
          ),
          const SizedBox(height: AppSpacing.xs),
          _PlanRow(
            icon: Icons.eco_rounded,
            color: AppColors.accent,
            title: S.newWords,
            subtitle: newWords > 0
                ? '${FaFormat.digits(newWords)} واژه‌ی تازه در سطح تو'
                : 'واژه‌ی تازه‌ای نمانده؛ فردا سر بزن',
            done: newWords == 0,
            actionLabel: newWords > 0 ? S.startLearn : null,
            onAction: onLearn,
          ),
          const SizedBox(height: AppSpacing.xs),
          _PlanRow(
            icon: Icons.local_fire_department_rounded,
            color: AppColors.gold,
            title: S.dailyChallenge,
            subtitle: challengeReady
                ? '۱۰ سؤال ترکیبی + پاداش دوبرابر'
                : S.challengeCompleted,
            done: !challengeReady,
            actionLabel: challengeReady ? S.challengeStart : null,
            onAction: onChallenge,
          ),
          if (dueCount == 0 && newWords == 0 && !challengeReady) ...<Widget>[
            const SizedBox(height: AppSpacing.sm),
            Text(
              S.allCaughtUp,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: palette.success,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PlanRow extends StatelessWidget {
  const _PlanRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.done,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final bool done;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Row(
      children: <Widget>[
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: color.fade(0.14),
            borderRadius: BorderRadius.circular(AppRadius.xs),
          ),
          child: Icon(done ? Icons.check_rounded : icon, color: color, size: 20),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: palette.textPrimary,
                    ),
              ),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: palette.textTertiary,
                    ),
              ),
            ],
          ),
        ),
        if (actionLabel != null)
          AppButton(
            label: actionLabel!,
            expanded: false,
            height: 36,
            compact: true,
            variant: AppButtonVariant.secondary,
            onPressed: onAction,
          ),
      ],
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({
    required this.onReview,
    required this.onQuiz,
    required this.onChat,
    required this.onExplore,
    required this.onAchievements,
    required this.onSettings,
  });

  final VoidCallback onReview;
  final VoidCallback onQuiz;
  final VoidCallback onChat;
  final VoidCallback onExplore;
  final VoidCallback onAchievements;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final items = <(IconData, String, Color, VoidCallback)>[
      (Icons.autorenew_rounded, 'مرور هوشمند', AppColors.brand, onReview),
      (Icons.quiz_rounded, 'تمرین ترکیبی', AppColors.info, onQuiz),
      (Icons.chat_bubble_outline_rounded, 'معلم هوشمند', AppColors.accent, onChat),
      (Icons.category_rounded, 'بسته‌های موضوعی', AppColors.pink, onExplore),
      (Icons.emoji_events_rounded, 'دستاوردها', AppColors.gold, onAchievements),
      (Icons.settings_rounded, 'تنظیمات', AppColors.brandDark, onSettings),
    ];
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppSpacing.xs,
      crossAxisSpacing: AppSpacing.xs,
      childAspectRatio: 0.95,
      children: <Widget>[
        for (final item in items)
          AppCard(
            onTap: item.$4,
            padding: const EdgeInsets.all(AppSpacing.xs),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: item.$3.fade(0.14),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Icon(item.$1, color: item.$3, size: 21),
                ),
                const SizedBox(height: 6),
                Text(
                  item.$2,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppPalette.of(context).textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _WordOfDayCard extends StatelessWidget {
  const _WordOfDayCard({required this.word});

  final Word word;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.sm),
      onTap: () => Navigator.of(context).push(
        AppRouter.build<void>(
          settings: const RouteSettings(name: AppRoutes.wordDetail),
          builder: (_) => WordDetailScreen(args: WordDetailArgs(word: word)),
        ),
      ),
      child: Row(
        children: <Widget>[
          WordImage(word: word, size: 62),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Flexible(
                      child: Text(
                        word.term,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: palette.textPrimary,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    CefrBadge(
                      code: word.level.code,
                      title: word.level.faTitle,
                      dense: true,
                    ),
                  ],
                ),
                if (word.ipa != null)
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: Text(
                      word.ipa!,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: palette.textTertiary,
                          ),
                    ),
                  ),
                const SizedBox(height: 2),
                Text(
                  word.faMeanings.join('، '),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: palette.textSecondary,
                      ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_left_rounded, color: palette.textTertiary),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.wordsStarted,
    required this.reviewedToday,
    required this.accuracy,
    required this.streak,
    required this.onTap,
  });

  final int wordsStarted;
  final int reviewedToday;
  final double accuracy;
  final int streak;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return AppCard(
      onTap: onTap,
      child: Row(
        children: <Widget>[
          Expanded(
            child: StatTile(
              value: FaFormat.digits(wordsStarted),
              label: S.wordsLearned,
              icon: Icons.menu_book_rounded,
              compact: true,
            ),
          ),
          Expanded(
            child: StatTile(
              value: FaFormat.digits(reviewedToday),
              label: 'مرور امروز',
              icon: Icons.today_rounded,
              color: palette.info,
              compact: true,
            ),
          ),
          Expanded(
            child: StatTile(
              value: FaFormat.percent(accuracy * 100),
              label: S.accuracyLabel,
              icon: Icons.percent_rounded,
              color: palette.success,
              compact: true,
            ),
          ),
          Expanded(
            child: StatTile(
              value: FaFormat.digits(streak),
              label: S.streakLabel,
              icon: Icons.local_fire_department_rounded,
              color: AppColors.gold,
              compact: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _WeeklyActivityCard extends StatelessWidget {
  const _WeeklyActivityCard({required this.activities});

  final List<DailyActivity> activities;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final last7 = activities.length <= 7
        ? activities
        : activities.sublist(activities.length - 7);
    final values = <double>[
      for (final activity in last7) activity.reviews.toDouble(),
    ];
    final labels = <String>[
      for (final activity in last7) FaFormat.digits(activity.date.day),
    ];
    final total = last7.fold<int>(0, (sum, item) => sum + item.reviews);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SectionHeader(
            title: S.weeklyActivity,
            subtitle: '${FaFormat.digits(total)} مرور در ۷ روز گذشته',
            icon: Icons.bar_chart_rounded,
          ),
          const SizedBox(height: AppSpacing.xs),
          if (values.isEmpty || total == 0)
            Text(
              'هنوز فعالیتی ثبت نشده؛ امروز شروع کن!',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: palette.textTertiary,
                  ),
            )
          else
            MiniBarChart(
              values: values,
              labels: labels,
              color: AppColors.brand,
              height: 96,
              highlightIndex: values.length - 1,
            ),
        ],
      ),
    );
  }
}

class _ReviewReminder extends StatelessWidget {
  const _ReviewReminder({required this.dueCount, required this.reviewedToday});

  final int dueCount;
  final int reviewedToday;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    if (dueCount > 0) {
      return InfoBanner(
        text: '${FaFormat.digits(dueCount)} واژه امروز سررسید شده‌اند. '
            'مرور کوتاه حالا، فردا یادآوری را آسان‌تر می‌کند.',
        icon: Icons.schedule_rounded,
        color: AppColors.brand,
      );
    }
    if (reviewedToday > 0) {
      return InfoBanner(
        text: 'کار امروزت تمام شد! فردا واژه‌های تازه‌ای منتظرت هستند 🌙',
        icon: Icons.nightlight_round,
        color: palette.success,
      );
    }
    return InfoBanner(
      text: 'امروز هنوز شروع نکردی. ۵ دقیقه هم کافی است تا زنجیره‌ات زنده بماند.',
      icon: Icons.tips_and_updates_rounded,
      color: AppColors.gold,
    );
  }
}
