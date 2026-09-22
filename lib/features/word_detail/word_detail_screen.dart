import 'package:flutter/material.dart';

import '../../core/di/app_container.dart';
import '../../core/routing/app_router.dart';
import '../../core/state/value_store.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/fa_format.dart';
import '../../domain/entities/review_state.dart';
import '../../domain/entities/word.dart';
import '../../l10n/labels.dart';
import '../../l10n/strings.dart';
import '../../widgets/animations.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/badges.dart';
import '../../widgets/progress_views.dart';
import '../../widgets/states.dart';
import '../../widgets/word_tile.dart';
import '../chat/chat_screen.dart';
import '../quiz/quiz_screen.dart';

/// صفحه‌ی جزئیات واژه: همه‌ی محتوای آموزشی یک واژه در یک نگاه.
///
/// ساختار: سرصفحه (واژه + تلفظ + معنی) ➜ کارت تسلط ➜ بخش‌های محتوا
/// (مثال‌ها، مکالمه، سینما، کالوکیشن، مترادف/متضاد، شکل‌ها، نکته‌ی
/// فارسی‌زبان‌ها، ترفند حفظ) ➜ تمرین و یادداشت.
class WordDetailScreen extends StatefulWidget {
  const WordDetailScreen({super.key, required this.args});

  final WordDetailArgs args;

  @override
  State<WordDetailScreen> createState() => _WordDetailScreenState();
}

class _WordDetailScreenState extends State<WordDetailScreen> {
  final TextEditingController _note = TextEditingController();
  bool _noteOpen = false;
  bool _speaking = false;
  bool _savingNote = false;

  Word get _word => widget.args.word;

