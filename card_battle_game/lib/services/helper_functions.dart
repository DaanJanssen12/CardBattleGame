import 'package:card_battle_game/animations/booster_pack_animation.dart';

class Functions {
  static String getBoosterPackName(BoosterPackType type) {
    switch (type) {
      case BoosterPackType.common:
        return "Mana Trickles Pack";
      case BoosterPackType.uncommon:
        return "Runebound Pack";
      case BoosterPackType.rare:
        return "Stormcaller's Pack";
      case BoosterPackType.best:
        return "Forbidden Archives Pack";
    }
  }
}
