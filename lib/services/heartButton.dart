import 'dart:math';

import 'package:flutter/material.dart';

class HeartButton extends StatefulWidget {
  @override
  _HeartButtonState createState() => _HeartButtonState();
}

class _HeartButtonState extends State<HeartButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.5).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onHeartPressed() {
    _controller.forward().then((_) => _controller.reverse());

    // Get heart button position
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final Offset buttonPosition = renderBox.localToGlobal(Offset.zero);

    // Create overlay entry
    final OverlayEntry overlayEntry = OverlayEntry(
      builder: (context) => FlyingHeart(startPosition: buttonPosition),
    );

    // Insert overlay
    Overlay.of(context).insert(overlayEntry);
  }


  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _onHeartPressed,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Icon(Icons.favorite, color: Colors.red, size: 30),
          );
        },
      ),
    );
  }
}

class FlyingHeart extends StatefulWidget {
  final Offset startPosition;

  const FlyingHeart({super.key, required this.startPosition});

  @override
  State<FlyingHeart> createState() => _FlyingHeartState();
}

class _FlyingHeartState extends State<FlyingHeart> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _position;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..forward().then((_) => _controller.dispose());

    _opacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _position = Tween<Offset>(
      begin: widget.startPosition,
      end: widget.startPosition.translate(_randomHorizontalOffset(), -200 // How high hearts fly
          ),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _scale = Tween<double>(begin: 0.8, end: 1.2).animate(_controller);
  }

  double _randomHorizontalOffset() => (Random().nextDouble() - 0.5) * 50;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: const Icon(Icons.favorite, color: Colors.red, size: 36),
      builder: (context, child) {
        return Positioned(
          left: _position.value.dx,
          top: _position.value.dy,
          child: Transform.scale(
            scale: _scale.value,
            child: Opacity(
              opacity: _opacity.value,
              child: child,
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
