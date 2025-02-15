import 'package:card_battle_game/models/card.dart';
import 'package:card_battle_game/models/constants.dart';
import 'package:card_battle_game/models/cpu.dart';
import 'package:card_battle_game/models/player.dart';
import 'package:card_battle_game/models/stage_match.dart';
import 'package:card_battle_game/models/user_storage.dart';
import 'package:card_battle_game/screens/main_menu.dart';
import 'package:card_battle_game/screens/stage_selection_screen.dart';
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
  late StageMatch match;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    var player = widget.userData.activeGame!.player;
    var opponent = await widget.userData.activeGame!.initCPU();
    setState(() {
      _isLoading = false;
    });
    await initGame(player, opponent);
  }

  Future<void> initGame(Player player, CpuPlayer opponent) async {
    match = StageMatch(player, opponent, [], () => {setState(() {})},
        showDeckOverlay, endGame, context);
    await match.init();
    showCoinFlipDialog();
  }

  void endGame(bool playerWon) {
    if (!playerWon) {
      widget.userData.activeGame!.playerHasLost = true;
    }
    toStageSelection();
  }

  void showBattleLog() async {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          title:
              Text("Battle Log", style: TextStyle(fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: match.battleLog.length,
                    itemBuilder: (context, index) {
                      return match.battleLog[index] == '-'
                          ? Padding(
                              padding: EdgeInsets.symmetric(vertical: 4),
                              child: Divider(
                                color: Colors.blueGrey,
                                thickness: 2,
                              ),
                            )
                          : Card(
                              elevation: 2,
                              margin: EdgeInsets.symmetric(vertical: 4),
                              child: Padding(
                                  padding: EdgeInsets.all(8),
                                  child: Text(
                                    match.battleLog[index],
                                    style: TextStyle(fontSize: 16),
                                  )),
                            );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("Close"),
            ),
          ],
        );
      },
    );
  }

  void showCoinFlipDialog() async {
    showDialog(
      context: context,
      barrierDismissible:
          false, // Prevent closing before the animation finishes
      builder: (BuildContext context) {
        return CoinFlipWidget(onFlipComplete: (bool isPlayerFirst) async {
          setState(() {
            if (isPlayerFirst) {
              match.log('${match.player.name} won the coin toss');
            } else {
              match.log('${match.opponent.name} won the coin toss');
            }
          });
          match.setTurnPlayer(isPlayerFirst);
          match.start();
        });
      },
    );
  }

  void showCardDetails(GameCard card) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return CardDetailsDialog(card: card);
      },
    );
  }

  void playCard(GameCard card, int monsterZoneIndex) async {
    await match.playCard(card, monsterZoneIndex, context);
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
              TextButton(
                onPressed: showBattleLog, // Disable when it's the enemy's turn
                child: Text(
                  'Log',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // End Turn Button: Positioned at the top-right of the app bar
              TextButton(
                onPressed: match.isPlayersTurn ? match.endPlayerTurn : null,
                style: TextButton.styleFrom(
                  backgroundColor: match.isPlayersTurn
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
                    'assets/images/${widget.userData.background}'), // Path to your background image
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
                                        player: match.player,
                                        isActive: match.isPlayersTurn,
                                        handleAttackPlayerDirectly: null)),
                                SizedBox(width: 16),
                                Expanded(
                                    child: PlayerInfoWidget(
                                        player: match.opponent,
                                        isActive: !match.isPlayersTurn,
                                        handleAttackPlayerDirectly:
                                            match.handleAttackPlayerDirectly)),
                              ],
                            ),
                          ),
                          SizedBox(height: 12),
                          // Game Board
                          GameBoardWidget(
                              player: match.player,
                              enemy: match.opponent,
                              isPlayersTurn: match.isPlayersTurn,
                              onCardDrop: playCard,
                              onCardTap: showCardDetails,
                              onMonsterAttack: match.attackMonster),
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
                              player: match.player, onCardTap: showCardDetails),
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
      barrierDismissible: false,
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
                        "Tap to Draw your Cards",
                        style: TextStyle(color: Colors.white, fontSize: 20),
                      ),
                      const SizedBox(height: 16),

                      // Deck Image (Tappable)
                      GestureDetector(
                        onTap: () {
                          List<GameCard> gameCards = [];
                          setState(() {
                            gameCards = match.player.drawCards(Constants.drawCardsPerTurn, match.battleLog);
                          });
                          Navigator.of(context).pop(); // Close overlay
                          showDrawnCardAnimation(gameCards);
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

  void showDrawnCardAnimation(List<GameCard> drawnCards) {
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
              if (drawnCards.isNotEmpty) ...[
                Text(
                  "You Drew:",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    for (var card in drawnCards) ...[
                      SizedBox(
                        width: 120,
                        height: 200,
                        child: CardWidget(card: card),
                      ),
                      SizedBox(width: 10),
                    ]
                  ],
                )
              ] else ...[
                Text(
                  "No cards to draw",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ]
            ],
          ),
        );
      },
    );

    Future.delayed(Duration(milliseconds: 750), () {
      Navigator.of(context).pop();
      setState(() {});
    });
  }
}
