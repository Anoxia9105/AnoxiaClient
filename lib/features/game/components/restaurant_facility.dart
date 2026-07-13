import 'dart:convert';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class RestaurantFacility extends SpriteAnimationComponent
    with HasGameReference, DragCallbacks, TapCallbacks {
  RestaurantFacility({
    required this.facilityId,
    required this.assetNames,
    required Vector2 position,
    this.initialFrame = 0,
    this.renderOffset = 0,
    this.onSelected,
    this.onLayoutChanged,
  }) : super(position: position, anchor: Anchor.bottomCenter);

  final String facilityId;
  final List<String> assetNames;
  final int initialFrame;
  final int renderOffset;
  final void Function(RestaurantFacility facility)? onSelected;
  final void Function()? onLayoutChanged;
  bool editable = false;
  bool selected = false;
  bool isVertical = true;
  int _level = 1;
  int _cols = 1;
  double _cellW = 1;
  double _cellH = 1;
  late dynamic _image;

  int get level => _level;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await setLevel(_level);
    debugPrint('[Facility] $facilityId placed from separated sheet');
  }

  Future<void> setLevel(int value) async {
    _level = value.clamp(1, assetNames.length);
    final name = assetNames[_level - 1];
    final config =
        jsonDecode(
              await rootBundle.loadString(
                'assets/images/flame_resources/config/$name.json',
              ),
            )
            as Map<String, dynamic>;
    _cellW = (config['cell_w'] as num).toDouble();
    _cellH = (config['cell_h'] as num).toDouble();
    _cols = config['cols'] as int;
    _image = await game.images.load(config['sheet_path'] as String);
    size = Vector2(_cellW, _cellH);
    showFrame(initialFrame);
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
    flipHorizontallyAroundCenter();
    isVertical = !isVertical;
    onLayoutChanged?.call();
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
    position += Vector2(isVertical ? delta.x : -delta.x, delta.y);
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    if (!editable) return;
    onLayoutChanged?.call();
  }

  Sprite _spriteFor(int frame) => Sprite(
    _image,
    srcPosition: Vector2((frame % _cols) * _cellW, (frame ~/ _cols) * _cellH),
    srcSize: Vector2(_cellW, _cellH),
  );

  @override
  void update(double dt) {
    super.update(dt);
    priority = position.y.round() + renderOffset;
  }

  @override
  void renderDebugMode(Canvas canvas) {
    super.renderDebugMode(canvas);
    if (!selected) return;
    canvas.drawRect(
      size.toRect(),
      Paint()
        ..color = const Color(0xFF00E5FF)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );
  }
}
