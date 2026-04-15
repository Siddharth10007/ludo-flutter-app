import 'package:flutter/material.dart';

class TokenWidget extends StatelessWidget {
  final Color color;
  final bool canMove;   // highlights tappable tokens
  final VoidCallback onTap;

  const TokenWidget({
    super.key,
    required this.color,
    required this.canMove,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: canMove ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          // Slightly lighter inner fill + coloured border for a 3-D look
          gradient: RadialGradient(
            center: const Alignment(-0.3, -0.3),
            colors: [
              Color.lerp(color, Colors.white, 0.45)!,
              color,
            ],
          ),
          border: Border.all(
            color: canMove ? Colors.white : Colors.black45,
            width: canMove ? 2.5 : 1.2,
          ),
          boxShadow: canMove
              ? [
            BoxShadow(
              color: Colors.white.withOpacity(0.7),
              blurRadius: 8,
              spreadRadius: 1,
            ),
            BoxShadow(
              color: color.withOpacity(0.6),
              blurRadius: 4,
              spreadRadius: 0,
            ),
          ]
              : [
            BoxShadow(
              color: Colors.black38,
              blurRadius: 3,
              offset: const Offset(1, 1),
            ),
          ],
        ),
      ),
    );
  }
}