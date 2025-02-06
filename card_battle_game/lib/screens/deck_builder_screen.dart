import 'package:card_battle_game/models/card.dart';
import 'package:card_battle_game/models/user_storage.dart';
import 'package:card_battle_game/widgets/card_details_dialog.dart';
import 'package:flutter/material.dart';
import 'package:card_battle_game/widgets/card_widget.dart'; // Your existing card widget

class DeckBuilderScreen extends StatefulWidget {
  const DeckBuilderScreen({super.key, required this.userData});
  final UserData userData;

  @override
  _DeckBuilderScreenState createState() => _DeckBuilderScreenState();
}

class _DeckBuilderScreenState extends State<DeckBuilderScreen> {
  List<GameCard> deck = []; // List of card IDs in the deck
  List<GameCard> availableCards = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    deck = await widget.userData.deck.asDeck();
    availableCards = await widget.userData.availableCards();
    setState(() {});
  }

  void showCardDetails(GameCard card) {
    showDialog(
      context: context,
      barrierDismissible: true, // Allows dismiss by tapping outside
      builder: (BuildContext context) {
        return CardDetailsDialog(card: card);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Deck Builder"),
        backgroundColor: Colors.white, // Change to suit your design
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background Image
          Image.asset(
            'assets/images/background.jpg',
            fit: BoxFit.cover,
          ),
          Column(
            children: [
              // Deck Column (your deck of cards)
              Expanded(
                child: DragTarget<GameCard>(
                  onWillAccept: (card) {
                    return !card!.isInDeck;
                  },
                  onAccept: (card) {
                    setState(() {
                      availableCards.remove(card);
                      deck.add(card);
                      card.isInDeck = true;
                    });
                  },
                  builder: (context, candidateData, rejectedData) {
                    return _buildCardList(deck, "Your Deck", true);
                  },
                ),
              ),
              Divider(thickness: 2, color: Colors.white),
              // Available Cards Column
              Expanded(
                child: DragTarget<GameCard>(
                  onWillAccept: (card) {
                    return card!.isInDeck;
                  },
                  onAccept: (card) {
                    setState(() {
                      deck.remove(card);
                      availableCards.add(card);
                      card.isInDeck = false;
                    });
                  },
                  builder: (context, candidateData, rejectedData) {
                    return _buildCardList(
                        availableCards, "Available Cards", false);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCardList(List<GameCard> cards, String title, bool isDeck) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8.0, 0, 8.0, 0),
          child: Text(
            title,
            style: TextStyle(
                fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
        // Set a fixed height for each section (deck or available cards)
        Container(
          height: 300, // Fixed height for each section (change as needed)
          child: SingleChildScrollView(
            child: Wrap(
              spacing: 10, // Horizontal space between cards
              runSpacing: 10, // Vertical space between rows
              children: cards.map((card) {
                return Draggable<GameCard>(
                  data: card,
                  feedback: Material(
                    child: SizedBox(
                      width: 100, // Fixed width for the card
                      height: 160, // Fixed height for the card
                      child: CardWidget(
                        card: card,
                        onTap: () => showCardDetails(card),
                      ),
                    ),
                  ),
                  childWhenDragging: Opacity(
                    opacity: 0.5,
                    child: SizedBox(
                      width: 100,
                      height: 160,
                      child: CardWidget(card: card),
                    ),
                  ),
                  child: SizedBox(
                    width: 100,
                    height: 160,
                    child: CardWidget(
                      card: card,
                      onTap: () => showCardDetails(card),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}
