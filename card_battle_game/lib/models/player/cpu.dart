import 'dart:math';
import 'package:card_battle_game/models/cards/action_card.dart';
import 'package:card_battle_game/models/constants.dart';
import 'package:card_battle_game/models/enums/action_card_type.dart';
import 'package:card_battle_game/models/cards/card.dart';
import 'package:card_battle_game/models/database/card_database.dart';
import 'package:card_battle_game/models/cards/monster_card.dart';
import 'package:card_battle_game/models/player/player.dart';
import 'package:card_battle_game/models/cards/upgrade_card.dart';
import 'package:card_battle_game/models/enums/upgrade_card_type.dart';

class CpuPlayer extends Player {
  late bool isCPU;
  late CpuLevels level;
  late CpuStrategy strategy;
  late List<String> deckCardIds;
  late int possibleFromStage;
  late int possibleUntillStage;
  late String? id;
  late String? tags;
  bool hasTag(String? tag) {
    if (tags == null && tag == null) {
      return true;
    }
    if (tag != null && tags == null) {
      return false;
    }
    if (tag == null && tags != null) {
      return false;
    }
    return tags!.contains(tag!);
  }

  CpuPlayer({required super.name}) {
    isCPU = true;
    level = CpuLevels.easy;
    strategy = CpuStrategy.random;
  }

  Future<void> executeTurn(
      Player opponent,
      Function updateGameState,
      List<String> battleLog,
      bool Function() isGameOver,
      bool isGameInOvertime) async {
    await CPU.executeTurn(this, opponent, updateGameState, battleLog,
        isGameOver, isGameInOvertime);
  }

  Future<void> init() async {
    deck = await CardDatabase.getCards(deckCardIds);
    var mascotCard = deck.firstWhere((w) => w.id == mascot);
    setMascot(mascotCard.toMonster());
  }

  factory CpuPlayer.fromJson(Map<String, dynamic> json) {
    var cpu = CpuPlayer(name: json['name']);
    cpu.level = CpuLevelsExtension.fromString(json['cpuLevel']);
    cpu.strategy = CpuStrategyExtension.fromString(json['cpuStrategy']);
    cpu.mascot = json['mascot'];
    cpu.deckCardIds =
        (json['deck'] as List<dynamic>).map((m) => m.toString()).toList();
    cpu.possibleFromStage = json['possibleFromStage'];
    cpu.possibleUntillStage = json['possibleUntillStage'];
    cpu.id = json['id'];
    cpu.tags = json['tags'];
    return cpu;
  }

  Future<void> generateDeck(int deckSize) async {
    deck = await CardDatabase.generateDeck(deckSize, strategy, level);
    deck.shuffle();
  }
}

enum CpuLevels { easy, medium, hard, expert }

extension CpuLevelsExtension on CpuLevels {
  // Convert a string to an enum value
  static CpuLevels fromString(String str) {
    return CpuLevels.values.firstWhere(
      (e) => e.toString().split('.').last.toLowerCase() == str.toLowerCase(),
      orElse: () => CpuLevels.easy, // Default value
    );
  }
}

enum CpuStrategy { random, defensive, offensive, balanced }

extension CpuStrategyExtension on CpuStrategy {
  // Convert a string to an enum value
  static CpuStrategy fromString(String str) {
    return CpuStrategy.values.firstWhere(
      (e) => e.toString().split('.').last.toLowerCase() == str.toLowerCase(),
      orElse: () => CpuStrategy.random, // Default value
    );
  }
}

class CPU {
  static Future<void> executeTurn(
      CpuPlayer cpu,
      Player opponent,
      Function updateGameState,
      List<String> battleLog,
      bool Function() isGameOver,
      bool isGameInOvertime) async {
    await playCardsFromHand(cpu, opponent, updateGameState, battleLog,
        isGameOver, isGameInOvertime);
    await attackWithAllActiveMonsters(cpu, opponent, updateGameState, battleLog,
        isGameOver, isGameInOvertime);
  }

