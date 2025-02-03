import 'package:card_battle_game/models/player.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class PlayerInfoWidget extends StatelessWidget {
  final Player player;

  const PlayerInfoWidget({super.key, required this.player});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[100],
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
          Text(player.name,
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[800])),
          _buildStatBar(
              'Health', player.health, Colors.red, FontAwesomeIcons.heart),
          _buildStatBar('Mana', player.mana, Colors.blue, FontAwesomeIcons.gem),
          Expanded(
              child:
                  Container()), // Prevent overflow by expanding the column's space usage
        ],
      ),
    );
  }

  Widget _buildStatBar(String statName, int value, Color color, IconData icon) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment
              .spaceBetween, // This ensures space between the left and right widgets
          children: [
            Text(statName, style: TextStyle(fontSize: 14)),
            Row(
              mainAxisSize: MainAxisSize
                  .min, // Prevent the Row from expanding unnecessarily
              children: [
                Text(value.toString(),
                    style: TextStyle(fontSize: 14), textAlign: TextAlign.right),
                SizedBox(
                    width: 8), // Optional: Add space between value and icon
                Icon(icon, size: 14),
              ],
            ),
          ],
        )
      ],
    );
  }
}
