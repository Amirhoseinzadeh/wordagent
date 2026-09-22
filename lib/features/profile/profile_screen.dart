import 'package:flutter/material.dart';

import '../../core/di/app_container.dart';
import '../../core/routing/app_router.dart';
import '../../core/state/value_store.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_palette.dart';
import '../../core/utils/fa_format.dart';
import '../../core/utils/jalali_date.dart';
import '../../domain/engines/xp_engine.dart';
import '../../domain/entities/progress.dart';
import '../../domain/entities/subscription.dart';
import '../../domain/entities/user_profile.dart';
import '../../l10n/labels.dart';
import '../../l10n/strings.dart';
import '../../widgets/animations.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/badges.dart';
import '../../widgets/states.dart';
import '../achievements/achievements_screen.dart';
import '../chat/chat_screen.dart';
import '../paywall/paywall_screen.dart';
import '../settings/settings_screen.dart';

/// پروفایل کاربر: هویت، اشتراک، دستاوردها و میان‌برها.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final container = AppScope.of(context);
    final controller = container.controller;

    return Watch(
      listenables: <Listenable>[
        container.stores.profileStore,
        container.stores.xpStore,
        container.stores.streakStore,
        container.stores.achievementsStore,
        container.stores.subscriptionStore,
        container.stores.statesStore,
      ],
      builder: (context) {
        final profile = controller.profile;
        final level = controller.appLevel;
        final xp = container.stores.xpStore.value;
        final streak = container.stores.streakStore.value;
        final subscription = container.stores.subscriptionStore.value;
        final achievements = container.stores.achievementsStore.value;
        final unlocked =
            achievements.values.where((item) => item.isUnlocked).length;

        return AppScaffold(
          title: S.profileTitle,
          padding: EdgeInsets.zero,
          actions: <Widget>[
            CircleIconButton(
              icon: Icons.settings_outlined,
              tooltip: S.settingsTitle,
              onPressed: () => _openSettings(context),
            ),
          ],
          body: ListView(
            padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
            children: <Widget>[
              _ProfileHeader(
                profile: profile,
                level: level,
                onEditName: () => _editName(context, profile),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Column(
                  children: <Widget>[
                    _QuickStats(
                      xp: xp,
                      streakCurrent: streak.current,
                      streakBest: streak.best,
                      unlocked: unlocked,
                      totalAchievements: achievements.length,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _SubscriptionCard(state: subscription),
                    const SizedBox(height: AppSpacing.md),
                    AppCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.xs,
                      ),
                      child: Column(
                        children: <Widget>[
                          _MenuRow(
                            icon: Icons.emoji_events_rounded,
                            color: AppColors.gold,
                            title: S.achievementsTitle,
                            subtitle: '${FaFormat.digits(unlocked)} نشان باز شده',
                            onTap: () => Navigator.of(context).push(
                              AppRouter.build<void>(
                                settings: const RouteSettings(
                                  name: AppRoutes.achievements,
                                ),
                                builder: (_) => const AchievementsScreen(),
                              ),
                            ),
                          ),
                          _MenuRow(
                            icon: Icons.insights_rounded,
                            color: AppColors.info,
                            title: S.progressTitle,
                            subtitle: 'نمودارها و تحلیل پیشرفت',
                            onTap: () => Navigator.of(context)
                                .popUntil((route) => route.isFirst),
                          ),
                          _MenuRow(
                            icon: Icons.chat_bubble_outline_rounded,
                            color: AppColors.accent,
                            title: S.chatTitle,
                            subtitle: 'پرسش درباره‌ی هر واژه یا گرامر',
                            onTap: () => Navigator.of(context).push(
                              AppRouter.build<void>(
                                settings:
                                    const RouteSettings(name: AppRoutes.chat),
                                builder: (_) => const ChatScreen(),
                              ),
                            ),
                          ),
                          _MenuRow(
                            icon: Icons.category_rounded,
                            color: AppColors.pink,
                            title: S.wordPacks,
                            subtitle: 'دسته‌بندی موضوعی واژه‌ها',
                            onTap: () => Navigator.of(context)
                                .popUntil((route) => route.isFirst),
                          ),
                          _MenuRow(
                            icon: Icons.settings_outlined,
                            color: AppColors.brand,
                            title: S.settingsTitle,
                            subtitle: 'ظاهر، اهداف، صدا و داده‌ها',
                            onTap: () => _openSettings(context),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _AboutCard(contentVersion: container.contentVersion),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _openSettings(BuildContext context) {
    Navigator.of(context).push(
      AppRouter.build<void>(
        settings: const RouteSettings(name: AppRoutes.settings),
        builder: (_) => const SettingsScreen(),
      ),
    );
  }

  Future<void> _editName(BuildContext context, UserProfile profile) async {
    final controller = TextEditingController(text: profile.name);
    final container = AppScope.of(context);
    final result = await showAppSheet<String>(
      context: context,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          TextField(
            controller: controller,
            autofocus: true,
            textAlign: TextAlign.center,
            maxLength: 24,
            decoration: const InputDecoration(
              hintText: S.onboardingNameHint,
              counterText: '',
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label: S.save,
            onPressed: () => Navigator.of(context).pop(controller.text),
          ),
          const SizedBox(height: AppSpacing.xs),
          AppButton(
            label: S.cancel,
            variant: AppButtonVariant.ghost,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      ),
    );
    controller.dispose();
    if (result == null || result.trim().isEmpty) return;
    await container.controller.saveProfile(profile.copyWith(name: result.trim()));
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.profile,
    required this.level,
    required this.onEditName,
  });

  final UserProfile profile;
  final AppLevel level;
  final VoidCallback onEditName;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.lg,
      ),
      decoration: const BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(AppRadius.xl)),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: Colors.white.fade(0.22),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.fade(0.55), width: 2),
            ),
            alignment: Alignment.center,
            child: Text(
              profile.initial,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Flexible(
                      child: Text(
                        profile.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    ScaleTap(
                      onTap: onEditName,
                      child: const Icon(
                        Icons.edit_rounded,
                        size: 15,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '${level.emoji} ${level.title} • ${profile.level.code} ${profile.level.faTitle}',
                  style: TextStyle(color: Colors.white.fade(0.92), fontSize: 12),
                ),
                const SizedBox(height: 3),
                Text(
                  '${profile.goal.emoji} ${profile.goal.faTitle} • '
                  'از ${JalaliDate.fromDateTime(profile.createdAt).longLabel}',
                  style: TextStyle(color: Colors.white.fade(0.8), fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickStats extends StatelessWidget {
  const _QuickStats({
    required this.xp,
    required this.streakCurrent,
    required this.streakBest,
    required this.unlocked,
    required this.totalAchievements,
  });

  final XpState xp;
  final int streakCurrent;
  final int streakBest;
  final int unlocked;
  final int totalAchievements;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: <Widget>[
          Expanded(
            child: StatTile(
              value: FaFormat.compactNumber(xp.totalXp),
              label: 'امتیاز کل',
              icon: Icons.bolt_rounded,
              color: AppColors.gold,
              compact: true,
            ),
          ),
          Expanded(
            child: StatTile(
              value: FaFormat.digits(streakCurrent),
              label: 'روز پیاپی',
              icon: Icons.local_fire_department_rounded,
              color: AppColors.brand,
              compact: true,
            ),
          ),
          Expanded(
            child: StatTile(
              value: FaFormat.digits(streakBest),
              label: 'رکورد زنجیره',
              icon: Icons.emoji_events_outlined,
              color: AppPalette.of(context).info,
              compact: true,
            ),
          ),
          Expanded(
            child: StatTile(
              value: '${FaFormat.digits(unlocked)}/${FaFormat.digits(totalAchievements)}',
              label: S.achievementsUnlocked,
              icon: Icons.workspace_premium_rounded,
              color: AppColors.accent,
              compact: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _SubscriptionCard extends StatelessWidget {
  const _SubscriptionCard({required this.state});

  final SubscriptionState state;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final now = DateTime.now();
    final premium = state.hasPremiumAccess(now);
    final days = state.daysRemaining(now);

    if (premium) {
      return AppCard(
        child: Row(
          children: <Widget>[
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                gradient: AppColors.goldGradient,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: const Icon(
                Icons.workspace_premium_rounded,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'اشتراک ${state.tier.faLabel}',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: palette.textPrimary,
                        ),
                  ),
                  Text(
                    days > 0
                        ? '${FaFormat.digits(days)} روز باقی مانده • ${state.plan.priceLabel}'
                        : 'اشتراک دائمی فعال است',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: palette.textTertiary,
                        ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () => showToast(
                context,
                'مدیریت اشتراک در نسخه‌ی متصل به فروشگاه فعال می‌شود.',
              ),
              child: const Text(S.subscriptionManage),
            ),
          ],
        ),
      );
    }

    return PremiumBanner(
      title: S.paywallHeadline,
      subtitle: 'واژه‌های نامحدود، تمرین آزاد و بدون تبلیغ',
      onTap: () => Navigator.of(context).push(
        AppRouter.build<void>(
          settings: const RouteSettings(name: AppRoutes.paywall),
          builder: (_) => const PaywallScreen(),
        ),
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Row(
          children: <Widget>[
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.fade(0.14),
                borderRadius: BorderRadius.circular(AppRadius.xs),
              ),
              child: Icon(icon, color: color, size: 19),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: palette.textPrimary,
                        ),
                  ),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: palette.textTertiary,
                        ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_left_rounded, color: palette.textTertiary),
          ],
        ),
      ),
    );
  }
}

class _AboutCard extends StatelessWidget {
  const _AboutCard({required this.contentVersion});

  final String? contentVersion;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SectionHeader(title: S.aboutSection, icon: Icons.info_outline_rounded),
          const SizedBox(height: AppSpacing.xs),
          _InfoRow(label: S.versionLabel, value: '۱٫۰٫۰'),
          _InfoRow(label: 'نسخه‌ی محتوا', value: contentVersion ?? '۱٫۰٫۰'),
          _InfoRow(label: 'سازنده', value: 'تیم واژه‌یار'),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'واژه‌یار یک اپلیکیشن آموزشی مستقل است؛ همه‌ی داده‌های پیشرفت '
            'روی همین دستگاه ذخیره می‌شود و بدون حساب کاربری کار می‌کند.',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: palette.textTertiary,
                  height: 1.8,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: <Widget>[
              TextButton(
                onPressed: () => showToast(context, 'به‌زودی: صفحه‌ی قوانین'),
                child: const Text(S.termsLabel),
              ),
              TextButton(
                onPressed: () => showToast(context, 'به‌زودی: سیاست حفظ حریم خصوصی'),
                child: const Text(S.privacyLabel),
              ),
              TextButton(
                onPressed: () => showToast(context, 'پشتیبانی: support@wordagent.app'),
                child: const Text(S.contactUs),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

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
                ),
          ),
        ],
      ),
    );
  }
}
