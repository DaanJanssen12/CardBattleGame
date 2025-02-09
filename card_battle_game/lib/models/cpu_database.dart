import 'dart:convert';
import 'dart:math';
import 'package:card_battle_game/models/cpu.dart';
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
      int? stage, List<String> excludeCpuIds) async {
    await loadData();
    if (cpuPlayers.isEmpty) {
      return null;
    }
    var possibleCpuPlayers =
        cpuPlayers.where((w) => !excludeCpuIds.contains(w.id ?? '')).toList();
    if (stage == null) {
      return possibleCpuPlayers[Random().nextInt(possibleCpuPlayers.length)];
    } else {
      possibleCpuPlayers = possibleCpuPlayers
          .where((w) =>
              w.possibleFromStage <= stage && w.possibleUntillStage >= stage)
          .toList();
      if (possibleCpuPlayers.isEmpty) {
        return await getRandomCpuPlayer(null, excludeCpuIds);
      }
      return possibleCpuPlayers[Random().nextInt(possibleCpuPlayers.length)];
    }
  }
}
