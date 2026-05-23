import 'package:flutter/material.dart';
import 'dart:math' as math;

class BadPulsingSphere extends StatefulWidget {
  const BadPulsingSphere({super.key});

  @override
  State<BadPulsingSphere> createState() => _BadPulsingSphereState();
}

class _BadPulsingSphereState extends State<BadPulsingSphere> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 5))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280, height: 280,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) => CustomPaint(painter: _DarkPlasmaPainter(animationValue: _controller.value)),
      ),
    );
  }
}

class _DarkPlasmaPainter extends CustomPainter {
  final double animationValue;
  _DarkPlasmaPainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = size.width / 2.6;
    final time = animationValue * 2 * math.pi;

    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [const Color(0xFF3E000F), const Color(0xFF800020).withValues(alpha: 0.7), Colors.transparent],
        stops: const [0.3, 0.7, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: baseRadius + 20));
    canvas.drawCircle(center, baseRadius + 20, glowPaint);

    void drawDarkWave(Color color, double freq, double amp, double phase, double strokeWidth) {
      final paint = Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = strokeWidth..isAntiAlias = true;
      final path = Path();
      const points = 100;
      for (int i = 0; i <= points; i++) {
        final angle = (i / points) * 2 * math.pi;
        // Aszimmetrikus, fortyogó mozgás
        final offset = math.sin(angle * freq - time * 1.5 + phase) * amp + math.sin(angle * 7 + time) * (amp*0.3);
        final r = baseRadius + offset;
        final x = center.dx + r * math.cos(angle);
        final y = center.dy + r * math.sin(angle);
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(path, paint);
    }

    drawDarkWave(Colors.black.withValues(alpha: 0.6), 4, 12, 0, 4.0);
    drawDarkWave(const Color(0xFFC62828).withValues(alpha: 0.8), 3, 15, math.pi, 2.5);
    drawDarkWave(const Color(0xFFFF5252).withValues(alpha: 0.5), 5, 8, math.pi/2, 1.5);
  }
  @override
  bool shouldRepaint(covariant _DarkPlasmaPainter oldDelegate) => true;
}