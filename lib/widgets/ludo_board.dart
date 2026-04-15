import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../logic/game_state.dart';
import '../utils/constants.dart';
import 'token_widget.dart';

// ── Public widget ─────────────────────────────────────────────────────────────

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
          // ── Painted board ─────────────────────────────────────────────────
          CustomPaint(
            size: Size(boardSize, boardSize),
            painter: _LudoBoardPainter(),
          ),

          // ── Tokens ────────────────────────────────────────────────────────
          ..._buildAllTokens(),
        ],
      ),
    );
  }

  List<Widget> _buildAllTokens() {
    final widgets = <Widget>[];
    for (final player in gameState.players) {
      for (final token in player.tokens) {
        final offset = gameState.getTokenOffset(
          token,
          boardSize,
          subIndex: token.tokenIndex,
        );
        final canMove = gameState.canMoveToken(player.index, token.tokenIndex);
        // Token widget is 22×22; offset is the pixel centre, so subtract 11
        widgets.add(
          Positioned(
            left: offset.dx - 11,
            top:  offset.dy - 11,
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

// ── Board painter ─────────────────────────────────────────────────────────────

class _LudoBoardPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final c = s / 15; // one cell size

    // Draw in layers, bottom → top
    _drawBackground(canvas, s, c);
    _drawPathCells(canvas, s, c);
    _drawSafeStars(canvas, s, c);
    _drawHomeColumns(canvas, s, c);
    _drawQuadrants(canvas, s, c);
    _drawGrid(canvas, s, c);
    _drawCentreArrows(canvas, s, c);
    _drawBorder(canvas, s);
  }

  // ── 1. White background ───────────────────────────────────────────────────

  void _drawBackground(Canvas canvas, double s, double c) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, s, s),
      Paint()..color = Colors.white,
    );
  }

  // ── 2. Path cells (the 3-cell-wide track) ────────────────────────────────
  //
  // The outer track occupies:
  //   Vertical strips:   cols 6–8, rows 0–5  and  rows 9–14
  //   Horizontal strips: rows 6–8, cols 0–5  and  cols 9–14
  //
  // Centre 3×3 (cols 6–8, rows 6–8) is the home arrow area.
  //
  // Each cell in the track is light grey; coloured entry/home cells
  // are painted over in later steps.

  void _drawPathCells(Canvas canvas, double s, double c) {
    final trackPaint = Paint()..color = const Color(0xFFEEEEEE);

    // Vertical track segments
    for (int col = 6; col <= 8; col++) {
      // Top vertical (rows 0–5)
      for (int row = 0; row <= 5; row++) {
        _fillCell(canvas, col, row, c, trackPaint);
      }
      // Bottom vertical (rows 9–14)
      for (int row = 9; row <= 14; row++) {
        _fillCell(canvas, col, row, c, trackPaint);
      }
    }
    // Horizontal track segments
    for (int row = 6; row <= 8; row++) {
      // Left horizontal (cols 0–5)
      for (int col = 0; col <= 5; col++) {
        _fillCell(canvas, col, row, c, trackPaint);
      }
      // Right horizontal (cols 9–14)
      for (int col = 9; col <= 14; col++) {
        _fillCell(canvas, col, row, c, trackPaint);
      }
    }

    // Paint the coloured middle lane of each arm
    // Red arm   – col 7, rows 9–13 going up (Red home column)
    final redPaint   = Paint()..color = kPlayerColors[0].withOpacity(0.35);
    final bluePaint  = Paint()..color = kPlayerColors[1].withOpacity(0.35);
    final greenPaint = Paint()..color = kPlayerColors[2].withOpacity(0.35);
    final yellowPaint= Paint()..color = kPlayerColors[3].withOpacity(0.35);

    // Tinted centre lanes (home column background)
    for (int row = 8; row <= 13; row++) _fillCell(canvas, 7, row, c, redPaint);
    for (int col = 8; col <= 13; col++) _fillCell(canvas, col, 7, c, bluePaint);
    for (int row = 1; row <=  6; row++) _fillCell(canvas, 7, row, c, greenPaint);
    for (int col = 1; col <=  6; col++) _fillCell(canvas, col, 7, c, yellowPaint);

    // Coloured entry cells (player colour, full opacity)
    // Red entry (6,13)
    _fillCell(canvas, 6, 13, c, Paint()..color = kPlayerColors[0].withOpacity(0.7));
    // Blue entry (14,8)
    _fillCell(canvas, 14, 8, c, Paint()..color = kPlayerColors[1].withOpacity(0.7));
    // Green entry (1,6)
    _fillCell(canvas, 1,  6, c, Paint()..color = kPlayerColors[2].withOpacity(0.7));
    // Yellow entry (8,0)
    _fillCell(canvas, 8,  0, c, Paint()..color = kPlayerColors[3].withOpacity(0.7));
  }

  // ── 3. Safe stars ─────────────────────────────────────────────────────────

  void _drawSafeStars(Canvas canvas, double s, double c) {
    // Safe squares that are NOT entry squares
    const safeNonEntry = [8, 21, 34, 47];
    final List<(int, int)> mainPathCoords = _mainPathCoords();
    for (final idx in safeNonEntry) {
      final (col, row) = mainPathCoords[idx];
      _drawStar(canvas, col * c + c / 2, row * c + c / 2, c * 0.3);
    }
    // Also draw smaller stars on entry cells
    const entryIdxs = [0, 39, 13, 26];
    for (int i = 0; i < entryIdxs.length; i++) {
      final (col, row) = mainPathCoords[entryIdxs[i]];
      _drawStar(canvas, col * c + c / 2, row * c + c / 2, c * 0.28,
          color: Colors.white.withOpacity(0.8));
    }
  }

  void _drawStar(Canvas canvas, double cx, double cy, double r,
      {Color color = const Color(0xFFFFD700)}) {
    const int points = 5;
    final path = Path();
    final innerR = r * 0.45;
    for (int i = 0; i < points * 2; i++) {
      final angle = (i * math.pi / points) - math.pi / 2;
      final radius = i.isEven ? r : innerR;
      final x = cx + radius * math.cos(angle);
      final y = cy + radius * math.sin(angle);
      if (i == 0) path.moveTo(x, y); else path.lineTo(x, y);
    }
    path.close();
    canvas.drawPath(path, Paint()..color = color);
  }

  // ── 4. Home columns (tinted middle lane) ─────────────────────────────────
  //  Already painted in step 2; this step adds the finish triangle cap.

  void _drawHomeColumns(Canvas canvas, double s, double c) {
    // Nothing extra needed – finish cells are covered by centre arrows.
  }

  // ── 5. Coloured quadrants (home yards) ───────────────────────────────────

  void _drawQuadrants(Canvas canvas, double s, double c) {
    final List<(int, int, int)> quads = [
      // (playerIdx, qx, qy)  – top-left corner of the 6×6 quadrant
      (0,  0,  9), // Red    bottom-left
      (1,  9,  9), // Blue   bottom-right
      (2,  0,  0), // Green  top-left
      (3,  9,  0), // Yellow top-right
    ];

    for (final (idx, qx, qy) in quads) {
      final color = kPlayerColors[idx];

      // Coloured outer background of the 6×6 quadrant
      final bgRect = Rect.fromLTWH(qx * c, qy * c, 6 * c, 6 * c);
      canvas.drawRect(bgRect, Paint()..color = color.withOpacity(0.85));

      // White inner yard (4×4 centred, 1-cell margin each side)
      final yardRect = Rect.fromLTWH(
        (qx + 1) * c, (qy + 1) * c, 4 * c, 4 * c,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(yardRect, Radius.circular(c * 0.25)),
        Paint()..color = Colors.white,
      );

      // Thin coloured border around yard
      canvas.drawRRect(
        RRect.fromRectAndRadius(yardRect, Radius.circular(c * 0.25)),
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }
  }

  // ── 6. Grid lines ─────────────────────────────────────────────────────────

  void _drawGrid(Canvas canvas, double s, double c) {
    final gridPaint = Paint()
      ..color = Colors.black.withOpacity(0.25)
      ..strokeWidth = 0.5;

    // Only draw grid on the track cells, not inside quadrants
    // Draw all lines for simplicity – quadrant coloring above will overlay
    for (int i = 0; i <= 15; i++) {
      canvas.drawLine(Offset(i * c, 0), Offset(i * c, s), gridPaint);
      canvas.drawLine(Offset(0, i * c), Offset(s, i * c), gridPaint);
    }
  }

  // ── 7. Centre home arrows (4 coloured triangles pointing inward) ──────────

  void _drawCentreArrows(Canvas canvas, double s, double c) {
    // The 3×3 centre (cols 6–8, rows 6–8)
    final cx = 7.5 * c; // pixel centre of the 3×3 block
    final cy = 7.5 * c;
    final half = 1.5 * c;

    // Four triangles, one per player, pointing to centre
    final triangles = [
      // Red – bottom triangle pointing UP
      (
      [Offset(cx - half, cy + half), Offset(cx + half, cy + half), Offset(cx, cy)],
      kPlayerColors[0],
      ),
      // Blue – right triangle pointing LEFT
      (
      [Offset(cx + half, cy - half), Offset(cx + half, cy + half), Offset(cx, cy)],
      kPlayerColors[1],
      ),
      // Green – top triangle pointing DOWN
      (
      [Offset(cx - half, cy - half), Offset(cx + half, cy - half), Offset(cx, cy)],
      kPlayerColors[2],
      ),
      // Yellow – left triangle pointing RIGHT
      (
      [Offset(cx - half, cy - half), Offset(cx - half, cy + half), Offset(cx, cy)],
      kPlayerColors[3],
      ),
    ];

    for (final (pts, color) in triangles) {
      final path = Path()
        ..moveTo(pts[0].dx, pts[0].dy)
        ..lineTo(pts[1].dx, pts[1].dy)
        ..lineTo(pts[2].dx, pts[2].dy)
        ..close();
      canvas.drawPath(path, Paint()..color = color);
    }

    // Small white circle at the very centre (finish point)
    canvas.drawCircle(
      Offset(cx, cy),
      c * 0.35,
      Paint()..color = Colors.white,
    );
    canvas.drawCircle(
      Offset(cx, cy),
      c * 0.35,
      Paint()
        ..color = Colors.black26
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  // ── 8. Outer border ───────────────────────────────────────────────────────

  void _drawBorder(Canvas canvas, double s) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, s, s),
      Paint()
        ..color = Colors.black87
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  // ── Helper: fill a single grid cell ──────────────────────────────────────

  void _fillCell(Canvas canvas, int col, int row, double c, Paint paint) {
    canvas.drawRect(
      Rect.fromLTWH(col * c, row * c, c, c),
      paint,
    );
  }

  // ── Helper: main path (col,row) lookup ───────────────────────────────────

  List<(int, int)> _mainPathCoords() => [
    (6,13),(6,12),(6,11),(6,10),(6, 9),
    (5, 8),(4, 8),(3, 8),(2, 8),(1, 8),(0, 8),
    (0, 7),(0, 6),
    (1, 6),(2, 6),(3, 6),(4, 6),(5, 6),(6, 6),
    (6, 5),(6, 4),(6, 3),(6, 2),(6, 1),
    (7, 0),(7, 1),
    (8, 0),(8, 1),(8, 2),(8, 3),(8, 4),(8, 5),
    (9, 6),(10,6),(11,6),(12,6),(13,6),(14,6),
    (14,7),(14,8),
    (13,8),(12,8),(11,8),(10,8),(9, 8),(8, 8),
    (8, 9),(8,10),(8,11),(8,12),(8,13),(8,14),
  ];

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}