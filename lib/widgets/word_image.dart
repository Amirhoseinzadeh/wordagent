import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_dimens.dart';
import '../core/theme/app_palette.dart';
import '../domain/entities/word.dart';
import '../l10n/strings.dart';

/// تصویر پیوست واژه — قلاب حافظه‌ی بصری.
///
/// ترتیب اولویت:
///   ۱) تصویر محلی بسته (`assets/images/…`) که با محتوا عرضه می‌شود،
///   ۲) تصویر آنلاین (`image_url`) که از به‌روزرسانی محتوا می‌آید،
///   ۳) کارت تزئینی با حرف نخست واژه.
///
/// نبودِ تصویر خطا نیست؛ رابط کاربری در هر حالت چیزی برای نشان‌دادن دارد و
/// اپ کاملاً آفلاین هم کار می‌کند.
class WordImageCard extends StatelessWidget {
  const WordImageCard({
    super.key,
    required this.word,
    this.height = 172,
    this.compact = false,
  });

  final Word word;
  final double height;

  /// حالت فشرده: بدون متن راهنما (برای کارت‌های کوچک‌تر).
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final asset = word.imageAsset;
    final url = word.imageUrl;
    final hasAsset = asset != null && asset.trim().isNotEmpty;
    final hasUrl = url != null && url.trim().isNotEmpty;

    return ClipRRect(
      borderRadius: AppRadius.cardLarge,
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: hasAsset
            ? Image.asset(
                asset,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stack) => _Fallback(
                  word: word,
                  compact: compact,
                ),
              )
            : hasUrl
                ? Image.network(
                    url,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stack) => _Fallback(
                      word: word,
                      compact: compact,
                    ),
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return _Fallback(word: word, compact: compact, loading: true);
                    },
                  )
                : _Fallback(word: word, compact: compact),
      ),
    );
  }
}

/// کارت تزئینی جانشین تصویر: گرادیان برند + حرف نخست واژه.
class _Fallback extends StatelessWidget {
  const _Fallback({
    required this.word,
    required this.compact,
    this.loading = false,
  });

  final Word word;
  final bool compact;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final textTheme = Theme.of(context).textTheme;
    final initial = word.term.trim().isEmpty
        ? '؟'
        : word.term.trim().substring(0, 1).toUpperCase();

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: <Color>[
            AppColors.brand.fade(palette.isDark ? 0.30 : 0.16),
            AppColors.gold.fade(palette.isDark ? 0.18 : 0.10),
          ],
        ),
        border: Border.all(color: palette.border),
        borderRadius: AppRadius.cardLarge,
      ),
      child: Stack(
        children: <Widget>[
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: AppSpacing.md),
              child: Text(
                initial,
                style: TextStyle(
                  fontSize: compact ? 44 : 62,
                  fontWeight: FontWeight.w800,
                  color: AppColors.brand.fade(palette.isDark ? 0.34 : 0.24),
                ),
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(
                  loading ? Icons.sync_rounded : Icons.image_outlined,
                  size: 26,
                  color: palette.textTertiary,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  S.wordImageSoon,
                  style: textTheme.labelSmall?.copyWith(
                    color: palette.textSecondary,
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
