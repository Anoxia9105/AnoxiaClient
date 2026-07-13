import 'dart:convert';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:anoxia/features/game/models/facility_placement.dart';
import 'package:anoxia/features/game/models/restaurant_level_config.dart';

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

  final FacilityConfig config;
  final void Function(RestaurantFacility facility)? onSelected;
  final PlacementResult Function(
    RestaurantFacility facility,
    Vector2 requestedPosition,
  )?
  onMoveRequested;
  final bool Function(RestaurantFacility facility)? onRotateRequested;
  final void Function()? onPlacementChanged;
  bool editable = false;
  bool selected = false;
  bool isVertical = true;
  bool active = true;
  PlacementFailure? lastPlacementFailure;
  int _level = 1;
  int _cols = 1;
  double _cellW = 1;
  double _cellH = 1;
  late dynamic _image;

  int get level => _level;
  String get facilityId => config.id;
  List<String> get assetNames => config.assetNames;

  /// 占地框只描述家具接触地面的部分，不使用整张精灵图片尺寸。
  Rect footprintAt(Vector2 target, {required bool vertical}) {
    final footprintSize = config.footprintFor(vertical);
    return Rect.fromCenter(
      center: Offset(target.x, target.y - footprintSize.y / 2),
      width: footprintSize.x,
      height: footprintSize.y,
    );
  }

  Rect get footprint => footprintAt(position, vertical: isVertical);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await setLevel(_level);
    debugPrint('[Facility] $facilityId placed from separated sheet');
  }

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

  void showFrame(int frame) {
    animation = SpriteAnimation.spriteList(
      [_spriteFor(frame)],
      stepTime: 1,
      loop: false,
    );
  }

  void animateFrames(List<int> frames, {double stepTime = .45}) {
    animation = SpriteAnimation.spriteList(
      frames.map(_spriteFor).toList(),
      stepTime: stepTime,
      loop: true,
    );
  }

  void rotateOrientation() {
    if (!(onRotateRequested?.call(this) ?? true)) {
      lastPlacementFailure = PlacementFailure.overlapsFacility;
      debugPrint('[家具摆放] $facilityId 旋转失败：会与其他家具重叠');
      return;
    }
    flipHorizontallyAroundCenter();
    isVertical = !isVertical;
    lastPlacementFailure = null;
    onPlacementChanged?.call();
  }

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

  Sprite _spriteFor(int frame) => Sprite(
    _image,
    srcPosition: Vector2((frame % _cols) * _cellW, (frame ~/ _cols) * _cellH),
    srcSize: Vector2(_cellW, _cellH),
  );

  @override
  void update(double dt) {
    super.update(dt);
    priority = position.y.round() + config.renderOffset;
  }

  @override
  void render(Canvas canvas) {
    if (!active) return;
    super.render(canvas);
  }

  @override
  void renderDebugMode(Canvas canvas) {
    if (!active) return;
    super.renderDebugMode(canvas);
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
