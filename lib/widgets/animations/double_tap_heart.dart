import 'package:flutter/material.dart';

class DoubleTapHeart extends StatefulWidget {
  final Widget child;
  final VoidCallback onLike;

  const DoubleTapHeart({
    super.key,
    required this.child,
    required this.onLike,
  });

  @override
  State<DoubleTapHeart> createState() => _DoubleTapHeartState();
}

class _DoubleTapHeartState extends State<DoubleTapHeart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  bool _showHeart = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _scale = Tween<double>(begin: 0.5, end: 1.4).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Future.delayed(const Duration(milliseconds: 200), () {
          setState(() => _showHeart = false);
          _controller.reset();
        });
      }
    });
  }

  void _triggerAnimation() {
    setState(() => _showHeart = true);
    _controller.forward();
    widget.onLike();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTap: _triggerAnimation,
      child: Stack(
        alignment: Alignment.center,
        children: [
          widget.child,
          if (_showHeart)
            ScaleTransition(
              scale: _scale,
              child: const Icon(
                Icons.favorite,
                color: Colors.white,
                size: 90,
              ),
            ),
        ],
      ),
    );
  }
}
