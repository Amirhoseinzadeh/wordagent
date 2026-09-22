import 'package:flutter/material.dart';

import '../../core/di/app_container.dart';
import '../../core/routing/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_palette.dart';
import '../../l10n/strings.dart';
import '../../widgets/animations.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';

/// صفحه‌ی راه‌انداز: نشان اپ، سپس تصمیم‌گیری بین آنبوردینگ و خانه.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _failed = false;
  bool _retrying = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _decide());
  }

  Future<void> _decide() async {
    // مکث کوتاه تا کاربر نشان اپ را ببیند و محتوا در پس‌زمینه آماده شود.
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    final container = AppScope.of(context);
    if (container.controller.allWords.isEmpty) {
      setState(() => _failed = true);
      return;
    }
    final onboarded = container.controller.profile.onboarded;
    Navigator.of(context).pushReplacementNamed(
      onboarded ? AppRoutes.shell : AppRoutes.onboarding,
    );
  }

  Future<void> _retry() async {
    if (_retrying) return;
    setState(() => _retrying = true);
    final container = AppScope.of(context);
    try {
      final words = await container.wordRepository.loadWords();
      final packs = await container.wordRepository.loadPacks();
      container.stores.wordsStore.value = words;
      container.stores.packsStore.value = packs;
    } catch (_) {
      // خطای بارگذاری را با همان کارت پایین به کاربر نشان می‌دهیم.
    }
    if (!mounted) return;
    setState(() => _retrying = false);
    if (container.controller.allWords.isNotEmpty) {
      setState(() => _failed = false);
      await _decide();
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Scaffold(
      backgroundColor: palette.background,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              AppColors.brand.fade(palette.isDark ? 0.22 : 0.12),
              palette.background,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Spacer(),
                FadeSlideIn(
                  child: Container(
                    width: 108,
                    height: 108,
                    decoration: BoxDecoration(
                      gradient: AppColors.brandGradient,
                      borderRadius: BorderRadius.circular(AppRadius.xl),
                      boxShadow: AppShadows.brandGlow(),
                    ),
                    child: const Center(
                      child: Text('📚', style: TextStyle(fontSize: 52)),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 120),
                  child: Text(
                    S.appName,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: palette.textPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
                const SizedBox(height: 6),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 200),
                  child: Text(
                    S.appTagline,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: palette.textSecondary,
                        ),
                  ),
                ),
                const Spacer(),
                if (_failed)
                  AppCard(
                    child: Column(
                      children: <Widget>[
                        Text(
                          S.somethingWentWrong,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                color: palette.textPrimary,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'محتوای واژه‌ها بارگذاری نشد. یک‌بار دیگر تلاش کن.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: palette.textSecondary,
                              ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        AppButton(
                          label: S.retry,
                          icon: Icons.refresh_rounded,
                          loading: _retrying,
                          onPressed: _retry,
                        ),
                      ],
                    ),
                  )
                else
                  const SizedBox(
                    width: 26,
                    height: 26,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.6,
                      color: AppColors.brand,
                    ),
                  ),
                const SizedBox(height: AppSpacing.md),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
