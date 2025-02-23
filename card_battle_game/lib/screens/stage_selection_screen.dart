import 'package:card_battle_game/models/database/user_storage.dart';
import 'package:card_battle_game/screens/game_screen.dart';
import 'package:card_battle_game/screens/mystery_event_screen.dart';
import 'package:flutter/material.dart';

class StageSelectionScreen extends StatefulWidget {
  const StageSelectionScreen({super.key, required this.userData});
  final UserData? userData;

  @override
  _StageSelectionScreenState createState() => _StageSelectionScreenState();
}

class _StageSelectionScreenState extends State<StageSelectionScreen> {
  UserData? _userData; // Store user data
  final List<PathOption> pathOptions = [
    PathOption(PathType.battle, "Battle", "🔥", "Tough enemies, high rewards"),
    //PathOption(PathType.battle, "Shop", "💰", "Buy cards & upgrades"),
    PathOption(PathType.mystery, "Mystery", "❓", "Unknown encounter"),
  ];
  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  /// Fetch user data when the screen loads
  Future<void> _loadUserData() async {
    if (widget.userData != null) {
      setState(() {
        _userData = widget.userData!;
      });
    } else {
      final userData = await UserStorage.getUserData();
      setState(() {
        _userData = userData;
      });
    }
  }

  void startMatch() async {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => GameScreen(userData: _userData!)),
    );
  }

  void mysteryEvent() async {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => MysteryEventScreen(userData: _userData!)),
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
            'assets/images/${_userData == null ? "forrest.jpg" : _userData!.background}',
            fit: BoxFit.cover,
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Stage ${_userData!.activeGame!.stage}",
                    style: TextStyle(fontSize: 22, color: Colors.white70)),
                SizedBox(height: 10),
                Text("Choose Your Next Path",
                    style: TextStyle(fontSize: 18, color: Colors.white70)),
                SizedBox(height: 30),
                Column(
                  children: pathOptions
                      .map((option) => buildOptionCard(context, option))
                      .toList(),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildOptionCard(BuildContext context, PathOption option) {
    return GestureDetector(
      onTap: () {
        switch (option.type) {
          case PathType.battle:
            startMatch();
            break;
          case PathType.mystery:
            mysteryEvent();
            break;
        }
        // Handle path selection logic here
        print("Selected: ${option.name}");
      },
      child: Card(
        color: Colors.grey[850],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: EdgeInsets.all(15),
          child: Row(
            children: [
              Text(option.emoji, style: TextStyle(fontSize: 28)),
              SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(option.name,
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                  Text(option.description,
                      style: TextStyle(fontSize: 14, color: Colors.white70)),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}

class PathOption {
  final PathType type;
  final String name;
  final String emoji;
  final String description;
  PathOption(this.type, this.name, this.emoji, this.description);
}

enum PathType { battle, mystery }
