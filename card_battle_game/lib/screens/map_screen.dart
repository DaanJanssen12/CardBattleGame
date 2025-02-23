import 'package:card_battle_game/models/database/user_storage.dart';
import 'package:card_battle_game/models/game/game.dart';
import 'package:card_battle_game/screens/game_screen.dart';
import 'package:card_battle_game/screens/mystery_event_screen.dart';
import 'package:flutter/material.dart';
import 'dart:math';

import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class NodeMapScreen extends StatefulWidget {
  final UserData userData;
  NodeMapScreen({required this.userData});

  @override
  _NodeMapScreenState createState() => _NodeMapScreenState();
}

class _NodeMapScreenState extends State<NodeMapScreen> {
  final ScrollController _scrollController = ScrollController();
  final GameMap map = GameMap();

  @override
  void initState() {
    super.initState();
    if (widget.userData.activeGame != null) {
      map.setStages(widget.userData.activeGame!.currentMap!._stages);
      map._selectedMapStage =
          widget.userData.activeGame!.currentMap!._selectedMapStage;
    } else {
      map.generateMap();
    }

    // Delay scrolling to allow the UI to build first
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToSelectedNode();
    });
  }

  void _moveToNode(MapStage node) {
    setState(() {
      map._selectedMapStage = node;
    });
  }

  void _scrollToSelectedNode() {
    if (map._selectedMapStage != null) {
      _scrollController.animateTo(
        map._selectedMapStage
            .y, // Scroll to the Y position of the selected node
        duration: Duration(milliseconds: 500), // Smooth animation
        curve: Curves.easeInOut, // Smooth scrolling effect
      );
    }
  }

  void startStage() {
    widget.userData.activeGame!.currentMap = map;
    switch (map._selectedMapStage.type) {
      case NodeType.battle:
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => GameScreen(userData: widget.userData)),
        );
        break;
      case NodeType.mystery:
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  MysteryEventScreen(userData: widget.userData)),
        );
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/${widget.userData.background}',
              fit: BoxFit.cover,
            ),
          ),
          SingleChildScrollView(
            controller: _scrollController,
            child: Center(
              child: SizedBox(
                width: double.infinity,
                child: Stack(
                  children: [
                    CustomPaint(
                      painter: NodeMapPainter(map._stages),
                      size: Size(
                          MediaQuery.of(context).size.width, map._yStart + 100),
                    ),
                    ...map._stages.map((node) => Positioned(
                          left: node.x,
                          top: node.y,
                          child: GestureDetector(
                            onTap: () => map.canMoveToNode(node)
                                ? _moveToNode(node)
                                : null,
                            child: NodeWidget(
                                node: node,
                                isActive: node == map._selectedMapStage ||
                                    node.cleared),
                          ),
                        )),
                    if (!map._selectedMapStage.cleared) ...[
                      Positioned(
                        top: map._selectedMapStage.y - 150,
                        left: map._selectedMapStage.x -
                            (MediaQuery.of(context).size.width / 4),
                        child: Container(
                          width: MediaQuery.of(context).size.width / 2,
                          padding: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "Stage: ${map._selectedMapStage!.stage}",
                                style: TextStyle(
                                    color: Colors.white, fontSize: 18),
                              ),
                              Text(
                                "Type: ${map._selectedMapStage!.type.toString().split('.').last}",
                                style: TextStyle(
                                    color: Colors.white, fontSize: 16),
                              ),
                              SizedBox(height: 10),
                              ElevatedButton(
                                onPressed: startStage,
                                child: Text("Enter stage"),
                              )
                            ],
                          ),
                        ),
                      ),
                    ]
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MapPath {
  final int id;
  final int xMin, xMax;

  MapPath({required this.id, required this.xMin, required this.xMax});

  int getValueX() {
    return Random().nextInt(xMax - xMin) + xMin;
  }

  List<int> getPathConnections() {
    var connections = [id];
    if (Random().nextInt(100) > 75) {
      connections.add(id - 1);
    }
    if (Random().nextInt(100) > 75) {
      connections.add(id + 1);
    }
    return connections;
  }
}

class GameMap {
  final List<MapPath> _paths = [
    MapPath(id: 1, xMin: 40, xMax: 80),
    MapPath(id: 2, xMin: 140, xMax: 180),
    MapPath(id: 3, xMin: 240, xMax: 280)
  ];
  final double _yStart = 1200;
  final double _yDecreasePerStage = 120;
  final List<MapStage> _stages = [];
  final int _amountOfStages = 10;
  late MapStage _selectedMapStage;

  GameMap();

  void generateMap() {
    _stages.clear();
    for (int i = 1; i <= _amountOfStages; i++) {
      if (i == 1) {
        _stages.add(MapStage(
          stage: i,
          connectToPaths: [1, 2, 3],
          type: NodeType.battle,
          x: _paths[1].getValueX().toDouble(),
          y: getStageValueY(i),
        ));
      } else {
        for (var path in _paths) {
          _stages.add(MapStage(
            stage: i,
            connectToPaths: path.getPathConnections(),
            type: getRandomStageType(i),
            x: path.getValueX().toDouble(),
            y: getStageValueY(i),
          ));
        }
      }
    }

    _selectedMapStage = _stages[0];
  }

  bool canMoveToNode(MapStage node) {
    var clearedStages = _stages.where((w) => w.cleared);
    if (clearedStages.isEmpty) {
      return false;
    }

    MapStage? lastClearedStage;
    for (var stage in clearedStages) {
      lastClearedStage ??= stage;
      if (lastClearedStage.stage < stage.stage) {
        lastClearedStage = stage;
      }
    }

    return lastClearedStage!.connectsTo(node);
  }

  NodeType getRandomStageType(int stage) {
    var rngResult = Random().nextInt(100) + 1; //Value between 1 and 100
    switch (stage) {
      case < 5:
        switch (rngResult) {
          case < 75:
            return NodeType.battle;
          case >= 75 && < 90:
            return NodeType.mystery;
          case >= 90:
            return NodeType.shop;
        }
      default:
        return NodeType.battle;
    }
    return NodeType.battle;
  }

  void setCurrentStageCleared() {
    var stage = _stages.firstWhere((w) => w == _selectedMapStage);
    _selectedMapStage.clearStage();
    stage.clearStage();
  }

  void setStages(List<MapStage> stages) {
    _stages.clear();
    _stages.addAll(stages);
  }

  double getStageValueY(int stage) {
    return _yStart - ((stage - 1) * _yDecreasePerStage);
  }
}

class MapStage {
  final int stage;
  final NodeType type;
  final double x, y;
  final List<int> connectToPaths;
  bool cleared = false;

  MapStage(
      {required this.stage,
      required this.type,
      required this.x,
      required this.y,
      required this.connectToPaths});

  IconData getIcon() {
    switch (type) {
      case NodeType.battle:
        return FontAwesomeIcons.handFist;
      case NodeType.event:
        return FontAwesomeIcons.star;
      case NodeType.mystery:
        return FontAwesomeIcons.question;
      case NodeType.shop:
        return FontAwesomeIcons.store;
    }
  }

  void clearStage() {
    cleared = true;
  }

  bool connectsTo(MapStage mapStage) {
    //Same stage never connects
    if (mapStage.stage == stage) {
      return false;
    }

    var stageDifference = mapStage.stage - stage;
    if (stageDifference < 0) stageDifference *= -1;
    if (stageDifference != 1) {
      return false;
    }

    return connectToPaths.any((a) => mapStage.connectToPaths.contains(a));
  }
}

enum NodeType { battle, shop, event, mystery }

class NodeWidget extends StatelessWidget {
  final MapStage node;
  final bool isActive;

  const NodeWidget({required this.node, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isActive ? Colors.blue : Colors.grey.shade300,
        border: Border.all(
            width: 3, color: isActive ? Colors.yellow : Colors.black),
      ),
      child: Center(
        child: Icon(node.getIcon()),
      ),
    );
  }
}

class NodeMapPainter extends CustomPainter {
  final List<MapStage> nodes;

  NodeMapPainter(this.nodes);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < nodes.length - 1; i++) {
      final node1 = nodes[i];
      var nextStages = nodes.where((w) =>
          w.stage == node1.stage + 1 &&
          node1.connectToPaths.any((path) => w.connectToPaths.contains(path)));
      if (nextStages.isNotEmpty) {
        for (var stage in nextStages) {
          if (node1.cleared && stage.cleared) {
            paint.color = Colors.yellow;
          } else {
            paint.color = Colors.white;
          }
          canvas.drawLine(
            Offset(node1.x + 20, node1.y + 20),
            Offset(stage.x + 20, stage.y + 20),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
