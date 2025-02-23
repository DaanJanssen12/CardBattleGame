import 'dart:math';

import 'package:card_battle_game/models/cards/card.dart';
import 'package:card_battle_game/models/database/card_database.dart';
import 'package:card_battle_game/models/database/user_storage.dart';
import 'package:card_battle_game/screens/map_screen.dart';
import 'package:card_battle_game/screens/stage_completion_screen.dart';
import 'package:card_battle_game/services/notification_service.dart';
import 'package:card_battle_game/widgets/card_widget.dart';
import 'package:flutter/material.dart';

class ShopScreen extends StatefulWidget {
  final UserData userData;

  const ShopScreen({required this.userData});

  @override
  _ShopScreenState createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Map<GameCard, int> shopCards = {};
  final int cardPrice = 50;
  final int removePrice = 30;
  GameCard? selectedCard;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  void _loadData() async {
    var cards = await CardDatabase.generateRewards(
        widget.userData.activeGame!.stage, 4);
    Map<GameCard, int> cardsWithPrices = {
      for (var card in cards) card: getGameCardPrice(card)
    };
    setState(() {
      shopCards.addAll(cardsWithPrices);
    });
  }

  int getGameCardPrice(GameCard card) {
    var minPrice = 30;
    var maxPrice = 75;
    switch (card.rarity) {
      case CardRarity.Common:
        minPrice = 30;
        maxPrice = 75;
        break;
      case CardRarity.Uncommon:
        minPrice = 50;
        maxPrice = 125;
      case CardRarity.Rare:
        minPrice = 100;
        maxPrice = 200;
      case CardRarity.UltraRare:
        minPrice = 175;
        maxPrice = 300;
      case CardRarity.Legendary:
        minPrice = 275;
        maxPrice = 400;
    }
    return Random().nextInt(maxPrice - minPrice) + minPrice;
  }

  void advanceStage() {
    widget.userData.activeGame!.advanceStage(RewardOptions.none, null);
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => NodeMapScreen(userData: widget.userData)),
    );
  }

  void buyCard() {
    bool isShop = _tabController.index == 0;
    int price = 100000;
    if (selectedCard != null) {
      if (isShop &&
          shopCards.isNotEmpty &&
          shopCards.entries.isNotEmpty &&
          selectedCard != null) {
        var selectedShopCard =
            shopCards.entries.firstWhere((w) => w.key == selectedCard);
        price = selectedShopCard.value;
      }

      if (widget.userData.activeGame!.gold >= price) {
        setState(() {
          widget.userData.activeGame!.gold -= price;
          widget.userData.activeGame!.player.deck.add(selectedCard!);
          shopCards.remove(selectedCard);
          selectedCard = null;
        });
      }
    }
  }

  void removeCard() {
    if (widget.userData.activeGame!.gold < removePrice) {
      NotificationService.showDialogMessage(
          context, "You don't have enough gold for this action",
          title: 'Not enough gold');
    }
    if (selectedCard != null &&
        widget.userData.activeGame!.gold >= removePrice) {
      setState(() {
        widget.userData.activeGame!.gold -= removePrice;
        widget.userData.activeGame!.player.deck.remove(selectedCard!);
        selectedCard = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
        canPop: false,
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.black,
            title: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Shop',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                Text('Gold: ${widget.userData.activeGame!.gold}',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white))
              ],
            ),
            bottom: TabBar(
              controller: _tabController,
              labelStyle: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
              labelColor: Colors.white,
              tabs: [
                Tab(text: "Shop Inventory"),
                Tab(text: "My Deck"),
              ],
              onTap: (int value) => {
                setState(() {
                  selectedCard = null;
                })
              },
            ),
          ),
          body: Stack(
            children: [
              // Background Image
              Positioned.fill(
                child: Image.asset(
                  'assets/images/${widget.userData.background}',
                  fit: BoxFit.cover,
                ),
              ),
              Column(
                children: [
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        // Shop Inventory Tab
                        _buildCardGrid(shopCards.keys.toList(), true),

                        // My Deck Tab
                        _buildCardGrid(
                            widget.userData.activeGame!.player.deck, false),
                      ],
                    ),
                  ),
                  _buildSelectedCardPanel(),
                ],
              ),
            ],
          ),
        ));
  }

  Widget _buildCardGrid(List<GameCard> cards, bool isShop) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: cards.length,
        itemBuilder: (context, index) {
          final card = cards[index];
          return GestureDetector(
            onTap: () {
              setState(() {
                selectedCard = card;
              });
            },
            child: CardWidget(
              card: card,
              isSelected: selectedCard == card,
            ),
          );
        },
      ),
    );
  }

  Widget _buildSelectedCardPanel() {
    bool isShop = _tabController.index == 0;
    int price = isShop ? cardPrice : removePrice;
    if (isShop &&
        shopCards.isNotEmpty &&
        shopCards.entries.length > 0 &&
        selectedCard != null) {
      var selectedShopCard =
          shopCards.entries.firstWhere((w) => w.key == selectedCard);
      price = selectedShopCard.value;
    }
    String buttonText = isShop ? "Buy and add to deck" : "Remove from deck";
    VoidCallback? action = isShop ? buyCard : removeCard;

    return Container(
      padding: EdgeInsets.all(10),
      color: Colors.black54,
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (selectedCard != null) ...[
                Text('Card: ${selectedCard!.name}',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                Text('Price: $price',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white))
              ] else ...[
                Text('Tap a card to select it',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white))
              ],
            ],
          ),
          SizedBox(height: 5),
          Text(
              selectedCard == null
                  ? ''
                  : selectedCard!.fullDescription ??
                      selectedCard!.shortDescription ??
                      '',
              style: TextStyle(color: Colors.white70)),
          SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton(
                onPressed: action,
                child: Text(buttonText),
              ),
              ElevatedButton(
                onPressed: advanceStage,
                child: Text('Leave shop'),
              ),
            ],
          )
        ],
      ),
    );
  }
}
