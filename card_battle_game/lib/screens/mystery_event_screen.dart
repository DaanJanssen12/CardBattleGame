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
        title: "The Lucky Fountain 🎩",
        description: "You find a wishing fountain! Do you toss a coin?",
        choice1: "Throw a coin!",
        choice2: "Walk away",
        effect1: () {
          advanceStage();
        },
        effect2: () {
          advanceStage();
        },
      ),
      MysteryEvent(
        title: "The Clown's Gamble 🤡",
        description: '📖 A grinning clown jumps out of nowhere! \n\n'
            '💬 "Wanna play a game? You could win big... or lose something dear!"',
        choice1:
            "Play the game!",
        choice2: "Ignore the clown and back away slowly...",
        effect1: () {
          _playTheGame();
        },
        effect2: () {
          advanceStage();
        },
      ),
      // Add new events here
    ];

    setState(() {
      _currentEvent = events[Random().nextInt(events.length)];
    });
  }

  // Event effect for "Play the game!"
  void _playTheGame() {
    final outcome =
        (Random().nextBool()) ? "win" : "lose"; // Random outcome (50/50)

    if (outcome == "win") {
      // Player wins gold!
      int rewardGold = 100; // Example reward
      //widget.userData!.gold += rewardGold;

      _showResultDialog(
        "You Won!",
        "You gained $rewardGold gold!",
        Colors.greenAccent,
      );
    } else {
      // Player loses a random item
      // String lostItem = widget.userData!.inventory.isNotEmpty
      //     ? widget.userData!.inventory.removeAt(0)
      //     : "nothing";
      _showResultDialog(
        "You Lost!",
        "You lost a random item: ",
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
