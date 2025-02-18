import 'package:card_battle_game/models/database/card_database.dart';
import 'package:card_battle_game/models/cards/monster_card.dart';
import 'package:card_battle_game/models/player/player.dart';
import 'package:card_battle_game/models/cards/upgrade_card.dart';
import 'package:card_battle_game/models/enums/upgrade_card_type.dart';

class MascotEffects {
  int startingHealth;
  int startingMana;
  int regainManaPerTurn;
  late MascotAdditionalEffect? additionalEffect;

  MascotEffects(this.startingHealth, this.startingMana, this.regainManaPerTurn);

  factory MascotEffects.fromJson(Map<String, dynamic>? json) {
    var data = MascotEffects(3, 4, 1);
    if (json == null || json.isEmpty) {
      return data;
    }
    data.startingHealth = json['startingHealth'];
    data.startingMana = json['startingMana'];
    data.regainManaPerTurn = json['regainManaPerTurn'];
    data.additionalEffect = json['additionalEffect'] != null
        ? MascotAdditionalEffect.fromJson(json['additionalEffect'])
        : null;
    return data;
  }

  Map<String, dynamic> toJson() {
    return {
      'startingHealth': startingHealth,
      'startingMana': startingMana,
      'regainManaPerTurn': regainManaPerTurn,
      'additionalEffect': additionalEffect?.toJson()
    };
  }

  @override
  String toString() {
    return """
Starting health: $startingHealth
Starting mana: $startingMana
Regain mana per turn: $regainManaPerTurn
""";
  }
}

class MascotAdditionalEffect {
  late String name;
  late String description;
  late MascotAdditionalEffectType type;
  late String value;

  MascotAdditionalEffect();

