import 'dart:convert';
import 'dart:math';

import 'package:card_battle_game/models/card.dart';
import 'package:flutter/services.dart';

class CardDatabase {
  static String filePath = 'assets/card_database.json';
  static Future<List<GameCard>> getCards(List<String> cardIds) async {
    var allCards = await loadCardsFromJson(filePath);
    var filteredCards =
        allCards.where((w) => cardIds.contains(w.id)).toList();

    List<GameCard> returnCards = [];
    for (var id in cardIds) {
      print('Getting $id');
      var card = filteredCards.firstWhere((w) => w.id == id).clone();
      returnCards.add(card);
    }
    return returnCards;
  }

  static Future<List<GameCard>> generateDeck(int amount) async {
    var allCards = await loadCardsFromJson(filePath);
    List<GameCard> deck = [];
    for (var i = 0; i < amount; i++) {
      var card = allCards[Random().nextInt(allCards.length)].clone();
      deck.add(card);
    }
    return deck;
  }

  static Future<List<GameCard>> generateRewards(int stage, int amount) async{
    var allCards = await loadCardsFromJson(filePath);
    List<GameCard> rewards = [];
    for (var i = 0; i < amount; i++) {
      var card = allCards[Random().nextInt(allCards.length)].clone();
      rewards.add(card);
    }
    return rewards;
  }
}

Future<List<GameCard>> loadCardsFromJson(String filePath) async {
  // Read JSON from asset
  final String jsonString = await rootBundle.loadString(filePath);

  // Decode the JSON string into a List
  final List<dynamic> jsonResponse = json.decode(jsonString);

  // Convert the list of maps to GameCard instances
  List<GameCard> cards = jsonResponse.map((cardJson) {
    return GameCard.fromJson(cardJson); // Default to GameCard for other types
  }).toList();

  return cards;
}
