import 'dart:math';
import 'package:card_battle_game/models/database/card_database.dart';
import 'package:card_battle_game/models/game/game_effect.dart';
import 'package:card_battle_game/models/cards/monster_card.dart';
import 'package:card_battle_game/models/player/player.dart';

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

  Map<String, dynamic> toJson() {
    return {'type': type.toString().split(".").last, 'value': value};
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
      case SummonEffectType.backToHand:
        var amount = int.parse(value!);

        for (int i = 0; i < amount; i++) {
          if (opponent!.monsters.any((a) => a != null)) {
            var possibleTargets =
                opponent.monsters.where((w) => w != null).toList();
            var target =
                possibleTargets[Random().nextInt(possibleTargets.length)];
            if (target == null) {
              continue;
            }
            opponent.monsters[target.monsterZoneIndex!] = null;
            target.faint();
            opponent.hand.add(target);
          }
        }
        break;
    }
  }
}

enum SummonEffectType { swarm, freeze, backToHand }

extension SummonEffectTypeExtension on SummonEffectType {
  // Convert a string to an enum value
  static SummonEffectType fromString(String str) {
    return SummonEffectType.values.firstWhere(
      (e) => e.toString().split('.').last.toLowerCase() == str.toLowerCase(),
      orElse: () => SummonEffectType.swarm, // Default value
    );
  }
}
