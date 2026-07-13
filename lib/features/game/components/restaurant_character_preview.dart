import 'dart:convert';

import 'package:flame/components.dart';
import 'package:flutter/services.dart';

/// 餐厅角色预览组件。
/// 用于在 UI 界面（例如角色选择、展示界面）中循环播放某个角色的预览动画。
/// 该组件继承自 [SpriteAnimationComponent]，并混合了 [HasGameReference]
/// 以便从游戏缓存中加载图片资源。
///
/// 预览动画帧优先从配置文件的 `preview` 字段读取，若不存在则依次回退到
/// `walking` 或 `idle` 动画帧列表。
class RestaurantCharacterPreview extends SpriteAnimationComponent
    with HasGameReference {
  /// 角色名称，用于定位对应的精灵表配置文件和图片资源。
  final String characterName;

  /// 预览时的缩放倍数，默认 1.4 倍以在 UI 中显示更大。
  final double previewScale;

  /// 构造一个角色预览组件。
  /// [characterName] 角色名称（例如 'waiter', 'yongman' 等）。
  /// [position] 组件在父级坐标系中的位置。
  /// [previewScale] 缩放倍数，默认为 1.4。
  RestaurantCharacterPreview({
    required this.characterName,
    required Vector2 position,
    this.previewScale = 1.4,
  }) : super(position: position);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // 构建配置文件路径（例如 'assets/images/flame_sprites/waiter_anim_config.json'）
    final configPath =
        'assets/images/flame_sprites/${characterName}_anim_config.json';
    // 加载并解析 JSON 配置
    final config =
    jsonDecode(await rootBundle.loadString(configPath))
    as Map<String, dynamic>;

    // 读取精灵表元数据
    final sheetPath = config['sheet_path'] as String; // 精灵表图片路径
    final cellW = (config['cell_w'] as num).toDouble(); // 单帧宽度
    final cellH = (config['cell_h'] as num).toDouble(); // 单帧高度
    final cols = config['cols'] as int;                // 精灵表列数
    final animations = config['animations'] as Map<String, dynamic>;

    // 获取预览动画的帧索引列表
    final frameIndexes = _readAnimationFrames(animations);

    // 从游戏缓存中获取已加载的精灵表图片（由其他组件预加载）
    final image = game.images.fromCache(sheetPath);

    // 设置组件尺寸并应用缩放
    size = Vector2(cellW, cellH);
    scale = Vector2.all(previewScale);

    // 创建精灵动画，帧间隔 0.18 秒，循环播放（多帧时）
    animation = SpriteAnimation.spriteList(
      frameIndexes.map((frameIndex) {
        return Sprite(
          image,
          srcPosition: Vector2(
            (frameIndex % cols) * cellW, // 计算帧在精灵表中的 X 偏移
            (frameIndex ~/ cols) * cellH, // 计算帧在精灵表中的 Y 偏移
          ),
          srcSize: Vector2(cellW, cellH),
        );
      }).toList(),
      stepTime: 0.18,
      loop: frameIndexes.length > 1, // 多帧时循环，单帧则静止
    );
  }

  /// 从配置的动画映射中读取预览帧列表。
  /// 优先读取 `preview` 字段，若不存在则依次回退到 `walking` 或 `idle`。
  /// 如果所有字段都不存在或不是列表，则返回仅包含第 0 帧的列表（默认帧）。
  List<int> _readAnimationFrames(Map<String, dynamic> animations) {
    // 按优先级依次尝试获取帧列表
    final frames =
        animations['preview'] ?? animations['walking'] ?? animations['idle'];
    if (frames is List) {
      return frames.cast<int>(); // 转换为 int 列表
    }
    // 未找到有效的帧列表，返回默认第 0 帧
    return const [0];
  }
}