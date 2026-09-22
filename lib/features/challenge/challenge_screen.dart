import 'package:flutter/material.dart';

import '../../core/di/app_container.dart';
import '../../core/routing/app_router.dart';
import '../../core/state/value_store.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_palette.dart';
import '../../core/utils/fa_format.dart';
import '../../domain/engines/session_builder.dart';
import '../../domain/entities/progress.dart';
import '../../domain/entities/study_session.dart';
import '../../l10n/strings.dart';
import '../../widgets/animations.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/badges.dart';
import '../../widgets/states.dart';
import '../../widgets/word_tile.dart';
import '../quiz/quiz_screen.dart';

/// چالش روزانه: یک جلسه‌ی کوتاه و پرانرژی که هر روز نوسازی می‌شود.
///
/// چالش، «عادت روزانه» را می‌سازد: پاداش بیشتر، محافظ زنجیره و
/// سؤال‌هایی که هم واژه‌های سررسیده و هم نقاط ضعف را پوشش می‌دهند.
class ChallengeScreen extends StatelessWidget {
  const ChallengeScreen({super.key, required this.plan});

  final SessionPlan plan;

  @override
  Widget build(BuildContext context) {
    final container = AppScope.of(context);
    final palette = AppPalette.of(context);

    return StoreBuilder<DailyChallengeState>(
      store: container.stores.challengeStore,
      builder: (context, state) {
        final completedToday = container.controller.isChallengeCompletedToday;

        return AppScaffold(
          title: S.challengeTitle,
          subtitle: S.challengeSubtitle,
          showBack: true,
          body: ListView(
            padding: const EdgeInsets.only(bottom: AppSpacing.xl),
            children: <Widget>[
              FadeSlideIn(
                child: HighlightCard(
                  gradient: AppColors.goldGradient,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          const Text('🔥', style: TextStyle(fontSize: 30)),
                          const SizedBox(width: AppSpacing.xs),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  completedToday
                                      ? 'چالش امروز انجام شد'
                                      : 'چالش امروزت آماده است',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        color: const Color(0xFF3A2400),
                                        fontWeight: FontWeight.w800,
                                      ),
                                ),
                                Text(
                                  completedToday
                                      ? S.challengeComeBack
                                      : '۱۰ سؤال ترکیبی • پاداش دوبرابر',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(
                                        color: const Color(0xFF6B4A00),
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: <Widget>[
                          _MiniStat(
                            value: FaFormat.digits(state.streakDays),
                            label: 'روز پشت‌سرهم',
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          _MiniStat(
                            value: FaFormat.digits(plan.wordCount),
                            label: 'سؤال امروز',
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          _MiniStat(
                            value: FaFormat.digits(state.bestStreak),
                            label: 'رکورد',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    SectionHeader(
                      title: 'قواعد چالش',
                      icon: Icons.rule_rounded,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    const _RuleTile(
                      icon: Icons.checklist_rounded,
                      text: '۱۰ سؤال از واژه‌های سررسیده، ضعیف و تازه — ترکیبی از همه‌ی مهارت‌ها',
                    ),
                    const _RuleTile(
                      icon: Icons.bolt_rounded,
                      text: 'امتیاز بیشتر: هر پاسخ درست، پاداش اضافه‌ی چالش می‌گیرد',
                    ),
                    const _RuleTile(
                      icon: Icons.shield_moon_rounded,
                      text: 'با کامل‌کردن چالش، یک محافظ زنجیره می‌گیری که روزهای پرت را جبران می‌کند',
                    ),
                    const _RuleTile(
                      icon: Icons.local_fire_department_rounded,
                      text: 'زنجیره‌ی چالش را نشکن؛ رکوردت را در پروفایل می‌بینی',
                    ),
                  ],
                ),
              ),
              if (!plan.isEmpty) ...<Widget>[
                const SizedBox(height: AppSpacing.md),
                SectionHeader(
                  title: 'واژه‌های امروز',
                  subtitle: 'پیش‌نمایش سؤال‌ها',
                  icon: Icons.style_rounded,
                ),
                const SizedBox(height: AppSpacing.xs),
                for (final word in plan.words.take(4))
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: WordTile(
                      word: word,
                      dense: true,
                      trailing: CefrBadge(
                        code: word.level.code,
                        title: word.level.faTitle,
                        dense: true,
                      ),
                    ),
                  ),
                if (plan.wordCount > 4)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      'و ${FaFormat.digits(plan.wordCount - 4)} واژه‌ی دیگر…',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: palette.textTertiary,
                          ),
                    ),
                  ),
              ],
              const SizedBox(height: AppSpacing.lg),
              if (plan.isEmpty)
                const EmptyStateView(
                  title: 'چالش امروز در دسترس نیست',
                  message: 'اول چند واژه یاد بگیر تا چالش روزانه ساخته شود.',
                  emoji: '🧭',
                )
              else
                AppButton(
                  label: completedToday ? 'تمرین آزاد با واژه‌های چالش' : S.challengeStart,
                  icon: completedToday
                      ? Icons.replay_rounded
                      : Icons.play_arrow_rounded,
                  variant: completedToday
                      ? AppButtonVariant.secondary
                      : AppButtonVariant.gold,
                  onPressed: () => _start(context, isChallenge: !completedToday),
                ),
              const SizedBox(height: AppSpacing.xs),
              Center(
                child: Text(
                  'چالش هر روز ساعت ۴ بامداد نوسازی می‌شود',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: palette.textTertiary,
                      ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _start(BuildContext context, {required bool isChallenge}) {
    Navigator.of(context).pushReplacement(
      AppRouter.build<void>(
        settings: const RouteSettings(name: AppRoutes.quiz),
        builder: (_) => QuizScreen(
          args: QuizArgs(
            words: plan.words,
            kind: SessionKind.challenge,
            isChallenge: isChallenge,
            title: S.challengeTitle,
          ),
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs, horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.white.fade(0.35),
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Column(
          children: <Widget>[
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: const Color(0xFF3A2400),
                    fontWeight: FontWeight.w800,
                  ),
            ),
            Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: const Color(0xFF6B4A00),
                    fontSize: 10,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RuleTile extends StatelessWidget {
  const _RuleTile({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.goldSoft,
              borderRadius: BorderRadius.circular(AppRadius.xs),
            ),
            child: Icon(icon, size: 15, color: AppColors.goldDeep),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: palette.textSecondary,
                    height: 1.7,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
