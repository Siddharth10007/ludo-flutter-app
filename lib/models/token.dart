// Represents a single token (piece) for a player.
class Token {
  final int playerIndex; // which player owns this token (0-3)
  final int tokenIndex;  // which token within the player (0-3)

  // position meanings:
  //  -1  → still in home base (not yet entered)
  //   0-51 → on main track (absolute index)
  //  52-57 → in home column (52=first step, 57=arrived)
  //  58  → FINISHED (reached centre)
  int position;

  Token({
    required this.playerIndex,
    required this.tokenIndex,
    this.position = -1,
  });

  bool get isHome => position == -1;
  bool get isFinished => position >= 58;
  bool get isOnBoard => position >= 0 && position < 58;
}