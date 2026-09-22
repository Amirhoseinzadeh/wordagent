import 'package:flutter/material.dart';

import '../../core/di/app_container.dart';
import '../../core/routing/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_palette.dart';
import '../../core/utils/fa_format.dart';
import '../../domain/entities/cefr_level.dart';
import '../../domain/entities/settings.dart';
import '../../domain/entities/user_profile.dart';
import '../../l10n/strings.dart';
import '../../widgets/animations.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/badges.dart';
import '../placement/placement_screen.dart';

/// آنبوردینگ کوتاه و هدفمند: نام، هدف، سطح و هدف روزانه.
///
/// در پایان، پروفایل ذخیره می‌شود و کاربر (در صورت انتخاب) به آزمون
/// تعیین سطح می‌رود.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const int _steps = 5;

  final PageController _page = PageController();
  final TextEditingController _name = TextEditingController();

  int _index = 0;
  LearningGoal _goal = LearningGoal.travel;
  CefrLevel _level = CefrLevel.a1;
  bool _takePlacement = true;
  int _dailyMinutes = 10;
  int _dailyNewWords = 10;
  bool _saving = false;

  @override
  void dispose() {
    _page.dispose();
    _name.dispose();
    super.dispose();
  }

  void _next() {
    if (_index >= _steps - 1) {
      _finish();
      return;
    }
    _page.nextPage(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  void _back() {
    if (_index == 0) return;
    _page.previousPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _finish() async {
    if (_saving) return;
    setState(() => _saving = true);
    final container = AppScope.of(context);
    final settings = container.controller.settings.copyWith(
      dailyGoalMinutes: _dailyMinutes,
      dailyNewWords: _dailyNewWords,
    );
    await container.controller.completeOnboarding(
      name: _name.text,
      goal: _goal,
      level: _level,
      newSettings: settings,
    );
    if (!mounted) return;
    setState(() => _saving = false);

    if (_takePlacement) {
      Navigator.of(context).pushReplacement(
        AppRouter.build<void>(
          settings: const RouteSettings(name: AppRoutes.placement),
          builder: (context) => PlacementScreen(
            args: const PlacementArgs(),
            onFinished: (_) => Navigator.of(context).pushReplacementNamed(
              AppRoutes.shell,
            ),
          ),
        ),
      );
      return;
    }
    Navigator.of(context).pushReplacementNamed(AppRoutes.shell);
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                0,
              ),
              child: Row(
                children: <Widget>[
                  if (_index > 0)
                    IconButton(
                      onPressed: _back,
                      icon: const Icon(Icons.arrow_forward_rounded),
                    )
                  else
                    const SizedBox(width: 46),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      child: LinearProgressIndicator(
                        value: (_index + 1) / _steps,
                        minHeight: 6,
                        backgroundColor: palette.surfaceAlt,
                        color: AppColors.brand,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  TextButton(
                    onPressed: _finish,
                    child: Text(
                      S.skip,
                      style: TextStyle(color: palette.textTertiary),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _page,
                physics: const ClampingScrollPhysics(),
                onPageChanged: (value) => setState(() => _index = value),
                children: <Widget>[
                  _WelcomeStep(),
                  _NameStep(controller: _name),
                  _GoalStep(
                    selected: _goal,
                    onSelect: (goal) => setState(() => _goal = goal),
                  ),
                  _LevelStep(
                    level: _level,
                    takePlacement: _takePlacement,
                    onLevel: (level) => setState(() => _level = level),
                    onPlacement: (value) => setState(() => _takePlacement = value),
                  ),
                  _DailyGoalStep(
                    minutes: _dailyMinutes,
                    newWords: _dailyNewWords,
                    onMinutes: (value) => setState(() => _dailyMinutes = value),
                    onNewWords: (value) => setState(() => _dailyNewWords = value),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: AppButton(
                label: _index >= _steps - 1
                    ? (_takePlacement
                        ? S.onboardingLevelTest
                        : S.onboardingGetStarted)
                    : S.next,
                icon: _index >= _steps - 1
                    ? Icons.rocket_launch_rounded
                    : Icons.arrow_back_rounded,
                loading: _saving,
                onPressed: _next,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepShell extends StatelessWidget {
  const _StepShell({
    required this.emoji,
    required this.title,
    required this.body,
    this.children = const <Widget>[],
  });

  final String emoji;
  final String title;
  final String body;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
      ),
      children: <Widget>[
        Text(emoji, style: const TextStyle(fontSize: 46), textAlign: TextAlign.center),
        const SizedBox(height: AppSpacing.sm),
        Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: palette.textPrimary,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          body,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: palette.textSecondary,
                height: 1.9,
              ),
        ),
        const SizedBox(height: AppSpacing.lg),
        ...children,
      ],
    );
  }
}

class _WelcomeStep extends StatelessWidget {
  static const List<(String, String)> _features = <(String, String)>[
    ('🧠', 'تکرار فاصله‌دار هوشمند: هر واژه دقیقاً سر وقت مرور می‌شود'),
    ('🗣️', 'تلفظ، معنی دقیق فارسی، مثال واقعی و کاربرد در مکالمه'),
    ('🎯', 'تشخیص نقطه‌ضعف و تمرین اختصاصی روی همان واژه‌ها'),
    ('🔥', 'زنجیره‌ی روزانه، امتیاز، دستاورد و چالش روزانه'),
  ];

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return _StepShell(
      emoji: '📚',
      title: 'به ${S.appName} خوش آمدی',
      body: 'لغت‌یار هوشمند تو برای یادگیری واژه‌های انگلیسی؛ '
          'فارسی، ساده و متناسب با سطح خودت.',
      children: <Widget>[
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              for (final feature in _features)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(feature.$1, style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          feature.$2,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: palette.textSecondary,
                                height: 1.8,
                              ),
                        ),
                      ),
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

class _NameStep extends StatelessWidget {
  const _NameStep({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return _StepShell(
      emoji: '👋',
      title: S.onboardingNameQuestion,
      body: 'اسمت را بنویس تا برنامه را با همین اسم برایت بسازیم.',
      children: <Widget>[
        TextField(
          controller: controller,
          textAlign: TextAlign.center,
          textInputAction: TextInputAction.done,
          maxLength: 24,
          decoration: InputDecoration(
            hintText: S.onboardingNameHint,
            counterText: '',
            filled: true,
            fillColor: palette.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide(color: palette.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide(color: palette.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: const BorderSide(color: AppColors.brand, width: 1.6),
            ),
          ),
        ),
      ],
    );
  }
}

class _GoalStep extends StatelessWidget {
  const _GoalStep({required this.selected, required this.onSelect});

  final LearningGoal selected;
  final ValueChanged<LearningGoal> onSelect;

  @override
  Widget build(BuildContext context) {
    return _StepShell(
      emoji: '🎯',
      title: S.onboardingGoalQuestion,
      body: 'بر اساس هدفت، واژه‌ها و مثال‌های مرتبط با همان موضوع را می‌بینیم.',
      children: <Widget>[
        for (final goal in LearningGoal.values)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: _ChoiceTile(
              emoji: goal.emoji,
              title: goal.faTitle,
              subtitle: 'موضوع‌ها: ${goal.topics.join(' • ')}',
              selected: goal == selected,
              onTap: () => onSelect(goal),
            ),
          ),
      ],
    );
  }
}

class _LevelStep extends StatelessWidget {
  const _LevelStep({
    required this.level,
    required this.takePlacement,
    required this.onLevel,
    required this.onPlacement,
  });

  final CefrLevel level;
  final bool takePlacement;
  final ValueChanged<CefrLevel> onLevel;
  final ValueChanged<bool> onPlacement;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return _StepShell(
      emoji: '🧭',
      title: S.onboardingLevelQuestion,
      body: 'اگر سطحت را می‌دانی انتخاب کن؛ وگرنه آزمون کوتاه تعیین سطح '
          'در ۵ دقیقه سطح درست را پیدا می‌کند.',
      children: <Widget>[
        _ChoiceTile(
          emoji: '⚡',
          title: S.onboardingLevelTest,
          subtitle: '۱۸ سؤال تطبیقی • دقیق‌ترین راه • پیشنهاد ما',
          selected: takePlacement,
          onTap: () => onPlacement(true),
        ),
        const SizedBox(height: AppSpacing.xs),
        _ChoiceTile(
          emoji: '✅',
          title: S.onboardingLevelKnow,
          subtitle: 'سطح خودم را انتخاب می‌کنم',
          selected: !takePlacement,
          onTap: () => onPlacement(false),
        ),
        if (!takePlacement) ...<Widget>[
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: <Widget>[
              for (final item in CefrLevel.values)
                TagChip(
                  label: '${item.code} • ${item.faTitle}',
                  color: item == level ? AppColors.brand : palette.textTertiary,
                  dense: false,
                  icon: item == level ? Icons.check_rounded : null,
                  onTap: () => onLevel(item),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            level.faDescription,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: palette.textSecondary,
                ),
          ),
        ],
      ],
    );
  }
}

class _DailyGoalStep extends StatelessWidget {
  const _DailyGoalStep({
    required this.minutes,
    required this.newWords,
    required this.onMinutes,
    required this.onNewWords,
  });

  final int minutes;
  final int newWords;
  final ValueChanged<int> onMinutes;
  final ValueChanged<int> onNewWords;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return _StepShell(
      emoji: '⏱️',
      title: S.onboardingDailyGoalQuestion,
      body: S.onboardingDailyGoalHint,
      children: <Widget>[
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                S.dailyGoalLabel,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: palette.textPrimary,
                    ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: <Widget>[
                  for (final value in <int>[5, 10, 15, 20, 30])
                    TagChip(
                      label: '${FaFormat.digits(value)} دقیقه',
                      color: value == minutes ? AppColors.brand : palette.textTertiary,
                      icon: value == minutes ? Icons.check_rounded : null,
                      onTap: () => onMinutes(value),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                S.wordsPerDayLabel,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: palette.textPrimary,
                    ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: <Widget>[
                  for (final value in <int>[5, 10, 15, 20])
                    TagChip(
                      label: '${FaFormat.digits(value)} واژه',
                      color:
                          value == newWords ? AppColors.accent : palette.textTertiary,
                      icon: value == newWords ? Icons.check_rounded : null,
                      onTap: () => onNewWords(value),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'می‌توانی هر زمان از تنظیمات تغییرشان بدهی.',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: palette.textTertiary,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String emoji;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return ScaleTap(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppDurations.fast,
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: selected ? AppColors.brandSoft : palette.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: selected ? AppColors.brand : palette.border,
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Row(
          children: <Widget>[
            Text(emoji, style: const TextStyle(fontSize: 22)),
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
            if (selected)
              const Icon(Icons.check_circle_rounded, color: AppColors.brand),
          ],
        ),
      ),
    );
  }
}
