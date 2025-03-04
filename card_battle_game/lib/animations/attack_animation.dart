import 'package:flutter/material.dart';

class AttackAnimation extends StatefulWidget {
  final Duration duration;

  const AttackAnimation({Key? key, this.duration = const Duration(milliseconds: 500)}) : super(key: key);

  @override
  _AttackAnimationState createState() => _AttackAnimationState();
}

class _AttackAnimationState extends State<AttackAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Image.asset("assets/slash.png", width: 100, height: 100), // Use your effect image
    );
  }
}
