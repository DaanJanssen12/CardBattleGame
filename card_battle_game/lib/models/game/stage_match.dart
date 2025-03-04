import 'package:card_battle_game/models/cards/card.dart';
import 'package:card_battle_game/models/cards/play_card_result.dart';
import 'package:card_battle_game/models/constants.dart';
import 'package:card_battle_game/models/player/cpu.dart';
import 'package:card_battle_game/models/cards/monster_card.dart';
import 'package:card_battle_game/models/player/player.dart';
import 'package:card_battle_game/services/notification_service.dart';
import 'package:card_battle_game/services/sound_player_service.dart';
import 'package:flutter/material.dart';

class StageMatch {
  int currentTurn = 1;
  bool playerHasTakenTurn = false;
  bool opponentHasTakenTurn = false;
  bool gameIsActive = false;
  bool gameIsInOvertime = false;
  SoundPlayerService soundPlayerService = SoundPlayerService();

  bool isPlayersTurn = false;
  Player player;
  CpuPlayer opponent;
  List<String> battleLog;
  Function updateGameState;
  Function playerDrawFunction;
  Function(bool playerWon, Player beatenPlayer) endMatch;
  BuildContext context;
  bool isBossBattle = false;

  StageMatch(this.player, this.opponent, this.battleLog, this.updateGameState,
      this.playerDrawFunction, this.endMatch, this.context);

  Future<void> init() async {
    battleLog.add('Game Started');
    await player.startGame(battleLog, opponent);
    await opponent.startGame(battleLog, player);
    opponent.setGameBuildContext(context);
    updateGameState();

    for (int i = 0; i < Constants.startWithCardsInHand; i++) {
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
    startGame();
  }

  Future<void> startGame() async {
    playerHasTakenTurn = false;
    opponentHasTakenTurn = false;
    battleLog.add('-');
    battleLog.add('TURN $currentTurn');
    battleLog.add('-');
    battleLog.add(
        isPlayersTurn ? "${player.name}'s Turn" : "${opponent.name}'s Turn");
    if (isPlayersTurn) {
      await startPlayerTurn(isFirstTurn: true);
    } else {
      await startOpponentTurn(isFirstTurn: true);
    }
  }

  Future<void> startPlayerTurn({bool isFirstTurn = false}) async {
    await player.startTurn(currentTurn, opponent, battleLog);
    updateGameState();
    if (isFirstTurn) {
      await NotificationService.showDialogMessage(
          context, "You're up first, good luck!",
          title: "Game started!");
    } else if (player.canDraw()) {
      playerDrawFunction();
      updateGameState();
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

  Future<void> startOpponentTurn({bool isFirstTurn = false}) async {
    await Future.delayed(Duration(seconds: 1));
    opponent.startTurn(currentTurn, player, battleLog);
    if (!isFirstTurn) {
      opponent.drawCards(Constants.drawCardsPerTurn, battleLog);
      await Future.delayed(Duration(seconds: 1));
    }
    opponent.isMyTurn = true;
    await CPU.executeTurn(opponent, player, updateGameState, battleLog, () {
      return !gameIsActive;
    }, gameIsInOvertime);
    opponent.isMyTurn = false;
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
      playerHasTakenTurn = false;
      opponentHasTakenTurn = false;

      if (currentTurn == 10) {
        gameIsInOvertime = true;
        player.setGameOvertime();
        opponent.setGameOvertime();
        await NotificationService.showDialogMessage(context,
            "The game is in overtime now, all monsters can attack twice every turn.",
            title: "Overtime!");
      }
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

  Future<PlayCardResult?> playCard(
      GameCard card, int monsterZoneIndex, BuildContext context) async {
    PlayCardResult? result;
    var canPlayCard = player.canPlayCard(card, monsterZoneIndex);
    if (canPlayCard.$1) {
      result = await player.playCard(
          card, monsterZoneIndex, battleLog, opponent, gameIsInOvertime);
      updateGameState();
      soundPlayerService.playSound(context, Sounds.dropCard);
    } else {
      NotificationService.showDialogMessage(context, canPlayCard.$2,
          title: "Can't play card!");
    }
    return result;
  }

  Future<void> attackMonster(
      MonsterCard attackingMonster, int targetIndex) async {
    //soundPlayerService.playAttackSound();
    var targetMonster = opponent.monsters[targetIndex]!;
    await player.attackOpponentMonster(attackingMonster, opponent,
        targetMonster, battleLog, updateGameState, gameIsInOvertime);
  }

  void handleAttackPlayerDirectly(MonsterCard attackingMonster) {
    if (!isPlayersTurn) {
      return;
    }

    opponent.isBeingAttacked = true;
    attackingMonster.attackPlayer(opponent, battleLog, gameIsInOvertime);
    updateGameState();

    Future.sync(() async {
      await Future.delayed(Duration(milliseconds: 500));
    }).then((_) {
      checkGameEnd();
      opponent.isBeingAttacked = false;
      updateGameState();
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
          opponent.endGame(player);
          player.endGame(opponent);
          endMatch(true, opponent);
        });
      });
    } else if (player.health <= 0) {
      gameIsActive = false;
      updateGameState();
      NotificationService.showDialogMessage(context, 'You lost!',
          title: "Loser", callback: () async {
        Future.sync(() async {
          await Future.delayed(Duration(seconds: 1));
        }).then((_) {
          opponent.endGame(player);
          player.endGame(opponent);
          endMatch(false, opponent);
        });
      });
    }
  }
}
