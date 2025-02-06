import 'package:card_battle_game/models/user_storage.dart';
import 'package:card_battle_game/screens/deck_builder_screen.dart';
import 'package:card_battle_game/screens/game_screen.dart';
import 'package:card_battle_game/screens/how_to_play_screen.dart';
import 'package:card_battle_game/screens/user_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class MainMenu extends StatefulWidget {
  const MainMenu({super.key});

  @override
  _MainMenuState createState() => _MainMenuState();
}

class _MainMenuState extends State<MainMenu> {
  UserData? _userData; // Store user data

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  /// Fetch user data when the screen loads
  Future<void> _loadUserData() async {
    final userData = await UserStorage.getUserData();
    setState(() {
      _userData = userData;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background image
          Image.asset(
            'assets/images/background.jpg',
            fit: BoxFit.cover,
          ),

          // Top right buttons
          Positioned(
            top: 40, // Adjust for status bar spacing
            right: 20,
            child: Row(
              children: [
                // User Profile Button
                _buildRoundButton(
                  icon: Icons.person,
                  color: Colors.blue,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => UserProfileScreen(userData: _userData!)),
                    );
                  },
                ),
                SizedBox(width: 10),
                // Deck Builder Button
                _buildRoundButton(
                  icon: FontAwesomeIcons.database,
                  color: Colors.green,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => DeckBuilderScreen(userData: _userData!)),
                    );
                  },
                ),
              ],
            ),
          ),

          // Menu content
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Start Game Button
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => GameScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.blue,
                    padding: EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                    textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  child: Text('Start Game!'),
                ),
                SizedBox(height: 20),

                // How to Play Button
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => HowToPlayScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.green,
                    padding: EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                    textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  child: Text('How to Play?'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Helper function to create a round button
  Widget _buildRoundButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return FloatingActionButton(
      mini: true, // Makes it smaller
      backgroundColor: color,
      onPressed: onPressed,
      child: Icon(icon, color: Colors.white),
    );
  }
}
