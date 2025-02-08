import 'dart:math';

import 'package:card_battle_game/models/card.dart';
import 'package:card_battle_game/models/player.dart';

class CpuPlayer extends Player {
  late bool isCPU;
  late CpuLevels level;
  late CpuStrategy strategy;

  CpuPlayer({required super.name}) {
    isCPU = true;
    level = CpuLevels.easy;
    strategy = CpuStrategy.random;
  }

  Future<void> executeTurn(Player opponent, Function updateGameState) async {
    await CPU.executeTurn(this, opponent, updateGameState);
  }
}

enum CpuLevels { easy, medium, hard, expert }

enum CpuStrategy { random, defensive, offensive }

class CPU {
  static Future<void> executeTurn(
      CpuPlayer cpu, Player opponent, Function updateGameState) async {
    await playCardsFromHand(cpu, opponent, updateGameState);
    await attackWithAllActiveMonsters(cpu, opponent, updateGameState);
  }

  static Future<void> playCardsFromHand(
      CpuPlayer cpu, Player opponent, Function updateGameState) async {
    // If the enemy has cards to play, play them.
    if (cpu.strategy == CpuStrategy.random) {
      cpu.hand.shuffle();
      for (var card in List.from(cpu.hand)) {
        for (var i = 0; i < 3; i++) {
          if (cpu.canPlayCard(card, i).$1) {
            cpu.playCard(card, i);
            updateGameState();
            await Future.delayed(Duration(seconds: 1));
          }
        }
      }
    }
    //Do 2 loops
    for (var x = 0; x < 2; x++) {
      if (cpu.strategy == CpuStrategy.offensive) {
        await playMonsterCards(cpu, opponent, updateGameState);
        await playOtherCards(cpu, opponent, updateGameState);
      }
      if (cpu.strategy == CpuStrategy.defensive) {
        await playOtherCards(cpu, opponent, updateGameState);
        await playMonsterCards(cpu, opponent, updateGameState);
      }
    }
  }

  static Future<void> playMonsterCards(
      CpuPlayer cpu, Player opponent, Function updateGameState) async {
    //Open monster zones ?
    if (cpu.monsters.any((a) => a == null)) {
      for (var monsterCard in cpu.hand.where((w) => w.isMonster())) {
        //Do a loop for every monster zone
        for (var i = 0; i < 3; i++) {
          //If monster can be played > play it
          if (cpu.canPlayCard(monsterCard, i).$1) {
            cpu.playCard(monsterCard, i);
            updateGameState();
            await Future.delayed(Duration(seconds: 1));
          }
        }
      }
    }
  }

  static Future<void> playOtherCards(
      CpuPlayer cpu, Player opponent, Function updateGameState) async {
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
          cpu.playCard(gameCard, i);
          updateGameState();
          await Future.delayed(Duration(seconds: 1));
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
          case UpgradeCardType.heal:
            return 0;
        }
      }
      if (gameCard.isAction()) {
        switch ((gameCard as ActionCard).actionCardType) {
          case ActionCardType.draw:
            return 10;
        }
      }
    }
    if (strategy == CpuStrategy.defensive) {
      if (gameCard.isUpgrade()) {
        switch ((gameCard as UpgradeCard).upgradeCardType) {
          case UpgradeCardType.boostAtk:
            return 0;
          case UpgradeCardType.heal:
            return 100;
        }
      }
      if (gameCard.isAction()) {
        switch ((gameCard as ActionCard).actionCardType) {
          case ActionCardType.draw:
            return 10;
        }
      }
    }

    return 0;
  }

  static Future<void> attackWithAllActiveMonsters(
      CpuPlayer cpu, Player opponent, Function updateGameState) async {
    for (var monster in List.from(cpu.monsters)) {
      //No monster in spot so no attack
      if (monster == null) {
        continue;
      }

      //Monster can attack?
      if (monster.canAttack()) {
        //Opponent has no active monsters > attack player directly
        if (opponent.monsters.isEmpty ||
            !opponent.monsters.any((w) => w != null)) {
          monster.attackPlayer(opponent);
        } else {
          var opponentMonsters =
              opponent.monsters.where((w) => w != null).toList();
          if (cpu.strategy == CpuStrategy.random) {
            //Attack a random opponent monster
            monster.doAttack(
                opponentMonsters[Random().nextInt(opponentMonsters.length)]);
          } else {
            //Attack the opponent monster with the least health
            var weakestMonster = opponentMonsters
                .reduce((a, b) => a!.currentHealth < b!.currentHealth ? a : b);
            monster.doAttack(weakestMonster);
          }
        }
        updateGameState();
        await Future.delayed(Duration(seconds: 1));
      }
    }
  }
}
