import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:card_battle_game/models/card.dart';
import 'package:card_battle_game/models/card_database.dart';
import 'package:card_battle_game/models/cpu.dart';
import 'package:card_battle_game/models/cpu_database.dart';
import 'package:card_battle_game/models/monster_card.dart';
import 'package:card_battle_game/models/player.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

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
      print(jsonString);
      final dynamic jsonResponse = json.decode(jsonString);
      print(jsonResponse);
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

  static Future<void> setBackground(String background) async {
    var data = await getUserData();
    data.background = background;
    await saveUserData(data);
  }

  static Future<void> endGame(int stage, GameCard? reward) async {
    var data = await getUserData();
    if (stage > data.highscore) {
      data.highscore = stage;
    }
    if (reward != null) {
      data.cards.add(reward.id);
    }
    data.activeGame = null;
    await saveUserData(data);
  }

  static Future<void> updateActiveGame(Game game) async {
    var data = await getUserData();
    data.activeGame = game;
    await saveUserData(data);
  }
}

class UserData {
  late Deck deck;
  late String name;
  late List<String> cards;
  late Game? activeGame;
  late String background;
  late int highscore;

  UserData();
  factory UserData.fromJson(Map<String, dynamic> json) {
    var data = UserData();
    data.name = json['name'];
    data.background = json['background'] ?? "forrest.jpg";
    data.deck = Deck.fromJson(json['deck']);
    data.cards = json['cards'] != null
        ? (json['cards'] as List<dynamic>).map((m) => m.toString()).toList()
        : [];
    data.activeGame =
        json['activeGame'] != null ? Game.fromJson(json['activeGame']) : null;
    data.highscore = json['highscore'] ?? 0;
    return data;
  }

  Future<void> newGame() async {
    activeGame = Game();
    var player = await asPlayer();
    activeGame!.setPlayer(player);
  }

  Future<void> endGame(int currentStage, GameCard? reward) async {
    await UserStorage.endGame(currentStage, reward);
    activeGame = null;
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'cards': cards,
      'background': background,
      'deck': deck.toJson(),
      'highscore': highscore,
      'activeGame': activeGame?.toJson()
    };
  }

  Future<Player> asPlayer() async {
    var player = Player(name: name);
    player.deck = await deck.asDeck();
    return player;
  }

  Future<List<GameCard>> availableCards() async {
    var availableCards = await CardDatabase.getCards(cards);
    return availableCards;
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

class Game {
  late int stage;
  late String mascot;
  late Player player;
  late bool playerHasLost = false;
  List<String> versedCPUs = [];
  List<GameCard> selectedRewards = [];
  Game() {
    stage = 0;
    mascot = '';
    player = Player(name: '');
  }

  void setMascot(MonsterCard card) {
    player.setMascot(card);
    mascot = card.id;
  }

  void stageUp() {
    stage++;
  }

  void setPlayer(Player player) {
    this.player = player;
  }

  void endGame() {
    playerHasLost = true;
  }

  Future<CpuPlayer> initCPU() async {
    var cpuPlayer = await CpuDatabase.getRandomCpuPlayer(stage, versedCPUs);
    if (cpuPlayer == null) {
      return await generateNewCPU();
    }
    await cpuPlayer.init();
    versedCPUs.add(cpuPlayer.id ?? Uuid().v4());
    return cpuPlayer;
  }

  Future<CpuPlayer> generateNewCPU() async {
    var cpu = CpuPlayer(name: 'Enemy');
    if (stage <= 1) {
      cpu.level = CpuLevels.easy;
      cpu.strategy = CpuStrategy.random;
    } else {
      cpu.level = CpuLevels.easy;
      cpu.strategy =
          CpuStrategy.values[Random().nextInt(CpuStrategy.values.length)];
    }
    await cpu.generateDeck();
    return cpu;
  }

  factory Game.fromJson(Map<String, dynamic> json) {
    var data = Game();
    data.stage = json['stage'];
    data.mascot = json['mascot'];
    data.player = Player.fromJson(json['player']);
    data.versedCPUs =
        (json['versedCPUs'] as List<dynamic>).map((m) => m.toString()).toList();
    data.selectedRewards = (json['selectedRewards'] as List<dynamic>)
        .map((m) => GameCard.fromJson(m))
        .toList();
    return data;
  }
  Map<String, dynamic> toJson() {
    return {
      'stage': stage,
      'mascot': mascot,
      'player': player.toJson(),
      'versedCPUs': versedCPUs,
      'selectedRewards': selectedRewards.map((m) => m.toJson()).toList()
    };
  }
}
