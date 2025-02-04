import 'package:flutter/material.dart';
import 'package:card_battle_game/widgets/monster_zone_widget.dart';
import '../models/player.dart';
import '../models/card.dart';

class GameBoardWidget extends StatelessWidget {
  final Player player;
  final Player enemy;
  final Function(GameCard, int) onCardDrop;
  final Function(GameCard) onCardTap;
  final Function(MonsterCard, Player, int) onMonsterAttack;

  const GameBoardWidget({
    super.key,
    required this.player,
    required this.enemy,
    required this.onCardDrop,
    required this.onCardTap,
    required this.onMonsterAttack,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          // Enemy monster zones
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (index) {
              return Flexible(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2.0),
                  child: DragTarget<GameCard>(
                    onWillAcceptWithDetails: (data) => true, // Accept any draggable card
                    onAcceptWithDetails: (details) {
                      // Call attack method for the enemy monster at the given index
                      if (details.data is GameCard) {
                        // Assuming the card is a MonsterCard
                        onMonsterAttack(details.data as MonsterCard, enemy, index);
                      }
                    },
                    builder: (context, candidateData, rejectedData) {
                      return MonsterZoneWidget(
                        card: enemy.monsters.length > index ? enemy.monsters[index] : null,
                        isHovered: candidateData.isNotEmpty, // Visual feedback for hovering
                        onCardTap: onCardTap,
                      );
                    },
                  ),
                ),
              );
            }),
          ),
          SizedBox(height: 25),
          // Player monster zones
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (index) {
              return Flexible(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2.0),
                  child: DragTarget<GameCard>(
                    onWillAcceptWithDetails: (data) => true, // Accept any draggable card
                    onAcceptWithDetails: (details) {
                      // Place card in player's monster zone if it's a monster card
                      if (details.data is GameCard) {
                        onCardDrop(details.data, index); // Drop logic remains unchanged
                      }
                    },
                    builder: (context, candidateData, rejectedData) {
                      return MonsterZoneWidget(
                        card: player.monsters.length > index ? player.monsters[index] : null,
                        isHovered: candidateData.isNotEmpty,
                        onCardTap: onCardTap,
                      );
                    },
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