  static Future<void> playCardsFromHand(
      CpuPlayer cpu,
      Player opponent,
      Function updateGameState,
      List<String> battleLog,
      bool Function() isGameOver,
      bool gameIsInOvertime) async {
    if (isGameOver()) {
      return;
    }
    switch (cpu.level) {
      case CpuLevels.easy:
        await cpuEasyPlayCardsFromHand(cpu, opponent, updateGameState,
            battleLog, isGameOver, gameIsInOvertime);
        break;
      default:
        for (int i = 0; i < 2; i++) {
          //Empty hand and mana to spare: Exchange
          if(cpu.hand.isEmpty && cpu.mana > Constants.cardExchangeCost){
            cpu.mana -= Constants.cardExchangeCost;
            cpu.drawCard(battleLog);
            updateGameState();
          }
          await cpuMediumPlayCardsFromHand(cpu, opponent, updateGameState,
              battleLog, isGameOver, gameIsInOvertime);
        }
        break;
    }
  }

  static Future<void> cpuEasyPlayCardsFromHand(
      CpuPlayer cpu,
      Player opponent,
      Function updateGameState,
      List<String> battleLog,
      bool Function() isGameOver,
      bool gameIsInOvertime) async {
    if (isGameOver()) {
      return;
    }
    // If the enemy has cards to play, play them.
    if (cpu.strategy == CpuStrategy.random) {
      cpu.hand.shuffle();
      for (var card in List.from(cpu.hand)) {
        for (var i = 0; i < 3; i++) {
          if (cpu.canPlayCard(card, i).$1) {
            await cpu.playCard(card, i, battleLog, opponent, gameIsInOvertime);
            updateGameState();
            await Future.delayed(Duration(seconds: 1));
            if (isGameOver()) {
              return;
            }
            //Played card, do not check the other spots
            break;
          }
        }
      }
      return;
    }

    //Do 2 loops
    for (var x = 0; x < 2; x++) {
      if (cpu.strategy == CpuStrategy.offensive) {
        await playMonsterCards(cpu, opponent, updateGameState, battleLog,
            isGameOver, gameIsInOvertime);
        await playOtherCards(cpu, opponent, updateGameState, battleLog,
            isGameOver, gameIsInOvertime);
      }
      if (cpu.strategy == CpuStrategy.defensive) {
        await playOtherCards(cpu, opponent, updateGameState, battleLog,
            isGameOver, gameIsInOvertime);
        await playMonsterCards(cpu, opponent, updateGameState, battleLog,
            isGameOver, gameIsInOvertime);
      }
    }
  }

  static Future<void> cpuMediumPlayCardsFromHand(
      CpuPlayer cpu,
      Player opponent,
      Function updateGameState,
      List<String> battleLog,
      bool Function() isGameOver,
      bool gameIsInOvertime) async {
    if (isGameOver()) {
      return;
    }

    if (cpu.monsters.any((a) => a != null)) {
      await playBestMonsterCard(cpu, opponent, updateGameState, battleLog,
          isGameOver, gameIsInOvertime);
    }

    //Sort Hand by Priority**
    cpu.hand.sort((a, b) {
      int aPriority = getCardPriority(a, cpu);
      int bPriority = getCardPriority(b, cpu);
      return bPriority.compareTo(aPriority); // Higher priority first
    });

    // Has any monsters on the field?
    var hasMonstersOnField = cpu.monsters.any((a) => a != null);
    if (!hasMonstersOnField) {
      if (cpu.hand.any((a) => a.isMonster())) {
        //Get the first monster you can play
        var cardToPlay = cpu.hand.where(
            (w) => w.isMonster() && w.canBePlayed() && w.cost <= cpu.mana);
        if (cardToPlay.isNotEmpty) {
          await cpu.playCard(
              cardToPlay.first, 1, battleLog, opponent, gameIsInOvertime);
          updateGameState();
          await Future.delayed(Duration(milliseconds: 500));
        }
      }
    }

    //Play Cards in Order of Priority**
    for (var card in List.from(cpu.hand)) {
      for (var i = 0; i < 3; i++) {
        if (cpu.canPlayCard(card, i).$1) {
          await cpu.playCard(card, i, battleLog, opponent, gameIsInOvertime);
          updateGameState();
          await Future.delayed(Duration(milliseconds: 500));
          if (isGameOver()) {
            return;
          }
          break;
        }
      }
    }
  }

