import 'package:flutter/material.dart';

import '../../core/di/app_container.dart';
import '../../core/routing/app_router.dart';
import '../../core/state/value_store.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_palette.dart';
import '../../core/utils/fa_format.dart';
import '../../domain/entities/cefr_level.dart';
import '../../domain/entities/review_state.dart';
import '../../domain/entities/study_session.dart';
import '../../domain/engines/word_search.dart';
import '../../domain/entities/word.dart';
import '../../l10n/labels.dart';
import '../../l10n/strings.dart';
import '../../widgets/animations.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/states.dart';
import '../../widgets/word_tile.dart';
import '../quiz/quiz_screen.dart';
import '../review/learn_screen.dart';
import '../word_detail/word_detail_screen.dart';

/// فهرست واژه‌ها با فیلتر، مرتب‌سازی و شروع سریع مطالعه.
class WordListScreen extends StatefulWidget {
  const WordListScreen({super.key, required this.args});

  final WordListArgs args;

  @override
  State<WordListScreen> createState() => _WordListScreenState();
}

enum _SortMode { frequency, difficulty, recent, alphabetical }

class _WordListScreenState extends State<WordListScreen> {
  final TextEditingController _search = TextEditingController();
  String _query = '';
  CefrLevel? _level;
  WordStatus? _status;
  bool _bookmarkedOnly = false;
  String? _topic;
  _SortMode _sort = _SortMode.frequency;

