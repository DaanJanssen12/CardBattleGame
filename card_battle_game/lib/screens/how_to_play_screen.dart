import 'package:card_battle_game/models/constants.dart';
import 'package:flutter/material.dart';

class HowToPlayScreen extends StatelessWidget {
  const HowToPlayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3, // Number of tabs
      child: Scaffold(
        appBar: AppBar(
          title: Text('How to Play'),
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context); // Go back to the previous screen
            },
          ),
          bottom: TabBar(
            tabs: [
              Tab(text: 'Game'),
              Tab(text: 'Cards'),
              Tab(text: 'Deck builder'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildGameTab(),
            _buildCardsTab(),
            _buildDeckBuilderTab(),
          ],
        ),
      ),
    );
  }

  /// **Game Tab Content**
  Widget _buildGameTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
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
              '3. Use your abilities, move pieces, or play cards strategically.\n'
              '4. The match ends when one player reaches 0 health.\n\n'),
          _buildSectionTitle('Resources'),
          _buildSubSectionTitle('Mana'),
          _buildSectionContent(
              'Based on your mascot you start with an x amount of mana. Every turn you gain mana, this scales with the turns. You have a mana limit of ${Constants.playerMaxMana}.\n'),
          _buildSubSectionTitle('Cards'),
          _buildSectionContent(
              'During your turn you play cards, these cards have a mana cost to play. Played cards are put in your discard pile, when your deck is empty your discard pile is recycled back into your deck.\n'),
          _buildSubSectionTitle('Hand'),
          _buildSectionContent(
              'You can play cards that are in your hand. Every turn you draw (if possible) ${Constants.drawCardsPerTurn} card(s) from your deck into your hand. The amount of cards in your hand is limited to ${Constants.playerMaxHandSize}.\n'),
        ],
      ),
    );
  }

  Widget _buildDeckBuilderTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Deck builder'),
          _buildSectionContent(
            'From the main menu you can access your deck builder by clicking the button in the top right.\n\n'
            'In this page you see your collection of cards, by dragging them around you can assemble the deck with which you start a new game.',
          ),
        ],
      ),
    );
  }

  /// **Cards Tab Content**
  Widget _buildCardsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Different Types of Cards'),
          _buildSectionContent(
              'There are different types of cards, and every card has a mana cost.'),
          _buildSubSectionTitle('Monster Card'),
          _buildSectionContent(
              'Monster cards all have health and attack, some monsters have additional effects.\n\n'
              'Every monster can attack once per turn. You attack by dragging the monster onto an opponent monster.\n\n'
              'If the opponent has no monsters on the board you can attack them directly by dragging your attacking monster onto the opponent’s info card. A direct attack does 1 point of damage.'),
          _buildSubSectionTitle('Upgrade Card'),
          _buildSectionContent(
              'Upgrade cards are cards that upgrade monsters. You play an upgrade card by dragging it onto a summoned monster.'),
          _buildSubSectionTitle('Action Card'),
          _buildSectionContent(
              'Action cards are cards that have various effects, for example: Draw 1 card.\n\n'
              'You play an action card by dragging it onto the field.'),
        ],
      ),
    );
  }

  /// **Reusable Section Title**
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(top: 16, bottom: 8),
      child: Text(
        title,
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
    );
  }

  /// **Reusable Subsection Title**
  Widget _buildSubSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(top: 8, bottom: 8),
      child: Text(
        title,
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  /// **Reusable Section Content**
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
