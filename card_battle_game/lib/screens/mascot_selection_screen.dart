import 'package:card_battle_game/models/cards/card.dart';
import 'package:card_battle_game/screens/game_screen.dart';
import 'package:card_battle_game/screens/map_screen.dart';
import 'package:card_battle_game/widgets/card_widget.dart';
import 'package:flutter/material.dart';
import 'package:card_battle_game/models/database/user_storage.dart';

class MascotSelectionScreen extends StatefulWidget {
  final UserData userData;

  const MascotSelectionScreen({super.key, required this.userData});

  @override
  _MascotSelectionScreenState createState() => _MascotSelectionScreenState();
}

class _MascotSelectionScreenState extends State<MascotSelectionScreen> {
  GameCard? _selectedMascot;
  List<GameCard> deck = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    await widget.userData.newGame(); // Ensure game and player are initialized

    if (widget.userData.activeGame != null) {
      setState(() {
        deck = widget.userData.activeGame!.player.deck
            .where((card) => card.isMonster()) // Filter only monster cards
            .toList();
      });
    }
  }

  void startGame() {
    widget.userData.activeGame!.setMascot(_selectedMascot!.toMonster());
    widget.userData.activeGame!.stage = 1;
    // Navigator.push(
    //   context,
    //   MaterialPageRoute(
    //       builder: (context) => GameScreen(userData: widget.userData)),
    // );
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => NodeMapScreen(userData: widget.userData)),
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

          // Title
          Positioned(
            top: 50,
            left: 20,
            child: Text(
              "Choose Your Mascot",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),

          // Card Selection Grid
          // Center(
          //   child: Padding(
          //     padding: EdgeInsets.fromLTRB(20, 80, 20, 0),
          //     child: GridView.builder(
          //       gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          //         crossAxisCount: 3,
          //         crossAxisSpacing: 10,
          //         mainAxisSpacing: 10,
          //       ),
          //       itemCount: deck.length,
          //       itemBuilder: (context, index) {
          //         final card = deck[index];
          //         return GestureDetector(
          //           onTap: () {
          //             setState(() {
          //               _selectedMascot = card;
          //             });
          //           },
          //           child: CardWidget(
          //             card: card,
          //             isSelected:
          //                 _selectedMascot == card, // Highlight selected card
          //           ),
          //         );
          //       },
          //     ),
          //   ),
          // ),

          Center(
            child: Container(
              height: 500, // Give it some space to render
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: deck.map((card) {
                    return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedMascot = card;
                          });
                        },
                        child: Container(
                          width: 100,
                          height: 160,
                          child: CardWidget(
                            card: card,
                            isSelected: _selectedMascot == card,
                          ),
                        ));
                  }).toList(),
                ),
              ),
            ),
          ),

          // Effects Box (Below Card Selection)
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
                    'Mascot Effects:',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  _selectedMascot == null
                      ? Text(
                          'Select a mascot to see its effects',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Starting Health: ${deck.firstWhere((card) => card == _selectedMascot).toMonster().mascotEffects.startingHealth}',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              'Starting Mana: ${deck.firstWhere((card) => card == _selectedMascot).toMonster().mascotEffects.startingMana}',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              'Starting Gold: ${_selectedMascot!.toMonster().mascotEffects.startingGold}',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                            if (_selectedMascot!
                                    .toMonster()
                                    .mascotEffects
                                    .additionalEffect !=
                                null) ...[
                              SizedBox(height: 8),
                              Text(
                                _selectedMascot!
                                    .toMonster()
                                    .mascotEffects
                                    .additionalEffect!
                                    .name,
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold),
                              ),
                              Text(
                                _selectedMascot!
                                    .toMonster()
                                    .mascotEffects
                                    .additionalEffect!
                                    .description,
                                style: TextStyle(
                                    color: Colors.white, fontSize: 16),
                              ),
                            ]
                          ],
                        ),
                ],
              ),
            ),
          ),

          // Confirm Button
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Center(
              child: ElevatedButton(
                onPressed: _selectedMascot == null ? null : startGame,
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor:
                      _selectedMascot == null ? Colors.grey : Colors.green,
                  padding: EdgeInsets.symmetric(horizontal: 100, vertical: 20),
                  textStyle:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                child: Text('Confirm Mascot'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
