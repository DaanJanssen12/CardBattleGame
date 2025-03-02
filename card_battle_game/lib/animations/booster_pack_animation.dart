import 'package:card_battle_game/models/cards/card.dart';
import 'package:card_battle_game/models/database/card_database.dart';
import 'package:card_battle_game/models/database/user_storage.dart';
import 'package:card_battle_game/widgets/card_widget.dart';
import 'package:flutter/material.dart';
import 'dart:math';

enum BoosterPackType { starterDeck, common, uncommon, rare, best }

class BoosterPackOpenAnimation extends StatefulWidget {
  final BoosterPackType type;
  final UserData userData;
  final List<GameCard> rewardsCards;
  const BoosterPackOpenAnimation(
      {super.key, required this.type, required this.userData, required this.rewardsCards});

  @override
  _BoosterPackOpenAnimationState createState() =>
      _BoosterPackOpenAnimationState();
}

class _BoosterPackOpenAnimationState extends State<BoosterPackOpenAnimation>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _fadeIncontroller;
  late Animation<double> _glowAnimation;
  late Animation<double> _shakeXAnimation, _shakeYAnimation;
  late Animation<double> _fogAnimation;
  late Animation<double> _cardFadeAnimation;
  bool _showCard = false;
  late List<GameCard> rewardCards;
  int i = 0;

  void _loadRewardCards() async {

    if(widget.type == BoosterPackType.starterDeck){
      rewardCards = widget.rewardsCards;
      return;
    }

    var cardRarity = CardRarity.Common;
    switch (widget.type) {
      case BoosterPackType.common:
      cardRarity = CardRarity.Common;
        break;
      case BoosterPackType.uncommon:
      cardRarity = CardRarity.Uncommon;
        break;
      case BoosterPackType.rare:
      cardRarity = CardRarity.Rare;
        break;
      case BoosterPackType.best:
      cardRarity = CardRarity.UltraRare;
        break;
      default:
        break;
    }

    await CardDatabase.loadCardsFromJson(CardDatabase.filePath);
    var rewardCard = CardDatabase.getRandomCard(type: '', rarity: cardRarity);
    widget.userData.cards.add(rewardCard.id);
    rewardCards = [
      rewardCard
    ];
    await UserStorage.saveUserData(widget.userData);
  }

  final Random _random = Random();

  List<TweenSequenceItem<double>> _generateShakeSequence(
      {double maxOffset = 6.0, int shakes = 12}) {
    List<TweenSequenceItem<double>> sequence = [];

    double lastOffset = 0;
    for (int i = 0; i < shakes; i++) {
      double offset = _random.nextDouble() *
          maxOffset *
          (_random.nextBool() ? 1 : -1); // Random positive/negative
      double weight =
          _random.nextDouble() * 5 + 3; // Random weight (between 3-8)

      sequence.add(TweenSequenceItem(
        tween: Tween(begin: offset, end: -offset)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: weight,
      ));

      sequence.add(TweenSequenceItem(
        tween: Tween(begin: -offset, end: offset)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: weight,
      ));

      if (i == shakes - 1) {
        lastOffset = offset;
      }
    }

    // Ensure it settles back to zero
    sequence.add(TweenSequenceItem(
      tween: Tween(begin: lastOffset, end: 0.0)
          .chain(CurveTween(curve: Curves.elasticOut)),
      weight: 10,
    ));

    return sequence;
  }

  @override
  void initState() {
    super.initState();

    _loadRewardCards();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 4),
    );
    _fadeIncontroller =
        AnimationController(vsync: this, duration: Duration(seconds: 2));

    _glowAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _shakeXAnimation = TweenSequence<double>([
      for (int i = 0; i < 10; i++) ...[
        TweenSequenceItem(
            tween: Tween(begin: -5.0, end: 5.0)
                .chain(CurveTween(curve: Curves.easeInOut)),
            weight: 5),
        TweenSequenceItem(
            tween: Tween(begin: 5.0, end: -5.0)
                .chain(CurveTween(curve: Curves.easeInOut)),
            weight: 5),
      ],
      TweenSequenceItem(
          tween: Tween(begin: -5.0, end: 0.0)
              .chain(CurveTween(curve: Curves.elasticOut)),
          weight: 10),
    ]).animate(_controller);

    _shakeYAnimation = TweenSequence<double>([
      for (int i = 0; i < 10; i++) ...[
        TweenSequenceItem(
            tween: Tween(begin: -3.0, end: 3.0)
                .chain(CurveTween(curve: Curves.easeInOut)),
            weight: 5),
        TweenSequenceItem(
            tween: Tween(begin: 3.0, end: -3.0)
                .chain(CurveTween(curve: Curves.easeInOut)),
            weight: 5),
      ],
      TweenSequenceItem(
          tween: Tween(begin: -3.0, end: 0.0)
              .chain(CurveTween(curve: Curves.elasticOut)),
          weight: 10),
    ]).animate(_controller);

    _shakeXAnimation =
        TweenSequence<double>(_generateShakeSequence(maxOffset: 8.0))
            .animate(_controller);
    _shakeYAnimation =
        TweenSequence<double>(_generateShakeSequence(maxOffset: 4.0))
            .animate(_controller);

    _fogAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _cardFadeAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _fadeIncontroller, curve: Curves.easeIn),
    );
  }

  void startAnimation() {
    _controller.forward().whenComplete(() {
      setState(() {
        _showCard = true;
      });
      _fadeIncontroller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (_showCard) {
          if(i < rewardCards.length - 1){
            setState(() {
              i++;
            });
          }else{
          Navigator.of(context).pop(); // Close animation on tap
          }
        } else {
          startAnimation();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Fog Effect
              AnimatedBuilder(
                animation: _fogAnimation,
                builder: (context, child) {
                  return Opacity(
                    opacity: _fogAnimation.value,
                    child: Container(
                      width: 250,
                      height: 250,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.7),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withOpacity(0.5),
                            blurRadius: 50,
                            spreadRadius: 50,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              // Booster Pack (Before Opening)
              if (!_showCard)
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(
                          _shakeXAnimation.value, _shakeYAnimation.value),
                      child: Transform.scale(
                        scale: _glowAnimation.value,
                        child: child,
                      ),
                    );
                  },
                  child: Container(
                    width: 120,
                    height: 200,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage('assets/images/card_back.png'),
                        fit: BoxFit.cover,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blueAccent.withOpacity(0.5),
                          blurRadius: 15,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                  ),
                ),

              // Single Card Reveal
              if (_showCard)
                AnimatedBuilder(
                  animation: _cardFadeAnimation,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _cardFadeAnimation.value,
                      child: Transform.scale(
                        scale: 1,
                        child: child,
                      ),
                    );
                  },
                  child: Container(
                    width: 120,
                    height: 200,
                    child: CardWidget(card: rewardCards[i]),
                    // decoration: BoxDecoration(
                    //   image: DecorationImage(
                    //     image: AssetImage('assets/images/revealed_card.png'),
                    //     fit: BoxFit.cover,
                    //   ),
                    //   borderRadius: BorderRadius.circular(16),
                    //   boxShadow: [
                    //     BoxShadow(
                    //       color: Colors.white.withOpacity(0.8),
                    //       blurRadius: 20,
                    //       spreadRadius: 5,
                    //     ),
                    //   ],
                    // ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
