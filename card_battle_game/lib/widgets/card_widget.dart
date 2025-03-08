import 'package:card_battle_game/models/cards/monster_card.dart';
import 'package:card_battle_game/widgets/outlined_text.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../models/cards/card.dart';

class CardWidget extends StatelessWidget {
  final GameCard card;
  final VoidCallback? onTap;
  final bool isHovered;
  final bool isSelected;
  final int? amount;

  const CardWidget(
      {super.key,
      required this.card,
      this.onTap,
      this.isHovered = false,
      this.isSelected = false,
      this.amount});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onDoubleTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          border: isSelected
              ? Border.all(color: Colors.yellowAccent, width: 1)
              : null,
          boxShadow: const [
            BoxShadow(
              color: Colors.black45,
              offset: Offset(4, 4),
              blurRadius: 6,
            ),
          ],
        ),
        child: ClipRect(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: [
                  Positioned(
                      top: 2.5,
                      left: 4,
                      child: Center(
                        child: _buildImage(constraints),
                      )),
                  Container(
                      width: constraints.maxWidth,
                      height: constraints.maxHeight,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage(card.isMonster()
                              ? 'assets/images/card_front.png'
                              : 'assets/images/card_front.png'),
                          fit: BoxFit.fill,
                        ),
                        //borderRadius: BorderRadius.circular(16),
                      )),
                  if (card is MonsterCard) ...[
                    Positioned(
                        right: 5,
                        bottom: 5,
                        child: _buildStatsSection(card as MonsterCard))
                  ],
                  if (amount != null) ...[
                    Positioned(
                      top: 2,
                      left: 2,
                      child: Container(
                        width: 18, // Adjust size of circle
                        height: 18, // Adjust size of circle
                        decoration: BoxDecoration(
                          color:
                              Colors.deepPurple, // Background color for crown
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: Colors.white, width: 1), // Optional border
                        ),
                        child: Center(
                          child: Text('${amount}x',
                              style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                  ],
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: constraints.maxHeight * 0.5,
                      ),
                      _buildNameHeader(),
                      const SizedBox(
                          height: 4), // Space between icon and number
                      //_buildImage(constraints),

                      _buildDescriptionSection()
                      // Padding(
                      //     padding: EdgeInsets.fromLTRB(5, 1, 0, 0),
                      //     child: Text('${card.cost}',
                      //         textAlign: TextAlign.left,
                      //         style: TextStyle(
                      //             fontSize: 12, fontWeight: FontWeight.bold)))
                    ],
                  ),
                  Positioned(
                      left: 5,
                      bottom: 0,
                      child: OutlinedText.render('${card.cost}', null, null))
                ],
              );
            },
          ),
        ),
      ),
    );
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
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        if (card.isMonster() && card.toMonster().isMascot) ...[
          Positioned(
            top: -6, // Moves the crown above
            right: -6, // Moves it slightly outward for floating effect
            child: Container(
              width: 18, // Adjust size of circle
              height: 18, // Adjust size of circle
              decoration: BoxDecoration(
                color: Colors.deepPurple, // Background color for crown
                shape: BoxShape.circle,
                border: Border.all(
                    color: Colors.white, width: 1), // Optional border
              ),
              child: const Center(
                child: Icon(
                  FontAwesomeIcons.crown, // Crown icon
                  size: 10, // Smaller for fitting inside
                  color: Colors.amber, // Gold color for effect
                ),
              ),
            ),
          ),
        ],
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
            width: constraints.maxWidth * 0.9,
            height: constraints.maxHeight * 0.6,
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
        //_buildCostBadge(), // Cost badge now overlaying slightly on the image
      ],
    );
  }

  // Widget for displaying the cost badge
  Widget _buildCostBadge() {
    return Positioned(
      bottom: 0, // Adjusted to be closer to the bottom-left corner
      right: 0, // Added a slight left offset for more overlap
      child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.deepPurple,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(FontAwesomeIcons.droplet, color: Colors.blue, size: 10),
              const SizedBox(width: 2), // Space between icon and number
              Text('${card.cost}',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  )),
            ],
          )),
    );
  }

  Widget _buildDescriptionSection() {
    var description = card.shortDescription;
    if (description == null ||
        (card.fullDescription != null && card.fullDescription!.length < 50)) {
      description = card.fullDescription;
    }
    double fontSize = 7;
    if (description!.length > 50) {
      fontSize = 5;
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

  Widget _buildStatsSection(MonsterCard monster) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildStatRow(FontAwesomeIcons.solidHeart, 'Health',
            monster.currentHealth, Colors.red),
        _buildStatRow(FontAwesomeIcons.solidHandBackFist, 'Attack',
            monster.currentAttack, Colors.indigoAccent),
      ],
    );
  }

  Widget _buildStatRow(IconData icon, String label, int? value, Color color) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Icon(icon,
        //   color: Colors.black,
        //   size: 20),
        Icon(icon, color: color, size: 14),
        OutlinedText.render('${value ?? 0}', 8, FontWeight.bold)
        // Text(
        //     '${value ?? 0}',
        //     style: const TextStyle(
        //       color: Colors.black,
        //       fontWeight: FontWeight.bold,
        //       fontSize: 12,
        //     ),
        //   ),
      ],
    );
  }
}
