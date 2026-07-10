import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame_tiled/flame_tiled.dart';

class RestaurantMap extends PositionComponent {
  static final Vector2 tileSize = Vector2(32, 16);
  static const String _mapFile = 'restaurant_level_1.tmx';
  static const String _mapPrefix = 'assets/images/flame_resources/maps/';
  static const double _pathNodeSize = 16;

  late final TiledComponent tiled;

  final List<Rect> _collisionRects = [];
  final Map<String, Vector2> _spawnPoints = {};

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
  }

  bool isWalkableAt(Vector2 worldPosition) {
    final local = worldPosition - absolutePosition;
    if (local.x < 0 || local.y < 0 || local.x > size.x || local.y > size.y) {
      return false;
    }

    return !_collisionRects.any((rect) {
      return rect.contains(Offset(local.x, local.y));
    });
  }

  Vector2 spawnPoint(String name, {Vector2? fallback}) {
    return (_spawnPoints[name] ?? fallback ?? size / 2) + position;
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
