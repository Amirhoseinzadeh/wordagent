import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_dimens.dart';
import '../core/theme/app_palette.dart';

/// دکمه‌ی اصلی اپلیکیشن با حالت‌های بصری متنوع.
enum AppButtonVariant { primary, secondary, ghost, gold, danger }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.variant = AppButtonVariant.primary,
    this.loading = false,
    this.expanded = true,
    this.height = AppSizes.buttonHeight,
    this.compact = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final AppButtonVariant variant;
  final bool loading;
  final bool expanded;
  final double height;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final isEnabled = onPressed != null && !loading;

    late final Color foreground;
    Gradient? gradient;
    Color background = Colors.transparent;
    Color? borderColor;

    switch (variant) {
      case AppButtonVariant.primary:
        gradient = AppColors.brandGradient;
        foreground = Colors.white;
      case AppButtonVariant.secondary:
        background = AppColors.brandSoft;
        foreground = palette.isDark ? AppColors.brandLight : AppColors.brandDark;
        borderColor = AppColors.brand.fade(0.35);
      case AppButtonVariant.gold:
        gradient = AppColors.goldGradient;
        foreground = const Color(0xFF3A2400);
      case AppButtonVariant.danger:
        background = AppColors.dangerSoft;
        foreground = palette.danger;
        borderColor = palette.danger.fade(0.35);
      case AppButtonVariant.ghost:
        background = Colors.transparent;
        foreground = palette.textSecondary;
    }

    final content = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (loading)
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              color: foreground,
            ),
          )
        else if (icon != null)
          Icon(icon, size: AppSizes.icon, color: foreground),
        if (loading || icon != null) const SizedBox(width: AppSpacing.xs),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: foreground,
                  fontSize: compact ? 13 : 15,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
      ],
    );

    final button = Opacity(
      opacity: isEnabled ? 1 : 0.55,
      child: Container(
        height: height,
        padding: EdgeInsets.symmetric(horizontal: compact ? AppSpacing.sm : AppSpacing.lg),
        decoration: BoxDecoration(
          color: gradient == null ? background : null,
          gradient: isEnabled || variant == AppButtonVariant.ghost ? gradient : null,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: borderColor == null ? null : Border.all(color: borderColor),
          boxShadow: variant == AppButtonVariant.primary && isEnabled
              ? AppShadows.brandGlow()
              : null,
        ),
        child: Center(child: content),
      ),
    );

    final tappable = Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: isEnabled ? onPressed : null,
        child: button,
      ),
    );

    return expanded ? SizedBox(width: double.infinity, child: tappable) : tappable;
  }
}

/// دکمه‌ی آیکونی گرد (برای نوار بالا، پخش صدا و…).
class CircleIconButton extends StatelessWidget {
  const CircleIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.size = 42,
    this.background,
    this.foreground,
    this.tooltip,
    this.badgeCount,
    this.borderColor,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final double size;
  final Color? background;
  final Color? foreground;
  final String? tooltip;
  final int? badgeCount;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final content = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background ?? palette.surface,
        shape: BoxShape.circle,
        border: Border.all(color: borderColor ?? palette.border),
      ),
      child: Icon(
        icon,
        size: size * 0.46,
        color: foreground ?? palette.textPrimary,
      ),
    );

    final button = Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: content,
      ),
    );

    final withBadge = badgeCount == null || badgeCount == 0
        ? button
        : Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              button,
              Positioned(
                top: -2,
                right: -2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: AppColors.danger,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    '$badgeCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          );

    if (tooltip == null) return withBadge;
    return Tooltip(message: tooltip!, child: withBadge);
  }
}

/// چیپ قابل انتخاب (برای فیلترها).
class ChoiceChipTile extends StatelessWidget {
  const ChoiceChipTile({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
    this.icon,
    this.color,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;
  final IconData? icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final accent = color ?? AppColors.brand;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onSelected,
        child: AnimatedContainer(
          duration: AppDurations.fast,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: selected ? accent.fade(0.16) : palette.surface,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(
              color: selected ? accent : palette.border,
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (icon != null) ...<Widget>[
                Icon(
                  icon,
                  size: AppSizes.iconSm,
                  color: selected ? accent : palette.textSecondary,
                ),
                const SizedBox(width: AppSpacing.xxs),
              ],
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: selected ? accent : palette.textSecondary,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// برچسب کوچک رنگی (سطح، نقش دستوری، موضوع…).
class TagChip extends StatelessWidget {
  const TagChip({
    super.key,
    required this.label,
    this.color,
    this.icon,
    this.dense = false,
    this.onTap,
  });

  final String label;
  final Color? color;
  final IconData? icon;
  final bool dense;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final accent = color ?? palette.textSecondary;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: dense ? AppSpacing.xs : AppSpacing.sm,
            vertical: dense ? 2 : 4,
          ),
          decoration: BoxDecoration(
            color: palette.softFor(accent),
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (icon != null) ...<Widget>[
                Icon(icon, size: 12, color: accent),
                const SizedBox(width: 3),
              ],
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: accent,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
