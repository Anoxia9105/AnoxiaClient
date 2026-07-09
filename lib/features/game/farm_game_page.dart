import 'dart:ui';
import 'package:anoxia/features/game/config/crop_map.dart';
import 'package:anoxia/features/game/config/crop_type_enum.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/material.dart' show Colors, ValueNotifier;

// ========== 地块状态 ==========
enum PlotStage { empty, growing, ripe, withered }

class FarmGamePage extends FlameGame {
  final ValueNotifier<int> coinNotifier = ValueNotifier<int>(100);
  final ValueNotifier<Map<CropType, int>> seedInventoryNotifier =
      ValueNotifier<Map<CropType, int>>({});
  final ValueNotifier<Map<CropType, int>> harvestInventoryNotifier =
      ValueNotifier<Map<CropType, int>>({});
  final ValueNotifier<CropType?> selectedSeedNotifier =
      ValueNotifier<CropType?>(null);

  // 预加载好的逐帧图片缓存：一种作物对应一串 Sprite
  final Map<CropType, List<Sprite>> cropSprites = {};

  @override
  Future<void> onLoad() async {
    super.onLoad();

    // 预加载所有作物的雪碧图并切成一帧一帧的 Sprite，避免种下去那一刻卡顿
    for (final entry in cropRegistry.entries) {
      final config = entry.value;
      final image = await Flame.images.load(config.spriteSheetPath);
      final sheet = SpriteSheet(
        image: image,
        srcSize: Vector2(
          config.frameWidth.toDouble(),
          config.frameHeight.toDouble(),
        ),
      );
      cropSprites[entry.key] = List.generate(
        config.frameCount,
        (i) => sheet.getSprite(0, i), // 单行横排，行号固定为 0
      );
    }

    const int rows = 3;
    const int cols = 3;
    const double plotSize = 120.0;
    const double spacing = 15.0;

    final double totalWidth = (cols * plotSize) + ((cols - 1) * spacing);
    final double totalHeight = (rows * plotSize) + ((rows - 1) * spacing);

    final double startX = (size.x - totalWidth) / 2;
    final double startY = (size.y - totalHeight) / 2;

    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < cols; col++) {
        final double x = startX + (col * (plotSize + spacing)) + (plotSize / 2);
        final double y = startY + (row * (plotSize + spacing)) + (plotSize / 2);

        add(
          DirtPlot()
            ..position = Vector2(x, y)
            ..anchor = Anchor.center,
        );
      }
    }
  }

  // ---------- 金币 ----------
  bool spendCoin(int amount) {
    if (coinNotifier.value >= amount) {
      coinNotifier.value -= amount;
      return true;
    }
    return false;
  }

  void earnCoin(int amount) => coinNotifier.value += amount;

  // ---------- 种子背包 ----------
  bool buySeed(CropType type) {
    final config = cropRegistry[type]!;
    if (!spendCoin(config.seedPrice)) return false;
    final map = Map<CropType, int>.from(seedInventoryNotifier.value);
    map[type] = (map[type] ?? 0) + 1;
    seedInventoryNotifier.value = map;
    return true;
  }

  bool consumeSeed(CropType type) {
    final map = Map<CropType, int>.from(seedInventoryNotifier.value);
    final count = map[type] ?? 0;
    if (count <= 0) return false;
    if (count == 1) {
      map.remove(type);
      if (selectedSeedNotifier.value == type) {
        selectedSeedNotifier.value = null;
      }
    } else {
      map[type] = count - 1;
    }
    seedInventoryNotifier.value = map;
    return true;
  }

  // ---------- 收获背包 ----------
  void addHarvest(CropType type) {
    final map = Map<CropType, int>.from(harvestInventoryNotifier.value);
    map[type] = (map[type] ?? 0) + 1;
    harvestInventoryNotifier.value = map;
  }

  void sellHarvest(CropType type) {
    final map = Map<CropType, int>.from(harvestInventoryNotifier.value);
    final count = map[type] ?? 0;
    if (count <= 0) return;
    earnCoin(count * cropRegistry[type]!.sellPrice);
    map.remove(type);
    harvestInventoryNotifier.value = map;
  }

  void sellAllHarvest() {
    final map = harvestInventoryNotifier.value;
    if (map.isEmpty) return;
    int total = 0;
    for (final entry in map.entries) {
      total += entry.value * cropRegistry[entry.key]!.sellPrice;
    }
    earnCoin(total);
    harvestInventoryNotifier.value = {};
  }
}

