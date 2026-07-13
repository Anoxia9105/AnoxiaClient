import 'dart:convert';

import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

enum CustomerState {
  entering,
  waitingForTable,
  seated,
  waiting,
  eating,
  queueing,
  paying,
  leaving,
}

class RestaurantCustomer extends SpriteAnimationComponent
    with HasGameReference {
  RestaurantCustomer({
    required this.customerId,
    required this.characterName,
    required Vector2 position,
  }) : super(position: position, anchor: Anchor.bottomCenter);

  static const _speed = 72.0;
  final int customerId;
  final String characterName;
  final List<Vector2> _path = [];
  Vector2? _target;
  bool _facingRight = true;
  late final SpriteAnimation _standingAnimation;
  late final SpriteAnimation _seatedAnimation;
  CustomerState state = CustomerState.entering;

  bool get isMoving => _target != null || _path.isNotEmpty;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    final config =
        jsonDecode(
              await rootBundle.loadString(
                'assets/images/flame_resources/customers/$characterName.json',
              ),
            )
            as Map<String, dynamic>;
    final cellW = (config['cell_w'] as num).toDouble();
    final cellH = (config['cell_h'] as num).toDouble();
    final cols = config['cols'] as int;
    final animations = config['animations'] as Map<String, dynamic>;
    final standingFrames = (animations['standing'] as List).cast<int>();
    final seatedFrames = (animations['seatedSide'] as List).cast<int>();
    final image = game.images.fromCache(config['sheet_path'] as String);
    size = Vector2(cellW, cellH);
    Sprite frameSprite(int frame) => Sprite(
      image,
      srcPosition: Vector2((frame % cols) * cellW, (frame ~/ cols) * cellH),
      srcSize: Vector2(cellW, cellH),
    );
    _standingAnimation = SpriteAnimation.spriteList(
      [frameSprite(standingFrames.first)],
      stepTime: 1,
      loop: false,
    );
    _seatedAnimation = SpriteAnimation.spriteList(
      [frameSprite(seatedFrames.first)],
      stepTime: 1,
      loop: false,
    );
    animation = _standingAnimation;
    debugPrint('[Restaurant] customer#$customerId ($characterName) spawned');
  }

  void followPath(List<Vector2> path) {
    _path
      ..clear()
      ..addAll(path.map((point) => point.clone()));
    _advancePath();
  }

  void changeState(CustomerState value) {
    if (state == value) return;
    state = value;
    animation =
        value == CustomerState.seated ||
            value == CustomerState.waiting ||
            value == CustomerState.eating
        ? _seatedAnimation
        : _standingAnimation;
    debugPrint('[Restaurant] customer#$customerId -> ${value.name}');
  }

  @override
  void update(double dt) {
    super.update(dt);
    priority = position.y.round();
    final target = _target;
    if (target == null) return;
    final diff = target - position;
    final distance = diff.length;
    if (distance < 2) {
      position = target;
      _target = null;
      _advancePath();
      return;
    }
    final direction = diff / distance;
    if (direction.x.abs() > 0.05) {
      final faceRight = direction.x > 0;
      if (faceRight != _facingRight) {
        flipHorizontallyAroundCenter();
        _facingRight = faceRight;
      }
    }
    final step = direction * _speed * dt;
    position += step.length >= distance ? diff : step;
  }

  void _advancePath() {
    _target = _path.isEmpty ? null : _path.removeAt(0);
  }
}
