import 'package:flutter/material.dart';

import '../../core/di/app_container.dart';
import '../../core/routing/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_palette.dart';
import '../../core/utils/fa_format.dart';
import '../../domain/engines/level_engine.dart';
import '../../domain/engines/xp_engine.dart';
import '../../domain/entities/cefr_level.dart';
import '../../domain/entities/quiz_question.dart';
import '../../domain/entities/study_session.dart';
import '../../domain/entities/word.dart';
import '../../l10n/strings.dart';
import '../../widgets/animations.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/badges.dart';
import '../../widgets/progress_views.dart';
import '../../widgets/quiz_widgets.dart';
import '../../widgets/states.dart';

/// آزمون تعیین سطح تطبیقی.
///
/// سه مرحله دارد: معرفی ➜ آزمون (۱۸ سؤال تطبیقی) ➜ نتیجه و تنظیم سطح.
class PlacementScreen extends StatefulWidget {
  const PlacementScreen({super.key, required this.args, this.onFinished});

  final PlacementArgs args;

  /// وقتی از آنبوردینگ می‌آییم، به‌جای بازگشت ساده این callback صدا زده می‌شود.
  final ValueChanged<PlacementResult>? onFinished;

  @override
  State<PlacementScreen> createState() => _PlacementScreenState();
}

enum _Phase { intro, test, result }

class _PlacementScreenState extends State<PlacementScreen> {
  static const int _questionCount = 18;

  _Phase _phase = _Phase.intro;
  PlacementEngine? _engine;
  QuizQuestion? _question;
  PlacementResult? _result;
  final List<QuizAttempt> _attempts = <QuizAttempt>[];
  final List<String> _premiumHits = <String>[];

