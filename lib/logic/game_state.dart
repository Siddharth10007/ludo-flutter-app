import 'package:flutter/material.dart';
import '../models/player.dart';
import '../models/token.dart';
import '../utils/constants.dart';
import 'dart:math';

class GameState extends ChangeNotifier {
  late List<Player> players;
  int currentPlayerIndex = 0;
  int diceValue = 1;
  bool hasDiceBeenRolled = false;
  String? winnerName;
  String statusMessage = '';
  bool gameOver = false;

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

  // ── Dice roll ─────────────────────────────────────────────────────────────

  void rollDice() {
    if (hasDiceBeenRolled || gameOver) return;

    // Use a better random source
    final random = Random();
    diceValue = random.nextInt(6) + 1;
    hasDiceBeenRolled = true;

    if (!_hasAnyValidMove(currentPlayer, diceValue)) {
      statusMessage =
      '${currentPlayer.name}: rolled $diceValue – no valid move, skipping.';
      notifyListeners();
      Future.delayed(const Duration(milliseconds: 900), () {
        _advanceTurn(bonusTurn: false);
      });
      return;
    }

    statusMessage =
    '${currentPlayer.name}: rolled $diceValue – choose a token to move.';
    notifyListeners();
  }

  // ── Move token ────────────────────────────────────────────────────────────

  void moveToken(int playerIdx, int tokenIdx) {
    if (!hasDiceBeenRolled || gameOver) return;
    if (playerIdx != currentPlayerIndex) return;

    final player = players[playerIdx];
    final token  = player.tokens[tokenIdx];

    if (!_isValidMove(player, token, diceValue)) return;

    if (token.isHome) {
      // Enter the board at this player's entry square
      token.position = kEntryPositions[playerIdx];
    } else {
      // Relative progress from this player's entry square (0–51 on main track)
      final int relPos = _relativePosition(playerIdx, token.position);

      if (relPos + diceValue >= 52) {
        // Token entering / moving through home column
        final int homeStep = relPos + diceValue - 52; // 0 = first home-col square
        if (homeStep > 5) {
          statusMessage = 'Cannot move – would overshoot home!';
          notifyListeners();
          return;
        }
        token.position = 52 + homeStep;
        if (token.position == 57) {
          token.position = 58; // finished
        }
      } else {
        // Still on main track – advance absolute position, wrap at 52
        token.position = (token.position + diceValue) % kMainPathLength;
      }
    }

    bool captured = false;
    if (token.isOnBoard) {
      captured = _handleCapture(playerIdx, token);
    }

    if (player.checkWin()) {
      winnerName = player.name;
      gameOver   = true;
      statusMessage = '🎉 ${player.name} wins!';
      notifyListeners();
      return;
    }

    bool bonusTurn = (diceValue == 6) || captured;
    hasDiceBeenRolled = false;
    statusMessage = bonusTurn
        ? '${currentPlayer.name} gets a bonus turn!'
        : '${currentPlayer.name}\'s turn done.';
    notifyListeners();

    _advanceTurn(bonusTurn: bonusTurn);
  }

  // ── Relative position helper ──────────────────────────────────────────────
  //
  // Returns how many steps this token has advanced from its player's entry
  // square on the main track (0–51).  Should only be called when the token
  // is on the main track (position 0–51).

  int _relativePosition(int playerIdx, int absPos) {
    // If the token is already in the home column, return a value ≥ 52
    if (absPos >= 52) return absPos; // caller should not call this branch
    final entry = kEntryPositions[playerIdx];
    return (absPos - entry + kMainPathLength) % kMainPathLength;
  }

  // ── Capture ───────────────────────────────────────────────────────────────

  bool _handleCapture(int attackerPlayerIdx, Token attacker) {
    if (attacker.position > 51) return false;
    if (kSafePositions.contains(attacker.position)) return false;

    bool captured = false;
    for (final opponent in players) {
      if (opponent.index == attackerPlayerIdx) continue;
      for (final ot in opponent.tokens) {
        if (ot.isOnBoard &&
            ot.position == attacker.position &&
            ot.position <= 51) {
          ot.position = -1; // send home
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

  // ── Validity checks ───────────────────────────────────────────────────────

  bool _hasAnyValidMove(Player player, int dice) {
    return player.tokens.any((t) => _isValidMove(player, t, dice));
  }

  bool _isValidMove(Player player, Token token, int dice) {
    if (token.isFinished) return false;
    if (token.isHome)     return dice == 6;

    // Inside home column
    if (token.position >= 52) {
      final homeStep = token.position - 52; // 0–5
      return homeStep + dice <= 5;
    }

    // On main track – check for overshoot into home column
    final relPos  = _relativePosition(player.index, token.position);
    final newRel  = relPos + dice;
    // After 52 relative steps the token enters home column (6 squares)
    if (newRel > 57) return false; // would overshoot past finish
    return true;
  }

  // ── Token offset (pixel centre on board) ─────────────────────────────────

  Offset getTokenOffset(Token token, double boardSize, {int subIndex = 0}) {
    final int playerIdx = token.playerIndex;

    if (token.isHome) {
      final bases = buildBasePositions(playerIdx, boardSize);
      return bases[token.tokenIndex];
    }

    if (token.isFinished) {
      // Cluster finished tokens around the board centre
      final centre = Offset(boardSize / 2, boardSize / 2);
      const offsets = [
        Offset(-9, -9), Offset(9, -9),
        Offset(-9,  9), Offset(9,  9),
      ];
      return centre + offsets[token.tokenIndex];
    }

    if (token.position >= 52) {
      final col = buildHomeColumnPath(playerIdx, boardSize);
      final idx = (token.position - 52).clamp(0, col.length - 1);
      return col[idx];
    }

    // Main track
    final mainPath = buildMainPath(boardSize);
    final base     = mainPath[token.position.clamp(0, mainPath.length - 1)];

    // Slight stagger when multiple tokens share a square
    const stagger = [
      Offset(0, 0), Offset(5, 0),
      Offset(0, 5), Offset(5, 5),
    ];
    return base + stagger[token.tokenIndex];
  }

  bool canMoveToken(int playerIdx, int tokenIdx) {
    if (!hasDiceBeenRolled || gameOver) return false;
    if (playerIdx != currentPlayerIndex)  return false;
    final token = players[playerIdx].tokens[tokenIdx];
    return _isValidMove(players[playerIdx], token, diceValue);
  }
}