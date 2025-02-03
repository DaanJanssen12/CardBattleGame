import 'package:card_battle_game/models/card.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class CardWidget extends StatelessWidget {
  final GameCard card;
  final VoidCallback? onTap;
  final bool isHovered; // Add this to represent whether the widget is hovered

  const CardWidget({super.key, required this.card, this.onTap, this.isHovered = false});

  @override
  Widget build(BuildContext context) {
    double cardWidth = MediaQuery.of(context).size.width * 0.20;
    // BoxShadow logic for hover effect
    BoxShadow boxShadow = BoxShadow(
      color: isHovered ? Colors.blueAccent.withOpacity(0.6) : Colors.black26,
      blurRadius: isHovered ? 12 : 8,
      spreadRadius: isHovered ? 3 : 0,
      offset: Offset(0, 2),
    );

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: cardWidth,
        decoration: BoxDecoration(
          color: Colors.orange[100], // Set the background color to orange
          boxShadow: [boxShadow], // Apply the shadow
        ),
        padding: EdgeInsets.all(8.0),
        margin: EdgeInsets.all(4.0), // Optional: Add margin for spacing
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              card.name,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            // Wrap LayoutBuilder inside a Container with a set maxHeight
            Container(
              constraints: BoxConstraints(
                  maxHeight:
                      100), // Optional: Set maxHeight to avoid overflow
              child: LayoutBuilder(
                builder: (context, constraints) {
                  double imageHeight = constraints.maxHeight * 0.3; // 30% of available space
                  return Image.asset(card.imagePath, height: imageHeight);
                },
              ),
            ),
            SizedBox(height: 8), // Add space between image and stats
            if (card is MonsterCard) ...[
              Row(
                children: [
                  Icon(FontAwesomeIcons.solidHeart, color: Colors.red, size: 14),
                  SizedBox(width: 4),
                  Text('${(card as MonsterCard).health}'),
                ],
              ),
              Row(
                children: [
                  Icon(FontAwesomeIcons.handFist, color: Colors.orange, size: 14),
                  SizedBox(width: 4),
                  Text('${(card as MonsterCard).attack}'),
                ],
              ),
            ]
          ],
        ),
      ),
    );
  }
}
