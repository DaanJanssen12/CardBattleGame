import 'package:card_battle_game/models/cards/card.dart';
import 'package:card_battle_game/models/game/effect.dart';
import 'package:card_battle_game/models/game/game_effect.dart';
import 'package:card_battle_game/models/cards/mascot_effects.dart';
import 'package:card_battle_game/models/game/monster_effect.dart';
import 'package:card_battle_game/models/player/player.dart';
import 'package:card_battle_game/models/cards/upgrade_card.dart';
import 'package:card_battle_game/models/enums/upgrade_card_type.dart';

class MonsterCard extends GameCard {
  //Stats
  int health;
  int attack;
  late MascotEffects mascotEffects;
  late bool isMascot = false;
  late SummonEffect? summonEffect;
  late MonsterEffect? monsterEffect;

  //Game info
  late bool isActive;
  late int currentHealth;
  late int currentAttack;
  late int? monsterZoneIndex;
  List<GameEffect> effects = [];
  int isAttackedCounter = 0;
  int hasAttackedCounter = 0;
  int maxAttacksPerTurn = 1;

  MonsterCard(super.name, super.imagePath, super.cost, super.shortDescription,
      super.fullDescription,
      {this.health = 10, this.attack = 3}) {
    isActive = false;
    type = 'Monster';
    currentHealth = health;
    currentAttack = attack;
    mascotEffects = MascotEffects.fromJson(null);
    summonEffect = null;
    id = id;
    //id = Uuid().v4();
  }
  void apply(UpgradeCard card) {
    switch (card.upgradeCardType) {
      case UpgradeCardType.boostAtk:
        currentAttack += card.value!;
        break;
      case UpgradeCardType.heal:
        if (card.value == null) {
          currentHealth = health;
        } else {
          currentHealth += card.value!;
        }
        break;
      case UpgradeCardType.effectShield:
        effects.add(GameEffect(GameEffectType.shield, card.value!));
        break;
    }
  }

  void summon(int spot, bool gameIsInOvertime) {
    isActive = true;
    hasAttackedCounter = 0;
    currentHealth = health;
    currentAttack = attack;
    monsterZoneIndex = spot;
    isAttackedCounter = 0;
    maxAttacksPerTurn = 1;
    if (gameIsInOvertime) {
      maxAttacksPerTurn = 2;
    }
  }

  bool takeDamage(int damage) {
    isAttackedCounter++;
    if (effects.isNotEmpty &&
        effects.any((a) => a.type == GameEffectType.shield)) {
      damage = (damage / 2).ceil();
    }
    currentHealth -= damage;
    if (currentHealth <= 0) {
      currentHealth = 0;
      return true;
    }

    return false;
  }

  bool canAttack() {
    if (!isActive || currentAttack <= 0) {
      return false;
    }
    if (hasEffect(GameEffectType.freeze)) {
      return false;
    }
    return hasAttackedCounter < maxAttacksPerTurn;
  }

  void setMaxAttacksPerTurn(int amount) {
    maxAttacksPerTurn = amount;
  }

  bool hasEffect(GameEffectType effectType) {
    for (var effect in effects) {
      if (effect.type == effectType) {
        return true;
      }
    }
    return false;
  }

  bool doAttack(MonsterCard target, List<String> battleLog) {
    var targetFainted = target.takeDamage(currentAttack);
    hasAttackedCounter++;
    battleLog.add('$name attacked ${target.name} ($currentAttack dmg)');
    return targetFainted;
  }

  void attackPlayer(
      Player player, List<String> battleLog, bool gameIsInOvertime) {
    player.health -= currentAttack;
    if (player.health < 0) {
      player.health = 0;
    }
    hasAttackedCounter++;
    battleLog.add('$name attacked ${player.name} directly');
  }

  Future<void> startnewTurn(Player player, Player opponent,
      List<String> battleLog, bool isGameInOvertime) async {
    if (isMascot && mascotEffects.additionalEffect != null) {
      await mascotEffects.additionalEffect!.trigger(
          MascotEffectTriggers.startOfTurn,
          this,
          player,
          null,
          opponent,
          battleLog,
          null,
          isGameInOvertime);
    }
    //This must be done after the mascot effect
    hasAttackedCounter = 0;
    isAttackedCounter = 0;
  }

  Future<void> endTurn() async {
    for (var effect in effects) {
      effect.value--;
    }
    effects = effects.any((a) => a.value > 0)
        ? effects.where((w) => w.value > 0).toList()
        : [];
  }

  void faint() {
    isActive = false;
    hasAttackedCounter = 0;
    currentHealth = health;
    currentAttack = attack;
    monsterZoneIndex = null;
    effects = [];
    isAttackedCounter = 0;
  }

  factory MonsterCard.fromJson(Map<String, dynamic> json) {
    var card = MonsterCard(
      json['name'],
      json['imagePath'],
      json['cost'],
      json['shortDescription'],
      json['fullDescription'],
      health: json['health'],
      attack: json['attack'],
    );
    card.id = json['id'];
    card.isMascot = json['isMascot'] ?? false;
    card.mascotEffects = MascotEffects.fromJson(json['mascotEffects']);
    card.summonEffect = json['summonEffect'] == null
        ? null
        : SummonEffect.fromJson(json['summonEffect']);
    card.monsterEffect =
        json['effect'] == null ? null : MonsterEffect.fromJson(json['effect']);
    card.rarity = CardRarityExtension.fromString(json['rarity']);

    return card;
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      ...super.toJson(),
      'health': health,
      'attack': attack,
      'isMascot': isMascot,
      'mascotEffects': mascotEffects.toJson(),
      'summonEffect': summonEffect?.toJson(),
      'effect': monsterEffect?.toJson()
    };
  }

  @override
  GameCard clone() {
    var card = MonsterCard(
        name, imagePath, cost, shortDescription, fullDescription,
        health: health, attack: attack);
    card.id = id;
    card.mascotEffects = mascotEffects;
    card.summonEffect = summonEffect;
    card.rarity = rarity;
    card.isOpponentCard = isOpponentCard;
    card.oneTimeUse = oneTimeUse;
    card.monsterEffect = monsterEffect;
    return card;
  }
}
