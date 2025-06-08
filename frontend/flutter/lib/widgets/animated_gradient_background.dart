import 'package:flutter/material.dart';

class AnimatedGradientBackground extends StatefulWidget {
  final Widget child;

  const AnimatedGradientBackground({super.key, required this.child});

  @override
  State<AnimatedGradientBackground> createState() =>
      _AnimatedGradientBackgroundState();
}

class _AnimatedGradientBackgroundState extends State<AnimatedGradientBackground>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Color?> _animation1;
  late Animation<Color?> _animation2;

  final List<Color> colorList = [
    const Color(0xFF4A5B7B), // Muted blue
    const Color(0xFF8B6B9C), // Muted purple-pink
    const Color(0xFF855B5B), // Muted red
    const Color(0xFF4A5C7D), // Another muted blue shade
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();

    _animation1 = TweenSequence<Color?>([
      TweenSequenceItem(
        weight: 1.0,
        tween: ColorTween(begin: colorList[0], end: colorList[1]),
      ),
      TweenSequenceItem(
        weight: 1.0,
        tween: ColorTween(begin: colorList[1], end: colorList[2]),
      ),
      TweenSequenceItem(
        weight: 1.0,
        tween: ColorTween(begin: colorList[2], end: colorList[3]),
      ),
      TweenSequenceItem(
        weight: 1.0,
        tween: ColorTween(begin: colorList[3], end: colorList[0]),
      ),
    ]).animate(_controller);

    _animation2 = TweenSequence<Color?>([
      TweenSequenceItem(
        weight: 1.0,
        tween: ColorTween(begin: colorList[1], end: colorList[2]),
      ),
      TweenSequenceItem(
        weight: 1.0,
        tween: ColorTween(begin: colorList[2], end: colorList[3]),
      ),
      TweenSequenceItem(
        weight: 1.0,
        tween: ColorTween(begin: colorList[3], end: colorList[0]),
      ),
      TweenSequenceItem(
        weight: 1.0,
        tween: ColorTween(begin: colorList[0], end: colorList[1]),
      ),
    ]).animate(_controller);
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
        AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_animation1.value!, _animation2.value!],
                ),
              ),
            );
          },
        ),
        BackdropFilter(
          filter: ColorFilter.mode(
            Colors.black.withValues(
              red: 0,
              green: 0,
              blue: 0,
              alpha: 217,
            ), // Slightly darker overlay (0.85 * 255 ≈ 217)
            BlendMode.softLight,
          ),
          child: widget.child,
        ),
      ],
    );
  }
}
