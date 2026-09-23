import 'package:flutter/material.dart';

import '../../core/di/app_container.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_palette.dart';
import '../../core/utils/fa_format.dart';
import '../../l10n/strings.dart';
import '../../widgets/animations.dart';
import '../explore/explore_screen.dart';
import '../home/home_screen.dart';
import '../profile/profile_screen.dart';
import '../progress/progress_screen.dart';
import '../review/learn_hub_screen.dart';

/// پوسته‌ی اصلی اپ با نوار ناوبری پایین.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  late int _index = widget.initialIndex.clamp(0, 4);

  void _select(int index) {
    if (index == _index) return;
    setState(() => _index = index);
  }

  @override
  Widget build(BuildContext context) {
    final container = AppScope.of(context);
    final palette = AppPalette.of(context);
    final dueCount = container.controller.dueCount;

    final tabs = <Widget>[
      HomeScreen(onOpenTab: _select),
      const LearnHubScreen(),
      const ExploreScreen(),
      const ProgressScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: palette.background,
      body: IndexedStack(index: _index, children: tabs),
      bottomNavigationBar: _BottomNav(
        index: _index,
        onSelect: _select,
        badges: <int, String>{
          0: dueCount > 0 ? FaFormat.digits(dueCount) : '',
          1: dueCount > 0 ? FaFormat.digits(dueCount) : '',
        },
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({
    required this.index,
    required this.onSelect,
    required this.badges,
  });

  final int index;
  final ValueChanged<int> onSelect;
  final Map<int, String> badges;

  static const List<(IconData, IconData, String)> _items = <(IconData, IconData, String)>[
    (Icons.home_outlined, Icons.home_rounded, S.navHome),
    (Icons.school_outlined, Icons.school_rounded, S.navLearn),
    (Icons.search_rounded, Icons.search_rounded, S.navExplore),
    (Icons.insights_outlined, Icons.insights_rounded, S.navProgress),
    (Icons.person_outline_rounded, Icons.person_rounded, S.navProfile),
  ];

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Container(
      decoration: BoxDecoration(
        color: palette.surface,
        border: Border(top: BorderSide(color: palette.border)),
        boxShadow: AppShadows.soft(palette.isDark),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: AppSizes.bottomNavHeight,
          child: Row(
            children: <Widget>[
              for (var i = 0; i < _items.length; i++)
                Expanded(
                  child: _NavItem(
                    icon: _items[i].$1,
                    activeIcon: _items[i].$2,
                    label: _items[i].$3,
                    selected: i == index,
                    badge: badges[i],
                    onTap: () => onSelect(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.badge,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final color = selected ? AppColors.brand : palette.textTertiary;
    return ScaleTap(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Stack(
              clipBehavior: Clip.none,
              children: <Widget>[
                AnimatedContainer(
                  duration: AppDurations.fast,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.brandSoft : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Icon(selected ? activeIcon : icon, size: 23, color: color),
                ),
                if (badge != null && badge!.isNotEmpty)
                  Positioned(
                    top: -2,
                    left: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.danger,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(
                        badge!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: color,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                    fontSize: 10.5,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
