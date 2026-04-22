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
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      height: 280,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _FloatingBlobPainter(
              animationValue: _controller.value,
            ),
          );
        },
      ),
    );
  }
}

class _FloatingBlobPainter extends CustomPainter {
  final double animationValue;
  _FloatingBlobPainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = size.width / 2.3; 
    final time = animationValue * 2 * math.pi;
    final tealColor = const Color(0xFF4DB6AC);

    // INVERTÁLT FADE: Középen fehér, a kerületnél intenzív teal, utána átlátszó
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withOpacity(0.7), // Fehéredő mag
          tealColor.withOpacity(0.6),    // Legintenzívebb a kerületnél
          Colors.transparent,            // Kifelé elhalványul
        ],
        stops: const [0.0, 0.75, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: baseRadius + 15));
    
    canvas.drawCircle(center, baseRadius + 15, glowPaint);

    void drawFloatingWave(Color color, double freq1, double freq2, double amp1, double amp2, double phase) {
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..isAntiAlias = true;

      final path = Path();
      const points = 120;

      for (int i = 0; i <= points; i++) {
        final angle = (i / points) * 2 * math.pi;
        final offset = math.sin(angle * freq1 + time + phase) * amp1 +
                       math.cos(angle * freq2 - time + phase) * amp2;

        final r = baseRadius + offset;
        final x = center.dx + r * math.cos(angle);
        final y = center.dy + r * math.sin(angle);

        if (i == 0) path.moveTo(x, y);
        else path.lineTo(x, y);
      }
      canvas.drawPath(path, paint);
    }

    drawFloatingWave(tealColor.withOpacity(0.8), 4, 6, 12, 10, 0);
    drawFloatingWave(const Color(0xFF81D4FA).withOpacity(0.7), 5, 3, 15, 12, math.pi / 2);
  }

  @override
  bool shouldRepaint(covariant _FloatingBlobPainter oldDelegate) => true;
}