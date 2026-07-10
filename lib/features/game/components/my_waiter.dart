import 'dart:convert';

import 'package:flame/components.dart';
import 'package:flutter/services.dart';

enum WaiterState { idle, walking, carryingFood }

class MyWaiter extends SpriteAnimationComponent with HasGameReference {
  static const String _sheetPath = 'flame_sprites/waiter_anim_sheet.png';
  static const String _configPath =
      'assets/images/flame_sprites/waiter_anim_config.json';

  late final Map<WaiterState, SpriteAnimation> _animations;

  Vector2? _targetPosition;
  bool _facingRight = true;
  static const double _speed = 90; // px/秒

  void moveTo(Vector2 target) {
    _targetPosition = target;
    changeState(WaiterState.walking);
  }

  @override
  void update(double dt) {
    super.update(dt);
    final target = _targetPosition;
    if (target == null) return;

    final diff = target - position;
    final distance = diff.length;

    if (distance < 2) {
      position = target;
      _targetPosition = null;
      changeState(WaiterState.idle);
      return;
    }

    final direction = diff / distance;

    // 左右朝向翻转
    if (direction.x.abs() > 0.05) {
      final shouldFaceRight = direction.x > 0;
      if (shouldFaceRight != _facingRight) {
        flipHorizontallyAroundCenter();
        _facingRight = shouldFaceRight;
      }
    }

    final step = direction * _speed * dt;
    position += step.length >= distance ? diff : step;
  }

  WaiterState currentState = WaiterState.idle;

  MyWaiter() : super(position: Vector2(24, 24)) {
    scale = Vector2.all(2);
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    final image = game.images.fromCache(_sheetPath);
    final jsonStr = await rootBundle.loadString(_configPath);
    final config = jsonDecode(jsonStr) as Map<String, dynamic>;
    final cellW = (config['cell_w'] as num).toDouble();
    final cellH = (config['cell_h'] as num).toDouble();
    final cols = config['cols'] as int;
    final animations = config['animations'] as Map<String, dynamic>;
    size = Vector2(cellW, cellH);

    Sprite spriteForFrame(int frameIndex) {
      return Sprite(
        image,
        srcPosition: Vector2(
          (frameIndex % cols) * cellW,
          (frameIndex ~/ cols) * cellH,
        ),
        srcSize: Vector2(cellW, cellH),
      );
    }

    SpriteAnimation buildAnimation(String key, {double stepTime = 0.15}) {
      final indexes = (animations[key] as List<dynamic>).cast<int>();
      return SpriteAnimation.spriteList(
        indexes.map(spriteForFrame).toList(),
        stepTime: stepTime,
        loop: indexes.length > 1,
      );
    }

    _animations = {
      WaiterState.idle: buildAnimation('idle', stepTime: 1),
      WaiterState.walking: buildAnimation('walking'),
      WaiterState.carryingFood: buildAnimation('carryingFood'),
    };

    animation = _animations[currentState];
  }

  void changeState(WaiterState state) {
    if (currentState == state) return;
    currentState = state;
    animation = _animations[state];
    animationTicker?.reset();
  }
}
