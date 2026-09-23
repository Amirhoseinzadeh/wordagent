import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_dimens.dart';
import '../core/theme/app_palette.dart';
import '../core/utils/fa_format.dart';

/// حلقه‌ی پیشرفت (هدف روزانه، تسلط، …).
class ProgressRing extends StatelessWidget {
  const ProgressRing({
    super.key,
    required this.progress,
    this.size = AppSizes.progressRing,
    this.strokeWidth = 10,
    this.center,
    this.gradientColors = const <Color>[Color(0xFF7B5CFF), Color(0xFF5B3BE0)],
    this.trackColor,
  });

  final double progress;
  final double size;
  final double strokeWidth;
  final Widget? center;
  final List<Color> gradientColors;
  final Color? trackColor;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: progress.clamp(0.0, 1.0)),
      duration: AppDurations.slow,
      curve: AppDurations.standardCurve,
      builder: (context, value, _) {
        return SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _RingPainter(
              progress: value,
              strokeWidth: strokeWidth,
              trackColor: trackColor ?? palette.border,
              colors: gradientColors,
            ),
            child: Center(child: center),
          ),
        );
      },
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.strokeWidth,
    required this.trackColor,
    required this.colors,
  });

  final double progress;
  final double strokeWidth;
  final Color trackColor;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final center = rect.center;
    final radius = (math.min(size.width, size.height) - strokeWidth) / 2;

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = trackColor;
    canvas.drawCircle(center, radius, track);

    if (progress <= 0) return;

    final progressPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: 3 * math.pi / 2,
        colors: <Color>[colors.first, colors.last, colors.first],
        transform: const GradientRotation(-math.pi / 2),
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.strokeWidth != strokeWidth ||
      oldDelegate.trackColor != trackColor;
}

/// نوار پیشرفت خطی با گرادیان.
class AppProgressBar extends StatelessWidget {
  const AppProgressBar({
    super.key,
    required this.progress,
    this.height = 10,
    this.gradient = AppColors.brandGradient,
    this.trackColor,
    this.radius = AppRadius.pill,
  });

