import 'package:flutter/material.dart';

import '../../core/di/app_container.dart';
import '../../core/routing/app_router.dart';
import '../../core/state/value_store.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_palette.dart';
import '../../core/utils/fa_format.dart';
import '../../core/utils/jalali_date.dart';
import '../../domain/engines/session_builder.dart';
import '../../domain/engines/stats_engine.dart';
import '../../domain/engines/xp_engine.dart';
import '../../domain/engines/weakness_engine.dart';
import '../../domain/entities/progress.dart';
import '../../domain/entities/study_session.dart';
import '../../l10n/labels.dart';
import '../../l10n/strings.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/progress_views.dart';
import '../../widgets/states.dart';
import '../achievements/achievements_screen.dart';
import '../review/learn_screen.dart';

/// پیشرفت: آمار، نمودارها، زنجیره و تحلیل نقاط ضعف.
class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final container = AppScope.of(context);
    final controller = container.controller;

    return Watch(
      listenables: <Listenable>[
        container.stores.statesStore,
        container.stores.sessionsStore,
        container.stores.xpStore,
        container.stores.streakStore,
        container.stores.weaknessStore,
        container.stores.achievementsStore,
      ],
      builder: (context) {
        final stats = controller.stats;
        final xp = container.stores.xpStore.value;
        final streak = container.stores.streakStore.value;
        final level = controller.appLevel;
        final weakness = controller.weakness;
        final unlocked = container.stores.achievementsStore.value.values
            .where((progress) => progress.isUnlocked)
            .length;
        final weaknessPlan = controller.weakPlan;

        return AppScaffold(
          title: S.progressTitle,
          subtitle: 'مسیر یادگیری‌ات را این‌جا ببین',
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          body: ListView(
            padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
            children: <Widget>[
              _LevelCard(level: level, xp: xp),
              const SizedBox(height: AppSpacing.md),
              _StreakCard(streak: streak, activities: stats.last30Days),
              const SizedBox(height: AppSpacing.md),
              _StatGrid(stats: stats),
              const SizedBox(height: AppSpacing.md),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    SectionHeader(
                      title: S.accuracyTrend,
                      subtitle: 'دقت پاسخ‌های تو در ۱۴ روز گذشته',
                      icon: Icons.show_chart_rounded,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    SparkLineChart(
                      values: stats.accuracyTrend.isEmpty
                          ? const <double>[0, 0]
                          : stats.accuracyTrend,
                      height: 110,
                      color: AppColors.accent,
                      showAverage: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    SectionHeader(
                      title: S.masteryDistribution,
                      subtitle: 'واژه‌ها در چه مرحله‌ای از تسلط‌اند؟',
                      icon: Icons.donut_small_rounded,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    MasteryDistributionBar(buckets: stats.masteryBuckets),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    SectionHeader(
                      title: S.activityHeatmap,
                      subtitle: '${FaFormat.digits(stats.activeDays)} روز فعال از ۳۰ روز گذشته',
                      icon: Icons.grid_view_rounded,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    ActivityHeatmap(
                      counts: <int>[
                        for (final day in stats.last30Days) day.reviews,
                      ],
                      days: 30,
                      color: AppColors.brand,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _WeaknessCard(report: weakness, plan: weaknessPlan),
              const SizedBox(height: AppSpacing.md),
              AppCard(
                onTap: () => Navigator.of(context).push(
                  AppRouter.build<void>(
                    settings: const RouteSettings(name: AppRoutes.achievements),
                    builder: (_) => const AchievementsScreen(),
                  ),
                ),
                child: Row(
                  children: <Widget>[
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        gradient: AppColors.goldGradient,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: const Icon(
                        Icons.emoji_events_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            S.achievementsTitle,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  color: AppPalette.of(context).textPrimary,
                                ),
                          ),
                          Text(
                            '${FaFormat.digits(unlocked)} نشان از '
                            '${FaFormat.digits(container.stores.achievementsStore.value.length)} باز شده',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: AppPalette.of(context).textTertiary,
                                ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_left_rounded),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _SessionHistory(sessions: container.stores.sessionsStore.value),
            ],
          ),
        );
      },
    );
  }
}

class _LevelCard extends StatelessWidget {
  const _LevelCard({required this.level, required this.xp});

  final AppLevel level;
  final XpState xp;

  @override
  Widget build(BuildContext context) {
    final progress = level.progress(xp.totalXp);
    return HighlightCard(
      gradient: AppColors.brandGradient,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: <Widget>[
          ProgressRing(
            progress: progress,
            size: 78,
            strokeWidth: 8,
            gradientColors: const <Color>[Colors.white, Color(0xFFD9D0FF)],
            trackColor: Colors.white.fade(0.25),
            center: Text(
              level.emoji,
              style: const TextStyle(fontSize: 26),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'سطح ${FaFormat.digits(level.index)} • ${level.title}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${FaFormat.digits(xp.totalXp)} امتیاز کل',
                  style: TextStyle(color: Colors.white.fade(0.9), fontSize: 12),
                ),
                const SizedBox(height: 2),
                Text(
                  '${FaFormat.digits(level.xpToNext(xp.totalXp))} امتیاز تا سطح بعد',
                  style: TextStyle(color: Colors.white.fade(0.8), fontSize: 11),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: Colors.white.fade(0.25),
                    color: Colors.white,
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

class _StreakCard extends StatelessWidget {
  const _StreakCard({required this.streak, required this.activities});

  final StreakState streak;
  final List<DailyActivity> activities;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final last7 = activities.length <= 7
        ? activities
        : activities.sublist(activities.length - 7);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Text('🔥', style: TextStyle(fontSize: 26)),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      '${FaFormat.digits(streak.current)} روز پیاپی',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: palette.textPrimary,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    Text(
                      'رکورد تو: ${FaFormat.digits(streak.best)} روز • '
                      '${FaFormat.digits(streak.totalStudyDays)} روز مطالعه‌ی کل',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: palette.textTertiary,
                          ),
                    ),
                  ],
                ),
              ),
              if (streak.freezesAvailable > 0)
                TagChip(
                  label: '${FaFormat.digits(streak.freezesAvailable)} محافظ زنجیره',
                  color: palette.info,
                  icon: Icons.shield_moon_rounded,
                  dense: true,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: <Widget>[
              for (final activity in last7)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Column(
                      children: <Widget>[
                        Container(
                          height: 26,
                          decoration: BoxDecoration(
                            color: activity.reviews > 0
                                ? AppColors.gold.fade(0.75)
                                : palette.surfaceAlt,
                            borderRadius: BorderRadius.circular(AppRadius.xs),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            activity.reviews > 0
                                ? FaFormat.digits(activity.reviews)
                                : '',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          JalaliDate.fromDateTime(activity.date).weekDayShortName,
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: palette.textTertiary,
                                fontSize: 9,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          if (streak.lastStudyDayKey ==
              AppScope.of(context).clock.studyDayKey()) ...<Widget>[
            const SizedBox(height: AppSpacing.xs),
            InfoBanner(
              text: 'امروز هم مطالعه کردی؛ زنجیره‌ات امن است ✅',
              icon: Icons.verified_rounded,
              color: palette.success,
            ),
          ],
        ],
      ),
    );
  }

}

class _StatGrid extends StatelessWidget {
  const _StatGrid({required this.stats});

  final ProgressStats stats;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final items = <(String, String, IconData, Color)>[
      (FaFormat.digits(stats.wordsStarted), S.wordsLearned, Icons.menu_book_rounded, AppColors.brand),
      (FaFormat.digits(stats.wordsMastered), S.wordsMastered, Icons.workspace_premium_rounded, palette.success),
      (FaFormat.digits(stats.totalReviews), S.totalReviews, Icons.repeat_rounded, palette.info),
      (FaFormat.digits(stats.totalMinutes), 'دقیقه مطالعه', Icons.timer_outlined, AppColors.gold),
      (FaFormat.percent(stats.accuracy * 100), S.accuracyLabel, Icons.percent_rounded, AppColors.accent),
      (FaFormat.digits(stats.totalSessions), 'جلسه‌ی کامل', Icons.event_available_rounded, AppColors.pink),
    ];
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppSpacing.xs,
      crossAxisSpacing: AppSpacing.xs,
      childAspectRatio: 1.05,
      children: <Widget>[
        for (final item in items)
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.xs),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(item.$3, color: item.$4, size: 20),
                const SizedBox(height: 4),
                Text(
                  item.$1,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: palette.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                Text(
                  item.$2,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: palette.textTertiary,
                        fontSize: 10,
                      ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// سه حوزه‌ی ضعیف‌تر (کمترین دقت) از میان حوزه‌هایی که داده‌ی کافی دارند.
List<AreaScore> _weakest(List<AreaScore> source) => source
    .where((area) => area.total >= 2)
    .toList(growable: false)
  ..sort((a, b) => a.accuracy.compareTo(b.accuracy));

/// فهرست میله‌ای حوزه‌های نیازمند تمرین (نقش دستوری یا موضوع).
class _AreaList extends StatelessWidget {
  const _AreaList({required this.title, required this.areas, this.labelOf});

  final String title;
  final List<AreaScore> areas;
  final String Function(String label)? labelOf;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: theme.textTheme.labelMedium?.copyWith(
            color: palette.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        for (final area in areas)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        labelOf?.call(area.label) ?? area.label,
                        style: theme.textTheme.labelMedium
                            ?.copyWith(color: palette.textPrimary),
                      ),
                    ),
                    Text(
                      '${FaFormat.percent(area.accuracy * 100)} '
                      '(${FaFormat.digits(area.correct)}/${FaFormat.digits(area.total)})',
                      style: theme.textTheme.labelSmall
                          ?.copyWith(color: palette.textTertiary),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                AppProgressBar(
                  progress: area.accuracy,
                  height: 6,
                  gradient: LinearGradient(
                    colors: <Color>[
                      area.accuracy < 0.6
                          ? palette.danger
                          : area.accuracy < 0.8
                              ? palette.warning
                              : palette.success,
                      area.accuracy < 0.6 ? palette.warning : palette.success,
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _WeaknessCard extends StatelessWidget {
  const _WeaknessCard({required this.report, required this.plan});

  final WeaknessReport report;
  final SessionPlan plan;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final areas = _weakest(report.byPartOfSpeech);
    final topics = _weakest(report.byTopic);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SectionHeader(
            title: S.weakWordsTitle,
            subtitle: S.weakWordsBody,
            icon: Icons.trending_down_rounded,
          ),
          const SizedBox(height: AppSpacing.xs),
          if (!report.hasData)
            Text(
              'برای تحلیل دقیق، چند جلسه‌ی تمرین لازم است. تا آن‌جا با خیال راحت تمرین کن!',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: palette.textTertiary,
                    height: 1.8,
                  ),
            )
          else ...<Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: StatTile(
                    value: FaFormat.percent(report.recentAccuracy * 100),
                    label: 'دقت ۷ روز اخیر',
                    icon: Icons.calendar_view_week_rounded,
                    color: palette.info,
                    compact: true,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: StatTile(
                    value: report.accuracyDelta >= 0
                        ? '+${FaFormat.percent(report.accuracyDelta * 100)}'
                        : FaFormat.percent(report.accuracyDelta * 100),
                    label: 'تغییر نسبت به هفته‌ی قبل',
                    icon: report.accuracyDelta >= 0
                        ? Icons.trending_up_rounded
                        : Icons.trending_down_rounded,
                    color: report.accuracyDelta >= 0
                        ? palette.success
                        : palette.danger,
                    compact: true,
                  ),
                ),
              ],
            ),
            if (areas.isNotEmpty) ...<Widget>[
              const SizedBox(height: AppSpacing.sm),
              _AreaList(
                title: 'حوزه‌های نیازمند تمرین',
                areas: areas.take(3).toList(growable: false),
              ),
            ],
            if (topics.isNotEmpty) ...<Widget>[
              const SizedBox(height: AppSpacing.sm),
              _AreaList(
                title: 'موضوع‌های نیازمند تمرین',
                areas: topics.take(3).toList(growable: false),
                labelOf: TopicLabels.fa,
              ),
            ],
            if (report.suggestions.isNotEmpty) ...<Widget>[
              const SizedBox(height: AppSpacing.xs),
              for (final suggestion in report.suggestions.take(2))
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Icon(
                        Icons.tips_and_updates_rounded,
                        size: 15,
                        color: AppColors.gold,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          suggestion,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: palette.textSecondary,
                                height: 1.7,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
            const SizedBox(height: AppSpacing.xs),
            AppButton(
              label: S.startWeakReview,
              icon: Icons.bolt_rounded,
              variant: AppButtonVariant.secondary,
              onPressed: () => _startWeak(context),
            ),
          ],
        ],
      ),
    );
  }

  void _startWeak(BuildContext context) {
    if (plan.isEmpty) {
      showToast(context, 'هنوز واژه‌ی ضعیفی برای تمرین پیدا نشده.');
      return;
    }
    Navigator.of(context).push(
      AppRouter.build<void>(
        settings: const RouteSettings(name: AppRoutes.learn),
        builder: (_) => LearnScreen(
          args: LearnArgs(
            kind: plan.kind,
            words: plan.words,
            title: plan.title,
            subtitle: plan.subtitle,
          ),
        ),
      ),
    );
  }
}

class _SessionHistory extends StatelessWidget {
  const _SessionHistory({required this.sessions});

  final List<StudySession> sessions;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final recent = sessions.length <= 6
        ? sessions.reversed.toList(growable: false)
        : sessions.reversed.take(6).toList(growable: false);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SectionHeader(
            title: 'جلسه‌های اخیر',
            subtitle: '${FaFormat.digits(sessions.length)} جلسه تا امروز',
            icon: Icons.history_rounded,
          ),
          const SizedBox(height: AppSpacing.xs),
          if (recent.isEmpty)
            Text(
              'هنوز جلسه‌ای ثبت نشده است.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: palette.textTertiary,
                  ),
            )
          else
            for (final session in recent)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Row(
                  children: <Widget>[
                    Container(
                      width: 38,
                      height: 38,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: palette.surfaceAlt,
                        borderRadius: BorderRadius.circular(AppRadius.xs),
                      ),
                      child: Text(
                        session.kind.emoji,
                        style: const TextStyle(fontSize: 17),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            session.kind.faTitle,
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium
                                ?.copyWith(color: palette.textPrimary),
                          ),
                          Text(
                            '${JalaliDate.fromDateTime(session.finishedAt).dayMonthLabel} • '
                            '${FaFormat.digits(session.reviewedCount)} واژه • '
                            '${FaFormat.percent(session.accuracy * 100)} درست',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(color: palette.textTertiary),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '+${FaFormat.digits(session.xpEarned)}',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: AppColors.gold,
                            fontWeight: FontWeight.w800,
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
