import 'package:flutter/material.dart';

import '../../core/di/app_container.dart';
import '../../core/di/app_controller.dart';
import '../../core/routing/app_router.dart';
import '../../core/state/value_store.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_palette.dart';
import '../../core/utils/fa_format.dart';
import '../../domain/engines/session_builder.dart';
import '../../domain/engines/weakness_engine.dart';
import '../../domain/entities/review_state.dart';
import '../../l10n/strings.dart';
import '../../widgets/animations.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/badges.dart';
import '../../widgets/states.dart';
import '../../widgets/word_tile.dart';
import 'learn_screen.dart';

/// مرکز یادگیری: انتخاب بین مرور، واژه‌ی تازه، تقویت نقاط ضعف و چالش.
class LearnHubScreen extends StatelessWidget {
  const LearnHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final container = AppScope.of(context);
    final controller = container.controller;
    final palette = AppPalette.of(context);

    return Watch(
      listenables: <Listenable>[
        container.stores.statesStore,
        container.stores.settingsStore,
        container.stores.profileStore,
        container.stores.challengeStore,
      ],
      builder: (context) {
        final reviewPlan = controller.reviewPlan;
        final learnPlan = controller.learnPlan;
        final weakPlan = controller.weakPlan;
        final challengePlan = controller.challengePlan;
        final dueCount = controller.dueCount;

        return AppScaffold(
          title: S.learnTitle,
          subtitle: 'برنامه‌ی امروزت آماده است',
          padding: EdgeInsets.zero,
          body: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.xxl,
            ),
            children: <Widget>[
              FadeSlideIn(
                child: _PlanCard(
                  emoji: '🔁',
                  title: S.dueReviews,
                  subtitle: dueCount > 0
                      ? '${FaFormat.digits(dueCount)} واژه‌ی سررسیده — با تکرار فاصله‌دار'
                      : 'همه‌ی مرورهای امروز انجام شده',
                  badge: dueCount > 0 ? FaFormat.digits(dueCount) : null,
                  gradient: AppColors.brandGradient,
                  onTap: reviewPlan.isEmpty
                      ? null
                      : () => _openLearn(context, LearnArgs(
                            kind: reviewPlan.kind,
                            words: reviewPlan.words,
                            title: reviewPlan.title,
                            subtitle: reviewPlan.subtitle,
                          )),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              FadeSlideIn(
                delay: const Duration(milliseconds: 60),
                child: _PlanCard(
                  emoji: '🌱',
                  title: S.newWords,
                  subtitle: learnPlan.isEmpty
                      ? 'واژه‌ی تازه‌ای در سطح تو باقی نمانده'
                      : '${FaFormat.digits(learnPlan.wordCount)} واژه در سطح ${controller.profile.level.code}',
                  badge: learnPlan.isEmpty ? null : FaFormat.digits(learnPlan.wordCount),
                  gradient: AppColors.accentGradient,
                  onTap: learnPlan.isEmpty
                      ? null
                      : () => _openLearn(context, LearnArgs(
                            kind: learnPlan.kind,
                            words: learnPlan.words,
                            title: learnPlan.title,
                            subtitle: learnPlan.subtitle,
                          )),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              FadeSlideIn(
                delay: const Duration(milliseconds: 120),
                child: _PlanCard(
                  emoji: '🔥',
                  title: S.dailyChallenge,
                  subtitle: controller.isChallengeCompletedToday
                      ? S.challengeCompleted
                      : S.challengeSubtitle,
                  badge: controller.isChallengeCompletedToday ? '✓' : '۱۰',
                  gradient: AppColors.goldGradient,
                  darkText: true,
                  onTap: challengePlan.isEmpty
                      ? null
                      : () => Navigator.of(context).push(
                            AppRouter.build<void>(
                              builder: (_) => ChallengeScreen(plan: challengePlan),
                              settings: const RouteSettings(name: AppRoutes.challenge),
                            ),
                          ),
                ),
              ),
              if (!weakPlan.isEmpty) ...<Widget>[
                const SizedBox(height: AppSpacing.sm),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 180),
                  child: _PlanCard(
                    emoji: '🎯',
                    title: S.weakWordsTitle,
                    subtitle: '${FaFormat.digits(weakPlan.wordCount)} واژه‌ی دشوار برای تمرین',
                    badge: FaFormat.digits(weakPlan.wordCount),
                    gradient: AppColors.sunsetGradient,
                    onTap: () => _openLearn(context, LearnArgs(
                      kind: weakPlan.kind,
                      words: weakPlan.words,
                      title: weakPlan.title,
                      subtitle: weakPlan.subtitle,
                    )),
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              SectionHeader(
                title: 'حالت مطالعه',
                icon: Icons.tune_rounded,
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: <Widget>[
                  Expanded(
                    child: _ModeTile(
                      title: 'فلش‌کارت',
                      subtitle: 'مرور سریع با کارت',
                      icon: Icons.style_rounded,
                      onTap: reviewPlan.isEmpty
                          ? null
                          : () => _openLearn(context, LearnArgs(
                                kind: reviewPlan.kind,
                                words: reviewPlan.words,
                                title: reviewPlan.title,
                              )),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _ModeTile(
                      title: 'تمرین ترکیبی',
                      subtitle: '۸ نوع سؤال مختلف',
                      icon: Icons.quiz_rounded,
                      onTap: () {
                        final words = reviewPlan.words.isNotEmpty
                            ? reviewPlan.words
                            : learnPlan.words;
                        if (words.isEmpty) {
                          showToast(context, 'اول چند واژه یاد بگیر تا تمرین بسازم.');
                          return;
                        }
                        Navigator.of(context).push(
                          AppRouter.build<void>(
                            builder: (_) => QuizLauncherScreen(words: words),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              const _WeaknessPreview(),
              const SizedBox(height: AppSpacing.xl),
              const _StudyTipsCard(),
            ],
          ),
        );
      },
    );
  }

  void _openLearn(BuildContext context, LearnArgs args) {
    Navigator.of(context).push(
      AppRouter.build<void>(
        settings: const RouteSettings(name: AppRoutes.learn),
        builder: (_) => LearnScreen(args: args),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.gradient,
    this.badge,
    this.onTap,
    this.darkText = false,
  });

  final String emoji;
  final String title;
  final String subtitle;
  final Gradient gradient;
  final String? badge;
  final VoidCallback? onTap;
  final bool darkText;

  @override
  Widget build(BuildContext context) {
    final textColor = darkText ? const Color(0xFF3A2400) : Colors.white;
    final mutedColor = darkText ? const Color(0xFF6B4A00) : Colors.white.fade(0.85);
    return Opacity(
      opacity: onTap == null ? 0.65 : 1,
      child: HighlightCard(
        gradient: gradient,
        padding: const EdgeInsets.all(AppSpacing.md),
        onTap: onTap,
        child: Row(
          children: <Widget>[
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white.fade(0.22),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              alignment: Alignment.center,
              child: Text(emoji, style: const TextStyle(fontSize: 26)),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: textColor,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: mutedColor,
                        ),
                  ),
                ],
              ),
            ),
            if (badge != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.fade(darkText ? 0.35 : 0.2),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  badge!,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: textColor,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              )
            else
              Icon(Icons.chevron_left_rounded, color: textColor),
          ],
        ),
      ),
    );
  }
}

class _ModeTile extends StatelessWidget {
  const _ModeTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Opacity(
      opacity: onTap == null ? 0.6 : 1,
      child: AppCard(
        onTap: onTap,
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.brandSoft,
                borderRadius: BorderRadius.circular(AppRadius.xs),
              ),
              child: Icon(icon, color: AppColors.brand, size: 20),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: palette.textPrimary,
                  ),
            ),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: palette.textTertiary,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeaknessPreview extends StatelessWidget {
  const _WeaknessPreview();

  @override
  Widget build(BuildContext context) {
    final container = AppScope.of(context);
    final palette = AppPalette.of(context);
    return StoreBuilder<WeaknessReport>(
      store: container.stores.weaknessStore,
      builder: (context, report) {
        if (!report.hasData || report.weakWords.isEmpty) {
          return const SizedBox.shrink();
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SectionHeader(
              title: S.weakWordsTitle,
              subtitle: S.weakWordsBody,
              icon: Icons.trending_down_rounded,
            ),
            const SizedBox(height: AppSpacing.xs),
            for (final entry in report.weakWords.take(3))
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: WordTile(
                  word: entry.word,
                  state: entry.state,
                  dense: true,
                  trailing: TagChip(
                    label: entry.reasonFa,
                    color: palette.danger,
                    dense: true,
                  ),
                  onTap: () => Navigator.of(context).push(
                    AppRouter.build<void>(
                      settings: const RouteSettings(name: AppRoutes.wordDetail),
                      builder: (_) => WordDetailLauncher(word: entry.word),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _StudyTipsCard extends StatelessWidget {
  const _StudyTipsCard();

  static const List<String> _tips = <String>[
    'واژه را با صدای بلند تکرار کن؛ حافظه‌ی شنیداری قوی‌تر است.',
    'هر واژه را در یک جمله‌ی مربوط به زندگی خودت به کار ببر.',
    'مرورهای سررسیده را عقب نینداز؛ کل راز اپ همین است.',
    'اگر واژه‌ای سه بار فراموش شد، از ترفند حفظ استفاده کن.',
    'پیش از خواب ۵ دقیقه مرور کن؛ مغز شبانه تثبیت می‌کند.',
  ];

  @override
  Widget build(BuildContext context) {
    final tips = _tips;
    final tip = tips[DateTime.now().day % tips.length];
    return InfoBanner(
      text: tip,
      icon: Icons.lightbulb_outline_rounded,
      color: paletteAccent(context),
    );
  }

  Color paletteAccent(BuildContext context) => AppPalette.of(context).gold;
}
