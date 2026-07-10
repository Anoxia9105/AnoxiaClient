import 'dart:convert';

import 'package:flame/components.dart';
import 'package:flutter/services.dart';

class RestaurantCharacterPreview extends SpriteAnimationComponent
    with HasGameReference {
  final String characterName;
  final double previewScale;

  RestaurantCharacterPreview({
    required this.characterName,
    required Vector2 position,
    this.previewScale = 1.4,
  }) : super(position: position);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    final configPath =
        'assets/images/flame_sprites/${characterName}_anim_config.json';
    final config =
        jsonDecode(await rootBundle.loadString(configPath))
            as Map<String, dynamic>;
    final sheetPath = config['sheet_path'] as String;
    final cellW = (config['cell_w'] as num).toDouble();
    final cellH = (config['cell_h'] as num).toDouble();
    final cols = config['cols'] as int;
    final animations = config['animations'] as Map<String, dynamic>;
    final frameIndexes = _readAnimationFrames(animations);
    final image = game.images.fromCache(sheetPath);

    size = Vector2(cellW, cellH);
    scale = Vector2.all(previewScale);
    animation = SpriteAnimation.spriteList(
      frameIndexes.map((frameIndex) {
        return Sprite(
          image,
          srcPosition: Vector2(
            (frameIndex % cols) * cellW,
            (frameIndex ~/ cols) * cellH,
          ),
          srcSize: Vector2(cellW, cellH),
        );
      }).toList(),
      stepTime: 0.18,
      loop: frameIndexes.length > 1,
    );
  }

  List<int> _readAnimationFrames(Map<String, dynamic> animations) {
    final frames =
        animations['preview'] ?? animations['walking'] ?? animations['idle'];
    if (frames is List) {
      return frames.cast<int>();
    }
    return const [0];
  }
}
