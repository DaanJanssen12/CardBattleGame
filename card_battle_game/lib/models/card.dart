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

  GameCard(this.name, this.imagePath, this.cost, this.shortDescription,
      this.fullDescription) {
    id = Uuid().v4();
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
    return GameCard(name, imagePath, cost, shortDescription, fullDescription);
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
    id = Uuid().v4();
  }
  void apply(UpgradeCard card) {
    switch (card.upgradeCardType) {
      case UpgradeCardType.boostAtk:
        currentAttack += card.value;
        break;
      case UpgradeCardType.heal:
        currentHealth += card.value;
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

  void doAttack(MonsterCard target) {
    target.takeDamage(currentAttack);
    hasAttacked = true;
  }

  void attackPlayer(Player player) {
    player.health--;
    hasAttacked = true;
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
    return MonsterCard(name, imagePath, cost, shortDescription, fullDescription,
        health: health, attack: attack);
  }
}

class ActionCard extends GameCard {
  ActionCardType actionCardType;
  int value;

  ActionCard(super.name, super.imagePath, super.cost, super.shortDescription,
      super.fullDescription,
      {this.actionCardType = ActionCardType.draw, this.value = 1}) {
    type = 'Action';
    id = Uuid().v4();
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
    return card;
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
    return ActionCard(name, imagePath, cost, shortDescription, fullDescription,
        actionCardType: actionCardType, value: value);
  }
}

class UpgradeCard extends GameCard {
  UpgradeCardType upgradeCardType;
  int value;

  UpgradeCard(super.name, super.imagePath, super.cost, super.shortDescription,
      super.fullDescription,
      {this.upgradeCardType = UpgradeCardType.boostAtk, this.value = 1}) {
    type = 'Upgrade';
    id = Uuid().v4();
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
    return UpgradeCard(name, imagePath, cost, shortDescription, fullDescription,
        upgradeCardType: upgradeCardType, value: value);
  }
}

enum UpgradeCardType { boostAtk, heal }

extension UpgradeCardTypeExtension on UpgradeCardType {
  // Convert a string to an enum value
  static UpgradeCardType fromString(String str) {
    return UpgradeCardType.values.firstWhere(
      (e) => e.toString().split('.').last == str.toLowerCase(),
      orElse: () => UpgradeCardType.boostAtk, // Default value
    );
  }
}

enum ActionCardType { draw }

extension ActionCardTypeExtension on ActionCardType {
  // Convert a string to an enum value
  static ActionCardType fromString(String str) {
    return ActionCardType.values.firstWhere(
      (e) => e.toString().split('.').last == str.toLowerCase(),
      orElse: () => ActionCardType.draw, // Default value
    );
  }
}
