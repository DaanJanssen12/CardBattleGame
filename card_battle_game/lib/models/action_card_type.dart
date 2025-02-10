enum ActionCardType {
  draw,
  drawNotFromDeck,
  stealRandomCardFromOpponentHand,
  gainMana
}

extension ActionCardTypeExtension on ActionCardType {
  // Convert a string to an enum value
  static ActionCardType fromString(String str) {
    return ActionCardType.values.firstWhere(
      (e) => e.toString().split('.').last.toLowerCase() == str.toLowerCase(),
      orElse: () => ActionCardType.draw, // Default value
    );
  }
}
