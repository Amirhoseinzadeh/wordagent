import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_dimens.dart';
import '../core/theme/app_palette.dart';
import '../core/theme/app_typography.dart';
import '../core/utils/fa_format.dart';
import '../l10n/strings.dart';
import 'animations.dart';
import 'app_button.dart';
import '../domain/entities/quiz_question.dart';
import 'app_card.dart';
import 'badges.dart';
import 'states.dart';

/// سرصفحه‌ی تمرین: نوار پیشرفت + شماره‌ی سؤال + امتیاز جلسه.
class QuizHeader extends StatelessWidget {
  const QuizHeader({
    super.key,
    required this.index,
    required this.total,
    required this.sessionXp,
    required this.onClose,
    this.combo = 0,
  });

  final int index;
  final int total;
  final int sessionXp;
  final VoidCallback onClose;
  final int combo;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final progress = total == 0 ? 0.0 : index / total;
    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            CircleIconButton(
              icon: Icons.close_rounded,
              onPressed: onClose,
              size: 38,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    '${S.placementProgress} ${FaFormat.digits(index + 1)} از ${FaFormat.digits(total)}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: palette.textTertiary,
                        ),
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    child: LinearProgressIndicator(
                      value: progress.clamp(0.0, 1.0),
                      minHeight: 7,
                      backgroundColor: palette.surfaceAlt,
                      color: AppColors.brand,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Row(
              children: <Widget>[
                if (combo >= 2) ...<Widget>[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.goldSoft,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text(
                      '🔥 ${FaFormat.digits(combo)}',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.goldDeep,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.brandSoft,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      const Icon(Icons.bolt_rounded, size: 15, color: AppColors.brand),
                      const SizedBox(width: 3),
                      Text(
                        FaFormat.digits(sessionXp),
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: AppColors.brand,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

/// گزینه‌های چندگزینه‌ای با حالت‌های بصری درست/نادرست.
class McqOptions extends StatelessWidget {
  const McqOptions({
    super.key,
    required this.choices,
    required this.selected,
    required this.correctAnswer,
    required this.revealed,
    required this.onSelect,
    this.rtl = false,
  });

  final List<String> choices;
  final String? selected;
  final String correctAnswer;
  final bool revealed;
  final ValueChanged<String> onSelect;

  /// آیا گزینه‌ها متن فارسی هستند؟ (برای چیدمان راست‌به‌چپ)
  final bool rtl;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Column(
      children: <Widget>[
        for (final choice in choices)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: _OptionTile(
              label: choice,
              isSelected: selected == choice,
              isCorrect: choice == correctAnswer,
              revealed: revealed,
              onTap: revealed ? null : () => onSelect(choice),
              palette: palette,
              useEnglishFont: !rtl,
            ),
          ),
      ],
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.label,
    required this.isSelected,
    required this.isCorrect,
    required this.revealed,
    required this.onTap,
    required this.palette,
    required this.useEnglishFont,
  });

  final String label;
  final bool isSelected;
  final bool isCorrect;
  final bool revealed;
  final VoidCallback? onTap;
  final AppPalette palette;
  final bool useEnglishFont;

  @override
  Widget build(BuildContext context) {
    Color border = palette.border;
    Color background = palette.surface;
    Color textColor = palette.textPrimary;
    IconData? trailing;

    if (revealed) {
      if (isCorrect) {
        border = palette.success;
        background = palette.softFor(palette.success);
        textColor = palette.success;
        trailing = Icons.check_circle_rounded;
      } else if (isSelected) {
        border = palette.danger;
        background = palette.softFor(palette.danger);
        textColor = palette.danger;
        trailing = Icons.cancel_rounded;
      }
    } else if (isSelected) {
      border = AppColors.brand;
      background = AppColors.brandSoft;
      textColor = AppColors.brand;
    }

    return ScaleTap(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppDurations.fast,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: border, width: isSelected || revealed ? 1.6 : 1),
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Text(
                label,
                style: (useEnglishFont
                        ? AppTypography.answer
                        : Theme.of(context).textTheme.bodyLarge ?? const TextStyle())
                    .copyWith(color: textColor, fontSize: 16),
              ),
            ),
            if (trailing != null)
              Icon(trailing, size: 20, color: textColor)
            else
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: border),
                  color: isSelected ? AppColors.brand : Colors.transparent,
                ),
                child: isSelected
                    ? const Icon(Icons.check_rounded, size: 13, color: Colors.white)
                    : null,
              ),
          ],
        ),
      ),
    );
  }
}

/// ورودی پاسخ تایپی با بازخورد بصری.
class TypingAnswerField extends StatelessWidget {
  const TypingAnswerField({
    super.key,
    required this.controller,
    required this.onSubmit,
    this.revealed = false,
    this.isCorrect = false,
    this.hint,
    this.english = false,
    this.focusNode,
    this.enabled = true,
  });

