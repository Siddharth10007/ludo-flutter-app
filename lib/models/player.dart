import 'token.dart';

class Player {
  final int index;
  final String name;
  final List<Token> tokens;
  bool hasWon = false;

  Player({required this.index, required this.name})
      : tokens = List.generate(
    4,
        (i) => Token(playerIndex: index, tokenIndex: i),
  );

  // Returns true when all 4 tokens have finished.
  bool checkWin() {
    hasWon = tokens.every((t) => t.isFinished);
    return hasWon;
  }
}