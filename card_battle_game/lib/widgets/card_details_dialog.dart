import 'package:card_battle_game/models/card.dart';
import 'package:card_battle_game/models/monster_card.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class CardDetailsDialog extends StatelessWidget {
  final GameCard card;

  const CardDetailsDialog({super.key, required this.card});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(card.name),
      content: SingleChildScrollView( // Prevent overflow in smaller screens
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 150, // Set a fixed height for the image
              child: Image.asset(card.imagePath, fit: BoxFit.contain),
            ),
            SizedBox(height: 8),
            Text(card.fullDescription!),
            SizedBox(height: 8),
            if (card is MonsterCard) ...[
              Row(
                children: [
                  Icon(FontAwesomeIcons.solidHeart, color: Colors.red, size: 14),
                  SizedBox(width: 4),
                  Text('Health: ${(card as MonsterCard).health}'),
                ],
              ),
              Row(
                children: [
                  Icon(FontAwesomeIcons.handFist, color: Colors.orange, size: 14),
                  SizedBox(width: 4),
                  Text('Attack: ${(card as MonsterCard).attack}'),
                ],
              ),
            ],
              Row(
                children: [
                  Icon(FontAwesomeIcons.gem, color: Colors.lightBlue, size: 14),
                  SizedBox(width: 4),
                  Text('Cost: ${card.cost}'),
                ],
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(); // Close the dialog
          },
          child: Text('Close'),
        ),
      ],
    );
  }
}
