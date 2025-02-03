import 'package:card_battle_game/widgets/card_widget.dart';
import 'package:flutter/material.dart';
import '../models/card.dart';
import '../models/player.dart';
import 'monster_card_widget.dart';

class PlayerHandWidget extends StatelessWidget {
  final Player player;
  final Function(GameCard) onCardTap;

  const PlayerHandWidget(
      {super.key, required this.player, required this.onCardTap});

  @override
  Widget build(BuildContext context) {
    return Container(
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
                child: CardWidget(card: card), // No translation here
                feedback: Material(
                  color: Colors.transparent,
                  child: Transform.translate(
                    offset: Offset(offset, 0), // Apply the offset to the feedback
                    child: CardWidget(card: card),
                  ),
                ),
                childWhenDragging: Container(), // Empty container while dragging
              ),
            ),
          );
        },
      ),
    );
  }
}
