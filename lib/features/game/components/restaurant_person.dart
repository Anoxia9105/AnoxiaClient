import 'dart:convert';

import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// A stationary member of the restaurant staff/customer cast.
class RestaurantPerson extends SpriteAnimationComponent with HasGameReference {
  RestaurantPerson({required this.characterName, required Vector2 position})
    : super(
        position: position,
        anchor: Anchor.bottomCenter,
        priority: position.y.round(),
      );

  final String characterName;

  @override
  void update(double dt) {
    super.update(dt);
    // Isometric depth is determined by the character's feet, not add order.
    priority = position.y.round();
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    final config =
        jsonDecode(
              await rootBundle.loadString(
                'assets/images/flame_sprites/${characterName}_anim_config.json',
              ),
            )
            as Map<String, dynamic>;
    final cellW = (config['cell_w'] as num).toDouble();
    final cellH = (config['cell_h'] as num).toDouble();
    final cols = config['cols'] as int;
    final animations = config['animations'] as Map<String, dynamic>;
    final frames = ((animations['idle'] ?? animations['preview']) as List)
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
      stepTime: 0.2,
      loop: frames.length > 1,
    );
    debugPrint(
      '[RestaurantNPC] loaded=$characterName position=$position '
      'size=$size anchor=$anchor debug=$debugMode',
    );
  }
}
