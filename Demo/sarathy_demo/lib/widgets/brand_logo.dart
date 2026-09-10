import 'package:flutter/material.dart';

/// Shared Sarathy mark: a route line flowing through a bus-pin monogram.
class SarathyBrand extends StatelessWidget {
  const SarathyBrand({super.key, this.module});
  final String? module;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: const Color(0xffffeee8),
          borderRadius: BorderRadius.circular(16),
        ),
        child: CustomPaint(painter: _LogoPainter()),
      ),
      const SizedBox(width: 12),
      Text(
        'sarathy',
        style: TextStyle(
          fontSize: 27,
          fontWeight: FontWeight.w900,
          letterSpacing: -.8,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      if (module != null)
        Text(
          '  /  $module',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
    ],
  );
}

class _LogoPainter extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final orange = Paint()..color = const Color(0xffff7b45);
    final navy = Paint()..color = const Color(0xff11243e);
    c.drawCircle(Offset(s.width * .5, s.height * .45), 16, navy);
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(s.width * .5, s.height * .45),
          width: 23,
          height: 14,
        ),
        const Radius.circular(4),
      ),
      orange,
    );
    c.drawCircle(Offset(s.width * .38, s.height * .55), 2.5, navy);
    c.drawCircle(Offset(s.width * .62, s.height * .55), 2.5, navy);
    c.drawLine(
      Offset(8, s.height * .77),
      Offset(s.width - 8, s.height * .77),
      orange..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
