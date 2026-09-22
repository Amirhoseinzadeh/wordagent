import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_dimens.dart';
import '../core/theme/app_palette.dart';
import '../core/theme/app_typography.dart';
import '../core/utils/fa_format.dart';
import '../domain/entities/review_state.dart';
import '../domain/entities/word.dart';
import 'animations.dart';
import 'app_button.dart';
import 'badges.dart';

/// تصویر یک واژه: تصویر محتوا، تصویر شبکه‌ای، یا جای‌گزین رنگی با ایموجی.
///
/// جای‌گزین بر پایه‌ی شناسه‌ی واژه ساخته می‌شود، پس هر واژه هویت بصری
/// پایدار خودش را دارد (و هیچ فایل تصویری اضافه‌ای به بسته‌ی اپ نمی‌افزاید).
class WordImage extends StatelessWidget {
  const WordImage({
    super.key,
    required this.word,
    this.size = 56,
    this.radius = AppRadius.sm,
    this.showEmojiOnly = false,
  });

  final Word word;
  final double size;
  final double radius;
  final bool showEmojiOnly;

  static const List<List<Color>> _palettes = <List<Color>>[
    <Color>[Color(0xFF6C4CF1), Color(0xFF9E8BFF)],
    <Color>[Color(0xFF00BFA5), Color(0xFF5CE0CC)],
    <Color>[Color(0xFFF5A524), Color(0xFFFFD166)],
    <Color>[Color(0xFFF04492), Color(0xFFFF8FC4)],
    <Color>[Color(0xFF2E90FA), Color(0xFF84CAFF)],
    <Color>[Color(0xFF17B26A), Color(0xFF75E0A7)],
  ];

  List<Color> get _palette =>
      _palettes[word.id.hashCode.abs() % _palettes.length];

  static String _initial(String term) {
    final trimmed = term.trim();
    if (trimmed.isEmpty) return '?';
    return String.fromCharCode(trimmed.runes.first).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final asset = word.imageAsset;
    final url = word.imageUrl;
    Widget child;
    if (asset != null && !showEmojiOnly) {
      child = Image.asset(
        asset,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stack) => _fallback(context),
      );
    } else if (url != null && !showEmojiOnly) {
      child = Image.network(
        url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stack) => _fallback(context),
        loadingBuilder: (context, widget, progress) =>
            progress == null ? widget : _fallback(context),
      );
    } else {
      child = _fallback(context);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: child,
    );
  }

  Widget _fallback(BuildContext context) {
    final colors = _palette;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: colors,
        ),
      ),
      alignment: Alignment.center,
      child: word.emoji != null
          ? Text(word.emoji!, style: TextStyle(fontSize: size * 0.44))
          : Text(
              _initial(word.term),
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: size * 0.4,
              ),
            ),
    );
  }
}

/// ردیف نمایش یک واژه در فهرست‌ها.
class WordTile extends StatelessWidget {
  const WordTile({
    super.key,
    required this.word,
    this.state,
    this.onTap,
    this.trailing,
    this.showLevel = true,
    this.dense = false,
  });

  final Word word;
  final ReviewState? state;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool showLevel;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final currentState = state;
    return ScaleTap(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(dense ? AppSpacing.xs : AppSpacing.sm),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: palette.border),
        ),
        child: Row(
          children: <Widget>[
            WordImage(word: word, size: dense ? 40 : 48),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Flexible(
                        child: Text(
                          word.term,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.wordTitle.copyWith(
                            fontSize: dense ? 16 : 18,
                            color: palette.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      if (word.premium) const PremiumBadge(dense: true),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    word.primaryMeaning,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: palette.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: <Widget>[
                      TagChip(label: word.pos.faLabel, dense: true),
                      const SizedBox(width: 4),
                      if (showLevel)
                        CefrBadge(
                          code: word.level.code,
                          title: word.level.faTitle,
                          dense: true,
                        ),
                      if (currentState != null) ...<Widget>[
                        const SizedBox(width: 4),
                        StatusPill(
                          label: _statusLabel(currentState.status),
                          color: _statusColor(currentState.status, palette),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            if (trailing != null) ...<Widget>[
              const SizedBox(width: AppSpacing.xs),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }

  static String _statusLabel(WordStatus status) {
    switch (status) {
      case WordStatus.fresh:
        return 'جدید';
      case WordStatus.learning:
        return 'در حال یادگیری';
      case WordStatus.reviewing:
        return 'در حال مرور';
      case WordStatus.mastered:
        return 'مسلط';
      case WordStatus.leech:
        return 'سخت‌آموز';
    }
  }

  static Color _statusColor(WordStatus status, AppPalette palette) {
    switch (status) {
      case WordStatus.fresh:
        return palette.info;
      case WordStatus.learning:
        return AppColors.brand;
      case WordStatus.reviewing:
        return AppColors.accent;
      case WordStatus.mastered:
        return palette.success;
      case WordStatus.leech:
        return palette.danger;
    }
  }
}

/// ردیف نمایش تلفظ (آوانگاری + دکمه‌ی پخش).
class PronunciationRow extends StatelessWidget {
  const PronunciationRow({
    super.key,
    required this.ipa,
    required this.onSpeak,
    this.speaking = false,
    this.label,
  });

  final String? ipa;
  final VoidCallback onSpeak;
  final bool speaking;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Row(
      children: <Widget>[
        ScaleTap(
          onTap: onSpeak,
          child: PulsingHalo(
            active: speaking,
            size: 48,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: AppColors.brandGradient,
                shape: BoxShape.circle,
                boxShadow: AppShadows.brandGlow(),
              ),
              child: const Icon(
                Icons.volume_up_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (label != null)
                Text(
                  label!,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: palette.textTertiary,
                      ),
                ),
              Text(
                ipa == null || ipa!.isEmpty ? 'تلفظ در دسترس نیست' : ipa!,
                style: AppTypography.ipa.copyWith(
                  color: ipa == null ? palette.textTertiary : AppColors.brand,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// کارت سطح تسلط روی واژه (برای صفحه‌ی جزئیات).
class WordMasteryCard extends StatelessWidget {
  const WordMasteryCard({super.key, required this.state});

  final ReviewState state;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final rows = <(String, String)>[
      ('درصد تسلط', '${FaFormat.digits(state.masteryPercent)}٪'),
      ('تعداد مرور', FaFormat.digits(state.totalReviews)),
      ('دقت پاسخ', state.totalReviews == 0 ? '—' : FaFormat.percent(state.accuracy * 100)),
      ('خطاها', FaFormat.digits(state.lapses)),
      (
        'مرور بعدی',
        state.dueAt == null
            ? '—'
            : FaFormat.dueLabel(state.timeUntilDue(DateTime.now())),
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        for (final row in rows)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    row.$1,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: palette.textSecondary,
                        ),
                  ),
                ),
                Text(
                  row.$2,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: palette.textPrimary,
                      ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
