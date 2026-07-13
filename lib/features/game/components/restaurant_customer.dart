import 'dart:convert';

import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// 顾客状态枚举，描述顾客从进入餐厅到离店的完整流程
enum CustomerState {
  entering,           // 正在进入餐厅，走向座位
  waitingForTable,    // 等待分配空桌
  seated,             // 已就坐，等待点单
  waiting,            // 等待食物（已点单，正在等餐）
  eating,             // 正在用餐
  queueing,           // 排队结账（走向收银台或排队中）
  paying,             // 正在结账
  leaving,            // 离开餐厅
}

/// 餐厅顾客组件。
/// 基于 `SpriteAnimationComponent`，支持路径跟随、状态切换和表情图标显示。
/// 顾客拥有独立的动画（站立/就坐）和情绪图标（满意/等待/失望）。
class RestaurantCustomer extends SpriteAnimationComponent
    with HasGameReference {
  RestaurantCustomer({
    required this.customerId,
    required this.characterName,
    required Vector2 position,
  }) : super(position: position, anchor: Anchor.bottomCenter);

  // ---------- 常量 ----------
  static const _speed = 72.0; // 移动速度（像素/秒）

  // ---------- 外部字段 ----------
  final int customerId;          // 顾客唯一编号
  final String characterName;    // 角色名称（对应配置文件和精灵表）

  // ---------- 路径跟随 ----------
  final List<Vector2> _path = []; // 待行走的路径点列表
  Vector2? _target;               // 当前目标点
  bool _facingRight = true;       // 是否面朝右（用于翻转）

  // ---------- 动画与UI ----------
  late final SpriteAnimation _standingAnimation; // 站立动画（单帧）
  late final SpriteAnimation _seatedAnimation;   // 就坐动画（单帧，正面坐姿）
  late final SpriteComponent _moodIcon;          // 表情图标（头上方的气泡）

  // ---------- 状态 ----------
  CustomerState state = CustomerState.entering;

  /// 是否正在移动（有目标点或路径）
  bool get isMoving => _target != null || _path.isNotEmpty;

  // ---------- 生命周期 ----------
  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // 加载顾客配置文件（JSON 元数据）
    final config =
    jsonDecode(
      await rootBundle.loadString(
        'assets/images/flame_resources/customers/$characterName.json',
      ),
    )
    as Map<String, dynamic>;
    final cellW = (config['cell_w'] as num).toDouble(); // 单帧宽度
    final cellH = (config['cell_h'] as num).toDouble(); // 单帧高度
    final cols = config['cols'] as int;                // 精灵表列数
    final animations = config['animations'] as Map<String, dynamic>;

    // 获取站立和就坐的帧索引列表
    final standingFrames = (animations['standing'] as List).cast<int>();
    // 因为等距地图的桌子使用垂直朝向，顾客必须使用正面就坐帧，而不是侧身帧。
    final seatedFrames = (animations['seatedFront'] as List).cast<int>();

    // 加载精灵表图片
    final image = await game.images.load(config['sheet_path'] as String);
    size = Vector2(cellW, cellH);

    // 辅助函数：从精灵表创建指定帧的 Sprite
    Sprite frameSprite(int frame) => Sprite(
      image,
      srcPosition: Vector2((frame % cols) * cellW, (frame ~/ cols) * cellH),
      srcSize: Vector2(cellW, cellH),
    );

    // 站立动画（仅使用第一帧，静态）
    _standingAnimation = SpriteAnimation.spriteList(
      [frameSprite(standingFrames.first)],
      stepTime: 1,
      loop: false,
    );

    // 就坐动画（使用 seatedFrames 的最后一帧）。
    // 原因：第一帧包含一个分离的脚（原本由 J2ME 渲染器合成），
    // 而最后一帧是干净、完整的近坐姿（适合我们的预合成精灵表）。
    _seatedAnimation = SpriteAnimation.spriteList(
      [frameSprite(seatedFrames.last)],
      stepTime: 1,
      loop: false,
    );

    // 默认使用站立动画
    animation = _standingAnimation;

    // ---------- 加载表情图标（情绪气泡） ----------
    final moodSheet = await game.images.load('flame_resources/raw/lian.png');
    _moodIcon = SpriteComponent(
      sprite: Sprite(
        moodSheet,
        srcPosition: Vector2.zero(),
        srcSize: Vector2(12, 12),
      ),
      size: Vector2(12, 12),
      position: Vector2(size.x / 2, -7), // 显示在角色头部上方
      anchor: Anchor.center,
      priority: 10, // 确保表情在角色之上
    );
    await add(_moodIcon);

    debugPrint('[Restaurant] customer#$customerId ($characterName) spawned');
  }

  // ---------- 路径跟随 ----------
  /// 设置行走路径，并开始移动
  void followPath(List<Vector2> path) {
    _path
      ..clear()
      ..addAll(path.map((point) => point.clone()));
    _advancePath();
  }

  /// 切换顾客状态，同时更新动画和表情
  void changeState(CustomerState value) {
    if (state == value) return;
    state = value;
    // 就坐/等待/用餐状态使用就坐动画，其余使用站立动画
    animation =
    value == CustomerState.seated ||
        value == CustomerState.waiting ||
        value == CustomerState.eating
        ? _seatedAnimation
        : _standingAnimation;
    _showMood(_moodFor(value));
    debugPrint('[Restaurant] customer#$customerId -> ${value.name}');
  }

  // ---------- 更新逻辑 ----------
  @override
  void update(double dt) {
    super.update(dt);

    // 深度排序：就坐时 +1 优先级，确保顾客绘制在椅子之上（避免椅子遮挡顾客）
    final isSeated =
        state == CustomerState.seated ||
            state == CustomerState.waiting ||
            state == CustomerState.eating;
    priority = position.y.round() + (isSeated ? 1 : 0);

    final target = _target;
    if (target == null) return;

    // 移动到目标点
    final diff = target - position;
    final distance = diff.length;
    if (distance < 2) {
      // 到达目标，清除目标并尝试下一个路径点
      position = target;
      _target = null;
      _advancePath();
      return;
    }

    // 计算移动方向
    final direction = diff / distance;
    // 根据水平方向翻转角色（面向移动方向）
    if (direction.x.abs() > 0.05) {
      final faceRight = direction.x > 0;
      if (faceRight != _facingRight) {
        flipHorizontallyAroundCenter();
        _facingRight = faceRight;
      }
    }

    // 移动步长
    final step = direction * _speed * dt;
    // 防止过冲
    position += step.length >= distance ? diff : step;
  }

  /// 从路径中取出下一个目标点
  void _advancePath() {
    _target = _path.isEmpty ? null : _path.removeAt(0);
  }

  // ---------- 表情控制 ----------
  /// 根据状态返回对应的表情索引（0=微笑，1=等待，2=失望）
  int _moodFor(CustomerState value) => switch (value) {
    CustomerState.waitingForTable || CustomerState.waiting => 1,
    CustomerState.leaving => 2,
    _ => 0,
  };

  /// 显示指定索引的表情图标（从 lian.png 中裁剪）
  void _showMood(int index) {
    _moodIcon.sprite = Sprite(
      _moodIcon.sprite!.image,
      srcPosition: Vector2(index * 12, 0), // 每个表情 12x12
      srcSize: Vector2(12, 12),
    );
  }
}