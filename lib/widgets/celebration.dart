import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_dimens.dart';
import '../core/utils/fa_format.dart';

/// جشن کاغذرنگی‌ها — بدون هیچ پکیج بیرونی، با CustomPainter.
///
/// وقتی [active] روشن شود، ذرات رنگی از بالای صفحه می‌ریزند و پس از پایان
/// نمایش، خودکار متوقف می‌شوند (مصرف CPU صفر در حالت غیرفعال).
class ConfettiOverlay extends StatefulWidget {
  const ConfettiOverlay({
    super.key,
    required this.active,
    this.particleCount = 42,
    this.duration = AppDurations.celebration,
    this.child,
    this.onFinished,
  });

  final bool active;
  final int particleCount;
  final Duration duration;
  final Widget? child;
  final VoidCallback? onFinished;

  @override
  State<ConfettiOverlay> createState() => _ConfettiOverlayState();
}

class _ConfettiOverlayState extends State<ConfettiOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );
  late final List<_Particle> _particles = _makeParticles();

  @override
  void initState() {
    super.initState();
    if (widget.active) _start();
  }

  @override
  void didUpdateWidget(ConfettiOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) _start();
  }

  void _start() {
    _controller.forward(from: 0).whenComplete(() {
      widget.onFinished?.call();
    });
  }

  List<_Particle> _makeParticles() {
    final random = math.Random(7);
    return List<_Particle>.generate(widget.particleCount, (index) {
      return _Particle(
        x: random.nextDouble(),
        delay: random.nextDouble() * 0.35,
        size: 5 + random.nextDouble() * 7,
        color: _colors[random.nextInt(_colors.length)],
        rotation: random.nextDouble() * math.pi,
        drift: (random.nextDouble() - 0.5) * 0.25,
        isCircle: random.nextBool(),
      );
    });
  }

  static const List<Color> _colors = <Color>[
    AppColors.brand,
    AppColors.accent,
    AppColors.gold,
    AppColors.pink,
    Color(0xFF2E90FA),
    Color(0xFF17B26A),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final content = widget.child ?? const SizedBox.shrink();
    return Stack(
      children: <Widget>[
        content,
        if (widget.active)
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) => CustomPaint(
                  painter: _ConfettiPainter(
                    particles: _particles,
                    progress: _controller.value,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _Particle {
  const _Particle({
    required this.x,
    required this.delay,
    required this.size,
    required this.color,
    required this.rotation,
    required this.drift,
    required this.isCircle,
  });

  final double x;
  final double delay;
  final double size;
  final Color color;
  final double rotation;
  final double drift;
  final bool isCircle;
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter({required this.particles, required this.progress});

  final List<_Particle> particles;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      final local = ((progress - particle.delay) / (1 - particle.delay)).clamp(0.0, 1.0);
      if (local <= 0) continue;
      final dy = -20 + local * (size.height + 40);
      final dx = particle.x * size.width + particle.drift * size.width * local;
      final opacity = local > 0.85 ? (1 - local) / 0.15 : 1.0;

      final paint = Paint()..color = particle.color.fade(opacity.clamp(0.0, 1.0));
      canvas.save();
      canvas.translate(dx, dy);
      canvas.rotate(particle.rotation + local * 6);
      if (particle.isCircle) {
        canvas.drawCircle(Offset.zero, particle.size / 2, paint);
      } else {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset.zero,
              width: particle.size,
              height: particle.size * 0.6,
            ),
            const Radius.circular(2),
          ),
          paint,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

/// نشان شناور امتیاز («+۱۲ امتیاز») که پس از پاسخ درست بالا می‌رود.
class XpPopBadge extends StatelessWidget {
  const XpPopBadge({
    super.key,
    required this.xp,
    this.reason,
    this.visible = true,
  });

  final int xp;
  final String? reason;
  final bool visible;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: visible ? 1 : 0,
      duration: AppDurations.fast,
      child: AnimatedSlide(
        offset: visible ? Offset.zero : const Offset(0, 0.4),
        duration: AppDurations.normal,
        curve: AppDurations.emphasizedCurve,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: AppColors.gold.fade(0.18),
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(color: AppColors.gold.fade(0.5)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(Icons.bolt_rounded, size: 16, color: AppColors.gold),
              const SizedBox(width: 4),
              Text(
                '+${FaFormat.digits(xp)} امتیاز',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppColors.goldDeep,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              if (reason != null) ...<Widget>[
                const SizedBox(width: AppSpacing.xs),
                Text(
                  '• $reason',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.goldDeep,
                      ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
