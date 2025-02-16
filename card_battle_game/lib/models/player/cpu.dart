import 'dart:math';
import 'package:card_battle_game/models/cards/action_card.dart';
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

  CpuPlayer({required super.name}) {
    isCPU = true;
    level = CpuLevels.easy;
    strategy = CpuStrategy.random;
  }

  Future<void> executeTurn(Player opponent, Function updateGameState,
      List<String> battleLog, bool Function() isGameOver) async {
    await CPU.executeTurn(
        this, opponent, updateGameState, battleLog, isGameOver);
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
      bool Function() isGameOver) async {
    await playCardsFromHand(
        cpu, opponent, updateGameState, battleLog, isGameOver);
    await attackWithAllActiveMonsters(
        cpu, opponent, updateGameState, battleLog, isGameOver);
  }

  static Future<void> playCardsFromHand(
      CpuPlayer cpu,
      Player opponent,
      Function updateGameState,
      List<String> battleLog,
      bool Function() isGameOver) async {
    if (isGameOver()) {
      return;
    }
    switch (cpu.level) {
      case CpuLevels.easy:
        await cpuEasyPlayCardsFromHand(
            cpu, opponent, updateGameState, battleLog, isGameOver);
        break;
      case CpuLevels.medium:
        await cpuMediumPlayCardsFromHand(
            cpu, opponent, updateGameState, battleLog, isGameOver);
        break;
      default:
        await cpuEasyPlayCardsFromHand(
            cpu, opponent, updateGameState, battleLog, isGameOver);
        break;
    }
  }

  static Future<void> cpuEasyPlayCardsFromHand(
      CpuPlayer cpu,
      Player opponent,
      Function updateGameState,
      List<String> battleLog,
      bool Function() isGameOver) async {
    if (isGameOver()) {
      return;
    }
    // If the enemy has cards to play, play them.
    if (cpu.strategy == CpuStrategy.random) {
      cpu.hand.shuffle();
      for (var card in List.from(cpu.hand)) {
        for (var i = 0; i < 3; i++) {
          if (cpu.canPlayCard(card, i).$1) {
            await cpu.playCard(card, i, battleLog, opponent);
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
    }
    //Do 2 loops
    for (var x = 0; x < 2; x++) {
      if (cpu.strategy == CpuStrategy.offensive) {
        await playMonsterCards(
            cpu, opponent, updateGameState, battleLog, isGameOver);
        await playOtherCards(
            cpu, opponent, updateGameState, battleLog, isGameOver);
      }
      if (cpu.strategy == CpuStrategy.defensive) {
        await playOtherCards(
            cpu, opponent, updateGameState, battleLog, isGameOver);
        await playMonsterCards(
            cpu, opponent, updateGameState, battleLog, isGameOver);
      }
    }
  }

  static Future<void> cpuMediumPlayCardsFromHand(
      CpuPlayer cpu,
      Player opponent,
      Function updateGameState,
      List<String> battleLog,
      bool Function() isGameOver) async {
    if (isGameOver()) {
      return;
    }

    // **Step 1: Sort Hand by Priority**
    cpu.hand.sort((a, b) {
      int aPriority = getCardPriority(a, cpu);
      int bPriority = getCardPriority(b, cpu);
      return bPriority.compareTo(aPriority); // Higher priority first
    });

    // **Step 2: Play Cards in Order of Priority**
    for (var card in List.from(cpu.hand)) {
      for (var i = 0; i < 3; i++) {
        if (cpu.canPlayCard(card, i).$1) {
          await cpu.playCard(card, i, battleLog, opponent);
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
      bool Function() isGameOver) async {
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
            await cpu.playCard(monsterCard, i, battleLog, opponent);
            updateGameState();
            await Future.delayed(Duration(milliseconds: 500));
            //Played card, do not check the other spots
            break;
          }
        }
      }
    }
  }

  static Future<void> playOtherCards(
      CpuPlayer cpu,
      Player opponent,
      Function updateGameState,
      List<String> battleLog,
      bool Function() isGameOver) async {
    if (isGameOver()) {
      return;
    }
    var noneMonsterCards = cpu.hand.where((w) => !w.isMonster()).toList();
    noneMonsterCards.sort((a, b) {
      int aVal = getGameCardSortValue(a, cpu.strategy);
      int bVal = getGameCardSortValue(b, cpu.strategy);
      return aVal > bVal ? 1 : 0;
    });
    for (var gameCard in noneMonsterCards) {
      //Do a loop for every monster zone
      for (var i = 0; i < 3; i++) {
        //If card can be played > play it
        if (cpu.canPlayCard(gameCard, i).$1) {
          await cpu.playCard(gameCard, i, battleLog, opponent);
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
      bool Function() isGameOver) async {
    if (isGameOver() || opponent.health == 0) {
      return;
    }

    switch (cpu.level) {
      case CpuLevels.easy:
        await cpuEasyAttackWithAllActiveMonsters(
            cpu, opponent, updateGameState, battleLog, isGameOver);
        break;
      case CpuLevels.medium:
        await cpuMediumAttackWithAllActiveMonsters(
            cpu, opponent, updateGameState, battleLog, isGameOver);
        break;
      default:
        await cpuEasyAttackWithAllActiveMonsters(
            cpu, opponent, updateGameState, battleLog, isGameOver);
        break;
    }
  }

  static Future<void> cpuEasyAttackWithAllActiveMonsters(
      CpuPlayer cpu,
      Player opponent,
      Function updateGameState,
      List<String> battleLog,
      bool Function() isGameOver) async {
    if (isGameOver() || opponent.health == 0) {
      return;
    }
    for (var monster in cpu.monsters) {
      //No monster in spot so no attack
      if (monster == null) {
        continue;
      }

      //Monster can attack?
      if (monster.canAttack()) {
        //Opponent has no active monsters > attack player directly
        if (opponent.monsters.isEmpty ||
            !opponent.monsters.any((w) => w != null)) {
          monster.attackPlayer(opponent, battleLog);
          if (opponent.health == 0) {
            return;
          }
        } else {
          var opponentMonsters =
              opponent.monsters.where((w) => w != null).toList();
          if (cpu.strategy == CpuStrategy.random) {
            //Attack a random opponent monster
            await cpu.attackOpponentMonster(
                monster,
                opponent,
                opponentMonsters[Random().nextInt(opponentMonsters.length)]!,
                battleLog,
                updateGameState);
          } else {
            //Attack the opponent monster with the least health
            var weakestMonster = opponentMonsters
                .reduce((a, b) => a!.currentHealth < b!.currentHealth ? a : b);
            await cpu.attackOpponentMonster(
                monster, opponent, weakestMonster!, battleLog, updateGameState);
          }
        }
        updateGameState();
        await Future.delayed(Duration(milliseconds: 500));
        if (isGameOver()) {
          return;
        }
      }
    }
  }

  static Future<void> cpuMediumAttackWithAllActiveMonsters(
      CpuPlayer cpu,
      Player opponent,
      Function updateGameState,
      List<String> battleLog,
      bool Function() isGameOver) async {
    if (isGameOver() || opponent.health == 0) {
      return;
    }

    List<MonsterCard> activeMonsters =
        cpu.monsters.where((m) => m != null).map((m) => m!).toList();
    List<MonsterCard> opponentMonsters =
        opponent.monsters.where((m) => m != null).map((m) => m!).toList();

    bool isAggressive = cpu.strategy == CpuStrategy.offensive;
    bool isDefensive = cpu.strategy == CpuStrategy.defensive;

    for (var monster in activeMonsters) {
      if (!monster.canAttack()) continue;

      opponentMonsters =
          opponent.monsters.where((m) => m != null).map((m) => m!).toList();
      // Opponent has no monsters? Attack player directly!
      if (opponentMonsters.isEmpty) {
        monster.attackPlayer(opponent, battleLog);
        updateGameState();
        await Future.delayed(Duration(milliseconds: 500));
        if (isGameOver()) return;
        continue;
      }

      // Opponent has monsters, so attack one of them based on strategy
      MonsterCard target;

      if (isAggressive) {
        // Try to finish off a low-HP enemy first
        MonsterCard? killableTarget;
        if (opponentMonsters
            .any((enemy) => enemy.currentHealth <= monster.attack)) {
          opponentMonsters
              .firstWhere((enemy) => enemy.currentHealth <= monster.attack);
        }

        target = killableTarget ??
            opponentMonsters.reduce((a, b) => a.attack > b.attack
                ? a
                : b); // Otherwise, hit the strongest enemy
      } else if (isDefensive) {
        // Focus on the strongest enemy first
        target = opponentMonsters
            .reduce((a, b) => a.currentHealth > b.currentHealth ? a : b);
      } else {
        // Balanced: Attack the weakest enemy
        target = opponentMonsters
            .reduce((a, b) => a.currentHealth < b.currentHealth ? a : b);
      }

      await cpu.attackOpponentMonster(
          monster, opponent, target, battleLog, updateGameState);

      updateGameState();
      await Future.delayed(Duration(milliseconds: 500));
      if (isGameOver()) return;
    }
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
      int attackValue = card.toMonster().attack;
      int basePrio = 50 + (attackValue * 5); // Adjust base priority

      // Reduce priority for very weak monsters (attack 1-2)
      if (attackValue <= 2) basePrio -= 10;

      // Aggressive CPUs push monster priority higher
      if (isAggressive) return basePrio + 10;

      // Defensive CPUs hesitate to play monsters unless they have defenses
      if (isDefensive) return basePrio - 10;

      return basePrio; // Balanced CPU gets normal priority
    }

    return 0; // Unknown cards get lowest priority
  }
}