  int _answered = 0;
  int _correct = 0;
  int _xp = 0;
  String? _selected;
  bool _revealed = false;
  bool _isCorrect = false;
  bool _busy = false;
  bool _ready = false;
  DateTime _questionStartedAt = DateTime.now();
  DateTime _startedAt = DateTime.now();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _ready = true;
  }

  void _start() {
    final container = AppScope.of(context);
    final pool = container.controller.allWords
        .where((word) => word.faMeanings.isNotEmpty)
        .toList(growable: false);
    final engine = PlacementEngine(words: pool, maxQuestions: _questionCount);
    if (!engine.isUsable) {
      showToast(context, 'بانک واژه‌ها هنوز آماده نیست؛ کمی بعد امتحان کن.');
      return;
    }
    setState(() {
      _engine = engine;
      _question = engine.currentQuestion;
      _phase = _Phase.test;
      _startedAt = DateTime.now();
      _questionStartedAt = DateTime.now();
    });
  }

  Future<void> _choose(String value) async {
    final engine = _engine;
    final question = _question;
    if (engine == null || question == null || _revealed || _busy) return;

    final container = AppScope.of(context);
    final elapsed = DateTime.now().difference(_questionStartedAt).inMilliseconds;
    final isCorrect = QuizFactory.isAnswerCorrect(question, value);

    _attempts.add(
      QuizAttempt(
        question: question,
        userAnswer: value,
        isCorrect: isCorrect,
        elapsedMs: elapsed,
      ),
    );
    if (question.usesPremiumContent) _premiumHits.add(question.word.id);

    _answered += 1;
    if (isCorrect) {
      _correct += 1;
      container.haptics.success();
    } else {
      container.haptics.light();
    }
    _xp += XpEngine.forAnswer(
      type: question.type,
      isCorrect: isCorrect,
      combo: 0,
      isNewWord: false,
      isChallenge: false,
      level: container.controller.profile.level,
      elapsedMs: elapsed,
    ).amount;

    setState(() {
      _selected = value;
      _revealed = true;
      _isCorrect = isCorrect;
      _busy = true;
    });

    engine.submit(isCorrect: isCorrect);

    // مکث کوتاه برای دیدن بازخورد، سپس سؤال بعدی — ریتم آزمون سریع است.
    await Future<void>.delayed(const Duration(milliseconds: 520));
    if (!mounted) return;

    if (engine.isFinished) {
      await _finish(engine);
      return;
    }
    setState(() {
      _question = engine.currentQuestion;
      _selected = null;
      _revealed = false;
      _isCorrect = false;
      _busy = false;
      _questionStartedAt = DateTime.now();
    });
  }

  Future<void> _finish(PlacementEngine engine) async {
    final container = AppScope.of(context);
    final result = engine.result;
    await container.controller.applyPlacementResult(result);
    final outcome = await container.controller.finishSession(
      kind: SessionKind.placement,
      attempts: _attempts,
      startedAt: _startedAt,
      sessionXp: _xp,
    );
    if (!mounted) return;
    setState(() {
      _result = result;
      _phase = _Phase.result;
      _busy = false;
    });
    container.haptics.celebrate();
    if (outcome.leveledUp) {
      showToast(context, 'دستاورد تازه باز شد! 🎉');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) return const SizedBox.shrink();
    return Scaffold(
      backgroundColor: AppPalette.of(context).background,
      body: SafeArea(
        child: switch (_phase) {
          _Phase.intro => _IntroView(onStart: _start, retake: widget.args.retake),
          _Phase.test => _testView(),
          _Phase.result => _resultView(),
        },
      ),
    );
  }

  Widget _testView() {
    final question = _question;
    final engine = _engine;
    if (question == null || engine == null) {
      return const LoadingView(message: 'در حال آماده‌سازی آزمون…');
    }
    final palette = AppPalette.of(context);
    final progress = engine.progress;

    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  S.placementProgress,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: palette.textSecondary,
                      ),
                ),
              ),
              Text(
                '${FaFormat.digits(_answered)}/${FaFormat.digits(_questionCount)}',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: palette.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: AppProgressBar(
            progress: progress,
            gradient: AppColors.brandGradient,
            height: 8,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.xs,
              AppSpacing.md,
              AppSpacing.lg,
            ),
            children: <Widget>[
              FadeSlideIn(
                key: ValueKey<String>('pq_${question.id}'),
                child: QuizQuestionCard(question: question, revealed: _revealed),
              ),
              const SizedBox(height: AppSpacing.md),
              McqOptions(
                choices: question.choices,
                selected: _selected,
                correctAnswer: question.correctAnswer,
                revealed: _revealed,
                rtl: true,
                onSelect: _choose,
              ),
              if (_revealed) ...<Widget>[
                const SizedBox(height: AppSpacing.md),
                Center(
                  child: Text(
                    _isCorrect ? S.quizCorrect : S.quizWrong,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: _isCorrect ? palette.success : palette.danger,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _resultView() {
    final result = _result;
    if (result == null) return const SizedBox.shrink();
    final palette = AppPalette.of(context);
    final confidencePercent = (result.confidence * 100).round();

    return ListView(
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
              const Text('🧭', style: TextStyle(fontSize: 52)),
              const SizedBox(height: AppSpacing.sm),
              Text(
                S.placementResultTitle,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: palette.textPrimary,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                'بر اساس ${FaFormat.digits(result.totalQuestions)} پاسخ، سطح تو'
                ' ${result.level.faTitle} (${result.level.code}) است.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: palette.textSecondary,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        FadeSlideIn(
          child: HighlightCard(
            gradient: AppColors.brandGradient,
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: <Widget>[
                Text(
                  result.level.code,
                  style: const TextStyle(
                    fontSize: 46,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),
                Text(
                  result.level.faTitle,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.fade(0.9),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: AppSpacing.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    _ResultStat(
                      value: FaFormat.digits(result.correctCount),
                      label: 'پاسخ درست',
                    ),
                    _ResultStat(
                      value: FaFormat.digits(_xp),
                      label: S.earnedXp,
                    ),
                    _ResultStat(
                      value: FaFormat.percent(confidencePercent),
                      label: 'دقت تخمین',
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
                title: 'معنای این سطح برای تو',
                icon: Icons.auto_awesome_rounded,
              ),
              const SizedBox(height: AppSpacing.xs),
              InfoBanner(
                text: result.summaryFa,
                icon: Icons.tips_and_updates_rounded,
                color: AppColors.brand,
              ),
              const SizedBox(height: AppSpacing.xs),
              _LevelGuide(level: result.level),
            ],
          ),
        ),
        if (_premiumHits.isNotEmpty) ...<Widget>[
          const SizedBox(height: AppSpacing.md),
          InfoBanner(
            text: 'در آزمون با ${FaFormat.digits(_premiumHits.length)} واژه‌ی ویژه روبرو شدی؛ '
                'محتوای ویژه با اشتراک فعال می‌شود.',
            icon: Icons.workspace_premium_rounded,
            color: AppColors.gold,
            actionLabel: S.premium,
            onTap: () => Navigator.of(context).pushNamed(AppRoutes.paywall),
          ),
        ],
        const SizedBox(height: AppSpacing.xs),
        Text(
          S.placementResultBody,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: palette.textTertiary,
                height: 1.7,
              ),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppButton(
          label: S.placementResultStart,
          icon: Icons.play_arrow_rounded,
          onPressed: () {
            final callback = widget.onFinished;
            if (callback != null) {
              callback(result);
            } else {
              Navigator.of(context).maybePop();
            }
          },
        ),
        const SizedBox(height: AppSpacing.xs),
        AppButton(
          label: S.placementResultRetest,
          icon: Icons.restart_alt_rounded,
          variant: AppButtonVariant.ghost,
          onPressed: () => setState(() {
            _phase = _Phase.intro;
            _attempts.clear();
            _premiumHits.clear();
            _answered = 0;
            _correct = 0;
            _xp = 0;
            _selected = null;
            _revealed = false;
            _question = null;
            _engine = null;
            _result = null;
          }),
        ),
      ],
    );
  }
}

class _IntroView extends StatelessWidget {
  const _IntroView({required this.onStart, required this.retake});

  final VoidCallback onStart;
  final bool retake;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.xl,
        AppSpacing.md,
        AppSpacing.xl,
      ),
      children: <Widget>[
        Center(
          child: Column(
            children: <Widget>[
              const Text('🧭', style: TextStyle(fontSize: 56)),
              const SizedBox(height: AppSpacing.sm),
              Text(
                retake ? 'آزمون تعیین سطح جدید' : S.placementTitle,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: palette.textPrimary,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                S.placementIntro,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: palette.textSecondary,
                      height: 1.8,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppCard(
          child: Column(
            children: <Widget>[
              const _Rule(
                icon: Icons.timer_outlined,
                title: 'حدود ۵ دقیقه',
                body: '۱۸ سؤال که سختی‌شان با پاسخ‌های تو تنظیم می‌شود.',
              ),
              const _Rule(
                icon: Icons.trending_up_rounded,
                title: 'آزمون تطبیقی',
                body: 'هر چه بهتر جواب بدهی، سؤال بعدی سخت‌تر می‌شود.',
              ),
              const _Rule(
                icon: Icons.emoji_events_outlined,
                title: 'نتیجه‌ی دقیق',
                body: 'در پایان، سطح CEFR تو (A1 تا C2) و برنامه‌ی مناسبش را می‌گیری.',
              ),
              const _Rule(
                icon: Icons.lock_outline_rounded,
                title: 'بدون نمره‌ی منفی',
                body: 'پاسخ اشتباه فقط سطح را دقیق‌تر می‌کند؛ استرس ندارد!',
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppButton(
          label: S.placementStart,
          icon: Icons.play_arrow_rounded,
          onPressed: onStart,
        ),
        if (retake) ...<Widget>[
          const SizedBox(height: AppSpacing.xs),
          AppButton(
            label: S.cancel,
            variant: AppButtonVariant.ghost,
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ],
      ],
    );
  }
}

class _Rule extends StatelessWidget {
  const _Rule({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.brandSoft,
              borderRadius: BorderRadius.circular(AppRadius.xs),
            ),
            child: Icon(icon, size: 18, color: AppColors.brand),
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
                  body,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: palette.textSecondary,
                        height: 1.7,
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

class _ResultStat extends StatelessWidget {
  const _ResultStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.white.fade(0.85),
          ),
        ),
      ],
    );
  }
}

class _LevelGuide extends StatelessWidget {
  const _LevelGuide({required this.level});

  final CefrLevel level;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'مسیر پیشنهادی',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: palette.textSecondary,
              ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: <Widget>[
            for (final item in CefrLevel.values)
              TagChip(
                label: item.code,
                color: item.index <= level.index ? AppColors.brand : palette.textTertiary,
                dense: true,
                icon: item.index == level.index
                    ? Icons.my_location_rounded
                    : (item.index < level.index ? Icons.check_rounded : null),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          '${level.code}: ${level.faDescription}'
          '${level.index < CefrLevel.values.length - 1 ? ' • بعد از آن: ${CefrLevel.values[level.index + 1].faTitle}' : ''}',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: palette.textTertiary,
                height: 1.7,
              ),
        ),
      ],
    );
  }
}
