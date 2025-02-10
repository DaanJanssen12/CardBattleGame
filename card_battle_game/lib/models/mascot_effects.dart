class MascotEffects {
  int startingHealth;
  int startingMana;
  int regainManaPerTurn;
  MascotEffects(this.startingHealth, this.startingMana, this.regainManaPerTurn);
  factory MascotEffects.fromJson(Map<String, dynamic>? json) {
    var data = MascotEffects(3, 4, 1);
    if (json == null || json.isEmpty) {
      return data;
    }
    data.startingHealth = json['startingHealth'];
    data.startingMana = json['startingMana'];
    data.regainManaPerTurn = json['regainManaPerTurn'];
    return data;
  }
}
