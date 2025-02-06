import 'package:card_battle_game/models/card.dart';
import 'package:card_battle_game/models/card_database.dart';

class Player {
  String name;
  int health;
  int mana;
  List<GameCard> hand;
  List<MonsterCard?> monsters;
  List<GameCard> deck;
  List<GameCard> discardPile;

  Player({required this.name})
      : health = 3,
        mana = 5,
        deck = [],
        hand = [],
        discardPile = [],
        monsters = List.filled(3, null) {
    //initDeck();
  }

  Future<void> initDeck() async {
    // deck = [
    //   MonsterCard("Penguin Mage", "assets/images/PenguinMage.png", 4,
    //       health: 8, attack: 7),
    //   MonsterCard("Flame Dog", "assets/images/FlameDog.png", 3,
    //       health: 10, attack: 3),
    //   UpgradeCard("Heal", "assets/images/Heal.png", 1,
    //       upgradeCardType: UpgradeCardType.heal, value: 3),
    //   UpgradeCard("Strengthen", "assets/images/Strengthen.png", 1,
    //       upgradeCardType: UpgradeCardType.boostAtk, value: 2),
    // ];
    deck = await CardDatabase.generateDeck(5);
    deck.shuffle();
  }

  void startTurn() {
    drawCard(1);
    mana += 2;

    for (var monster in monsters.where((w) => w != null)) {
      monster!.startnewTurn();
    }
  }

  void drawCard(int amount) {
    for (int i = 0; i < amount; i++) {
      if (deck.isEmpty) shuffleDiscardPile();
      if (deck.isNotEmpty) hand.add(deck.removeAt(0));
    }
  }

  void shuffleDiscardPile() {
    deck.addAll(discardPile);
    discardPile.clear();
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
    if (card.isUpgrade()) {
      monsters[monsterZoneIndex]?.apply(card as UpgradeCard);
    }

    if (!card.isMonster()) {
      discardPile.add(card);
    }
  }

  void summonMonster(MonsterCard monster, int monsterZoneIndex) {
    monsters[monsterZoneIndex] = monster;
    monster.summon(monsterZoneIndex);
  }

  void faintMonster(MonsterCard monster) {
    monster.faint();
    var i = monsters.indexOf(monster);
    monsters[i] = null;
    discardPile.add(monster);
  }
}

class CPU {
  static Future<void> executeTurn(
      Player player, Player opponent, Function updateGameState) async {
    print('Enemy turn initiated');

    // If the enemy has cards to play, play them.
    for (var card in List.from(player.hand)) {
      for (var i = 0; i < 3; i++) {
        if (player.canPlayCard(card, i).$1) {
          print('Enemy plays card: ${card.name}');
          player.playCard(card, i);
          updateGameState();
          await Future.delayed(Duration(seconds: 1));
        }
      }
    }

    for (var monster in List.from(player.monsters)) {
      if (monster == null) continue;

      if (monster.canAttack()) {
        if (opponent.monsters.isEmpty 
            || !opponent.monsters.any((w) => w != null)) {
          monster.attackPlayer(opponent);
        } else {
          var opponentMonster = opponent.monsters.where((w) => w != null).first;
          if(opponentMonster == null) continue;
          monster.doAttack(opponentMonster);
        }
        updateGameState();
        await Future.delayed(Duration(seconds: 1));
      }
    }

    // Optionally, simulate attack or other actions after card play
    // If there are other actions to simulate, you can add them here

    print('Enemy turn finished');
  }
}