  @override
  void initState() {
    super.initState();
    final initial = widget.args.initialLevel;
    if (initial != null) {
      _level = CefrLevel.fromCode(initial);
    }
    _topic = widget.args.topic;
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<Word> _source(List<Word> all, Map<String, ReviewState> states) {
    final args = widget.args;
    if (args.words != null) return args.words!;
    if (args.wordIds != null) {
      final index = <String, Word>{for (final word in all) word.id: word};
      final result = <Word>[];
      for (final id in args.wordIds!) {
        final word = index[id];
        if (word != null) result.add(word);
      }
      return result;
    }
    return all;
  }

  List<Word> _apply(List<Word> words, Map<String, ReviewState> states) {
    final filtered = words.where((word) {
      if (_level != null && word.level != _level) return false;
      if (_topic != null && !word.topics.contains(_topic)) return false;
      final state = states[word.id];
      if (_bookmarkedOnly && !(state?.bookmarked ?? false)) return false;
      if (_status != null) {
        final status = state?.status ?? WordStatus.fresh;
        if (_status == WordStatus.leech) {
          if (status != WordStatus.leech) return false;
        } else if (status != _status) {
          return false;
        }
      }
      return WordSearch.matches(word, _query);
    }).toList(growable: false);

    final sorted = List<Word>.of(filtered);
    switch (_sort) {
      case _SortMode.frequency:
        sorted.sort((a, b) {
          final rankA = a.frequencyRank == 0 ? 1 << 30 : a.frequencyRank;
          final rankB = b.frequencyRank == 0 ? 1 << 30 : b.frequencyRank;
          if (rankA != rankB) return rankA.compareTo(rankB);
          return a.term.compareTo(b.term);
        });
      case _SortMode.difficulty:
        sorted.sort((a, b) {
          if (a.difficulty != b.difficulty) {
            return a.difficulty.compareTo(b.difficulty);
          }
          return a.level.index.compareTo(b.level.index);
        });
      case _SortMode.recent:
        sorted.sort((a, b) {
          final dateA = states[a.id]?.lastReviewedAt ?? states[a.id]?.firstSeenAt;
          final dateB = states[b.id]?.lastReviewedAt ?? states[b.id]?.firstSeenAt;
          if (dateA == null && dateB == null) return a.term.compareTo(b.term);
          if (dateA == null) return 1;
          if (dateB == null) return -1;
          return dateB.compareTo(dateA);
        });
      case _SortMode.alphabetical:
        sorted.sort((a, b) => a.term.toLowerCase().compareTo(b.term.toLowerCase()));
    }
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    final container = AppScope.of(context);
    final args = widget.args;
    final palette = AppPalette.of(context);

    return StoreBuilder<Map<String, ReviewState>>(
      store: container.stores.statesStore,
      builder: (context, states) {
        final source = _source(container.controller.allWords, states);
        final words = _apply(source, states);
        final learnable = words.take(30).toList(growable: false);

        return AppScaffold(
          title: args.title,
          subtitle: args.subtitle ??
              '${FaFormat.digits(words.length)} واژه از '
                  '${FaFormat.digits(source.length)}',
          showBack: true,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          actions: <Widget>[
            PopupMenuButton<_SortMode>(
              icon: const Icon(Icons.sort_rounded),
              tooltip: S.sortByFrequency,
              color: palette.surface,
              onSelected: (value) => setState(() => _sort = value),
              itemBuilder: (context) => const <PopupMenuEntry<_SortMode>>[
                PopupMenuItem<_SortMode>(
                  value: _SortMode.frequency,
                  child: Text(S.sortByFrequency),
                ),
                PopupMenuItem<_SortMode>(
                  value: _SortMode.difficulty,
                  child: Text(S.sortByDifficulty),
                ),
                PopupMenuItem<_SortMode>(
                  value: _SortMode.recent,
                  child: Text(S.sortByRecent),
                ),
                PopupMenuItem<_SortMode>(
                  value: _SortMode.alphabetical,
                  child: Text('الفبایی (A→Z)'),
                ),
              ],
            ),
          ],
          body: Column(
            children: <Widget>[
              if (args.showFilters) ...<Widget>[
                TextField(
                  controller: _search,
                  onChanged: (value) => setState(() => _query = value),
                  decoration: InputDecoration(
                    hintText: S.searchHint,
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.close_rounded, size: 18),
                            onPressed: () {
                              _search.clear();
                              setState(() => _query = '');
                            },
                          ),
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
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: <Widget>[
                      TagChip(
                        label: S.statusAll,
                        color: _level == null &&
                                _status == null &&
                                _topic == null &&
                                !_bookmarkedOnly
                            ? AppColors.brand
                            : palette.textTertiary,
                        dense: true,
                        onTap: () => setState(() {
                          _level = null;
                          _status = null;
                          _topic = null;
                          _bookmarkedOnly = false;
                        }),
                      ),
                      for (final level in CefrLevel.values) ...<Widget>[
                        const SizedBox(width: 6),
                        TagChip(
                          label: level.code,
                          color: _level == level ? level.color : palette.textTertiary,
                          dense: true,
                          onTap: () => setState(
                            () => _level = _level == level ? null : level,
                          ),
                        ),
                      ],
                      for (final status in WordStatus.values) ...<Widget>[
                        const SizedBox(width: 6),
                        TagChip(
                          label: status.faLabel,
                          color: _status == status
                              ? Color(status.colorValue)
                              : palette.textTertiary,
                          dense: true,
                          onTap: () => setState(
                            () => _status = _status == status ? null : status,
                          ),
                        ),
                      ],
                      if (_topic != null) ...<Widget>[
                        const SizedBox(width: 6),
                        TagChip(
                          label: 'موضوع: ${TopicLabels.fa(_topic!)}',
                          color: palette.info,
                          dense: true,
                          icon: Icons.local_offer_outlined,
                          onTap: () => setState(() => _topic = null),
                        ),
                      ],
                      const SizedBox(width: 6),
                      TagChip(
                        label: S.statusBookmarked,
                        color: _bookmarkedOnly ? AppColors.pink : palette.textTertiary,
                        dense: true,
                        icon: Icons.bookmark_rounded,
                        onTap: () =>
                            setState(() => _bookmarkedOnly = !_bookmarkedOnly),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
              ],
              Expanded(
                child: words.isEmpty
                    ? EmptyStateView(
                        title: S.noResult,
                        message: S.noResultHint,
                        emoji: '🗂️',
                        actionLabel: S.statusAll,
                        onAction: () => setState(() {
                          _query = '';
                          _search.clear();
                          _level = null;
                          _status = null;
                          _bookmarkedOnly = false;
                        }),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
                        itemCount: words.length,
                        itemBuilder: (context, index) {
                          final word = words[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                            child: WordTile(
                              word: word,
                              state: states[word.id],
                              onTap: () => Navigator.of(context).push(
                                AppRouter.build<void>(
                                  settings: const RouteSettings(
                                    name: AppRoutes.wordDetail,
                                  ),
                                  builder: (_) => WordDetailScreen(
                                    args: WordDetailArgs(word: word),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
              if (learnable.isNotEmpty)
                SafeArea(
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
                            onPressed: () => Navigator.of(context).push(
                              AppRouter.build<void>(
                                settings:
                                    const RouteSettings(name: AppRoutes.learn),
                                builder: (_) => LearnScreen(
                                  args: LearnArgs(
                                    kind: SessionKind.learn,
                                    words: learnable,
                                    title: 'یادگیری واژه‌های تازه',
                                    subtitle: '${learnable.length} واژه',
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        ScaleTap(
                          onTap: () => Navigator.of(context).push(
                            AppRouter.build<void>(
                              settings: const RouteSettings(name: AppRoutes.quiz),
                              builder: (_) => QuizLauncherScreen(
                                words: learnable,
                                title: args.title,
                              ),
                            ),
                          ),
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.brandSoft,
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                            ),
                            child: const Icon(
                              Icons.quiz_rounded,
                              color: AppColors.brand,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
