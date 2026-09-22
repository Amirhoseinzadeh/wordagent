import 'package:flutter/material.dart';

import '../core/di/app_container.dart';
import '../core/routing/app_router.dart';
import '../core/state/value_store.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_dimens.dart';
import '../core/theme/app_palette.dart';
import '../domain/entities/subscription.dart';
import '../l10n/strings.dart';
import 'app_card.dart';

/// جایگاه تبلیغ غیرمزاحم — تنها در نسخه‌ی رایگان دیده می‌شود.
///
/// این ویجت یک «نقطه‌ی اتصال» تمیز برای شبکه‌های تبلیغاتی است:
/// برای فعال‌سازی تبلیغ واقعی (AdMob، تپسل، یکتانت و…)، ویجت تبلیغ را
/// به‌جای کادر نمونه بگذارید. منطق نمایش/پنهان‌شدن بر اساس اشتراک و
/// اندازه‌ی استاندارد بنر (۳۲۰×۵۰) از همین‌جا مدیریت می‌شود و کاربران
/// ویژه هیچ‌وقت تبلیغ نمی‌بینند.
class AdSlot extends StatelessWidget {
  const AdSlot({
    super.key,
    this.placement = 'default',
    this.height = 64,
  });

  /// نام جایگاه (برای گزارش‌گیری و A/B تست در آینده).
  final String placement;

  final double height;

  @override
  Widget build(BuildContext context) {
    final container = AppScope.maybeOf(context);
    if (container == null) return const SizedBox.shrink();
    return StoreBuilder<SubscriptionState>(
      store: container.stores.subscriptionStore,
      builder: (context, subscription) {
        if (subscription.hasPremiumAccess(DateTime.now())) {
          return const SizedBox.shrink();
        }
        final palette = AppPalette.of(context);
        return AppCard(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          child: SizedBox(
            height: height,
            child: Row(
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: palette.surfaceAlt,
                    borderRadius: BorderRadius.circular(AppRadius.xs),
                  ),
                  child: Text(
                    'تبلیغ',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: palette.textTertiary,
                          fontSize: 10,
                        ),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'بدون تبلیغ درس بخوان',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: palette.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      Text(
                        'اشتراک ویژه، تبلیغ‌ها و محدودیت روزانه را برمی‌دارد',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: palette.textTertiary,
                              fontSize: 10,
                            ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pushNamed(AppRoutes.paywall),
                  child: Text(
                    S.upgradeCta,
                    style: const TextStyle(
                      color: AppColors.brand,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
