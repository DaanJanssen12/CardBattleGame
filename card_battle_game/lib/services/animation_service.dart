import 'package:card_battle_game/animations/play_card_animation.dart';
import 'package:card_battle_game/models/cards/card.dart';
import 'package:flutter/material.dart';

class AnimationService {
  static final AnimationService _instance = AnimationService._internal();
  factory AnimationService() => _instance;
  AnimationService._internal();

  final List<OverlayEntry> _activeAnimations = [];

  Offset getScreenCenter(BuildContext context) {
    Size screenSize = MediaQuery.of(context).size;
    return Offset(screenSize.width / 2, screenSize.height / 2);
  }

  void playAnimation(BuildContext context, Widget animation,
      {Duration duration = const Duration(seconds: 1)}) {
    var position = getScreenCenter(context);
    OverlayEntry entry = OverlayEntry(
      builder: (context) => Positioned(
        left: position.dx,
        top: position.dy,
        child: animation,
      ),
    );

    Overlay.of(context).insert(entry);
    _activeAnimations.add(entry);

    Future.delayed(duration, () {
      entry.remove();
      _activeAnimations.remove(entry);
    });
  }

  void clearAnimations() {
    for (var entry in _activeAnimations) {
      entry.remove();
    }
    _activeAnimations.clear();
  }

  Future<void> triggerCardPlayAnimation(
      BuildContext context, GameCard card) async {
    await showDialog(
      barrierColor: Colors.transparent,
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return CardPlayAnimation(
          card: card,
          onComplete: () async {
            Navigator.of(context).pop(); // Close the animation dialog when done
            return;
          },
        );
      },
    );
  }
}
