import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_dimens.dart';
import '../core/theme/app_palette.dart';
import '../l10n/strings.dart';
import 'app_button.dart';
import 'app_card.dart';

/// سرتیتر بخش‌ها با دکمه‌ی «مشاهده همه».
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.icon,
    this.padding = const EdgeInsets.only(bottom: AppSpacing.sm),
  });

  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData? icon;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: AppColors.brandSoft,
                borderRadius: BorderRadius.circular(AppRadius.xs),
              ),
              child: Icon(icon, size: 17, color: AppColors.brand),
            ),
            const SizedBox(width: AppSpacing.xs),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: palette.textPrimary,
                      ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: palette.textTertiary,
                        ),
                  ),
              ],
            ),
          ),
          if (actionLabel != null && onAction != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.brand,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                minimumSize: const Size(0, 32),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                actionLabel!,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppColors.brand,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
        ],
      ),
    );
  }
}

/// حالت خالی با پیام دوستانه و دعوت به اقدام.
class EmptyStateView extends StatelessWidget {
  const EmptyStateView({
    super.key,
    required this.title,
    this.message,
    this.emoji = '🌱',
    this.icon,
    this.actionLabel,
    this.onAction,
    this.compact = false,
  });

  final String title;
  final String? message;
  final String emoji;
  final IconData? icon;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Center(
      child: Padding(
        padding: EdgeInsets.all(compact ? AppSpacing.md : AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: compact ? 66 : 86,
              height: compact ? 66 : 86,
              decoration: BoxDecoration(
                color: AppColors.brandSoft,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: icon != null
                  ? Icon(icon, size: compact ? 30 : 38, color: AppColors.brand)
                  : Text(emoji, style: TextStyle(fontSize: compact ? 28 : 36)),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: palette.textPrimary,
                  ),
            ),
            if (message != null) ...<Widget>[
              const SizedBox(height: AppSpacing.xs),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: palette.textSecondary,
                    ),
              ),
            ],
            if (actionLabel != null && onAction != null) ...<Widget>[
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                label: actionLabel!,
                onPressed: onAction,
                expanded: false,
                height: 46,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// نمایشگر بارگذاری کل صفحه.
class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.message = S.loading});

  final String message;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const SizedBox(
            width: 34,
            height: 34,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            message,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: palette.textSecondary,
                ),
          ),
        ],
      ),
    );
  }
}

/// نمایشگر خطا با امکان تلاش دوباره.
class ErrorView extends StatelessWidget {
  const ErrorView({
    super.key,
    this.message = S.somethingWentWrong,
    this.onRetry,
  });

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return EmptyStateView(
      title: 'اوه!',
      message: message,
      icon: Icons.cloud_off_rounded,
      actionLabel: onRetry == null ? null : S.retry,
      onAction: onRetry,
    );
  }
}

/// نوار اطلاع‌رسانی (هشدار، پیشنهاد، تبلیغ ملایم).
class InfoBanner extends StatelessWidget {
  const InfoBanner({
    super.key,
    required this.text,
    this.icon = Icons.lightbulb_outline_rounded,
    this.color,
    this.onTap,
    this.actionLabel,
    this.margin,
  });

  final String text;
  final IconData icon;
  final Color? color;
  final VoidCallback? onTap;
  final String? actionLabel;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final accent = color ?? AppColors.info;
    return AppCard(
      margin: margin,
      color: palette.softFor(accent),
      borderColor: accent.fade(0.28),
      padding: const EdgeInsets.all(AppSpacing.sm),
      onTap: onTap,
      child: Row(
        children: <Widget>[
          Icon(icon, size: 20, color: accent),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: palette.textPrimary,
                  ),
            ),
          ),
          if (actionLabel != null)
            Text(
              actionLabel!,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w800,
                  ),
            ),
        ],
      ),
    );
  }
}

/// بنر دعوت به نسخه‌ی ویژه (تبلیغ ملایم و بدون مزاحمت).
class PremiumBanner extends StatelessWidget {
  const PremiumBanner({
    super.key,
    required this.onTap,
    this.title = 'به واژه‌یار ویژه خوش آمدی',
    this.subtitle = 'لغت‌های نامحدود، تمرین بی‌پایان و بدون تبلیغ',
    this.margin,
  });

  final VoidCallback onTap;
  final String title;
  final String subtitle;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    return HighlightCard(
      margin: margin,
      gradient: AppColors.goldGradient,
      padding: const EdgeInsets.all(AppSpacing.md),
      onTap: onTap,
      child: Row(
        children: <Widget>[
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.fade(0.25),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.workspace_premium_rounded,
              color: Color(0xFF3A2400),
              size: 22,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: const Color(0xFF3A2400),
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: const Color(0xFF3A2400).fade(0.85),
                      ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.arrow_back_rounded,
            color: Color(0xFF3A2400),
            size: 20,
          ),
        ],
      ),
    );
  }
}
