import 'package:card_battle_game/animations/booster_pack_animation.dart';
import 'package:card_battle_game/models/cards/card.dart';
import 'package:card_battle_game/models/constants.dart';
import 'package:card_battle_game/models/database/card_database.dart';
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

class _DeckBuilderScreenState extends State<DeckBuilderScreen>
    with SingleTickerProviderStateMixin {
  List<GameCard> deck = [];
  List<GameCard> availableCards = [];
  List<BoosterPackType> boosterPacks  = [BoosterPackType.common];
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  void _loadData() async {
    deck = await widget.userData.deck.asDeck();
    availableCards = await widget.userData.availableCards();
    boosterPacks = [BoosterPackType.common]; // await widget.userData.boosterPacks;
    setState(() {});
  }

  void showCardDetails(GameCard card) {
    showDialog(
      context: context,
      barrierDismissible: true,
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
        backgroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: "Deck Builder"),
            Tab(text: "Booster Packs"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDeckBuilderTab(),
          _buildBoosterPacksTab(),
        ],
      ),
    );
  }

  Widget _buildDeckBuilderTab() {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/images/${widget.userData.background}',
          fit: BoxFit.cover,
        ),
        Column(
          children: [
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
    );
  }

  Widget _buildBoosterPacksTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            "Your Booster Packs",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: boosterPacks.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(boosterPacks[index].name),
                trailing: ElevatedButton(
                  onPressed: () => _openBoosterPack(boosterPacks[index]),
                  child: Text("Open"),
                ),
              );
            },
          ),
        ),
        //BoosterPackOpenAnimation(key: _animationKey)
      ],
    );
  }

 void _openBoosterPack(BoosterPackType type) {
  showDialog(
    context: context,
    barrierDismissible: false, // Prevents accidental closing
    builder: (BuildContext context) {
      return Dialog(
        backgroundColor: Colors.transparent, // Makes it overlay-like
        child: BoosterPackOpenAnimation(type: type),
      );
    },
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
      ..sort((a, b) => a.type == b.type
          ? a.name.compareTo(b.name)
          : a.isMonster()
              ? -1
              : b.isMonster()
                  ? 1
                  : a.isUpgrade()
                      ? -1
                      : b.isUpgrade()
                          ? 1
                          : 0);

    return Column(
      children: [
        Container(
          color: Colors.blueGrey,
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
                '${cards.length} Cards',
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
          height: 300,
          child: SingleChildScrollView(
            child: Wrap(
              spacing: 10, // Horizontal space between cards
              runSpacing: 10, // Vertical space between rows
              children: sortedGrouped.map((card) {
                var amount = grouped[card];
                return GestureDetector(
                  onTap: () => showCardDetails(card),
                  child: LongPressDraggable<GameCard>(
                    data: card,
                    delay: Duration(
                        milliseconds:
                            Constants.longPressDraggableDelayInMilliseconds),
                    feedback: Material(
                      child: SizedBox(
                        width: 100, // Fixed width for the card
                        height: 160, // Fixed height for the card
                        child: CardWidget(
                          card: card,
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