  final TextEditingController controller;
  final VoidCallback onSubmit;
  final bool revealed;
  final bool isCorrect;
  final String? hint;
  final bool english;
  final FocusNode? focusNode;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final borderColor = revealed
        ? (isCorrect ? palette.success : palette.danger)
        : palette.border;
    return TextField(
      controller: controller,
      focusNode: focusNode,
      enabled: enabled,
      autofocus: false,
      textInputAction: TextInputAction.done,
      onSubmitted: (_) => onSubmit(),
      textDirection: english ? TextDirection.ltr : TextDirection.rtl,
      textAlign: english ? TextAlign.left : TextAlign.right,
      style: english
          ? AppTypography.answer.copyWith(color: palette.textPrimary)
          : (Theme.of(context).textTheme.bodyLarge ?? const TextStyle())
              .copyWith(color: palette.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: palette.textTertiary,
            ),
        filled: true,
        fillColor: revealed ? palette.softFor(borderColor) : palette.surfaceAlt,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: AppColors.brand, width: 1.6),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide(color: borderColor),
        ),
      ),
    );
  }
}

/// تمرین جمله‌سازی: چیدن قطعه‌ها کنار هم.
class SentenceBuilder extends StatelessWidget {
  const SentenceBuilder({
    super.key,
    required this.available,
    required this.selected,
    required this.onAdd,
    required this.onRemove,
    this.revealed = false,
    this.isCorrect = false,
    this.correctSentence,
    this.direction = TextDirection.ltr,
  });

  final List<String> available;
  final List<String> selected;
  final ValueChanged<String> onAdd;
  final ValueChanged<String> onRemove;
  final bool revealed;
  final bool isCorrect;
  final String? correctSentence;
  final TextDirection direction;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 84),
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: revealed
                ? palette.softFor(isCorrect ? palette.success : palette.danger)
                : palette.surfaceAlt,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(
              color: revealed
                  ? (isCorrect ? palette.success : palette.danger)
                  : palette.border,
            ),
          ),
          child: Directionality(
            textDirection: direction,
            child: Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: <Widget>[
                for (final token in selected)
                  ScaleTap(
                    onTap: revealed ? null : () => onRemove(token),
                    child: _Token(token: token, palette: palette, selected: true),
                  ),
                if (selected.isEmpty)
                  Text(
                    'روی واژه‌ها بزن و جمله را بساز',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: palette.textTertiary,
                        ),
                  ),
              ],
            ),
          ),
        ),
        if (revealed && correctSentence != null && !isCorrect) ...<Widget>[
          const SizedBox(height: AppSpacing.xs),
          Text(
            'پاسخ درست: $correctSentence',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: palette.success,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        Directionality(
          textDirection: direction,
          child: Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: <Widget>[
              for (final token in available)
                if (!selected.contains(token) || _countIn(available, token) > _countIn(selected, token))
                  ScaleTap(
                    onTap: revealed ? null : () => onAdd(token),
                    child: _Token(token: token, palette: palette, selected: false),
                  ),
            ],
          ),
        ),
      ],
    );
  }

  int _countIn(List<String> list, String value) =>
      list.where((item) => item == value).length;
}

class _Token extends StatelessWidget {
  const _Token({
    required this.token,
    required this.palette,
    required this.selected,
  });

  final String token;
  final AppPalette palette;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: selected ? AppColors.brandSoft : palette.surface,
        borderRadius: BorderRadius.circular(AppRadius.xs),
        border: Border.all(
          color: selected ? AppColors.brand : palette.border,
        ),
      ),
      child: Text(
        token,
        style: AppTypography.answer.copyWith(
          fontSize: 15,
          color: selected ? AppColors.brand : palette.textPrimary,
        ),
      ),
    );
  }
}

/// کارت پرسش: نوع تمرین، سطح واژه و متن سؤال.
///
/// این کارت در همه‌ی مسیرهای تمرین (تمرین ترکیبی، تعیین سطح و چالش)
/// استفاده می‌شود تا کاربر تجربه‌ی یکدستی داشته باشد.
class QuizQuestionCard extends StatelessWidget {
  const QuizQuestionCard({
    super.key,
    required this.question,
    this.revealed = false,
  });

  final QuizQuestion question;

  /// پس از پاسخ، ترجمه‌ی جمله هم نمایش داده می‌شود.
  final bool revealed;

