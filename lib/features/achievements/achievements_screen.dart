import 'package:flutter/material.dart';

import '../../core/di/app_container.dart';
import '../../core/state/value_store.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_palette.dart';
import '../../core/utils/fa_format.dart';
import '../../core/utils/jalali_date.dart';
import '../../domain/engines/achievement_catalog.dart';
import '../../domain/entities/achievement.dart';
import '../../l10n/labels.dart';
import '../../l10n/strings.dart';
import '../../widgets/animations.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/badges.dart';
import '../../widgets/progress_views.dart';
import '../../widgets/states.dart';

/// دستاوردها: فهرست نشان‌ها با پیشرفت، تفکیک‌شده بر اساس وضعیت.
class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

enum _Filter { all, unlocked, inProgress, premium }

class _AchievementsScreenState extends State<AchievementsScreen> {
  _Filter _filter = _Filter.all;
  bool _seen = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_seen) return;
    _seen = true;
    final container = AppScope.of(context);
    // پرچم «تازه باز شد» پس از دیدن فهرست پاک می‌شود.
    container.controller.markAchievementsSeen();
  }

  @override
  Widget build(BuildContext context) {
    final container = AppScope.of(context);
    final palette = AppPalette.of(context);

    return StoreBuilder<Map<String, AchievementProgress>>(
      store: container.stores.achievementsStore,
      builder: (context, progressMap) {
        final all = AchievementCatalog.all;
        final unlocked = all
            .where((achievement) =>
                progressMap[achievement.id]?.isUnlocked ?? false)
            .length;
        final items = all.where((achievement) {
          final progress = progressMap[achievement.id];
          switch (_filter) {
            case _Filter.all:
              return true;
            case _Filter.unlocked:
              return progress?.isUnlocked ?? false;
            case _Filter.inProgress:
              return !(progress?.isUnlocked ?? false) &&
                  (progress?.current ?? 0) > 0;
            case _Filter.premium:
              return achievement.premium;
          }
        }).toList(growable: false);

        return AppScaffold(
          title: S.achievementsTitle,
          subtitle: '${FaFormat.digits(unlocked)} از ${FaFormat.digits(all.length)} '
              'نشان باز شده',
          showBack: true,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          body: ListView(
            padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
            children: <Widget>[
              HighlightCard(
                gradient: AppColors.goldGradient,
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: <Widget>[
                    ProgressRing(
                      progress: all.isEmpty ? 0 : unlocked / all.length,
                      size: 74,
                      strokeWidth: 8,
                      gradientColors: const <Color>[
                        Colors.white,
                        Color(0xFFFFE7B0),
                      ],
                      trackColor: Colors.white.fade(0.3),
                      center: Text(
                        FaFormat.percent(
                          all.isEmpty ? 0 : (unlocked / all.length) * 100,
                        ),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const Text(
                            'مسیر نشان‌ها',
                            style: TextStyle(
                              color: Color(0xFF3A2400),
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'هر نشان، یک قدم واقعی در یادگیری است: '
                            'واژه‌های مسلط، زنجیره‌ها، تمرین‌ها و چالش‌ها.',
                            style: TextStyle(
                              color: const Color(0xFF6B4A00),
                              fontSize: 11,
                              height: 1.7,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'جایزه‌ی نشان‌ها: امتیاز اضافه برای سطح بعدی',
                            style: TextStyle(
                              color: const Color(0xFF6B4A00),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: <Widget>[
                    for (final filter in _Filter.values) ...<Widget>[
                      TagChip(
                        label: switch (filter) {
                          _Filter.all => 'همه',
                          _Filter.unlocked => 'بازشده',
                          _Filter.inProgress => 'در پیشرفت',
                          _Filter.premium => 'ویژه',
                        },
                        color: _filter == filter
                            ? AppColors.brand
                            : palette.textTertiary,
                        dense: true,
                        onTap: () => setState(() => _filter = filter),
                      ),
                      const SizedBox(width: 6),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              if (items.isEmpty)
                EmptyStateView(
                  title: 'نشانی در این دسته نیست',
                  message: 'با کمی تمرین، نشان‌های این بخش باز می‌شوند.',
                  emoji: '🏅',
                  compact: true,
                )
              else
                for (final achievement in items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: FadeSlideIn(
                      child: _AchievementCard(
                        achievement: achievement,
                        progress: progressMap[achievement.id] ??
                            AchievementProgress(
                              id: achievement.id,
                              current: 0,
                            ),
                      ),
                    ),
                  ),
            ],
          ),
        );
      },
    );
  }
}

class _AchievementCard extends StatelessWidget {
  const _AchievementCard({required this.achievement, required this.progress});

  final Achievement achievement;
  final AchievementProgress progress;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final unlockedAt = progress.unlockedAt;
    final target = achievement.target <= 0 ? 1 : achievement.target;
    final ratio = (progress.current / target).clamp(0.0, 1.0);
    final accent = unlockedAt != null
        ? AppColors.gold
        : achievement.premium
            ? AppColors.pink
            : palette.textTertiary;

    return AppCard(
      color: unlockedAt != null ? AppColors.goldSoft : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: accent.fade(0.16),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            alignment: Alignment.center,
            child: Text(
              unlockedAt != null ? achievement.emoji : '🔒',
              style: const TextStyle(fontSize: 24),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        achievement.title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: palette.textPrimary,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                    if (achievement.premium && unlockedAt == null)
                      const PremiumBadge(dense: true)
                    else
                      TagChip(
                        label: '+${FaFormat.digits(achievement.xpReward)} امتیاز',
                        color: AppColors.gold,
                        dense: true,
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  achievement.description,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: palette.textSecondary,
                        height: 1.7,
                      ),
                ),
                const SizedBox(height: 6),
                AppProgressBar(
                  progress: ratio,
                  height: 6,
                  gradient: unlockedAt != null
                      ? AppColors.goldGradient
                      : AppColors.brandGradient,
                ),
                const SizedBox(height: 4),
                Row(
                  children: <Widget>[
                    Text(
                      unlockedAt != null
                          ? 'باز شد • ${JalaliDate.fromDateTime(unlockedAt).longLabel}'
                          : '${FaFormat.digits(progress.current)} از '
                              '${FaFormat.digits(target)} '
                              '${achievement.metric.unitFa}',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: unlockedAt != null
                                ? AppColors.goldDeep
                                : palette.textTertiary,
                            fontSize: 10,
                          ),
                    ),
                    const Spacer(),
                    if (progress.isNew && unlockedAt != null)
                      const TagChip(label: 'تازه', color: AppColors.pink, dense: true),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
