import 'package:card_battle_game/models/player.dart';

class GameCard {
  String name;
  late String type;
  String imagePath;
  int cost;

  GameCard(this.name, this.imagePath, this.cost);

  bool isMonster() => type == 'Monster';
  bool isUpgrade() => type == 'Upgrade';
  bool isAction() => type == 'Action';

  MonsterCard toMonster() {
    return this as MonsterCard;
  }

  bool canBePlayed(){
    
    //Already summoned monsters can't be played
    if(isMonster()){
      return !toMonster().isActive;
    }

    return true;
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

  MonsterCard(super.name, super.imagePath, super.cost,
      {this.health = 10, this.attack = 3}) {
    isActive = false;
    hasAttacked = false;
    type = 'Monster';
    currentHealth = health;
    currentAttack = attack;
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

  void summon(){
    isActive = true;
    hasAttacked = false;
    currentHealth = health;
    currentAttack = attack;
  }

  void takeDamage(int damage) {
    currentHealth -= damage;
    if(currentHealth < 0){
      currentHealth = 0;
    }
  }

  bool canAttack() {
    return !hasAttacked && isActive;
  }

  void doAttack(MonsterCard target){
    target.takeDamage(currentAttack);
    hasAttacked = true;
  }

  void attackPlayer(Player player){
    player.health--;
    hasAttacked = true;
  }

  void startnewTurn(){
    hasAttacked = false;
  }

  void faint(){
    isActive = false;
    hasAttacked = false;
    currentHealth = health;
    currentAttack = attack;
  }
}

class ActionCard extends GameCard {
  ActionCardType actionCardType;
  int value;

  ActionCard(super.name, super.imagePath, super.cost,
      {this.actionCardType = ActionCardType.draw, this.value = 1}) {
    type = 'Action';
  }
}

class UpgradeCard extends GameCard {
  UpgradeCardType upgradeCardType;
  int value;

  UpgradeCard(super.name, super.imagePath, super.cost,
      {this.upgradeCardType = UpgradeCardType.boostAtk, this.value = 1}) {
    type = 'Upgrade';
  }
}

enum UpgradeCardType { boostAtk, heal }

enum ActionCardType { draw }
