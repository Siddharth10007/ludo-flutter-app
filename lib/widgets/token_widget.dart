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
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          border: Border.all(
            color: canMove ? Colors.white : Colors.black45,
            width: canMove ? 2.5 : 1.0,
          ),
          boxShadow: canMove
              ? [
            BoxShadow(
              color: Colors.white.withOpacity(0.6),
              blurRadius: 6,
              spreadRadius: 1,
            ),
          ]
              : null,
        ),
      ),
    );
  }
}