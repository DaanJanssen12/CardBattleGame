import 'package:card_battle_game/models/cards/card.dart';
import 'package:card_battle_game/widgets/card_widget.dart';
import 'package:flutter/material.dart';

class BoosterPackOpenAnimation extends StatefulWidget {
  @override
  _BoosterPackOpenAnimationState createState() =>
      _BoosterPackOpenAnimationState();
}

class _BoosterPackOpenAnimationState extends State<BoosterPackOpenAnimation>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _shakeAnimation;
  late Animation<double> _flashAnimation;
  late Animation<double> _cardFadeInAnimation;
  bool _startAnimation = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 10),
    );

    // Shake animation - side-to-side movement for the booster pack
    _shakeAnimation = Tween<double>(begin: 0.0, end: 10.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    // Flash animation - quickly fading in and out of the booster pack
    _flashAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    // Card fade-in animation (to reveal the card)
    _cardFadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  void startAnimation() {
    setState(() {
      _startAnimation = true;
    });
    _controller.forward(); // Start the animation
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Booster Pack Open Animation")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: 30),
            if (!_startAnimation)
              GestureDetector(
                onTap: startAnimation, // Start animation when image is tapped
                child: Container(
                  width: 200,
                  height: 300,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/images/card_back.png'), // Replace with your booster pack image
                      fit: BoxFit.cover,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            if (_startAnimation)
              SizedBox(
                width: 200,
                height: 300,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Booster Pack Image (closed) that shakes and flashes
                    AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(_shakeAnimation.value, 0),
                          child: Opacity(
                            opacity: _flashAnimation.value,
                            child: child,
                          ),
                        );
                      },
                      child: Container(
                        width: 200,
                        height: 300,
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: AssetImage('assets/images/card_back.png'), // Replace with your booster pack image
                            fit: BoxFit.cover,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                    // The Card widget that will fade in after the shake and flash
                    FadeTransition(
                      opacity: _cardFadeInAnimation,
                      child: Positioned(
                        bottom: 30,
                        child: CardWidget(card: GameCard('TEST', '', 0, '', '')), // This is your existing card widget
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