  final double progress;
  final double height;
  final Gradient gradient;
  final Color? trackColor;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Stack(
        children: <Widget>[
          Container(
            height: height,
            color: trackColor ?? palette.surfaceAlt,
          ),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: progress.clamp(0.0, 1.0)),
            duration: AppDurations.slow,
            curve: AppDurations.standardCurve,
            builder: (context, value, _) => FractionallySizedBox(
              widthFactor: value == 0 ? 0.001 : value,
              child: Container(
                height: height,
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(radius),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// نمودار میله‌ای کوچک (فعالیت هفته).
class MiniBarChart extends StatelessWidget {
  const MiniBarChart({
    super.key,
    required this.values,
    this.labels = const <String>[],
    this.height = 90,
    this.color = AppColors.brand,
    this.highlightIndex,
  });

  final List<double> values;
  final List<String> labels;
  final double height;
  final Color color;
  final int? highlightIndex;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    if (values.isEmpty) return SizedBox(height: height);
    final maxValue = values.reduce(math.max);
    return SizedBox(
      height: height + (labels.isEmpty ? 0 : 22),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          for (var i = 0; i < values.length; i++)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(
                        begin: 0,
                        end: maxValue <= 0 ? 0 : (values[i] / maxValue),
                      ),
                      duration: Duration(milliseconds: 320 + i * 45),
                      curve: Curves.easeOutCubic,
                      builder: (context, factor, _) => Container(
                        height: math.max(4, height * factor),
                        decoration: BoxDecoration(
                          gradient: highlightIndex == i
                              ? AppColors.goldGradient
                              : LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: <Color>[color, color.lighten(0.25)],
                                ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                    if (labels.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 6),
                      Text(
                        labels[i],
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: highlightIndex == i
                                  ? AppColors.gold
                                  : palette.textTertiary,
                              fontSize: 10,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// نمودار خطی روند (دقت پاسخ‌ها).
class SparkLineChart extends StatelessWidget {
  const SparkLineChart({
    super.key,
    required this.values,
    this.height = 110,
    this.color = AppColors.accent,
    this.showAverage = true,
  });

  final List<double> values;
  final double height;
  final Color color;
  final bool showAverage;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    if (values.length < 2) {
      return SizedBox(
        height: height,
        child: Center(
          child: Text(
            'داده‌ی کافی برای نمودار نیست',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: palette.textTertiary,
                ),
          ),
        ),
      );
    }
    return SizedBox(
      height: height,
      width: double.infinity,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: 1),
        duration: AppDurations.slow,
        curve: AppDurations.standardCurve,
        builder: (context, t, _) => CustomPaint(
          painter: _SparkLinePainter(
            values: values,
            progress: t,
            color: color,
            average: showAverage ? _average(values) : null,
            gridColor: palette.border,
          ),
        ),
      ),
    );
  }

  double _average(List<double> data) =>
      data.reduce((a, b) => a + b) / data.length;
}

class _SparkLinePainter extends CustomPainter {
  _SparkLinePainter({
    required this.values,
    required this.progress,
    required this.color,
    required this.gridColor,
    this.average,
  });

  final List<double> values;
  final double progress;
  final Color color;
  final Color gridColor;
  final double? average;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    final maxValue = values.reduce(math.max);
    final minValue = values.reduce(math.min);
    final range = (maxValue - minValue).abs() < 0.001 ? 1.0 : maxValue - minValue;
    final stepX = size.width / (values.length - 1);
    final points = <Offset>[];
    for (var i = 0; i < values.length; i++) {
      final normalized = (values[i] - minValue) / range;
      final y = size.height - (normalized * (size.height - 16)) - 8;
      points.add(Offset(stepX * i, y));
    }

    // خط میانگین
    final avg = average;
    if (avg != null) {
      final normalized = (avg - minValue) / range;
      final y = size.height - (normalized * (size.height - 16)) - 8;
      final gridPaint = Paint()
        ..color = gridColor
        ..strokeWidth = 1;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final visibleCount = math.max(2, (points.length * progress).ceil());
    final visible = points.take(visibleCount).toList(growable: false);
    if (visible.length < 2) return;

    final linePath = Path()..moveTo(visible.first.dx, visible.first.dy);
    for (var i = 1; i < visible.length; i++) {
      final previous = visible[i - 1];
      final current = visible[i];
      final controlX = (previous.dx + current.dx) / 2;
      linePath.cubicTo(
        controlX,
        previous.dy,
        controlX,
        current.dy,
        current.dx,
        current.dy,
      );
    }

    final areaPath = Path.from(linePath)
      ..lineTo(visible.last.dx, size.height)
      ..lineTo(visible.first.dx, size.height)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[color.fade(0.35), color.fade(0.02)],
      ).createShader(Offset.zero & size);
    canvas.drawPath(areaPath, fillPaint);

    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round
      ..color = color;
    canvas.drawPath(linePath, linePaint);

    canvas.drawCircle(visible.last, 4, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_SparkLinePainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.values != values;
}

/// نقشه‌ی حرارتی فعالیت (شبکه‌ی ۷ ستونه).
class ActivityHeatmap extends StatelessWidget {
  const ActivityHeatmap({
    super.key,
    required this.counts,
    this.days = 35,
    this.color = AppColors.accent,
  });

  /// ترتیب داده‌ها: از قدیم به جدید.
  final List<int> counts;
  final int days;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final data = counts.length > days ? counts.sublist(counts.length - days) : counts;
    final maxValue = data.isEmpty ? 0 : data.reduce(math.max);
    final cells = <Widget>[];
    for (var i = 0; i < data.length; i++) {
      final intensity = maxValue == 0 ? 0.0 : data[i] / maxValue;
      cells.add(
        Padding(
          padding: const EdgeInsets.all(2),
          child: Container(
            decoration: BoxDecoration(
              color: intensity == 0
                  ? palette.surfaceAlt
                  : color.fade(0.2 + intensity * 0.8),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 0,
          crossAxisSpacing: 0,
          children: cells,
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: <Widget>[
            Text(
              'کم',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: palette.textTertiary,
                  ),
            ),
            const SizedBox(width: AppSpacing.xs),
            for (var i = 0; i < 4; i++)
              Container(
                width: 12,
                height: 12,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: color.fade(0.2 + i * 0.25),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              'زیاد',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: palette.textTertiary,
                  ),
            ),
          ],
        ),
      ],
    );
  }
}

/// نوار تسلط سگمنتی (توزیع واژه‌ها در سبدهای تسلط).
class MasteryDistributionBar extends StatelessWidget {
  const MasteryDistributionBar({
    super.key,
    required this.buckets,
  });

  /// کلید: کف سبد (۰، ۲۵، ۵۰، ۷۵، ۱۰۰) — مقدار: تعداد واژه.
  final Map<int, int> buckets;

  static const List<int> _order = <int>[0, 25, 50, 75, 100];

  static const List<Color> _colors = <Color>[
    Color(0xFFB0B7C9),
    Color(0xFF2E90FA),
    Color(0xFF6C4CF1),
    Color(0xFF00BFA5),
    Color(0xFF17B26A),
  ];

  String _labelFor(int bucket) {
    switch (bucket) {
      case 0:
        return 'شروع';
      case 25:
        return 'نوپا';
      case 50:
        return 'در حال یادگیری';
      case 75:
        return 'نزدیک به تسلط';
      default:
        return 'مسلط';
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final total = buckets.values.fold<int>(0, (sum, value) => sum + value);
    if (total == 0) {
      return Text(
        'هنوز واژه‌ای در برنامه‌ی یادگیری نداری.',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: palette.textTertiary,
            ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: SizedBox(
            height: 14,
            child: Row(
              children: <Widget>[
                for (var i = 0; i < _order.length; i++)
                  if ((buckets[_order[i]] ?? 0) > 0)
                    Expanded(
                      flex: buckets[_order[i]]!,
                      child: Container(color: _colors[i]),
                    ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.xs,
          children: <Widget>[
            for (var i = 0; i < _order.length; i++)
              if ((buckets[_order[i]] ?? 0) > 0)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: _colors[i],
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${_labelFor(_order[i])} • ${FaFormat.digits(buckets[_order[i]] ?? 0)}',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: palette.textSecondary,
                          ),
                    ),
                  ],
                ),
          ],
        ),
      ],
    );
  }
}
