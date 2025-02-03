import 'package:card_battle_game/models/card.dart';

class Player {
  String name;
  int health;
  int mana;
  List<GameCard> hand;
  List<MonsterCard?> monsters;
  List<GameCard> deck;
  List<GameCard> discardPile;

  Player({required this.name})
      : health = 30,
        mana = 5,
        deck = [],
        hand = [],
        discardPile = [],
        monsters = List.filled(3, null) {
    initDeck();
  }

  void initDeck() {
    deck = [
      MonsterCard("Starter Monster 1", "assets/images/buddy1.png", 4,
          health: 15, attack: 4),
      MonsterCard("Starter Monster 2", "assets/images/buddy2.png", 3,
          health: 10, attack: 3),
      UpgradeCard("Heal", "", 1,
          upgradeCardType: UpgradeCardType.heal, value: 1),
      UpgradeCard("Strengthen", "", 1,
          upgradeCardType: UpgradeCardType.boostAtk, value: 1),
    ];
    deck.shuffle();
  }

  (bool, String) canPlayCard(GameCard card, int monsterZoneIndex) {
    if (card.cost > mana) {
      return (false, 'Not enough mana');
    }
    var monsterZoneOccupied = monsters[monsterZoneIndex] != null;
    if (card.isMonster() && monsterZoneOccupied) {
      return (false, 'There already is a monster in that zone');
    }

    if (card.isUpgrade() && !monsterZoneOccupied) {
      return (false, 'There is no monster in that zone');
    }

    return (true, '');
  }

  void playCard(GameCard card, int monsterZoneIndex) {
    mana -= card.cost;
    hand.remove(card);
    if (card.isMonster()) {
      summonMonster(card as MonsterCard, monsterZoneIndex);
    }
    if(card.isUpgrade()){
      monsters[monsterZoneIndex]?.apply(card as UpgradeCard);
    }
    discardPile.add(card);
  }

  void summonMonster(MonsterCard monster, int monsterZoneIndex) {
    monsters[monsterZoneIndex] = monster;
  }
}

class CPU {
  static Future<void> executeTurn(
      Player enemy, Function updateGameState) async {
    print('Enemy turn initiated');

    // If the enemy has cards to play, play them.
    for (var card in List.from(enemy.hand)) {
      print('Enemy plays card: ${card.name}');
      await Future.delayed(
          Duration(seconds: 1)); // Simulate delay between actions
      for (var i = 0; i < 3; i++) {
        if (enemy.canPlayCard(card, i).$1) {
          enemy.playCard(card, i);
          updateGameState();
        }
      }
    }

    // Optionally, simulate attack or other actions after card play
    // If there are other actions to simulate, you can add them here

    print('Enemy turn finished');
  }
}
