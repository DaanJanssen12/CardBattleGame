import 'package:card_battle_game/models/cards/card.dart';
import 'package:card_battle_game/models/database/user_storage.dart';
import 'package:card_battle_game/models/game/game.dart';
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

  void addCardToDeck(GameCard card) {
    setState(() {
      availableCards.remove(card);
      deck.add(card);
      card.isInDeck = true;
    });
    saveData();
  }

  void removeCardFromDeck(GameCard card) {
    setState(() {
      deck.remove(card);
      availableCards.add(card);
      card.isInDeck = false;
    });
    saveData();
  }

  void saveData() async {
    widget.userData.deck.cards = deck.map((m) => m.id).toList();
    widget.userData.cards = availableCards.map((m) => m.id).toList();
    await UserStorage.saveUserData(widget.userData);
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
            'assets/images/${widget.userData.background}',
            fit: BoxFit.cover,
          ),
          Column(
            children: [
              // Deck Column (your deck of cards)
              Expanded(
                child: DragTarget<GameCard>(
                  onWillAcceptWithDetails: (card) {
                    return !card.data.isInDeck;
                  },
                  onAcceptWithDetails: (card) {
                    addCardToDeck(card.data);
                  },
                  builder: (context, candidateData, rejectedData) {
                    return _buildCardList(deck, "Your Deck", true);
                  },
                ),
              ),
              // Available Cards Column
              Expanded(
                child: DragTarget<GameCard>(
                  onWillAcceptWithDetails: (card) {
                    return card.data.isInDeck;
                  },
                  onAcceptWithDetails: (card) {
                    removeCardFromDeck(card.data);
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
    Map<GameCard, int> grouped = {};
    for (var card in cards) {
      var key = card;
      if (grouped.keys.any((a) => a.id == card.id)) {
        key = grouped.keys.firstWhere((w) => w.id == card.id);
      }
      grouped[key] = (grouped[key] ?? 0) + 1;
    }
    // Sort the keys alphabetically by the name of the Item
    var sortedGrouped = grouped.keys.toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    return Column(
      children: [
        // Title with background and card count
        Container(
          color: Colors.blueGrey, // Background color for the title section
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
              Text(
                '${cards.length} Cards', // Display the number of cards
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ],
          ),
        ),
        // Divider with background color
        Container(
          color: Colors.blueGrey, // Background color for the divider
        ),
        // Set a fixed height for each section (deck or available cards)
        SizedBox(
          height: 300, // Fixed height for each section (change as needed)
          child: SingleChildScrollView(
            child: Wrap(
              spacing: 10, // Horizontal space between cards
              runSpacing: 10, // Vertical space between rows
              children: sortedGrouped.map((card) {
                var amount = grouped[card];
                return LongPressDraggable<GameCard>(
                  data: card,
                  delay: Duration(microseconds: 750),
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
                        amount: amount),
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
