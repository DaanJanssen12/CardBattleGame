import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:card_battle_game/models/cards/monster_card.dart';
import 'package:card_battle_game/models/player/player.dart';

class PlayerInfoWidget extends StatefulWidget {
  final Player player;
  final bool isActive;
  final Function(MonsterCard)? handleAttackPlayerDirectly;

  const PlayerInfoWidget({
    super.key,
    required this.player,
    required this.isActive,
    required this.handleAttackPlayerDirectly,
  });

  @override
  _PlayerInfoWidgetState createState() => _PlayerInfoWidgetState();
}

class _PlayerInfoWidgetState extends State<PlayerInfoWidget> {
  bool isHovered = false;
  bool canAcceptAttack = false;

  @override
  void initState() {
    super.initState();
  }

  void _showPlayerDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(widget.player.name),
          content: DefaultTabController(
            length: 2, // Two tabs: Player Info and Mascot Info
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TabBar(
                  labelColor: Colors.blue,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: Colors.blue,
                  tabs: [
                    Tab(icon: Icon(FontAwesomeIcons.user), text: "Player Info"),
                    Tab(icon: Icon(FontAwesomeIcons.paw), text: "Mascot Info"),
                  ],
                ),
                SizedBox(
                  height: 300, // Adjust height as needed
                  child: TabBarView(
                    children: [
                      // Player Info Tab
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildStatRow("Health", widget.player.health,
                              Colors.red, FontAwesomeIcons.solidHeart),
                          _buildStatRow("Mana", widget.player.mana, Colors.blue,
                              FontAwesomeIcons.droplet),
                          _buildStatRow("Deck", widget.player.deck.length,
                              Colors.black, FontAwesomeIcons.database),
                          _buildStatRow("Hand", widget.player.hand.length,
                              Colors.black, FontAwesomeIcons.hand),
                          _buildStatRow(
                              "Discard",
                              widget.player.discardPile.length,
                              Colors.black,
                              FontAwesomeIcons.recycle),
                        ],
                      ),
                      // Mascot Info Tab
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text("Mascot: ${widget.player.mascotCard.name}",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                          Image.asset(widget.player.mascotCard.imagePath,
                              height: 80),
                          SizedBox(height: 10),
                          _buildStatRow("Starting Health", widget.player.mascotCard.mascotEffects.startingHealth,
                              Colors.red, FontAwesomeIcons.solidHeart),
                          _buildStatRow("Starting Mana", widget.player.mascotCard.mascotEffects.startingMana, Colors.blue, FontAwesomeIcons.droplet),
                          _buildStatRow("Gain Mana per turn", widget.player.mascotCard.mascotEffects.regainManaPerTurn, Colors.blue, FontAwesomeIcons.droplet),
                          if(widget.player.mascotCard.mascotEffects.additionalEffect != null)...[
                            _buildStatRow(widget.player.mascotCard.mascotEffects.additionalEffect!.name, null, Colors.green, FontAwesomeIcons.wandMagic),
                            Text(widget.player.mascotCard.mascotEffects.additionalEffect!.description)
                          ]
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Close"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showPlayerDetails(context),
      child: DragTarget<MonsterCard>(
        onWillAcceptWithDetails: (details) {
          bool canAttack = details.data.canAttack();
          setState(() {
            canAcceptAttack = canAttack &&
                (widget.player.monsters.isEmpty ||
                    widget.player.monsters.every((e) => e == null));
            isHovered = canAcceptAttack;
          });
          return canAcceptAttack;
        },
        onLeave: (data) {
          setState(() {
            isHovered = false;
          });
        },
        onAcceptWithDetails: (details) {
          if (widget.handleAttackPlayerDirectly != null &&
              (widget.player.monsters.isEmpty ||
                  widget.player.monsters.every((e) => e == null))) {
            widget.handleAttackPlayerDirectly!(details.data);
            setState(() {
              isHovered = false;
            });
          }
        },
        builder: (context, candidateData, rejectedData) {
          return AnimatedScale(
            duration: Duration(milliseconds: 300),
            scale: isHovered ? 1.05 : 1.0,
            child: Container(
              width: 200,
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: widget.isActive ? Colors.blue[200] : Colors.blue[100],
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(2, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 25,
                        height: 25,
                        margin: EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          image: DecorationImage(
                            image:
                                AssetImage(widget.player.mascotCard.imagePath),
                          ),
                        ),
                      ),
                      Text(
                        widget.isActive
                            ? '${widget.player.name} (Turn)'
                            : widget.player.name,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[800],
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStatBar(widget.player.health, Colors.red,
                          FontAwesomeIcons.solidHeart),
                      _buildStatBar(widget.player.deck.length, Colors.black,
                          FontAwesomeIcons.database),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStatBar(widget.player.mana, Colors.blue,
                          FontAwesomeIcons.droplet),
                      _buildStatBar(widget.player.hand.length, Colors.black,
                          FontAwesomeIcons.hand),
                    ],
                  ),
                  Expanded(child: Container()),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatBar(int value, Color color, IconData icon) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(value.toString(), style: TextStyle(fontSize: 14)),
            SizedBox(width: 8),
            Icon(icon, size: 14, color: color),
          ],
        ),
      ],
    );
  }

  Widget _buildStatRow(String label, int? value, Color color, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          SizedBox(width: 8),
          Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
          Spacer(),
          if(value != null)...[
          Text(value.toString(), style: TextStyle(fontSize: 16)),
          ]
        ],
      ),
    );
  }
}
