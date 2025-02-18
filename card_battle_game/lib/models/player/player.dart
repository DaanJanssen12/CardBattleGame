import 'package:card_battle_game/models/cards/action_card.dart';
import 'package:card_battle_game/models/cards/card.dart';
import 'package:card_battle_game/models/cards/play_card_result.dart';
import 'package:card_battle_game/models/constants.dart';
import 'package:card_battle_game/models/cards/mascot_effects.dart';
import 'package:card_battle_game/models/cards/monster_card.dart';
import 'package:card_battle_game/models/cards/upgrade_card.dart';

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

  void endGame(Player opponent) {
    for (var monster in monsters) {
      if (monster != null) {
        faintMonster(monster.monsterZoneIndex!, [], opponent);
      }
    }
    shuffleHandIntoDeck(opponent);
    shuffleDiscardPile();
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
    var mascotCard = deck.any((a) => a.isMonster() && a.toMonster().isMascot)
        ? deck.firstWhere((w) => w.isMonster() && w.toMonster().isMascot)
        : deck.firstWhere((w) => w.id == mascot);
    deck.remove(mascotCard);
    await summonMonster(mascotCard.toMonster(), 1, battleLog, opponent, true);
    deck.shuffle();
  }

  Future<void> startTurn(
      int currentTurn, Player opponent, List<String> battleLog) async {
    switch (currentTurn) {
      case >= 1 && < 3:
        mana += 1;
        break;
      case >= 3 && < 5:
        mana += 2;
        break;
      case >= 5:
        mana += 3;
        break;
    }
    mana += regainManaPerTurn;
    if (mana > Constants.playerMaxMana) {
      mana = Constants.playerMaxMana;
    }

    for (var monster in monsters.where((w) => w != null)) {
      await monster!.startnewTurn(this, opponent, battleLog);
    }
    if (deck.isEmpty || deck.isEmpty) {
      shuffleDiscardPile();
    }
  }

  Future<void> endTurn() async {
    for (var monster in monsters.where((w) => w != null)) {
      await monster!.endTurn();
    }
  }

  bool canDraw() {
    return hand.length < Constants.playerMaxHandSize;
  }

  List<GameCard> drawCards(int amount, List<String> battleLog) {
    List<GameCard> cardsDrawn = [];
    for (int i = 0; i < amount; i++) {
      if (canDraw()) {
        var card = drawCard(battleLog);
        if (card != null) {
          cardsDrawn.add(card);
        }
      }
    }
    battleLog.add('$name drew ${cardsDrawn.length} card(s)');
    return cardsDrawn;
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

    return drawnCard;
  }

  void shuffleDiscardPile() {
    if (discardPile.isEmpty) {
      return;
    }
    deck.addAll(discardPile);
    discardPile.clear();
    deck.shuffle();
  }

  void shuffleHandIntoDeck(Player opponent) {
    if (hand.isEmpty) {
      return;
    }

    var cardsToAddBackIntoDeck =
        hand.where((w) => !w.oneTimeUse && !w.isOpponentCard).toList();
    var cardsToAddBackIntoOpponentDeck =
        hand.where((w) => w.isOpponentCard).toList();
    if (cardsToAddBackIntoOpponentDeck.isNotEmpty) {
      opponent.deck.addAll(cardsToAddBackIntoOpponentDeck);
    }
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

  Future<PlayCardResult?> playCard(GameCard card, int monsterZoneIndex,
      List<String> battleLog, Player opponent) async {
    PlayCardResult? result;

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
                battleLog,
                null);
      }
      battleLog
          .add('${card.name} applied to ${monsters[monsterZoneIndex]?.name}');
    }
    if (card.isAction()) {
      var actionCard = (card as ActionCard);
      result = await actionCard.doAction(this, opponent);
      battleLog.add('${card.name} played');
    }
    if (card.isOpponentCard && !card.isMonster()) {
      opponent.discardPile.add(card);
    }

    if (!card.oneTimeUse && !card.isOpponentCard && !card.isMonster()) {
      discardPile.add(card);
    }

    return result;
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

  Future<void> attackOpponentMonster(
      MonsterCard attackingMonster,
      Player opponent,
      MonsterCard opponentMonster,
      List<String> battleLog,
      Function updateScreen) async {
    var opponentMonsterFainted =
        attackingMonster.doAttack(opponentMonster, battleLog);
    if (opponentMonster.isMascot &&
        opponentMonster.mascotEffects.additionalEffect != null) {
      await opponentMonster.mascotEffects.additionalEffect!.trigger(
          MascotEffectTriggers.isAttacked,
          opponentMonster,
          opponent,
          null,
          this,
          battleLog,
          attackingMonster);
    }

    updateScreen();
    if (opponentMonsterFainted) {
      await Future.delayed(Duration(milliseconds: 500));
      opponent.faintMonster(opponentMonster.monsterZoneIndex!, battleLog, this);
      updateScreen();
    }

    if (attackingMonster.isMascot &&
        attackingMonster.mascotEffects.additionalEffect != null &&
        opponentMonsterFainted) {
      await attackingMonster.mascotEffects.additionalEffect!.trigger(
          MascotEffectTriggers.faintOpponentMonster,
          attackingMonster,
          this,
          null,
          opponent,
          battleLog,
          null);
      await Future.delayed(Duration(milliseconds: 500));
      updateScreen();
    }
    if (opponentMonster.isMascot &&
        opponentMonster.mascotEffects.additionalEffect != null &&
        opponentMonsterFainted) {
      await opponentMonster.mascotEffects.additionalEffect!.trigger(
          MascotEffectTriggers.mascotFainted,
          opponentMonster,
          opponent,
          null,
          this,
          battleLog,
          attackingMonster);
      await Future.delayed(Duration(milliseconds: 500));
      updateScreen();
    }
  }
}