  static Future<void> playMonsterCards(
      CpuPlayer cpu,
      Player opponent,
      Function updateGameState,
      List<String> battleLog,
      bool Function() isGameOver,
      bool gameIsInOvertime) async {
    if (isGameOver()) {
      return;
    }
    //Open monster zones ?
    if (cpu.monsters.any((a) => a == null)) {
      var monsterCards = cpu.hand.where((w) => w.isMonster()).toList();
      for (var monsterCard in monsterCards) {
        //Do a loop for every monster zone
        for (var i = 0; i < 3; i++) {
          //If monster can be played > play it
          if (cpu.canPlayCard(monsterCard, i).$1) {
            await cpu.playCard(
                monsterCard, i, battleLog, opponent, gameIsInOvertime);
            updateGameState();
            await Future.delayed(Duration(milliseconds: 500));
            //Played card, do not check the other spots
            break;
          }
        }
      }
    }
  }

  static Future<void> playBestMonsterCard(
      CpuPlayer cpu,
      Player opponent,
      Function updateGameState,
      List<String> battleLog,
      bool Function() isGameOver,
      bool gameIsInOvertime) async {
    if (isGameOver()) {
      return;
    }
    //Open monster zones ?
    if (cpu.monsters.any((a) => a == null)) {
      var monsterCards = cpu.hand.where((w) => w.isMonster()).toList();
      if (monsterCards.isEmpty) {
        return;
      }
      var mostValuableMonster = getBiggestThreat(
          monsterCards.map((card) => card.toMonster()).toList(), cpu);
      GameCard monsterCard =
          monsterCards.firstWhere((w) => w.id == mostValuableMonster.id);
      if (monsterCard.cost > cpu.mana) {
        return;
      }
      for (var i = 0; i < 3; i++) {
        //If monster can be played > play it
        if (cpu.canPlayCard(monsterCard, i).$1) {
          await cpu.playCard(
              monsterCard, i, battleLog, opponent, gameIsInOvertime);
          updateGameState();
          await Future.delayed(Duration(milliseconds: 500));

          //Played card
          return;
        }
      }
    }
  }

  static Future<void> playOtherCards(
      CpuPlayer cpu,
      Player opponent,
      Function updateGameState,
      List<String> battleLog,
      bool Function() isGameOver,
      bool gameIsInOvertime) async {
    if (isGameOver()) {
      return;
    }
    var nonMonsterCards = cpu.hand.where((w) => !w.isMonster()).toList();
    nonMonsterCards.sort((a, b) {
      int aVal = getGameCardSortValue(a, cpu.strategy);
      int bVal = getGameCardSortValue(b, cpu.strategy);
      return aVal > bVal ? 1 : 0;
    });
    for (var gameCard in nonMonsterCards) {
      //Do a loop for every monster zone
      for (var i = 0; i < 3; i++) {
        //If card can be played > play it
        if (cpu.canPlayCard(gameCard, i).$1) {
          await cpu.playCard(
              gameCard, i, battleLog, opponent, gameIsInOvertime);
          updateGameState();
          await Future.delayed(Duration(milliseconds: 500));
          if (isGameOver()) {
            return;
          }
          //Played card, do not check the other spots
          break;
        }
      }
    }
  }

  static int getGameCardSortValue(GameCard gameCard, CpuStrategy strategy) {
    if (strategy == CpuStrategy.offensive) {
      if (gameCard.isUpgrade()) {
        switch ((gameCard as UpgradeCard).upgradeCardType) {
          case UpgradeCardType.boostAtk:
            return 100;
          case UpgradeCardType.effectShield:
            return 30;
          case UpgradeCardType.heal:
            return 0;
        }
      }
      if (gameCard.isAction()) {
        switch ((gameCard as ActionCard).actionCardType) {
          case ActionCardType.draw:
            return 10;
          case ActionCardType.drawNotFromDeck:
            return 20;
          case ActionCardType.stealRandomCardFromOpponentHand:
            return 40;
          default:
            return 0;
        }
      }
    }
    if (strategy == CpuStrategy.defensive) {
      if (gameCard.isUpgrade()) {
        switch ((gameCard as UpgradeCard).upgradeCardType) {
          case UpgradeCardType.boostAtk:
            return 0;
          case UpgradeCardType.effectShield:
            return 90;
          case UpgradeCardType.heal:
            return 100;
          default:
            return 0;
        }
      }
      if (gameCard.isAction()) {
        switch ((gameCard as ActionCard).actionCardType) {
          case ActionCardType.draw:
            return 10;
          case ActionCardType.drawNotFromDeck:
            return 20;
          case ActionCardType.stealRandomCardFromOpponentHand:
            return 30;
          default:
            return 0;
        }
      }
    }

    return 0;
  }

