import 'dart:convert';

import 'package:anoxia/features/game/components/restaurant_map.dart';
import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// 用于验证地图碰撞、人物层级和行走动画的键盘测试角色。
///
/// WASD 和方向键都可以移动。这个组件不参与点餐业务，可以随时删除或关闭。
class KeyboardWaitress extends SpriteAnimationComponent with HasGameReference {
  KeyboardWaitress({required this.map, required Vector2 position})
    : super(position: position, anchor: Anchor.bottomCenter);

  static const _configPath =
      'assets/images/flame_sprites/womanwaiter_anim_config.json';
  static const _moveSpeed = 90.0;
  static const _footRadius = 5.0;

  final RestaurantMap map;
  late final SpriteAnimation _idleAnimation;
  late final SpriteAnimation _walkingAnimation;
  bool _walking = false;
  bool _facingRight = true;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    final config =
        jsonDecode(await rootBundle.loadString(_configPath))
            as Map<String, dynamic>;
    final cellWidth = (config['cell_w'] as num).toDouble();
    final cellHeight = (config['cell_h'] as num).toDouble();
    final columns = config['cols'] as int;
    final animations = config['animations'] as Map<String, dynamic>;
    final image = game.images.fromCache(config['sheet_path'] as String);

    size = Vector2(cellWidth, cellHeight);

    Sprite spriteFor(int frame) => Sprite(
      image,
      srcPosition: Vector2(
        (frame % columns) * cellWidth,
        (frame ~/ columns) * cellHeight,
      ),
      srcSize: Vector2(cellWidth, cellHeight),
    );

    SpriteAnimation build(String name, double stepTime) {
      final frames = (animations[name] as List<dynamic>).cast<int>();
      return SpriteAnimation.spriteList(
        frames.map(spriteFor).toList(),
        stepTime: stepTime,
        loop: frames.length > 1,
      );
    }

    _idleAnimation = build('idle', 1);
    _walkingAnimation = build('walking', .14);
    animation = _idleAnimation;
    debugPrint('[键盘女服务员] 已创建：WASD/方向键移动，坐标=$position');
  }

  @override
  void update(double dt) {
    super.update(dt);
    priority = position.y.round();
    if (!isLoaded) return;

    final direction = _readDirection();
    if (direction.isZero()) {
      _setWalking(false);
      return;
    }

    direction.normalize();
    _setWalking(true);
    _updateFacing(direction.x);
    _moveWithCollision(direction * _moveSpeed * dt);
  }

  Vector2 _readDirection() {
    final keys = HardwareKeyboard.instance.logicalKeysPressed;
    var x = 0.0;
    var y = 0.0;
    if (keys.contains(LogicalKeyboardKey.keyA) ||
        keys.contains(LogicalKeyboardKey.arrowLeft)) {
      x--;
    }
    if (keys.contains(LogicalKeyboardKey.keyD) ||
        keys.contains(LogicalKeyboardKey.arrowRight)) {
      x++;
    }
    if (keys.contains(LogicalKeyboardKey.keyW) ||
        keys.contains(LogicalKeyboardKey.arrowUp)) {
      y--;
    }
    if (keys.contains(LogicalKeyboardKey.keyS) ||
        keys.contains(LogicalKeyboardKey.arrowDown)) {
      y++;
    }
    return Vector2(x, y);
  }

  /// X/Y 分开检测，撞到一个方向后仍可沿家具或墙体边缘滑动。
  void _moveWithCollision(Vector2 movement) {
    final nextX = position + Vector2(movement.x, 0);
    if (_canStandAt(nextX)) position.x = nextX.x;

    final nextY = position + Vector2(0, movement.y);
    if (_canStandAt(nextY)) position.y = nextY.y;
  }

  /// 角色以脚底为碰撞点；四点检测避免身体中心能贴进障碍边缘。
  bool _canStandAt(Vector2 target) {
    return map.isWalkableAt(target) &&
        map.isWalkableAt(target + Vector2(_footRadius, 0)) &&
        map.isWalkableAt(target + Vector2(-_footRadius, 0)) &&
        map.isWalkableAt(target + Vector2(0, _footRadius)) &&
        map.isWalkableAt(target + Vector2(0, -_footRadius));
  }

  void _setWalking(bool value) {
    if (_walking == value) return;
    _walking = value;
    animation = value ? _walkingAnimation : _idleAnimation;
    animationTicker?.reset();
  }

  void _updateFacing(double horizontalDirection) {
    if (horizontalDirection.abs() < .05) return;
    final faceRight = horizontalDirection > 0;
    if (faceRight == _facingRight) return;
    flipHorizontallyAroundCenter();
    _facingRight = faceRight;
  }
}