  @override
  void initState() {
    super.initState();
    final container = AppScope.maybeOf(context);
    _note.text = container?.controller.states[_word.id]?.note ?? '';
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _speak() async {
    final container = AppScope.of(context);
    setState(() => _speaking = true);
    await container.controller.speak(_word.term);
    if (!mounted) return;
    setState(() => _speaking = false);
  }

  Future<void> _toggleBookmark() async {
    final container = AppScope.of(context);
    await container.controller.toggleBookmark(_word.id);
    if (!mounted) return;
    final bookmarked =
        container.controller.states[_word.id]?.bookmarked ?? false;
    showToast(
      context,
      bookmarked ? S.addedToReview : S.unbookmark,
    );
  }

  Future<void> _saveNote() async {
    if (_savingNote) return;
    setState(() => _savingNote = true);
    final container = AppScope.of(context);
    await container.controller.saveWordNote(_word.id, _note.text.trim());
    if (!mounted) return;
    setState(() {
      _savingNote = false;
      _noteOpen = false;
    });
    showToast(context, S.savedToast);
  }

  void _practice() {
    Navigator.of(context).push(
      AppRouter.build<void>(
        settings: const RouteSettings(name: AppRoutes.quiz),
        builder: (_) => QuizLauncherScreen(words: <Word>[_word], title: _word.term),
      ),
    );
  }

  void _askAi() {
    Navigator.of(context).push(
      AppRouter.build<void>(
        settings: const RouteSettings(name: AppRoutes.chat),
        builder: (_) => ChatScreen(contextWord: _word),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final container = AppScope.of(context);
    final palette = AppPalette.of(context);
    final word = _word;
    final locked = word.premium && !container.controller.hasPremium;

    return StoreBuilder<Map<String, ReviewState>>(
      store: container.stores.statesStore,
      builder: (context, states) {
        final state = states[word.id];
        return AppScaffold(
          padding: EdgeInsets.zero,
          showBack: true,
          actions: <Widget>[
            CircleIconButton(
              icon: (state?.bookmarked ?? false)
                  ? Icons.bookmark_rounded
                  : Icons.bookmark_border_rounded,
              tooltip: S.bookmark,
              onPressed: _toggleBookmark,
            ),
            const SizedBox(width: AppSpacing.xs),
            CircleIconButton(
              icon: Icons.note_alt_outlined,
              tooltip: S.myNote,
              onPressed: () => setState(() => _noteOpen = !_noteOpen),
            ),
          ],
          body: ListView(
            padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
            children: <Widget>[
              _WordHeader(
                word: word,
                state: state,
                speaking: _speaking,
                onSpeak: _speak,
                locked: locked,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    if (locked) ...<Widget>[
                      PremiumBanner(
                        title: S.premiumWordLocked,
                        subtitle: 'این واژه بخشی از محتوای ویژه است؛ '
                            'با اشتراک فعال می‌شود.',
                        onTap: () => Navigator.of(context).pushNamed(AppRoutes.paywall),
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    _MasteryCard(state: state, word: word),
                    const SizedBox(height: AppSpacing.md),
                    if (_noteOpen) ...<Widget>[
                      AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            SectionHeader(
                              title: S.myNote,
                              icon: Icons.edit_note_rounded,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            TextField(
                              controller: _note,
                              maxLines: 3,
                              decoration: InputDecoration(
                                hintText: S.myNoteHint,
                                filled: true,
                                fillColor: palette.surfaceAlt,
                                border: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.sm),
                                  borderSide: BorderSide(color: palette.border),
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Row(
                              children: <Widget>[
                                Expanded(
                                  child: AppButton(
                                    label: S.save,
                                    height: 44,
                                    loading: _savingNote,
                                    onPressed: _saveNote,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.xs),
                                Expanded(
                                  child: AppButton(
                                    label: S.cancel,
                                    height: 44,
                                    variant: AppButtonVariant.ghost,
                                    onPressed: () =>
                                        setState(() => _noteOpen = false),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    if (state?.note != null && state!.note!.isNotEmpty) ...<Widget>[
                      InfoBanner(
                        text: 'یادداشت من: ${state.note}',
                        icon: Icons.sticky_note_2_outlined,
                        color: AppColors.info,
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: AppButton(
                            label: 'تمرین این واژه',
                            icon: Icons.quiz_rounded,
                            onPressed: locked ? null : _practice,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: AppButton(
                            label: S.askAi,
                            icon: Icons.chat_bubble_outline_rounded,
                            variant: AppButtonVariant.secondary,
                            onPressed: _askAi,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _Section(
                      title: S.meaningSection,
                      icon: Icons.translate_rounded,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          for (final meaning in word.faMeanings)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Container(
                                    margin: const EdgeInsets.only(top: 7, left: 8),
                                    width: 7,
                                    height: 7,
                                    decoration: const BoxDecoration(
                                      color: AppColors.brand,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      meaning,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall
                                          ?.copyWith(color: palette.textPrimary),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 4),
                          Text(
                            word.faDefinition,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: palette.textSecondary,
                                  height: 1.9,
                                ),
                          ),
                        ],
                      ),
                    ),
                    if (word.examples.isNotEmpty) ...<Widget>[
                      const SizedBox(height: AppSpacing.sm),
                      _Section(
                        title: S.examplesSection,
                        icon: Icons.format_quote_rounded,
                        child: Column(
                          children: <Widget>[
                            for (final example in word.examples)
                              _ExampleTile(
                                en: example.en,
                                fa: example.fa,
                                term: word.term,
                                label: example.kind.faLabel,
                                onSpeak: () => container.controller.speak(example.en),
                              ),
                          ],
                        ),
                      ),
                    ],
                    if (word.movieLines.isNotEmpty) ...<Widget>[
                      const SizedBox(height: AppSpacing.sm),
                      _Section(
                        title: S.mediaSection,
                        icon: Icons.movie_filter_outlined,
                        child: Column(
                          children: <Widget>[
                            for (final line in word.movieLines)
                              _MovieTile(
                                line: line,
                                term: word.term,
                                onSpeak: () => container.controller.speak(line.line),
                              ),
                          ],
                        ),
                      ),
                    ],
                    if (word.collocations.isNotEmpty) ...<Widget>[
                      const SizedBox(height: AppSpacing.sm),
                      _Section(
                        title: S.collocationsSection,
                        icon: Icons.link_rounded,
                        child: Wrap(
                          spacing: AppSpacing.xs,
                          runSpacing: AppSpacing.xs,
                          children: <Widget>[
                            for (final collocation in word.collocations)
                              TagChip(
                                label: collocation,
                                color: AppColors.accent,
                                icon: Icons.add_rounded,
                              ),
                          ],
                        ),
                      ),
                    ],
                    if (word.synonyms.isNotEmpty || word.antonyms.isNotEmpty) ...<Widget>[
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          if (word.synonyms.isNotEmpty)
                            Expanded(
                              child: _Section(
                                title: S.synonymsSection,
                                icon: Icons.sync_alt_rounded,
                                child: Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: <Widget>[
                                    for (final item in word.synonyms)
                                      TagChip(label: item, color: palette.success),
                                  ],
                                ),
                              ),
                            ),
                          if (word.synonyms.isNotEmpty && word.antonyms.isNotEmpty)
                            const SizedBox(width: AppSpacing.sm),
                          if (word.antonyms.isNotEmpty)
                            Expanded(
                              child: _Section(
                                title: S.antonymsSection,
                                icon: Icons.swap_horiz_rounded,
                                child: Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: <Widget>[
                                    for (final item in word.antonyms)
                                      TagChip(label: item, color: palette.danger),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                    if (word.forms.isNotEmpty) ...<Widget>[
                      const SizedBox(height: AppSpacing.sm),
                      _Section(
                        title: S.formsSection,
                        icon: Icons.rule_folder_outlined,
                        child: Column(
                          children: <Widget>[
                            for (final form in word.forms)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Row(
                                  children: <Widget>[
                                    SizedBox(
                                      width: 96,
                                      child: Text(
                                        form.label,
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelSmall
                                            ?.copyWith(color: palette.textTertiary),
                                      ),
                                    ),
                                    Expanded(
                                      child: Directionality(
                                        textDirection: TextDirection.ltr,
                                        child: Text(
                                          form.value,
                                          style: AppTypography.answer.copyWith(
                                            fontSize: 15,
                                            color: palette.textPrimary,
                                          ),
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
                    if (word.topics.isNotEmpty) ...<Widget>[
                      const SizedBox(height: AppSpacing.sm),
                      _Section(
                        title: S.topicsSection,
                        icon: Icons.local_offer_outlined,
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: <Widget>[
                            for (final topic in word.topics)
                              TagChip(
                                label: _topicLabel(topic),
                                color: palette.info,
                                dense: true,
                              ),
                          ],
                        ),
                      ),
                    ],
                    if (word.persianNote != null) ...<Widget>[
                      const SizedBox(height: AppSpacing.sm),
                      _Section(
                        title: S.persianNoteSection,
                        icon: Icons.lightbulb_outline_rounded,
                        child: InfoBanner(
                          text: word.persianNote!,
                          icon: Icons.info_outline_rounded,
                          color: AppColors.pink,
                        ),
                      ),
                    ],
                    if (word.mnemonic != null) ...<Widget>[
                      const SizedBox(height: AppSpacing.sm),
                      _Section(
                        title: S.mnemonicSection,
                        icon: Icons.psychology_alt_outlined,
                        child: InfoBanner(
                          text: word.mnemonic!,
                          icon: Icons.auto_awesome_rounded,
                          color: AppColors.gold,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.md),
                    _MetaCard(word: word),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static String _topicLabel(String topic) {
    const map = <String, String>{
      'daily': 'زندگی روزمره',
      'travel': 'سفر',
      'food': 'خوردنی‌ها',
      'business': 'کسب‌وکار',
      'academic': 'آکادمیک',
      'science': 'علم',
      'media': 'فیلم و سریال',
      'feelings': 'احساسات',
      'health': 'سلامت',
      'technology': 'فناوری',
      'sport': 'ورزش',
      'nature': 'طبیعت',
      'education': 'آموزش',
      'money': 'مالی',
      'family': 'خانواده',
      'work': 'کار',
    };
    return map[topic] ?? topic;
  }
}

/// پوشش سبک برای باز کردن جزئیات واژه از سایر صفحه‌ها.
class WordDetailLauncher extends StatelessWidget {
  const WordDetailLauncher({super.key, required this.word});

  final Word word;

  @override
  Widget build(BuildContext context) =>
      WordDetailScreen(args: WordDetailArgs(word: word));
}

class _WordHeader extends StatelessWidget {
  const _WordHeader({
    required this.word,
    required this.state,
    required this.speaking,
    required this.onSpeak,
    required this.locked,
  });

  final Word word;
  final ReviewState? state;
  final bool speaking;
  final VoidCallback onSpeak;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        MediaQuery.of(context).padding.top + 52,
        AppSpacing.md,
        AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            AppColors.brand.fade(palette.isDark ? 0.35 : 0.18),
            palette.background,
          ],
        ),
      ),
      child: Column(
        children: <Widget>[
          Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              WordImage(word: word, size: 96, radius: AppRadius.md),
              if (locked)
                Positioned(
                  right: -4,
                  top: -4,
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: const BoxDecoration(
                      gradient: AppColors.goldGradient,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lock_rounded,
                      size: 13,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Directionality(
            textDirection: TextDirection.ltr,
            child: Text(
              word.term,
              textAlign: TextAlign.center,
              style: AppTypography.wordDisplay.copyWith(
                color: palette.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 6,
            runSpacing: 6,
            children: <Widget>[
              TagChip(label: word.pos.faLabel, color: AppColors.brand, dense: true),
              CefrBadge(
                code: word.level.code,
                title: word.level.faTitle,
                dense: true,
              ),
              TagChip(
                label: '${S.difficultyLabel}: ${word.difficultyLabelFa}',
                color: AppColors.pink,
                dense: true,
              ),
              if (word.frequencyRank > 0)
                TagChip(
                  label: 'کاربرد #${FaFormat.digits(word.frequencyRank)}',
                  color: palette.info,
                  dense: true,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (word.ipa != null || word.ipaUk != null)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                if (word.ipa != null)
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: Text('US ${word.ipa}', style: AppTypography.ipa),
                  ),
                if (word.ipa != null && word.ipaUk != null)
                  const SizedBox(width: AppSpacing.sm),
                if (word.ipaUk != null)
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: Text('UK ${word.ipaUk}', style: AppTypography.ipa),
                  ),
              ],
            ),
          const SizedBox(height: AppSpacing.sm),
          ScaleTap(
            onTap: onSpeak,
            child: PulsingHalo(
              active: speaking,
              size: 72,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: AppColors.brandGradient,
                  shape: BoxShape.circle,
                  boxShadow: AppShadows.brandGlow(),
                ),
                child: Icon(
                  speaking ? Icons.volume_up_rounded : Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
          ),
          Text(
            S.pronunciationSection,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: palette.textTertiary,
                ),
          ),
        ],
      ),
    );
  }
}

class _MasteryCard extends StatelessWidget {
  const _MasteryCard({required this.state, required this.word});

  final ReviewState? state;
  final Word word;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final current = state ?? ReviewState(wordId: word.id);
    final mastery = current.masteryPercent;
    final due = current.dueAt;
    final now = DateTime.now();
    final dueLabel = due == null
        ? 'هنوز مرور نشده'
        : current.isDue(now)
            ? 'همین حالا برای مرور آماده است'
            : 'مرور بعدی: ${FaFormat.dueLabel(current.timeUntilDue(now))}';

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: SectionHeader(
                  title: 'وضعیت یادگیری',
                  subtitle: dueLabel,
                  icon: Icons.timeline_rounded,
                ),
              ),
              StatusPill(
                label: current.status.faLabel,
                color: Color(current.status.colorValue),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          AppProgressBar(
            progress: mastery / 100,
            gradient: AppColors.brandGradient,
            height: 8,
          ),
          const SizedBox(height: 6),
          Text(
            'تسلط ${FaFormat.percent(mastery)} • '
            '${FaFormat.digits(current.totalReviews)} مرور • '
            'دقت ${FaFormat.percent(current.accuracy * 100)}'
            '${current.lapses > 0 ? ' • ${FaFormat.digits(current.lapses)} فراموشی' : ''}',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: palette.textTertiary,
                ),
          ),
          if (current.status == WordStatus.leech) ...<Widget>[
            const SizedBox(height: AppSpacing.xs),
            InfoBanner(
              text: 'این واژه چند بار فراموش شده؛ ترفند حفظ را بخوان و '
                  'کالوکیشن‌هایش را به خاطر بسپار.',
              icon: Icons.priority_high_rounded,
              color: palette.warning,
            ),
          ],
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SectionHeader(title: title, icon: icon),
          const SizedBox(height: AppSpacing.xs),
          child,
        ],
      ),
    );
  }
}

class _ExampleTile extends StatelessWidget {
  const _ExampleTile({
    required this.en,
    required this.fa,
    required this.term,
    required this.label,
    required this.onSpeak,
  });

  final String en;
  final String fa;
  final String term;
  final String label;
  final VoidCallback onSpeak;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                TagChip(label: label, color: palette.textTertiary, dense: true),
                const SizedBox(height: 4),
                RichText(
                  textDirection: TextDirection.ltr,
                  text: _highlight(context, en, term, palette),
                ),
                const SizedBox(height: 2),
                Text(
                  fa,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: palette.textSecondary,
                        height: 1.8,
                      ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onSpeak,
            icon: const Icon(Icons.volume_up_outlined, size: 19),
            tooltip: S.playAudio,
            color: palette.textTertiary,
          ),
        ],
      ),
    );
  }

  TextSpan _highlight(
    BuildContext context,
    String sentence,
    String term,
    AppPalette palette,
  ) {
    final base = AppTypography.answer.copyWith(
      fontSize: 15,
      color: palette.textPrimary,
      height: 1.6,
    );
    final lowerSentence = sentence.toLowerCase();
    final lowerTerm = term.toLowerCase();
    final index = lowerSentence.indexOf(lowerTerm);
    if (index < 0) return TextSpan(text: sentence, style: base);
    final prefix = sentence.substring(0, index);
    final match = sentence.substring(index, index + term.length);
    final suffix = sentence.substring(index + term.length);
    return TextSpan(
      style: base,
      children: <TextSpan>[
        TextSpan(text: prefix),
        TextSpan(
          text: match,
          style: base.copyWith(
            color: AppColors.brand,
            fontWeight: FontWeight.w800,
            backgroundColor: AppColors.brandSoft,
          ),
        ),
        TextSpan(text: suffix),
      ],
    );
  }
}

class _MovieTile extends StatelessWidget {
  const _MovieTile({
    required this.line,
    required this.term,
    required this.onSpeak,
  });

  final MovieLine line;
  final String term;
  final VoidCallback onSpeak;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: palette.surfaceAlt,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: palette.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                const Icon(
                  Icons.movie_creation_outlined,
                  size: 16,
                  color: AppColors.pink,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    line.year == null
                        ? line.sourceTitle
                        : '${line.sourceTitle} (${FaFormat.digits(line.year!)})',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: palette.textSecondary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                if (line.character != null)
                  Text(
                    line.character!,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: palette.textTertiary,
                        ),
                  ),
                IconButton(
                  onPressed: onSpeak,
                  icon: const Icon(Icons.volume_up_outlined, size: 18),
                  color: palette.textTertiary,
                  tooltip: S.playAudio,
                ),
              ],
            ),
            Directionality(
              textDirection: TextDirection.ltr,
              child: Text(
                '«${line.line}»',
                style: AppTypography.answer.copyWith(
                  fontSize: 15,
                  color: palette.textPrimary,
                  height: 1.7,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              line.fa,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: palette.textSecondary,
                    height: 1.8,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaCard extends StatelessWidget {
  const _MetaCard({required this.word});

  final Word word;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SectionHeader(
            title: S.relatedWords,
            subtitle: 'واژه‌های هم‌خانواده و موضوعی',
            icon: Icons.hub_outlined,
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: <Widget>[
              Expanded(
                child: _MetaItem(
                  label: S.frequencyLabel,
                  value: word.frequencyRank > 0
                      ? '#${FaFormat.digits(word.frequencyRank)}'
                      : '—',
                  color: palette.info,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: _MetaItem(
                  label: S.difficultyLabel,
                  value: word.difficultyLabelFa,
                  color: AppColors.pink,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: _MetaItem(
                  label: 'سطح',
                  value: word.level.code,
                  color: AppColors.brand,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetaItem extends StatelessWidget {
  const _MetaItem({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xs),
      decoration: BoxDecoration(
        color: color.fade(0.12),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Column(
        children: <Widget>[
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w800,
                ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: palette.textTertiary,
                  fontSize: 10,
                ),
          ),
        ],
      ),
    );
  }
}
