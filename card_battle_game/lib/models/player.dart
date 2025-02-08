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

  late int startingHealth;
  late int startingMana;
  late int regainManaPerTurn;
  late String mascot;

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
    data.hand = json['hand'] == null
        ? json['hand'].map((cardJson) {
            return GameCard.fromJson(cardJson);
          }).toList()
        : [];
    data.deck = json['deck'] == null
        ? json['deck'].map((cardJson) {
            return GameCard.fromJson(cardJson);
          }).toList()
        : [];
    return data;
  }

  Future<void> generateDeck() async {
    deck = await CardDatabase.generateDeck(5);
    deck.shuffle();
  }

  void endGame() {
    for (var monster in monsters) {
      if (monster != null) {
        faintMonster(monster.monsterZoneIndex!);
      }
    }
    shuffleDiscardPile();
    shuffleHandIntoDeck();
  }

  void setMascot(MonsterCard card) {
    mascot = card.id;
    startingHealth = card.mascotEffects.startingHealth;
    startingMana = card.mascotEffects.startingMana;
    regainManaPerTurn = card.mascotEffects.regainManaPerTurn;
  }

  Future<void> startGame() async {
    if (mascot.isEmpty) {
      var newMascot = deck.firstWhere((w) => w.isMonster());
      mascot = newMascot.id;
      setMascot(newMascot.toMonster());
    }
    health = startingHealth;
    mana = startingMana;
    var mascotCard = deck.firstWhere((w) => w.id == mascot);
    deck.remove(mascotCard);
    await summonMonster(mascotCard.toMonster(), 1);
    deck.shuffle();
  }

  void startTurn() {
    mana += regainManaPerTurn;

    for (var monster in monsters.where((w) => w != null)) {
      monster!.startnewTurn();
    }
    if (deck.isEmpty || deck.length == 0) {
      shuffleDiscardPile();
    }
  }

  GameCard drawCard() {
    if (deck.isEmpty) {
      shuffleDiscardPile();
    }
    var drawnCard = deck.removeAt(0);
    hand.add(drawnCard);

    if (deck.isEmpty) {
      shuffleDiscardPile();
    }

    return drawnCard;
  }

  void shuffleDiscardPile() {
    deck.addAll(discardPile);
    discardPile.clear();
    deck.shuffle();
  }

  void shuffleHandIntoDeck() {
    deck.addAll(hand);
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
    if (card.isAction()) {
      (card as ActionCard).doAction(this);
    }

    if (!card.isMonster()) {
      discardPile.add(card);
    }
  }

  Future<void> summonMonster(MonsterCard monster, int monsterZoneIndex) async {
    monsters[monsterZoneIndex] = monster;
    monster.summon(monsterZoneIndex);
    if (monster.summonEffect != null) {
      print('triggering summon effect');
      await monster.summonEffect!.apply(monster, this);
    }
  }

  void faintMonster(int monsterZoneIndex) {
    var monster = monsters[monsterZoneIndex];
    monster!.faint();
    monsters[monsterZoneIndex] = null;
    if (!monster.oneTimeUse) {
      discardPile.add(monster);
    }
  }
}
