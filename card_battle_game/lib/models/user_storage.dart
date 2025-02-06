import 'dart:convert';
import 'dart:io';

import 'package:card_battle_game/models/card.dart';
import 'package:card_battle_game/models/card_database.dart';
import 'package:card_battle_game/models/player.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class UserStorage {
  static String fileName = 'user_data.json';

  static Future<String> _getFilePath() async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/$fileName';
  }

  static Future<UserData> getUserData() async {
    final filePath = await _getFilePath();
    final file = File(filePath);

    if (await file.exists()) {
      // Read existing file
      final String jsonString = await file.readAsString();
      final dynamic jsonResponse = json.decode(jsonString);
      return UserData.fromJson(jsonResponse);
    } else {
      // First time: Load from assets & create file
      final String jsonString =
          await rootBundle.loadString('assets/user_data.json');
      final dynamic jsonResponse = json.decode(jsonString);

      await file
          .writeAsString(json.encode(jsonResponse)); // Save to writable storage
      return UserData.fromJson(jsonResponse);
    }
  }

  static Future<void> saveUserData(UserData userData) async {
    final filePath = await _getFilePath();
    final file = File(filePath);
    var jsonStr = jsonEncode(userData.toJson());

    await file.writeAsString(jsonStr);
  }

  static Future<void> setName(String name) async {
    var data = await getUserData();
    data.name = name;
    await saveUserData(data);
  }
}

class UserData {
  late Deck deck;
  late String name;
  UserData();
  factory UserData.fromJson(Map<String, dynamic> json) {
    var data = UserData();
    data.name = json['name'];
    data.deck = Deck.fromJson(json['deck']);
    return data;
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'deck': deck.toJson(),
    };
  }

  Future<Player> asPlayer() async {
    var player = Player(name: name);
    player.deck = await deck.asDeck();
    return player;
  }
}

class Deck {
  late List<String> cards;
  Deck();
  factory Deck.fromJson(Map<String, dynamic> json) {
    var data = Deck();
    data.cards =
        (json['cards'] as List<dynamic>).map((m) => m.toString()).toList();
    return data;
  }
  Map<String, dynamic> toJson() {
    return {
      'cards': cards,
    };
  }

  Future<List<GameCard>> asDeck() async {
    var deck = await CardDatabase.getCards(cards);
    for (var card in deck) {
      card.isInDeck = true;
    }
    return deck;
  }
}
