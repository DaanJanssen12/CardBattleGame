import 'dart:math';
import 'package:card_battle_game/models/card_database.dart';
import 'package:card_battle_game/models/game_effect.dart';
import 'package:card_battle_game/models/monster_card.dart';
import 'package:card_battle_game/models/player.dart';

class SummonEffect {
  late SummonEffectType type;
  String? value;

  SummonEffect();

  factory SummonEffect.fromJson(Map<String, dynamic>? json) {
    var effect = SummonEffect();
    if (json == null) {
      return effect;
    }
    effect.value = json['value'];
    effect.type = SummonEffectTypeExtension.fromString(json['type']);
    return effect;
  }

  Future<void> apply(
      MonsterCard triggeringMonster, Player player, Player? opponent) async {
    switch (type) {
      case SummonEffectType.swarm:
        var swarmCard = await CardDatabase.getCards([value!]);
        for (var i = 0; i < 3; i++) {
          if (player.monsters[i] == null) {
            var swarmMonster = swarmCard[0].toMonster().clone().toMonster();
            swarmMonster.oneTimeUse = true;
            player.summonMonster(swarmMonster, i, [], null, false);
          }
        }
        break;
      case SummonEffectType.freeze:
        if (opponent!.monsters.any((a) => a != null)) {
          var possibleTargets =
              opponent.monsters.where((w) => w != null).toList();
          var target =
              possibleTargets[Random().nextInt(possibleTargets.length)];
          var amount = int.parse(value!);
          target!.effects.add(GameEffect(GameEffectType.freeze, amount));
        }
        break;
    }
  }
}

enum SummonEffectType { swarm, freeze }

extension SummonEffectTypeExtension on SummonEffectType {
  // Convert a string to an enum value
  static SummonEffectType fromString(String str) {
    return SummonEffectType.values.firstWhere(
      (e) => e.toString().split('.').last == str.toLowerCase(),
      orElse: () => SummonEffectType.swarm, // Default value
    );
  }
}
