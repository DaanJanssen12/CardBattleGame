import 'package:card_battle_game/models/game/game_effect.dart';
import 'package:card_battle_game/models/cards/monster_card.dart';
import 'package:card_battle_game/widgets/outlined_text.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class MonsterCardWidget extends StatelessWidget {
  final MonsterCard? monster;

  const MonsterCardWidget({super.key, required this.monster});

  @override
  Widget build(BuildContext context) {
    return Container(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              _buildImage(constraints),
              Container(
                  width: constraints.maxWidth,
                  height: constraints.maxHeight,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/images/monstercard_front2.png'),
                      fit: BoxFit.fill,
                    ),
                    //borderRadius: BorderRadius.circular(16),
                  )),
              Positioned(
                  left: 7,
                  child: OutlinedText.render(
                      monster!.currentHealth.toString(), null, null)),
              Positioned(
                  right: 7,
                  child: OutlinedText.render(
                      monster!.currentAttack.toString(), null, null)),
              if (monster!.isMascot && !monster!.isOpponentCard) ...[
                _buildMascotBadge(),
              ],
              if (monster!.effects.isNotEmpty) ...[
                for (var i = 0; i < monster!.effects.length; i++) ...[
                  _buildEffectBadge(monster!.effects[i], i)
                ]
              ],
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: constraints.maxHeight * 0.5,
                  ),
                  _buildNameHeader(),
                  const SizedBox(height: 4), // Space between icon and number
                  //_buildImage(constraints),
                  // if (card is MonsterCard) ...[
                  //   _buildStatsSection(card as MonsterCard),
                  // ] else ...[
                  // ],
                  _buildDescriptionSection(),

                  // Padding(
                  //     padding: EdgeInsets.fromLTRB(5, 1, 0, 0),
                  //     child: Text('${card.cost}',
                  //         textAlign: TextAlign.left,
                  //         style: TextStyle(
                  //             fontSize: 12, fontWeight: FontWeight.bold)))
                ],
              )
            ],
          );
        },
      ),
    );
  }

  Widget _buildDescriptionSection() {
    var description = monster!.shortDescription;
    if (description == null ||
        (monster!.fullDescription != null &&
            monster!.fullDescription!.length < 50)) {
      description = monster!.fullDescription;
    }
    double fontSize = 8;
    if (description!.length > 50) {
      fontSize = 6;
    }
    return Container(
        //height: 60,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 8),
        // decoration: BoxDecoration(
        //   color: Colors.deepPurple.shade700,
        //   borderRadius: BorderRadius.circular(8),
        // ),
        child: Text(
          description,
          style: TextStyle(
            color: Colors.black,
            //fontWeight: FontWeight.bold,
            fontSize: fontSize,
          ),
        ));
  }

  Widget _buildNameHeader() {
    double fontSize = 12;
    if (monster!.name.length > 10) {
      fontSize = 10;
    }
    if (monster!.name.length > 15) {
      fontSize = 8;
    }
    return Stack(
      clipBehavior: Clip.none, // Allows the crown to slightly overflow
      children: [
        Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  monster!.name,
                  textAlign: TextAlign.center,
                  softWrap: false,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            )),
      ],
    );
  }

  Widget _buildImage(BoxConstraints constraints) {
    return Stack(
      alignment:
          Alignment.bottomLeft, // Positioning the badge to the bottom-left
      children: [
        SizedBox(
          height: constraints.maxHeight * 0.6,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              monster?.imagePath ?? 'assets/images/placeholder.png',
              width: 200,
              height: 100,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(
                  Icons.image_not_supported,
                  size: 50,
                  color: Colors.grey,
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMascotBadge() {
    return Positioned(
      right: 5, // Adjusted to be closer to the bottom-left corner
      bottom: 5, // Added a slight left offset for more overlap
      child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.deepPurple,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(FontAwesomeIcons.crown, color: Colors.yellow, size: 8),
            ],
          )),
    );
  }

  Widget _buildEffectBadge(GameEffect effect, int index) {
    IconData? icon;
    switch (effect.type) {
      case GameEffectType.shield:
        icon = FontAwesomeIcons.shield;
        break;
      case GameEffectType.freeze:
        icon = FontAwesomeIcons.snowflake;
        break;
    }
    return Positioned(
      left: 0, // Adjusted to be closer to the bottom-left corner
      bottom: index * 20, // Added a slight left offset for more overlap
      child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.deepPurple,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.lightBlue, size: 8),
              const SizedBox(width: 4), // Space between icon and number
              Text('${effect.value}',
                  style: const TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  )),
            ],
          )),
    );
  }

  Widget _buildStatsSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.deepPurple.shade700,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildStatRow(FontAwesomeIcons.solidHeart, 'Health',
              monster?.currentHealth ?? 0, Colors.redAccent),
          _buildStatRow(FontAwesomeIcons.handFist, 'Attack',
              monster?.currentAttack ?? 0, Colors.orangeAccent),
        ],
      ),
    );
  }

  Widget _buildStatRow(IconData icon, String label, int value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 10),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              '$label: $value',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
              overflow: TextOverflow.ellipsis,
              softWrap: false,
            ),
          ),
        ],
      ),
    );
  }
}
