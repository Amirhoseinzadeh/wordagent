import 'package:flutter/material.dart';

import '../../core/di/app_container.dart';
import '../../core/di/app_controller.dart';
import '../../core/routing/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/fa_format.dart';
import '../../domain/engines/srs_engine.dart';
import '../../domain/entities/quiz_question.dart';
import '../../domain/entities/review_state.dart';
import '../../domain/entities/study_session.dart';
import '../../domain/entities/word.dart';
import '../../l10n/strings.dart';
import '../../widgets/animations.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/badges.dart';
import '../../widgets/flip_card.dart';
import '../../widgets/session_summary.dart';
import '../../widgets/states.dart';
import '../../widgets/word_tile.dart';
import '../word_detail/word_detail_screen.dart';

/// جلسه‌ی فلش‌کارت: دیدن واژه، تلاش برای یادآوری، سپس انتخاب کیفیت یادآوری.
///
/// این جلسه «قلب» روش تکرار فاصله‌دار است؛ هر پاسخ، فاصله‌ی مرور بعدی را
/// تعیین می‌کند.
class LearnScreen extends StatefulWidget {
  const LearnScreen({super.key, required this.args});

  final LearnArgs args;

  @override
  State<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends State<LearnScreen> {
  late final List<Word> _words = widget.args.words ?? const <Word>[];
  late final DateTime _startedAt = DateTime.now();
  final Map<String, ReviewState> _appliedStates = <String, ReviewState>{};
  final List<QuizAttempt> _attempts = <QuizAttempt>[];

  int _index = 0;
  bool _flipped = false;
  bool _busy = false;
  bool _finished = false;
  int _correct = 0;
  int _xp = 0;
  bool _speaking = false;
  DateTime _cardStartedAt = DateTime.now();
  LearningOutcome? _outcome;

  Word? get _currentWord => _index < _words.length ? _words[_index] : null;

  @override
  void initState() {
    super.initState();
    final container = AppScope.maybeOf(context);
    container?.audio.warmUp();
  }

  Future<void> _speak(Word word) async {
    final container = AppScope.of(context);
    setState(() => _speaking = true);
    container.haptics.tap();
    await container.controller.speak(word.term);
    if (mounted) setState(() => _speaking = false);
  }

  Future<void> _grade(ReviewGrade grade) async {
    final word = _currentWord;
    if (word == null || _busy) return;
    setState(() => _busy = true);
    final container = AppScope.of(context);
    final elapsed = DateTime.now().difference(_cardStartedAt).inMilliseconds;

    final outcome = await container.controller.reviewWordByGrade(
      word: word,
      grade: grade,
      elapsedMs: elapsed,
    );

    final state = container.stores.statesStore.value[word.id];
    if (state != null) _appliedStates[word.id] = state;

    _attempts.add(
      QuizAttempt(
        question: QuizQuestion(
          id: 'card_${word.id}',
          type: QuizType.meaningChoice,
          word: word,
          correctAnswer: word.primaryMeaning,
        ),
        userAnswer: grade.shortLabel,
        isCorrect: !grade.isFailure,
        elapsedMs: elapsed,
      ),
    );

    if (!grade.isFailure) _correct += 1;
    _xp += outcome.xpEarned;

    if (grade.isFailure) {
      container.haptics.light();
    } else {
      container.haptics.success();
    }

    if (!mounted) return;
    if (_index + 1 >= _words.length) {
      await _finish();
    } else {
      setState(() {
        _index += 1;
        _flipped = false;
        _busy = false;
        _cardStartedAt = DateTime.now();
      });
    }
  }

  Future<void> _finish() async {
    final container = AppScope.of(context);
    final outcome = await container.controller.finishSession(
      kind: widget.args.kind,
      attempts: _attempts,
      startedAt: _startedAt,
      appliedStates: _appliedStates,
      isChallenge: widget.args.isChallenge,
      sessionXp: _xp,
    );
    if (!mounted) return;
    setState(() {
      _finished = true;
      _outcome = outcome;
      _busy = false;
    });
    if (outcome.leveledUp || outcome.unlockedAchievements.isNotEmpty) {
      container.haptics.celebrate();
    }
  }

  Future<bool> _confirmExit() async {
    if (_finished || _attempts.isEmpty) return true;
    return showConfirmDialog(
      context: context,
      title: 'جلسه را نیمه‌کاره رها کنی؟',
      message: 'پیشرفت کارت‌های پاسخ‌داده‌شده ذخیره می‌شود، اما جلسه ناتمام می‌ماند.',
      confirmLabel: 'خروج',
      cancelLabel: 'ادامه بدهم',
      destructive: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    if (_words.isEmpty) {
      return AppScaffold(
        title: widget.args.title ?? S.learnTitle,
        showBack: true,
        body: const EmptyStateView(
          title: 'واژه‌ای برای این جلسه پیدا نشد',
          message: 'کمی بعد دوباره امتحان کن یا از بخش کاوش یک بسته انتخاب کن.',
          emoji: '📭',
        ),
      );
    }

    return PopScope(
      canPop: _finished || _attempts.isEmpty,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldExit = await _confirmExit();
        if (shouldExit && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: palette.background,
        body: SafeArea(
          child: _finished
              ? SessionSummaryView(
                  title: S.sessionComplete,
                  subtitle: widget.args.kind.faTitle,
                  outcome: _outcome,
                  xp: _xp,
                  total: _attempts.length,
                  correct: _correct,
                  onDone: () => Navigator.of(context).pop(),
                  onRepeatMistakes: () {
                    final mistakes = _attempts
                        .where((attempt) => !attempt.isCorrect)
                        .map((attempt) => attempt.question.word)
                        .toList(growable: false);
                    if (mistakes.isEmpty) return;
                    Navigator.of(context).pushReplacement(
                      AppRouter.build<void>(
                        builder: (_) => LearnScreen(
                          args: LearnArgs(
                            kind: SessionKind.weak,
                            words: mistakes,
                            title: 'مرور اشتباه‌ها',
                            subtitle: '${mistakes.length} واژه',
                          ),
                        ),
                      ),
                    );
                  },
                )
              : _CardView(
                  word: _currentWord!,
                  index: _index,
                  total: _words.length,
                  flipped: _flipped,
                  xp: _xp,
                  speaking: _speaking,
                  busy: _busy,
                  state: AppScope.of(context).stores.statesStore.value[_currentWord!.id],
                  onFlip: () {
                    if (_flipped) return;
                    AppScope.of(context).haptics.tap();
                    setState(() => _flipped = true);
                  },
                  onSpeak: () => _speak(_currentWord!),
                  onGrade: _grade,
                  onClose: () async {
                    final shouldExit = await _confirmExit();
                    if (shouldExit && context.mounted) Navigator.of(context).pop();
                  },
                  onOpenDetail: () => Navigator.of(context).push(
                    AppRouter.build<void>(
                      settings: const RouteSettings(name: AppRoutes.wordDetail),
                      builder: (_) => WordDetailScreen(
                        args: WordDetailArgs(word: _currentWord!),
                      ),
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

/// نمای کارت جاری + دکمه‌های ارزیابی.
class _CardView extends StatelessWidget {
  const _CardView({
    required this.word,
    required this.index,
    required this.total,
    required this.flipped,
    required this.xp,
    required this.speaking,
    required this.busy,
    required this.state,
    required this.onFlip,
    required this.onSpeak,
    required this.onGrade,
    required this.onClose,
    required this.onOpenDetail,
  });

  final Word word;
  final int index;
  final int total;
  final bool flipped;
  final int xp;
  final bool speaking;
  final bool busy;
  final ReviewState? state;
  final VoidCallback onFlip;
  final VoidCallback onSpeak;
  final ValueChanged<ReviewGrade> onGrade;
  final VoidCallback onClose;
  final VoidCallback onOpenDetail;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    const srs = SpacedRepetitionEngine();
    final intervals = srs.previewIntervals(
      state ?? ReviewState(wordId: word.id),
    );

    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            children: <Widget>[
              CircleIconButton(
                icon: Icons.close_rounded,
                onPressed: onClose,
                size: 38,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  child: LinearProgressIndicator(
                    value: total == 0 ? 0 : (index + (flipped ? 0.5 : 0)) / total,
                    minHeight: 8,
                    backgroundColor: palette.surfaceAlt,
                    color: AppColors.brand,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '${FaFormat.digits(index + 1)}/${FaFormat.digits(total)}',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: palette.textSecondary,
                    ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.brandSoft,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Icon(Icons.bolt_rounded, size: 14, color: AppColors.brand),
                    const SizedBox(width: 3),
                    Text(
                      FaFormat.digits(xp),
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
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: FlipCard(
              showBack: flipped,
              onTap: onFlip,
              front: _CardFront(
                word: word,
                speaking: speaking,
                onSpeak: onSpeak,
                state: state,
              ),
              back: _CardBack(word: word),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: AnimatedSwitcher(
            duration: AppDurations.normal,
            child: flipped
                ? _GradeButtons(
                    busy: busy,
                    intervals: intervals,
                    onGrade: onGrade,
                  )
                : Column(
                    key: const ValueKey<String>('hint'),
                    children: <Widget>[
                      Text(
                        S.tapToFlip,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: palette.textTertiary,
                            ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      AppButton(
                        label: S.tapToFlip,
                        icon: Icons.flip_rounded,
                        onPressed: onFlip,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: AppButton(
                              label: 'تلفظ',
                              icon: Icons.volume_up_rounded,
                              variant: AppButtonVariant.secondary,
                              onPressed: onSpeak,
                              height: 46,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Expanded(
                            child: AppButton(
                              label: 'جزئیات واژه',
                              icon: Icons.info_outline_rounded,
                              variant: AppButtonVariant.ghost,
                              onPressed: onOpenDetail,
                              height: 46,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}

class _CardFront extends StatelessWidget {
  const _CardFront({
    required this.word,
    required this.speaking,
    required this.onSpeak,
    required this.state,
  });

  final Word word;
  final bool speaking;
  final VoidCallback onSpeak;
  final ReviewState? state;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: palette.border),
        boxShadow: AppShadows.soft(palette.isDark),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              TagChip(label: word.pos.faLabel, color: AppColors.brand),
              const SizedBox(width: AppSpacing.xs),
              CefrBadge(code: word.level.code, title: word.level.faTitle),
              if (word.premium) ...<Widget>[
                const SizedBox(width: AppSpacing.xs),
                const PremiumBadge(),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          ScaleTap(
            onTap: onSpeak,
            child: WordImage(word: word, size: 92, radius: AppRadius.md),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            word.term,
            textAlign: TextAlign.center,
            style: AppTypography.wordDisplay.copyWith(color: palette.textPrimary),
          ),
          if (word.ipa != null) ...<Widget>[
            const SizedBox(height: 6),
            Text(word.ipa!, style: AppTypography.ipa),
          ],
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              ScaleTap(
                onTap: onSpeak,
                child: PulsingHalo(
                  active: speaking,
                  size: 62,
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: AppColors.brandGradient,
                      shape: BoxShape.circle,
                      boxShadow: AppShadows.brandGlow(),
                    ),
                    child: const Icon(Icons.volume_up_rounded, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'خودت معنی را به یاد بیاور، بعد کارت را برگردان.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: palette.textTertiary,
                ),
          ),
          if (state != null && state!.totalReviews > 0) ...<Widget>[
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(
                  Icons.history_rounded,
                  size: 14,
                  color: palette.textTertiary,
                ),
                const SizedBox(width: 4),
                Text(
                  '${FaFormat.digits(state!.totalReviews)} مرور • '
                  'دقت ${FaFormat.percent(state!.accuracy * 100)}'
                  '${state!.lapses > 0 ? ' • ${FaFormat.digits(state!.lapses)} خطا' : ''}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: palette.textTertiary,
                      ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _CardBack extends StatelessWidget {
  const _CardBack({required this.word});

  final Word word;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final example = word.examples.isNotEmpty ? word.examples.first : null;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.brand.fade(0.35)),
        boxShadow: AppShadows.soft(palette.isDark),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    word.term,
                    style: AppTypography.wordTitle.copyWith(
                      color: palette.textPrimary,
                    ),
                  ),
                ),
                if (word.ipa != null)
                  Text(
                    word.ipa!,
                    style: AppTypography.ipa.copyWith(fontSize: 13),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            for (final meaning in word.faMeanings)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      margin: const EdgeInsets.only(top: 8, left: 8),
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.brand,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        meaning,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: palette.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            if (word.faDefinition.isNotEmpty) ...<Widget>[
              const SizedBox(height: AppSpacing.xs),
              Text(
                word.faDefinition,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: palette.textSecondary,
                    ),
              ),
            ],
            if (example != null) ...<Widget>[
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: palette.surfaceAlt,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      example.en,
                      style: AppTypography.answer.copyWith(
                        fontSize: 15,
                        color: palette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      example.fa,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: palette.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
            ],
            if (word.collocations.isNotEmpty) ...<Widget>[
              const SizedBox(height: AppSpacing.md),
              Text(
                S.collocationsSection,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: palette.textPrimary,
                    ),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xxs,
                children: <Widget>[
                  for (final collocation in word.collocations.take(4))
                    TagChip(label: collocation, color: AppColors.accent),
                ],
              ),
            ],
            if (word.persianNote != null) ...<Widget>[
              const SizedBox(height: AppSpacing.md),
              InfoBanner(
                text: word.persianNote!,
                icon: Icons.info_outline_rounded,
                color: palette.warning,
              ),
            ],
            if (word.mnemonic != null) ...<Widget>[
              const SizedBox(height: AppSpacing.sm),
              InfoBanner(
                text: 'ترفند حفظ: ${word.mnemonic}',
                icon: Icons.lightbulb_outline_rounded,
                color: AppColors.pink,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _GradeButtons extends StatelessWidget {
  const _GradeButtons({
    required this.busy,
    required this.intervals,
    required this.onGrade,
  });

  final bool busy;
  final Map<ReviewGrade, Duration> intervals;
  final ValueChanged<ReviewGrade> onGrade;

  static const Map<ReviewGrade, Color> _colors = <ReviewGrade, Color>{
    ReviewGrade.forgot: AppColors.danger,
    ReviewGrade.hard: AppColors.warning,
    ReviewGrade.good: AppColors.accent,
    ReviewGrade.easy: AppColors.brand,
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Text(
          S.howWellDidYouKnow,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppPalette.of(context).textTertiary,
              ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: <Widget>[
            for (final grade in ReviewGrade.values) ...<Widget>[
              Expanded(
                child: _GradeButton(
                  grade: grade,
                  color: _colors[grade] ?? AppColors.brand,
                  interval: intervals[grade] ?? Duration.zero,
                  onTap: busy ? null : () => onGrade(grade),
                ),
              ),
              if (grade != ReviewGrade.easy) const SizedBox(width: 6),
            ],
          ],
        ),
      ],
    );
  }
}

class _GradeButton extends StatelessWidget {
  const _GradeButton({
    required this.grade,
    required this.color,
    required this.interval,
    this.onTap,
  });

  final ReviewGrade grade;
  final Color color;
  final Duration interval;
  final VoidCallback? onTap;

  String get _intervalLabel {
    if (interval.inMinutes < 60) return '${FaFormat.digits(interval.inMinutes)} دقیقه';
    if (interval.inHours < 24) return '${FaFormat.digits(interval.inHours)} ساعت';
    if (interval.inDays < 30) return '${FaFormat.digits(interval.inDays)} روز';
    final months = (interval.inDays / 30).round();
    if (months < 12) return '${FaFormat.digits(months)} ماه';
    return '${FaFormat.digits((interval.inDays / 365).round())} سال';
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTap(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm, horizontal: 4),
        decoration: BoxDecoration(
          color: color.fade(0.14),
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: color.fade(0.4)),
        ),
        child: Column(
          children: <Widget>[
            Text(
              grade.shortLabel,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 2),
            Text(
              _intervalLabel,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: color.fade(0.9),
                    fontSize: 10,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
