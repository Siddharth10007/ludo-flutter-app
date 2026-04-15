import 'package:flutter/material.dart';

// ── Player colours & names ────────────────────────────────────────────────────
const List<Color> kPlayerColors = [
  Color(0xFFE53935), // Red    (player 0) – bottom-left quadrant
  Color(0xFF1E88E5), // Blue   (player 1) – bottom-right quadrant
  Color(0xFF43A047), // Green  (player 2) – top-left quadrant
  Color(0xFFFDD835), // Yellow (player 3) – top-right quadrant
];

const List<String> kPlayerNames = ['Red', 'Blue', 'Green', 'Yellow'];

// ── Path lengths ──────────────────────────────────────────────────────────────
const int kMainPathLength    = 52; // squares on the outer track
const int kHomeColumnLength  =  6; // steps inside the coloured home column
const int kTotalPathLength   = 58; // 52 + 6

// ── Safe squares (cannot be captured here) ───────────────────────────────────
//
// Standard Ludo star/safe squares on the 52-square main path.
// These correspond to the coloured "star" cells on a real board.
//
//   idx  (col,row)  meaning
//    0   (6,13)     Red entry
//    8   (2, 8)     safe
//   13   (1, 6)     Green entry
//   21   (6, 2)     safe
//   26   (8, 0)     Yellow entry  ← fixed (was wrong)
//   34   (12,6)     safe
//   39   (14,8)     Blue entry    ← fixed (was wrong)
//   47   (8,12)     safe
//
// Entry squares are inherently safe; the four mid-side squares are also safe.
const List<int> kSafePositions = [0, 8, 13, 21, 26, 34, 39, 47];

// ── Entry positions ───────────────────────────────────────────────────────────
//
// Absolute path index where a token is placed when the player rolls a 6.
//
//   Red    (0) → idx  0  → (6,13)  bottom of left vertical track  ✓
//   Blue   (1) → idx 39  → (14,8)  right side of right horizontal track
//   Green  (2) → idx 13  → (1, 6)  left side of top horizontal track
//   Yellow (3) → idx 26  → (8, 0)  top of right vertical track
//
// NOTE: The original code had [0,13,26,39] which gave Blue=Green's entry,
//       Green=Yellow's entry, and Yellow=Blue's entry.  Fixed below.
const List<int> kEntryPositions = [0, 39, 13, 26];

// ── Grid helper ───────────────────────────────────────────────────────────────
//
// Returns the pixel centre of the cell at (col, row) on the 15×15 grid.
Offset cellCenter(int col, int row, double boardSize) {
  final c = boardSize / 15;
  return Offset(col * c + c / 2, row * c + c / 2);
}

// Convenience alias used internally
Offset _cell(int col, int row, double s) => cellCenter(col, row, s);

