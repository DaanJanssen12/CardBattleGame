import 'package:flutter/material.dart';
import '../models/card.dart';
import '../models/player.dart';
import 'card_widget.dart';
import 'monster_card_widget.dart';

class PlayerHandWidget extends StatelessWidget {
  final Player player;
  final Function(GameCard) onCardTap;

  const PlayerHandWidget(
      {super.key, required this.player, required this.onCardTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: player.hand.length,
        itemBuilder: (context, index) {
          var card = player.hand[index];

          // Offset the card slightly based on the index to create the overlap effect
          double offset = index * -30.0; // Adjust the value for more/less overlap

          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: GestureDetector(
              onTap: () => onCardTap(card),
              child: Draggable<GameCard>(
                data: card,
                feedback: Material(
                  color: Colors.transparent,
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: 100, // Define max width for feedback
                      maxHeight: 150, // Define max height for feedback
                    ),
                    child: Transform.translate(
                      offset: Offset(offset, 0), // Apply the offset to the feedback
                      child: CardWidget(card: card),
                    ),
                  ),
                ),
                childWhenDragging: Container(),
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: 100, // Define max width for static card
                    maxHeight: 150, // Define max height for static card
                  ),
                  child: CardWidget(card: card),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
