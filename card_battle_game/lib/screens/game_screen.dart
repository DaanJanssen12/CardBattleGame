import 'package:card_battle_game/models/database/user_storage.dart';
import 'package:card_battle_game/services/stage_match_service.dart';
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
  late StageMatchService _stageMatchService;

  @override
  void initState() {
    super.initState();
    _stageMatchService = StageMatchService(context, widget.userData, () => {setState(() {})});
    _loadData();
  }

     Future<void> _loadData() async {
    var player = widget.userData.activeGame!.player;
    var opponent = await widget.userData.activeGame!.initCPU();
    setState(() {
      _isLoading = false;
    });
    _stageMatchService.initGame(player, opponent);
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
                onPressed: _stageMatchService.showBattleLog, // Disable when it's the enemy's turn
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
                onPressed: _stageMatchService.match.isPlayersTurn ? _stageMatchService.match.endPlayerTurn : null,
                style: TextButton.styleFrom(
                  backgroundColor: _stageMatchService.match.isPlayersTurn
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
                                        player: _stageMatchService.match.player,
                                        isActive: _stageMatchService.match.isPlayersTurn,
                                        handleAttackPlayerDirectly: null)),
                                SizedBox(width: 16),
                                Expanded(
                                    child: PlayerInfoWidget(
                                        player: _stageMatchService.match.opponent,
                                        isActive: !_stageMatchService.match.isPlayersTurn,
                                        handleAttackPlayerDirectly:
                                            _stageMatchService.match.handleAttackPlayerDirectly)),
                              ],
                            ),
                          ),
                          SizedBox(height: 12),
                          // Game Board
                          GameBoardWidget(
                              player: _stageMatchService.match.player,
                              enemy: _stageMatchService.match.opponent,
                              isPlayersTurn: _stageMatchService.match.isPlayersTurn,
                              onCardDrop: _stageMatchService.playCard,
                              onCardTap: _stageMatchService.showCardDetails,
                              onMonsterAttack: _stageMatchService.match.attackMonster),
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
                              player: _stageMatchService.match.player, onCardTap: _stageMatchService.showCardDetails),
                        ),
                      ),
                    ],
                  ),
          ),
        ));
  }

}
