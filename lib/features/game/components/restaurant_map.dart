import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame_tiled/flame_tiled.dart';

class RestaurantMap extends PositionComponent {
  static final Vector2 tileSize = Vector2(32, 16);
  static const String _mapFile = 'restaurant_level_1.tmx';
  static const String _mapPrefix = 'assets/images/flame_resources/maps/';

  late final TiledComponent tiled;

  final List<Rect> _collisionRects = [];
  final Map<String, Vector2> _spawnPoints = {};

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
