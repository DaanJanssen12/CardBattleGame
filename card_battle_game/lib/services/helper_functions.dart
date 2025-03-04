import 'dart:math';

import 'package:card_battle_game/animations/booster_pack_animation.dart';
import 'package:card_battle_game/models/cards/action_card.dart';
import 'package:card_battle_game/models/cards/card.dart';
import 'package:card_battle_game/models/constants.dart';
import 'package:card_battle_game/models/enums/action_card_type.dart';

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
      default:
        return "";
    }
  }

  static String getBoosterPackDescription(BoosterPackType type) {
    switch (type) {
      case BoosterPackType.common:
        return "This pack contains 3 cards, most will be common but with a slight change of getting an uncommon card.";
      case BoosterPackType.uncommon:
        return "Runebound Pack";
      case BoosterPackType.rare:
        return "Stormcaller's Pack";
      case BoosterPackType.best:
        return "Forbidden Archives Pack";
      default:
        return "";
    }
  }

  static GameCard getConstantDrawCard() {
    var card = ActionCard(
        'Exchange',
        'assets/images/actions/Exchange.png',
        Constants.cardExchangeCost,
        'In exchange for 3 mana you can draw a card.',
        'This is a card always in your hand, which you can play to draw a card in exchange for 3 mana.');
    card.actionCardType = ActionCardType.draw;
    card.value = 1;
    card.oneTimeUse = true;
    return card;
  }

  static List<CardRarity> getBoosterPackCardRarities(BoosterPackType type) {
    switch (type) {
      case BoosterPackType.common:
        bool lastCardUncommon = Random().nextInt(100) > 70;
        return [
          CardRarity.Common,
          CardRarity.Common,
          CardRarity.values[lastCardUncommon ? 1 : 0]
        ];
      case BoosterPackType.uncommon:
        bool lastCardRare = Random().nextInt(100) > 70;
        return [
          CardRarity.Common,
          CardRarity.Uncommon,
          CardRarity.values[lastCardRare
              ? CardRarity.Rare.index
              : CardRarity.Uncommon.index]];
      case BoosterPackType.rare:
        bool lastCardUltraRare = Random().nextInt(100) > 70;
        return [
          CardRarity.Uncommon,
          CardRarity.Rare,
          CardRarity.values[lastCardUltraRare
              ? CardRarity.UltraRare.index
              : CardRarity.Rare.index]];
      case BoosterPackType.best:
        bool firstCardRare = Random().nextInt(100) > 50;
        bool lastCardLegendary = Random().nextInt(100) > 70;
        return [
          CardRarity.values[firstCardRare
              ? CardRarity.Rare.index
              : CardRarity.Uncommon.index],
          CardRarity.UltraRare,
          CardRarity.values[lastCardLegendary
              ? CardRarity.Legendary.index
              : CardRarity.UltraRare.index]
        ];
      default:
        return [];
    }
  }

  static List<String> getStarterDeck(int i) {
    List<String> cardIds = [];
    // Magician's pack
    if (i == 0) {
      cardIds = [
        'monster_penguin_mage',
        'monster_water_droplet',
        'upgrade_heal',
        'upgrade_strengthen',
        'action_energy_blast'
      ];
    }
    // Farmer's pack
    if (i == 1) {
      cardIds = [
        'monster_worker_bee',
        'monster_mushroom_boy',
        'monster_sheep',
        'upgrade_honey',
        'action_harvest'
      ];
    }
    // Demon's pack
    if (i == 2) {
      cardIds = [
        'monster_fire_dog',
        'monster_bat',
        'upgrade_heal',
        'upgrade_strengthen',
        'action_draw'
      ];
    }
    return cardIds;
  }
}
