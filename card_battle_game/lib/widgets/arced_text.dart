import 'package:flutter/material.dart';
import 'dart:math';

class ArcedText extends StatelessWidget {
  final String text;
  final TextStyle textStyle;
  final double width;
  double arcHeight; // Controls the curve intensity

  ArcedText({
    Key? key,
    required this.text,
    required this.textStyle,
    required this.width,
    this.arcHeight = -5, // Adjust arc curvature
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    this.arcHeight = text.length * -1;
    return SizedBox(
      width: width,
      height: 100, // Adjust height based on font size
      child: Stack(
        alignment: Alignment.center,
        children: List.generate(text.length, (i) {
          double xOffset = (i - text.length / 2) * textStyle.fontSize! * 0.8;
          double yOffset = -pow(i - text.length / 2, 2) * (arcHeight / pow(text.length / 2, 2));
          double angle = (i - text.length / 2) * (pi / text.length) * 0.15; // Adjust rotation angle
          if(text.length < 5){
            yOffset = 0;
            angle = 0;
          }
          return Transform.translate(
            offset: Offset(xOffset, yOffset),
            child: Transform.rotate(
              angle: angle, // Rotate the letter to follow the curve
              child: Text(text[i], style: textStyle),
            ),
          );
        }),
      ),
    );
  }
}
