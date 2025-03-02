import 'package:card_battle_game/models/cards/monster_card.dart';
import 'package:card_battle_game/models/player/player.dart';

class MonsterEffect {
  MonsterEffectTrigger trigger = MonsterEffectTrigger.passive;
  MonsterEffectType type = MonsterEffectType.boostOthers;
  String monsterId = "";
  int atk = 0;
  int hp = 0;

  MonsterEffect();

  factory MonsterEffect.fromJson(Map<String, dynamic>? json) {
    var effect = MonsterEffect();
    if (json == null) {
      return effect;
    }
    var parts = (json['value'] as String).split(";");
    effect.type = MonsterEffectTypeExtension.fromString(parts[0]);
    switch (effect.type) {
      case MonsterEffectType.boostOthers:
        effect.monsterId = parts[1];
        effect.atk = num.parse(parts[2]).toInt();
        effect.hp = num.parse(parts[3]).toInt();
        break;
    }
    return effect;
  }

  Map<String, dynamic> toJson() {
    return {'value': getValueJsonStr(), 'trigger': trigger.name};
  }

  String getValueJsonStr() {
    switch (type) {
      case MonsterEffectType.boostOthers:
        return '${type.name};$atk;$hp';
    }
  }

  void onSummon(Player player, MonsterCard monster, Player? opponent) {
    //Boost the monsters that match
    if (type == MonsterEffectType.boostOthers) {
      if (player.monsters.any((a) => a != null && a.id == monsterId)) {
        var monstersToBoost = player.monsters
            .where((w) => w != null && w.id == monsterId)
            .toList();
        for (var monsterToBoost in monstersToBoost) {
          monsterToBoost!.currentAttack += atk;
          monsterToBoost.currentHealth += hp;
        }
      }
    }
  }

  void onSummonOther(Player player, MonsterCard monster, Player? opponent) {
    //If the summoned monster matches then boost them
    if (type == MonsterEffectType.boostOthers) {
      if (monster.id != monsterId) {
        return;
      }

      monster.currentAttack += atk;
      monster.currentHealth += hp;
      return;
    }
  }

  void onFaint(Player player, MonsterCard monster, Player? opponent) {
    //Remove the boosts
    if (type == MonsterEffectType.boostOthers) {
      if (player.monsters.any((a) => a != null && a.id == monsterId)) {
        var monstersToBoost = player.monsters
            .where((w) => w != null && w.id == monsterId)
            .toList();
        for (var monsterToBoost in monstersToBoost) {
          monsterToBoost!.currentAttack -= atk;
          monsterToBoost.currentHealth -= hp;

          if(monsterToBoost.currentHealth <= 0){
            player.faintMonster(monsterToBoost.monsterZoneIndex!, [], opponent);
          }
        }
      }
    }
  }
}

enum MonsterEffectType { boostOthers }

enum MonsterEffectTrigger { passive }

extension MonsterEffectTypeExtension on MonsterEffectType {
  // Convert a string to an enum value
  static MonsterEffectType fromString(String str) {
    return MonsterEffectType.values.firstWhere(
      (e) => e.toString().split('.').last.toLowerCase() == str.toLowerCase(),
      orElse: () => MonsterEffectType.boostOthers, // Default value
    );
  }
}

extension MonsterEffectTriggerExtension on MonsterEffectTrigger {
  // Convert a string to an enum value
  static MonsterEffectTrigger fromString(String str) {
    return MonsterEffectTrigger.values.firstWhere(
      (e) => e.toString().split('.').last.toLowerCase() == str.toLowerCase(),
      orElse: () => MonsterEffectTrigger.passive, // Default value
    );
  }
}
