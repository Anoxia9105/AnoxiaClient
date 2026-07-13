import 'dart:convert';

import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

enum CustomerState { entering, seated, waiting, eating, paying, leaving }

class RestaurantCustomer extends SpriteAnimationComponent
    with HasGameReference {
  RestaurantCustomer({required Vector2 position})
    : super(position: position, anchor: Anchor.bottomCenter);

  static const _speed = 72.0;
  final List<Vector2> _path = [];
  Vector2? _target;
  bool _facingRight = true;
  CustomerState state = CustomerState.entering;

  bool get isMoving => _target != null || _path.isNotEmpty;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    final config =
        jsonDecode(
              await rootBundle.loadString(
                'assets/images/flame_sprites/yongman_anim_config.json',
              ),
            )
            as Map<String, dynamic>;
    final cellW = (config['cell_w'] as num).toDouble();
    final cellH = (config['cell_h'] as num).toDouble();
    final cols = config['cols'] as int;
    final animations = config['animations'] as Map<String, dynamic>;
    final frames =
        ((animations['walking'] ?? animations['preview'] ?? animations['idle'])
                as List)
            .cast<int>();
    final image = game.images.fromCache(config['sheet_path'] as String);
    size = Vector2(cellW, cellH);
    animation = SpriteAnimation.spriteList(
      frames
          .map(
            (frame) => Sprite(
              image,
              srcPosition: Vector2(
                (frame % cols) * cellW,
                (frame ~/ cols) * cellH,
              ),
              srcSize: Vector2(cellW, cellH),
            ),
          )
          .toList(),
      stepTime: 0.18,
      loop: frames.length > 1,
    );
    debugPrint('[MVP] customer spawned at $position');
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
    debugPrint('[MVP] customer state -> ${value.name}');
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
