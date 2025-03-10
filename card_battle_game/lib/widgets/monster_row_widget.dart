import 'package:card_battle_game/models/cards/monster_card.dart';
import 'package:flutter/material.dart';
import '../models/cards/card.dart';
import 'monster_card_widget.dart';

class MonsterRowWidget extends StatelessWidget {
  final List<GameCard> monsters;

  const MonsterRowWidget({super.key, required this.monsters});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: monsters
          .whereType<MonsterCard>() // Ensures only MonsterCards are displayed
          .map((monster) => MonsterCardWidget(monster: monster))
          .toList(),
    );
  }
}
