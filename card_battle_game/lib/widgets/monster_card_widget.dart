import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../models/card.dart';

class MonsterCardWidget extends StatelessWidget {
  final MonsterCard monster;

  const MonsterCardWidget({super.key, required this.monster});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: 250, // Ensures it doesn't exceed 250px width
      ),
      child: Container(
        width: 250,
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade200, Colors.blue.shade100], // Brighter
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black45,
              offset: Offset(4, 4),
              blurRadius: 6,
            ),
          ],
          //border: Border.all(color: Colors.blue.s, width: 2),
        ),
        child: SingleChildScrollView(
          physics: NeverScrollableScrollPhysics(),
          //shrinkWrap: true, // Fixes bottom overflow
          child: Column(
            mainAxisSize: MainAxisSize.min, 
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Card Name
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.deepPurple, 
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  monster.name,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                          color: Colors.black,
                          offset: Offset(1, 1),
                          blurRadius: 2),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 6),

              // Card Image
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  monster.imagePath,
                  width: 200,
                  height: 100,
                  fit: BoxFit.cover,
                ),
              ),
              SizedBox(height: 6),

              // Stats Section
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.shade700,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min, 
                  children: [
                    _buildStatRow(FontAwesomeIcons.solidHeart, 'Health',
                        monster.health, Colors.redAccent),
                    _buildStatRow(FontAwesomeIcons.handFist, 'Attack',
                        monster.attack, Colors.orangeAccent),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatRow(IconData icon, String label, int value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 12),
          SizedBox(width: 4),
          Flexible(
            child: Text(
              '$label: $value',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
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