// ========== 土地组件（用真实素材帧渲染） ==========
class DirtPlot extends PositionComponent
    with TapCallbacks, HasGameReference<FarmGamePage> {
  PlotStage currentStage = PlotStage.empty;
  CropType? growingCrop;
  double elapsedGrow = 0; // 种下后经过的时间
  double elapsedRipe = 0; // 成熟后经过的时间（用来判断是否枯萎）

  // 像素画用最近邻缩放，避免糊成马赛克
  static final Paint _pixelPaint = Paint()..filterQuality = FilterQuality.none;

  DirtPlot() : super(size: Vector2.all(120));

  @override
  void update(double dt) {
    super.update(dt);
    if (currentStage == PlotStage.growing && growingCrop != null) {
      final config = cropRegistry[growingCrop]!;
      elapsedGrow += dt;
      if (elapsedGrow >= config.growSeconds) {
        elapsedGrow = config.growSeconds;
        currentStage = PlotStage.ripe;
      }
    } else if (currentStage == PlotStage.ripe && growingCrop != null) {
      final config = cropRegistry[growingCrop]!;
      if (config.witherSeconds != null) {
        elapsedRipe += dt;
        if (elapsedRipe >= config.witherSeconds!) {
          currentStage = PlotStage.withered;
        }
      }
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    _drawSoil(canvas);

    if (currentStage == PlotStage.empty || growingCrop == null) return;

    final config = cropRegistry[growingCrop]!;
    final sprites = game.cropSprites[growingCrop]!;

    late final Sprite frame;
    if (currentStage == PlotStage.withered) {
      frame = sprites.last; // 最后一帧 = 枯萎
    } else if (currentStage == PlotStage.ripe) {
      frame = sprites[config.ripeFrameIndex];
    } else {
      final progress = (elapsedGrow / config.growSeconds).clamp(0.0, 1.0);
      final frameIndex = (progress * config.ripeFrameIndex).floor().clamp(
        0,
        config.ripeFrameIndex,
      );
      frame = sprites[frameIndex];
    }

    const spriteSize = 72.0; // 按你素材实际尺寸和视觉效果调整
    frame.render(
      canvas,
      position: Vector2((size.x - spriteSize) / 2, (size.y - spriteSize) / 2),
      size: Vector2.all(spriteSize),
      overridePaint: _pixelPaint,
    );

    if (currentStage == PlotStage.growing)
      _drawProgressBar(canvas, size.toRect());
    if (currentStage == PlotStage.ripe && config.witherSeconds != null) {
      _drawWitherWarning(canvas, size.toRect(), config.witherSeconds!);
    }
  }

  void _drawSoil(Canvas canvas) {
    final rect = size.toRect();
    final outerRRect = RRect.fromRectAndRadius(rect, const Radius.circular(14));
    canvas.drawRRect(outerRRect, Paint()..color = const Color(0xFF6B3F1F));
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.deflate(6), const Radius.circular(10)),
      Paint()..color = const Color(0xFF8B5A2B),
    );
    canvas.drawRRect(
      outerRRect,
      Paint()
        ..color = Colors.black.withOpacity(0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  void _drawProgressBar(Canvas canvas, Rect rect) {
    final config = cropRegistry[growingCrop]!;
    final barRect = Rect.fromLTWH(
      rect.left + 10,
      rect.bottom - 12,
      rect.width - 20,
      6,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(barRect, const Radius.circular(3)),
      Paint()..color = Colors.black.withOpacity(0.3),
    );
    final progress = (elapsedGrow / config.growSeconds).clamp(0.0, 1.0);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          barRect.left,
          barRect.top,
          barRect.width * progress,
          barRect.height,
        ),
        const Radius.circular(3),
      ),
      Paint()..color = const Color(0xFF7CFC00),
    );
  }

  void _drawWitherWarning(Canvas canvas, Rect rect, double witherSeconds) {
    // 快枯萎时进度条变红提醒
    final remain = 1 - (elapsedRipe / witherSeconds).clamp(0.0, 1.0);
    if (remain > 0.4) return; // 剩余时间还多，不提醒
    final barRect = Rect.fromLTWH(
      rect.left + 10,
      rect.bottom - 12,
      rect.width - 20,
      6,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(barRect, const Radius.circular(3)),
      Paint()..color = Colors.black.withOpacity(0.3),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          barRect.left,
          barRect.top,
          barRect.width * remain,
          barRect.height,
        ),
        const Radius.circular(3),
      ),
      Paint()..color = Colors.redAccent,
    );
  }

  @override
  void onTapDown(TapDownEvent event) {
    super.onTapDown(event);

    switch (currentStage) {
      case PlotStage.empty:
        final selected = game.selectedSeedNotifier.value;
        if (selected != null && game.consumeSeed(selected)) {
          growingCrop = selected;
          currentStage = PlotStage.growing;
          elapsedGrow = 0;
          elapsedRipe = 0;
        }
        break;
      case PlotStage.ripe:
        if (growingCrop != null) {
          game.addHarvest(growingCrop!);
          _reset();
        }
        break;
      case PlotStage.withered:
        _reset(); // 枯萎了只能清地，没有收获
        break;
      case PlotStage.growing:
        break; // 生长中点击无效果
    }
  }

  void _reset() {
    currentStage = PlotStage.empty;
    growingCrop = null;
    elapsedGrow = 0;
    elapsedRipe = 0;
  }
}
