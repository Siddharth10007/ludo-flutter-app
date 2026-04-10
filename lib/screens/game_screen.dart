import 'package:flutter/material.dart';
import '../logic/game_state.dart';
import '../utils/constants.dart';
import '../widgets/ludo_board.dart';
import '../widgets/dice_widget.dart';
import 'player_selection_screen.dart';

class GameScreen extends StatefulWidget {
  final int numPlayers;
  const GameScreen({super.key, required this.numPlayers});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late GameState _gameState;

  @override
  void initState() {
    super.initState();
    _gameState = GameState();
    _gameState.initGame(widget.numPlayers);
    // Listen for state changes and call setState to rebuild UI
    _gameState.addListener(_onGameStateChanged);
  }

  void _onGameStateChanged() {
    if (mounted) setState(() {});
    if (_gameState.gameOver && _gameState.winnerName != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showWinDialog());
    }
  }

  void _showWinDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('🎉 Game Over!'),
        content: Text(
          '${_gameState.winnerName} wins!\nCongratulations!',
          style: const TextStyle(fontSize: 18),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                    builder: (_) => const PlayerSelectionScreen()),
              );
            },
            child: const Text('Play Again'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _gameState.removeListener(_onGameStateChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final boardSize = screenWidth - 16;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: SafeArea(
        child: Column(
          children: [
            // ── Status bar ──────────────────────────────────────────────────
            _buildStatusBar(),

            // ── Board ───────────────────────────────────────────────────────
            Expanded(
              child: Center(
                child: LudoBoard(
                  gameState: _gameState,
                  boardSize: boardSize,
                ),
              ),
            ),

            // ── Dice + controls ─────────────────────────────────────────────
            _buildControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBar() {
    final cp = _gameState.currentPlayer;
    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: kPlayerColors[cp.index].withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kPlayerColors[cp.index].withOpacity(0.5)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: kPlayerColors[cp.index],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _gameState.statusMessage,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControls() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Player indicator pills
          ..._gameState.players.map((p) {
            final isActive = p.index == _gameState.currentPlayerIndex;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: kPlayerColors[p.index]
                    .withOpacity(isActive ? 0.9 : 0.25),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: kPlayerColors[p.index],
                  width: isActive ? 2 : 1,
                ),
              ),
              child: Text(
                p.name,
                style: TextStyle(
                  color: isActive ? Colors.white : Colors.white54,
                  fontWeight: isActive
                      ? FontWeight.bold
                      : FontWeight.normal,
                  fontSize: 12,
                ),
              ),
            );
          }),

          // Dice widget
          DiceWidget(
            diceValue: _gameState.diceValue,
            canRoll: !_gameState.hasDiceBeenRolled && !_gameState.gameOver,
            onRoll: () => setState(() => _gameState.rollDice()),
          ),
        ],
      ),
    );
  }
}