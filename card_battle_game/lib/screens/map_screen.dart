import 'package:card_battle_game/models/database/user_storage.dart';
import 'package:card_battle_game/models/game/game.dart';
import 'package:card_battle_game/screens/game_screen.dart';
import 'package:card_battle_game/screens/main_menu.dart';
import 'package:card_battle_game/screens/mystery_event_screen.dart';
import 'package:card_battle_game/screens/shop_screen.dart';
import 'package:card_battle_game/screens/stage_completion_screen.dart';
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
      map._startAtStage = widget.userData.activeGame!.currentMap!._startAtStage;
      map.setStages(widget.userData.activeGame!.currentMap!._stages);
      map._selectedMapStage =
          widget.userData.activeGame!.currentMap!._selectedMapStage;
    } else {
      map.generateMap(1);
    }

    // Delay scrolling to allow the UI to build first
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToSelectedNode();
    });

    _saveGame();
  }

  void _saveGame() async {
    UserStorage.updateActiveGame(widget.userData.activeGame!);
  }

  void _moveToNode(MapStage node) {
    setState(() {
      map._selectedMapStage = node;
    });
  }

  void _scrollToSelectedNode() {
    if (map._selectedMapStage != null) {
      _scrollController.animateTo(
        map._selectedMapStage.y -
            250, // Scroll to the Y position of the selected node
        duration: Duration(milliseconds: 500), // Smooth animation
        curve: Curves.easeInOut, // Smooth scrolling effect
      );
    } else {
      //last cleared stage
      MapStage? lastClearedStage;
      for (var stage in map._stages.where((w) => w.cleared)) {
        lastClearedStage ??= stage;
        if (lastClearedStage.stage < stage.stage) {
          lastClearedStage = stage;
        }
      }
      _scrollController.animateTo(
        lastClearedStage!.y -
            250, // Scroll to the Y position of the selected node
        duration: Duration(milliseconds: 500), // Smooth animation
        curve: Curves.easeInOut, // Smooth scrolling effect
      );
    }
  }

  void newMap() {
    map.generateMap(widget.userData.activeGame!.stage);
    setState(() {
      widget.userData.activeGame!.currentMap = map;
    });
    _scrollToSelectedNode();
  }

  void endGame() {
    widget.userData.activeGame!.endGame(false);
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => StageCompletionScreen(
              userData: widget.userData, beatenPlayer: null)),
    );
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
      case NodeType.eliteBattle:
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  GameScreen(userData: widget.userData, tag: 'elite')),
        );
        break;
      case NodeType.bossBattle:
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  GameScreen(userData: widget.userData, tag: 'boss')),
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
      case NodeType.shop:
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => ShopScreen(userData: widget.userData)),
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
          Column(
            children: [
              // Fixed Bar at the Top
              Container(
                height: 80, // Adjust height as needed
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                color: Colors.black
                    .withOpacity(0.8), // Semi-transparent background
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Go to Main Menu button
                    ElevatedButton(
                        onPressed: () => {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        MainMenu(userData: widget.userData)),
                              )
                            },
                        child: Text('Back To Main Menu',
                            style: TextStyle(fontSize: 12))),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          "Stage: ${widget.userData.activeGame!.stage}",
                          textAlign: TextAlign.right,
                          style: TextStyle(color: Colors.white, fontSize: 18),
                        ),
                        Text(
                          "Gold: ${widget.userData.activeGame!.gold}", // Replace with actual value
                          textAlign: TextAlign.right,
                          style: TextStyle(color: Colors.yellow, fontSize: 18),
                        ),
                      ],
                    )
                  ],
                ),
              ),
              // Scrollable Map Content
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  child: Center(
                    child: SizedBox(
                      width: double.infinity,
                      child: Stack(
                        children: [
                          CustomPaint(
                            painter: NodeMapPainter(map._stages),
                            size: Size(MediaQuery.of(context).size.width,
                                map._yStart + 100),
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
                                        node.cleared,
                                    isBossStage:
                                        node.stage == map._amountOfStages,
                                  ),
                                ),
                              )),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Container(
                height: 100, // Adjust height as needed
                padding: EdgeInsets.symmetric(horizontal: 16),
                color: Colors.black
                    .withOpacity(0.8), // Semi-transparent background
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (widget.userData.activeGame!.stage >
                        map.lastStage()) ...[
                      Column(
                        children: [
                          SizedBox(
                            width: MediaQuery.of(context).size.width - 20,
                            child: Text(
                              "You have cleared this map! Do you wanna continue or end this run?",
                              style:
                                  TextStyle(color: Colors.white, fontSize: 14),
                              softWrap: true,
                            ),
                          ),
                          Row(
                            spacing: 10,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              ElevatedButton(
                                onPressed: newMap,
                                child: Text(
                                    "Advance to stage ${widget.userData.activeGame!.stage}"),
                              ),
                              ElevatedButton(
                                onPressed: endGame,
                                child: Text("End game"),
                              )
                            ],
                          )
                        ],
                      ),
                    ] else if (!map._selectedMapStage.cleared) ...[
                      Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Stage: ${map._selectedMapStage.stage}",
                            style: TextStyle(color: Colors.white, fontSize: 18),
                          ),
                          Text(
                            "Type: ${map._selectedMapStage.typeString()}", // Replace with actual value
                            style: TextStyle(color: Colors.white, fontSize: 18),
                          ),
                        ],
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ElevatedButton(
                            onPressed: startStage,
                            child: Text("Enter stage"),
                          )
                        ],
                      )
                    ] else ...[
                      Text(
                        "Select your next stage",
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                    ],
                  ],
                ),
              ),
            ],
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
  int _startAtStage = 1;
  late MapStage _selectedMapStage;
  int lastStage() {
    return _startAtStage + (_amountOfStages - 1);
  }

  GameMap();

  factory GameMap.fromJson(Map<String, dynamic> json) {
    var data = GameMap();
    data._stages.addAll((json['stages'] as List<dynamic>)
        .map((m) => MapStage.fromJson(m))
        .toList());
    data._selectedMapStage = MapStage.fromJson(json['selectedMapStage']);
    data._startAtStage = json['startAtStage'] ?? 1;
    return data;
  }
  Map<String, dynamic> toJson() {
    return {
      'stages': _stages.map((m) => m.toJson()).toList(),
      'selectedMapStage': _selectedMapStage.toJson(),
      'startAtStage': _startAtStage
    };
  }

  void generateMap(int startingStage) {
    _startAtStage = startingStage;
    _stages.clear();
    for (int i = 0; i < _amountOfStages; i++) {
      var stage = i + _startAtStage;
      if (i == 0) {
        _stages.add(MapStage(
          stage: stage,
          connectToPaths: [1, 2, 3],
          type: NodeType.battle,
          x: _paths[1].getValueX().toDouble(),
          y: getStageValueY(i + 1),
        ));
      } else if (i == _amountOfStages - 1) {
        _stages.add(MapStage(
          stage: stage,
          connectToPaths: [1, 2, 3],
          type: NodeType.bossBattle,
          x: _paths[1].getValueX().toDouble(),
          y: getStageValueY(i + 1),
        ));
      } else {
        for (var path in _paths) {
          _stages.add(MapStage(
            stage: stage,
            connectToPaths: path.getPathConnections(),
            type: getRandomStageType(i),
            x: path.getValueX().toDouble(),
            y: getStageValueY(i + 1),
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
    int rngResult = Random().nextInt(100) + 1; // Value between 1 and 100

    if (stage < 5) {
      if (rngResult < 75) return NodeType.battle;
      if (rngResult < 90) return NodeType.mystery;
      return NodeType.shop;
    } else if (stage < 10) {
      if (rngResult < 50) return NodeType.battle;
      if (rngResult < 70) return NodeType.mystery;
      if (rngResult < 85) return NodeType.shop;
      return NodeType.eliteBattle;
    } else if (stage < 20) {
      if (rngResult < 40) return NodeType.battle;
      if (rngResult < 65) return NodeType.mystery;
      if (rngResult < 80) return NodeType.eliteBattle;
      return NodeType.shop;
    } else if (stage < 30) {
      if (rngResult < 35) return NodeType.battle;
      if (rngResult < 60) return NodeType.eliteBattle;
      if (rngResult < 80) return NodeType.mystery;
      return NodeType.shop;
    } else {
      // Stage 30+
      if (rngResult < 25) return NodeType.battle;
      if (rngResult < 60) return NodeType.eliteBattle;
      if (rngResult < 85) return NodeType.mystery;
      return NodeType.shop;
    }
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

  String typeString() {
    return type
        .toString()
        .split(".")
        .last
        .replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (match) {
      return '${match.group(1)} ${match.group(2)}';
    }).replaceFirstMapped(RegExp(r'^\w'), (match) {
      return match.group(0)!.toUpperCase();
    });
  }

  factory MapStage.fromJson(Map<String, dynamic> json) {
    var nodeType = NodeType.values.firstWhere(
      (e) =>
          e.toString().split('.').last.toLowerCase() ==
          json['type'].toLowerCase(),
      orElse: () => NodeType.battle, // Default value
    );
    var data = MapStage(
        stage: json['stage'],
        type: nodeType,
        x: json['x'],
        y: json['y'],
        connectToPaths: json['connectToPaths'] != null
            ? (json['connectToPaths'] as List<dynamic>)
                .map((m) => m as int)
                .toList()
            : []);
    data.cleared = json['cleared'];
    return data;
  }
  Map<String, dynamic> toJson() {
    return {
      'stage': stage,
      'type': type.toString().toLowerCase().split(".").last,
      'x': x,
      'y': y,
      'connectToPaths': connectToPaths,
      'cleared': cleared,
    };
  }

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
      case NodeType.eliteBattle:
        return FontAwesomeIcons.chessKnight;
      case NodeType.bossBattle:
        return FontAwesomeIcons.crown;
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

enum NodeType { battle, shop, event, mystery, bossBattle, eliteBattle }

class NodeWidget extends StatelessWidget {
  final MapStage node;
  final bool isActive;
  final bool isBossStage;

  const NodeWidget(
      {required this.node, required this.isActive, required this.isBossStage});

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
        child: Icon(node.getIcon(), size: 20),
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
