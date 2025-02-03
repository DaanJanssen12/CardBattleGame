import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../models/card.dart';

class MonsterCardWidget extends StatelessWidget {
  final MonsterCard monster;

  const MonsterCardWidget({super.key, required this.monster});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(8.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            monster.name,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          // Wrap LayoutBuilder inside a Container with a set maxHeight
          Container(
            constraints: BoxConstraints(maxHeight: 200), // Optional: Set maxHeight to avoid overflow
            child: LayoutBuilder(
              builder: (context, constraints) {
                double imageHeight = constraints.maxHeight * 0.3; // 30% of available space
                return Image.asset(monster.imagePath, height: imageHeight);
              },
            ),
          ),
          SizedBox(height: 8), // Add space between image and stats
          Row(
            children: [
              Icon(FontAwesomeIcons.solidHeart, color: Colors.red, size: 14),
              SizedBox(width: 4),
              Text('${monster.health}'),
            ],
          ),
          Row(
            children: [
              Icon(FontAwesomeIcons.handFist, color: Colors.orange, size: 14),
              SizedBox(width: 4),
              Text('${monster.attack}'),
            ],
          ),
        ],
      ),
    );
  }
}
