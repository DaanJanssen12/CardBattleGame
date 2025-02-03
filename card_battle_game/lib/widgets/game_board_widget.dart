import 'package:flutter/material.dart';
import 'package:card_battle_game/widgets/monster_zone_widget.dart';
import '../models/player.dart';
import '../models/card.dart';

class GameBoardWidget extends StatelessWidget {
  final Player player;
  final Player enemy;
  final Function(GameCard, int) onCardDrop;
  final Function(GameCard) onCardTap;

  const GameBoardWidget({
    super.key,
    required this.player,
    required this.enemy,
    required this.onCardDrop,
    required this.onCardTap
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
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: MonsterZoneWidget(
                    card: enemy.monsters.length > index
                        ? enemy.monsters[index]
                        : null,
                    isHovered: false,
                    onCardTap: onCardTap
                  ),
                ),
              );
            }),
          ),
          SizedBox(height: 16),

          // Player monster zones
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (index) {
              return Flexible(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: DragTarget<GameCard>(
                    onWillAcceptWithDetails: (data) => true,
                    onAcceptWithDetails: (details) {
                      onCardDrop(details.data, index);
                    },
                    builder: (context, candidateData, rejectedData) {
                      return MonsterZoneWidget(
                        card: player.monsters.length > index
                            ? player.monsters[index]
                            : null,
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
