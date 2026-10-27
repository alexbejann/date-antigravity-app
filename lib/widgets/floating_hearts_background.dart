import 'dart:math' as math;
import 'package:flutter/material.dart';

class FloatingHeartsBackground extends StatefulWidget {
  final Widget child;

  const FloatingHeartsBackground({
    super.key,
    required this.child,
  });

  @override
  State<FloatingHeartsBackground> createState() =>
      _FloatingHeartsBackgroundState();
}

class _FloatingHeartsBackgroundState extends State<FloatingHeartsBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_FloatingParticle> _particles;

  @override
  void initState() {
    super.initState();
    final rng = math.Random(42);
    _particles = List.generate(24, (index) {
      return _FloatingParticle(
        xFraction: rng.nextDouble(),
        initialYFraction: rng.nextDouble(),
        speed: 0.08 + rng.nextDouble() * 0.14,
        size: 14.0 + rng.nextDouble() * 20.0,
        swayAmplitude: 10.0 + rng.nextDouble() * 25.0,
        swayFrequency: 1.0 + rng.nextDouble() * 2.0,
        phase: rng.nextDouble() * math.pi * 2,
        opacity: 0.12 + rng.nextDouble() * 0.22,
        isSparkle: index % 4 == 0,
      );
    });

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 25),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFF0F5), // Soft lavender blush
            Color(0xFFFFE4EC), // Romantic rose mist
            Color(0xFFFFF7F0), // Warm peach cream
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  return CustomPaint(
                    painter: _HeartsBackgroundPainter(
                      progress: _controller.value,
                      particles: _particles,
                    ),
                  );
                },
              ),
            ),
          ),
          widget.child,
        ],
      ),
    );
  }
}

class _FloatingParticle {
  final double xFraction;
  final double initialYFraction;
  final double speed;
  final double size;
  final double swayAmplitude;
  final double swayFrequency;
  final double phase;
  final double opacity;
  final bool isSparkle;

  const _FloatingParticle({
    required this.xFraction,
    required this.initialYFraction,
    required this.speed,
    required this.size,
    required this.swayAmplitude,
    required this.swayFrequency,
    required this.phase,
    required this.opacity,
    required this.isSparkle,
  });
}

class _HeartsBackgroundPainter extends CustomPainter {
  final double progress;
  final List<_FloatingParticle> particles;

  _HeartsBackgroundPainter({
    required this.progress,
    required this.particles,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final yNorm = (p.initialYFraction - progress * p.speed * 6.0) % 1.0;
      final y = (yNorm < 0 ? yNorm + 1.0 : yNorm) * size.height;
      final sway = math.sin(progress * math.pi * 2 * p.swayFrequency + p.phase) *
          p.swayAmplitude;
      final x = (p.xFraction * size.width) + sway;

      final paint = Paint()
        ..color = (p.isSparkle
                ? const Color(0xFFFFB703)
                : const Color(0xFFFF4D79))
            .withOpacity(p.opacity)
        ..style = PaintingStyle.fill;

      if (p.isSparkle) {
        _drawSparkle(canvas, Offset(x, y), p.size * 0.6, paint);
      } else {
        _drawHeart(canvas, Offset(x, y), p.size, paint);
      }
    }
  }

