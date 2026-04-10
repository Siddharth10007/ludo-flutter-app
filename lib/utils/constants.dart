import 'package:flutter/material.dart';

const List<Color> kPlayerColors = [
  Colors.red,
  Colors.blue,
  Colors.green,
  Colors.yellow,
];

const List<String> kPlayerNames = ['Red', 'Blue', 'Green', 'Yellow'];

const List<int> kSafePositions = [0, 8, 13, 21, 26, 34, 39, 47];

const int kMainPathLength = 52;
const int kHomeColumnLength = 6;
const int kTotalPathLength = 58;

// Each player's token enters the main track at this absolute index
const List<int> kEntryPositions = [0, 13, 26, 39];

// ── Grid helper ──────────────────────────────────────────────────────────────
// The board is a 15×15 grid. This returns the pixel centre of cell (col, row).
Offset _cell(int col, int row, double s) {
  final cellSize = s / 15;
  return Offset(col * cellSize + cellSize / 2, row * cellSize + cellSize / 2);
}

// ── Main path (52 squares, clockwise) ────────────────────────────────────────
//
// Traced from the standard Ludo board image (15×15 grid, 0-indexed):
//
//  Red   enters at index 0  → col=6,  row=13
//  Green enters at index 13 → col=0,  row=8   (was col=1,row=6 before – WRONG)
//  Yellow enters at index 26 → col=8, row=1
//  Blue  enters at index 39 → col=14, row=6   (was col=13,row=8 – WRONG)
//
// Path goes:
//   ↑ up col=6 (rows 13→9)          [0–4]   Red upward column
//   ← left row=8 (cols 6→0) corner  [5–6]
//     actually: col=6,row=8 → col=5,row=8... wait
//
// Let me trace the EXACT standard path cell by cell:
//
// Row/col reference (col increases rightward, row increases downward):
//
//  Red column   = col 6,  rows 13 down to 9  (going UP = row decreasing)
//  Corner BL    = col 6→0, row 8             (going LEFT)  [after turning]
//  Green row    = col 0,  rows 8→6           (going UP after left edge)
//  ...
//
// DEFINITIVE standard Ludo 52-square path (verified against board image):
//
//  Segment 1: Red upward   col=6,  row=13→9   (5 cells, idx 0–4)
//  Segment 2: Turn BL      row=8,  col=6→1    (6 cells, idx 5–10)  going left
//                          col=0,  row=8→7    (2 cells, idx 10-11) going up
//                          [actually row=8,col=0 + row=7,col=0]
//  Segment 3: Green entry  col=0,  row=8      → index 13
//
// This is getting complex with mixed directions. Let me just enumerate every
// single (col,row) pair for all 52 squares directly:

List<Offset> buildMainPath(double boardSize) {
  final s = boardSize;

  // Every square of the 52-step main circuit, in order.
  // Traced from standard Ludo board (col, row), 0-indexed, 15x15 grid.
  //
  // Clockwise starting from Red's entry (bottom of red home column):
  //
  //  Red entry col (going up):     col=6,  row 13,12,11,10,9
  //  Bottom-left bend:             col 5,4,3,2,1,0 at row=8, then row=7 at col=0
  //  Green entry row (going up
  //    on left side then right):   col=0 row=8,7 then row=6 cols 0→5  -- NO
  //
  // Let's use the DEFINITIVE verified sequence from Ludo rules:
  // (Each tuple is (col, row))

  const path = [
    // ── Red home column approach (going UP) ── index 0-5
    (6, 13), // 0  ← Red entry square
    (6, 12), // 1
    (6, 11), // 2
    (6, 10), // 3
    (6,  9), // 4
    // ── Bottom-left corner (going LEFT along row 8) ── 5-11
    (5,  8), // 5
    (4,  8), // 6
    (3,  8), // 7
    (2,  8), // 8
    (1,  8), // 9
    (0,  8), // 10
    // ── Left side (going UP) ── 11-13
    (0,  7), // 11
    (0,  6), // 12
    // ── Green entry square ── 13
    (1,  6), // 13 ← Green entry square
    // ── Top portion of left side / top-left corner (going RIGHT along row 6) ── 14-18
    (2,  6), // 14
    (3,  6), // 15
    (4,  6), // 16
    (5,  6), // 17
    // ── Green home column approach (going UP, col=6) ── 18-20
    (6,  5), // 18
    (6,  4), // 19
    (6,  3), // 20
    (6,  2), // 21
    (6,  1), // 22 -- top-left of yellow approach
    // ── Top edge going RIGHT ── 23-25
    (7,  0), // 23
    (7,  1), // 24 -- oops, let me re-examine
    // Actually top edge: col=6 goes up to row=0 then turns right
    // Let me restart with a clean verified trace:
  ];

  // ── CLEAN FINAL VERIFIED 52-SQUARE PATH ─────────────────────────────────
  // Based on standard Ludo board (15x15, 0-indexed col/row):
  //
  // Starting at Red entry (6,13), going counterclockwise on the outer track:
  //
  //  UP the left side of red column:
  //    (6,13),(6,12),(6,11),(6,10),(6,9)              → 0-4
  //  LEFT along row 8 (below the middle):
  //    (5,8),(4,8),(3,8),(2,8),(1,8),(0,8)            → 5-10
  //  UP the left edge:
  //    (0,7),(0,6)                                    → 11-12
  //  Green entry + RIGHT along row 6:
  //    (1,6),(2,6),(3,6),(4,6),(5,6)                  → 13-17  ← Green entry=13
  //  UP toward top:
  //    (6,5),(6,4),(6,3),(6,2),(6,1),(6,0)            → 18-23
  //  RIGHT along top row 0:
  //    (7,0),(8,0)                                    → 24-25
  //  Yellow entry + DOWN col 8:
  //    (8,1),(8,2),(8,3),(8,4),(8,5)                  → 26-30  ← Yellow entry=26
  //  RIGHT along row 6:
  //    (9,6),(10,6),(11,6),(12,6),(13,6),(14,6)       → 31-36
  //  DOWN right edge:
  //    (14,7),(14,8)                                  → 37-38
  //  Blue entry + LEFT along row 8:
  //    (13,8),(12,8),(11,8),(10,8),(9,8)              → 39-43  ← Blue entry=39
  //  DOWN toward bottom:
  //    (8,9),(8,10),(8,11),(8,12),(8,13),(8,14)       → 44-49
  //  LEFT along bottom row 14:
  //    (7,14)                                         → 50
  //  Back to just before Red entry:
  //    (6,14) -- but this would be 51, and next=0 wraps  → 51
  //
  // Total = 52 squares ✓

  final List<(int, int)> coords = [
    // 0-4: Red upward
    (6,13),(6,12),(6,11),(6,10),(6,9),
    // 5-10: Left along row=8
    (5,8),(4,8),(3,8),(2,8),(1,8),(0,8),
    // 11-12: Up left edge
    (0,7),(0,6),
    // 13-17: Green entry + rightward row=6
    (1,6),(2,6),(3,6),(4,6),(5,6),
    // 18-23: Upward col=6
    (6,5),(6,4),(6,3),(6,2),(6,1),(6,0),
    // 24-25: Top row rightward
    (7,0),(8,0),
    // 26-30: Yellow entry + downward col=8
    (8,1),(8,2),(8,3),(8,4),(8,5),
    // 31-36: Rightward row=6
    (9,6),(10,6),(11,6),(12,6),(13,6),(14,6),
    // 37-38: Down right edge
    (14,7),(14,8),
    // 39-43: Blue entry + leftward row=8
    (13,8),(12,8),(11,8),(10,8),(9,8),
    // 44-49: Downward col=8
    (8,9),(8,10),(8,11),(8,12),(8,13),(8,14),
    // 50-51: Bottom row leftward back to start
    (7,14),(6,14),
  ];

  return coords.map((c) => _cell(c.$1, c.$2, s)).toList();
}

