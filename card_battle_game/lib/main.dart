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
      drawCard(player, 3);
      drawCard(enemy, 3);
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
      drawCard(player, 1);
    });
  }

  Future<void> enemyTurn(Player enemy) async {
    print('Enemy turn');
    drawCard(enemy, 1);
    await CPU.executeTurn(enemy, () {
      setState(() {});
    });
    setState(() {});
    nextTurn(); // Continue to the next turn
  }

  void drawCard(Player player, int amount) {
    for (int i = 0; i < amount; i++) {
      if (player.deck.isEmpty) shuffleDiscardPile(player);
      if (player.deck.isNotEmpty) player.hand.add(player.deck.removeAt(0));
    }
  }

  void shuffleDiscardPile(Player player) {
    player.deck.addAll(player.discardPile);
    player.discardPile.clear();
    player.deck.shuffle();
  }

  void playCard(GameCard card, int monsterZoneIndex) {
    var canPlayCard = player.canPlayCard(card, monsterZoneIndex);
    if (canPlayCard.$1) {
      setState(() {
        player.playCard(card, monsterZoneIndex);
      });
      soundPlayerService.playDropSound();
    } else {
      NotificationService.showDialogMessage(context, 
        canPlayCard.$2,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Card Battle Game')),
      body: Stack(
        children: [
          // Main content of the game
          SingleChildScrollView(
            child: Column(
              children: [
                // Player Info in a fixed Top Bar
                Container(
                  height: 105,
                  padding: EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: PlayerInfoWidget(player: player)),
                      SizedBox(width: 16),
                      Expanded(child: PlayerInfoWidget(player: enemy)),
                    ],
                  ),
                ),
                // Message
                Padding(
                  padding: EdgeInsets.all(8),
                  child: Text(message, style: TextStyle(fontSize: 14)),
                ),
                // Game Board
                GameBoardWidget(
                    player: player, enemy: enemy, onCardDrop: playCard, onCardTap: showCardDetails),
                // Player's Hand (horizontal scroll)
                PlayerHandWidget(player: player, onCardTap: showCardDetails),
                // End Turn Button
                ElevatedButton(
                    onPressed: playerTurn ? nextTurn : null,
                    child: Text('End Turn')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
