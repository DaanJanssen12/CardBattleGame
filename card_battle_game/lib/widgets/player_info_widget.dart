import 'package:card_battle_game/models/card.dart';
import 'package:card_battle_game/models/player.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class PlayerInfoWidget extends StatefulWidget {
  final Player player;
  final bool isActive;
  final Function(Player, MonsterCard)? handleAttackPlayerDirectly;

  const PlayerInfoWidget({
    super.key,
    required this.player,
    required this.isActive,
    required this.handleAttackPlayerDirectly,
  });

  @override
  _PlayerInfoWidgetState createState() => _PlayerInfoWidgetState();
}

class _PlayerInfoWidgetState extends State<PlayerInfoWidget> {
  bool isHovered = false; // To track hover state
  bool canAcceptAttack = false; // To track if the MonsterCard can attack

  @override
  Widget build(BuildContext context) {
    return DragTarget<MonsterCard>(
      onWillAcceptWithDetails: (details) {
        bool canAttack = details.data.canAttack();
        setState(() {
          canAcceptAttack = canAttack &&
              (widget.player.monsters.isEmpty ||
                  widget.player.monsters.every((e) => e == null));
          isHovered = canAcceptAttack; // Only hover when conditions are met
        });
        return canAttack &&
            (widget.player.monsters.isEmpty ||
                widget.player.monsters.every((e) => e == null));
      },
      onLeave: (data) => {
        setState(() {
          isHovered = false;
        })
      },
      onAcceptWithDetails: (details) {
        if (widget.handleAttackPlayerDirectly != null &&
            (widget.player.monsters.isEmpty ||
                widget.player.monsters.every((e) => e == null))) {
          widget.handleAttackPlayerDirectly!(widget.player, details.data);
          setState(() {
            isHovered = false;
          });
        }
      },
      builder: (context, candidateData, rejectedData) {
        return AnimatedScale(
          duration: Duration(milliseconds: 300),
          scale:
              isHovered ? 1.05 : 1.0, // Pulsing effect (scale slightly larger)
          child: Container(
            width: 200,
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: widget.isActive ? Colors.blue[200] : Colors.blue[100],
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: Offset(2, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Player's name with turn indicator circle
                Row(
                  children: [
                    // Turn indicator circle
                    Container(
                      width: 12,
                      height: 12,
                      margin: EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: widget.isActive ? Colors.green : Colors.grey,
                      ),
                    ),
                    Text(
                      widget.isActive
                          ? '${widget.player.name} (Turn)'
                          : widget.player.name,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[800],
                      ),
                    ),
                  ],
                ),
                _buildStatBar('Health', widget.player.health, Colors.red,
                    FontAwesomeIcons.heart),
                _buildStatBar('Mana', widget.player.mana, Colors.blue,
                    FontAwesomeIcons.gem),
                Expanded(
                  child: Container(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatBar(String statName, int value, Color color, IconData icon) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(statName, style: TextStyle(fontSize: 14)),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(value.toString(),
                    style: TextStyle(fontSize: 14), textAlign: TextAlign.right),
                SizedBox(width: 8),
                Icon(icon, size: 14),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
