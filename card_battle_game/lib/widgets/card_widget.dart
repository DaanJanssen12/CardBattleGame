import 'package:card_battle_game/models/monster_card.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../models/card.dart';

class CardWidget extends StatelessWidget {
  final GameCard card;
  final VoidCallback? onTap;
  final bool isHovered;
  final bool isSelected;

  const CardWidget(
      {super.key, required this.card, this.onTap, this.isHovered = false, this.isSelected = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade200, Colors.blue.shade100],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(16),
          border: isSelected ? Border.all(
            color: Colors.yellowAccent,
            width: 3
          ) : null,
          boxShadow: const [
            BoxShadow(
              color: Colors.black45,
              offset: Offset(4, 4),
              blurRadius: 6,
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildNameHeader(),
                const SizedBox(height: 4), // Space between icon and number
                _buildImage(constraints),
                const SizedBox(height: 4), // Space between icon and number
                if (card is MonsterCard) ...[
                  _buildStatsSection(card as MonsterCard),
                ] else ...[
                  _buildDescriptionSection()
                ]
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildNameHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: Colors.deepPurple,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        card.name,
        textAlign: TextAlign.center,
        softWrap: false,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildImage(BoxConstraints constraints) {
    return Stack(
      alignment:
          Alignment.bottomLeft, // Positioning the badge to the bottom-left
      children: [
        SizedBox(
          height: constraints.maxHeight * 0.4,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              card.imagePath.isNotEmpty == true
                  ? card.imagePath
                  : 'assets/images/placeholder.png',
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
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.deepPurple,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(FontAwesomeIcons.gem, color: Colors.lightBlue, size: 14),
              const SizedBox(width: 4), // Space between icon and number
              Text('${card.cost}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  )),
            ],
          )),
    );
  }

  Widget _buildDescriptionSection() {
    return Container(
      height: 48,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.deepPurple.shade700,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          card.fullDescription ?? card.shortDescription ?? '',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 8,
          ),
        ));
  }

  Widget _buildStatsSection(MonsterCard monster) {
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
              monster.currentHealth, Colors.redAccent),
          _buildStatRow(FontAwesomeIcons.handFist, 'Attack',
              monster.currentAttack, Colors.orangeAccent),
        ],
      ),
    );
  }

  Widget _buildStatRow(IconData icon, String label, int? value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 10),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              '$label: ${value ?? 0}',
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
