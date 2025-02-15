import 'dart:convert';
import 'dart:math';

import 'package:card_battle_game/models/action_card.dart';
import 'package:card_battle_game/models/card.dart';
import 'package:card_battle_game/models/cpu.dart';
import 'package:card_battle_game/models/monster_card.dart';
import 'package:card_battle_game/models/upgrade_card.dart';
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
      if (filteredCards.any((a) => a.id == id)) {
        var card = filteredCards.firstWhere((w) => w.id == id).clone();
        returnCards.add(card);
      }
    }
    return returnCards;
  }

  static Future<List<GameCard>> generateDeck(
      int amount, CpuStrategy? playStyle, CpuLevels? level) async {
    await loadCardsFromJson(filePath);
    List<GameCard> deck = [];
    if (level == null && playStyle == null) {
      //Completely random
      for (var i = 0; i < amount; i++) {
        var card = getRandomCard().clone();
        deck.add(card);
      }
    } else {
      switch (playStyle!) {
        case CpuStrategy.random:
          deck = await generateDeckByPercentages(level!, amount, 33, 33, 33);
          break;
        case CpuStrategy.defensive:
          deck = await generateDeckByPercentages(level!, amount, 40, 40, 20);
          break;
        case CpuStrategy.offensive:
          deck = await generateDeckByPercentages(level!, amount, 50, 25, 25);
          break;
      }
    }
    if (!deck.any((card) => card.isMonster())) {
      deck.removeAt(0);
      deck.add(getRandomCard(type: 'monster').clone());
    }
    return deck;
  }

  static Future<List<GameCard>> generateDeckByPercentages(
      CpuLevels level,
      int amountOfCards,
      int monsterCardsPercentage,
      int upgradeCardsPercentage,
      int actionCardsPercentage) async {
    List<GameCard> list = [];
    addCards(list, getAmount(amountOfCards, monsterCardsPercentage), 'monster',
        level);
    addCards(list, getAmount(amountOfCards, upgradeCardsPercentage), 'upgrade',
        level);
    addCards(
        list, getAmount(amountOfCards, actionCardsPercentage), 'action', level);
    if (list.length < amountOfCards) {
      addCards(list, 1, 'monster', level);
      addCards(list, 1, 'upgrade', level);
      addCards(list, 1, 'action', level);
    }
    return list;
  }

  static Future<List<GameCard>> addCards(List<GameCard> listToAddTo, int amount,
      String type, CpuLevels level) async {
    for (var i = 0; i < amount; i++) {
      listToAddTo
          .add(getRandomCard(type: type, rarity: getRarity(level)).clone());
    }
    return listToAddTo;
  }

  static CardRarity getRarity(CpuLevels level) {
    switch (level) {
      case CpuLevels.easy:
        return generateRarity(80, 20, 0, 0, 0);
      case CpuLevels.medium:
        return generateRarity(40, 35, 15, 5, 0);
      case CpuLevels.hard:
        return generateRarity(35, 30, 20, 15, 0);
      case CpuLevels.expert:
        return generateRarity(20, 20, 20, 20, 20);
    }
  }

  static int getAmount(int amount, int percentage) {
    return ((amount / 100) * percentage).floor();
  }

  static Future<List<GameCard>> generateRewards(int stage, int amount) async {
    await loadCardsFromJson(filePath);
    List<GameCard> rewards = [];
    for (var i = 0; i < amount; i++) {
      var card = getRandomCard(rarity: getRandomRarity(stage)).clone();
      rewards.add(card);
    }
    return rewards;
  }

  static CardRarity getRandomRarity(int? stage) {
    stage ??= 1;
    switch (stage) {
      case < 5:
        return generateRarity(95, 4, 1, 0, 0);
      case < 10:
        return generateRarity(65, 30, 8, 2, 1);
      case < 15:
        return generateRarity(40, 30, 10, 5, 2);
      case < 20:
        return generateRarity(30, 30, 15, 10, 3);
      case >= 20:
        return generateRarity(25, 25, 15, 10, 5);
    }

    return CardRarity.Common;
  }

  static CardRarity generateRarity(
      int common, int uncommon, int rare, int ultraRare, int legendary) {
    var totalPercentagePool = common + uncommon + rare + ultraRare + legendary;
    var randomGeneratedNumber = Random().nextInt(totalPercentagePool) + 1;
    if (randomGeneratedNumber <= legendary) {
      return CardRarity.Legendary;
    }
    if (randomGeneratedNumber <= (legendary + ultraRare)) {
      return CardRarity.UltraRare;
    }
    if (randomGeneratedNumber <= (legendary + ultraRare + rare)) {
      return CardRarity.Rare;
    }
    if (randomGeneratedNumber <= (legendary + ultraRare + rare + uncommon)) {
      return CardRarity.Uncommon;
    }

    return CardRarity.Common;
  }

  static GameCard getRandomCard({String? type, CardRarity? rarity}) {
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
    var monsterCardPool = monsterCards;
    var upgradeCardPool = upgradeCards;
    var actionCardPool = actionCards;
    if (rarity != null) {
      var pool = getCardsWithRarity(monsterCardPool, rarity);
      if (pool != null && pool.isNotEmpty) {
        monsterCardPool = pool.map((m) => m.toMonster()).toList();
      } else {
        monsterCardPool = monsterCards;
      }

      pool = getCardsWithRarity(upgradeCardPool, rarity);
      if (pool != null && pool.isNotEmpty) {
        upgradeCardPool = pool.map((m) => m as UpgradeCard).toList();
      } else {
        upgradeCardPool = upgradeCards;
      }

      pool = getCardsWithRarity(actionCardPool, rarity);
      if (pool != null && pool.isNotEmpty) {
        actionCardPool = pool.map((m) => m as ActionCard).toList();
      } else {
        actionCardPool = actionCards;
      }
    }
    switch (type!) {
      case 'monster':
        return monsterCardPool[rng.nextInt(monsterCardPool.length)];
      case 'upgrade':
        return upgradeCardPool[rng.nextInt(upgradeCardPool.length)];
      case 'action':
        return actionCardPool[rng.nextInt(actionCardPool.length)];
    }
    return monsterCardPool[rng.nextInt(monsterCardPool.length)];
  }

  static List<GameCard>? getCardsWithRarity(
      List<GameCard> list, CardRarity rarity) {
    var iterable = list.where((w) => w.rarity == rarity);
    if (iterable.isEmpty) {
      return null;
    }
    var pool = iterable.toList();
    var previousRarity = rarity.getPrevious();
    var whileCounter = 0;
    while (pool.isEmpty) {
      if (previousRarity == null || whileCounter > 10) {
        break;
      }
      pool = list.where((w) => w.rarity == previousRarity).toList();
      previousRarity = previousRarity.getPrevious();
      whileCounter++;
    }
    return pool;
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
