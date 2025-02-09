import 'dart:math';

import 'package:card_battle_game/models/card_database.dart';
import 'package:card_battle_game/models/effect.dart';
import 'package:card_battle_game/models/player.dart';
import 'package:uuid/uuid.dart';

class GameCard {
  late String id;
  String name;
  late String type;
  String imagePath;
  int cost;
  String? shortDescription;
  String? fullDescription;
  late bool isInDeck;
  late String cloneId;
  late bool oneTimeUse = false;

  GameCard(this.name, this.imagePath, this.cost, this.shortDescription,
      this.fullDescription) {
    //id = Uuid().v4();
    isInDeck = false;
  }

  bool isMonster() => type == 'Monster';
  bool isUpgrade() => type == 'Upgrade';
  bool isAction() => type == 'Action';

  MonsterCard toMonster() {
    return this as MonsterCard;
  }

  bool canBePlayed() {
    //Already summoned monsters can't be played
    if (isMonster()) {
      return !toMonster().isActive;
    }

    return true;
  }

  GameCard clone() {
    var clone =
        GameCard(name, imagePath, cost, shortDescription, fullDescription);
    clone.id = id;
    cloneId = Uuid().v4();
    return clone;
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'cost': cost,
      'imagePath': imagePath,
      'type': type,
      'shortDescription': shortDescription,
      'fullDescription': fullDescription,
    };
  }

  factory GameCard.fromJson(Map<String, dynamic> json) {
    switch (json['type'].toString().toLowerCase()) {
      case 'monster':
        return MonsterCard.fromJson(json);
      case 'upgrade':
        return UpgradeCard.fromJson(json);
      case 'action':
        return ActionCard.fromJson(json);
    }
    return GameCard('', '', 0, null, null);
  }
}

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
  }

  void faint() {
    isActive = false;
    hasAttacked = false;
    currentHealth = health;
    currentAttack = attack;
    monsterZoneIndex = null;
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
    card.summonEffect = json['summonEffect'] == null ? null : SummonEffect.fromJson(json['summonEffect']);
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
    return card;
  }
}

class MascotEffects {
  int startingHealth;
  int startingMana;
  int regainManaPerTurn;
  MascotEffects(this.startingHealth, this.startingMana, this.regainManaPerTurn);
  factory MascotEffects.fromJson(Map<String, dynamic>? json) {
    var data = MascotEffects(3, 4, 1);
    if (json == null || json.isEmpty) {
      return data;
    }
    data.startingHealth = json['startingHealth'];
    data.startingMana = json['startingMana'];
    data.regainManaPerTurn = json['regainManaPerTurn'];
    return data;
  }
}

class ActionCard extends GameCard {
  ActionCardType actionCardType;
  int value;
  String? extraData;

  ActionCard(super.name, super.imagePath, super.cost, super.shortDescription,
      super.fullDescription,
      {this.actionCardType = ActionCardType.draw, this.value = 1}) {
    type = 'Action';
  }

  factory ActionCard.fromJson(Map<String, dynamic> json) {
    var card = ActionCard(
      json['name'],
      json['imagePath'],
      json['cost'],
      json['shortDescription'],
      json['fullDescription'],
      actionCardType:
          ActionCardTypeExtension.fromString(json['actionCardType']),
      value: json['value'],
    );
    card.id = json['id'];
    card.extraData = json['extraData'];
    return card;
  }

  Future<void> doAction(Player player) async{
    switch(actionCardType){
      case ActionCardType.draw:
        for(var i = 0; i < value; i++){
          player.drawCard([]);
        }
      break;
      case ActionCardType.drawNotFromDeck:
      print(extraData);
      var cardIds = extraData!.split(";");
      print(cardIds);
      var cards = await CardDatabase.getCards(cardIds);
      print(cards.length);
      for(int i = 0; i < value; i++){
        var cardToAdd = cards[Random().nextInt(cards.length)].clone();
        cardToAdd.oneTimeUse = true;
        player.hand.add(cardToAdd);
      }
      break;
    }
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      ...super.toJson(),
      'actionCardType': actionCardType,
      'value': value,
    };
  }

  @override
  GameCard clone() {
    var card = ActionCard(
        name, imagePath, cost, shortDescription, fullDescription,
        actionCardType: actionCardType, value: value);
    card.id = id;
    card.extraData = extraData;
    return card;
  }
}

class UpgradeCard extends GameCard {
  UpgradeCardType upgradeCardType;
  int? value;

  UpgradeCard(super.name, super.imagePath, super.cost, super.shortDescription,
      super.fullDescription,
      {this.upgradeCardType = UpgradeCardType.boostAtk, this.value = 1}) {
    type = 'Upgrade';
    //id = Uuid().v4();
  }

  factory UpgradeCard.fromJson(Map<String, dynamic> json) {
    var card = UpgradeCard(
      json['name'],
      json['imagePath'],
      json['cost'],
      json['shortDescription'],
      json['fullDescription'],
      upgradeCardType:
          UpgradeCardTypeExtension.fromString(json['upgradeCardType']),
      value: json['value'],
    );
    card.id = json['id'];
    return card;
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      ...super.toJson(),
      'upgradeCardType': upgradeCardType,
      'value': value,
    };
  }

  @override
  GameCard clone() {
    var card = UpgradeCard(
        name, imagePath, cost, shortDescription, fullDescription,
        upgradeCardType: upgradeCardType, value: value);
    card.id = id;
    return card;
  }
}

enum UpgradeCardType { boostAtk, heal }

extension UpgradeCardTypeExtension on UpgradeCardType {
  // Convert a string to an enum value
  static UpgradeCardType fromString(String str) {
    return UpgradeCardType.values.firstWhere(
      (e) => e.toString().split('.').last.toLowerCase() == str.toLowerCase(),
      orElse: () => UpgradeCardType.boostAtk, // Default value
    );
  }
}

enum ActionCardType { draw, drawNotFromDeck }

extension ActionCardTypeExtension on ActionCardType {
  // Convert a string to an enum value
  static ActionCardType fromString(String str) {
    return ActionCardType.values.firstWhere(
      (e) => e.toString().split('.').last.toLowerCase() == str.toLowerCase(),
      orElse: () => ActionCardType.draw, // Default value
    );
  }
}
