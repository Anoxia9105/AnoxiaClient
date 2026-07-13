import 'dart:convert';

import 'package:flame/components.dart';
import 'package:flutter/services.dart';

/// 服务员状态枚举
enum WaiterState { idle, walking, carryingFood }

/// 餐厅服务员组件。
/// 继承自 [SpriteAnimationComponent]，支持路径跟随、朝向翻转、空闲/行走/搬运动画切换。
/// 作为餐厅的核心角色，执行点单、上菜、清洁等任务。
class MyWaiter extends SpriteAnimationComponent with HasGameReference {
  // ---------- 常量 ----------
  static const String _sheetPath = 'flame_sprites/waiter_anim_sheet.png';
  static const String _configPath =
      'assets/images/flame_sprites/waiter_anim_config.json';
  static const double _speed = 90; // 移动速度（像素/秒）

  // ---------- 动画 ----------
  late final Map<WaiterState, SpriteAnimation> _animations; // 各状态对应的动画

  // ---------- 路径与移动 ----------
  final List<Vector2> _path = [];    // 待行走的路径点列表
  Vector2? _targetPosition;          // 当前目标点
  bool _facingRight = true;          // 是否面朝右（用于翻转）
  WaiterState _movingState = WaiterState.walking; // 移动时使用的状态（行走或搬运）

  // ---------- 当前状态 ----------
  WaiterState currentState = WaiterState.idle;

  /// 是否正在移动（有目标点或路径）
  bool get isMoving => _targetPosition != null || _path.isNotEmpty;

  MyWaiter() : super(position: Vector2(24, 24), anchor: Anchor.bottomCenter) {
    scale = Vector2.all(1);
  }

  // ---------- 移动控制 ----------
  /// 直接移动至目标点（不使用路径查找，通常由外部计算路径后调用 [followPath]）
  void moveTo(Vector2 target) {
    _path.clear();
    _targetPosition = target;
    changeState(WaiterState.walking);
  }

  /// 沿指定路径移动，可指定移动状态（行走或搬运）
  void followPath(
      List<Vector2> path, {
        WaiterState movingState = WaiterState.walking,
      }) {
    _movingState = movingState;
    _path
      ..clear()
      ..addAll(path.map((point) => point.clone()));
    _advancePath();
  }

  /// 停止移动，进入空闲状态
  void stop() {
    _path.clear();
    _targetPosition = null;
    changeState(WaiterState.idle);
  }

  // ---------- 生命周期 ----------
  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // 加载精灵表图片和配置文件
    final image = game.images.fromCache(_sheetPath);
    final jsonStr = await rootBundle.loadString(_configPath);
    final config = jsonDecode(jsonStr) as Map<String, dynamic>;
    final cellW = (config['cell_w'] as num).toDouble();
    final cellH = (config['cell_h'] as num).toDouble();
    final cols = config['cols'] as int;
    final animations = config['animations'] as Map<String, dynamic>;
    size = Vector2(cellW, cellH);

    // 辅助函数：根据帧索引创建 Sprite
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

    // 辅助函数：构建动画
    SpriteAnimation buildAnimation(String key, {double stepTime = 0.15}) {
      final indexes = (animations[key] as List<dynamic>).cast<int>();
      return SpriteAnimation.spriteList(
        indexes.map(spriteForFrame).toList(),
        stepTime: stepTime,
        loop: indexes.length > 1,
      );
    }

    // 初始化所有状态动画
    _animations = {
      WaiterState.idle: buildAnimation('idle', stepTime: 1),
      WaiterState.walking: buildAnimation('walking'),
      WaiterState.carryingFood: buildAnimation('carryingFood'),
    };

    animation = _animations[currentState];
  }

  // ---------- 更新循环 ----------
  @override
  void update(double dt) {
    super.update(dt);
    // 等距地图深度排序，基于 Y 坐标
    priority = position.y.round();

    final target = _targetPosition;
    if (target == null) return;

    // 计算移动
    final diff = target - position;
    final distance = diff.length;

    if (distance < 2) {
      // 到达目标，尝试下一个路径点
      position = target;
      _targetPosition = null;
      _advancePath();
      return;
    }

    final direction = diff / distance;
    // 根据水平移动方向翻转角色
    if (direction.x.abs() > 0.05) {
      final shouldFaceRight = direction.x > 0;
      if (shouldFaceRight != _facingRight) {
        flipHorizontallyAroundCenter();
        _facingRight = shouldFaceRight;
      }
    }

    // 移动步长
    final step = direction * _speed * dt;
    position += step.length >= distance ? diff : step;
  }

  // ---------- 状态切换 ----------
  /// 切换到指定状态并更新动画
  void changeState(WaiterState state) {
    if (currentState == state) return;
    currentState = state;
    animation = _animations[state];
    animationTicker?.reset();
  }

  // ---------- 路径推进 ----------
  /// 从路径列表中取出下一个目标点
  void _advancePath() {
    if (_path.isEmpty) {
      _targetPosition = null;
      changeState(WaiterState.idle);
      return;
    }

    _targetPosition = _path.removeAt(0);
    changeState(_movingState);
  }
}