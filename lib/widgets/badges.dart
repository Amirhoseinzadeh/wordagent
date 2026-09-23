import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_dimens.dart';
import '../core/theme/app_palette.dart';
import '../core/utils/fa_format.dart';
import '../domain/engines/xp_engine.dart';

/// نشان زنجیره‌ی روزانه.
class StreakBadge extends StatelessWidget {
  const StreakBadge({
    super.key,
    required this.days,
    this.freezes = 0,
    this.compact = false,
  });

  final int days;
  final int freezes;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final active = days > 0;
    final color = active ? AppColors.gold : AppPalette.of(context).textTertiary;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? AppSpacing.xs : AppSpacing.sm,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: color.fade(active ? 0.16 : 0.1),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            Icons.local_fire_department_rounded,
            size: compact ? 14 : 18,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            FaFormat.digits(days),
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w800,
                ),
          ),
          if (!compact) ...<Widget>[
            const SizedBox(width: 4),
            Text(
              'روز',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color),
            ),
          ],
          if (freezes > 0 && !compact) ...<Widget>[
            const SizedBox(width: AppSpacing.xs),
            Icon(Icons.shield_rounded, size: 14, color: AppColors.accent),
            const SizedBox(width: 2),
            Text(
              FaFormat.digits(freezes),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}

/// نشان سطح کاربر در اپ.
class LevelBadge extends StatelessWidget {
  const LevelBadge({super.key, required this.level, this.showTitle = true});

  final AppLevel level;
  final bool showTitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(level.emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 5),
          Text(
            'سطح ${FaFormat.digits(level.index)}',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
          ),
          if (showTitle) ...<Widget>[
            const SizedBox(width: 5),
            Container(width: 1, height: 12, color: Colors.white.fade(0.4)),
            const SizedBox(width: 5),
            Text(
              level.title,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.white.fade(0.92),
                  ),
            ),
          ],
        ],
      ),
    );
  }
}

/// نشان سطح زبان (CEFR).
class CefrBadge extends StatelessWidget {
  const CefrBadge({
    super.key,
    required this.code,
    required this.title,
    this.color,
    this.dense = false,
  });

  final String code;
  final String title;
  final Color? color;
  final bool dense;

  static const Map<String, Color> _colors = <String, Color>{
    'A1': Color(0xFF17B26A),
    'A2': Color(0xFF2E90FA),
    'B1': Color(0xFF6C4CF1),
    'B2': Color(0xFFF04492),
    'C1': Color(0xFFF5A524),
    'C2': Color(0xFFF04438),
  };

  @override
  Widget build(BuildContext context) {
    final accent = color ?? _colors[code] ?? AppColors.brand;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 6 : AppSpacing.xs,
        vertical: dense ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: accent.fade(0.16),
        borderRadius: BorderRadius.circular(AppRadius.xs),
        border: Border.all(color: accent.fade(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            code,
            style: TextStyle(
              color: accent,
              fontWeight: FontWeight.w800,
              fontSize: dense ? 10 : 12,
              letterSpacing: 0.3,
            ),
          ),
          if (!dense) ...<Widget>[
            const SizedBox(width: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(color: accent),
            ),
          ],
        ],
      ),
    );
  }
}

/// نشان نسخه‌ی ویژه.
class PremiumBadge extends StatelessWidget {
  const PremiumBadge({super.key, this.label = 'ویژه', this.dense = false});

  final String label;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 6 : AppSpacing.xs,
        vertical: dense ? 2 : 4,
      ),
      decoration: BoxDecoration(
        gradient: AppColors.goldGradient,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            Icons.workspace_premium_rounded,
            size: dense ? 11 : 13,
            color: const Color(0xFF3A2400),
          ),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              color: const Color(0xFF3A2400),
              fontWeight: FontWeight.w800,
              fontSize: dense ? 10 : 11.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// نمایش دشواری با نقطه‌های رنگی.
class DifficultyDots extends StatelessWidget {
  const DifficultyDots({super.key, required this.difficulty, this.max = 5});

  final int difficulty;
  final int max;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (var i = 0; i < max; i++)
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.symmetric(horizontal: 1.5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i < difficulty
                  ? _colorFor(difficulty)
                  : palette.border,
            ),
          ),
      ],
    );
  }

  Color _colorFor(int value) {
    if (value <= 1) return AppColors.success;
    if (value == 2) return const Color(0xFF7BC043);
    if (value == 3) return AppColors.warning;
    if (value == 4) return const Color(0xFFF97316);
    return AppColors.danger;
  }
}

/// قرص وضعیت یادگیری واژه (جدید، در حال یادگیری، مسلط…).
class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: 3),
      decoration: BoxDecoration(
        color: color.fade(0.14),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}
