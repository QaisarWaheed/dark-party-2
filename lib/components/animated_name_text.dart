import 'package:flutter/material.dart';

class AnimatedNameText extends StatefulWidget {
  final String text;
  final double fontSize; // 👈 optional
  final Color? color;
  final List<Shadow>? shadows;

  const AnimatedNameText({
    super.key,
    required this.text,
    this.fontSize = 16, // 👈 default size
    this.color,
    this.shadows,
  });

  @override
  State<AnimatedNameText> createState() => _AnimatedNameTextState();
}

class _AnimatedNameTextState extends State<AnimatedNameText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.color != null) {
      return Text(
        widget.text,
        style: TextStyle(
          fontSize: widget.fontSize,
          fontWeight: FontWeight.bold,
          color: widget.color,
          shadows: widget.shadows,
        ),
      );
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: const [
                Color(0xFFFFD700), // Gold
                Color(0xFF9B59B6), // Purple
                Color(0xFFFF4ECD), // Pink
                Color(0xFF00E5FF), // Cyan
              ],
              stops: const [0.0, 0.33, 0.66, 1.0],
              transform:
                  GradientRotation(_controller.value * 2 * 3.1416),
            ).createShader(bounds);
          },
          child: Text(
            widget.text,
            style: TextStyle(
              fontSize: widget.fontSize, // 👈 use here
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        );
      },
    );
  }
}
