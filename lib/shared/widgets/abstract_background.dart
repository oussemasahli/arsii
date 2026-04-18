import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Animated abstract background with floating geometric shapes,
/// radial glow blobs, and a subtle grid pattern.
class AbstractBackground extends StatefulWidget {
  const AbstractBackground({super.key});

  @override
  State<AbstractBackground> createState() => _AbstractBackgroundState();
}

class _AbstractBackgroundState extends State<AbstractBackground>
    with TickerProviderStateMixin {
  late final AnimationController _slowDrift;
  late final AnimationController _mediumDrift;

  @override
  void initState() {
    super.initState();
    _slowDrift = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
    _mediumDrift = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
  }

  @override
  void dispose() {
    _slowDrift.dispose();
    _mediumDrift.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_slowDrift, _mediumDrift]),
      builder: (context, _) {
        return CustomPaint(
          painter: _BackgroundPainter(
            slowT: _slowDrift.value,
            mediumT: _mediumDrift.value,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class _BackgroundPainter extends CustomPainter {
  final double slowT;
  final double mediumT;

  _BackgroundPainter({required this.slowT, required this.mediumT});

  @override
  void paint(Canvas canvas, Size size) {
    _drawGlowBlobs(canvas, size);
    _drawGridPattern(canvas, size);
    _drawFloatingShapes(canvas, size);
  }

  void _drawGlowBlobs(Canvas canvas, Size size) {
    // Large cyan glow – top right area
    final cyanCenter = Offset(
      size.width * (0.7 + 0.05 * sin(slowT * 2 * pi)),
      size.height * (0.2 + 0.05 * cos(slowT * 2 * pi)),
    );
    final cyanPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          AppColors.primary.withOpacity(0.08),
          AppColors.primary.withOpacity(0.0),
        ],
      ).createShader(
        Rect.fromCircle(center: cyanCenter, radius: size.width * 0.4),
      );
    canvas.drawCircle(cyanCenter, size.width * 0.4, cyanPaint);

    // Violet glow – bottom left area
    final violetCenter = Offset(
      size.width * (0.25 + 0.04 * cos(mediumT * 2 * pi)),
      size.height * (0.75 + 0.04 * sin(mediumT * 2 * pi)),
    );
    final violetPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          AppColors.secondary.withOpacity(0.07),
          AppColors.secondary.withOpacity(0.0),
        ],
      ).createShader(
        Rect.fromCircle(center: violetCenter, radius: size.width * 0.35),
      );
    canvas.drawCircle(violetCenter, size.width * 0.35, violetPaint);

    // Small pink glow – center
    final pinkCenter = Offset(
      size.width * (0.5 + 0.06 * sin(mediumT * 2 * pi + 1.0)),
      size.height * (0.45 + 0.05 * cos(slowT * 2 * pi + 0.5)),
    );
    final pinkPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          AppColors.tertiary.withOpacity(0.04),
          AppColors.tertiary.withOpacity(0.0),
        ],
      ).createShader(
        Rect.fromCircle(center: pinkCenter, radius: size.width * 0.2),
      );
    canvas.drawCircle(pinkCenter, size.width * 0.2, pinkPaint);
  }

  void _drawGridPattern(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = AppColors.border.withOpacity(0.08)
      ..strokeWidth = 0.5;

    const spacing = 60.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  void _drawFloatingShapes(Canvas canvas, Size size) {
    // Rotating ring – top-right area
    _drawRing(
      canvas,
      center: Offset(
        size.width * 0.8 + 20 * sin(slowT * 2 * pi),
        size.height * 0.15 + 15 * cos(slowT * 2 * pi),
      ),
      radius: 40,
      color: AppColors.primary.withOpacity(0.12),
      rotation: slowT * 2 * pi,
    );

    // Small diamond – left center
    _drawDiamond(
      canvas,
      center: Offset(
        size.width * 0.1 + 10 * cos(mediumT * 2 * pi),
        size.height * 0.5 + 20 * sin(mediumT * 2 * pi),
      ),
      size: 18,
      color: AppColors.secondary.withOpacity(0.15),
      rotation: mediumT * 2 * pi * 0.5,
    );

    // Floating dots
    final dotPaint = Paint()..style = PaintingStyle.fill;
    final dots = [
      _FloatingDot(0.15, 0.25, 3, AppColors.primary.withOpacity(0.2)),
      _FloatingDot(0.85, 0.65, 2.5, AppColors.secondary.withOpacity(0.18)),
      _FloatingDot(0.6, 0.85, 2, AppColors.tertiary.withOpacity(0.15)),
      _FloatingDot(0.4, 0.12, 3.5, AppColors.primary.withOpacity(0.1)),
      _FloatingDot(0.92, 0.4, 2, AppColors.secondary.withOpacity(0.12)),
    ];

    for (final dot in dots) {
      dotPaint.color = dot.color;
      final offset = Offset(
        size.width * dot.x + 8 * sin(slowT * 2 * pi + dot.x * 10),
        size.height * dot.y + 8 * cos(mediumT * 2 * pi + dot.y * 10),
      );
      canvas.drawCircle(offset, dot.radius, dotPaint);
    }

    // Subtle horizontal scan line effect
    final scanY = size.height * ((slowT * 0.5) % 1.0);
    final scanPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          AppColors.primary.withOpacity(0.0),
          AppColors.primary.withOpacity(0.03),
          AppColors.primary.withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTWH(0, scanY - 30, size.width, 60));
    canvas.drawRect(Rect.fromLTWH(0, scanY - 30, size.width, 60), scanPaint);
  }

  void _drawRing(
    Canvas canvas, {
    required Offset center,
    required double radius,
    required Color color,
    required double rotation,
  }) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: radius * 2, height: radius),
      paint,
    );
    canvas.restore();
  }

  void _drawDiamond(
    Canvas canvas, {
    required Offset center,
    required double size,
    required Color color,
    required double rotation,
  }) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);

    final path = Path()
      ..moveTo(0, -size)
      ..lineTo(size, 0)
      ..lineTo(0, size)
      ..lineTo(-size, 0)
      ..close();

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_BackgroundPainter old) => true;
}

class _FloatingDot {
  final double x, y, radius;
  final Color color;
  const _FloatingDot(this.x, this.y, this.radius, this.color);
}