  factory MascotAdditionalEffect.fromJson(Map<String, dynamic>? json) {
    var data = MascotAdditionalEffect();
    if (json == null || json.isEmpty) {
      return data;
    }
    data.name = json['name'];
    data.description = json['description'];
    data.type = MascotAdditionalEffectTypeExtension.fromString(json['type']);
    data.value = json['value'];
    return data;
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'type': type.toString().split(".").last,
      'value': value
    };
  }

  Future<void> trigger(
      MascotEffectTriggers trigger,
      MonsterCard mascotMonster,
      Player player,
      UpgradeCard? upgrade,
      Player opponent,
      List<String> battleLog,
      MonsterCard? attackingMonster) async {
    switch (trigger) {
      case MascotEffectTriggers.upgradeApplied:
        if (type ==
            MascotAdditionalEffectType.gainManaWhenUpgradeAppliedToSelf) {
          await apply(mascotMonster, player, upgrade, opponent, battleLog,
              attackingMonster);
        } else if (type == MascotAdditionalEffectType.drawWhenHealed &&
            upgrade!.upgradeCardType == UpgradeCardType.heal) {
          await apply(mascotMonster, player, upgrade, opponent, battleLog,
              attackingMonster);
        } else if (type == MascotAdditionalEffectType.copyUpgrade) {
          await apply(mascotMonster, player, upgrade, opponent, battleLog,
              attackingMonster);
        }
        break;
      case MascotEffectTriggers.startOfTurn:
        if (type == MascotAdditionalEffectType.gainAtkStartOfTurnIfAttacked &&
            mascotMonster.hasAttacked) {
          await apply(mascotMonster, player, upgrade, opponent, battleLog,
              attackingMonster);
        } else if (type == MascotAdditionalEffectType.summonAtStartOfTurn) {
          await apply(mascotMonster, player, upgrade, opponent, battleLog,
              attackingMonster);
        }
        break;
      case MascotEffectTriggers.faintOpponentMonster:
        if (type == MascotAdditionalEffectType.summonWhenFaintOpponentMonster) {
          await apply(mascotMonster, player, upgrade, opponent, battleLog,
              attackingMonster);
        }
        break;
      case MascotEffectTriggers.isAttacked:
        if (type == MascotAdditionalEffectType.dealDamageWhenAttacked) {
          await apply(mascotMonster, player, upgrade, opponent, battleLog,
              attackingMonster);
        }
        break;
      case MascotEffectTriggers.mascotFainted:
        if (type == MascotAdditionalEffectType.summonWhenFaint) {
          await apply(mascotMonster, player, upgrade, opponent, battleLog,
              attackingMonster);
        }
        break;
      default:
        break;
    }
  }

  Future<void> apply(
      MonsterCard mascotMonster,
      Player player,
      UpgradeCard? upgrade,
      Player opponent,
      List<String> battleLog,
      MonsterCard? attackingMonster) async {
    switch (type) {
      case MascotAdditionalEffectType.gainManaWhenUpgradeAppliedToSelf:
        var intVal = int.parse(value);
        player.mana += intVal;
        break;
      case MascotAdditionalEffectType.gainAtkStartOfTurnIfAttacked:
        var intVal = int.parse(value);
        mascotMonster.currentAttack += intVal;
        break;
      case MascotAdditionalEffectType.summonAtStartOfTurn:
        if (player.monsters.any((a) => a == null)) {
          var parts = value.split(";");
          var howManyTimes = int.parse(parts[0]);
          var monsterToSummonId = parts[1];
          var monsterToSummon =
              (await CardDatabase.getCards([monsterToSummonId]))[0];
          for (var i = 0; i < howManyTimes; i++) {
            if (!player.monsters.any((a) => a == null)) {
              break;
            }
            var monsterZoneIndex = player.monsters.indexOf(null);
            monsterToSummon.oneTimeUse = true;
            await player.summonMonster(monsterToSummon.toMonster(),
                monsterZoneIndex, battleLog, opponent, false);
          }
        }
        break;
      case MascotAdditionalEffectType.copyUpgrade:
        var parts = value.split(";");
        var howManyTimes = int.parse(parts[0]);
        var toMonster = parts[1];
        if (player.monsters
            .any((a) => a != null && a != mascotMonster && a.id == toMonster)) {
          for (var x = 0; x < howManyTimes; x++) {
            var monsterToApplyTo = player.monsters.firstWhere(
                (a) => a != null && a != mascotMonster && a.id == toMonster);
            if (monsterToApplyTo != null) {
              monsterToApplyTo.apply(upgrade!);
            }
          }
        }
        break;
      case MascotAdditionalEffectType.drawWhenHealed:
        var intVal = int.parse(value);
        for (var i = 0; i < intVal; i++) {
          player.drawCard([]);
        }
        break;
      case MascotAdditionalEffectType.summonWhenFaintOpponentMonster:
        if (player.monsters.any((a) => a == null)) {
          var parts = value.split(";");
          var howManyTimes = int.parse(parts[0]);
          var monsterToSummonId = parts[1];
          var monsterToSummon =
              (await CardDatabase.getCards([monsterToSummonId]))[0];
          for (var i = 0; i < howManyTimes; i++) {
            if (!player.monsters.any((a) => a == null)) {
              break;
            }
            var monsterZoneIndex = player.monsters.indexOf(null);
            monsterToSummon.oneTimeUse = true;
            await player.summonMonster(monsterToSummon.toMonster(),
                monsterZoneIndex, battleLog, opponent, false);
          }
        }
        break;
      case MascotAdditionalEffectType.dealDamageWhenAttacked:
        var intVal = int.parse(value);
        var faint = attackingMonster!.takeDamage(intVal);
        if (faint) {
          opponent.faintMonster(
              attackingMonster!.monsterZoneIndex!, battleLog, player);
        }
        break;
      case MascotAdditionalEffectType.summonWhenFaint:
        if (player.monsters.any((a) => a == null)) {
          var parts = value.split(";");
          var howManyTimes = int.parse(parts[0]);
          var monsterToSummonId = parts[1];
          var monsterToSummon =
              (await CardDatabase.getCards([monsterToSummonId]))[0];
          for (var i = 0; i < howManyTimes; i++) {
            if (!player.monsters.any((a) => a == null)) {
              break;
            }
            var monsterZoneIndex = player.monsters.indexOf(null);
            monsterToSummon.oneTimeUse = true;
            await player.summonMonster(monsterToSummon.toMonster(),
                monsterZoneIndex, battleLog, opponent, false);
          }
        }
        break;
    }
  }
}

enum MascotEffectTriggers {
  upgradeApplied,
  startOfTurn,
  faintOpponentMonster,
  isAttacked,
  mascotFainted
}

enum MascotAdditionalEffectType {
  gainManaWhenUpgradeAppliedToSelf,
  gainAtkStartOfTurnIfAttacked,
  summonAtStartOfTurn,
  copyUpgrade,
  drawWhenHealed,
  summonWhenFaintOpponentMonster,
  dealDamageWhenAttacked,
  summonWhenFaint
}

extension MascotAdditionalEffectTypeExtension on MascotAdditionalEffectType {
  // Convert a string to an enum value
  static MascotAdditionalEffectType fromString(String str) {
    return MascotAdditionalEffectType.values.firstWhere(
      (e) => e.toString().split('.').last.toLowerCase() == str.toLowerCase(),
      orElse: () => MascotAdditionalEffectType
          .gainManaWhenUpgradeAppliedToSelf, // Default value
    );
  }
}
