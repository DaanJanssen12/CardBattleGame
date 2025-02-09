import 'dart:math';
import 'package:card_battle_game/models/card.dart';
import 'package:card_battle_game/models/card_database.dart';
import 'package:card_battle_game/models/player.dart';

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

enum CpuStrategy { random, defensive, offensive }

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
            await Future.delayed(Duration(seconds: 1));
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
    if (isGameOver()) {
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
        } else {
          var opponentMonsters =
              opponent.monsters.where((w) => w != null).toList();
          if (cpu.strategy == CpuStrategy.random) {
            //Attack a random opponent monster
            monster.doAttack(
                opponentMonsters[Random().nextInt(opponentMonsters.length)]!,
                battleLog);
          } else {
            //Attack the opponent monster with the least health
            var weakestMonster = opponentMonsters
                .reduce((a, b) => a!.currentHealth < b!.currentHealth ? a : b);
            monster.doAttack(weakestMonster!, battleLog);
          }
        }
        updateGameState();
        await Future.delayed(Duration(seconds: 1));
        if (isGameOver()) {
          return;
        }
      }
    }
  }
}
