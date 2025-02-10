import 'package:card_battle_game/models/card.dart';
import 'package:card_battle_game/models/effect.dart';
import 'package:card_battle_game/models/game_effect.dart';
import 'package:card_battle_game/models/mascot_effects.dart';
import 'package:card_battle_game/models/player.dart';
import 'package:card_battle_game/models/upgrade_card.dart';
import 'package:card_battle_game/models/upgrade_card_type.dart';

class MonsterCard extends GameCard {
  //Stats
  int health;
  int attack;
  late MascotEffects mascotEffects;
  late SummonEffect? summonEffect;

  //Game info
  late bool hasAttacked;
  late bool isActive;
  late int currentHealth;
  late int currentAttack;
  late int? monsterZoneIndex;
  List<GameEffect> effects = [];

  MonsterCard(super.name, super.imagePath, super.cost, super.shortDescription,
      super.fullDescription,
      {this.health = 10, this.attack = 3}) {
    isActive = false;
    hasAttacked = false;
    type = 'Monster';
    currentHealth = health;
    currentAttack = attack;
    mascotEffects = MascotEffects.fromJson(null);
    summonEffect = null;
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

  void summon(int spot) {
    isActive = true;
    hasAttacked = false;
    currentHealth = health;
    currentAttack = attack;
    monsterZoneIndex = spot;
  }

  void takeDamage(int damage) {
    if(effects.isNotEmpty && effects.any((a) => a.type == GameEffectType.shield)){
      damage = (damage/2).ceil();
    }
    currentHealth -= damage;
    if (currentHealth < 0) {
      currentHealth = 0;
    }
  }

  bool canAttack() {
    return !hasAttacked && isActive;
  }

  void doAttack(MonsterCard target, List<String> battleLog) {
    target.takeDamage(currentAttack);
    hasAttacked = true;

    battleLog.add('$name attacked ${target.name} ($currentAttack dmg)');
  }

  void attackPlayer(Player player, List<String> battleLog) {
    player.health--;
    hasAttacked = true;
    battleLog.add('$name attacked ${player.name} directly');
  }

  void startnewTurn() {
    hasAttacked = false;
    for (var effect in effects) {
      if(effect.type == GameEffectType.freeze){
        hasAttacked = true;
      }
      effect.value--;
    }

    effects = effects.any((a) => a.value > 0)
      ? effects.where((w) => w.value > 0).toList()
      : [];
  }

  void faint() {
    isActive = false;
    hasAttacked = false;
    currentHealth = health;
    currentAttack = attack;
    monsterZoneIndex = null;
    effects = [];
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
    card.mascotEffects = MascotEffects.fromJson(json['mascotEffects']);
    card.summonEffect = json['summonEffect'] == null
        ? null
        : SummonEffect.fromJson(json['summonEffect']);
    card.rarity = CardRarityExtension.fromString(json['rarity']);

    return card;
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      ...super.toJson(),
      'health': health,
      'attack': attack,
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
    return card;
  }
}
