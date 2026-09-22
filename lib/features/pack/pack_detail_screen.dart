import 'package:flutter/material.dart';

import '../../core/di/app_container.dart';
import '../../core/routing/app_router.dart';
import '../../core/state/value_store.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/utils/fa_format.dart';
import '../../domain/entities/pack.dart';
import '../../domain/entities/review_state.dart';
import '../../domain/entities/study_session.dart';
import '../../domain/entities/word.dart';
import '../../l10n/strings.dart';
import '../../widgets/animations.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/badges.dart';
import '../../widgets/progress_views.dart';
import '../../widgets/states.dart';
import '../../widgets/word_tile.dart';
import '../paywall/paywall_screen.dart';
import '../quiz/quiz_screen.dart';
import '../review/learn_screen.dart';
import '../word_detail/word_detail_screen.dart';

/// صفحه‌ی یک بسته‌ی موضوعی: پیشرفت، واژه‌ها و شروع سریع یادگیری/تمرین.
class PackDetailScreen extends StatelessWidget {
  const PackDetailScreen({super.key, required this.args});

  final PackArgs args;

  StudyPack get pack => args.pack;

  static const List<Gradient> _gradients = <Gradient>[
    AppColors.brandGradient,
    AppColors.accentGradient,
    AppColors.goldGradient,
    AppColors.sunsetGradient,
  ];

