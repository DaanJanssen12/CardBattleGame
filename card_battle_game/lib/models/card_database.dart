import 'dart:convert';
import 'dart:math';

import 'package:card_battle_game/models/card.dart';
import 'package:flutter/services.dart';

class CardDatabase {
  static String filePath = 'assets/card_database.json';
  static List<MonsterCard> monsterCards = [];
  static List<UpgradeCard> upgradeCards = [];
  static List<ActionCard> actionCards = [];

  static Future<List<GameCard>> getCards(List<String> cardIds) async {
    await loadCardsFromJson(filePath);
    var filteredCards = [monsterCards, upgradeCards, actionCards]
        .expand((gameCard) => gameCard)
        .where((w) => cardIds.contains(w.id))
        .toList();

    List<GameCard> returnCards = [];
    for (var id in cardIds) {
      var card = filteredCards.firstWhere((w) => w.id == id).clone();
      returnCards.add(card);
    }
    return returnCards;
  }

  static Future<List<GameCard>> generateDeck(int amount) async {
    await loadCardsFromJson(filePath);
    List<GameCard> deck = [];
    for (var i = 0; i < amount; i++) {
      var card = getRandomCard().clone();
      deck.add(card);
    }
    if (!deck.any((card) => card.isMonster())) {
      deck.removeAt(0);
      deck.add(getRandomCard(type: 'monster').clone());
    }
    return deck;
  }

  static Future<List<GameCard>> generateRewards(int stage, int amount) async {
    await loadCardsFromJson(filePath);
    List<GameCard> rewards = [];
    for (var i = 0; i < amount; i++) {
      var card = getRandomCard().clone();
      rewards.add(card);
    }
    return rewards;
  }

  static GameCard getRandomCard({String? type = null}) {
    var rng = Random();
    if (type == null) {
      switch (rng.nextInt(3)) {
        case 0:
          type = 'monster';
          break;
        case 1:
          type = 'upgrade';
          break;
        case 2:
          type = 'action';
          break;
      }
    }
    switch (type!) {
      case 'monster':
        return monsterCards[rng.nextInt(monsterCards.length)];
      case 'upgrade':
        return upgradeCards[rng.nextInt(upgradeCards.length)];
      case 'action':
        return actionCards[rng.nextInt(actionCards.length)];
    }
    return monsterCards[rng.nextInt(monsterCards.length)];
  }

  static Future<void> loadCardsFromJson(String filePath) async {
    final String jsonString = await rootBundle.loadString(filePath);
    final dynamic jsonResponse = json.decode(jsonString);

    monsterCards = (jsonResponse['monsters'] as List<dynamic>).map((cardJson) {
      return MonsterCard.fromJson(cardJson);
    }).toList();
    upgradeCards = (jsonResponse['upgrades'] as List<dynamic>).map((cardJson) {
      return UpgradeCard.fromJson(cardJson);
    }).toList();
    actionCards = (jsonResponse['actions'] as List<dynamic>).map((cardJson) {
      return ActionCard.fromJson(cardJson);
    }).toList();
  }
}
