import 'dart:convert';
import 'dart:math';

import 'package:anoxia/features/game/components/restaurant_map.dart';
import 'package:flame/components.dart';
import 'package:flutter/services.dart';

/// 营业期间随机巡视房间的保洁人员。
/// 继承自 [SpriteAnimationComponent]，拥有空闲和行走两种动画状态。
/// 利用地图的路径查找功能在可通行区域内随机选择目标点进行巡逻。
class RandomCleaner extends SpriteAnimationComponent with HasGameReference {
  RandomCleaner({required this.map, required Vector2 position})
      : super(position: position, anchor: Anchor.bottomCenter);

  // ---------- 外部依赖 ----------
  final RestaurantMap map; // 地图引用，用于碰撞检测和路径查找

  // ---------- 内部状态 ----------
  final _random = Random();          // 随机数生成器
  final _path = <Vector2>[];         // 当前巡逻路径点列表
  late SpriteAnimation _idle;        // 空闲动画
  late SpriteAnimation _walking;     // 行走动画
  Vector2? _target;                 // 当前移动目标点
  double _waitTimer = 1;            // 等待计时器（秒），用于两次巡逻之间的停留
  bool enabled = false;             // 是否启用巡逻（营业时开启）
  bool _moving = false;             // 是否正在行走（用于切换动画）

  // ---------- 生命周期 ----------
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    // 加载清洁工的动画配置
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

    // 辅助函数：根据帧索引创建 Sprite
    Sprite frame(int index) => Sprite(
      image,
      srcPosition: Vector2(
        (index % columns) * width,
        (index ~/ columns) * height,
      ),
      srcSize: Vector2(width, height),
    );

    // 辅助函数：从配置中构建指定名称的动画
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
    animation = _idle; // 初始为空闲状态
  }

  // ---------- 更新循环 ----------
  @override
  void update(double dt) {
    super.update(dt);
    // 等距深度排序
    priority = position.y.round();

    // 未启用时停止行走并保持空闲
    if (!enabled) {
      _setMoving(false);
      return;
    }

    final target = _target;
    if (target == null) {
      // 没有目标时，等待一段时间后选择新的巡逻点
      _waitTimer -= dt;
      if (_waitTimer <= 0) _choosePatrolPoint();
      return;
    }

    // 向目标移动
    final difference = target - position;
    if (difference.length < 2) {
      // 到达目标，尝试取路径中的下一个点
      position = target;
      _target = _path.isEmpty ? null : _path.removeAt(0);
      if (_target == null) {
        // 路径走完，进入等待
        _waitTimer = 1.5 + _random.nextDouble() * 2.5;
        _setMoving(false);
      }
      return;
    }

    // 移动速度 48 像素/秒
    final movement = difference.normalized() * 48 * dt;
    position += movement.length >= difference.length ? difference : movement;
  }

  // ---------- 巡逻逻辑 ----------
  /// 随机选择一个可到达的巡逻点，并计算路径
  void _choosePatrolPoint() {
    for (var attempt = 0; attempt < 20; attempt++) {
      // 在地图视觉范围内随机生成候选点
      final candidate =
          map.position +
              Vector2(
                _random.nextDouble() * map.visualSize.x,
                _random.nextDouble() * map.visualSize.y,
              );
      // 检查该点是否可行走（不碰撞）
      if (!map.isWalkableAt(candidate)) continue;
      // 计算从当前位置到候选点的路径
      final nextPath = map.findPath(position, candidate);
      if (nextPath.isEmpty) continue;
      // 路径有效，设置路径并开始移动
      _path
        ..clear()
        ..addAll(nextPath);
      _target = _path.removeAt(0);
      _setMoving(true);
      return;
    }
    // 多次尝试失败，短暂等待后重试
    _waitTimer = 1;
  }

  /// 切换行走/空闲状态，并更新动画
  void _setMoving(bool value) {
    if (_moving == value) return;
    _moving = value;
    animation = value ? _walking : _idle;
    // 重置动画时钟，避免从中间开始
    animationTicker?.reset();
  }
}