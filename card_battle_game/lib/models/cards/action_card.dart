import 'dart:math';
import 'package:card_battle_game/models/cards/play_card_result.dart';
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
      {this.actionCardType = ActionCardType.draw,
      this.value = 1,
      this.extraData}) {
    type = 'Action';
  }

  factory ActionCard.fromJson(Map<String, dynamic> json) {
    var card = ActionCard(json['name'], json['imagePath'], json['cost'],
        json['shortDescription'], json['fullDescription'],
        actionCardType:
            ActionCardTypeExtension.fromString(json['actionCardType']),
        value: json['value'],
        extraData: json['extraData']);
    card.id = json['id'];
    card.rarity = CardRarityExtension.fromString(json['rarity']);
    return card;
  }

  Future<PlayCardResult?> doAction(
      Player player, Player opponent, bool isGameInOvertime, Function updateGameState) async {
    PlayCardResult? result;
    switch (actionCardType) {
      case ActionCardType.draw:
        for (var i = 0; i < value; i++) {
          player.drawCard([]);
        }
        break;
      case ActionCardType.drawNotFromDeck:
        if (extraData == null) {
          print('EXTRA DATA NULL WITH drawNotFromDeck actioncard');
          var data = await CardDatabase.getCards([id]);
          if (data.isNotEmpty) {
            var actionCardData = data.first as ActionCard;
            extraData = actionCardData.extraData;
            value = actionCardData.value;
          }
          return result;
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
          return result;
        }
        var opponentCard =
            opponent.hand[Random().nextInt(opponent.hand.length)];
        opponent.hand.remove(opponentCard);
        opponentCard.isOpponentCard = true;
        player.hand.add(opponentCard);
        break;
      case ActionCardType.gainMana:
        player.mana += value;
        break;
      case ActionCardType.gainManaNextTurn:
        player.manabank += value;
        break;
      case ActionCardType.damageOpponent:
        opponent.isBeingAttacked = true;
        updateGameState();
        opponent.health -= value;
        await Future.delayed(Duration(milliseconds: 500));
        opponent.isBeingAttacked = false;
        updateGameState();
        break;
      case ActionCardType.showOpponentHand:
        result = PlayCardResult();
        result.type = PlayCardResultType.showOpponentHand;
        break;
      case ActionCardType.freezeOpponent:
        for (var monster in opponent.monsters) {
          if (monster != null) {
            monster.effects.add(GameEffect(GameEffectType.freeze, value));
          }
        }
        break;
      case ActionCardType.summon:
        var cards = await CardDatabase.getCards([extraData!]);
        for (int i = 0; i < value; i++) {
          var cardToAdd = cards[0].clone();
          cardToAdd.oneTimeUse = true;
          for (int x = 0; x < 3; x++) {
            var monsterZone = player.monsters[x];
            if (monsterZone == null) {
              await player.summonMonster(cardToAdd.toMonster(), x, [], opponent,
                  false, isGameInOvertime);
              updateGameState();
              break;
            }
          }
        }
        break;
      case ActionCardType.combined:
        for (var effect in extraData!.split(";")) {
          if (effect.contains(":")) {
            var effectValues = effect.split(":");
            var actionCardClone = (clone() as ActionCard);
            switch (effectValues[0]) {
              case 'draw':
                actionCardClone.actionCardType = ActionCardType.draw;
                actionCardClone.value = int.parse(effectValues[1]);
                await actionCardClone.doAction(
                    player, opponent, isGameInOvertime, updateGameState);
                break;
              case 'gainManaNextTurn':
                actionCardClone.actionCardType =
                    ActionCardType.gainManaNextTurn;
                actionCardClone.value = int.parse(effectValues[1]);
                break;
            }
          } else {
            if (effect == 'endTurn') {
              result = PlayCardResult();
              result.type = PlayCardResultType.endTurn;
            }
          }
        }
        break;
    }

    return result;
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      ...super.toJson(),
      'actionCardType': actionCardType.toString().split(".")[1],
      'value': value,
      'extraData': extraData
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
