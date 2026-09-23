import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_dimens.dart';
import '../core/theme/app_palette.dart';

/// اسکلت صفحه‌های اپلیکیشن.
///
/// یک سرصفحه‌ی ساده و تمیز (بدون تکیه بر تم‌های Material که بین نسخه‌ها
/// تغییر می‌کنند) + بدنه‌ی اسکرول‌شو + نوار پایین اختیاری.
class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.body,
    this.title,
    this.subtitle,
    this.actions = const <Widget>[],
    this.leading,
    this.showBack = false,
    this.padding = const EdgeInsets.symmetric(horizontal: AppSpacing.md),
    this.bottomBar,
    this.floatingAction,
    this.onRefresh,
    this.centerTitle = false,
    this.backgroundColor,
    this.resizeToAvoidBottomInset = true,
  });

  final Widget body;
  final String? title;
  final String? subtitle;
  final List<Widget> actions;
  final Widget? leading;
  final bool showBack;
  final EdgeInsetsGeometry padding;
  final Widget? bottomBar;
  final Widget? floatingAction;
  final Future<void> Function()? onRefresh;
  final bool centerTitle;
  final Color? backgroundColor;
  final bool resizeToAvoidBottomInset;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    Widget content = Padding(padding: padding, child: body);
    if (onRefresh != null) {
      content = RefreshIndicator(
        onRefresh: onRefresh!,
        color: AppColors.brand,
        child: content,
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor ?? palette.background,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      appBar: title == null && !showBack && actions.isEmpty
          ? null
          : AppBar(
              backgroundColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              scrolledUnderElevation: 0,
              centerTitle: centerTitle,
              automaticallyImplyLeading: false,
              leading: showBack
                  ? Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.xs, left: 2),
                      child: IconButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: const Icon(Icons.arrow_forward_rounded),
                        color: palette.textPrimary,
                        tooltip: 'بازگشت',
                      ),
                    )
                  : (leading == null
                      ? null
                      : Padding(
                          padding: const EdgeInsets.only(right: AppSpacing.xs),
                          child: leading,
                        )),
              title: title == null
                  ? null
                  : Column(
                      crossAxisAlignment: centerTitle
                          ? CrossAxisAlignment.center
                          : CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          title!,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
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
              actions: actions,
            ),
      body: SafeArea(
        top: title == null && !showBack,
        child: content,
      ),
      bottomNavigationBar: bottomBar,
      floatingActionButton: floatingAction,
    );
  }
}

/// هدر گرادیانی برای صفحه‌های مهم (خانه، جشن‌ها).
class GradientHeader extends StatelessWidget {
  const GradientHeader({
    super.key,
    required this.child,
    this.gradient = AppColors.brandGradient,
    this.height,
    this.padding = const EdgeInsets.fromLTRB(
      AppSpacing.md,
      AppSpacing.lg,
      AppSpacing.md,
      AppSpacing.xxl,
    ),
  });

  final Widget child;
  final Gradient gradient;
  final double? height;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(AppRadius.xl),
        ),
      ),
      child: child,
    );
  }
}

/// نمایش پیام کوتاه (توست).
void showToast(
  BuildContext context,
  String message, {
  IconData? icon,
  Color? color,
  Duration duration = const Duration(seconds: 2),
}) {
  final palette = AppPalette.of(context);
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  messenger
    ..clearSnackBars()
    ..showSnackBar(
      SnackBar(
        content: Row(
          children: <Widget>[
            if (icon != null) ...<Widget>[
              Icon(icon, color: color ?? AppColors.brand, size: 20),
              const SizedBox(width: AppSpacing.xs),
            ],
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: palette.textPrimary,
                    ),
              ),
            ),
          ],
        ),
        backgroundColor: palette.surface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          side: BorderSide(color: palette.border),
        ),
        margin: const EdgeInsets.all(AppSpacing.md),
        duration: duration,
      ),
    );
}

/// نمایش برگه‌ی پایین با ظاهر یکدست.
Future<T?> showAppSheet<T>({
  required BuildContext context,
  required Widget child,
  bool isScrollControlled = true,
  bool dismissible = true,
}) {
  final palette = AppPalette.of(context);
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    isDismissible: dismissible,
    enableDrag: dismissible,
    backgroundColor: palette.surface,
    shape: const RoundedRectangleBorder(borderRadius: AppRadius.sheet),
    builder: (context) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: child,
    ),
  );
}

/// گفت‌وگوی تأیید با ظاهر یکدست.
Future<bool> showConfirmDialog({
  required BuildContext context,
  required String title,
  String? message,
  String confirmLabel = 'تأیید',
  String cancelLabel = 'انصراف',
  bool destructive = false,
}) async {
  final palette = AppPalette.of(context);
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: palette.surface,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.card),
      title: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: palette.textPrimary,
            ),
      ),
      content: message == null
          ? null
          : Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: palette.textSecondary,
                  ),
            ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(
            cancelLabel,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: palette.textSecondary,
                ),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(
            confirmLabel,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: destructive ? palette.danger : AppColors.brand,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// کشیدن دسته‌ی کوچک بالای برگه‌ها.
class SheetHandle extends StatelessWidget {
  const SheetHandle({super.key, this.margin = const EdgeInsets.only(top: AppSpacing.sm)});

  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Container(
      margin: margin,
      width: 44,
      height: 4,
      decoration: BoxDecoration(
        color: palette.border,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
    );
  }
}
