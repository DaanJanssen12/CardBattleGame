import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class OutlinedText {
  static Widget render(String text, double? fontSize, FontWeight? fontWeight) {
    return Stack(
      children: [
        // Outline
        Text(
          text,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: fontWeight,
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2
              ..color = Colors.black, // Border color
          ),
        ),
        // Inner text
        Text(
          text,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: fontWeight,
            color: Colors.white, // Fill color
          ),
        ),
      ],
    );
  }
}
