import 'package:flutter/material.dart';

import '../core/di/app_controller.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_dimens.dart';
import '../core/theme/app_palette.dart';
import '../core/utils/fa_format.dart';
import '../l10n/strings.dart';
import 'app_button.dart';
import 'app_card.dart';
import 'celebration.dart';
import 'states.dart';

/// خلاصه‌ی پایان جلسه — مشترک بین فلش‌کارت، تمرین، چالش و آزمون‌ها.
///
/// یک نمای واحد یعنی کاربر در همه‌ی مسیرهای یادگیری، بازخورد یکسانی
/// می‌بیند و کد تکراری نداریم.
class SessionSummaryView extends StatefulWidget {
  const SessionSummaryView({
    super.key,
    required this.title,
    required this.total,
    required this.correct,
    this.subtitle,
    this.emoji,
    this.outcome,
    this.xp,
    this.onDone,
    this.doneLabel = S.done,
    this.onRepeatMistakes,
    this.extra,
    this.streakDays,
    this.headline,
  });

  /// عنوان اصلی (مثلاً «این جلسه تمام شد!»).
  final String title;

  /// جمله‌ی توضیحی زیر عنوان.
  final String? subtitle;
  final String? emoji;

  /// تعداد کل پاسخ‌ها و پاسخ‌های درست.
  final int total;
  final int correct;

  /// نتیجه‌ی کنترلر (زنجیره، سطح، دستاوردها).
  final LearningOutcome? outcome;

  /// امتیاز کسب‌شده؛ اگر خالی باشد از [outcome] خوانده می‌شود.
  final int? xp;

  final VoidCallback? onDone;
  final String doneLabel;
  final VoidCallback? onRepeatMistakes;

  /// بخش دلخواه (برای چالش و آزمون تعیین سطح).
  final Widget? extra;

  /// تعداد روزهای زنجیره‌ی چالش (اختیاری).
  final int? streakDays;

  /// جمله‌ی تشویقی جایگزین (مثلاً «خوب بلدی، سخت‌تر می‌پرسیم»).
  final String? headline;

  @override
  State<SessionSummaryView> createState() => _SessionSummaryViewState();
}

class _SessionSummaryViewState extends State<SessionSummaryView> {
  bool _celebrate = true;

  double get _accuracy => widget.total == 0 ? 0 : widget.correct / widget.total;

  String get _headline {
    if (widget.headline != null) return widget.headline!;
    if (_accuracy >= 0.9) return 'عالی بود! تقریباً بی‌نقص بودی.';
    if (_accuracy >= 0.7) return 'خوب پیش رفتی؛ چند واژه را دوباره مرور کن.';
    if (_accuracy >= 0.4) return 'مسیر درست است؛ تکرار این واژه‌ها معجزه می‌کند.';
    return 'سخت بود؟ نگران نباش، همین واژه‌ها را دوباره تمرین می‌کنیم.';
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final outcome = widget.outcome;
    final xp = widget.xp ?? outcome?.xpEarned ?? 0;
    final wrong = widget.total - widget.correct;

    return ConfettiOverlay(
      active: _celebrate,
      onFinished: () => setState(() => _celebrate = false),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.xl,
        ),
        children: <Widget>[
          Center(
            child: Column(
              children: <Widget>[
                Text(
                  widget.emoji ?? (_accuracy >= 0.8 ? '🎉' : '💪'),
                  style: const TextStyle(fontSize: 54),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  widget.title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: palette.textPrimary,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.subtitle ?? _headline,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: palette.textSecondary,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: StatTile(
                        value: FaFormat.digits(widget.total),
                        label: S.reviewedCount,
                        icon: Icons.style_rounded,
                        compact: true,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: StatTile(
                        value: FaFormat.digits(widget.correct),
                        label: S.correctCount,
                        icon: Icons.check_circle_rounded,
                        color: palette.success,
                        compact: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: StatTile(
                        value: FaFormat.digits(wrong),
                        label: S.wrongCount,
                        icon: Icons.cancel_rounded,
                        color: palette.danger,
                        compact: true,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: StatTile(
                        value: FaFormat.digits(xp),
                        label: S.earnedXp,
                        icon: Icons.bolt_rounded,
                        color: AppColors.gold,
                        compact: true,
                      ),
                    ),
                  ],
                ),
                if (widget.total >= 4) ...<Widget>[
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Icon(
                        Icons.insights_rounded,
                        size: 15,
                        color: palette.textTertiary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${S.accuracyLabel}: ${FaFormat.percent(_accuracy * 100)}',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: palette.textTertiary,
                            ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (outcome != null) ...<Widget>[
            const SizedBox(height: AppSpacing.md),
            Row(
              children: <Widget>[
                Expanded(
                  child: AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            const Text('🔥', style: TextStyle(fontSize: 16)),
                            const SizedBox(width: 6),
                            Text(
                              FaFormat.digits(outcome.streak.current),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(color: palette.textPrimary),
                            ),
                          ],
                        ),
                        Text(
                          S.streakLabel,
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: palette.textTertiary,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Text(
                              outcome.level.emoji,
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              FaFormat.digits(outcome.level.index),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(color: palette.textPrimary),
                            ),
                          ],
                        ),
                        Text(
                          outcome.level.title,
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: palette.textTertiary,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (widget.streakDays != null && widget.streakDays! > 0) ...<Widget>[
            const SizedBox(height: AppSpacing.md),
            InfoBanner(
              text: 'چالش روزانه را ${FaFormat.digits(widget.streakDays!)} روز پشت‌سرهم کامل کردی! '
                  'فردا هم منتظرت هستیم 🔥',
              icon: Icons.local_fire_department_rounded,
              color: AppColors.gold,
            ),
          ],
          if (outcome != null && outcome.leveledUp) ...<Widget>[
            const SizedBox(height: AppSpacing.md),
            InfoBanner(
              text: 'سطحت بالا رفت! به ${outcome.level.title} رسیدی ${outcome.level.emoji}',
              icon: Icons.celebration_rounded,
              color: AppColors.gold,
            ),
          ],
          if (outcome != null && outcome.dailyGoalReached) ...<Widget>[
            const SizedBox(height: AppSpacing.xs),
            const InfoBanner(
              text: 'هدف امروزت را کامل کردی! 🎯',
              icon: Icons.flag_rounded,
              color: AppColors.accent,
            ),
          ],
          if (outcome != null && outcome.unlockedAchievements.isNotEmpty) ...<Widget>[
            const SizedBox(height: AppSpacing.xs),
            InfoBanner(
              text: 'دستاورد تازه: '
                  '${outcome.unlockedAchievements.map((a) => '${a.emoji} ${a.title}').join('، ')}',
              icon: Icons.emoji_events_rounded,
              color: AppColors.pink,
            ),
          ],
          if (widget.extra != null) ...<Widget>[
            const SizedBox(height: AppSpacing.md),
            widget.extra!,
          ],
          const SizedBox(height: AppSpacing.lg),
          if (widget.onDone != null)
            AppButton(
              label: widget.doneLabel,
              icon: Icons.check_rounded,
              onPressed: widget.onDone,
            ),
          if (widget.onRepeatMistakes != null && wrong > 0) ...<Widget>[
            const SizedBox(height: AppSpacing.xs),
            AppButton(
              label: S.quizReviewMistakes,
              icon: Icons.replay_rounded,
              variant: AppButtonVariant.secondary,
              onPressed: widget.onRepeatMistakes,
            ),
          ],
        ],
      ),
    );
  }
}
