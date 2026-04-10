import 'package:flutter/material.dart';

class DiceWidget extends StatelessWidget {
  final int diceValue;   // 1-6
  final bool canRoll;
  final VoidCallback onRoll;

  const DiceWidget({
    super.key,
    required this.diceValue,
    required this.canRoll,
    required this.onRoll,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: canRoll ? onRoll : null,
      child: AnimatedOpacity(
        opacity: canRoll ? 1.0 : 0.55,
        duration: const Duration(milliseconds: 200),
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: canRoll
                ? [
              BoxShadow(
                color: Colors.white.withOpacity(0.3),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ]
                : null,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              'assets/images/dice$diceValue.png',
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }
}