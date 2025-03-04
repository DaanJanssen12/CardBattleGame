import 'dart:math';

import 'package:card_battle_game/models/constants.dart';
import 'package:card_battle_game/models/database/card_database.dart';
import 'package:card_battle_game/models/player/player.dart';
import 'package:card_battle_game/screens/main_menu.dart';
import 'package:card_battle_game/screens/map_screen.dart';
import 'package:card_battle_game/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:card_battle_game/models/cards/card.dart';
import 'package:card_battle_game/models/database/user_storage.dart';
import 'package:card_battle_game/widgets/card_widget.dart';

class StageCompletionScreen extends StatefulWidget {
  final UserData userData;
  final Player? beatenPlayer;

  const StageCompletionScreen(
      {super.key, required this.userData, required this.beatenPlayer});

  @override
  _StageCompletionScreenState createState() => _StageCompletionScreenState();
}

enum RewardOptions { addCard, upgradeCard, skip, none }

class _StageCompletionScreenState extends State<StageCompletionScreen> {
  GameCard? _selectedReward;
  GameCard? _selectedCardToRemoveFromDeck;
  RewardOptions? _selectedOption;
  int currentStage =
      1; // The stage starts at 1 and increases with each completed stage
  List<GameCard> rewardCards = [];
  bool gameOver = false;
  bool playerHasLost = false;
  final int rewardFromStage = 5;

  @override
  void initState() {
    super.initState();
    currentStage = widget.userData.activeGame!.stage;
    gameOver = widget.userData.activeGame!.gameHasEnded;
    playerHasLost = widget.userData.activeGame!.playerHasLost;
    _selectedOption = RewardOptions.addCard;
    if (gameOver) {
      if (!playerHasLost) {
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
    var card1 = Random().nextInt(widget.beatenPlayer!.deck.length);
    var card2 = Random().nextInt(widget.beatenPlayer!.deck.length);
    var card3 = Random().nextInt(widget.beatenPlayer!.deck.length);
    while (card2 == card1) {
      card2 = Random().nextInt(widget.beatenPlayer!.deck.length);
    }
    while (card3 == card1 || card3 == card2) {
      card3 = Random().nextInt(widget.beatenPlayer!.deck.length);
    }

    return [
      widget.beatenPlayer!.deck[card1],
      widget.beatenPlayer!.deck[card2],
      widget.beatenPlayer!.deck[card3]
    ];
    //return await CardDatabase.generateRewards(stage, 3);
  }

  void advanceToNextStage() async {
    if (canNotAdvance()) {
      return;
    }
    if (gameOver && playerHasLost) {
      endGame(null);
      return;
    }
    if (gameOver) {
      if (_selectedReward != null) {
        widget.userData.cards.add(_selectedReward!.id);
      }
      await endGame(_selectedReward);
      return;
    }

    if (_selectedOption == null) {
      return;
    }
    if (_selectedOption == RewardOptions.addCard && _selectedReward == null) {
      return;
    }

    if (_selectedReward != null && _selectedReward!.isMonster()) {
      if (_selectedReward!.toMonster().isMascot) {
        _selectedReward!.toMonster().isMascot = false;
      }
    }

    widget.userData.activeGame!.advanceStage(_selectedOption!, _selectedReward);
    await saveActiveGame();
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => NodeMapScreen(userData: widget.userData)),
    );
  }

  void skipReward() async {
    NotificationService.showDialogMessageWithActions(
        context,
        'Are you sure you wanna proceed to the next stage without taking a reward?',
        [
          TextButton(
              onPressed: () {
                _selectedOption = RewardOptions.skip;
                advanceToNextStage();
              },
              child: Text('Yes')),
          TextButton(
              onPressed: () => {Navigator.pop(context)}, child: Text('No'))
        ],
        title: 'Skip reward?');
  }

  Future<void> saveActiveGame() async {
    await UserStorage.updateActiveGame(widget.userData.activeGame!);
  }

