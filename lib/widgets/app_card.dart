import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_dimens.dart';
import '../core/theme/app_palette.dart';

/// کارت پایه‌ی اپلیکیشن با پشتیبانی از گرادیان، حاشیه و قابلیت ضربه‌زدن.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.margin,
    this.gradient,
    this.color,
    this.borderColor,
    this.radius = AppRadius.md,
    this.onTap,
    this.elevated = false,
    this.borderWidth = 1,
    this.clip = true,
    this.width,
    this.height,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final Gradient? gradient;
  final Color? color;
  final Color? borderColor;
  final double radius;
  final VoidCallback? onTap;
  final bool elevated;
  final double borderWidth;
  final bool clip;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final borderRadius = BorderRadius.circular(radius);
    final background = color ?? palette.surface;

    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: gradient == null ? background : null,
        gradient: gradient,
        borderRadius: borderRadius,
        border: Border.all(
          color: borderColor ?? (gradient == null ? palette.border : Colors.transparent),
          width: borderWidth,
        ),
        boxShadow: elevated ? AppShadows.soft(palette.isDark) : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: borderRadius,
        clipBehavior: clip ? Clip.antiAlias : Clip.none,
        child: onTap == null
            ? Padding(padding: padding, child: child)
            : InkWell(
                onTap: onTap,
                borderRadius: borderRadius,
                child: Padding(padding: padding, child: child),
              ),
      ),
    );
  }
}

/// کارت شیشه‌ای/رنگی برای بخش‌های برجسته (مثل کارت هدف روزانه یا زنجیره).
class HighlightCard extends StatelessWidget {
  const HighlightCard({
    super.key,
    required this.child,
    this.gradient = AppColors.brandGradient,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.radius = AppRadius.lg,
    this.onTap,
    this.margin,
  });

  final Widget child;
  final Gradient gradient;
  final EdgeInsetsGeometry padding;
  final double radius;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: AppShadows.brandGlow(),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(radius),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: <Widget>[
            // درخشش تزئینی گوشه‌ی کارت
            Positioned(
              left: -30,
              top: -40,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.fade(0.08),
                ),
              ),
            ),
            if (onTap == null)
              Padding(padding: padding, child: child)
            else
              InkWell(
                onTap: onTap,
                child: Padding(padding: padding, child: child),
              ),
          ],
        ),
      ),
    );
  }
}

/// ردیف آماری کوچک (مقدار + برچسب + آیکون).
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.value,
    required this.label,
    this.icon,
    this.color,
    this.compact = false,
  });

  final String value;
  final String label;
  final IconData? icon;
  final Color? color;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final accent = color ?? AppColors.brand;
    return AppCard(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: compact ? AppSpacing.sm : AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            children: <Widget>[
              if (icon != null) ...<Widget>[
                Icon(icon, size: AppSizes.iconSm, color: accent),
                const SizedBox(width: AppSpacing.xxs),
              ],
              Flexible(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: palette.textPrimary,
                        fontSize: compact ? 18 : 22,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 2,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: palette.textSecondary,
                ),
          ),
        ],
      ),
    );
  }
}
