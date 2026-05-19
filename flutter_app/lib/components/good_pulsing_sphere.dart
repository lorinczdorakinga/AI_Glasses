import 'package:flutter/material.dart';
import 'dart:math' as math;

class GoodPulsingSphere extends StatefulWidget {
  const GoodPulsingSphere({super.key});

  @override
  State<GoodPulsingSphere> createState() => _GoodPulsingSphereState();
}

class _GoodPulsingSphereState extends State<GoodPulsingSphere> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat();
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
        builder: (context, child) => CustomPaint(painter: _SmoothAuraPainter(animationValue: _controller.value)),
      ),
    );
  }
}

class _SmoothAuraPainter extends CustomPainter {
  final double animationValue;
  _SmoothAuraPainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = size.width / 2.6; 
    final time = animationValue * 2 * math.pi;

    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [Colors.white, const Color(0xFF4DB6AC).withValues(alpha: 0.5), Colors.transparent],
        stops: const [0.2, 0.7, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: baseRadius + 30));
    
    canvas.drawCircle(center, baseRadius + 30, glowPaint);

    void drawSmoothWave(Color color, double freq, double amp, double phase, double strokeWidth) {
      final paint = Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = strokeWidth..isAntiAlias = true;
      final path = Path();
      const points = 100;
      for (int i = 0; i <= points; i++) {
        final angle = (i / points) * 2 * math.pi;
        // Nagyon lágy, organikus mozgás
        final offset = math.sin(angle * freq + time + phase) * amp + math.cos(angle * (freq-1) - time*0.5) * (amp*0.5);
        final r = baseRadius + offset;
        final x = center.dx + r * math.cos(angle);
        final y = center.dy + r * math.sin(angle);
        if (i == 0) path.moveTo(x, y); else path.lineTo(x, y);
      }
      canvas.drawPath(path, paint);
    }

    drawSmoothWave(const Color(0xFF26A69A).withValues(alpha: 0.6), 3, 10, 0, 3.0);
    drawSmoothWave(const Color(0xFF80CBC4).withValues(alpha: 0.8), 2, 8, math.pi, 2.0);
    drawSmoothWave(Colors.white.withValues(alpha: 0.5), 4, 6, math.pi / 2, 1.5);
  }
  @override
  bool shouldRepaint(covariant _SmoothAuraPainter oldDelegate) => true;
}