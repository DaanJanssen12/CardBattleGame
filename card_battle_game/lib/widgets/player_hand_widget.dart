import 'package:card_battle_game/models/constants.dart';
import 'package:card_battle_game/services/helper_functions.dart';
import 'package:flutter/material.dart';
import '../models/cards/card.dart';
import '../models/player/player.dart';
import 'card_widget.dart';

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
        itemCount: player.hand.length + 1,
        itemBuilder: (context, index) {
          GameCard card;
          if (index == player.hand.length) {
            card = Functions.getConstantDrawCard();
          } else {
            card = player.hand[index];
          }

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 0),
            child: Align(
              alignment: Alignment.center, // Keeps cards at the bottom
              child: GestureDetector(
                onTap: () => onCardTap(card),
                child: SizedBox(
                  width: 100,
                  height: 160, // Ensures the card stays at 160 height
                  child: LongPressDraggable<GameCard>(
                    data: card,
                    delay: Duration(
                        milliseconds:
                            Constants.longPressDraggableDelayInMilliseconds),
                    feedback: Material(
                      color: Colors.transparent,
                      child: SizedBox(
                        width: 100,
                        height: 160,
                        child: CardWidget(card: card),
                      ),
                    ),
                    childWhenDragging: Container(),
                    child: CardWidget(card: card),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