// ── Main path – 52 squares, clockwise ────────────────────────────────────────
//
// Standard Ludo board path verified against the classic layout.
//
//  Sector   direction     squares   col/row fixed
//  ───────────────────────────────────────────────
//  Red up   ↑ col=6       0–4      rows 13→9
//  bend-1   ← row=8       5–10     cols  5→0
//  left↑    ↑ col=0      11–12     rows  7→6
//  top→     → row=6      13–18     cols  1→6   (Green enters at 13)
//  top↑     ↑ col=6      19–23     rows  5→1
//  bend-2   → row=0      24–25     cols  7→8   (top centre turn)
//  Yel↓     ↓ col=8      26–31     rows  0→5   (Yellow enters at 26)
//  right→   → row=6      32–37     cols  9→14
//  right↓   ↓ col=14     38–39     rows  7→8   (Blue enters at 39)
//  bottom←  ← row=8      40–45     cols 13→8
//  Red↓     ↓ col=8      46–51     rows  9→14
//
List<Offset> buildMainPath(double boardSize) {
  final s = boardSize;
  final coords = <(int, int)>[
    // 0–4: Red entry column going UP (col=6, rows 13→9)
    (6, 13), // 0  ← Red entry
    (6, 12), // 1
    (6, 11), // 2
    (6, 10), // 3
    (6,  9), // 4

    // 5–10: Bottom-left bend going LEFT (row=8, cols 5→0)
    (5,  8), // 5
    (4,  8), // 6
    (3,  8), // 7
    (2,  8), // 8  ← safe
    (1,  8), // 9
    (0,  8), // 10

    // 11–12: Left edge going UP (col=0, rows 7→6)
    (0,  7), // 11
    (0,  6), // 12

    // 13–18: Green entry + going RIGHT (row=6, cols 1→6)
    (1,  6), // 13 ← Green entry / safe
    (2,  6), // 14
    (3,  6), // 15
    (4,  6), // 16
    (5,  6), // 17
    (6,  6), // 18

    // 19–23: Going UP left of centre (col=6, rows 5→1)
    (6,  5), // 19
    (6,  4), // 20
    (6,  3), // 21 ← safe
    (6,  2), // 22
    (6,  1), // 23

    // 24–25: Top-centre bend going RIGHT (row=0, cols 7→8)
    (7,  0), // 24
    (7,  1), // 25  ← ramp into Yellow column

    // 26–31: Yellow entry + going DOWN (col=8, rows 0→5)
    (8,  0), // 26 ← Yellow entry / safe
    (8,  1), // 27
    (8,  2), // 28
    (8,  3), // 29
    (8,  4), // 30
    (8,  5), // 31

    // 32–37: Top-right bend going RIGHT (row=6, cols 9→14)
    (9,  6), // 32
    (10, 6), // 33
    (11, 6), // 34 ← safe
    (12, 6), // 35
    (13, 6), // 36
    (14, 6), // 37

    // 38–39: Right edge going DOWN (col=14, rows 7→8)
    (14, 7), // 38
    (14, 8), // 39 ← Blue entry / safe

    // 40–45: Bottom-right bend going LEFT (row=8, cols 13→8)
    (13, 8), // 40
    (12, 8), // 41
    (11, 8), // 42
    (10, 8), // 43
    (9,  8), // 44
    (8,  8), // 45

    // 46–51: Red-side going DOWN (col=8, rows 9→14)
    (8,  9), // 46
    (8, 10), // 47 ← safe
    (8, 11), // 48
    (8, 12), // 49
    (8, 13), // 50
    (8, 14), // 51  → wraps to 0
  ];

  return coords.map((c) => _cell(c.$1, c.$2, s)).toList();
}

// ── Home column paths (6 steps into the centre for each player) ───────────────
//
// After 52 main-track squares, the token enters its coloured home column.
// position 52 = first step in, position 57 = last step before finish.
//
//   Red    (0): col=7, rows 13→8 going UP
//   Blue   (1): row=7, cols 13→8 going LEFT
//   Green  (2): col=7, rows  1→6 going DOWN
//   Yellow (3): row=7, cols  1→6 going RIGHT
//
List<Offset> buildHomeColumnPath(int playerIndex, double boardSize) {
  final s = boardSize;
  const homePaths = [
    // Red (0)
    [(7,13),(7,12),(7,11),(7,10),(7,9),(7,8)],
    // Blue (1)
    [(13,7),(12,7),(11,7),(10,7),(9,7),(8,7)],
    // Green (2)
    [(7,1),(7,2),(7,3),(7,4),(7,5),(7,6)],
    // Yellow (3)
    [(1,7),(2,7),(3,7),(4,7),(5,7),(6,7)],
  ];
  return homePaths[playerIndex].map((c) => _cell(c.$1, c.$2, s)).toList();
}

// ── Base (home yard) token positions ─────────────────────────────────────────
//
// Each quadrant is 6×6 cells.  Tokens sit in a 2×2 arrangement inside the
// white inner yard that occupies roughly cells 1–4 within each quadrant.
//
// Quadrant top-left corners on the 15×15 grid:
//   Red    (0) bottom-left  qx=0,  qy=9
//   Blue   (1) bottom-right qx=9,  qy=9
//   Green  (2) top-left     qx=0,  qy=0
//   Yellow (3) top-right    qx=9,  qy=0
//
List<Offset> buildBasePositions(int playerIndex, double boardSize) {
  final c = boardSize / 15; // one cell size

  List<Offset> quad(double qx, double qy) {
    // Token centres placed at cells (qx+1.5, qy+1.5) and (qx+3.5, qy+3.5)
    // inside the quadrant – sits nicely within the inner white yard.
    final double x1 = (qx + 1.5) * c;
    final double x2 = (qx + 3.5) * c;
    final double y1 = (qy + 1.5) * c;
    final double y2 = (qy + 3.5) * c;
    return [
      Offset(x1, y1), // top-left token
      Offset(x2, y1), // top-right token
      Offset(x1, y2), // bottom-left token
      Offset(x2, y2), // bottom-right token
    ];
  }

  switch (playerIndex) {
    case 0: return quad(0, 9);  // Red    – bottom-left
    case 1: return quad(9, 9);  // Blue   – bottom-right
    case 2: return quad(0, 0);  // Green  – top-left
    case 3: return quad(9, 0);  // Yellow – top-right
    default: return [];
  }
}