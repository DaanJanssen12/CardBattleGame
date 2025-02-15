import 'package:card_battle_game/models/monster_card.dart';
import 'package:flutter/material.dart';
import 'package:card_battle_game/widgets/monster_zone_widget.dart';
import '../models/player.dart';
import '../models/card.dart';

class GameBoardWidget extends StatefulWidget {
  final Player player;
  final Player enemy;
  final bool isPlayersTurn;
  final Function(GameCard, int) onCardDrop;
  final Function(GameCard) onCardTap;
  final Function(MonsterCard, int) onMonsterAttack;

  const GameBoardWidget({
    super.key,
    required this.player,
    required this.enemy,
    required this.isPlayersTurn,
    required this.onCardDrop,
    required this.onCardTap,
    required this.onMonsterAttack,
  });

  @override
  _GameBoardWidgetState createState() => _GameBoardWidgetState();
}

class _GameBoardWidgetState extends State<GameBoardWidget> {
  MonsterCard? draggingMonster;

  // Handle drag start for summoning or attacking
  void startDrag(MonsterCard card) {
    setState(() {
      draggingMonster = card;
    });
  }

  // Handle drag end for attacking an enemy monster
  void endDrag(int index) {
    if (draggingMonster != null) {
      widget.onMonsterAttack(draggingMonster!, index);
    }
    setState(() {
      draggingMonster = null; // Reset dragging monster after attack
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Center(
          child: Column(
            children: [
              // Enemy Monster Zones (Drag Target for attacking)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (index) {
                  return Expanded(
                    child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2.0),
                        child: SizedBox(
                          height: MediaQuery.of(context).size.height * 0.20,
                          child: DragTarget<MonsterCard>(
                            onWillAcceptWithDetails: (details) {
                              return widget.isPlayersTurn && widget.enemy.monsters[index] != null &&
                                  draggingMonster != null &&
                                  draggingMonster!.canAttack();
                            },
                            onAcceptWithDetails: (details) {
                              endDrag(index); // Trigger the attack when dropped
                            },
                            builder: (context, candidateData, rejectedData) {
                              return MonsterZoneWidget(
                                card: widget.enemy.monsters.length > index
                                    ? widget.enemy.monsters[index]
                                    : null,
                                isHovered: candidateData.isNotEmpty,
                                onCardTap: widget.onCardTap,
                              );
                            },
                          ),
                        )),
                  );
                }),
              ),
              const SizedBox(height: 25),
              // Player Monster Zones (Draggable for summoning and attacking)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (index) {
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2.0),
                      child: SizedBox(
                          height: MediaQuery.of(context).size.height * 0.20,
                          child: DragTarget<GameCard>(
                            onWillAcceptWithDetails: (details) => widget.isPlayersTurn && details.data
                                .canBePlayed(), // Accept any draggable card
                            onAcceptWithDetails: (details) {
                              // Place card in player's monster zone if it's a monster card
                              widget.onCardDrop(details.data,
                                  index); // Drop logic remains unchanged
                            },
                            builder: (context, candidateData, rejectedData) {
                              return Draggable<MonsterCard>(
                                data: widget.player.monsters.length > index
                                    ? widget.player.monsters[index]
                                    : null,
                                onDragStarted: () {
                                  if (widget.player.monsters.length > index &&
                                      widget.player.monsters[index] != null &&
                                      widget.player.monsters[index]!
                                              .hasAttacked ==
                                          false) {
                                    startDrag(widget.player.monsters[index]!);
                                  }
                                },
                                onDraggableCanceled: (_, __) {
                                  setState(() {
                                    draggingMonster = null; // Reset on cancel
                                  });
                                },
                                childWhenDragging:
                                    Container(), // Show nothing when dragging
                                feedback: Material(
                                  color: Colors.transparent,
                                  child: MonsterZoneWidget(
                                    card: widget.player.monsters.length > index
                                        ? widget.player.monsters[index]
                                        : null,
                                    isHovered: candidateData
                                        .isNotEmpty, // No hover during drag
                                    onCardTap: widget.onCardTap,
                                  ),
                                ),
                                child: MonsterZoneWidget(
                                  card: widget.player.monsters.length > index
                                      ? widget.player.monsters[index]
                                      : null,
                                  isHovered: candidateData.isNotEmpty,
                                  onCardTap: widget.onCardTap,
                                ),
                              );
                            },
                          )),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
