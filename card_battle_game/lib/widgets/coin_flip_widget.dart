import 'dart:math';
import 'package:flutter/material.dart';

class CoinFlipWidget extends StatefulWidget {
  final Function(bool) onFlipComplete;

  const CoinFlipWidget({super.key, required this.onFlipComplete});

  @override
  _CoinFlipWidgetState createState() => _CoinFlipWidgetState();
}

class _CoinFlipWidgetState extends State<CoinFlipWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool? playerChoice; // true = heads, false = tails
  bool? coinResult;
  bool flipCompleted = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2), // Duration is still 5 seconds
      vsync: this,
    );

    // Increase the speed of the flipping by modifying the range of rotation
    _animation = Tween<double>(begin: 0, end: 20 * pi).animate(_controller)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          setState(() {
            flipCompleted = true;
          });
        }
      });
  }

  void startFlip() {
    if (playerChoice == null) return; // Prevent flipping before choice

    setState(() {
      coinResult = Random().nextBool(); // Randomize coin result
    });

    _controller.forward(); // Start animation
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (playerChoice == null) ...[
            Text("Choose heads or tails:",
                style: TextStyle(color: Colors.white, fontSize: 18)),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () => setState(() => playerChoice = true),
                  child: Column(
                      children: [
                        const Text("Heads"),
                        Image.asset(
                          'assets/images/heads.png',
                          width: 70,
                          height: 70,
                        ),
                      ],
                    )),
                const SizedBox(width: 16),
                ElevatedButton(
                    onPressed: () => setState(() => playerChoice = false),
                    child: Column(
                      children: [
                        const Text("Tails"),
                        Image.asset(
                          'assets/images/tails.png',
                          width: 70,
                          height: 70,
                        ),
                      ],
                    )),
              ],
            ),
            const SizedBox(height: 16),
            // Show the side of the coin the player chose immediately after selection
            if (playerChoice != null) ...[
              Image.asset(
                playerChoice == true
                    ? 'assets/images/heads.png'
                    : 'assets/images/tails.png',
                width: 100,
                height: 100,
              ),
            ]
          ] else if (!flipCompleted) ...[
            AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                // Alternate between heads and tails at the halfway point (π)
                bool isHeads = _animation.value % (2 * pi) <
                    pi; // True for heads, false for tails
                return Transform(
                  transform: Matrix4.rotationY(_animation.value),
                  alignment: Alignment.center,
                  child: Image.asset(
                    isHeads
                        ? 'assets/images/heads.png'
                        : 'assets/images/tails.png',
                    width: 100,
                    height: 100,
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: startFlip,
              child: const Text("Flip Coin"),
            ),
          ] else ...[
            // Display the result of the coin toss with image
            Text(
              coinResult! ? "Heads!" : "Tails!",
              style: const TextStyle(color: Colors.white, fontSize: 22),
            ),
            const SizedBox(height: 16),
            Image.asset(
              coinResult == true
                  ? 'assets/images/heads.png'
                  : 'assets/images/tails.png',
              width: 100,
              height: 100,
            ),
            const SizedBox(height: 16),
            Text(
              coinResult == playerChoice ? "You go first" : "Enemy goes first",
              style: const TextStyle(color: Colors.white, fontSize: 20),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();

                widget.onFlipComplete(coinResult == playerChoice);
              },
              child: const Text("Tap to Start"),
            ),
          ]
        ],
      ),
    );
  }
}