  @override
  Widget build(BuildContext context) {
    final container = AppScope.of(context);
    return Watch(
      listenables: <Listenable>[
        container.stores.packsStore,
        container.stores.statesStore,
        container.stores.subscriptionStore,
        container.stores.profileStore,
      ],
      builder: (context) {
        final all = container.controller.allWords;
        final states = container.controller.states;
        final target = container.controller.packs.firstWhere(
          (item) => item.id == pack.id,
          orElse: () => pack,
        );
        final words = _wordsOf(target, all);
        final locked = target.premium && !container.controller.hasPremium;

        return AppScaffold(
          title: target.title,
          subtitle: target.description,
          showBack: true,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          body: ListView(
            padding: const EdgeInsets.only(top: AppSpacing.xs, bottom: AppSpacing.lg),
            children: <Widget>[
              FadeSlideIn(child: _header(context, target, words, states)),
              const SizedBox(height: AppSpacing.md),
              if (locked)
                PremiumBanner(
                  title: S.premiumWordLocked,
                  subtitle: 'این بسته در نسخه‌ی ویژه باز می‌شود؛ با آزمایش رایگان امتحانش کن.',
                  margin: const EdgeInsets.only(bottom: AppSpacing.md),
                  onTap: () => Navigator.of(context).push(
                    AppRouter.build<void>(
                      settings: const RouteSettings(name: AppRoutes.paywall),
                      builder: (_) => const PaywallScreen(),
                    ),
                  ),
                ),
              SectionHeader(
                title: S.wordPacks,
                subtitle: '${FaFormat.digits(words.length)} واژه در این بسته',
                icon: Icons.list_alt_rounded,
              ),
              const SizedBox(height: AppSpacing.xs),
              for (final word in _preview(words, locked))
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: WordTile(
                    word: word,
                    state: states[word.id],
                    onTap: () => _openWord(context, word),
                  ),
                ),
              if (locked && words.length > _lockedPreview)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child: InfoBanner(
                    text: '${FaFormat.digits(words.length - _lockedPreview)} واژه‌ی دیگر '
                        'در نسخه‌ی ویژه باز می‌شود.',
                    icon: Icons.lock_rounded,
                    color: AppColors.gold,
                    actionLabel: S.upgradeCta,
                    onTap: () => Navigator.of(context).push(
                      AppRouter.build<void>(
                        settings: const RouteSettings(name: AppRoutes.paywall),
                        builder: (_) => const PaywallScreen(),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          bottomBar: _bottomBar(context, words, locked),
        );
      },
    );
  }

  static const int _lockedPreview = 3;

  List<Word> _preview(List<Word> words, bool locked) =>
      locked ? words.take(_lockedPreview).toList(growable: false) : words;

  List<Word> _wordsOf(StudyPack target, List<Word> all) {
    final index = <String, Word>{for (final word in all) word.id: word};
    final result = <Word>[];
    for (final id in target.wordIds) {
      final word = index[id];
      if (word != null) result.add(word);
    }
    return result;
  }

  Widget _header(
    BuildContext context,
    StudyPack target,
    List<Word> words,
    Map<String, ReviewState> states,
  ) {
    var learned = 0;
    var mastered = 0;
    var masterySum = 0.0;
    for (final word in words) {
      final state = states[word.id];
      if (state == null) continue;
      if (state.isActive) learned++;
      if (state.status == WordStatus.mastered) mastered++;
      masterySum += state.masteryPercent / 100;
    }
    final progress = words.isEmpty ? 0.0 : masterySum / words.length;

    return HighlightCard(
      gradient: _gradients[target.gradientSeed % _gradients.length],
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: Colors.white.fade(0.2),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                alignment: Alignment.center,
                child: Text(target.emoji, style: const TextStyle(fontSize: 26)),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      target.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      target.description,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.fade(0.88),
                        fontSize: 12,
                        height: 1.7,
                      ),
                    ),
                  ],
                ),
              ),
              ProgressRing(
                progress: progress.clamp(0.0, 1.0),
                size: 60,
                strokeWidth: 7,
                gradientColors: const <Color>[Colors.white, Color(0xFFF1ECFF)],
                trackColor: Colors.white.fade(0.28),
                center: Text(
                  FaFormat.percent(progress.clamp(0.0, 1.0) * 100),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: <Widget>[
              if (target.level != null) ...<Widget>[
                CefrBadge(
                  code: target.level!.code,
                  title: target.level!.faTitle,
                  dense: true,
                ),
                const SizedBox(width: 6),
              ],
              StatusPill(
                label: target.premium ? S.premium : S.free,
                color: Colors.white.fade(0.28),
              ),
              const Spacer(),
              Text(
                '${FaFormat.digits(learned)} یادگرفته • '
                '${FaFormat.digits(mastered)} تسلط',
                style: TextStyle(
                  color: Colors.white.fade(0.9),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: <Widget>[
              Expanded(
                child: _MetricPill(
                  label: 'واژه‌ها',
                  value: FaFormat.digits(words.length),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _MetricPill(
                  label: 'یادگرفته',
                  value: FaFormat.digits(learned),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _MetricPill(
                  label: 'مسلط',
                  value: FaFormat.digits(mastered),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget? _bottomBar(BuildContext context, List<Word> words, bool locked) {
    if (words.isEmpty) return null;
    if (locked) {
      return SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: AppButton(
            label: S.upgradeCta,
            icon: Icons.workspace_premium_rounded,
            variant: AppButtonVariant.gold,
            height: 48,
            onPressed: () => Navigator.of(context).push(
              AppRouter.build<void>(
                settings: const RouteSettings(name: AppRoutes.paywall),
                builder: (_) => const PaywallScreen(),
              ),
            ),
          ),
        ),
      );
    }
    final learnable = words.take(30).toList(growable: false);
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Row(
          children: <Widget>[
            Expanded(
              child: AppButton(
                label: 'یادگیری ${FaFormat.digits(learnable.length)} واژه',
                icon: Icons.play_arrow_rounded,
                height: 48,
                onPressed: () => _startSession(
                  context,
                  learnable,
                  SessionKind.learn,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            AppButton(
              label: 'تمرین',
              icon: Icons.quiz_rounded,
              variant: AppButtonVariant.secondary,
              expanded: false,
              height: 48,
              onPressed: () => Navigator.of(context).push(
                AppRouter.build<void>(
                  builder: (_) => QuizLauncherScreen(
                    words: learnable,
                    title: 'تمرین بسته‌ی ${pack.title}',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openWord(BuildContext context, Word word) {
    Navigator.of(context).push(
      AppRouter.build<void>(
        settings: const RouteSettings(name: AppRoutes.wordDetail),
        builder: (_) => WordDetailScreen(args: WordDetailArgs(word: word)),
      ),
    );
  }

  void _startSession(BuildContext context, List<Word> words, SessionKind kind) {
    Navigator.of(context).push(
      AppRouter.build<void>(
        settings: const RouteSettings(name: AppRoutes.learn),
        builder: (_) => LearnScreen(
          args: LearnArgs(
            kind: kind,
            words: words,
            title: kind == SessionKind.review ? S.startReview : S.startLearn,
            subtitle: '${FaFormat.digits(words.length)} واژه از ${pack.title}',
          ),
        ),
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.fade(0.16),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Column(
        children: <Widget>[
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.fade(0.85),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
