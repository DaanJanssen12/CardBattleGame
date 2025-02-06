import 'package:card_battle_game/models/card.dart';
import 'package:card_battle_game/models/user_storage.dart';
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
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Deck Builder"),
        backgroundColor: Colors.white,  // Change to suit your design
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
                    return _buildCardList(availableCards, "Available Cards", false);
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
          padding: const EdgeInsets.all(8.0),
          child: Text(
            title,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
        // Wrap the GridView with Expanded to provide it a bounded height
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Calculate the width of each card based on screen width and 3 items per row
              double cardWidth = (constraints.maxWidth - 40) / 3; // Subtract 40 for spacing
              double cardHeight = cardWidth * 1.5; // Height scales proportionally based on width

              return GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3, // 3 items per row
                  crossAxisSpacing: 10, // Space between the cards horizontally
                  mainAxisSpacing: 10,  // Space between the cards vertically
                ),
                itemCount: cards.length,
                itemBuilder: (context, index) {
                  return Draggable<GameCard>(
                    data: cards[index],
                    feedback: Material(
                      child: SizedBox(
                        width: cardWidth,
                        height: cardHeight,
                        child: CardWidget(card: cards[index]),
                      ),
                    ),
                    childWhenDragging: Opacity(
                      opacity: 0.5,
                      child: SizedBox(
                        width: cardWidth,
                        height: cardHeight,
                        child: CardWidget(card: cards[index]),
                      ),
                    ),
                    child: SizedBox(
                      width: cardWidth,
                      height: cardHeight,
                      child: CardWidget(card: cards[index]),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
