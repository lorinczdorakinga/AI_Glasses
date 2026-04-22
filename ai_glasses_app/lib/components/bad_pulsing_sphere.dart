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
    // LELASSÍTVA: 1 másodperc helyett 3 másodperces ciklus. 
    // Így fenyegetőbb, lassan fortyogó hatást kelt.
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 6000),
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
      width: 250,
      height: 250,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _MeltingVolatilePainter(
              animationValue: _controller.value,
            ),
          );
        },
      ),
    );
  }
}

class _MeltingVolatilePainter extends CustomPainter {
  final double animationValue;
  _MeltingVolatilePainter({required this.animationValue});

  double _triangleWave(double t) => math.asin(math.sin(t)) / (math.pi / 2);

  @override
  void paint(Canvas canvas, Size size) {
    final baseRadius = size.width / 2.6;
    final time = animationValue * 2 * math.pi;

    // A középpont rángatózása (a lassabb tempó miatt ez is lomhább lesz)
    final twitchX = math.sin(time * 17) * 5;
    final twitchY = math.cos(time * 19) * 5;
    final center = Offset(size.width / 2 + twitchX, size.height / 2 + twitchY);

    final burgundyColor = const Color(0xFF800020);

    // INVERTÁLT FADE: Fehér mag, intenzív burgundi perem, majd kifelé elhalványul
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withOpacity(0.65),
          burgundyColor.withOpacity(0.85),
          Colors.transparent,
        ],
        stops: const [0.0, 0.75, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: baseRadius + 15));
    
    canvas.drawCircle(center, baseRadius + 15, glowPaint);

    void drawMeltingWave(Color color, double spikes, double speed, double amp, double phase, double strokeWidth, bool isJagged) {
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..isAntiAlias = true;

      final path = Path();
      const points = 160;

      for (int i = 0; i <= points; i++) {
        final angle = (i / points) * 2 * math.pi;
        
        final asymmetry = math.sin(angle * 1.2 + time * 4) * 20 + 
                          math.cos(angle * 2.2 - time * 5) * 15;
        
        double waveEffect = 0;
        if (isJagged) {
          final dynamicFreq = spikes + math.sin(angle * 2 + time * 4) * 3;
          waveEffect = _triangleWave(angle * dynamicFreq - time * speed + phase) * amp;
        }

        final jitter = math.sin(angle * 50 + time * 40) * 4;
        final r = baseRadius + asymmetry + waveEffect + jitter;
        
        final x = center.dx + r * math.cos(angle);
        final y = center.dy + r * math.sin(angle);

        if (i == 0) path.moveTo(x, y);
        else path.lineTo(x, y);
      }
      canvas.drawPath(path, paint);
    }

    // Fekete "széteső" alapvonal
    drawMeltingWave(Colors.black.withOpacity(0.8), 5, 2, 8, 0, 4.0, true);

    // Sötét burgundi réteg
    drawMeltingWave(burgundyColor.withOpacity(0.9), 13, 10, 25, math.pi / 4, 2.5, true);

    // Nagyon sötét, szinte feketébe hajló vörös/barna réteg
    drawMeltingWave(const Color(0xFF3B0B0B).withOpacity(0.8), 18, -12, 15, math.pi, 2.0, true);
  }

  @override
  bool shouldRepaint(covariant _MeltingVolatilePainter oldDelegate) => true;
}