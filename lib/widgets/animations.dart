import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_dimens.dart';

/// ورود نرم و پله‌ای عناصر هنگام باز شدن صفحه.
class FadeSlideIn extends StatelessWidget {
  const FadeSlideIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.offset = 22,
    this.duration = AppDurations.normal,
  });

  final Widget child;
  final Duration delay;
  final double offset;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: duration + delay,
      curve: AppDurations.standardCurve,
      builder: (context, value, inner) {
        // تأخیر با نگه‌داشتن پیشرفت صفر در ابتدای بازه ساخته می‌شود
        // (بدون نیاز به State و بدون هزینه‌ی اجرا).
        final totalMs = (duration + delay).inMilliseconds;
        final delayMs = delay.inMilliseconds;
        final linear = totalMs == 0 ? 1.0 : (value * totalMs - delayMs) / math.max(1, duration.inMilliseconds);
        final curve = Curves.easeOutCubic.transform(linear.clamp(0.0, 1.0));
        return Opacity(
          opacity: curve,
          child: Transform.translate(
            offset: Offset(0, offset * (1 - curve)),
            child: inner,
          ),
        );
      },
      child: child,
    );
  }
}

/// بازخورد فشرده‌شدن هنگام لمس (حس اپلیکیشن‌های پریمیوم).
class ScaleTap extends StatefulWidget {
  const ScaleTap({
    super.key,
    required this.child,
    this.onTap,
    this.scale = 0.97,
    this.enableHaptics = true,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double scale;
  final bool enableHaptics;

  @override
  State<ScaleTap> createState() => _ScaleTapState();
}

class _ScaleTapState extends State<ScaleTap> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onTap == null ? null : (_) => setState(() => _pressed = true),
      onTapCancel: widget.onTap == null ? null : () => setState(() => _pressed = false),
      onTapUp: widget.onTap == null
          ? null
          : (_) {
              setState(() => _pressed = false);
              widget.onTap!.call();
            },
      child: AnimatedScale(
        scale: _pressed ? widget.scale : 1,
        duration: AppDurations.instant,
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

/// شمارنده‌ی انیمیشنی اعداد (امتیاز، تعداد واژه…).
class AnimatedCounter extends StatelessWidget {
  const AnimatedCounter({
    super.key,
    required this.value,
    required this.builder,
    this.duration = AppDurations.slow,
  });

  final int value;
  final Widget Function(BuildContext context, int value) builder;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: 0, end: value),
      duration: duration,
      curve: AppDurations.standardCurve,
      builder: (context, current, _) => builder(context, current),
    );
  }
}

/// درخشش عبوری روی عناصر در حال بارگذاری.
class ShimmerBox extends StatefulWidget {
  const ShimmerBox({
    super.key,
    this.width = double.infinity,
    this.height = 16,
    this.radius = AppRadius.xs,
  });

  final double width;
  final double height;
  final double radius;

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? const Color(0xFF1C2233) : const Color(0xFFEDEFF6);
    final highlight = isDark ? const Color(0xFF28304A) : const Color(0xFFF7F8FC);
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final value = _controller.value;
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            gradient: LinearGradient(
              begin: Alignment(-1 + value * 2, 0),
              end: Alignment(0 + value * 2, 0),
              colors: <Color>[base, highlight, base],
            ),
          ),
        );
      },
    );
  }
}

/// موج ضربه‌ای سبک اطراف عنصر (برای بازخورد تلفظ).
class PulsingHalo extends StatefulWidget {
  const PulsingHalo({
    super.key,
    required this.child,
    required this.active,
    this.color = AppColors.brand,
    this.size = 64,
  });

  final Widget child;
  final bool active;
  final Color color;
  final double size;

  @override
  State<PulsingHalo> createState() => _PulsingHaloState();
}

class _PulsingHaloState extends State<PulsingHalo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void initState() {
    super.initState();
    if (widget.active) _controller.repeat();
  }

  @override
  void didUpdateWidget(PulsingHalo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.active && _controller.isAnimating) {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final value = _controller.value;
          return Stack(
            alignment: Alignment.center,
            children: <Widget>[
              if (widget.active)
                Container(
                  width: widget.size * (0.7 + value * 0.3),
                  height: widget.size * (0.7 + value * 0.3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.color.fade((1 - value) * 0.25),
                  ),
                ),
              child ?? const SizedBox(),
            ],
          );
        },
        child: widget.child,
      ),
    );
  }
}
