import 'package:flutter/material.dart';

import '../../core/di/app_container.dart';
import '../../core/routing/app_router.dart';
import '../../core/state/value_store.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_palette.dart';
import '../../core/utils/fa_format.dart';
import '../../core/utils/text_normalizer.dart';
import '../../domain/entities/cefr_level.dart';
import '../../domain/entities/pack.dart';
import '../../domain/entities/word.dart';
import '../../l10n/labels.dart';
import '../../l10n/strings.dart';
import '../../widgets/ad_slot.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/app_button.dart';
import '../../widgets/states.dart';
import '../../widgets/word_tile.dart';
import '../pack/pack_detail_screen.dart';
import '../word_detail/word_detail_screen.dart';
import '../word_list/word_list_screen.dart';

/// کاوش: جست‌وجوی واژه‌ها، بسته‌های موضوعی و مرور بر اساس سطح.
class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final TextEditingController _search = TextEditingController();
  String _query = '';
  CefrLevel? _levelFilter;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<Word> _filter(List<Word> words) {
    final query = TextNormalizer.normalizeEn(_query);
    final queryFa = TextNormalizer.normalizeFa(_query);
    return words.where((word) {
      if (_levelFilter != null && word.level != _levelFilter) return false;
      if (query.isEmpty) return true;
      if (TextNormalizer.normalizeEn(word.term).contains(query)) return true;
      if (TextNormalizer.normalizeFa(word.primaryMeaning).contains(queryFa)) {
        return true;
      }
      for (final meaning in word.faMeanings) {
        if (TextNormalizer.normalizeFa(meaning).contains(queryFa)) return true;
      }
      for (final synonym in word.synonyms) {
        if (TextNormalizer.normalizeEn(synonym).contains(query)) return true;
      }
      return false;
    }).toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final container = AppScope.of(context);
    final palette = AppPalette.of(context);
    final controller = container.controller;

    return Watch(
      listenables: <Listenable>[
        container.stores.wordsStore,
        container.stores.packsStore,
        container.stores.statesStore,
        container.stores.subscriptionStore,
      ],
      builder: (context) {
        final words = controller.allWords;
        final packs = controller.packs;
        final results = _query.isEmpty && _levelFilter == null
            ? const <Word>[]
            : _filter(words).take(40).toList(growable: false);
        final bookmarked = controller.states.entries
            .where((entry) => entry.value.bookmarked)
            .map((entry) => entry.key)
            .toList(growable: false);

        return AppScaffold(
          title: S.exploreTitle,
          subtitle: '${FaFormat.digits(words.length)} واژه • ${FaFormat.digits(packs.length)} بسته‌ی موضوعی',
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          body: ListView(
            padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
            children: <Widget>[
              TextField(
                controller: _search,
                textInputAction: TextInputAction.search,
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
              const SizedBox(height: AppSpacing.sm),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: <Widget>[
                    TagChip(
                      label: 'همه',
                      color: _levelFilter == null
                          ? AppColors.brand
                          : palette.textTertiary,
                      onTap: () => setState(() => _levelFilter = null),
                    ),
                    for (final level in CefrLevel.values) ...<Widget>[
                      const SizedBox(width: 6),
                      TagChip(
                        label: level.code,
                        color: _levelFilter == level
                            ? level.color
                            : palette.textTertiary,
                        onTap: () => setState(
                          () => _levelFilter =
                              _levelFilter == level ? null : level,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (results.isNotEmpty) ...<Widget>[
                const SizedBox(height: AppSpacing.md),
                SectionHeader(
                  title: 'نتیجه‌ی جست‌وجو',
                  subtitle: '${FaFormat.digits(results.length)} واژه پیدا شد',
                  icon: Icons.manage_search_rounded,
                ),
                const SizedBox(height: AppSpacing.xs),
                for (final word in results)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: WordTile(
                      word: word,
                      state: controller.states[word.id],
                      dense: true,
                      onTap: () => _openWord(context, word),
                    ),
                  ),
                if (results.length >= 40)
                  Center(
                    child: TextButton(
                      onPressed: () => _openList(
                        context,
                        WordListArgs(
                          title: _query.isEmpty ? S.allWords : 'نتایج «$_query»',
                          words: _filter(words),
                        ),
                      ),
                      child: const Text(S.seeAll),
                    ),
                  ),
              ] else if (_query.isNotEmpty) ...<Widget>[
                const SizedBox(height: AppSpacing.lg),
                const EmptyStateView(
                  title: S.noResult,
                  message: S.noResultHint,
                  emoji: '🔍',
                  compact: true,
                ),
              ],
              if (_query.isEmpty) ...<Widget>[
                const SizedBox(height: AppSpacing.md),
                SectionHeader(
                  title: 'بر اساس سطح',
                  subtitle: 'واژه‌های هر سطح CEFR را جدا ببین',
                  icon: Icons.stairs_rounded,
                ),
                const SizedBox(height: AppSpacing.xs),
                GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: AppSpacing.xs,
                  crossAxisSpacing: AppSpacing.xs,
                  childAspectRatio: 1.15,
                  children: <Widget>[
                    for (final level in CefrLevel.values)
                      AppCard(
                        padding: const EdgeInsets.all(AppSpacing.xs),
                        onTap: () => _openList(
                          context,
                          WordListArgs(
                            title: '${level.code} • ${level.faTitle}',
                            subtitle: level.faDescription,
                            initialLevel: level.code,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Text(
                              level.code,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: level.color,
                              ),
                            ),
                            Text(
                              level.faTitle,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(color: palette.textSecondary),
                            ),
                            Text(
                              '${FaFormat.digits(words.where((w) => w.level == level).length)} واژه',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(color: palette.textTertiary, fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                if (packs.isNotEmpty) ...<Widget>[
                  SectionHeader(
                    title: S.wordPacks,
                    subtitle: 'موضوع‌های پرکاربرد، دسته‌بندی‌شده',
                    icon: Icons.category_rounded,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  for (final pack in packs)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                      child: _PackTile(
                        pack: pack,
                        locked: pack.premium && !controller.hasPremium,
                        onTap: () => _openPack(context, pack),
                      ),
                    ),
                  const SizedBox(height: AppSpacing.md),
                ],
                SectionHeader(
                  title: 'مجموعه‌های من',
                  icon: Icons.collections_bookmark_rounded,
                ),
                const SizedBox(height: AppSpacing.xs),
                AppCard(
                  onTap: () => _openList(
                    context,
                    WordListArgs(
                      title: S.emptyBookmarks,
                      subtitle: 'واژه‌هایی که نشان‌گذاری کرده‌ای',
                      wordIds: bookmarked,
                    ),
                  ),
                  child: Row(
                    children: <Widget>[
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: AppColors.pinkSoft,
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: const Icon(
                          Icons.bookmark_rounded,
                          color: AppColors.pink,
                          size: 21,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              S.emptyBookmarks,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(color: palette.textPrimary),
                            ),
                            Text(
                              bookmarked.isEmpty
                                  ? 'هنوز واژه‌ای نشان‌گذاری نکرده‌ای'
                                  : '${FaFormat.digits(bookmarked.length)} واژه نشان‌شده',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(color: palette.textTertiary),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_left_rounded, color: palette.textTertiary),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                AppCard(
                  onTap: () => _openList(
                    context,
                    WordListArgs(title: S.allWords, showFilters: true),
                  ),
                  child: Row(
                    children: <Widget>[
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: AppColors.brandSoft,
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: const Icon(
                          Icons.list_alt_rounded,
                          color: AppColors.brand,
                          size: 21,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'همه‌ی واژه‌ها',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(color: palette.textPrimary),
                            ),
                            Text(
                              'جست‌وجو، فیلتر و مرتب‌سازی پیشرفته',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(color: palette.textTertiary),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_left_rounded, color: palette.textTertiary),
                    ],
                  ),
                ),
                if (!controller.hasPremium) ...<Widget>[
                  const SizedBox(height: AppSpacing.md),
                  const AdSlot(placement: 'explore'),
                ],
              ],
            ],
          ),
        );
      },
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

  void _openPack(BuildContext context, StudyPack pack) {
    Navigator.of(context).push(
      AppRouter.build<void>(
        settings: const RouteSettings(name: AppRoutes.pack),
        builder: (_) => PackDetailScreen(args: PackArgs(pack: pack)),
      ),
    );
  }

  void _openList(BuildContext context, WordListArgs args) {
    Navigator.of(context).push(
      AppRouter.build<void>(
        settings: const RouteSettings(name: AppRoutes.wordList),
        builder: (_) => WordListScreen(args: args),
      ),
    );
  }
}

class _PackTile extends StatelessWidget {
  const _PackTile({
    required this.pack,
    required this.locked,
    required this.onTap,
  });

  final StudyPack pack;
  final bool locked;
  final VoidCallback onTap;

  static const List<Gradient> _gradients = <Gradient>[
    AppColors.brandGradient,
    AppColors.accentGradient,
    AppColors.goldGradient,
    AppColors.sunsetGradient,
  ];

  @override
  Widget build(BuildContext context) {
    final gradient = _gradients[pack.gradientSeed % _gradients.length];
    return HighlightCard(
      gradient: gradient,
      padding: const EdgeInsets.all(AppSpacing.sm),
      onTap: onTap,
      child: Row(
        children: <Widget>[
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white.fade(0.22),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            alignment: Alignment.center,
            child: Text(pack.emoji, style: const TextStyle(fontSize: 22)),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Flexible(
                      child: Text(
                        pack.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (locked) ...<Widget>[
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.lock_rounded,
                        size: 13,
                        color: Colors.white,
                      ),
                    ],
                  ],
                ),
                Text(
                  pack.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.fade(0.88),
                    fontSize: 11,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${FaFormat.digits(pack.wordCount)} واژه'
                  '${pack.level != null ? ' • سطح ${pack.level!.code}' : ''}',
                  style: TextStyle(
                    color: Colors.white.fade(0.8),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_left_rounded, color: Colors.white),
        ],
      ),
    );
  }
}
