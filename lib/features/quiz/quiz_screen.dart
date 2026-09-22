import 'package:flutter/material.dart';

import '../../core/di/app_container.dart';
import '../../core/di/app_controller.dart';
import '../../core/routing/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_palette.dart';
import '../../core/utils/fa_format.dart';
import '../../domain/engines/quiz_engine.dart';
import '../../domain/engines/xp_engine.dart';
import '../../domain/entities/quiz_question.dart';
import '../../domain/entities/study_session.dart';
import '../../domain/entities/word.dart';
import '../../l10n/strings.dart';
import '../../widgets/animations.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/quiz_widgets.dart';
import '../../widgets/session_summary.dart';
import '../../widgets/states.dart';

/// تمرین ترکیبی/تک‌مهارتی.
///
/// همه‌ی انواع سؤال (معنی، شنیداری، تایپ، جمله‌سازی، کالوکیشن، مترادف و
/// متضاد) از یک موتور واحد می‌آیند؛ این صفحه فقط چرخه‌ی پرسش–پاسخ و
/// بازخورد را مدیریت می‌کند.
class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key, required this.args});

  final QuizArgs args;

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  static const List<QuizType> _defaultTypes = <QuizType>[
    QuizType.meaningChoice,
    QuizType.wordChoice,
    QuizType.fillBlank,
    QuizType.listening,
    QuizType.typeMeaning,
    QuizType.collocation,
    QuizType.sentenceBuild,
    QuizType.synonym,
    QuizType.antonym,
    QuizType.typeWord,
  ];

  final TextEditingController _typing = TextEditingController();
  final ScrollController _scroll = ScrollController();

  List<QuizQuestion> _questions = const <QuizQuestion>[];
  final List<QuizAttempt> _attempts = <QuizAttempt>[];
  final List<String> _tokens = <String>[];

  DateTime _startedAt = DateTime.now();
  DateTime _questionStartedAt = DateTime.now();
  LearningOutcome? _outcome;

  int _index = 0;
  int _correct = 0;
  int _xp = 0;
  int _combo = 0;
  String? _selected;
  bool _revealed = false;
  bool _isCorrect = false;
  bool _nearly = false;
  bool _playing = false;
  bool _finished = false;
  bool _busy = false;
  bool _ready = false;

  QuizQuestion? get _question =>
      _index < _questions.length ? _questions[_index] : null;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_ready) return;
    _ready = true;
    _prepare();
  }

  @override
  void dispose() {
    _typing.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _prepare() {
    final container = AppScope.of(context);
    final args = widget.args;
    final precomputed = args.precomputedQuestions;
    if (precomputed != null && precomputed.isNotEmpty) {
      _questions = precomputed;
    } else {
      final pool = container.controller.allWords;
      final types = args.forcedType == null
          ? _defaultTypes
          : <QuizType>[args.forcedType!];
      _questions = QuizFactory().buildSet(
        words: args.words,
        pool: pool,
        preferredTypes: types,
        allowTypedPractice: true,
        maxQuestions: args.isChallenge ? 10 : 15,
      );
    }
    _startedAt = DateTime.now();
    _questionStartedAt = DateTime.now();
    _autoPlay();
  }

  Future<void> _autoPlay() async {
    final question = _question;
    final container = AppScope.of(context);
    if (question == null) return;
    if (question.type != QuizType.listening) return;
    if (!container.controller.settings.autoPlayAudio) return;
    await _play(question.audioText ?? question.word.term);
  }

  Future<void> _play(String text) async {
    final container = AppScope.of(context);
    setState(() => _playing = true);
    await container.controller.speak(text);
    if (!mounted) return;
    setState(() => _playing = false);
  }

  String _currentAnswer() {
    final question = _question;
    if (question == null) return '';
    switch (question.type) {
      case QuizType.sentenceBuild:
        return _tokens.join(' ');
      case QuizType.typeMeaning:
      case QuizType.typeWord:
      case QuizType.listening:
        return _typing.text.trim();
      case QuizType.meaningChoice:
      case QuizType.wordChoice:
      case QuizType.fillBlank:
      case QuizType.collocation:
      case QuizType.synonym:
      case QuizType.antonym:
        return _selected ?? '';
    }
  }

  void _check() {
    final question = _question;
    if (question == null || _revealed || _busy) return;
    final answer = _currentAnswer();
    if (answer.isEmpty) {
      showToast(context, 'اول پاسخت را بنویس یا انتخاب کن.');
      return;
    }
    _submit(answer);
  }

  void _choose(String value) {
    final question = _question;
    if (question == null || _revealed) return;
    setState(() => _selected = value);
    // در انتخاب چندگزینه‌ای، انتخاب کاربر بلافاصله بررسی می‌شود تا
    // حس «بازی» سریع‌تر باشد.
    _submit(value);
  }

  void _submit(String answer) {
    final question = _question;
    if (question == null) return;
    final container = AppScope.of(context);
    final elapsed = DateTime.now().difference(_questionStartedAt).inMilliseconds;
    final isCorrect = QuizFactory.isAnswerCorrect(question, answer);
    final nearly = !isCorrect && QuizFactory.isNearlyCorrect(question, answer);

    _attempts.add(
      QuizAttempt(
        question: question,
        userAnswer: answer,
        isCorrect: isCorrect,
        elapsedMs: elapsed,
      ),
    );

    if (isCorrect) {
      _correct += 1;
      _combo += 1;
      container.haptics.success();
    } else {
      _combo = 0;
      container.haptics.light();
    }

    final award = XpEngine.forAnswer(
      type: question.type,
      isCorrect: isCorrect,
      combo: _combo > 1 ? _combo - 1 : 0,
      isNewWord: false,
      isChallenge: widget.args.isChallenge,
      level: container.controller.profile.level,
      elapsedMs: elapsed,
    );
    _xp += award.amount;

    setState(() {
      _revealed = true;
      _isCorrect = isCorrect;
      _nearly = nearly;
    });
  }

  Future<void> _next() async {
    if (_index + 1 >= _questions.length) {
      await _finish();
      return;
    }
    setState(() {
      _index += 1;
      _revealed = false;
      _isCorrect = false;
      _nearly = false;
      _selected = null;
      _tokens.clear();
      _typing.clear();
      _questionStartedAt = DateTime.now();
    });
    if (_scroll.hasClients) _scroll.jumpTo(0);
    await _autoPlay();
  }

  Future<void> _finish() async {
    final container = AppScope.of(context);
    setState(() => _busy = true);
    final outcome = await container.controller.submitAttempts(
      kind: widget.args.kind,
      attempts: _attempts,
      startedAt: _startedAt,
      isChallenge: widget.args.isChallenge,
      bonusXp: widget.args.isChallenge ? 15 : 0,
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

  void _restart() {
    setState(() {
      _questions = const <QuizQuestion>[];
      _attempts.clear();
      _tokens.clear();
      _typing.clear();
      _index = 0;
      _correct = 0;
      _xp = 0;
      _combo = 0;
      _selected = null;
      _revealed = false;
      _isCorrect = false;
      _nearly = false;
      _finished = false;
      _outcome = null;
    });
    _prepare();
    setState(() {});
  }

  Future<bool> _confirmExit() async {
    if (_finished || _attempts.isEmpty) return true;
    return showConfirmDialog(
      context: context,
      title: 'تمرین را نیمه‌کاره رها کنی؟',
      message: 'پاسخ‌های این جلسه ثبت نمی‌شود.',
      confirmLabel: 'خروج',
      cancelLabel: 'ادامه بدهم',
      destructive: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final question = _question;

    if (_questions.isEmpty) {
      return AppScaffold(
        title: widget.args.title ?? S.quizTitle,
        showBack: true,
        body: EmptyStateView(
          title: 'برای این تمرین سؤالی ساخته نشد',
          message: 'واژه‌های بیشتری یاد بگیر یا نوع تمرین دیگری را امتحان کن.',
          emoji: '🧩',
          actionLabel: S.back,
          onAction: () => Navigator.of(context).maybePop(),
        ),
      );
    }

    return PopScope(
      canPop: _finished || _attempts.isEmpty,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldExit = await _confirmExit();
        if (shouldExit && context.mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
        backgroundColor: palette.background,
        body: SafeArea(
          child: _finished
              ? SessionSummaryView(
                  title: S.quizResult,
                  subtitle: widget.args.title ??
                      '${widget.args.kind.faTitle} • ${question?.type.faTitle ?? ''}',
                  outcome: _outcome,
                  total: _attempts.length,
                  correct: _correct,
                  xp: _xp,
                  emoji: _correct / (_attempts.isEmpty ? 1 : _attempts.length) >= 0.8
                      ? '🏆'
                      : '📝',
                  onDone: () => Navigator.of(context).pop(),
                  onRepeatMistakes: _restart,
                )
              : Column(
                  children: <Widget>[
                    QuizHeader(
                      index: _index,
                      total: _questions.length,
                      sessionXp: _xp,
                      combo: _combo,
                      onClose: () async {
                        final shouldExit = await _confirmExit();
                        if (shouldExit && context.mounted) Navigator.of(context).pop();
                      },
                    ),
                    Expanded(
                      child: ListView(
                        controller: _scroll,
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.md,
                          AppSpacing.sm,
                          AppSpacing.md,
                          AppSpacing.lg,
                        ),
                        children: <Widget>[
                          FadeSlideIn(
                            key: ValueKey<String>('q_${question!.id}'),
                            child: QuizQuestionCard(
                              question: question,
                              revealed: _revealed,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          if (question.type == QuizType.listening) ...<Widget>[
                            Center(
                              child: ListenButton(
                                label: 'پخش دوباره',
                                large: true,
                                playing: _playing,
                                onPlay: () => _play(
                                  question.audioText ?? question.word.term,
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                          ],
                          _answerArea(question),
                          if (_revealed) ...<Widget>[
                            const SizedBox(height: AppSpacing.md),
                            FeedbackBanner(
                              isCorrect: _isCorrect,
                              nearlyCorrect: _nearly,
                              correctAnswer: question.correctAnswer,
                              explanation: _explanationOf(question),
                              isLast: _index + 1 >= _questions.length,
                              onNext: _next,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  String? _explanationOf(QuizQuestion question) {
    final parts = <String>[];
    if (question.feedbackFa != null && question.feedbackFa!.isNotEmpty) {
      parts.add(question.feedbackFa!);
    }
    if (question.word.persianNote != null) {
      parts.add('نکته: ${question.word.persianNote}');
    }
    return parts.isEmpty ? null : parts.join('\n');
  }

  Widget _answerArea(QuizQuestion question) {
    switch (question.type) {
      case QuizType.sentenceBuild:
        return SentenceBuilder(
          available: question.tokens,
          selected: _tokens,
          revealed: _revealed,
          isCorrect: _isCorrect,
          correctSentence: question.correctAnswer,
          onAdd: _revealed
              ? (_) {}
              : (token) => setState(() => _tokens.add(token)),
          onRemove: _revealed
              ? (_) {}
              : (token) => setState(() => _tokens.remove(token)),
        );
      case QuizType.typeMeaning:
      case QuizType.typeWord:
      case QuizType.listening:
        final english = question.type != QuizType.typeMeaning;
        return TypingAnswerField(
          controller: _typing,
          onSubmit: _check,
          revealed: _revealed,
          isCorrect: _isCorrect,
          english: english,
          enabled: !_revealed,
          hint: english ? 'واژه را انگلیسی بنویس' : 'معنی را فارسی بنویس',
        );
      case QuizType.meaningChoice:
        return McqOptions(
          choices: question.choices,
          selected: _selected,
          correctAnswer: question.correctAnswer,
          revealed: _revealed,
          rtl: true,
          onSelect: _choose,
        );
      case QuizType.wordChoice:
      case QuizType.fillBlank:
      case QuizType.collocation:
      case QuizType.synonym:
      case QuizType.antonym:
        return McqOptions(
          choices: question.choices,
          selected: _selected,
          correctAnswer: question.correctAnswer,
          revealed: _revealed,
          onSelect: _choose,
        );
    }
  }
}

/// انتخاب نوع تمرین پیش از شروع جلسه.
class QuizLauncherScreen extends StatelessWidget {
  const QuizLauncherScreen({super.key, required this.words, this.title});

  final List<Word> words;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final factory = QuizFactory();
    final available = <QuizType>[
      for (final type in QuizType.values)
        if (words.any((word) => factory.supports(word, type))) type,
    ];

    return AppScaffold(
      title: title ?? S.quizTitle,
      subtitle: '${FaFormat.digits(words.length)} واژه • نوع تمرین را انتخاب کن',
      showBack: true,
      body: ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.xl),
        children: <Widget>[
          _LauncherTile(
            title: 'تمرین ترکیبی',
            subtitle: 'ترکیبی از همه‌ی مهارت‌ها — پیشنهاد ما',
            icon: Icons.auto_awesome_rounded,
            color: AppColors.brand,
            badge: '${FaFormat.digits(words.length)} سؤال',
            onTap: () => _start(context, null),
          ),
          const SizedBox(height: AppSpacing.xs),
          SectionHeader(
            title: 'تمرین تک‌مهارتی',
            icon: Icons.tune_rounded,
          ),
          const SizedBox(height: AppSpacing.xs),
          for (final type in QuizType.values)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: _LauncherTile(
                title: type.faTitle,
                subtitle: _subtitleFor(type),
                icon: QuizQuestionCard.iconFor(type),
                color: palette.info,
                badge: available.contains(type)
                    ? '${FaFormat.digits(words.where((word) => factory.supports(word, type)).length)} واژه'
                    : 'ناموجود',
                onTap: available.contains(type) ? () => _start(context, type) : null,
              ),
            ),
        ],
      ),
    );
  }

  void _start(BuildContext context, QuizType? type) {
    Navigator.of(context).push(
      AppRouter.build<void>(
        settings: const RouteSettings(name: AppRoutes.quiz),
        builder: (_) => QuizScreen(
          args: QuizArgs(
            words: words,
            kind: SessionKind.quiz,
            forcedType: type,
            title: type == null ? 'تمرین ترکیبی' : type.faTitle,
          ),
        ),
      ),
    );
  }

  static String _subtitleFor(QuizType type) {
    switch (type) {
      case QuizType.meaningChoice:
        return 'واژه را ببین و معنی فارسی را انتخاب کن';
      case QuizType.wordChoice:
        return 'معنی را ببین و واژه‌ی درست را انتخاب کن';
      case QuizType.fillBlank:
        return 'جای خالی جمله را با واژه‌ی درست پر کن';
      case QuizType.typeMeaning:
        return 'معنی فارسی را خودت تایپ کن';
      case QuizType.typeWord:
        return 'واژه‌ی انگلیسی را خودت تایپ کن';
      case QuizType.listening:
        return 'واژه را بشنو و بنویس';
      case QuizType.sentenceBuild:
        return 'کلمه‌ها را مرتب کن تا جمله ساخته شود';
      case QuizType.collocation:
        return 'ترکیب درست واژه‌ها را تشخیص بده';
      case QuizType.synonym:
        return 'مترادف نزدیک را پیدا کن';
      case QuizType.antonym:
        return 'متضاد درست را پیدا کن';
    }
  }
}

class _LauncherTile extends StatelessWidget {
  const _LauncherTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.badge,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String badge;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final enabled = onTap != null;
    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: Container(
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: palette.border),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Row(
                children: <Widget>[
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: color.fade(0.14),
                      borderRadius: BorderRadius.circular(AppRadius.xs),
                    ),
                    child: Icon(icon, color: color, size: 22),
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
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: palette.textTertiary,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    badge,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: palette.textSecondary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  Icon(
                    Icons.chevron_left_rounded,
                    color: palette.textTertiary,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
