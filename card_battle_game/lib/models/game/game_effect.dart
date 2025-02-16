enum GameEffectType {shield, freeze}

class GameEffect{

  int value;
  GameEffectType type;

  GameEffect(this.type, this.value);
}