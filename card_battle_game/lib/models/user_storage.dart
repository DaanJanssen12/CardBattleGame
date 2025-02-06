import 'dart:convert';
import 'dart:io';

import 'package:card_battle_game/models/card.dart';
import 'package:card_battle_game/models/card_database.dart';
import 'package:card_battle_game/models/player.dart';
import 'package:flutter/services.dart';

class UserStorage {
  static String filePath = 'assets/user_data.json';

  static Future<UserData> getUserData() async {
    final String jsonString = await rootBundle.loadString(filePath);
    final dynamic jsonResponse = json.decode(jsonString);

    return UserData.fromJson(jsonResponse);
  }

  static Future<void> saveUserData(UserData userData) async{
     final file = File(filePath);
  await file.writeAsString(jsonEncode(userData.toJson()));
  }

  static Future<void> setName(String name) async{
    var data = await getUserData();
    data.name = name;
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

  Map<String, dynamic> toJson(){
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
    data.cards = (json['cards'] as List<dynamic>).map((m) => m.toString()).toList();
    return data;
  }
  Map<String, dynamic> toJson(){
    return {
      'cards': cards,
    };
  }

  Future<List<GameCard>> asDeck() async {
    return await CardDatabase.getCards(cards);
  }
}
