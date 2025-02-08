import 'package:card_battle_game/models/card.dart';
import 'package:card_battle_game/models/card_database.dart';
import 'package:card_battle_game/models/player.dart';

class SummonEffect{
  late SummonEffectType type;
  String? value;

  SummonEffect();

  factory SummonEffect.fromJson(Map<String, dynamic>? json) {
    var effect = SummonEffect();
    if(json == null){
      return effect;
    }
      effect.value = json['value'];
      effect.type = SummonEffectTypeExtension.fromString(json['type']);
      return effect;
  }

  Future<void> apply(MonsterCard triggeringMonster, Player player) async{
    switch(type){
      case SummonEffectType.swarm:
      var swarmCard = await CardDatabase.getCards([value!]);
      for(var i = 0; i < 3; i++){
        if(player.monsters[i] == null){
          var swarmMonster = swarmCard[0].toMonster().clone().toMonster();
          swarmMonster.oneTimeUse = true;
          player.summonMonster(swarmMonster, i, []);
        }
      }
      break;
    }
  }
}

enum SummonEffectType { swarm }

extension SummonEffectTypeExtension on SummonEffectType {
  // Convert a string to an enum value
  static SummonEffectType fromString(String str) {
    return SummonEffectType.values.firstWhere(
      (e) => e.toString().split('.').last == str.toLowerCase(),
      orElse: () => SummonEffectType.swarm, // Default value
    );
  }
}