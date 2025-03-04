import 'package:card_battle_game/effects/attack_effect.dart';
import 'package:card_battle_game/models/cards/card.dart';
import 'package:card_battle_game/models/cards/monster_card.dart';
import 'package:card_battle_game/widgets/monster_card_widget.dart';
import 'package:flutter/material.dart';

class MonsterZoneWidget extends StatefulWidget {
  final MonsterCard? card;
  final bool isHovered;
  final Function(GameCard) onCardTap;

  const MonsterZoneWidget({
    super.key,
    required this.card,
    required this.isHovered,
    required this.onCardTap,
  });

  @override
  _MonsterZoneWidgetState createState() => _MonsterZoneWidgetState();
}

class _MonsterZoneWidgetState extends State<MonsterZoneWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
      lowerBound: 0.9,
      upperBound: 1.1,
    );
  }

  @override
  void didUpdateWidget(covariant MonsterZoneWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isHovered && !oldWidget.isHovered) {
      _pulseController.forward().then((_) => _pulseController.reverse());
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _pulseController,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        width: 120,
        height: 220,
        margin: EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color:
              widget.card == null ? Colors.blueGrey[100] : Colors.transparent,
          boxShadow: [
            BoxShadow(
              color: widget.isHovered
                  ? Colors.blueAccent.withOpacity(0.6)
                  : Colors.black26,
              blurRadius: widget.isHovered ? 12 : 8,
              spreadRadius: widget.isHovered ? 3 : 0,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: widget.card == null
            ? Center(
                child: Text(
                  'Empty',
                  style: TextStyle(
                      color: Colors.black,
                      fontSize: 14,
                      fontWeight: FontWeight.bold),
                ),
              )
            : GestureDetector(
                onTap: () {
                  if (widget.card != null) {
                    widget.onCardTap(widget.card!);
                  }
                },
                child: SizedBox(
                  width: 100, // Fixed size
                  height: 180,
                  child: widget.card!.isBeingAttacked 
                    ? AttackEffect(child: MonsterCardWidget(monster: widget.card!.toMonster()))
                    : MonsterCardWidget(monster: widget.card!.toMonster()),
                ),
              ),
      ),
    );
  }
}
