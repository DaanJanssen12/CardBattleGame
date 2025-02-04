import 'package:flutter/material.dart';

class ArrowWidget extends StatelessWidget {
  final Offset start;
  final Offset end;

  const ArrowWidget({Key? key, required this.start, required this.end})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: ArrowPainter(start: start, end: end),
      willChange: true
    );
  }
}

class ArrowPainter extends CustomPainter {
  final Offset start;
  final Offset end;

  ArrowPainter({required this.start, required this.end});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    // Draw the line from start to end
    canvas.drawLine(start, end, paint);

    // Calculate the angle of the arrowhead
    final double angle = (end - start).direction;

    // Length and width of the arrowhead
    final arrowHeadLength = 10.0;
    final arrowHeadWidth = 5.0;

    // Create two points for the arrowhead
    final arrowPoint1 = end - Offset.fromDirection(angle - 0.5, arrowHeadLength);
    final arrowPoint2 = end - Offset.fromDirection(angle + 0.5, arrowHeadLength);

    // Draw the arrowhead as two lines
    canvas.drawLine(end, arrowPoint1, paint);
    canvas.drawLine(end, arrowPoint2, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
