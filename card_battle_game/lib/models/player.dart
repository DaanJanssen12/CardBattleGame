import 'package:card_battle_game/models/action_card.dart';
import 'package:card_battle_game/models/card.dart';
import 'package:card_battle_game/models/card_database.dart';
import 'package:card_battle_game/models/mascot_effects.dart';
import 'package:card_battle_game/models/monster_card.dart';
import 'package:card_battle_game/models/upgrade_card.dart';

class Player {
  String name;
  int health;
  int mana;
  List<GameCard> hand;
  List<MonsterCard?> monsters;
  List<GameCard> deck;
  List<GameCard> discardPile;

  late int startingHealth;
  late int startingMana;
  late int regainManaPerTurn;
  late String mascot;
  late MonsterCard mascotCard;

  Player({required this.name})
      : health = 3,
        mana = 5,
        deck = [],
        hand = [],
        discardPile = [],
        monsters = List.filled(3, null) {
    startingHealth = 3;
    startingMana = 0;
    regainManaPerTurn = 1;
    mascot = '';
  }

  factory Player.fromJson(Map<String, dynamic> json) {
    var data = Player(name: 'Player');
    if (json.isEmpty) {
      return data;
    }

    data.name = json['name'];
    data.health = json['health'];
    data.mana = json['mana'];
    data.startingHealth = json['startingHealth'];
    data.startingMana = json['startingMana'];
    data.regainManaPerTurn = json['regainManaPerTurn'];
    data.mascot = json['mascot'];
    data.hand = json['hand'] != null
        ? (json['hand'] as List<dynamic>).map((cardJson) {
            return GameCard.fromJson(cardJson);
          }).toList()
        : [];
    data.deck = json['deck'] != null
        ? (json['deck'] as List<dynamic>).map((cardJson) {
            return GameCard.fromJson(cardJson);
          }).toList()
        : [];
    data.discardPile = json['discardPile'] != null
        ? (json['discardPile'] as List<dynamic>).map((cardJson) {
            return GameCard.fromJson(cardJson);
          }).toList()
        : [];
    data.monsters = List.filled(3, null);
    data.mascotCard = MonsterCard.fromJson(json['mascotCard']);
    return data;
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'health': health,
      'mana': mana,
      'startingHealth': startingHealth,
      'startingMana': startingMana,
      'regainManaPerTurn': regainManaPerTurn,
      'mascot': mascot,
      'mascotCard': mascotCard.toJson(),
      'hand': hand.map((m) => m.toJson()).toList(),
      'monsters': monsters.map((m) => m?.toJson()).toList(),
      'deck': deck.map((m) => m.toJson()).toList(),
      'discardPile': discardPile.map((m) => m.toJson()).toList()
    };
  }

  Future<void> generateDeck() async {
    deck = await CardDatabase.generateDeck(5);
    deck.shuffle();
  }

  void endGame() {
    for (var monster in monsters) {
      if (monster != null) {
        faintMonster(monster.monsterZoneIndex!, [], null);
      }
    }
    shuffleDiscardPile();
    shuffleHandIntoDeck();
  }

  void setMascot(MonsterCard card) {
    card.isMascot = true;
    mascot = card.id;
    mascotCard = card;
    startingHealth = card.mascotEffects.startingHealth;
    startingMana = card.mascotEffects.startingMana;
    regainManaPerTurn = card.mascotEffects.regainManaPerTurn;
  }

  Future<void> startGame(List<String> battleLog, Player opponent) async {
    if (mascot.isEmpty) {
      var newMascot = deck.firstWhere((w) => w.isMonster());
      mascot = newMascot.id;
      setMascot(newMascot.toMonster());
    }
    health = startingHealth;
    mana = startingMana;
    print('MASCOT: $mascot');
    print('MASCOT CARD: ${this.mascotCard.id}');
    print('DECK: ${this.deck.length}');
    var mascotCard = deck.any((a) => a.isMonster() && a.toMonster().isMascot)
      ? deck.firstWhere((w) => w.isMonster() && w.toMonster().isMascot)
      : deck.firstWhere((w) => w.id == mascot);
    deck.remove(mascotCard);
    await summonMonster(mascotCard.toMonster(), 1, battleLog, opponent, true);
    deck.shuffle();
  }

  Future<void> startTurn(Player opponent, List<String> battleLog) async {
    mana += regainManaPerTurn;

    for (var monster in monsters.where((w) => w != null)) {
      await monster!.startnewTurn(this, opponent, battleLog);
    }
    if (deck.isEmpty || deck.isEmpty) {
      shuffleDiscardPile();
    }
  }

  GameCard? drawCard(List<String> battleLog) {
    if (deck.isEmpty) {
      if (discardPile.isEmpty) {
        return null;
      }

      shuffleDiscardPile();
    }

    var drawnCard = deck.removeAt(0);
    hand.add(drawnCard);

    if (deck.isEmpty) {
      shuffleDiscardPile();
    }

    battleLog.add('$name drew a card');
    return drawnCard;
  }

  void shuffleDiscardPile() {
    deck.addAll(discardPile);
    discardPile.clear();
    deck.shuffle();
  }

  void shuffleHandIntoDeck() {
    if (hand.isEmpty) {
      return;
    }

    var cardsToAddBackIntoDeck =
        hand.where((w) => !w.oneTimeUse && !w.isOpponentCard).toList();
    if (cardsToAddBackIntoDeck.isEmpty) {
      return;
    }

    deck.addAll(cardsToAddBackIntoDeck);
    hand.clear();
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

    if (card.isMonster() && card.toMonster().isActive) {
      return (false, 'This monster has already been summoned');
    }

    if (card.isUpgrade() && !monsterZoneOccupied) {
      return (false, 'There is no monster in that zone');
    }

    return (true, '');
  }

  Future<void> playCard(GameCard card, int monsterZoneIndex,
      List<String> battleLog, Player opponent) async {
    mana -= card.cost;
    hand.remove(card);
    if (card.isMonster()) {
      summonMonster(
          card as MonsterCard, monsterZoneIndex, battleLog, opponent, false);
    }
    if (card.isUpgrade()) {
      monsters[monsterZoneIndex]?.apply(card as UpgradeCard);
      if (monsters[monsterZoneIndex]!.isMascot &&
          monsters[monsterZoneIndex]!.mascotEffects.additionalEffect != null) {
        await monsters[monsterZoneIndex]!
            .mascotEffects
            .additionalEffect!
            .trigger(
                MascotEffectTriggers.upgradeApplied,
                monsters[monsterZoneIndex]!,
                this,
                card as UpgradeCard,
                opponent,
                battleLog);
      }
      battleLog
          .add('${card.name} applied to ${monsters[monsterZoneIndex]?.name}');
    }
    if (card.isAction()) {
      var actionCard = (card as ActionCard);
      await actionCard.doAction(this, opponent);
      battleLog.add('${card.name} played');
    }
    print('Is opponent card: ${card.isOpponentCard}');
    if (card.isOpponentCard) {
      opponent.discardPile.add(card);
    }

    print('Is one time use: ${card.oneTimeUse}');
    if (card.oneTimeUse) {
      return;
    }
    if (card.isOpponentCard) {
      return;
    }
    if (card.isMonster()) {
      return;
    }
    discardPile.add(card);
  }

  Future<void> summonMonster(
      MonsterCard monster,
      int monsterZoneIndex,
      List<String> battleLog,
      Player? opponent,
      bool isInitialMascotSummon) async {
    monsters[monsterZoneIndex] = monster;
    monster.summon(monsterZoneIndex);
    if (monster.summonEffect != null && !isInitialMascotSummon) {
      await monster.summonEffect!.apply(monster, this, opponent);
    }
    battleLog.add('${monster.name} summoned');
  }

  void faintMonster(
      int monsterZoneIndex, List<String> battleLog, Player? opponent) {
    var monster = monsters[monsterZoneIndex];
    monster!.faint();
    monsters[monsterZoneIndex] = null;
    if (!monster.oneTimeUse && !monster.isOpponentCard) {
      discardPile.add(monster);
    }
    if (monster.isOpponentCard && opponent != null) {
      opponent.discardPile.add(monster);
    }
  }
}
