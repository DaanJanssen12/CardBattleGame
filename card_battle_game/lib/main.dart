import 'package:card_battle_game/models/card.dart';
import 'package:card_battle_game/models/player.dart';
import 'package:card_battle_game/services/notification_service.dart';
import 'package:card_battle_game/services/sound_player_service.dart';
import 'package:card_battle_game/widgets/card_details_dialog.dart';
import 'package:card_battle_game/widgets/game_board_widget.dart';
import 'package:card_battle_game/widgets/player_hand_widget.dart';
import 'package:card_battle_game/widgets/player_info_widget.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(CardBattleGame());
}

class CardBattleGame extends StatelessWidget {
  const CardBattleGame({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: GameScreen(),
    );
  }
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  _GameScreenState createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  Player player = Player(name: 'Player');
  Player enemy = Player(name: 'Enemy');
  bool playerTurn = true;
  String message = "";
  GameCard? selectedCard;
  SoundPlayerService soundPlayerService = SoundPlayerService();

  @override
  void initState() {
    super.initState();
    player.initDeck();
    enemy.initDeck();
    initGame();
  }

  void initGame() {
    setState(() {
      player.drawCard(3);
      enemy.drawCard(3);
    });

    nextTurn();
  }

  void nextTurn() async {
    setState(() {
      playerTurn = !playerTurn;
      message = playerTurn ? "Player's Turn" : "Enemy's Turn";
    });

    if (playerTurn) {
      startPlayerTurn(player);
    } else {
      await enemyTurn(enemy);
    }
  }

  void startPlayerTurn(Player player) {
    setState(() {
      player.startTurn();
    });
  }

  Future<void> enemyTurn(Player enemy) async {
    setState(() {
      enemy.startTurn();
    });
    await CPU.executeTurn(enemy, () {
      setState(() {});
    });
    setState(() {});
    nextTurn(); // Continue to the next turn
  }

  void playCard(GameCard card, int monsterZoneIndex) {
    var canPlayCard = player.canPlayCard(card, monsterZoneIndex);
    if (canPlayCard.$1) {
      setState(() {
        player.playCard(card, monsterZoneIndex);
      });
      soundPlayerService.playDropSound();
    } else {
      NotificationService.showDialogMessage(context, canPlayCard.$2,
          title: "Can't play card!");
    }
  }

  void showCardDetails(GameCard card) {
    setState(() {
      selectedCard = card; // Update the selected card
    });

    // Open the dialog
    showDialog(
      context: context,
      barrierDismissible: true, // Allows dismiss by tapping outside
      builder: (BuildContext context) {
        return CardDetailsDialog(card: card);
      },
    );
  }

  // Handle the attack by dragging a monster card to an enemy monster zone
  void attackMonster(
      MonsterCard attackingMonster, Player enemy, int targetIndex) {
    setState(() {
      attackingMonster.doAttack(enemy.monsters[targetIndex]!);
      //soundPlayerService.playAttackSound();
    });
    Future.sync(() async {
      await Future.delayed(Duration(seconds: 1));
    }).then((_) {
      checkForFaintedMonsters(player);
      checkForFaintedMonsters(enemy);
    });
  }

  void checkForFaintedMonsters(Player _player) {
    for (var monster in _player.monsters.where((w) => w != null)) {
      if (monster!.currentHealth <= 0) {
        setState(() {
          _player.faintMonster(monster);
        });
      }
    }
  }

  void handleAttackPlayerDirectly(
      Player attackedPlayer, MonsterCard attackingMonster) {
    setState(() {
      attackingMonster.attackPlayer(attackedPlayer);
    });

    Future.sync(() async {
      await Future.delayed(Duration(seconds: 1));
    }).then((_) {
      checkGameEnd();
    });
  }

  void checkGameEnd() {
    if (enemy.health <= 0) {
      NotificationService.showDialogMessage(context, 'You won!',
          title: "Winner");
    }
    if (player.health <= 0) {
      NotificationService.showDialogMessage(context, 'You lost!',
          title: "Loser");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Card Battle Game', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        actions: [
          // End Turn Button: Positioned at the top-right of the app bar
          TextButton(
            onPressed: playerTurn
                ? nextTurn
                : null, // Disable when it's the enemy's turn
            child: Text(
              'End Turn',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: TextButton.styleFrom(
              backgroundColor: playerTurn
                  ? Colors.green
                  : Colors.grey, // Green when active, grey when inactive
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(
                'assets/images/background.jpg'), // Path to your background image
            fit: BoxFit.cover, // Makes sure the image covers the entire screen
          ),
        ),
        child: Stack(
          children: [
            // Main content of the game
            Column(
              children: [
                // Player Info in a fixed Top Bar
                Container(
                  height: 125,
                  padding: EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                          child: PlayerInfoWidget(
                              player: player,
                              isActive: playerTurn,
                              handleAttackPlayerDirectly: null)),
                      SizedBox(width: 16),
                      Expanded(
                          child: PlayerInfoWidget(
                              player: enemy,
                              isActive: !playerTurn,
                              handleAttackPlayerDirectly:
                                  handleAttackPlayerDirectly)),
                    ],
                  ),
                ),
                SizedBox(height: 12),
                // Game Board
                GameBoardWidget(
                    player: player,
                    enemy: enemy,
                    onCardDrop: playCard,
                    onCardTap: showCardDetails,
                    onMonsterAttack: attackMonster),
              ],
            ),
            // Player's Hand at the bottom of the screen
            Positioned(
              bottom: 0, // Fixes the hand at the bottom
              left: 0,
              right: 0,
              child: Container(
                color: Colors
                    .grey[200], // Adding visual separation for the player hand
                child: PlayerHandWidget(
                    player: player, onCardTap: showCardDetails),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
