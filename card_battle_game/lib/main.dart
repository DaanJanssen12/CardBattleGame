import 'package:card_battle_game/providers/sound_settings_provider.dart';
import 'package:card_battle_game/screens/main_menu.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => SoundSettingsProvider(), 
      child: CardBattleGame()
    )
  );
}

class CardBattleGame extends StatelessWidget {
  const CardBattleGame({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MainMenu(userData: null),
      debugShowCheckedModeBanner: false,
      navigatorObservers: [routeObserver],
    );
  }
}
