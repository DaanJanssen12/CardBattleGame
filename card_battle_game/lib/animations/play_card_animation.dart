import 'package:card_battle_game/models/cards/card.dart';
import 'package:card_battle_game/widgets/card_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class CardPlayAnimation extends StatefulWidget {
  final GameCard card;
  final VoidCallback onComplete;

  const CardPlayAnimation({
    Key? key,
    required this.card,
    required this.onComplete,
  }) : super(key: key);

  @override
  _CardPlayAnimationState createState() => _CardPlayAnimationState();
}

class _CardPlayAnimationState extends State<CardPlayAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 600),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 0.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.4).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _controller.forward().then((_) {
      widget.onComplete(); // Notify when animation is done
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value,
                child: SizedBox(
                  height: 150,
                  width: 100,
                  child: CardWidget(card: widget.card, onTap: null),
                ),
              );
            },
          ),
        ));
  }
}
