class PlayCardResult{
  late String message;
  late PlayCardResultType type;
}

enum PlayCardResultType{
  showOpponentHand,
  endTurn
}