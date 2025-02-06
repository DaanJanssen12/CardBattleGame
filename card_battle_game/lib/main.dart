import 'package:card_battle_game/screens/main_menu.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(CardBattleGame());
}

class CardBattleGame extends StatelessWidget {
  const CardBattleGame({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MainMenu(),
      debugShowCheckedModeBanner: false,
    );
  }
}
