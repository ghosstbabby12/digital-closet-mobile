import 'package:flutter/material.dart';

/// Espejo de cuerpo entero con pie, para la pestaña Probador (Material no trae
/// uno). Relleno cuando la pestaña está seleccionada, como los demás íconos.
class MirrorIcon extends StatelessWidget {
  final double size;
  final Color color;
  final bool filled;

  const MirrorIcon({super.key, this.size = 24, required this.color, this.filled = false});

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _MirrorPainter(color: color, filled: filled),
      ),
    );
  }
}

class _MirrorPainter extends CustomPainter {
  final Color color;
  final bool filled;

  _MirrorPainter({required this.color, required this.filled});

  @override
  void paint(Canvas canvas, Size size) {
    final unit = size.width / 24;
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2 * unit
      ..strokeCap = StrokeCap.round;

    // Marco ovalado y alto.
    final frame = Rect.fromLTWH(6.5 * unit, 2 * unit, 11 * unit, 16 * unit);
    if (filled) {
      canvas.drawOval(frame, Paint()..color = color);
    } else {
      canvas.drawOval(frame, stroke);
      // Reflejo en diagonal.
      canvas.drawLine(Offset(9.5 * unit, 9 * unit), Offset(12 * unit, 6 * unit), stroke);
    }
    // Pie con dos patas.
    canvas.drawLine(Offset(12 * unit, 18 * unit), Offset(8 * unit, 22 * unit), stroke);
    canvas.drawLine(Offset(12 * unit, 18 * unit), Offset(16 * unit, 22 * unit), stroke);
  }

  @override
  bool shouldRepaint(_MirrorPainter oldDelegate) => oldDelegate.color != color || oldDelegate.filled != filled;
}
