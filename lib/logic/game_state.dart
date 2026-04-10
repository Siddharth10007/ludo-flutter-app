import 'package:flutter/material.dart';
import '../models/player.dart';
import '../models/token.dart';
import '../utils/constants.dart';

class GameState extends ChangeNotifier {
  // ── State ─────────────────────────────────────────────────────────────────
  late List<Player> players;
  int currentPlayerIndex = 0;
  int diceValue = 1;
  bool hasDiceBeenRolled = false;
  String? winnerName;
  String statusMessage = '';
  bool gameOver = false;

  // ── Initialise ────────────────────────────────────────────────────────────
  void initGame(int numPlayers) {
    players = List.generate(
      numPlayers,
          (i) => Player(index: i, name: kPlayerNames[i]),
    );
    currentPlayerIndex = 0;
    diceValue = 1;
    hasDiceBeenRolled = false;
    winnerName = null;
    gameOver = false;
    statusMessage = '${kPlayerNames[0]}\'s turn – roll the dice!';
    notifyListeners();
  }

  Player get currentPlayer => players[currentPlayerIndex];

  // ── Roll dice ─────────────────────────────────────────────────────────────
  void rollDice() {
    if (hasDiceBeenRolled || gameOver) return;
    diceValue = (DateTime.now().millisecondsSinceEpoch % 6) + 1;
    hasDiceBeenRolled = true;

    // Check if any move is possible
    if (!_hasAnyValidMove(currentPlayer, diceValue)) {
      statusMessage =
      '${currentPlayer.name}: rolled $diceValue – no valid move, turn skipped.';
      notifyListeners();
      // auto-advance after brief pause (caller calls advanceTurn)
      Future.delayed(const Duration(milliseconds: 900), () {
        _advanceTurn(bonusTurn: false);
      });
      return;
    }

    statusMessage =
    '${currentPlayer.name}: rolled $diceValue – choose a token to move.';
    notifyListeners();
  }

  // ── Move a token ──────────────────────────────────────────────────────────
  void moveToken(int playerIdx, int tokenIdx) {
    if (!hasDiceBeenRolled || gameOver) return;
    if (playerIdx != currentPlayerIndex) return;

    final player = players[playerIdx];
    final token = player.tokens[tokenIdx];

    if (!_isValidMove(player, token, diceValue)) return;

    // --- Apply move ---
    if (token.isHome) {
      // Enter board: place at player's entry position
      token.position = kEntryPositions[playerIdx];
    } else {
      token.position += diceValue;
      // Clamp: cannot exceed 57 (last home-column cell before finish)
      if (token.position > 57) {
        token.position -= diceValue; // revert – over-shoot not allowed
        statusMessage = 'Cannot move that token – would overshoot home!';
        notifyListeners();
        return;
      }
      if (token.position == 57) {
        token.position = 58; // mark finished
      }
    }

    // --- Check for capture ---
    bool captured = false;
    if (token.isOnBoard) {
      captured = _handleCapture(playerIdx, token);
    }

    // --- Check win ---
    if (player.checkWin()) {
      winnerName = player.name;
      gameOver = true;
      statusMessage = '🎉 ${player.name} wins!';
      notifyListeners();
      return;
    }

    // --- Decide next turn ---
    bool bonusTurn = (diceValue == 6) || captured;
    // Note: in many Ludo variants a capture also grants an extra turn.
    statusMessage = bonusTurn
        ? '${currentPlayer.name} gets a bonus turn!'
        : '';
    hasDiceBeenRolled = false;
    notifyListeners();

    _advanceTurn(bonusTurn: bonusTurn);
  }

  // ── Capture logic ─────────────────────────────────────────────────────────
  // Returns true if at least one opponent token was sent home.
  bool _handleCapture(int attackerPlayerIdx, Token attacker) {
    // Only main track positions can be captures (pos 0-51).
    if (attacker.position > 51) return false;
    // Safe zone? No capture allowed.
    if (kSafePositions.contains(attacker.position)) return false;

    bool captured = false;
    for (final opponent in players) {
      if (opponent.index == attackerPlayerIdx) continue;
      for (final ot in opponent.tokens) {
        if (ot.isOnBoard && ot.position == attacker.position && ot.position <= 51) {
          // Opponent is on main track at same square → send home
          ot.position = -1;
          captured = true;
        }
      }
    }
    return captured;
  }