  /// آیکون معرف هر نوع تمرین.
  static IconData iconFor(QuizType type) {
    switch (type) {
      case QuizType.meaningChoice:
        return Icons.translate_rounded;
      case QuizType.wordChoice:
        return Icons.abc_rounded;
      case QuizType.fillBlank:
        return Icons.short_text_rounded;
      case QuizType.typeMeaning:
        return Icons.keyboard_rounded;
      case QuizType.typeWord:
        return Icons.spellcheck_rounded;
      case QuizType.listening:
        return Icons.hearing_rounded;
      case QuizType.sentenceBuild:
        return Icons.linear_scale_rounded;
      case QuizType.collocation:
        return Icons.link_rounded;
      case QuizType.synonym:
        return Icons.sync_alt_rounded;
      case QuizType.antonym:
        return Icons.swap_horiz_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final isEnglishPrompt = question.type == QuizType.fillBlank ||
        question.type == QuizType.sentenceBuild ||
        question.type == QuizType.listening;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: palette.border),
        boxShadow: AppShadows.soft(palette.isDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              TagChip(
                label: question.type.faTitle,
                icon: iconFor(question.type),
                color: AppColors.brand,
                dense: true,
              ),
              const SizedBox(width: 6),
              CefrBadge(
                code: question.word.level.code,
                title: question.word.level.faTitle,
                dense: true,
              ),
              const Spacer(),
              if (question.usesPremiumContent) const PremiumBadge(dense: true),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (question.type == QuizType.listening)
            Center(
              child: Column(
                children: <Widget>[
                  Icon(
                    Icons.graphic_eq_rounded,
                    size: 42,
                    color: AppColors.brand.fade(0.6),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    S.quizListen,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: palette.textPrimary,
                        ),
                  ),
                ],
              ),
            )
          else
            Directionality(
              textDirection:
                  isEnglishPrompt ? TextDirection.ltr : TextDirection.rtl,
              child: Text(
                question.prompt ?? question.word.term,
                style: isEnglishPrompt
                    ? AppTypography.answer.copyWith(
                        fontSize: 20,
                        color: palette.textPrimary,
                      )
                    : Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: palette.textPrimary,
                        ),
              ),
            ),
          if (question.instructions != null &&
              question.type != QuizType.listening) ...<Widget>[
            const SizedBox(height: AppSpacing.xs),
            Text(
              question.instructions!,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: palette.textTertiary,
                  ),
            ),
          ],
          if (revealed &&
              question.sentenceFa != null &&
              question.type == QuizType.fillBlank) ...<Widget>[
            const SizedBox(height: AppSpacing.sm),
            InfoBanner(
              text: 'ترجمه: ${question.sentenceFa}',
              icon: Icons.translate_rounded,
              color: palette.info,
            ),
          ],
        ],
      ),
    );
  }
}

/// نوار پیام «درست/اشتباه» با راهنمای پاسخ.
/// نوار بازخورد پس از پاسخ.
class FeedbackBanner extends StatelessWidget {
  const FeedbackBanner({
    super.key,
    required this.isCorrect,
    required this.correctAnswer,
    required this.onNext,
    this.explanation,
    this.nearlyCorrect = false,
    this.isLast = false,
  });

  final bool isCorrect;
  final String correctAnswer;
  final VoidCallback onNext;
  final String? explanation;
  final bool nearlyCorrect;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final accent = isCorrect ? palette.success : palette.danger;
    final title = isCorrect
        ? S.quizCorrect
        : (nearlyCorrect ? 'نزدیک بود!' : S.quizWrong);
    return AppCard(
      color: palette.softFor(accent),
      borderColor: accent.fade(0.4),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                isCorrect ? Icons.check_circle_rounded : Icons.info_rounded,
                color: accent,
                size: 22,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: accent,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ],
          ),
          if (!isCorrect) ...<Widget>[
            const SizedBox(height: AppSpacing.xs),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  '${S.answerLabel}: ',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: palette.textSecondary,
                      ),
                ),
                Expanded(
                  child: Text(
                    correctAnswer,
                    style: AppTypography.answer.copyWith(
                      fontSize: 16,
                      color: palette.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (explanation != null && explanation!.isNotEmpty) ...<Widget>[
            const SizedBox(height: AppSpacing.xs),
            Text(
              explanation!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: palette.textSecondary,
                  ),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          AppButton(
            label: isLast ? S.done : S.quizNextQuestion,
            icon: Icons.arrow_back_rounded,
            onPressed: onNext,
            height: 46,
          ),
        ],
      ),
    );
  }
}

/// دکمه‌ی پخش صدا برای تمرین شنیداری.
class ListenButton extends StatelessWidget {
  const ListenButton({
    super.key,
    required this.onPlay,
    this.playing = false,
    this.label = 'پخش دوباره',
    this.large = false,
  });

  final VoidCallback onPlay;
  final bool playing;
  final String label;
  final bool large;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        ScaleTap(
          onTap: onPlay,
          child: PulsingHalo(
            active: playing,
            size: large ? 110 : 76,
            child: Container(
              width: large ? 96 : 68,
              height: large ? 96 : 68,
              decoration: BoxDecoration(
                gradient: AppColors.brandGradient,
                shape: BoxShape.circle,
                boxShadow: AppShadows.brandGlow(),
              ),
              child: Icon(
                playing ? Icons.graphic_eq_rounded : Icons.volume_up_rounded,
                color: Colors.white,
                size: large ? 40 : 30,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppColors.brand,
              ),
        ),
      ],
    );
  }
}
