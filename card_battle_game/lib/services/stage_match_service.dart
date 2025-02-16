import 'package:card_battle_game/models/cards/card.dart';
import 'package:card_battle_game/models/cards/play_card_result.dart';
import 'package:card_battle_game/models/constants.dart';
import 'package:card_battle_game/models/database/user_storage.dart';
import 'package:card_battle_game/models/game/stage_match.dart';
import 'package:card_battle_game/models/player/cpu.dart';
import 'package:card_battle_game/models/player/player.dart';
import 'package:card_battle_game/screens/main_menu.dart';
import 'package:card_battle_game/screens/stage_selection_screen.dart';
import 'package:card_battle_game/widgets/card_details_dialog.dart';
import 'package:card_battle_game/widgets/card_widget.dart';
import 'package:card_battle_game/widgets/coin_flip_widget.dart';
import 'package:flutter/material.dart';

class StageMatchService {
  late StageMatch match;
  UserData userData;
  BuildContext context;
  Function updateGameState;

  StageMatchService(this.context, this.userData, this.updateGameState);

  Future<void> initGame(Player player, CpuPlayer opponent) async {
    match = StageMatch(player, opponent, [], updateGameState, showDeckOverlay,
        endGame, context);
    await match.init();
    showCoinFlipDialog();
  }

  void endGame(bool playerWon) {
    if (!playerWon) {
      userData.activeGame!.endGame();
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
          if (isPlayerFirst) {
            match.log('${match.player.name} won the coin toss');
          } else {
            match.log('${match.opponent.name} won the coin toss');
          }
          updateGameState();
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
    var result = await match.playCard(card, monsterZoneIndex, context);
    if (result != null) {
      switch (result.type) {
        case PlayCardResultType.showOpponentHand:
          showCards(match.opponent.hand, "Opponent's hand", true, 5);
          break;
        case PlayCardResultType.endTurn:
          await match.endPlayerTurn();
          break;
      }
    }
  }

  void toStageSelection() {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => StageSelectionScreen(userData: userData)),
    );
  }

  void toMainMenu() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => MainMenu(userData: userData)),
    );
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
                          List<GameCard> gameCards = match.player.drawCards(
                              Constants.drawCardsPerTurn, match.battleLog);
                          Navigator.of(context).pop(); // Close overlay
                          showCards(
                              gameCards,
                              gameCards.isNotEmpty
                                  ? "You Drew:"
                                  : "No cards to draw",
                              false,
                              750);
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

  void showCards(List<GameCard> cards, String title, bool isDismissable,
      int closeAfterMilliseconds) {
    showDialog(
      context: context,
      barrierDismissible: isDismissable, // Don't allow closing mid-animation
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.transparent,
          contentPadding: EdgeInsets.zero,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (cards.isNotEmpty) ...[
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                for (int i = 0; i < (cards.length / 2).ceil(); i++) ...[
                  SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 120,
                        height: 200,
                        child: CardWidget(card: cards[i * 2]),
                      ),
                      SizedBox(width: 10),
                      if (((i * 2) + 1) < cards.length) ...[
                        SizedBox(
                          width: 120,
                          height: 200,
                          child: CardWidget(card: cards[(i * 2) + 1]),
                        ),
                      ]
                    ],
                  )
                ]
              ] else ...[
                Text(
                  title,
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

    if (!isDismissable) {
      Future.delayed(Duration(milliseconds: closeAfterMilliseconds), () {
        Navigator.of(context).pop();
        updateGameState();
      });
    }
  }
}