  static Future<void> attackWithAllActiveMonsters(
      CpuPlayer cpu,
      Player opponent,
      Function updateGameState,
      List<String> battleLog,
      bool Function() isGameOver,
      bool isGameInOvertime) async {
    if (isGameOver() || opponent.health == 0) {
      return;
    }

    var loops = isGameInOvertime ? 2 : 1;
    for (int i = 0; i < loops; i++) {
      switch (cpu.level) {
        case CpuLevels.easy:
          await cpuAttackWithAllActiveMonsters(cpu, opponent, updateGameState,
              battleLog, isGameOver, isGameInOvertime);
          break;
        case CpuLevels.medium:
          await cpuAttackWithAllActiveMonsters(cpu, opponent, updateGameState,
              battleLog, isGameOver, isGameInOvertime);
          break;
        default:
          await cpuAttackWithAllActiveMonsters(cpu, opponent, updateGameState,
              battleLog, isGameOver, isGameInOvertime);
          break;
      }
    }
  }

  static Future<void> cpuAttackWithAllActiveMonsters(
      CpuPlayer cpu,
      Player opponent,
      Function updateGameState,
      List<String> battleLog,
      bool Function() isGameOver,
      bool isGameInOvertime) async {
    if (isGameOver() || opponent.health == 0) {
      return;
    }

    List<MonsterCard> activeMonsters =
        cpu.monsters.where((m) => m != null).map((m) => m!).toList();
    List<MonsterCard> opponentMonsters =
        opponent.monsters.where((m) => m != null).map((m) => m!).toList();

    for (var monster in activeMonsters) {
      if (!monster.canAttack()) continue;

      opponentMonsters =
          opponent.monsters.where((m) => m != null).map((m) => m!).toList();
      // Opponent has no monsters? Attack player directly!
      if (opponentMonsters.isEmpty) {
        monster.attackPlayer(opponent, battleLog, isGameInOvertime);
        updateGameState();
        await Future.delayed(Duration(milliseconds: 500));
        if (isGameOver()) return;
        continue;
      }

      // Opponent has monsters, so determine the target
      MonsterCard target = determineTarget(cpu, opponent, updateGameState,
          battleLog, isGameOver, isGameInOvertime);

      await cpu.attackOpponentMonster(monster, opponent, target, battleLog,
          updateGameState, isGameInOvertime);

      updateGameState();
      await Future.delayed(Duration(milliseconds: 500));
      if (isGameOver()) return;
    }
  }

  static MonsterCard determineTarget(
      CpuPlayer cpu,
      Player opponent,
      Function updateGameState,
      List<String> battleLog,
      bool Function() isGameOver,
      bool isGameInOvertime) {
    var opponentMonsters =
        opponent.monsters.where((w) => w != null).map((m) => m!).toList();
    return getBiggestThreat(opponentMonsters, cpu);
  }

  static bool canKnockOutMonster(MonsterCard monster, CpuPlayer cpu) {
    var monstersToAttackWith =
        cpu.monsters.where((w) => w != null && w.canAttack()).toList();
    var totalAtkPower = 0;
    var totalAttacks = 0;
    for (var monster in monstersToAttackWith) {
      totalAtkPower += monster!.currentAttack;
      totalAttacks++;
      if (cpu.gameIsInOvertime && monster.hasAttackedCounter == 0) {
        totalAtkPower += monster.currentAttack;
        totalAttacks++;
      }
    }

    return monster.currentHealth <= totalAtkPower;
  }

