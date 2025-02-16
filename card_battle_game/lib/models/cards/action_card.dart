import 'dart:math';
import 'package:card_battle_game/models/enums/action_card_type.dart';
import 'package:card_battle_game/models/cards/card.dart';
import 'package:card_battle_game/models/database/card_database.dart';
import 'package:card_battle_game/models/game/game_effect.dart';
import 'package:card_battle_game/models/player/player.dart';

class ActionCard extends GameCard {
  ActionCardType actionCardType;
  int value;
  String? extraData;

  ActionCard(super.name, super.imagePath, super.cost, super.shortDescription,
      super.fullDescription,
      {this.actionCardType = ActionCardType.draw, this.value = 1}) {
    type = 'Action';
  }

  factory ActionCard.fromJson(Map<String, dynamic> json) {
    var card = ActionCard(
      json['name'],
      json['imagePath'],
      json['cost'],
      json['shortDescription'],
      json['fullDescription'],
      actionCardType:
          ActionCardTypeExtension.fromString(json['actionCardType']),
      value: json['value'],
    );
    card.id = json['id'];
    card.extraData = json['extraData'];
    card.rarity = CardRarityExtension.fromString(json['rarity']);
    return card;
  }

  Future<void> doAction(Player player, Player opponent) async {
    switch (actionCardType) {
      case ActionCardType.draw:
        for (var i = 0; i < value; i++) {
          player.drawCard([]);
        }
        break;
      case ActionCardType.drawNotFromDeck:
        if (extraData == null) {
          print('EXTRA DATA NULL WITH drawNotFromDeck actioncard');
          return;
        }
        var cardIds = extraData!.split(";");
        var cards = await CardDatabase.getCards(cardIds);
        for (int i = 0; i < value; i++) {
          var cardToAdd = cards[Random().nextInt(cards.length)].clone();
          cardToAdd.oneTimeUse = true;
          player.hand.add(cardToAdd);
        }
        break;
      case ActionCardType.stealRandomCardFromOpponentHand:
        if (opponent.hand.isEmpty) {
          return;
        }
        var opponentCard =
            opponent.hand[Random().nextInt(opponent.hand.length)];
        opponent.hand.remove(opponentCard);
        opponentCard.isOpponentCard;
        player.hand.add(opponentCard);
        break;
      case ActionCardType.gainMana:
        player.mana += value;
        break;
      case ActionCardType.showOpponentHand:
        break;
      case ActionCardType.freezeOpponent:
        for (var monster in opponent.monsters) {
          if (monster != null) {
            monster.effects.add(GameEffect(GameEffectType.freeze, value));
          }
        }
        break;
    }
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      ...super.toJson(),
      'actionCardType': actionCardType.toString().split(".")[1],
      'value': value,
    };
  }

  @override
  GameCard clone() {
    var card = ActionCard(
        name, imagePath, cost, shortDescription, fullDescription,
        actionCardType: actionCardType, value: value);
    card.id = id;
    card.extraData = extraData;
    card.rarity = rarity;
    return card;
  }
}
