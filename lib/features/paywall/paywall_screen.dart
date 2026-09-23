import 'package:flutter/material.dart';

import '../../core/di/app_container.dart';
import '../../core/state/value_store.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_palette.dart';
import '../../core/utils/fa_format.dart';
import '../../domain/entities/subscription.dart';
import '../../l10n/labels.dart';
import '../../l10n/strings.dart';
import '../../widgets/animations.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/badges.dart';
import '../../widgets/celebration.dart';
import '../../widgets/states.dart';

/// صفحه‌ی اشتراک ویژه (freemium).
///
/// مدل درآمد: نسخه‌ی رایگان با محدودیت روزانه و تبلیغ غیرمزاحم؛
/// نسخه‌ی ویژه با واژه‌های نامحدود، محتوای C1/C2، تمرین آزاد، دستیار
/// هوشمند بدون محدودیت و بدون تبلیغ.
class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  SubscriptionPlan _selected = SubscriptionPlan.yearly;
  bool _busy = false;
  bool _celebrate = false;

  static const List<(IconData, String, String)> _benefits = <(IconData, String, String)>[
    (
      Icons.all_inclusive_rounded,
      'مرور نامحدود',
      'محدودیت روزانه‌ی نسخه‌ی رایگان برداشته می‌شود',
    ),
    (
      Icons.school_rounded,
      'همه‌ی واژه‌ها',
      'واژه‌های پیشرفته (C1 و C2) و بسته‌های ویژه باز می‌شوند',
    ),
    (
      Icons.block_rounded,
      'بدون تبلیغ',
      'تجربه‌ی مطالعه‌ی تمیز و بدون مزاحمت',
    ),
    (
      Icons.psychology_alt_rounded,
      'دستیار هوشمند بی‌پایان',
      'پرسش و مثال‌سازی نامحدود درباره‌ی هر واژه',
    ),
    (
      Icons.cloud_sync_rounded,
      'به‌روزرسانی محتوا',
      'واژه‌ها و بسته‌های تازه، بدون نیاز به نصب دوباره',
    ),
    (
      Icons.insights_rounded,
      'تحلیل پیشرفته',
      'نمودارهای دقیق‌تر و تمرین اختصاصی نقاط ضعف',
    ),
  ];

  Future<void> _startTrial() async {
    if (_busy) return;
    setState(() => _busy = true);
    final container = AppScope.of(context);
    final result = await container.controller.startTrial();
    if (!mounted) return;
    setState(() {
      _busy = false;
      _celebrate = result.success;
    });
    showToast(
      context,
      result.success
          ? S.paywallActivated
          : (result.message ?? S.somethingWentWrong),
      icon: result.success ? Icons.verified_rounded : Icons.info_outline_rounded,
    );
  }

  Future<void> _purchase() async {
    if (_busy) return;
    setState(() => _busy = true);
    final container = AppScope.of(context);
    final result = await container.controller.purchase(_selected);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _celebrate = result.success;
    });
    showToast(
      context,
      result.success ? S.paywallActivated : (result.message ?? S.somethingWentWrong),
      icon: result.success ? Icons.verified_rounded : Icons.info_outline_rounded,
    );
  }

  Future<void> _restore() async {
    if (_busy) return;
    setState(() => _busy = true);
    final container = AppScope.of(context);
    final result = await container.controller.restorePurchases();
    if (!mounted) return;
    setState(() {
      _busy = false;
      _celebrate = result.success;
    });
    showToast(
      context,
      result.success ? S.paywallRestored : S.paywallNothingToRestore,
      icon: result.success ? Icons.restore_rounded : Icons.search_off_rounded,
    );
  }

  @override
  Widget build(BuildContext context) {
    final container = AppScope.of(context);
    final palette = AppPalette.of(context);

    return StoreBuilder<SubscriptionState>(
      store: container.stores.subscriptionStore,
      builder: (context, state) {
        final now = DateTime.now();
        final premium = state.hasPremiumAccess(now);
        final days = state.daysRemaining(now);

        return ConfettiOverlay(
          active: _celebrate,
          onFinished: () => setState(() => _celebrate = false),
          child: AppScaffold(
            title: S.paywallTitle,
            showBack: true,
            padding: EdgeInsets.zero,
            body: ListView(
              padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
              children: <Widget>[
                Container(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.lg,
                  ),
                  decoration: const BoxDecoration(
                    gradient: AppColors.goldGradient,
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(AppRadius.xl),
                    ),
                  ),
                  child: Column(
                    children: <Widget>[
                      const Text('⭐️', style: TextStyle(fontSize: 44)),
                      const SizedBox(height: AppSpacing.xs),
                      const Text(
                        S.paywallHeadline,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF3A2400),
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        premium
                            ? 'اشتراک فعال است — ${state.tier.faLabel}'
                            : 'اول ۷ روز رایگان امتحان کن، بعد تصمیم بگیر.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF6B4A00),
                          fontSize: 12,
                          height: 1.8,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    children: <Widget>[
                      if (premium) ...<Widget>[
                        AppCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              SectionHeader(
                                title: 'وضعیت اشتراک',
                                icon: Icons.workspace_premium_rounded,
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              _StatusRow(
                                label: 'نوع اشتراک',
                                value: state.tier.faLabel,
                              ),
                              _StatusRow(
                                label: 'پلن',
                                value: state.plan.priceLabel,
                              ),
                              _StatusRow(
                                label: 'روزهای باقی‌مانده',
                                value: days > 0 ? FaFormat.digits(days) : 'دائمی',
                              ),
                              _StatusRow(
                                label: 'تمدید خودکار',
                                value: state.autoRenew ? 'فعال' : 'خاموش',
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              if (state.autoRenew)
                                AppButton(
                                  label: 'خاموش‌کردن تمدید خودکار',
                                  variant: AppButtonVariant.ghost,
                                  height: 46,
                                  onPressed: () async {
                                    await container.controller.cancelAutoRenew();
                                    if (!context.mounted) return;
                                    showToast(context, 'تمدید خودکار خاموش شد.');
                                  },
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ],
                      AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            SectionHeader(
                              title: 'با اشتراک ویژه چه چیزی به دست می‌آوری؟',
                              icon: Icons.auto_awesome_rounded,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            for (final benefit in _benefits)
                              Padding(
                                padding:
                                    const EdgeInsets.only(bottom: AppSpacing.sm),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Container(
                                      width: 34,
                                      height: 34,
                                      decoration: BoxDecoration(
                                        color: AppColors.goldSoft,
                                        borderRadius:
                                            BorderRadius.circular(AppRadius.xs),
                                      ),
                                      child: Icon(
                                        benefit.$1,
                                        size: 17,
                                        color: AppColors.goldDeep,
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.sm),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: <Widget>[
                                          Text(
                                            benefit.$2,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleSmall
                                                ?.copyWith(
                                                  color: palette.textPrimary,
                                                ),
                                          ),
                                          Text(
                                            benefit.$3,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  color: palette.textSecondary,
                                                  height: 1.7,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (!premium) ...<Widget>[
                        const SizedBox(height: AppSpacing.md),
                        for (final plan in <SubscriptionPlan>[
                          SubscriptionPlan.monthly,
                          SubscriptionPlan.yearly,
                          SubscriptionPlan.lifetime,
                        ])
                          Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                            child: _PaywallPlanCard(
                              plan: plan,
                              selected: _selected == plan,
                              onTap: () => setState(() => _selected = plan),
                            ),
                          ),
                        const SizedBox(height: AppSpacing.sm),
                        if (state.trialUsed)
                          AppButton(
                            label: '${S.paywallCta} • ${_selected.priceLabel}',
                            icon: Icons.lock_open_rounded,
                            variant: AppButtonVariant.gold,
                            loading: _busy,
                            onPressed: _purchase,
                          )
                        else ...<Widget>[
                          AppButton(
                            label: S.paywallTrial,
                            icon: Icons.play_circle_fill_rounded,
                            variant: AppButtonVariant.gold,
                            loading: _busy,
                            onPressed: _startTrial,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          AppButton(
                            label: '${S.paywallCta} • ${_selected.priceLabel}',
                            icon: Icons.shopping_bag_rounded,
                            variant: AppButtonVariant.secondary,
                            loading: _busy,
                            onPressed: _purchase,
                          ),
                        ],
                        const SizedBox(height: AppSpacing.xs),
                        TextButton.icon(
                          onPressed: _busy ? null : _restore,
                          icon: const Icon(Icons.restore_rounded, size: 17),
                          label: const Text(S.paywallRestore),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          S.paywallTerms,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: palette.textTertiary,
                                height: 1.8,
                              ),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.md),
                      InfoBanner(
                        text: 'این نسخه برای نمایش تجربه‌ی خرید آماده است؛ '
                            'برای انتشار، درگاه پرداخت کافه‌بازار/مایکت یا '
                            'App Store فقط در یک کلاس (SubscriptionRepository) '
                            'جای‌گذاری می‌شود.',
                        icon: Icons.info_outline_rounded,
                        color: palette.info,
                      ),
                    ],
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

class _PaywallPlanCard extends StatelessWidget {
  const _PaywallPlanCard({
    required this.plan,
    required this.selected,
    required this.onTap,
  });

  final SubscriptionPlan plan;
  final bool selected;
  final VoidCallback onTap;

  String get _title {
    switch (plan) {
      case SubscriptionPlan.monthly:
        return S.paywallMonthly;
      case SubscriptionPlan.yearly:
        return S.paywallYearly;
      case SubscriptionPlan.lifetime:
        return S.paywallLifetime;
      case SubscriptionPlan.none:
        return '';
    }
  }

  String get _saveLabel {
    switch (plan) {
      case SubscriptionPlan.yearly:
        return S.paywallBestValue;
      case SubscriptionPlan.monthly:
        return S.paywallMonthlySave;
      case SubscriptionPlan.lifetime:
        return 'یک‌بار برای همیشه';
      case SubscriptionPlan.none:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return ScaleTap(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppDurations.fast,
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: selected ? AppColors.goldSoft : palette.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: selected ? AppColors.gold : palette.border,
            width: selected ? 1.8 : 1,
          ),
        ),
        child: Row(
          children: <Widget>[
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              color: selected ? AppColors.goldDeep : palette.textTertiary,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Text(
                        _title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: palette.textPrimary,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(width: 6),
                      if (plan == SubscriptionPlan.yearly)
                        const PremiumBadge(label: 'پیشنهاد', dense: true),
                    ],
                  ),
                  Text(
                    '${plan.priceLabel} • $_saveLabel',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: palette.textSecondary,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: <Widget>[
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: palette.textTertiary,
                ),
          ),
          const Spacer(),
          Text(
            value,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: palette.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}
