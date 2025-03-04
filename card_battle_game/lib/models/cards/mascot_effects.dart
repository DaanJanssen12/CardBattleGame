import 'package:card_battle_game/models/database/card_database.dart';
import 'package:card_battle_game/models/cards/monster_card.dart';
import 'package:card_battle_game/models/player/player.dart';
import 'package:card_battle_game/models/cards/upgrade_card.dart';
import 'package:card_battle_game/models/enums/upgrade_card_type.dart';

class TriggerEffectResult {
  bool isTriggered = false;
  String effect = "";
}

class MascotEffects {
  int startingHealth;
  int startingMana;
  int startingGold;
  late MascotAdditionalEffect? additionalEffect;

  MascotEffects(this.startingHealth, this.startingMana, this.startingGold);

  factory MascotEffects.fromJson(Map<String, dynamic>? json) {
    var data = MascotEffects(3, 4, 1);
    if (json == null || json.isEmpty) {
      return data;
    }
    data.startingHealth = json['startingHealth'];
    data.startingMana = json['startingMana'];
    data.startingGold = json['startingGold'] ?? 0;
    data.additionalEffect = json['additionalEffect'] != null
        ? MascotAdditionalEffect.fromJson(json['additionalEffect'])
        : null;
    return data;
  }

  Map<String, dynamic> toJson() {
    return {
      'startingHealth': startingHealth,
      'startingMana': startingMana,
      'startingGold': startingGold,
      'additionalEffect': additionalEffect?.toJson()
    };
  }

  @override
  String toString() {
    return """
Starting health: $startingHealth
Starting mana: $startingMana
Starting gold: $startingGold
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

  Future<TriggerEffectResult> trigger(
      MascotEffectTriggers trigger,
      MonsterCard mascotMonster,
      Player player,
      UpgradeCard? upgrade,
      Player opponent,
      List<String> battleLog,
      MonsterCard? attackingMonster,
      bool isGameInOvertime) async {
    bool doTrigger = false;
    switch (trigger) {
      case MascotEffectTriggers.upgradeApplied:
        doTrigger = type ==
                MascotAdditionalEffectType.gainManaWhenUpgradeAppliedToSelf ||
            (type == MascotAdditionalEffectType.drawWhenHealed &&
                upgrade!.upgradeCardType == UpgradeCardType.heal) ||
            type == MascotAdditionalEffectType.copyUpgrade;
        break;
      case MascotEffectTriggers.startOfTurn:
        doTrigger = type == MascotAdditionalEffectType.summonAtStartOfTurn ||
            type == MascotAdditionalEffectType.addCardStartOfTurn ||
            (type == MascotAdditionalEffectType.gainAtkStartOfTurnIfAttacked &&
                mascotMonster.hasAttackedCounter > 0);
        break;
      case MascotEffectTriggers.faintOpponentMonster:
        doTrigger =
            type == MascotAdditionalEffectType.summonWhenFaintOpponentMonster;
        break;
      case MascotEffectTriggers.isAttacked:
        doTrigger = type == MascotAdditionalEffectType.dealDamageWhenAttacked ||
            type == MascotAdditionalEffectType.negateDamage ||
            type == MascotAdditionalEffectType.canNotBeAttacked;
        break;
      case MascotEffectTriggers.mascotFainted:
        doTrigger = type == MascotAdditionalEffectType.summonWhenFaint;
        break;
      default:
        doTrigger = false;
        break;
    }

    if (doTrigger) {
      return await apply(mascotMonster, player, upgrade, opponent, battleLog,
          attackingMonster, isGameInOvertime);
    } else {
      return TriggerEffectResult();
    }
  }

  Future<TriggerEffectResult> apply(
      MonsterCard mascotMonster,
      Player player,
      UpgradeCard? upgrade,
      Player opponent,
      List<String> battleLog,
      MonsterCard? attackingMonster,
      bool isGameInOvertime) async {
    var result = TriggerEffectResult();
    switch (type) {
      case MascotAdditionalEffectType.gainManaWhenUpgradeAppliedToSelf:
        var intVal = int.parse(value);
        player.mana += intVal;
        break;
      case MascotAdditionalEffectType.gainAtkStartOfTurnIfAttacked:
        int intVal = 0;
        int? max;
        if (value.contains(";")) {
          var parts = value.split(";");
          intVal = int.parse(parts[0]);
          max = int.parse(parts[1].replaceAll("max", ""));
        } else {
          intVal = int.parse(value);
        }
        if (max == null || mascotMonster.currentAttack <= max) {
          mascotMonster.currentAttack += intVal;
          if (max != null && mascotMonster.currentAttack > 5) {
            mascotMonster.currentAttack = max;
          }
        }
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
                monsterZoneIndex, battleLog, opponent, false, isGameInOvertime);
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
            await player.summonMonster(monsterToSummon.cloneMonster(),
                monsterZoneIndex, battleLog, opponent, false, isGameInOvertime);
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
            await player.summonMonster(monsterToSummon.cloneMonster(),
                monsterZoneIndex, battleLog, opponent, false, isGameInOvertime);
          }
        }
        break;
      case MascotAdditionalEffectType.negateDamage:
        if (mascotMonster.isAttackedCounter == 0) {
          result.isTriggered = true;
          result.effect = "negateDamage";
        }
        break;
      case MascotAdditionalEffectType.addCardStartOfTurn:
        var parts = value.split(";");
        var howManyTimes = int.parse(parts[0]);
        var cardId = parts[1];
        var card = (await CardDatabase.getCards([cardId]))[0];
        for (var i = 0; i < howManyTimes; i++) {
          if (player.canDraw()) {
            var cardToAdd = card.clone();
            cardToAdd.oneTimeUse = true;
            player.hand.add(cardToAdd);
          }
        }
        break;
      case MascotAdditionalEffectType.canNotBeAttacked:
        var monsterId = value;
        if (opponent.monsters.any((a) => a != null && a.id == monsterId)) {
          result.isTriggered = true;
          result.effect = "canNotBeTargeted";
        }
        break;
    }
    return result;
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
  summonWhenFaint,
  negateDamage,
  addCardStartOfTurn,
  canNotBeAttacked
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