  // ── Advance turn ──────────────────────────────────────────────────────────
  void _advanceTurn({required bool bonusTurn}) {
    hasDiceBeenRolled = false;
    if (!bonusTurn) {
      currentPlayerIndex = (currentPlayerIndex + 1) % players.length;
      // Skip players who have already won
      int safety = 0;
      while (players[currentPlayerIndex].hasWon && safety < players.length) {
        currentPlayerIndex = (currentPlayerIndex + 1) % players.length;
        safety++;
      }
    }
    statusMessage = '${currentPlayer.name}\'s turn – roll the dice!';
    notifyListeners();
  }

  // ── Validity helpers ──────────────────────────────────────────────────────
  bool _hasAnyValidMove(Player player, int dice) {
    return player.tokens.any((t) => _isValidMove(player, t, dice));
  }

  bool _isValidMove(Player player, Token token, int dice) {
    if (token.isFinished) return false;

    if (token.isHome) {
      // Can only leave home on a 6
      return dice == 6;
    }

    // On board
    int newPos = token.position + dice;
    if (newPos > 57) return false; // would overshoot

    // In home column – no captures, always valid if no overshoot
    if (token.position >= 52) return true;

    // On main track
    // Check if landing on own token that's blocking (stacking rules: simple
    // Ludo allows stacking, so we allow it – only block if all 4 own tokens
    // already there, which is practically impossible in normal play).
    return true;
  }

  // ── Absolute board position → pixel offset ────────────────────────────────
  // Returns the Offset for drawing a token given:
  //  • its absolute position (–1 = base, 0-51 = main, 52-57 = home column, 58 = finished)
  //  • the board pixel size
  //  • a small sub-offset to avoid overlap when multiple tokens share a cell
  Offset getTokenOffset(Token token, double boardSize, {int subIndex = 0}) {
    final int playerIdx = token.playerIndex;

    if (token.isHome) {
      final bases = buildBasePositions(playerIdx, boardSize);
      return bases[token.tokenIndex];
    }

    if (token.isFinished) {
      // All finished tokens cluster in the centre
      final centre = Offset(boardSize / 2, boardSize / 2);
      final offsets = [
        const Offset(-8, -8), const Offset(8, -8),
        const Offset(-8, 8), const Offset(8, 8),
      ];
      return centre + offsets[token.tokenIndex];
    }

    // Home column (52-57)
    if (token.position >= 52) {
      final col = buildHomeColumnPath(playerIdx, boardSize);
      final idx = (token.position - 52).clamp(0, col.length - 1);
      return col[idx];
    }

    // Main track
    final mainPath = buildMainPath(boardSize);
    // Translate absolute position to player-relative index then back
    final absPos = _absoluteToMainIndex(playerIdx, token.position);
    final base = mainPath[absPos.clamp(0, mainPath.length - 1)];

    // Slight stagger so stacked tokens are visible
    final stagger = [
      const Offset(0, 0), const Offset(5, 0),
      const Offset(0, 5), const Offset(5, 5),
    ];
    return base + stagger[token.tokenIndex];
  }

  // Convert a player's token position (0-51 = absolute main track index).
  // In our scheme position IS already the absolute index, so no conversion needed.
  int _absoluteToMainIndex(int playerIdx, int pos) => pos;

  // ── Public helper: is this token tappable right now? ─────────────────────
  bool canMoveToken(int playerIdx, int tokenIdx) {
    if (!hasDiceBeenRolled || gameOver) return false;
    if (playerIdx != currentPlayerIndex) return false;
    final token = players[playerIdx].tokens[tokenIdx];
    return _isValidMove(players[playerIdx], token, diceValue);
  }
}