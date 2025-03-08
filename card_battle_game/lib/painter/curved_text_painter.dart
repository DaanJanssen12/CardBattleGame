import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:math';

class CurvedTextPainter extends CustomPainter {
  final String text;
  final TextStyle textStyle;

  CurvedTextPainter(this.text, this.textStyle);

  @override
  void paint(Canvas canvas, Size size) {
    final double width = size.width;
    final double height = size.height;
    const double curveHeight = -10; // Controls how much the text curves
    const double letterSpacing = 3; // Adjust spacing between letters

    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    List<double> charWidths = [];
    double totalTextWidth = 0;

    // Measure each character width
    for (int i = 0; i < text.length; i++) {
      textPainter.text = TextSpan(text: text[i], style: textStyle);
      textPainter.layout();
      double charWidth = textPainter.width + letterSpacing; // Add extra spacing
      charWidths.add(charWidth);
      totalTextWidth += charWidth;
    }

    // Start position to center text
    double startX = (width / 2) - (totalTextWidth / 2);
    
    // Create the path for curved text
    final path = Path();
    double x = startX;

    for (int i = 0; i < text.length; i++) {
      double y = height / 2 - pow(i - text.length / 2, 2) * (curveHeight / pow(text.length / 2, 2));
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
      x += charWidths[i]; // Move x based on the character width
    }

    final ui.PathMetric metric = path.computeMetrics().first;

    // Draw each letter along the curve
    x = startX;
    for (int i = 0; i < text.length; i++) {
      final char = text[i];
      textPainter.text = TextSpan(text: char, style: textStyle);
      textPainter.layout();

      double letterOffset = (x - startX) / totalTextWidth * metric.length;
      ui.Tangent? tangent = metric.getTangentForOffset(letterOffset);

      if (tangent != null) {
        canvas.save();
        canvas.translate(tangent.position.dx, tangent.position.dy);
        canvas.rotate(-tangent.angle);
        textPainter.paint(canvas, Offset(-textPainter.width / 2, -textPainter.height / 2));
        canvas.restore();
      }
      x += charWidths[i]; // Move x forward by character width
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
