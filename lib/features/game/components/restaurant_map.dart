import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:flutter/foundation.dart';

class RestaurantMap extends PositionComponent {
  static final Vector2 tileSize = Vector2(32, 16);
  static const String _mapFile = 'restaurant_level_1.tmx';
  static const String _mapPrefix = 'assets/images/flame_resources/maps/';
  static const double _pathNodeSize = 16;

  late final TiledComponent tiled;

  final List<Rect> _collisionRects = [];
  final List<Rect> _dynamicCollisionRects = [];
  final Map<String, Vector2> _spawnPoints = {};
  DateTime? _lastCollisionLogAt;

  Vector2 get visualSize {
    final map = tiled.tileMap.map;
    return Vector2(
      (map.width + map.height) * tileSize.x / 2,
      (map.width + map.height) * tileSize.y / 2,
    );
  }

  Vector2 get visualCenter => position + visualSize / 2;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    tiled = await TiledComponent.load(_mapFile, tileSize, prefix: _mapPrefix);
    await add(tiled);
    size = tiled.size;

    _loadCollisionRects();
    _loadSpawnPoints();
    debugPrint(
      '[RestaurantMap] debug=$debugMode, collisions=${_collisionRects.length}, '
      'spawns=${_spawnPoints.keys.join(', ')}',
    );
  }

  bool isWalkableAt(Vector2 worldPosition) {
    final local = worldPosition - absolutePosition;
    if (local.x < 0 || local.y < 0 || local.x > size.x || local.y > size.y) {
      return false;
    }

    final objectPosition = _screenToObject(local);
    if (_dynamicCollisionRects.any(
      (rect) => rect.contains(Offset(local.x, local.y)),
    )) {
      return false;
    }
    for (var index = 0; index < _collisionRects.length; index++) {
      final rect = _collisionRects[index];
      if (!rect.contains(Offset(objectPosition.x, objectPosition.y))) continue;

      final now = DateTime.now();
      if (_lastCollisionLogAt == null ||
          now.difference(_lastCollisionLogAt!).inMilliseconds >= 500) {
        _lastCollisionLogAt = now;
        debugPrint(
          '[RestaurantMap] COLLISION #$index screen=$local '
          'object=$objectPosition rect=$rect',
        );
      }
      return false;
    }
    return true;
  }

  Vector2 spawnPoint(String name, {Vector2? fallback}) {
    final objectPosition = _spawnPoints[name];
    if (objectPosition != null) {
      return _objectToScreen(objectPosition) + position;
    }
    return (fallback ?? size / 2) + position;
  }

  void setDynamicObstacles(List<Rect> obstacles) {
    _dynamicCollisionRects
      ..clear()
      ..addAll(obstacles);
  }

  /// Tiled stores object-layer coordinates for isometric maps in its
  /// unprojected coordinate plane. Flame renders tiles in screen space, so
  /// spawn points and collision shapes must use the same projection.
  Vector2 _objectToScreen(Vector2 point) {
    final scale = tileSize.x / tileSize.y;
    return Vector2(
      (point.x - point.y) * scale / 2 +
          tiled.tileMap.map.height * tileSize.x / 2,
      (point.x + point.y) / 2,
    );
  }

  Vector2 _screenToObject(Vector2 point) {
    final shiftedX = point.x - tiled.tileMap.map.height * tileSize.x / 2;
    final scale = tileSize.x / tileSize.y;
    return Vector2(point.y + shiftedX / scale, point.y - shiftedX / scale);
  }

  List<Vector2> findPath(Vector2 worldStart, Vector2 worldTarget) {
    final start = _nodeForWorldPosition(worldStart);
    final target = _nodeForWorldPosition(worldTarget);

    if (!_isWalkableNode(target)) return const [];
    if (start == target) return [worldTarget.clone()];

    final open = <_PathNode>[start];
    final cameFrom = <_PathNode, _PathNode>{};
    final gScore = <_PathNode, double>{start: 0};
    final fScore = <_PathNode, double>{start: _heuristic(start, target)};
    final closed = <_PathNode>{};

    while (open.isNotEmpty) {
      open.sort((a, b) {
        return (fScore[a] ?? double.infinity).compareTo(
          fScore[b] ?? double.infinity,
        );
      });

      final current = open.removeAt(0);
      if (current == target) {
        return _rebuildPath(cameFrom, current, worldTarget);
      }

      closed.add(current);

      for (final neighbor in _neighbors(current)) {
        if (closed.contains(neighbor) || !_isWalkableNode(neighbor)) continue;

        final moveCost = neighbor.x == current.x || neighbor.y == current.y
            ? 1.0
            : 1.414;
        final tentativeG = (gScore[current] ?? double.infinity) + moveCost;
        if (tentativeG >= (gScore[neighbor] ?? double.infinity)) continue;

        cameFrom[neighbor] = current;
        gScore[neighbor] = tentativeG;
        fScore[neighbor] = tentativeG + _heuristic(neighbor, target);
        if (!open.contains(neighbor)) {
          open.add(neighbor);
        }
      }
    }

    return const [];
  }

  _PathNode _nodeForWorldPosition(Vector2 worldPosition) {
    final local = worldPosition - absolutePosition;
    return _PathNode(
      (local.x / _pathNodeSize).floor(),
      (local.y / _pathNodeSize).floor(),
    );
  }

  Vector2 _worldPositionForNode(_PathNode node) {
    return Vector2(
          node.x * _pathNodeSize + _pathNodeSize / 2,
          node.y * _pathNodeSize + _pathNodeSize / 2,
        ) +
        position;
  }

  bool _isWalkableNode(_PathNode node) {
    return isWalkableAt(_worldPositionForNode(node));
  }

  Iterable<_PathNode> _neighbors(_PathNode node) sync* {
    for (var y = -1; y <= 1; y++) {
      for (var x = -1; x <= 1; x++) {
        if (x == 0 && y == 0) continue;
        yield _PathNode(node.x + x, node.y + y);
      }
    }
  }

  double _heuristic(_PathNode a, _PathNode b) {
    final dx = (a.x - b.x).abs();
    final dy = (a.y - b.y).abs();
    return dx > dy ? dx.toDouble() : dy.toDouble();
  }

  List<Vector2> _rebuildPath(
    Map<_PathNode, _PathNode> cameFrom,
    _PathNode current,
    Vector2 worldTarget,
  ) {
    final nodes = <_PathNode>[current];
    while (cameFrom.containsKey(current)) {
      current = cameFrom[current]!;
      nodes.add(current);
    }

    final points = nodes.reversed.map(_worldPositionForNode).toList();
    if (points.isNotEmpty) {
      points
        ..removeAt(0)
        ..add(worldTarget.clone());
    }
    return points;
  }

  void _loadCollisionRects() {
    final collisionLayer = tiled.tileMap.getLayer<ObjectGroup>('collision');
    if (collisionLayer == null) return;

    for (final object in collisionLayer.objects) {
      if (object.width <= 0 || object.height <= 0) continue;
      _collisionRects.add(
        Rect.fromLTWH(object.x, object.y, object.width, object.height),
      );
    }
  }

  void _loadSpawnPoints() {
    final spawnLayer = tiled.tileMap.getLayer<ObjectGroup>('spawn');
    if (spawnLayer == null) return;

    for (final object in spawnLayer.objects) {
      if (object.name.isEmpty) continue;
      _spawnPoints[object.name] = Vector2(object.x, object.y);
      debugPrint(
        '[RestaurantMap] SPAWN ${object.name}: object='
        '(${object.x}, ${object.y}) screen='
        '${_objectToScreen(Vector2(object.x, object.y))}',
      );
    }
  }

  @override
  void renderDebugMode(Canvas canvas) {
    super.renderDebugMode(canvas);

    final collisionFill = Paint()
      ..color = const Color(0x55FF1744)
      ..style = PaintingStyle.fill;
    final collisionLine = Paint()
      ..color = const Color(0xFFFF1744)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    for (final rect in _collisionRects) {
      final points = [
        _objectToScreen(Vector2(rect.left, rect.top)),
        _objectToScreen(Vector2(rect.right, rect.top)),
        _objectToScreen(Vector2(rect.right, rect.bottom)),
        _objectToScreen(Vector2(rect.left, rect.bottom)),
      ];
      final path = Path()..moveTo(points.first.x, points.first.y);
      for (final point in points.skip(1)) {
        path.lineTo(point.x, point.y);
      }
      path.close();
      canvas
        ..drawPath(path, collisionFill)
        ..drawPath(path, collisionLine);
    }
    final dynamicPaint = Paint()
      ..color = const Color(0x559C27B0)
      ..style = PaintingStyle.fill;
    for (final rect in _dynamicCollisionRects) {
      canvas.drawRect(rect, dynamicPaint);
    }

    final spawnPaint = Paint()
      ..color = const Color(0xFF00E676)
      ..strokeWidth = 2;
    for (final entry in _spawnPoints.entries) {
      final point = _objectToScreen(entry.value);
      canvas
        ..drawCircle(Offset(point.x, point.y), 5, spawnPaint)
        ..drawLine(
          Offset(point.x - 8, point.y),
          Offset(point.x + 8, point.y),
          spawnPaint,
        )
        ..drawLine(
          Offset(point.x, point.y - 8),
          Offset(point.x, point.y + 8),
          spawnPaint,
        );
    }
  }
}

class _PathNode {
  const _PathNode(this.x, this.y);

  final int x;
  final int y;

  @override
  bool operator ==(Object other) {
    return other is _PathNode && x == other.x && y == other.y;
  }

  @override
  int get hashCode => Object.hash(x, y);
}
