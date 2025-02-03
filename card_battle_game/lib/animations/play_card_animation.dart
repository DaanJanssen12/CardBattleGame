import 'package:flutter/material.dart';

class PlayCardAnimation extends StatefulWidget {
  final Widget card;
  final VoidCallback onAnimationEnd;

  const PlayCardAnimation({required this.card, required this.onAnimationEnd, Key? key}) : super(key: key);

  @override
  _PlayCardAnimationState createState() => _PlayCardAnimationState();
}

class _PlayCardAnimationState extends State<PlayCardAnimation> {
  bool _played = false;

  void _playCard() {
    setState(() {
      _played = true;
    });

    Future.delayed(Duration(milliseconds: 600), widget.onAnimationEnd);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        AnimatedPositioned(
          duration: Duration(milliseconds: 500),
          curve: Curves.easeOut,
          top: _played ? -100 : 0, // Moves up when played
          child: AnimatedOpacity(
            duration: Duration(milliseconds: 400),
            opacity: _played ? 0 : 1, // Fades out when played
            child: GestureDetector(
              onTap: _playCard,
              child: widget.card,
            ),
          ),
        ),
      ],
    );
  }
}
