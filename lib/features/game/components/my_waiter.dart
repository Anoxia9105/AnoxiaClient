import 'dart:convert';

import 'package:flame/components.dart';
import 'package:flutter/services.dart';

enum WaiterState { idle, walking, carryingFood }

class MyWaiter extends PositionComponent with HasGameReference {
  static const int _headFrameIndex = 0;
  static const int _idleBodyFrameIndex = 12;
  static const List<int> _walkingBodyFrameIndexes = [16, 17, 20, 22];
  static const List<int> _carryingBodyFrameIndexes = [8, 9, 10, 11];

  List<dynamic> frames = [];
  late SpriteComponent head;
  late SpriteComponent body;
  late SpriteComponent legs;

  WaiterState currentState = WaiterState.idle;
  double _timer = 0;
  int _walkFrame = 0;

  MyWaiter() : super(size: Vector2(48, 76), position: Vector2(24, 24)) {
    scale = Vector2.all(3.0);
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    final jsonStr = await rootBundle.loadString(
      'assets/images/flame_sprites/sprite_config.json',
    );
    final data = jsonDecode(jsonStr);
    frames = data['waiter']['frames'];

    head = SpriteComponent();
    body = SpriteComponent();
    legs = SpriteComponent();

    add(legs);
    add(body);
    add(head);

    _buildWaiter();
  }

  void _buildWaiter() {
    if (frames.isEmpty) return;

    Sprite getPart(int index) {
      final f = frames[index];
      return Sprite(
        game.images.fromCache('flame_sprites/waiter_sheet.png'),
        srcPosition: Vector2(f['x'].toDouble(), f['y'].toDouble()),
        srcSize: Vector2(f['w'].toDouble(), f['h'].toDouble()),
      );
    }

    final headFrame = frames[_headFrameIndex];
    head.sprite = getPart(_headFrameIndex);
    head.size = Vector2(
      headFrame['w'].toDouble(),
      headFrame['h'].toDouble(),
    );
    head.position = Vector2((size.x - head.size.x) / 2, 0);

    final bodyIndex = switch (currentState) {
      WaiterState.idle => _idleBodyFrameIndex,
      WaiterState.walking =>
        _walkingBodyFrameIndexes[_walkFrame % _walkingBodyFrameIndexes.length],
      WaiterState.carryingFood =>
        _carryingBodyFrameIndexes[_walkFrame % _carryingBodyFrameIndexes.length],
    };
    final bodyFrame = frames[bodyIndex];
    body.sprite = getPart(bodyIndex);
    body.size = Vector2(
      bodyFrame['w'].toDouble(),
      bodyFrame['h'].toDouble(),
    );
    body.position = Vector2((size.x - body.size.x) / 2, size.y - body.size.y);

    legs.sprite = null;
    legs.size = Vector2.zero();
  }

  void changeState(WaiterState state) {
    currentState = state;
    _buildWaiter();
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (currentState != WaiterState.idle) {
      _timer += dt;
      if (_timer > 0.15) {
        _timer = 0;
        _walkFrame++;
        _buildWaiter();
      }
    }
  }
}
