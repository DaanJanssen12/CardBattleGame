import 'package:card_battle_game/models/card.dart';
import 'package:card_battle_game/models/cpu.dart';
import 'package:card_battle_game/models/monster_card.dart';
import 'package:card_battle_game/models/player.dart';
import 'package:card_battle_game/services/notification_service.dart';
import 'package:card_battle_game/services/sound_player_service.dart';
import 'package:flutter/material.dart';

class StageMatch {
  static int startWithCards = 2;
  int currentTurn = 1;
  bool playerHasTakenTurn = false;
  bool opponentHasTakenTurn = false;
  bool gameIsActive = false;
  SoundPlayerService soundPlayerService = SoundPlayerService();

  bool isPlayersTurn = false;
  Player player;
  CpuPlayer opponent;
  List<String> battleLog;
  Function updateGameState;
  Function playerDrawFunction;
  Function(bool playerWon) endMatch;
  BuildContext context;

  StageMatch(this.player, this.opponent, this.battleLog, this.updateGameState,
      this.playerDrawFunction, this.endMatch, this.context);

  Future<void> init() async {
    battleLog.add('Game Started');
    await player.startGame(battleLog, opponent);
    await opponent.startGame(battleLog, player);
    updateGameState();

    for (int i = 0; i < startWithCards; i++) {
      player.drawCard(battleLog);
      opponent.drawCard(battleLog);
      updateGameState();
    }
  }

  void setTurnPlayer(bool playerGoesFirst) {
    isPlayersTurn = playerGoesFirst;
  }

  void log(String msg) {
    battleLog.add(msg);
  }

  void start() {
    gameIsActive = true;
    startTurn();
  }

  Future<void> startTurn() async {
    battleLog.add('-');
    battleLog.add('TURN $currentTurn');
    battleLog.add(
        isPlayersTurn ? "${player.name}'s Turn" : "${opponent.name}'s Turn");
    if (isPlayersTurn) {
      await startPlayerTurn();
    } else {
      await startOpponentTurn();
    }
  }

  Future<void> startPlayerTurn() async {
    await player.startTurn(currentTurn, opponent, battleLog);
    updateGameState();
    if (player.canDraw()) {
      playerDrawFunction();
    } else {
      await NotificationService.showDialogMessage(
          context, "Your hand is full, you can't draw a card",
          title: "Can't draw");
    }
  }

  Future<void> endPlayerTurn() async {
    playerHasTakenTurn = true;
    player.endTurn();
    updateGameState();
    await nextTurn();
  }

  Future<void> startOpponentTurn() async {
    await Future.delayed(Duration(seconds: 1));
    opponent.startTurn(currentTurn, player, battleLog);
    opponent.drawCard(battleLog);
    updateGameState();
    await Future.delayed(Duration(seconds: 1));
    await CPU.executeTurn(opponent, player, updateGameState, battleLog, () {
      return !gameIsActive;
    });
    updateGameState();
    checkGameEnd();
    await Future.delayed(Duration(seconds: 1));
    endOpponentTurn();
    nextTurn();
  }

  Future<void> endOpponentTurn() async {
    opponentHasTakenTurn = true;
    opponent.endTurn();
    updateGameState();
  }

  Future<void> nextTurn() async {
    if (!gameIsActive) {
      return;
    }
    battleLog.add('-');
    if (playerHasTakenTurn && opponentHasTakenTurn) {
      currentTurn++;
      battleLog.add('TURN $currentTurn');
      battleLog.add('-');
    }
    isPlayersTurn = !isPlayersTurn;
    battleLog.add("${isPlayersTurn ? player.name : opponent.name}'s Turn");
    updateGameState();

    if (isPlayersTurn) {
      await startPlayerTurn();
    } else {
      await startOpponentTurn();
    }
  }

  Future<void> playCard(
      GameCard card, int monsterZoneIndex, BuildContext context) async {
    var canPlayCard = player.canPlayCard(card, monsterZoneIndex);
    if (canPlayCard.$1) {
      await player.playCard(card, monsterZoneIndex, battleLog, opponent);
      updateGameState();
      soundPlayerService.playDropSound();
    } else {
      NotificationService.showDialogMessage(context, canPlayCard.$2,
          title: "Can't play card!");
    }
  }

  Future<void> attackMonster(
      MonsterCard attackingMonster, int targetIndex) async {
    //soundPlayerService.playAttackSound();
    await player.attackOpponentMonster(attackingMonster, opponent,
        opponent.monsters[targetIndex]!, battleLog, updateGameState);
  }

  void handleAttackPlayerDirectly(MonsterCard attackingMonster) {
    if (!isPlayersTurn) {
      return;
    }

    attackingMonster.attackPlayer(opponent, battleLog);
    updateGameState();

    Future.sync(() async {
      await Future.delayed(Duration(milliseconds: 500));
    }).then((_) {
      checkGameEnd();
    });
  }

  void checkGameEnd() {
    //Prevent this function being called multiple times
    if (!gameIsActive) {
      return;
    }
    if (opponent.health <= 0) {
      gameIsActive = false;
      updateGameState();
      NotificationService.showDialogMessage(context, 'You won!',
          title: "Winner", callback: () async {
        Future.sync(() async {
          await Future.delayed(Duration(seconds: 1));
        }).then((_) {
          player.endGame(opponent);
          opponent.endGame(player);
          endMatch(true);
        });
      });
    }
    else if (player.health <= 0) {
      gameIsActive = false;
      updateGameState();
      NotificationService.showDialogMessage(context, 'You lost!',
          title: "Loser", callback: () async {
        Future.sync(() async {
          await Future.delayed(Duration(seconds: 1));
        }).then((_) {
          player.endGame(opponent);
          opponent.endGame(player);
          endMatch(false);
        });
      });
    }
  }
}
