import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/di/app_container.dart';
import '../../core/routing/app_router.dart';
import '../../core/state/value_store.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_palette.dart';
import '../../core/utils/fa_format.dart';
import '../../domain/entities/settings.dart';
import '../../l10n/labels.dart';
import '../../l10n/strings.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/states.dart';
import '../paywall/paywall_screen.dart';

/// تنظیمات: ظاهر، اهداف یادگیری، صدا، محتوا و داده‌ها.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _busy = false;
  bool _checkingUpdates = false;

  Future<void> _update(AppSettings next) async {
    final container = AppScope.of(context);
    await container.controller.updateSettings(next);
  }

  Future<void> _checkUpdates() async {
    if (_checkingUpdates) return;
    setState(() => _checkingUpdates = true);
    final container = AppScope.of(context);
    try {
      final updated = await container.controller.checkContentUpdates();
      if (!mounted) return;
      showToast(
        context,
        updated ? S.contentUpdated : 'محتوای تو به‌روز است.',
        icon: updated ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
      );
    } catch (_) {
      if (!mounted) return;
      showToast(context, S.noInternet, icon: Icons.wifi_off_rounded);
    }
    if (!mounted) return;
    setState(() => _checkingUpdates = false);
  }

  Future<void> _export() async {
    final container = AppScope.of(context);
    final data = await container.controller.exportData();
    await Clipboard.setData(ClipboardData(text: data));
    if (!mounted) return;
    showToast(
      context,
      'پیشرفت تو در قالب JSON کپی شد (${FaFormat.digits(data.length)} نویسه).',
      icon: Icons.copy_rounded,
    );
  }

  Future<void> _reset() async {
    final confirmed = await showConfirmDialog(
      context: context,
      title: S.resetProgress,
      message: S.resetProgressConfirm,
      confirmLabel: S.delete,
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    setState(() => _busy = true);
    final container = AppScope.of(context);
    await container.controller.resetProgress();
    if (!mounted) return;
    setState(() => _busy = false);
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.onboarding,
      (route) => false,
    );
  }

  Future<void> _pickReminder(AppSettings settings) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: settings.reminderHour,
        minute: settings.reminderMinute,
      ),
    );
    if (picked == null) return;
    await _update(
      settings.copyWith(
        remindersEnabled: true,
        reminderHour: picked.hour,
        reminderMinute: picked.minute,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final container = AppScope.of(context);
    final controller = container.controller;

    return StoreBuilder<AppSettings>(
      store: container.stores.settingsStore,
      builder: (context, settings) {
        return AppScaffold(
          title: S.settingsTitle,
          subtitle: S.appTagline,
          showBack: true,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          body: ListView(
            padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
            children: <Widget>[
              _SettingsSection(
                title: S.appearanceSection,
                icon: Icons.palette_outlined,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: <Widget>[
                        for (final mode in AppThemeMode.values)
                          TagChip(
                            label: mode.faLabel,
                            color: settings.themeMode == mode
                                ? AppColors.brand
                                : AppPalette.of(context).textTertiary,
                            icon: switch (mode) {
                              AppThemeMode.system => Icons.brightness_auto_rounded,
                              AppThemeMode.light => Icons.light_mode_rounded,
                              AppThemeMode.dark => Icons.dark_mode_rounded,
                            },
                            onTap: () => controller.setThemeMode(mode),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              _SettingsSection(
                title: S.learningSection,
                icon: Icons.track_changes_rounded,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _LabelRow(
                      label: S.dailyGoalLabel,
                      value: '${FaFormat.digits(settings.dailyGoalMinutes)} دقیقه',
                    ),
                    Slider(
                      value: settings.dailyGoalMinutes.toDouble().clamp(5, 30),
                      min: 5,
                      max: 30,
                      divisions: 5,
                      label: '${FaFormat.digits(settings.dailyGoalMinutes)} دقیقه',
                      onChanged: (value) => _update(
                        settings.copyWith(dailyGoalMinutes: value.round()),
                      ),
                    ),
                    _LabelRow(
                      label: S.wordsPerDayLabel,
                      value: '${FaFormat.digits(settings.dailyNewWords)} واژه',
                    ),
                    Slider(
                      value: settings.dailyNewWords.toDouble().clamp(5, 20),
                      min: 5,
                      max: 20,
                      divisions: 3,
                      label: '${FaFormat.digits(settings.dailyNewWords)} واژه',
                      onChanged: (value) => _update(
                        settings.copyWith(dailyNewWords: value.round()),
                      ),
                    ),
                    _SwitchRow(
                      icon: Icons.notifications_active_outlined,
                      title: S.reminderLabel,
                      subtitle: settings.remindersEnabled
                          ? '${S.reminderTimeLabel}: ${settings.reminderLabel}'
                          : 'یادآور روزانه خاموش است',
                      value: settings.remindersEnabled,
                      onChanged: (value) => value
                          ? _pickReminder(settings)
                          : _update(settings.copyWith(remindersEnabled: false)),
                      onTapTitle: () => _pickReminder(settings),
                    ),
                    _SwitchRow(
                      icon: Icons.translate_rounded,
                      title: 'نمایش راهنمای فارسی',
                      subtitle: 'نکته‌های کاربرد برای فارسی‌زبان‌ها در تمرین‌ها',
                      value: settings.showPersianHints,
                      onChanged: (value) =>
                          _update(settings.copyWith(showPersianHints: value)),
                    ),
                    _SwitchRow(
                      icon: Icons.lock_clock_rounded,
                      title: 'محدودیت نسخه‌ی رایگان',
                      subtitle: 'روزانه ${FaFormat.digits(30)} مرور رایگان',
                      value: settings.dailyFreeLimitEnabled,
                      onChanged: (value) => _update(
                        settings.copyWith(dailyFreeLimitEnabled: value),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              _SettingsSection(
                title: S.audioSection,
                icon: Icons.volume_up_outlined,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      S.speechRateLabel,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: AppPalette.of(context).textSecondary,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Wrap(
                      spacing: AppSpacing.xs,
                      children: <Widget>[
                        for (final option in <(String, double)>[
                          ('کند', 0.75),
                          ('معمولی', 1.0),
                          ('تند', 1.25),
                        ])
                          TagChip(
                            label: option.$1,
                            color:
                                (settings.speechSpeed - option.$2).abs() < 0.01
                                    ? AppColors.brand
                                    : AppPalette.of(context).textTertiary,
                            onTap: () =>
                                _update(settings.copyWith(speechSpeed: option.$2)),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    _SwitchRow(
                      icon: Icons.play_circle_outline_rounded,
                      title: S.autoPlayLabel,
                      subtitle: 'در تمرین شنیداری، واژه خودکار پخش شود',
                      value: settings.autoPlayAudio,
                      onChanged: (value) =>
                          _update(settings.copyWith(autoPlayAudio: value)),
                    ),
                    _SwitchRow(
                      icon: Icons.vibration_rounded,
                      title: 'لرزش لمسی',
                      subtitle: 'بازخورد لمسی هنگام پاسخ‌دادن',
                      value: settings.hapticsEnabled,
                      onChanged: (value) =>
                          _update(settings.copyWith(hapticsEnabled: value)),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    AppButton(
                      label: 'امتحان تلفظ',
                      icon: Icons.volume_up_rounded,
                      variant: AppButtonVariant.secondary,
                      height: 46,
                      onPressed: () =>
                          controller.speak('Resilient people keep learning.'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              _SettingsSection(
                title: S.accountSection,
                icon: Icons.workspace_premium_outlined,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _LabelRow(
                      label: S.subscriptionLabel,
                      value: controller.subscription.tier.faLabel,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    AppButton(
                      label: controller.hasPremium ? S.subscriptionManage : S.upgradeCta,
                      icon: Icons.workspace_premium_rounded,
                      variant: controller.hasPremium
                          ? AppButtonVariant.secondary
                          : AppButtonVariant.gold,
                      height: 46,
                      onPressed: () => Navigator.of(context).push(
                        AppRouter.build<void>(
                          settings: const RouteSettings(name: AppRoutes.paywall),
                          builder: (_) => const PaywallScreen(),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    AppButton(
                      label: S.paywallRestore,
                      icon: Icons.restore_rounded,
                      variant: AppButtonVariant.ghost,
                      height: 46,
                      onPressed: () async {
                        final result = await controller.restorePurchases();
                        if (!context.mounted) return;
                        showToast(
                          context,
                          result.success ? S.paywallRestored : S.paywallNothingToRestore,
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              _SettingsSection(
                title: S.dataSection,
                icon: Icons.storage_rounded,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _LabelRow(
                      label: 'نسخه‌ی محتوا',
                      value: container.contentVersion ?? '۱٫۰٫۰',
                    ),
                    _LabelRow(
                      label: 'تعداد واژه‌های بارگذاری‌شده',
                      value: FaFormat.digits(controller.allWords.length),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    AppButton(
                      label: S.contentUpdateAvailable,
                      icon: Icons.cloud_download_outlined,
                      variant: AppButtonVariant.secondary,
                      height: 46,
                      loading: _checkingUpdates,
                      onPressed: _checkUpdates,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    AppButton(
                      label: S.exportData,
                      icon: Icons.ios_share_rounded,
                      variant: AppButtonVariant.ghost,
                      height: 46,
                      onPressed: _export,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    AppButton(
                      label: S.resetProgress,
                      icon: Icons.delete_outline_rounded,
                      variant: AppButtonVariant.danger,
                      height: 46,
                      loading: _busy,
                      onPressed: _reset,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              _SettingsSection(
                title: S.aboutSection,
                icon: Icons.info_outline_rounded,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _LabelRow(label: 'نام اپ', value: S.appName),
                    _LabelRow(label: S.versionLabel, value: '۱٫۰٫۰'),
                    _LabelRow(label: 'موتور محتوا', value: 'آفلاین + به‌روزرسانی آنلاین'),
                    _LabelRow(
                      label: 'دستیار هوشمند',
                      value: container.aiRepository.engineLabel,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'واژه‌یار داده‌ی تو را جایی ارسال نمی‌کند؛ همه‌چیز روی همین '
                      'دستگاه ذخیره می‌شود.',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppPalette.of(context).textTertiary,
                            height: 1.8,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Center(
                child: TextButton.icon(
                  onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(
                    AppRoutes.onboarding,
                    (route) => false,
                  ),
                  icon: const Icon(Icons.restart_alt_rounded, size: 18),
                  label: const Text('دیدن دوباره‌ی آنبوردینگ'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SectionHeader(title: title, icon: icon),
          const SizedBox(height: AppSpacing.xs),
          child,
        ],
      ),
    );
  }
}

class _LabelRow extends StatelessWidget {
  const _LabelRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: <Widget>[
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: palette.textSecondary,
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

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.onTapTitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final VoidCallback? onTapTitle;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 19, color: palette.textTertiary),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: GestureDetector(
              onTap: onTapTitle,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: palette.textPrimary,
                        ),
                  ),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: palette.textTertiary,
                          fontSize: 10,
                        ),
                  ),
                ],
              ),
            ),
          ),
          Switch.adaptive(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}
