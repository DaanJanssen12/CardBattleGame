import 'package:flutter/material.dart';

class AttackEffect extends StatefulWidget {
  final Widget child;
  final Duration duration;

  const AttackEffect({Key? key, required this.child, this.duration = const Duration(milliseconds: 300)}) : super(key: key);

  @override
  _AttackEffectState createState() => _AttackEffectState();
}

class _AttackEffectState extends State<AttackEffect> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 0.6).animate(_controller);

    // Start effect when widget is created
    _controller.forward().then((_) => _controller.reverse());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Container(
              color: Colors.red.withOpacity(_opacityAnimation.value),
            );
          },
        ),
      ],
    );
  }
}