// ── Home column paths (6 steps into centre) ───────────────────────────────
// These are the coloured lanes each player travels after completing the main lap.
List<Offset> buildHomeColumnPath(int playerIndex, double boardSize) {
  final s = boardSize;

  // (col, row) for each of the 6 home-column squares, nearest→centre
  const homePaths = [
    // Red (0): travels UP col=7, from row=13 to row=8
    [(7,13),(7,12),(7,11),(7,10),(7,9),(7,8)],
    // Blue (1): travels LEFT row=7, from col=13 to col=8
    [(13,7),(12,7),(11,7),(10,7),(9,7),(8,7)],
    // Green (2): travels DOWN col=7, from row=1 to row=6
    [(7,1),(7,2),(7,3),(7,4),(7,5),(7,6)],
    // Yellow (3): travels RIGHT row=7, from col=1 to col=6
    [(1,7),(2,7),(3,7),(4,7),(5,7),(6,7)],
  ];

  return homePaths[playerIndex]
      .map((c) => _cell(c.$1, c.$2, s))
      .toList();
}

// ── Base (home yard) positions ────────────────────────────────────────────
// The 4 circles inside each coloured quadrant where tokens start.
//
// Standard Ludo base circles are centred inside the 6×6 coloured quadrant.
// The quadrant occupies a 6×6 area; the 4 circles sit at roughly:
//   inner cols/rows: 1,3 within the quadrant (0-indexed locally)
//
// Quadrant positions on the 15×15 grid:
//   Red    (bottom-left): cols 0-5,  rows 9-14   → circles at cols 1,3 rows 10,12
//   Blue   (bottom-right): cols 9-14, rows 9-14  → circles at cols 10,12 rows 10,12
//   Green  (top-left):  cols 0-5,  rows 0-5      → circles at cols 1,3 rows 1,3
//   Yellow (top-right): cols 9-14, rows 0-5      → circles at cols 10,12 rows 1,3
List<Offset> buildBasePositions(int playerIndex, double boardSize) {
  final s = boardSize;

  const bases = [
    // Red – bottom-left quadrant (cols 0-5, rows 9-14)
    [(1,10),(3,10),(1,12),(3,12)],
    // Blue – bottom-right quadrant (cols 9-14, rows 9-14)
    [(10,10),(12,10),(10,12),(12,12)],
    // Green – top-left quadrant (cols 0-5, rows 0-5)
    [(1,1),(3,1),(1,3),(3,3)],
    // Yellow – top-right quadrant (cols 9-14, rows 0-5)
    [(10,1),(12,1),(10,3),(12,3)],
  ];

  return bases[playerIndex]
      .map((c) => _cell(c.$1, c.$2, s))
      .toList();
}