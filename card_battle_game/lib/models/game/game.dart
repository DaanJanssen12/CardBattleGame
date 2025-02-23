import 'package:card_battle_game/models/cards/card.dart';
import 'package:card_battle_game/models/constants.dart';
import 'package:card_battle_game/models/player/cpu.dart';
import 'package:card_battle_game/models/database/cpu_database.dart';
import 'package:card_battle_game/models/cards/monster_card.dart';
import 'package:card_battle_game/models/player/player.dart';
import 'package:card_battle_game/screens/map_screen.dart';
import 'package:card_battle_game/screens/stage_completion_screen.dart';
import 'package:uuid/uuid.dart';

class Game {
  late int stage;
  late String mascot;
  late Player player;
  late bool playerHasLost = false;
  List<String> versedCPUs = [];
  List<GameCard> selectedRewards = [];
  int amountOfSkipReward = Constants.gameAmountOfSkipReward;
  int amountOfUpgradeCard = Constants.gameAmountOfUpgradeCard;
  
  late MapStage? currentStage;
  late GameMap? currentMap;

  Game() {
    stage = 0;
    mascot = '';
    player = Player(name: '');
  }

  void setMascot(MonsterCard card) {
    player.setMascot(card);
    mascot = card.id;
  }

  void advanceStage(RewardOptions rewardOption, GameCard? selectedCard) {
    switch (rewardOption) {
      case RewardOptions.addCard:
        selectedRewards.add(selectedCard!);
        player.deck.add(selectedCard);
        break;
      case RewardOptions.skip:
        amountOfSkipReward--;
        break;
      case RewardOptions.upgradeCard:
        amountOfUpgradeCard--;
        break;
      case RewardOptions.none:
        break;
    }
    stage++;
    currentMap!.setCurrentStageCleared();
  }

  void setPlayer(Player player) {
    this.player = player;
  }

  void endGame() {
    playerHasLost = true;
  }

  Future<CpuPlayer> initCPU() async {
    var cpuPlayer = await CpuDatabase.getRandomCpuPlayer(stage, versedCPUs);
    print(cpuPlayer);
    if (cpuPlayer == null) {
      return await CpuDatabase.generateCPU(stage);
    }
    //print(cpuPlayer.id);
    print(cpuPlayer.name);
    await cpuPlayer.init();
    versedCPUs.add(cpuPlayer.id ?? Uuid().v4());
    return cpuPlayer;
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
