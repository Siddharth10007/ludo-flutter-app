import 'package:flutter/material.dart';
import '../logic/game_state.dart';
import '../utils/constants.dart';
import 'token_widget.dart';

class LudoBoard extends StatelessWidget {
  final GameState gameState;
  final double boardSize;

  const LudoBoard({
    super.key,
    required this.gameState,
    required this.boardSize,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: boardSize,
      height: boardSize,
      child: Stack(
        children: [
          // ── Board image ──────────────────────────────────────────────────
          Image.asset(
            'assets/images/ludo_board.png',
            width: boardSize,
            height: boardSize,
            fit: BoxFit.fill,
          ),

          // ── Tokens ───────────────────────────────────────────────────────
          ..._buildAllTokens(),
        ],
      ),
    );
  }

  List<Widget> _buildAllTokens() {
    final List<Widget> widgets = [];

    for (final player in gameState.players) {
      for (final token in player.tokens) {
        final offset =
        gameState.getTokenOffset(token, boardSize, subIndex: token.tokenIndex);
        final canMove =
        gameState.canMoveToken(player.index, token.tokenIndex);

        widgets.add(
          Positioned(
            left: offset.dx - 10, // centre the 20×20 widget
            top: offset.dy - 10,
            child: TokenWidget(
              color: kPlayerColors[player.index],
              canMove: canMove,
              onTap: () => gameState.moveToken(player.index, token.tokenIndex),
            ),
          ),
        );
      }
    }

    return widgets;
  }
}