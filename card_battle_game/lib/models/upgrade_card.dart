import 'package:card_battle_game/models/card.dart';
import 'package:card_battle_game/models/upgrade_card_type.dart';

class UpgradeCard extends GameCard {
  UpgradeCardType upgradeCardType;
  int? value;

  UpgradeCard(super.name, super.imagePath, super.cost, super.shortDescription,
      super.fullDescription,
      {this.upgradeCardType = UpgradeCardType.boostAtk, this.value = 1}) {
    type = 'Upgrade';
    //id = Uuid().v4();
  }

  factory UpgradeCard.fromJson(Map<String, dynamic> json) {
    var card = UpgradeCard(
      json['name'],
      json['imagePath'],
      json['cost'],
      json['shortDescription'],
      json['fullDescription'],
      upgradeCardType:
          UpgradeCardTypeExtension.fromString(json['upgradeCardType']),
      value: json['value'],
    );
    card.id = json['id'];
    card.rarity = CardRarityExtension.fromString(json['rarity']);

    return card;
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      ...super.toJson(),
      'upgradeCardType': upgradeCardType.toString().split(".")[1],
      'value': value,
    };
  }

  @override
  GameCard clone() {
    var card = UpgradeCard(
        name, imagePath, cost, shortDescription, fullDescription,
        upgradeCardType: upgradeCardType, value: value);
    card.id = id;
    card.rarity = rarity;
    return card;
  }
}