  void _drawHeart(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path();
    final width = size;
    final height = size;
    final x = center.dx - width / 2;
    final y = center.dy - height / 2;

    path.moveTo(x + width / 2, y + height * 0.88);
    path.cubicTo(
      x + width * 0.1,
      y + height * 0.55,
      x - width * 0.05,
      y + height * 0.25,
      x + width * 0.25,
      y + height * 0.12,
    );
    path.cubicTo(
      x + width * 0.42,
      y + height * 0.05,
      x + width / 2,
      y + height * 0.22,
      x + width / 2,
      y + height * 0.28,
    );
    path.cubicTo(
      x + width / 2,
      y + height * 0.22,
      x + width * 0.58,
      y + height * 0.05,
      x + width * 0.75,
      y + height * 0.12,
    );
    path.cubicTo(
      x + width * 1.05,
      y + height * 0.25,
      x + width * 0.9,
      y + height * 0.55,
      x + width / 2,
      y + height * 0.88,
    );
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawSparkle(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    for (int i = 0; i < 8; i++) {
      final angle = i * math.pi / 4;
      final r = i.isEven ? radius : radius * 0.35;
      final px = center.dx + math.cos(angle) * r;
      final py = center.dy + math.sin(angle) * r;
      if (i == 0) {
        path.moveTo(px, py);
      } else {
        path.lineTo(px, py);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _HeartsBackgroundPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class CelebrationConfettiOverlay extends StatefulWidget {
  final int triggerCount;

  const CelebrationConfettiOverlay({
    super.key,
    required this.triggerCount,
  });

  @override
  State<CelebrationConfettiOverlay> createState() =>
      _CelebrationConfettiOverlayState();
}

class _CelebrationConfettiOverlayState extends State<CelebrationConfettiOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  List<_ConfettiPiece> _pieces = [];
  final math.Random _rng = math.Random();

  static const List<Color> _palette = [
    Color(0xFFFF2A6D),
    Color(0xFFFF6B9D),
    Color(0xFFFFB703),
    Color(0xFFFB8500),
    Color(0xFF9B5DE5),
    Color(0xFF00BBF9),
    Color(0xFF00F5D4),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );
    if (widget.triggerCount > 0) {
      _spawnBurst();
    }
  }

  @override
  void didUpdateWidget(covariant CelebrationConfettiOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.triggerCount != oldWidget.triggerCount &&
        widget.triggerCount > 0) {
      _spawnBurst();
    }
  }

  void _spawnBurst() {
    _pieces = List.generate(95, (index) {
      return _ConfettiPiece(
        startX: 0.1 + _rng.nextDouble() * 0.8,
        startY: -0.05 - _rng.nextDouble() * 0.25,
        vx: (_rng.nextDouble() - 0.5) * 0.45,
        vy: 0.65 + _rng.nextDouble() * 0.75,
        size: 8.0 + _rng.nextDouble() * 10.0,
        color: _palette[_rng.nextInt(_palette.length)],
        rotationSpeed: (_rng.nextDouble() - 0.5) * 10.0,
        isHeart: index % 3 == 0,
      );
    });
    _controller.forward(from: 0.0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          if (!_controller.isAnimating && _controller.value == 0.0) {
            return const SizedBox.shrink();
          }
          return CustomPaint(
            size: Size.infinite,
            painter: _ConfettiPainter(
              t: _controller.value,
              pieces: _pieces,
            ),
          );
        },
      ),
    );
  }
}

class _ConfettiPiece {
  final double startX;
  final double startY;
  final double vx;
  final double vy;
  final double size;
  final Color color;
  final double rotationSpeed;
  final bool isHeart;

  const _ConfettiPiece({
    required this.startX,
    required this.startY,
    required this.vx,
    required this.vy,
    required this.size,
    required this.color,
    required this.rotationSpeed,
    required this.isHeart,
  });
}

class _ConfettiPainter extends CustomPainter {
  final double t;
  final List<_ConfettiPiece> pieces;

  _ConfettiPainter({
    required this.t,
    required this.pieces,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0.0 || t >= 1.0) return;

    final fade = t > 0.75 ? (1.0 - (t - 0.75) / 0.25).clamp(0.0, 1.0) : 1.0;

    for (final p in pieces) {
      final x = (p.startX + p.vx * t) * size.width;
      final y = (p.startY + p.vy * t + 0.35 * t * t) * size.height;

      final paint = Paint()
        ..color = p.color.withOpacity(fade)
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(t * p.rotationSpeed);

      if (p.isHeart) {
        final s = p.size * 1.3;
        final path = Path();
        path.moveTo(0, s * 0.38);
        path.cubicTo(-s * 0.4, s * 0.05, -s * 0.55, -s * 0.25, -s * 0.25, -s * 0.38);
        path.cubicTo(-s * 0.08, -s * 0.45, 0, -s * 0.28, 0, -s * 0.22);
        path.cubicTo(0, -s * 0.28, s * 0.08, -s * 0.45, s * 0.25, -s * 0.38);
        path.cubicTo(s * 0.55, -s * 0.25, s * 0.4, s * 0.05, 0, s * 0.38);
        path.close();
        canvas.drawPath(path, paint);
      } else {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset.zero,
              width: p.size,
              height: p.size * 0.55,
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
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) =>
      oldDelegate.t != t;
}
