import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class RestaurantMap extends PositionComponent {
  static const double cellSize = 32;

  // 0 = 可走, 1 = 墙/障碍(桌子、吧台之类先用这个占位)
  static const List<String> _layout = [
    '111111111111',
    '100000000001',
    '100110000101',
    '100110000101',
    '100000000001',
    '100000011001',
    '111111111111',
  ];

  late final int cols;
  late final int rows;

  RestaurantMap() {
    rows = _layout.length;
    cols = _layout[0].length;
    size = Vector2(cols * cellSize, rows * cellSize);
  }

  bool isWalkable(int col, int row) {
    if (row < 0 || row >= rows || col < 0 || col >= cols) return false;
    return _layout[row][col] == '0';
  }

  Vector2 gridToWorld(int col, int row) {
    return Vector2(
      col * cellSize + cellSize / 2,
      row * cellSize + cellSize / 2,
    );
  }

  @override
  void render(Canvas canvas) {
    final paint = Paint();
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        paint.color = _layout[r][c] == '1'
            ? const Color(0xFF8D6E63) // 墙
            : const Color(0xFFF5F0E6); // 地板
        canvas.drawRect(
          Rect.fromLTWH(c * cellSize, r * cellSize, cellSize, cellSize),
          paint,
        );
      }
    }
  }
}