  Future<void> endGame(GameCard? reward) async {
    await widget.userData.endGame(currentStage, reward);
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

          Positioned(
              top: 50,
              left: 20,
              right: 20,
              child: Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        gameOver
                            ? playerHasLost
                                ? "Lost at Stage $currentStage"
                                : "Game ended at Stage $currentStage"
                            : "Stage $currentStage Completed",
                        style: TextStyle(
                          fontSize: gameOver ? 24 : 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        gameOver
                            ? "You accumulated the following rewards"
                            : "Before you continue you can select a reward",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        softWrap: true,
                      ),
                    ],
                  ))),

          if (!gameOver) ...[
            if (_selectedOption == null) ...[
              Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _selectedOption = RewardOptions.addCard;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      fixedSize: Size(220, 75),
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.green,
                      padding:
                          EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                      textStyle:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    child: Column(
                      children: [
                        Text('Add card to deck'),
                        Text(
                            '(Current deck size: ${widget.userData.activeGame!.player.deck.length})',
                            style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _selectedOption = RewardOptions.upgradeCard;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      fixedSize: Size(220, 75),
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.blue,
                      padding:
                          EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                      textStyle:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    child: Column(
                      children: [
                        Text('Upgrade a card'),
                        Text(
                            '(${widget.userData.activeGame!.amountOfUpgradeCard} left)',
                            style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                      onPressed:
                          widget.userData.activeGame!.amountOfSkipReward <= 0
                              ? null
                              : () {
                                  _selectedOption = RewardOptions.skip;
                                  advanceToNextStage();
                                },
                      style: ElevatedButton.styleFrom(
                        fixedSize: Size(220, 75),
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.blueGrey,
                        padding:
                            EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                        textStyle: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      child: Column(
                        children: [
                          Text('Skip reward'),
                          Text(
                              '(${widget.userData.activeGame!.amountOfSkipReward} left)',
                              style: TextStyle(fontSize: 12)),
                        ],
                      ))
                ]),
              ),
            ]
            else if (!gameOver) ...[
              Center(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, 120, 20, 200),
                  child: GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: rewardCards.length,
                    itemBuilder: (context, index) {
                      final card = rewardCards[index];
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedReward = card;
                          });
                        },
                        child: CardWidget(
                          card: card,
                          isSelected: _selectedReward ==
                              card, // Highlight selected card
                        ),
                      );
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
                          ? Text(
                              'Select a reward to see its description',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            )
                          : Text(
                              _selectedReward!.fullDescription ??
                                  _selectedReward!.shortDescription ??
                                  "",
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
          ],

          // Reward Description Box (Below Card Selection)
          if (gameOver ||
              (_selectedOption != null &&
                  _selectedOption == RewardOptions.addCard)) ...[
            //(!gameOver || currentStage >= rewardFromStage) ...[
            // Reward Card Selection Grid
            if (!gameOver &&
                widget.userData.activeGame!.player.deck.length >=
                    Constants.playerMaxDeckSize) ...[
              Center(
                child: Padding(
                    padding: EdgeInsets.fromLTRB(20, 120, 20, 200),
                    child: Scrollbar(
                      thickness: 10,
                      radius: Radius.circular(10),
                      thumbVisibility: true,
                      interactive: true,
                      child: GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        itemCount:
                            widget.userData.activeGame!.player.deck.length,
                        itemBuilder: (context, index) {
                          final card =
                              widget.userData.activeGame!.player.deck[index];
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedCardToRemoveFromDeck = card;
                              });
                            },
                            child: CardWidget(
                              card: card,
                              isSelected: _selectedCardToRemoveFromDeck ==
                                  card, // Highlight selected card
                            ),
                          );
                        },
                      ),
                    )),
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
                        'Selected:',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      _selectedCardToRemoveFromDeck == null
                          ? Text(
                              'Select a card to remove from your deck',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            )
                          : Text(
                              _selectedCardToRemoveFromDeck!.name,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                    ],
                  ),
                ),
              ),
            ] else if (gameOver) ...[
              Center(
                child: Padding(
                    padding: EdgeInsets.fromLTRB(20, 150, 20, 200),
                    child: widget.userData.activeGame!.rewards.length > 0
                        ? ListView.separated(
                separatorBuilder: (context, index) =>
                    SizedBox(height: 10), // Space between items
                padding: EdgeInsets.fromLTRB(5, 5, 5, 5),
                itemCount: widget.userData.activeGame!.rewards.length,
                itemBuilder: (context, index) {
                  var reward = widget.userData.activeGame!.rewards[index];
                  return Container(
                    decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(10)),
                    child: ListTile(
                      title: Text(reward, style: TextStyle(color: Colors.white)),
                    ),
                  );
                },
              )
                        : Text('No rewards accumulated :(', style: TextStyle(color: Colors.white))),
              ),
            ],
          ],

          if (!gameOver &&
              widget.userData.activeGame!.player.deck.length >=
                  Constants.playerMaxDeckSize) ...[
            // Confirm Button
            Positioned(
              bottom: 50,
              left: 0,
              right: 0,
              child: Center(
                child: ElevatedButton(
                  onPressed: _selectedCardToRemoveFromDeck == null
                      ? null
                      : () => {
                            setState(() {
                              widget.userData.activeGame!.player.deck
                                  .remove(_selectedCardToRemoveFromDeck);
                            })
                          },
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: _selectedCardToRemoveFromDeck == null
                        ? Colors.grey
                        : Colors.blue,
                    padding: EdgeInsets.symmetric(horizontal: 90, vertical: 20),
                    textStyle:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  child: Text('Remove from deck'),
                ),
              ),
            )
          ] else if (_selectedOption != null || gameOver) ...[
            // Confirm Button
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (!gameOver) ...[
                    ElevatedButton(
                        onPressed:
                            widget.userData.activeGame!.amountOfSkipReward <= 0
                                ? null
                                : () {
                                    skipReward();
                                  },
                        style: ElevatedButton.styleFrom(
                          fixedSize: Size(150, 65),
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.blueGrey,
                          padding: EdgeInsets.symmetric(
                              horizontal: 40, vertical: 20),
                          textStyle: TextStyle(
                              fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                        child: Column(
                          children: [
                            Text('Skip reward'),
                            Text(
                                '(${widget.userData.activeGame!.amountOfSkipReward} left)',
                                style: TextStyle(fontSize: 10)),
                          ],
                        )),
                  ],
                  ElevatedButton(
                    onPressed: advanceToNextStage,
                    style: ElevatedButton.styleFrom(
                      fixedSize: Size(150, 65),
                      foregroundColor: Colors.white,
                      backgroundColor:
                          canNotAdvance() ? Colors.grey : Colors.blue,
                      textStyle:
                          TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                    child: Text(gameOver
                        ? 'End game'
                        : 'Proceed to Stage ${currentStage + 1}'),
                  ),
                ],
              ),
            )
          ]
        ],
      ),
    );
  }

  bool canNotAdvance() {
    if (gameOver) {
      return false;
    }
    return (_selectedOption == null) ||
        (_selectedOption == RewardOptions.addCard && _selectedReward == null);
  }
}
