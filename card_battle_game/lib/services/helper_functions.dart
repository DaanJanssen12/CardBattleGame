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

  static GameCard getConstantDrawCard(){
    var card = ActionCard(
      'Exchange', 
      'assets/images/actions/Exchange.png', 
      Constants.cardExchangeCost, 
      'In exchange for 3 mana you can draw a card.', 
      'This is a card always in your hand, which you can play to draw a card in exchange for 3 mana.');
    card.actionCardType = ActionCardType.draw;
    card.value = 1;
    return card;
  }
}
