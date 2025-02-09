import 'package:flutter/material.dart';

class HowToPlayScreen extends StatelessWidget {
  const HowToPlayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('How to Play'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); // Go back to the previous screen
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16), // Adds spacing
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Objective'),
            _buildSectionContent(
              'The goal of the game is to try and beat as many stages as you can before losing. '
              'Whilst advancing you get to build your deck.',
            ),
            _buildSectionTitle('Game Setup'),
            _buildSectionContent(
                '1. You start a game by choosing a mascot for your deck. A mascot has certain effects.\n'
                '2. Then stage 1 starts and you start your first match'),
            _buildSectionTitle('Matches'),
            _buildSectionContent(
              '1. Every game starts with both deck mascots being summoned in the middle monster zone.\n'
              '2. To decide who goes first we toss a coin.\n'
              '2. Use your abilities, move pieces, or play cards strategically.\n'
              '4. The match ends when one player reaches 0 health.',
            ),
            _buildSectionTitle('Different types of cards'),
            _buildSectionContent(
                'There are different types of cards, every card has a mana cost.'),
            _buildSubSectionTitle('Monster card'),
            _buildSectionContent(
                'Monster cards all have health and attack, some monsters have additional effects.\n\n'
                'Every monster can attack once per turn. You attack by dragging the monster onto an opponent monster.\n\n'
                'If the opponent has no monsters on the board you can attack them directly by dragging your attacking monster onto the opponents infocard. A direct attack does 1 point of damage.'),
            _buildSubSectionTitle('Upgrade card'),
            _buildSectionContent(
                'Upgrade cards are cards that upgrade monsters. You play an upgrade card by dragging it onto a summoned monster.'),
            _buildSubSectionTitle('Action card'),
            _buildSectionContent(
                'Action cards are cards that have all kinds of effects, for example: Draw 1 card.\n\n'
                'You play an action card by dragging it onto the field.'),
            SizedBox(height: 20), // Adds spacing at the bottom
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(top: 16, bottom: 8),
      child: Text(
        title,
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildSubSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(top: 8, bottom: 8),
      child: Text(
        title,
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildSectionContent(String content) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Text(
        content,
        style: TextStyle(fontSize: 16, height: 1.5),
      ),
    );
  }
}
