import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Decorative 3D-style sensor visual. It is presentation-only: no data or
/// repository code is involved, so it is safe to use on every platform.
class SensorOrbit extends StatefulWidget {
  const SensorOrbit({super.key});

  @override
  State<SensorOrbit> createState() => _SensorOrbitState();
}

class _SensorOrbitState extends State<SensorOrbit>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 9),
  )..repeat();

  Offset _pointer = Offset.zero;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return MouseRegion(
      onHover: (event) => setState(() => _pointer = event.localPosition),
      onExit: (_) => setState(() => _pointer = Offset.zero),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final spin = _controller.value * math.pi * 2;
          final tiltX =
              _pointer == Offset.zero ? 0.0 : (_pointer.dy - 70) / 850;
          final tiltY =
              _pointer == Offset.zero ? 0.0 : (_pointer.dx - 150) / -1100;
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0012)
              ..rotateX(tiltX)
              ..rotateY(tiltY),
            child: Container(
              height: 150,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    scheme.primary,
                    AppColors.seed.withValues(alpha: .76)
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: scheme.primary.withValues(alpha: .22),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                      child: CustomPaint(painter: _OrbitPainter(spin: spin))),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('SENSOR AKTIF',
                                  style: TextStyle(
                                      color: scheme.onPrimary
                                          .withValues(alpha: .72),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.5)),
                              const SizedBox(height: 8),
                              Text('Lihat dunia\ndengan data.',
                                  style: TextStyle(
                                      color: scheme.onPrimary,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      height: 1.1)),
                              const SizedBox(height: 8),
                              Text('GPS • FOTO • SENSOR',
                                  style: TextStyle(
                                      color: scheme.onPrimary
                                          .withValues(alpha: .78),
                                      fontSize: 9,
                                      letterSpacing: 1.1)),
                            ],
                          ),
                        ),
                        SizedBox(
                            width: 150,
                            height: 150,
                            child: CustomPaint(
                                painter: _CorePainter(
                                    spin: spin, color: scheme.onPrimary))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _OrbitPainter extends CustomPainter {
  const _OrbitPainter({required this.spin});
  final double spin;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.white.withValues(alpha: .12);
    for (var i = 0; i < 5; i++) {
      final radius = 35.0 + (i * 38);
      canvas.drawCircle(
          Offset(size.width * .78, size.height * .48), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _OrbitPainter oldDelegate) =>
      oldDelegate.spin != spin;
}

class _CorePainter extends CustomPainter {
  const _CorePainter({required this.spin, required this.color});
  final double spin;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final glow = Paint()..color = color.withValues(alpha: .12);
    canvas.drawCircle(center, 54, glow);
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = color.withValues(alpha: .7);
    canvas.drawOval(
        Rect.fromCenter(center: center, width: 92, height: 34), ring);
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(spin);
    canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: 92, height: 34), ring);
    canvas.drawCircle(
        Offset.zero,
        22,
        Paint()
          ..shader =
              RadialGradient(colors: [color, color.withValues(alpha: .15)])
                  .createShader(const Rect.fromLTWH(-22, -22, 44, 44)));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _CorePainter oldDelegate) =>
      oldDelegate.spin != spin || oldDelegate.color != color;
}
