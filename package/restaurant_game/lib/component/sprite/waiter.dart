import 'dart:async';
import 'dart:convert';

import 'package:flame/components.dart';
import 'package:flutter/services.dart';
import 'package:restaurant_game/component/sprite/enum/waiter_state.dart';
import 'package:restaurant_game/main_game.dart';

class Waiter extends SpriteAnimationGroupComponent
    with HasGameReference<MyGame> {
  static const String _sheetPath = 'flame_sprites/waiter_anim_sheet.png';
  static const String _configPath =
      'assets/images/flame_sprites/waiter_anim_config.json';

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    final image = await game.images.load(_sheetPath);
    // 加载并解析配置文件
    final jsonStr = await rootBundle.loadString(_configPath);
    final config = jsonDecode(jsonStr) as Map<String, dynamic>;

    final cellW = (config['cell_w'] as num).toDouble();
    final cellH = (config['cell_h'] as num).toDouble();
    final cols = config['cols'] as int;

    final animationMap = Map<String, dynamic>.from(config['animations'] as Map);
    // 设置物理尺寸
    size = Vector2(cellW, cellH);

    // 辅助函数：根据帧索引创建 Sprite
    Sprite spriteForFrame(int frameIndex) {
      return Sprite(
        image,
        srcPosition: Vector2(
          (frameIndex % cols) * cellW,
          (frameIndex ~/ cols) * cellH,
        ),
        srcSize: Vector2(cellW, cellH),
      );
    }

    // 辅助函数：构建动画
    SpriteAnimation buildAnimation(String key, {double stepTime = 0.15}) {
      if (!animationMap.containsKey(key)) {
        // 防止 JSON 里漏写了某个状态配置导致崩溃
        return SpriteAnimation.spriteList([], stepTime: stepTime);
      }
      final indexes = (animationMap[key] as List<dynamic>).cast<int>();
      return SpriteAnimation.spriteList(
        indexes.map(spriteForFrame).toList(),
        stepTime: stepTime,
        loop: indexes.length > 1,
      );
    }

    // 组装动画组
    animations = {
      WaiterState.idle: buildAnimation('idle', stepTime: 0.3),
      WaiterState.walking: buildAnimation('walking'),
      WaiterState.carryingFood: buildAnimation('carryingFood'),
    };
    // 当前状态
    current = WaiterState.carryingFood;
  }
}
