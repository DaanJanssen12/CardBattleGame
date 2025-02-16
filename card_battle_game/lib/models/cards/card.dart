import 'package:card_battle_game/models/cards/action_card.dart';
import 'package:card_battle_game/models/cards/monster_card.dart';
import 'package:card_battle_game/models/cards/upgrade_card.dart';
import 'package:uuid/uuid.dart';

class GameCard {
  late String id;
  String name;
  late String type;
  String imagePath;
  int cost;
  String? shortDescription;
  String? fullDescription;
  late bool isInDeck;
  late String cloneId;
  late bool oneTimeUse = false;
  late CardRarity rarity;
  late bool isOpponentCard = false;

  GameCard(this.name, this.imagePath, this.cost, this.shortDescription,
      this.fullDescription) {
    //id = Uuid().v4();
    isInDeck = false;
    rarity = CardRarity.Common;
    type = "";
  }

  bool isMonster() => type == 'Monster';
  bool isUpgrade() => type == 'Upgrade';
  bool isAction() => type == 'Action';

  MonsterCard toMonster() {
    return this as MonsterCard;
  }

  bool canBePlayed() {
    //Already summoned monsters can't be played
    if (isMonster()) {
      return !toMonster().isActive;
    }

    return true;
  }

  GameCard clone() {
    var clone =
        GameCard(name, imagePath, cost, shortDescription, fullDescription);
    clone.id = id;
    cloneId = Uuid().v4();
    clone.rarity = rarity;
    return clone;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'cost': cost,
      'imagePath': imagePath,
      'type': type,
      'shortDescription': shortDescription,
      'fullDescription': fullDescription,
    };
  }

  factory GameCard.fromJson(Map<String, dynamic> json) {
    switch (json['type'].toString().toLowerCase()) {
      case 'monster':
        return MonsterCard.fromJson(json);
      case 'upgrade':
        return UpgradeCard.fromJson(json);
      case 'action':
        return ActionCard.fromJson(json);
    }
    return GameCard('', '', 0, null, null);
  }

 @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GameCard && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
enum CardRarity { Common, Uncommon, Rare, UltraRare, Legendary }

extension CardRarityExtension on CardRarity {
  // Convert a string to an enum value
  static CardRarity fromString(String? str) {
    if(str == null){
      return CardRarity.Common;
    }
    return CardRarity.values.firstWhere(
      (e) => e.toString().split('.').last.toLowerCase() == str.toLowerCase(),
      orElse: () => CardRarity.Common, // Default value
    );
  }

  CardRarity? getPrevious() {
    // Get the index of the current value
    int index = this.index;

    // If it's the first value (common), return null (no previous)
    if (index == 0) {
      return null;
    }

    // Otherwise, return the previous value
    return CardRarity.values[index - 1];
  }
}