  static MonsterCard getBiggestThreat(
      List<MonsterCard> monsters, CpuPlayer cpu) {
    Map<MonsterCard, TargetValue> targetValues = {};
    MonsterCard? biggestThreat;

    for (var monster in monsters) {
      var targetValue = TargetValue(monster, cpu, null, null);
      targetValues[monster] = targetValue;

      biggestThreat ??= monster;
      if (targetValues[monster]!.value > targetValues[biggestThreat]!.value) {
        biggestThreat = monster;
      }
    }

    return biggestThreat!;
  }

  static int getCardPriority(GameCard card, CpuPlayer cpu) {
    if (cpu.strategy == CpuStrategy.random) {
      return Random().nextInt(100);
    }

    bool isAggressive = cpu.strategy == CpuStrategy.offensive;
    bool isDefensive = cpu.strategy == CpuStrategy.defensive;
    bool isBalanced = cpu.strategy == CpuStrategy.balanced;

    if (card.isAction()) {
      switch ((card as ActionCard).actionCardType) {
        case ActionCardType.draw:
          return 100; // Always play draw cards first
        case ActionCardType.stealRandomCardFromOpponentHand:
          return isAggressive
              ? 95
              : (isBalanced ? 85 : 80); // Balanced in the middle
        default:
          return 50; // Other actions are mid-priority
      }
    }

    if (card.isUpgrade()) {
      switch ((card as UpgradeCard).upgradeCardType) {
        case UpgradeCardType.boostAtk:
          return isAggressive
              ? 75
              : (isBalanced ? 65 : 55); // Balanced in between
        case UpgradeCardType.effectShield:
          return isDefensive ? 80 : (isBalanced ? 70 : 60);
        case UpgradeCardType.heal:
          return isDefensive ? 85 : (isBalanced ? 65 : 50);
      }
    }

    if (card.isMonster()) {
      var monster = card.toMonster();

      //When playing card from hand, apply reversed strategy then for targeting
      var inverseStrategy = CpuStrategy.balanced;
      if (cpu.strategy == CpuStrategy.defensive) {
        inverseStrategy = CpuStrategy.offensive;
      }
      if (cpu.strategy == CpuStrategy.offensive) {
        inverseStrategy = CpuStrategy.defensive;
      }
      var targetValue = TargetValue(monster, cpu, inverseStrategy, cpu.level);

      return targetValue.value;
    }

    return 0;
  }
}

class TargetValue {
  int atk = 0;
  int hp = 0;
  int cost = 0;
  bool isMascot = false;
  bool canKO = false;
  bool isOnField = false;

  TargetValue(MonsterCard monster, CpuPlayer cpu, CpuStrategy? strategy,
      CpuLevels? level) {
    atk = monster.isActive ? monster.currentAttack : monster.attack;
    hp = monster.isActive ? monster.currentHealth : monster.health;
    isMascot = monster.isMascot;
    isOnField = monster.isActive;
    cost = monster.cost;
    canKO = monster.isActive ? CPU.canKnockOutMonster(monster, cpu) : false;

    level ??= cpu.level;
    strategy ??= cpu.strategy;

    calculateValue(level, strategy);
  }

  int value = 0;

  // 1/1;no mascot;1cost;cpu_defensive = 30;
  // 2/2;mascot;3cost;cpu_offensive = 80
  // 1/2;no mascot;2cost;cpu_balanced = 40
  calculateValue(CpuLevels level, CpuStrategy strategy) {
    value = 0;
    if (strategy == CpuStrategy.random) {
      value = Random().nextInt(100);
      return;
    }

    switch (strategy) {
      case CpuStrategy.defensive:
        value += (atk * 30) + (hp * 10);
        break;
      case CpuStrategy.offensive:
        value += (atk * 10) + (hp * 30);
        break;
      default:
        value += (atk * 20) + (hp * 20);
        break;
    }

    if (level == CpuLevels.easy) {
      return;
    }

    if (isMascot) {
      value += 30;
    }
    if (canKO) {
      value += 50;
    }

    //value for playing card from hand
    if (!isOnField) {
      value -= (cost * 10);
    }
    if (level == CpuLevels.medium) {
      return;
    }

    if (level == CpuLevels.hard) {
      return;
    }

    if (level == CpuLevels.expert) {
      return;
    }
  }
}
