import 'dart:convert';

import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// 餐厅中的静态角色（员工或顾客）。
/// 基于精灵表单帧动画，从 JSON 配置文件加载动画元数据。
/// 角色使用等距深度排序（根据 Y 坐标设置优先级）。
class RestaurantPerson extends SpriteAnimationComponent with HasGameReference {
  /// 创建一个餐厅角色。
  /// [characterName] 角色名称，用于定位对应的配置文件和精灵表。
  /// [position] 角色的世界坐标（底部中心锚点）。
  RestaurantPerson({required this.characterName, required Vector2 position})
      : super(
    position: position,
    anchor: Anchor.bottomCenter,
    priority: position.y.round(),
  );

  /// 角色名称，对应 `assets/images/flame_sprites/${characterName}_anim_config.json`
  final String characterName;

  @override
  void update(double dt) {
    super.update(dt);
    // 等距地图的深度排序取决于角色的脚底位置（Y 坐标），而不是添加顺序。
    priority = position.y.round();
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // 加载角色动画配置文件
    final config =
    jsonDecode(
      await rootBundle.loadString(
        'assets/images/flame_sprites/${characterName}_anim_config.json',
      ),
    )
    as Map<String, dynamic>;

    // 解析精灵表元数据
    final cellW = (config['cell_w'] as num).toDouble(); // 单帧宽度
    final cellH = (config['cell_h'] as num).toDouble(); // 单帧高度
    final cols = config['cols'] as int;                // 精灵表列数
    final animations = config['animations'] as Map<String, dynamic>;

    // 获取空闲动画帧列表，如果不存在则回退到预览动画
    final frames = ((animations['idle'] ?? animations['preview']) as List)
        .cast<int>();

    // 从缓存中获取已加载的精灵表图片
    final image = game.images.fromCache(config['sheet_path'] as String);

    // 设置组件尺寸
    size = Vector2(cellW, cellH);

    // 根据帧列表创建精灵动画
    animation = SpriteAnimation.spriteList(
      frames
          .map(
            (frame) => Sprite(
          image,
          srcPosition: Vector2(
            (frame % cols) * cellW, // 计算帧在精灵表中的 X 偏移
            (frame ~/ cols) * cellH, // 计算帧在精灵表中的 Y 偏移
          ),
          srcSize: Vector2(cellW, cellH),
        ),
      )
          .toList(),
      stepTime: 0.2,        // 每帧持续时间（秒）
      loop: frames.length > 1, // 多帧时循环播放
    );

    debugPrint(
      '[RestaurantNPC] loaded=$characterName position=$position '
          'size=$size anchor=$anchor debug=$debugMode',
    );
  }
}