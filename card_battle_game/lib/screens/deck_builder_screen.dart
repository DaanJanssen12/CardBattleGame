import 'dart:math';
import 'package:card_battle_game/animations/booster_pack_animation.dart';
import 'package:card_battle_game/models/cards/card.dart';
import 'package:card_battle_game/models/constants.dart';
import 'package:card_battle_game/models/database/card_database.dart';
import 'package:card_battle_game/models/database/user_storage.dart';
import 'package:card_battle_game/screens/main_menu.dart';
import 'package:card_battle_game/services/helper_functions.dart';
import 'package:card_battle_game/services/notification_service.dart';
import 'package:card_battle_game/widgets/card_details_dialog.dart';
import 'package:flutter/material.dart';
import 'package:card_battle_game/widgets/card_widget.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart'; // Your existing card widget

class DeckBuilderScreen extends StatefulWidget {
  const DeckBuilderScreen(
      {super.key,
      required this.userData,
      this.playerHasNoCardsYet = false,
      this.openPage = 0});
  final UserData userData;
  final bool playerHasNoCardsYet;
  final int openPage;

  @override
  _DeckBuilderScreenState createState() => _DeckBuilderScreenState();
}

class _DeckBuilderScreenState extends State<DeckBuilderScreen>
    with SingleTickerProviderStateMixin {
  List<GameCard> deck = [];
  List<GameCard> availableCards = [];
  Map<BoosterPackType, int> boosterPacks = {};
  late TabController _tabController;
  bool _hasNoCardsYet = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
    _hasNoCardsYet = widget.playerHasNoCardsYet;
    _tabController.index = widget.openPage;
  }

  Future<void> _loadData() async {
    deck = await widget.userData.deck.asDeck();
    availableCards = await widget.userData.availableCards();
    boosterPacks = widget.userData.boosterPacks;
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
    if (_hasNoCardsYet) {
      return Scaffold(
          appBar: AppBar(
            title: Text("Choose your deck"),
            backgroundColor: Colors.white,
          ),
          body: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                'assets/images/${widget.userData.background}',
                fit: BoxFit.cover,
              ),
              Column(
                children: [
                  Text(
                      "Our best players have compiled a couple of starter decks. You can pick one.",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                  Expanded(
                    child: ListView.separated(
                      separatorBuilder: (context, index) =>
                          SizedBox(height: 10), // Space between items
                      padding: EdgeInsets.fromLTRB(5, 5, 5, 5),
                      itemCount: 3,
                      itemBuilder: (context, index) {
                        var text = getPackName(index);
                        var subTitle = getPackDescription(index);

                        return Container(
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10)),
                          child: ListTile(
                            title: Text(text),
                            subtitle: Text(subTitle),
                            trailing: ElevatedButton(
                              onPressed: () => {_chooseStarterDeck(index)},
                              child: Text("Choose"),
                            ),
                          ),
                        );
                      },
                    ),
                  )
                ],
              )
            ],
          ));
    } else {
      return PopScope(
          canPop: false,
          child: Scaffold(
            appBar: AppBar(
              title: Text("Deck Builder"),
              backgroundColor: Colors.white,
              leading: IconButton(
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                MainMenu(userData: widget.userData)));
                  },
                  icon: Icon(Icons.arrow_back)),
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
          ));
    }
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
                  return _buildCardList(deck, "Your Deck", true, 300, null);
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
                      availableCards, "Available Cards", false, 300, null);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBoosterPacksTab() {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/images/${widget.userData.background}',
          fit: BoxFit.cover,
        ),
        Column(
          children: [
            Text(
                "Open packs to gain new cards. You get cards by winning boss battles.",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
            Expanded(
              child: ListView.separated(
                separatorBuilder: (context, index) =>
                    SizedBox(height: 10), // Space between items
                padding: EdgeInsets.fromLTRB(5, 5, 5, 5),
                itemCount: BoosterPackType.values.length - 1,
                itemBuilder: (context, index) {
                  var amount =
                      boosterPacks[BoosterPackType.values[index + 1]] ?? 0;
                  return Container(
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10)),
                    child: ListTile(
                      title: Text(Functions.getBoosterPackName(
                          BoosterPackType.values[index + 1])),
                      //subtitle: Text(Functions.getBoosterPackDescription(BoosterPackType.values[index + 1])),
                      leading: Text('($amount)'),
                      trailing: ElevatedButton(
                        onPressed: () => amount > 0
                            ? _openBoosterPack(
                                BoosterPackType.values[index + 1])
                            : null,
                        child: Text("Open"),
                      ),
                    ),
                  );
                },
              ),
            ),
            Row(
              children: [
                Expanded(
                    child: Padding(
                        padding: EdgeInsets.all(10),
                        child: ElevatedButton(
                            onPressed: () {
                              showDialog(
                                  context: context,
                                  barrierDismissible: true,
                                  builder: (BuildContext context) {
                                    return StatefulBuilder(
                                        builder: (context, setState) {
                                      return _buildCardExchangeDialog(setState);
                                    });
                                  });
                            },
                            child: Text('Exchange cards'))))
              ],
            ),
            if (Constants.testMode) ...[
              Row(
                children: [
                  Expanded(
                      child: Padding(
                          padding: EdgeInsets.all(10),
                          child: ElevatedButton(
                              onPressed: () {
                                var type = BoosterPackType.values[Random()
                                    .nextInt(BoosterPackType.values.length)];
                                setState(() {
                                  boosterPacks[type] == null
                                      ? boosterPacks[type] = 1
                                      : boosterPacks[type] =
                                          boosterPacks[type]! + 1;
                                });
                              },
                              child: Text('Add pack'))))
                ],
              )
            ]
          ],
        ),
      ],
    );
  }

  void _openBoosterPack(BoosterPackType type) async {
    setState(() {
      boosterPacks[type] = boosterPacks[type]! - 1;
    });
    widget.userData.boosterPacks = boosterPacks;
    await showDialog(
      context: context,
      barrierDismissible: false, // Prevents accidental closing
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent, // Makes it overlay-like
          child: BoosterPackOpenAnimation(
            type: type,
            userData: widget.userData,
            rewardsCards: [],
          ),
        );
      },
    );
    await _loadData();
  }

  String getPackName(int i) {
    if (i == 0) {
      return "Magician's Pack";
    }
    if (i == 1) {
      return "Farmer's Pack";
    }
    if (i == 2) {
      return "Demon's Pack";
    }
    return "";
  }

  String getPackDescription(int i) {
    if (i == 0) {
      return "This deck is all about mana usage";
    }
    if (i == 1) {
      return "This deck has a healthy balance of offense and defense";
    }
    if (i == 2) {
      return "This deck is all about offense";
    }
    return "";
  }

  Future<List<GameCard>> getStarterDeckCards(int i) async {
    var cards = await CardDatabase.getCards(Functions.getStarterDeck(i));
    return cards;
  }

  Future<void> _chooseStarterDeck(int i) async {
    var packName = getPackName(i);
    var deckCards = await getStarterDeckCards(i);
    await NotificationService.showDialogMessageWithActions(
        context, "You sure you want to pick the $packName", [
      TextButton(
          onPressed: () async {
            Navigator.of(context).pop();
            widget.userData.deck.cards
                .addAll(deckCards.map((m) => m.id).toList());
            await UserStorage.saveUserData(widget.userData);
            await showDialog(
              context: context,
              barrierDismissible: false, // Prevents accidental closing
              builder: (BuildContext context) {
                return Dialog(
                  backgroundColor: Colors.transparent, // Makes it overlay-like
                  child: BoosterPackOpenAnimation(
                      type: BoosterPackType.starterDeck,
                      userData: widget.userData,
                      rewardsCards: deckCards),
                );
              },
            );
            _loadData();
            setState(() {
              _hasNoCardsYet = false;
            });
          },
          child: Text('Yes!')),
      TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            return;
          },
          child: Text('Not sure yet...'))
    ]);
  }

  Widget _buildCardList(List<GameCard> cards, String title, bool isDeck,
      double height, int? maxCards) {
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
                maxCards != null
                    ? '${cards.length} / $maxCards Cards'
                    : '${cards.length} Cards',
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
          height: height,
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

  List<GameCard> cardsToExchange = [];
  List<GameCard> allCards = [];
  int maxExchangeCards = 5;
  void addCardToExchange(GameCard card) {
    if (cardsToExchange.length == maxExchangeCards) {
      return;
    }
    setState(() {
      card.isSetForExchange = true;
      cardsToExchange.add(card);
    });
  }

  void removeCardFromExchange(GameCard card) {
    setState(() {
      card.isSetForExchange = false;
      cardsToExchange.remove(card);
    });
  }

  void exchangeCards() {
    if (cardsToExchange.length < maxExchangeCards) {
      NotificationService.showSnackbar(context,
          "To exchange your cards for a booster pack you need to add a total of $maxExchangeCards cards to exchange.");
      return;
    }
    var amountOfCards = deck.length + availableCards.length;
    if (amountOfCards - maxExchangeCards < Constants.playerMinDeckSize) {
      NotificationService.showSnackbar(context,
          "You can't exchange, you need to have at least ${Constants.playerMinDeckSize} cards left after exchanging.");
      return;
    }
    CardRarity minRarity = cardsToExchange.first.rarity;
    CardRarity maxRarity = cardsToExchange.first.rarity;
    BoosterPackType boosterPackType = BoosterPackType.common;
    for (var card in cardsToExchange) {
      if (card.rarity.index < minRarity.index) {
        minRarity = card.rarity;
      }
      if (card.rarity.index > maxRarity.index) {
        maxRarity = card.rarity;
      }
    }
    switch (minRarity) {
      case CardRarity.Common:
        boosterPackType = BoosterPackType.common;
        break;
      case CardRarity.Uncommon:
        boosterPackType = BoosterPackType.uncommon;
        break;
      case CardRarity.Rare:
        boosterPackType = BoosterPackType.rare;
        break;
      case CardRarity.UltraRare:
        boosterPackType = BoosterPackType.best;
        break;
      case CardRarity.Legendary:
        boosterPackType = BoosterPackType.best;
        break;
    }

    bool addedTooHighValueCards = maxRarity.index > minRarity.index;
    var text =
        'You are going to exchange 5 cards for 1 ${Functions.getBoosterPackName(boosterPackType)}.\n\n';
    if (addedTooHighValueCards) {
      text +=
          'Warning: for this pack you only need to exchange ${minRarity.name} cards.\nYou have included a ${maxRarity.name} card.\n\n';
    }
    text += 'Are you sure?';
    NotificationService.showDialogMessageWithActions(
        context,
        text,
        [
          TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                return;
              },
              child: Text('No, take me back')),
          TextButton(
              onPressed: () async {
                var userData = await UserStorage.getUserData();
                for (var card in cardsToExchange) {
                  if (card.isInDeck) {
                    userData.deck.cards.remove(card.id);
                  } else {
                    userData.cards.remove(card.id);
                  }
                }
                userData.addBoosterPack(boosterPackType);
                await UserStorage.saveUserData(userData);

                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => DeckBuilderScreen(
                          userData: userData,
                          playerHasNoCardsYet: false,
                          openPage: 1)),
                );
                return;
              },
              child: Text('Yes!'))
        ],
        title: "Exchange");
  }

  Widget _buildCardExchangeDialog(StateSetter setState) {
    return Scaffold(
        floatingActionButton:
            ElevatedButton(onPressed: exchangeCards, child: Text("Exchange")),
        body: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/images/${widget.userData.background}',
              fit: BoxFit.cover,
            ),
            Column(
              children: [
                Expanded(
                  flex: 2,
                  child: DragTarget<GameCard>(
                    onWillAcceptWithDetails: (card) {
                      return card.data.isSetForExchange;
                    },
                    onAcceptWithDetails: (card) {
                      setState(() => removeCardFromExchange(card.data));
                    },
                    builder: (context, candidateData, rejectedData) {
                      allCards = [];
                      allCards.addAll(deck.where((w) => !w.isSetForExchange));
                      allCards.addAll(
                          availableCards.where((w) => !w.isSetForExchange));
                      return _buildCardList(
                          allCards, "Your Cards", true, 450, null);
                    },
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: DragTarget<GameCard>(
                    onWillAcceptWithDetails: (card) {
                      return !card.data.isSetForExchange;
                    },
                    onAcceptWithDetails: (card) {
                      setState(() => addCardToExchange(card.data));
                    },
                    builder: (context, candidateData, rejectedData) {
                      return _buildCardList(cardsToExchange,
                          "Cards to Exchange", false, 200, maxExchangeCards);
                    },
                  ),
                ),
              ],
            ),
          ],
        ));
  }
}
