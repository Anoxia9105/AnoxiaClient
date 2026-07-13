import 'dart:convert';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:anoxia/features/game/models/facility_placement.dart';
import 'package:anoxia/features/game/models/restaurant_level_config.dart';

/// 餐厅家具组件。
/// 基于 `SpriteAnimationComponent` 实现，支持拖拽摆放、旋转、状态切换和碰撞检测。
/// 通过配置文件 [FacilityConfig] 定义外观、占地尺寸和行为。
/// 混合了 [HasGameReference] 以便访问游戏资源，以及 [DragCallbacks] 和 [TapCallbacks] 支持交互。
class RestaurantFacility extends SpriteAnimationComponent
    with HasGameReference, DragCallbacks, TapCallbacks {
  RestaurantFacility({
    required this.config,
    required Vector2 position,
    this.onSelected,
    this.onMoveRequested,
    this.onRotateRequested,
    this.onPlacementChanged,
  }) : super(position: position, anchor: Anchor.bottomCenter);

  // ---------- 配置与回调 ----------
  /// 家具配置（包含类型、精灵、占地等）
  final FacilityConfig config;

  /// 选中回调（编辑模式下点击时触发）
  final void Function(RestaurantFacility facility)? onSelected;

  /// 移动请求回调，由外部控制器决定是否允许移动并返回结果
  final PlacementResult Function(
      RestaurantFacility facility,
      Vector2 requestedPosition,
      )?
  onMoveRequested;

  /// 旋转请求回调，由外部控制器决定是否允许旋转
  final bool Function(RestaurantFacility facility)? onRotateRequested;

  /// 摆放状态变化回调（用于通知控制器更新碰撞数据）
  final void Function()? onPlacementChanged;

  // ---------- 状态标志 ----------
  /// 是否可编辑（即可被拖拽移动）
  bool editable = false;

  /// 是否被选中（编辑模式下高亮显示）
  bool selected = false;

  /// 是否垂直朝向（`true` = 垂直，`false` = 水平）
  bool isVertical = true;

  /// 是否激活（业务拥有该设施时显示，否则隐藏）
  bool active = true;

  /// 上次摆放失败的原因（用于调试显示）
  PlacementFailure? lastPlacementFailure;

  // ---------- 内部资源 ----------
  int _level = 1;           // 当前层级（对应精灵表中的一组帧）
  int _cols = 1;           // 精灵表中的列数
  double _cellW = 1;       // 每个精灵帧的宽度（像素）
  double _cellH = 1;       // 每个精灵帧的高度（像素）
  late dynamic _image;     // 加载的图片资源（Image 对象）

  // ---------- 属性访问器 ----------
  int get level => _level;
  String get facilityId => config.id;
  List<String> get assetNames => config.assetNames;

  /// 计算给定位置和朝向下，家具的占地矩形（对象空间坐标）。
  /// 占地矩形仅包含家具接触地面的部分，不包含整张精灵图片的尺寸，
  /// 用于碰撞检测和摆放约束。
  Rect footprintAt(Vector2 target, {required bool vertical}) {
    final footprintSize = config.footprintFor(vertical);
    return Rect.fromCenter(
      center: Offset(target.x, target.y - footprintSize.y / 2),
      width: footprintSize.x,
      height: footprintSize.y,
    );
  }

  /// 当前朝向下，基于当前位置的占地矩形
  Rect get footprint => footprintAt(position, vertical: isVertical);

  // ---------- 生命周期 ----------
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await setLevel(_level);
    debugPrint('[Facility] $facilityId placed from separated sheet');
  }

  /// 设置当前显示的层级（对应精灵表中的一组帧）。
  /// 从 JSON 配置文件中读取精灵表元数据，并加载对应的图片。
  Future<void> setLevel(int value) async {
    _level = value.clamp(1, assetNames.length);
    final name = assetNames[_level - 1];
    final assetConfig =
    jsonDecode(
      await rootBundle.loadString(
        'assets/images/flame_resources/config/$name.json',
      ),
    )
    as Map<String, dynamic>;
    _cellW = (assetConfig['cell_w'] as num).toDouble();
    _cellH = (assetConfig['cell_h'] as num).toDouble();
    _cols = assetConfig['cols'] as int;
    _image = await game.images.load(assetConfig['sheet_path'] as String);
    size = Vector2(_cellW, _cellH);
    showFrame(config.initialFrame);
  }

  // ---------- 帧控制 ----------
  /// 显示指定帧（单帧动画，用于静止状态）
  void showFrame(int frame) {
    animation = SpriteAnimation.spriteList(
      [_spriteFor(frame)],
      stepTime: 1,
      loop: false,
    );
  }

  /// 播放一组帧的循环动画（用于厨房烹饪等动态效果）
  void animateFrames(List<int> frames, {double stepTime = .45}) {
    animation = SpriteAnimation.spriteList(
      frames.map(_spriteFor).toList(),
      stepTime: stepTime,
      loop: true,
    );
  }

  // ---------- 旋转 ----------
  /// 旋转家具朝向（垂直 ↔ 水平）。
  /// 会先调用回调检查是否允许旋转，允许则翻转精灵并更新朝向标志。
  void rotateOrientation() {
    if (!(onRotateRequested?.call(this) ?? true)) {
      lastPlacementFailure = PlacementFailure.overlapsFacility;
      debugPrint('[家具摆放] $facilityId 旋转失败：会与其他家具重叠');
      return;
    }
    // 水平翻转精灵（视觉效果），并切换朝向标志
    flipHorizontallyAroundCenter();
    isVertical = !isVertical;
    lastPlacementFailure = null;
    onPlacementChanged?.call();
  }

  // ---------- 事件处理（拖拽与点击） ----------
  @override
  void onTapDown(TapDownEvent event) {
    if (!editable) return;
    onSelected?.call(this);
  }

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    if (!editable) return;
    onSelected?.call(this);
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    if (!editable) return;
    // 等距地图中，垂直朝向时水平移动方向相反，因此进行坐标矫正
    final delta = event.localDelta;
    final requested =
        position + Vector2(isVertical ? delta.x : -delta.x, delta.y);
    final result =
        onMoveRequested?.call(this, requested) ??
            PlacementResult.accepted(requested);
    lastPlacementFailure = result.failure;
    if (result.accepted) {
      position = result.position;
      onPlacementChanged?.call();
    }
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    if (!editable) return;
    if (lastPlacementFailure != null) {
      debugPrint('[家具摆放] $facilityId 摆放失败：$lastPlacementFailure');
    }
    onPlacementChanged?.call();
  }

  // ---------- 辅助方法 ----------
  /// 从精灵表中创建指定帧的 `Sprite` 对象
  Sprite _spriteFor(int frame) => Sprite(
    _image,
    srcPosition: Vector2((frame % _cols) * _cellW, (frame ~/ _cols) * _cellH),
    srcSize: Vector2(_cellW, _cellH),
  );

  // ---------- 渲染与更新 ----------
  @override
  void update(double dt) {
    super.update(dt);
    // 根据 Y 坐标设置渲染优先级（等距地图的深度排序）
    priority = position.y.round() + config.renderOffset;
  }

  @override
  void render(Canvas canvas) {
    if (!active) return; // 未激活则不渲染
    super.render(canvas);
  }

  @override
  void renderDebugMode(Canvas canvas) {
    if (!active) return;
    super.renderDebugMode(canvas);
    // 绘制占地矩形（调试模式）
    final localFootprint = footprint.shift(Offset(-position.x, -position.y));
    canvas.drawRect(
      localFootprint,
      Paint()
        ..color = lastPlacementFailure == null
            ? (selected ? const Color(0xFF00E5FF) : const Color(0xFFFFAB00))
            : const Color(0xFFFF1744)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );
  }
}