import 'package:card_battle_game/models/cards/card.dart';
import 'package:card_battle_game/models/database/card_database.dart';
import 'package:card_battle_game/models/database/user_storage.dart';
import 'package:card_battle_game/screens/map_screen.dart';
import 'package:card_battle_game/screens/stage_completion_screen.dart';
import 'package:card_battle_game/screens/stage_selection_screen.dart';
import 'package:flutter/material.dart';
import 'dart:math';

class MysteryEventScreen extends StatefulWidget {
  const MysteryEventScreen({super.key, required this.userData});
  final UserData? userData;

  @override
  _MysteryEventScreenState createState() => _MysteryEventScreenState();
}

class _MysteryEventScreenState extends State<MysteryEventScreen>
    with SingleTickerProviderStateMixin {
  late MysteryEvent _currentEvent;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _generateRandomEvent();
    _controller = AnimationController(
      duration: Duration(milliseconds: 500),
      vsync: this,
    )..forward();
  }

  void advanceStage() {
    widget.userData!.activeGame!.advanceStage(RewardOptions.none, null);
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => NodeMapScreen(userData: widget.userData!)),
    );
  }

  void _generateRandomEvent() {
    final events = [
      MysteryEvent(
        title: "The lucky fountain 🎩",
        description: "You come across 'The lucky fountain'! People toss coins into it in exchange for good fortune. Do you toss a coin?",
        choice1: "Toss a coin!",
        choice2: "I don't believe that superstitious stuff. *Walk away*",
        effect1: () {
          _tossACoin();
        },
        effect2: () {
          advanceStage();
        },
      ),
      MysteryEvent(
        title: "The Clown's Gamble 🤡",
        description: '📖 A grinning clown jumps out of nowhere! \n\n'
            '💬 "Wanna play a game? You could win big... or lose something dear!"',
        choice1: "Play the game!",
        choice2: "Ignore the clown and back away slowly...",
        effect1: () {
          _playTheGame();
        },
        effect2: () {
          advanceStage();
        },
      ),
      MysteryEvent(
        title: "Mysterious Stranger 🤵‍♂️",
        description: '"Hey you there! Could you give me a hand?" \n\n'
            'You see an old man trying to get up',
        choice1: "Give the man a hand",
        choice2: "Not my problem *I act like I did't hear him*",
        effect1: () async {
          var rngResult = Random().nextInt(100) + 1;
          //Add luck
          rngResult += widget.userData!.activeGame!.luck;

          if(rngResult < 50){
            var lostGold = Random().nextInt(100) + 1;
            if(lostGold > widget.userData!.activeGame!.gold){
              lostGold = widget.userData!.activeGame!.gold;
            }
            widget.userData!.activeGame!.removeGold(lostGold);
            _showResultDialog(
              "Who was that?",
              "You helped the man, but a little while later you discover you're missing some gold... Did he? \n\n"
              "You lost $lostGold gold",
              Colors.red,
            );
          }else{
            widget.userData!.activeGame!.addArtifact("GamblersCoin");
            _showResultDialog(
              "Who was that?",
              '"Thanks young man! Here, take this as a small reward." \n\n'
              "*You received an old coin*  \n\n"
              '"This coin has a bigger chance to land on tails"',
              Colors.green,
            );
          }
        },
        effect2: () {
          advanceStage();
        },
      ),
      MysteryEvent(
        title: "Abandoned Caravan 🏕️",
        description:
            'You stumble upon a wrecked merchant caravan. What do you do?',
        choice1: "Loot the Caravan!",
        choice2: "Ignore it and walk away",
        effect1: () async {
          var rngResult = Random().nextInt(100) + 1;
          //Add luck
          rngResult += widget.userData!.activeGame!.luck;

          //Determine result
          if (rngResult < 30) {
            var gold = widget.userData!.activeGame!.gold;
            var minLoseAmount =  Random().nextInt((gold / 4).floor());
            var maxLoseAmount =  Random().nextInt((gold / 2).floor());
            var loseGold = Random().nextInt(maxLoseAmount - minLoseAmount) + minLoseAmount;
            widget.userData!.activeGame!.removeGold(loseGold);
            _showResultDialog(
              "Run!",
              "The owner came back and saw you snooping around. You managed to escape but lost $loseGold gold",
              Colors.red,
            );
          }
          else if (rngResult < 80) {
            _showResultDialog(
              "Nothing..",
              "You found nothing of value...",
              Colors.black,
            );
          } else {
            var cards = await CardDatabase.getCards(["monster_zombie"]);
            var card = cards[Random().nextInt(cards.length)];
            widget.userData!.activeGame!.player.deck.add(card);
            _showResultDialog(
              "Lucky!",
              "You found a rare card. '${card.name}' has been added to your deck.",
              Colors.green,
            );
          }
        },
        effect2: () {
          advanceStage();
        },
      ),
    ];

    setState(() {
      _currentEvent = events[Random().nextInt(events.length)];
    });
  }

  void _tossACoin() async {
    widget.userData!.activeGame!.removeGold(1);
    widget.userData!.activeGame!.addLuck(1);

    _showResultDialog(
      "You tossed a coin",
      "Hopefully luck will be on your side...",
      Colors.white,
    );
  }

  // Event effect for "Play the game!"
  void _playTheGame() async {
    final outcome =
        (Random().nextBool()) ? "win" : "lose"; // Random outcome (50/50)

    if (outcome == "win") {
      int rewardGold = 100;
      widget.userData!.activeGame!.addGold(rewardGold);

      _showResultDialog(
        "You Won!",
        "You gained $rewardGold gold!",
        Colors.greenAccent,
      );
    } else {
      //Player loses a random card
      GameCard? cardToLose;
      bool cardfound = false;
      while (!cardfound) {
        cardToLose = widget.userData!.activeGame!.player.deck[
            Random().nextInt(widget.userData!.activeGame!.player.deck.length)];
        if (!cardToLose.isMonster() || !(cardToLose.toMonster()).isMascot) {
          cardfound = true;
        }
      }
      widget.userData!.activeGame!.player.deck.remove(cardToLose);
      _showResultDialog(
        "You Lost!",
        "You lost ${cardToLose!.name} from your deck",
        Colors.redAccent,
      );
    }
  }

  void _showResultDialog(String title, String content, Color buttonColor) {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              advanceStage(); // Go to next stage after acknowledging result
            },
            child: Text("Continue", style: TextStyle(color: Colors.white)),
            style: TextButton.styleFrom(backgroundColor: buttonColor),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/${widget.userData!.background}',
            fit: BoxFit.cover,
          ),
          Center(
            child: ScaleTransition(
              scale: CurvedAnimation(
                  parent: _controller, curve: Curves.easeOutBack),
              child: Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                color: Colors.white,
                margin: EdgeInsets.all(20),
                elevation: 10,
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _currentEvent.title,
                        style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black),
                      ),
                      SizedBox(height: 10),
                      Text(
                        _currentEvent.description,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Colors.black87),
                      ),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _currentEvent.effect1,
                        child: Text(_currentEvent.choice1),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.greenAccent,
                          foregroundColor: Colors.black,
                        ),
                      ),
                      SizedBox(height: 10),
                      TextButton(
                        onPressed: _currentEvent.effect2,
                        child: Text(_currentEvent.choice2,
                            style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MysteryEvent {
  final String title;
  final String description;
  final String choice1;
  final String choice2;
  final VoidCallback effect1;
  final VoidCallback effect2;

  MysteryEvent({
    required this.title,
    required this.description,
    required this.choice1,
    required this.choice2,
    required this.effect1,
    required this.effect2,
  });
}
