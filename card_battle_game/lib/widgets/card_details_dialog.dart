import 'package:card_battle_game/models/cards/card.dart';
import 'package:card_battle_game/models/cards/monster_card.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class CardDetailsDialog extends StatelessWidget {
  final GameCard card;

  const CardDetailsDialog({super.key, required this.card});

  @override
  Widget build(BuildContext context) {
    var dialogHeight = MediaQuery.of(context).size.height * 0.6;
    var dialogWidth = MediaQuery.of(context).size.width * 0.9;
    return Dialog(
        backgroundColor: Colors.transparent, // Removes default white background
        child: Container(
          width: dialogWidth, // 90% of screen width
          height: dialogHeight, // 60% of screen height
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/card_front.png'),
              fit: BoxFit.fill,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              SizedBox(
                height: dialogHeight * 0.25,
                width: dialogWidth * 0.9,
                child: Center(
                  child: _buildNameHeader(),
                ),
              ),
              SizedBox(
                height: dialogHeight * 0.35,
                width: dialogWidth * 0.9,
                child: Center(
                  child: _buildImage(BoxConstraints.tightFor(
                      height: dialogHeight * 0.4, width: dialogWidth * 0.9)),
                ),
              ),
              Padding(
                  padding: EdgeInsets.fromLTRB(
                      dialogWidth * 0.1,
                      dialogHeight * 0.02,
                      dialogWidth * 0.1,
                      dialogHeight * 0.02),
                  child: SizedBox(
                    height: dialogHeight * 0.35,
                    width: dialogWidth * 0.9,
                    child: _buildDescriptionSection(dialogWidth * 0.65),
                  ))
            ],
          ),
        ));
  }

  Widget _buildNameHeader() {
    return Stack(
      clipBehavior: Clip.none, // Allows the crown to slightly overflow
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text(
            card.name,
            textAlign: TextAlign.center,
            softWrap: false,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImage(BoxConstraints constraints) {
    return Stack(
      alignment:
          Alignment.bottomLeft, // Positioning the badge to the bottom-left
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.asset(
            card.imagePath.isNotEmpty == true
                ? card.imagePath
                : 'assets/images/placeholder.png',
            width: constraints.maxWidth * 0.8,
            height: constraints.maxHeight * 0.9,
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
        _buildCostBadge(), // Cost badge now overlaying slightly on the image
      ],
    );
  }

  // Widget for displaying the cost badge
  Widget _buildCostBadge() {
    return Positioned(
      bottom: 0, // Adjusted to be closer to the bottom-left corner
      right: 0, // Added a slight left offset for more overlap
      child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.deepPurple,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(FontAwesomeIcons.droplet, color: Colors.blue, size: 20),
              const SizedBox(width: 4), // Space between icon and number
              Text('${card.cost}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  )),
            ],
          )),
    );
  }

  Widget _buildDescriptionSection(double width) {
    var description = card.fullDescription ?? card.shortDescription ?? '';
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SizedBox(
              width: width,
              child: Text(description,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                softWrap: true),
            ),
          ],
        ),
        if (card.isMonster()) ...[_buildStatsSection(card.toMonster())],
      ],
    );
  }

  Widget _buildStatsSection(MonsterCard monster) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      _buildStatRow(FontAwesomeIcons.solidHeart, 'Health',
          monster.currentHealth, Colors.redAccent),
      _buildStatRow(FontAwesomeIcons.handFist, 'Attack', monster.currentAttack,
          Colors.orangeAccent),
    ]);
  }

  Widget _buildStatRow(IconData icon, String label, int? value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              '$label: ${value ?? 0}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
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
