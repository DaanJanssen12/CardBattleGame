import 'package:card_battle_game/models/game_effect.dart';
import 'package:card_battle_game/models/monster_card.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../models/card.dart';

class MonsterCardWidget extends StatelessWidget {
  final MonsterCard? monster;

  const MonsterCardWidget({super.key, required this.monster});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade200, Colors.blue.shade100],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          const BoxShadow(
            color: Colors.black45,
            offset: Offset(4, 4),
            blurRadius: 6,
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildNameHeader(),
              _buildImage(constraints),
              _buildStatsSection(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildNameHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: Colors.deepPurple,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        monster?.name ?? 'Unknown',
        textAlign: TextAlign.center,
        softWrap: false,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
            fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
      ),
    );
  }

  Widget _buildImage(BoxConstraints constraints) {
    return Stack(
      alignment:
          Alignment.bottomLeft, // Positioning the badge to the bottom-left
      children: [
        SizedBox(
          height: constraints.maxHeight * 0.4,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              monster?.imagePath ?? 'assets/images/placeholder.png',
              width: 200,
              height: 100,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(
                  Icons.image_not_supported,
                  size: 50,
                  color: Colors.grey,
                );
              },
            ),
          ),
        ),
        if (monster!.effects.isNotEmpty) ...[
          for (var effect in monster!.effects) ...[
            _buildEffectBadge(effect.type, effect.value)
          ]
        ] // Cost badge now overlaying slightly on the image
      ],
    );
  }

  Widget _buildEffectBadge(GameEffectType effectType, int value) {
    IconData? icon;
    switch (effectType) {
      case GameEffectType.shield:
        icon = FontAwesomeIcons.shield;
        break;
      case GameEffectType.freeze:
        icon = FontAwesomeIcons.snowflake;
        break;
    }
    return Positioned(
      left: 0, // Adjusted to be closer to the bottom-left corner
      bottom: 0, // Added a slight left offset for more overlap
      child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.deepPurple,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.lightBlue, size: 14),
              const SizedBox(width: 4), // Space between icon and number
              Text('$value',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  )),
            ],
          )),
    );
  }

  Widget _buildStatsSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.deepPurple.shade700,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildStatRow(FontAwesomeIcons.solidHeart, 'Health',
              monster?.currentHealth ?? 0, Colors.redAccent),
          _buildStatRow(FontAwesomeIcons.handFist, 'Attack',
              monster?.currentAttack ?? 0, Colors.orangeAccent),
        ],
      ),
    );
  }

  Widget _buildStatRow(IconData icon, String label, int value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 10),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              '$label: $value',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
              overflow: TextOverflow.ellipsis,
              softWrap: false,
            ),
          ),
        ],
      ),
    );
  }
}
