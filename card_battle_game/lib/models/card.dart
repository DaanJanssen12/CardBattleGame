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
}

class MonsterCard extends GameCard {
  int health;
  int attack;
  late bool hasAttacked;

  MonsterCard(super.name, super.imagePath, super.cost,
      {this.health = 10, this.attack = 3}) {
    hasAttacked = false;
    type = 'Monster';
  }
  void apply(UpgradeCard card){
    switch(card.upgradeCardType){
      case UpgradeCardType.boostAtk:
        attack += card.value;
      break;
      case UpgradeCardType.heal:
        health += card.value;
      break;
    }
  }

  void takeDamage(int damage){
    health -= damage;
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
