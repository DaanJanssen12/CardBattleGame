import 'dart:convert';
import 'dart:math';
import 'package:card_battle_game/models/player/cpu.dart';
import 'package:flutter/services.dart';

class CpuDatabase {
  static String filePath = 'assets/cpu_data.json';
  static List<CpuPlayer> cpuPlayers = [];

  static Future<void> loadData() async {
    final String jsonString = await rootBundle.loadString(filePath);
    final List<dynamic> jsonResponse = json.decode(jsonString);

    cpuPlayers = jsonResponse.map((json) {
      return CpuPlayer.fromJson(json);
    }).toList();
  }

  static Future<CpuPlayer?> getRandomCpuPlayer(
      int? stage, List<String> excludeCpuIds, {String? tag}) async {
    await loadData();
    if (cpuPlayers.isEmpty) {
      return null;
    }
    var possibleCpuPlayers =
        cpuPlayers.where((w) => !excludeCpuIds.contains(w.id ?? '')
        && w.hasTag(tag)).toList();
    if (stage == null) {
      return possibleCpuPlayers[Random().nextInt(possibleCpuPlayers.length)];
    } else {
      possibleCpuPlayers = possibleCpuPlayers
          .where((w) =>
              w.possibleFromStage <= stage && w.possibleUntillStage >= stage)
          .toList();
      if (possibleCpuPlayers.isEmpty) {
        return null;
      }
      return possibleCpuPlayers[Random().nextInt(possibleCpuPlayers.length)];
    }
  }

  static Future<CpuPlayer> generateCPU(int? stage, {String? tag}) async{
    var level = CpuLevels.easy;
    var strategy = CpuStrategy.random;
    int deckSize = 5;
    if (stage == null) {
      level = CpuLevels.values[Random().nextInt(CpuLevels.values.length)];
      strategy =
          CpuStrategy.values[Random().nextInt(CpuStrategy.values.length)];
      deckSize = Random().nextInt(15);
    } else {
      switch (stage) {
        case > 0 && <= 5:
          level = CpuLevels.easy;
          strategy = CpuStrategy.random;
          break;
        case > 5 && <= 15:
          level = CpuLevels.medium;
          strategy = getRandomNonRandomStrategy();
          deckSize = Random().nextInt(8) + 5;
          break;
        case > 15:
          level = CpuLevels.hard;
          strategy = getRandomNonRandomStrategy();
          deckSize = Random().nextInt(15) + 5;
          break;
      }
    }

    var cpu = CpuPlayer(name: 'CPU');
    cpu.strategy = strategy;
    cpu.level = level;
    await cpu.generateDeck(deckSize);
    print('INIT CPU');
    print('LEVEL: $level');
    print('STRATEGY: $strategy');
    print('DECKSIZE: ${cpu.deck.length}');
    print('DECK:');
    for(var card in cpu.deck){
      print(card.name);
    }
    print('MASCOT: ${cpu.mascot}');
    return cpu;
  }

  static CpuStrategy getRandomNonRandomStrategy() {
    var options = [CpuStrategy.defensive, CpuStrategy.offensive];
    return options[Random().nextInt(options.length)];
  }
}
