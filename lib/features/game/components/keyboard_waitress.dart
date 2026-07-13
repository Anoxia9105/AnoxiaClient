import 'dart:convert';

import 'package:anoxia/features/game/components/restaurant_map.dart';
import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// 键盘控制的女服务员测试角色。
///
/// 用于验证地图碰撞检测、人物深度排序（等距 Y 轴排序）以及行走动画。
/// 可使用 WASD 或方向键控制移动。该组件不参与实际的点餐业务流程，
/// 仅供开发调试使用，可以随时删除或通过开关禁用。
class KeyboardWaitress extends SpriteAnimationComponent with HasGameReference {
  KeyboardWaitress({required this.map, required Vector2 position})
      : super(position: position, anchor: Anchor.bottomCenter);

  // ---------- 常量 ----------
  static const _configPath =
      'assets/images/flame_sprites/womanwaiter_anim_config.json';
  static const _moveSpeed = 90.0;      // 移动速度（像素/秒）
  static const _footRadius = 5.0;      // 碰撞检测点的半径（用于四点检测）

  // ---------- 外部依赖 ----------
  final RestaurantMap map;             // 地图引用，用于碰撞检测

  // ---------- 动画 ----------
  late final SpriteAnimation _idleAnimation;
  late final SpriteAnimation _walkingAnimation;

  // ---------- 状态 ----------
  bool _walking = false;               // 是否正在行走（用于切换动画）
  bool _facingRight = true;            // 是否面朝右（用于水平翻转）

  // ---------- 生命周期 ----------
  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // 加载女服务员的动画配置
    final config =
    jsonDecode(await rootBundle.loadString(_configPath))
    as Map<String, dynamic>;
    final cellWidth = (config['cell_w'] as num).toDouble();
    final cellHeight = (config['cell_h'] as num).toDouble();
    final columns = config['cols'] as int;
    final animations = config['animations'] as Map<String, dynamic>;
    final image = game.images.fromCache(config['sheet_path'] as String);

    size = Vector2(cellWidth, cellHeight);

    // 辅助函数：根据帧索引创建 Sprite
    Sprite spriteFor(int frame) => Sprite(
      image,
      srcPosition: Vector2(
        (frame % columns) * cellWidth,
        (frame ~/ columns) * cellHeight,
      ),
      srcSize: Vector2(cellWidth, cellHeight),
    );

    // 辅助函数：构建指定名称的动画
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

  // ---------- 更新循环 ----------
  @override
  void update(double dt) {
    super.update(dt);
    // 等距深度排序：根据 Y 坐标设置绘制优先级
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

  // ---------- 键盘输入读取 ----------
  /// 读取 WASD / 方向键的输入，返回归一化的移动向量（未归一化）
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

  // ---------- 碰撞处理 ----------
  /// 分别沿 X 轴和 Y 轴尝试移动，实现“沿墙滑动”效果。
  /// 先尝试水平移动，再尝试垂直移动，这样撞墙时仍能沿墙滑动。
  void _moveWithCollision(Vector2 movement) {
    // 尝试 X 方向移动
    final nextX = position + Vector2(movement.x, 0);
    if (_canStandAt(nextX)) position.x = nextX.x;

    // 尝试 Y 方向移动
    final nextY = position + Vector2(0, movement.y);
    if (_canStandAt(nextY)) position.y = nextY.y;
  }

  /// 判断角色是否能在目标位置站立。
  /// 以脚底为中心，检测周围五个点（中心 + 上下左右），
  /// 确保角色不会与障碍物穿插。
  bool _canStandAt(Vector2 target) {
    return map.isWalkableAt(target) &&
        map.isWalkableAt(target + Vector2(_footRadius, 0)) &&
        map.isWalkableAt(target + Vector2(-_footRadius, 0)) &&
        map.isWalkableAt(target + Vector2(0, _footRadius)) &&
        map.isWalkableAt(target + Vector2(0, -_footRadius));
  }

  // ---------- 动画与朝向控制 ----------
  /// 设置行走状态（行走/空闲），并切换对应动画
  void _setWalking(bool value) {
    if (_walking == value) return;
    _walking = value;
    animation = value ? _walkingAnimation : _idleAnimation;
    animationTicker?.reset();
  }

  /// 根据水平移动方向更新角色朝向（左右翻转）
  void _updateFacing(double horizontalDirection) {
    if (horizontalDirection.abs() < .05) return;
    final faceRight = horizontalDirection > 0;
    if (faceRight == _facingRight) return;
    flipHorizontallyAroundCenter();
    _facingRight = faceRight;
  }
}