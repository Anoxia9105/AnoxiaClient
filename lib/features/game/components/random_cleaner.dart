import 'dart:convert';
import 'dart:math';

import 'package:anoxia/features/game/components/restaurant_map.dart';
import 'package:flame/components.dart';
import 'package:flutter/services.dart';

/// 营业期间随机巡视房间的保洁。
class RandomCleaner extends SpriteAnimationComponent with HasGameReference {
  RandomCleaner({required this.map, required Vector2 position})
    : super(position: position, anchor: Anchor.bottomCenter);

  final RestaurantMap map;
  final _random = Random();
  final _path = <Vector2>[];
  late SpriteAnimation _idle;
  late SpriteAnimation _walking;
  Vector2? _target;
  double _waitTimer = 1;
  bool enabled = false;
  bool _moving = false;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    final config =
        jsonDecode(
              await rootBundle.loadString(
                'assets/images/flame_sprites/cleaner_anim_config.json',
              ),
            )
            as Map<String, dynamic>;
    final width = (config['cell_w'] as num).toDouble();
    final height = (config['cell_h'] as num).toDouble();
    final columns = config['cols'] as int;
    final animations = config['animations'] as Map<String, dynamic>;
    final image = game.images.fromCache(config['sheet_path'] as String);
    size = Vector2(width, height);
    Sprite frame(int index) => Sprite(
      image,
      srcPosition: Vector2(
        (index % columns) * width,
        (index ~/ columns) * height,
      ),
      srcSize: Vector2(width, height),
    );
    SpriteAnimation build(String key) {
      final indexes = (animations[key] as List).cast<int>();
      return SpriteAnimation.spriteList(
        indexes.map(frame).toList(),
        stepTime: .18,
        loop: indexes.length > 1,
      );
    }

    _idle = build('idle');
    _walking = build('walking');
    animation = _idle;
  }

  @override
  void update(double dt) {
    super.update(dt);
    priority = position.y.round();
    if (!enabled) {
      _setMoving(false);
      return;
    }
    final target = _target;
    if (target == null) {
      _waitTimer -= dt;
      if (_waitTimer <= 0) _choosePatrolPoint();
      return;
    }
    final difference = target - position;
    if (difference.length < 2) {
      position = target;
      _target = _path.isEmpty ? null : _path.removeAt(0);
      if (_target == null) {
        _waitTimer = 1.5 + _random.nextDouble() * 2.5;
        _setMoving(false);
      }
      return;
    }
    final movement = difference.normalized() * 48 * dt;
    position += movement.length >= difference.length ? difference : movement;
  }

  void _choosePatrolPoint() {
    for (var attempt = 0; attempt < 20; attempt++) {
      final candidate =
          map.position +
          Vector2(
            _random.nextDouble() * map.visualSize.x,
            _random.nextDouble() * map.visualSize.y,
          );
      if (!map.isWalkableAt(candidate)) continue;
      final nextPath = map.findPath(position, candidate);
      if (nextPath.isEmpty) continue;
      _path
        ..clear()
        ..addAll(nextPath);
      _target = _path.removeAt(0);
      _setMoving(true);
      return;
    }
    _waitTimer = 1;
  }

  void _setMoving(bool value) {
    if (_moving == value) return;
    _moving = value;
    animation = value ? _walking : _idle;
    animationTicker?.reset();
  }
}
