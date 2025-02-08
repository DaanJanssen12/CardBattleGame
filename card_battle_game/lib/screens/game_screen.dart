import 'package:card_battle_game/models/card.dart';
import 'package:card_battle_game/models/cpu.dart';
import 'package:card_battle_game/models/player.dart';
import 'package:card_battle_game/models/user_storage.dart';
import 'package:card_battle_game/screens/main_menu.dart';
import 'package:card_battle_game/screens/stage_selection_screen.dart';
import 'package:card_battle_game/services/notification_service.dart';
import 'package:card_battle_game/services/sound_player_service.dart';
import 'package:card_battle_game/widgets/card_details_dialog.dart';
import 'package:card_battle_game/widgets/card_widget.dart';
import 'package:card_battle_game/widgets/coin_flip_widget.dart';
import 'package:card_battle_game/widgets/game_board_widget.dart';
import 'package:card_battle_game/widgets/player_hand_widget.dart';
import 'package:card_battle_game/widgets/player_info_widget.dart';
import 'package:flutter/material.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key, required this.userData});
  final UserData userData;

  @override
  _GameScreenState createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  bool _isLoading = true;
  Player player = Player(name: 'Player');
  CpuPlayer enemy = CpuPlayer(name: 'Enemy');
  bool playerTurn = true;
  String message = "";
  GameCard? selectedCard;
  SoundPlayerService soundPlayerService = SoundPlayerService();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    player = widget.userData.activeGame!.player;
    enemy = await widget.userData.activeGame!.initCPU();
    setState(() {
      _isLoading = false;
    });
    await initGame();
  }

  Future<void> initGame() async {
    await player.startGame();
    await enemy.startGame();
    setState(() {});
    showCoinFlipDialog();
  }

  void showCoinFlipDialog() async {
    showDialog(
      context: context,
      barrierDismissible:
          false, // Prevent closing before the animation finishes
      builder: (BuildContext context) {
        return CoinFlipWidget(onFlipComplete: (bool isPlayerFirst) async {
          setState(() {
            playerTurn = isPlayerFirst;
            message = playerTurn ? "Player starts!" : "Enemy starts!";
          });

          // Proceed with normal game initialization
          setState(() {
            player.drawCard();
            player.drawCard();
            enemy.drawCard();
            enemy.drawCard();
          });

          if (playerTurn) {
            startPlayerTurn(player);
          } else {
            await enemyTurn(enemy);
          }
        });
      },
    );
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

    showDeckOverlay();
  }

  Future<void> enemyTurn(CpuPlayer enemy) async {
    await Future.delayed(Duration(seconds: 1));
    setState(() {
      enemy.startTurn();
      enemy.drawCard();
    });
    await Future.delayed(Duration(seconds: 1));
    await CPU.executeTurn(enemy, player, () {
      setState(() {
        checkForFaintedMonsters(player);
        checkForFaintedMonsters(enemy);
        checkGameEnd();
      });
    });
    setState(() {});
    await Future.delayed(Duration(seconds: 1));
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

  void checkForFaintedMonsters(Player player) {
    for (var monster in player.monsters.where((w) => w != null)) {
      if (monster!.currentHealth <= 0) {
        setState(() {
          player.faintMonster(monster.monsterZoneIndex!);
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
      player.endGame();
      enemy.endGame();
      NotificationService.showDialogMessage(context, 'You won!',
          title: "Winner", callback: () async {
        Future.sync(() async {
          await Future.delayed(Duration(seconds: 1));
        }).then((_) {
          toStageSelection();
        });
      });
    }
    if (player.health <= 0) {
      player.endGame();
      enemy.endGame();
      NotificationService.showDialogMessage(context, 'You lost!',
          title: "Loser", callback: () async {
        Future.sync(() async {
          await Future.delayed(Duration(seconds: 1));
        }).then((_) {
          toMainMenu();
        });
      });
    }
  }

  void toStageSelection() {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) =>
              StageSelectionScreen(userData: widget.userData)),
    );
  }

  void toMainMenu() {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => MainMenu(userData: widget.userData)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
        canPop: false,
        child: Scaffold(
          appBar: AppBar(
            title: Text('Stage ${widget.userData.activeGame!.stage}',
                style: TextStyle(color: Colors.white)),
            backgroundColor: Colors.black,
            actions: [
              // End Turn Button: Positioned at the top-right of the app bar
              TextButton(
                onPressed: playerTurn ? nextTurn : null,
                style: TextButton.styleFrom(
                  backgroundColor: playerTurn
                      ? Colors.green
                      : Colors.grey, // Green when active, grey when inactive
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ), // Disable when it's the enemy's turn
                child: Text(
                  'End Turn',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
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
                fit: BoxFit
                    .cover, // Makes sure the image covers the entire screen
              ),
            ),
            child: _isLoading
                ? CircularProgressIndicator()
                : Stack(
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
                          color: Colors.grey[
                              200], // Adding visual separation for the player hand
                          child: PlayerHandWidget(
                              player: player, onCardTap: showCardDetails),
                        ),
                      ),
                    ],
                  ),
          ),
        ));
  }

  void showDeckOverlay() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.8, // 80% screen width
            height:
                MediaQuery.of(context).size.height * 0.5, // 50% screen height
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.85),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Background
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                // Content
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min, // Prevent infinite height
                    children: [
                      Text(
                        "Your turn",
                        style: TextStyle(color: Colors.white, fontSize: 24),
                      ),
                      Text(
                        "Tap to Draw a Card",
                        style: TextStyle(color: Colors.white, fontSize: 20),
                      ),
                      const SizedBox(height: 16),

                      // Deck Image (Tappable)
                      GestureDetector(
                        onTap: () {
                          GameCard? gameCard;
                          setState(() {
                            gameCard = player.drawCard();
                          });
                          Navigator.of(context).pop(); // Close overlay
                          showDrawnCardAnimation(gameCard!);
                        },
                        child: SizedBox(
                          width: 120, // Ensures finite size
                          height: 160,
                          child: Stack(
                            children: List.generate(
                              2,
                              (index) => Positioned(
                                top: index * 2.0,
                                left: 0,
                                right: 0,
                                child: Image.asset(
                                  'assets/images/card_back.png',
                                  width: 120, // Must be fixed
                                  height: 160, // Must be fixed
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void showDrawnCardAnimation(GameCard drawnCard) {
    showDialog(
      context: context,
      barrierDismissible: false, // Don't allow closing mid-animation
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.transparent,
          contentPadding: EdgeInsets.zero,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "You Drew:",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 12),
              SizedBox(
                width: 120,
                height: 200,
                child: CardWidget(card: drawnCard),
              )
            ],
          ),
        );
      },
    );

    Future.delayed(Duration(seconds: 1), () {
      Navigator.of(context).pop();
      setState(() {});
    });
  }
}
