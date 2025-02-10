import 'package:card_battle_game/models/card_database.dart';
import 'package:card_battle_game/models/cpu.dart';
import 'package:card_battle_game/screens/main_menu.dart';
import 'package:flutter/material.dart';
import 'package:card_battle_game/models/card.dart';
import 'package:card_battle_game/screens/game_screen.dart';
import 'package:card_battle_game/models/user_storage.dart';
import 'package:card_battle_game/widgets/card_widget.dart';

class StageSelectionScreen extends StatefulWidget {
  final UserData userData;

  const StageSelectionScreen({super.key, required this.userData});

  @override
  _StageSelectionScreenState createState() => _StageSelectionScreenState();
}

class _StageSelectionScreenState extends State<StageSelectionScreen> {
  GameCard? _selectedReward;
  bool skipReward = false;
  int currentStage =
      1; // The stage starts at 1 and increases with each completed stage
  List<GameCard> rewardCards = [];
  bool gameOver = false;
  final int rewardFromStage = 5;

  @override
  void initState() {
    super.initState();
    currentStage = widget.userData.activeGame!.stage;
    gameOver = widget.userData.activeGame!.playerHasLost;
    if (gameOver) {
      if (currentStage >= rewardFromStage) {
        _loadPermanentRewardCards();
      }
    } else {
      _loadRewardCards();
    }
  }

  // Simulate loading the reward cards from a service
  void _loadRewardCards() async {
    // Fetch the possible reward cards (This should come from a service or API)
    List<GameCard> fetchedCards = await fetchRewardCardsForStage(currentStage);

    setState(() {
      rewardCards = fetchedCards;
    });

    print("Fetched reward cards: ${rewardCards.length}");
  }

  void _loadPermanentRewardCards() async {
    setState(() {
      rewardCards = widget.userData.activeGame!.selectedRewards;
    });
  }

  // Simulate fetching reward cards from a service or backend
  Future<List<GameCard>> fetchRewardCardsForStage(int stage) async {
    return await CardDatabase.generateRewards(stage, 3);
  }

  void advanceToNextStage() {
    if (gameOver && currentStage < rewardFromStage) {
      endGame(null);
    }
    if (_selectedReward != null || skipReward) {
      if (gameOver) {
        if (!skipReward) {
          widget.userData.cards.add(_selectedReward!.id);
        }
        endGame(_selectedReward);
      } else {
        if (!skipReward) {
          widget.userData.activeGame!.selectedRewards.add(_selectedReward!);
          widget.userData.activeGame!.player.deck.add(_selectedReward!);
        }
        widget.userData.activeGame!.stageUp();
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => GameScreen(userData: widget.userData)),
        );
      }
    }
  }

  void endGame(GameCard? reward) async {
    UserStorage.endGame(currentStage, reward);
    widget.userData.activeGame!.endGame();
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => MainMenu(userData: widget.userData)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background image
          Image.asset(
            'assets/images/${widget.userData.background}',
            fit: BoxFit.cover,
          ),

          // Stage Header
          Positioned(
            top: 50,
            left: 20,
            child: Text(
              gameOver
                  ? "Lost at Stage $currentStage"
                  : "Stage $currentStage Completed",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          // Stage Header
          Positioned(
            top: 100,
            left: 20,
            child: Text(
              gameOver
                  ? currentStage >= rewardFromStage
                      ? "Select a reward to add to your collection"
                      : "Click the button below to end the game"
                  : "Before you continue you can select a reward",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              softWrap: true,
            ),
          ),

          // Reward Description Box (Below Card Selection)
          if (!gameOver || currentStage >= rewardFromStage) ...[
            // Reward Card Selection Grid
            Center(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 120, 20, 0),
                child: GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: rewardCards.length + 1,
                  itemBuilder: (context, index) {
                    if (index == rewardCards.length) {
                      return GestureDetector(
                          onTap: () {
                            setState(() {
                              skipReward = true;
                              _selectedReward = null;
                            });
                          },
                          child: Card(
                            child: CardWidget(
                                card: GameCard(
                                    'Skip', '', 0, 'Do not take a reward', ''),
                                isSelected: skipReward),
                          ));
                    } else {
                      final card = rewardCards[index];
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedReward = card;
                            skipReward = false;
                          });
                        },
                        child: CardWidget(
                          card: card,
                          isSelected: _selectedReward ==
                              card, // Highlight selected card
                        ),
                      );
                    }
                  },
                ),
              ),
            ),
            Positioned(
              bottom: 120, // Adjust the position
              left: 20,
              right: 20,
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reward Description:',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    _selectedReward == null
                        ? skipReward 
                          ? Text(
                            'Skip: you gain no reward',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          )
                          : Text(
                            'Select a reward to see its description',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          )
                        : Text(
                            _selectedReward!.shortDescription ?? "",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                  ],
                ),
              ),
            ),
          ],

          // Confirm Button
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Center(
              child: ElevatedButton(
                onPressed: canNotAdvance() ? null : advanceToNextStage,
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: canNotAdvance() ? Colors.grey : Colors.blue,
                  padding: EdgeInsets.symmetric(horizontal: 90, vertical: 20),
                  textStyle:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                child: Text(gameOver
                    ? 'End game'
                    : 'Proceed to Stage ${currentStage + 1}'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool canNotAdvance() {
    return (_selectedReward == null &&
        !skipReward &&
        (!gameOver || currentStage >= rewardFromStage));
  }
}
