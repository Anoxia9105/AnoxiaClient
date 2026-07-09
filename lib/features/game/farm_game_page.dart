import 'dart:math' show min;
import 'dart:ui' as ui;
import 'package:anoxia/features/game/config/crop_map.dart';
import 'package:anoxia/features/game/config/crop_type_enum.dart';
import 'package:anoxia/features/game/game_persistence.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/material.dart' show Color, Colors, ValueNotifier;

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

  // 预加载好的逐帧图片缓存
  final Map<CropType, List<Sprite>> cropSprites = {};
  // 所有地块引用（用于持久化快照）
  final List<DirtPlot> plots = [];
  // 地面瓦片图片
  ui.Image? groundImage;

  // 自动存档计时器
  double _saveTimer = 0;
  static const double _saveInterval = 5.0; // 每 5 秒自动存一次

  @override
  Color backgroundColor() => const Color(0xFF6AAB3A); // 草地绿背景

  @override
  Future<void> onLoad() async {
    super.onLoad();

    // 1. 加载地面瓦片
    groundImage = await Flame.images.load('tiles/ground_01_16x16.png');

    // 2. 预加载所有作物的雪碧图
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
        (i) => sheet.getSprite(0, i),
      );
    }

    // 3. 加载持久化存档
    final saved = await GamePersistence.load();
    if (saved != null) {
      coinNotifier.value = saved.coins;
      seedInventoryNotifier.value = saved.seeds;
      harvestInventoryNotifier.value = saved.harvest;
    }

    // 4. 动态计算地块大小并创建 4×5 = 20 块地
    const int rows = 5;
    const int cols = 4;
    const double spacing = 10.0;
    const double topPadding = 130.0;

    final double availW = size.x - 32;
    final double availH = size.y - topPadding - 20;
    final double plotSize = min(
      (availW - spacing * (cols - 1)) / cols,
      (availH - spacing * (rows - 1)) / rows,
    ).clamp(60.0, 112.0);

    final double totalWidth = cols * plotSize + (cols - 1) * spacing;
    final double totalHeight = rows * plotSize + (rows - 1) * spacing;
    final double startX = (size.x - totalWidth) / 2;
    final double startY = topPadding + (availH - totalHeight) / 2;

    int plotIndex = 0;
    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < cols; col++) {
        final double x = startX + col * (plotSize + spacing) + plotSize / 2;
        final double y = startY + row * (plotSize + spacing) + plotSize / 2;

        final plot = DirtPlot(groundImage: groundImage!, plotSize: plotSize)
          ..position = Vector2(x, y)
          ..anchor = Anchor.center;

        // 恢复持久化状态
        if (saved != null && plotIndex < saved.plots.length) {
          final ps = saved.plots[plotIndex];
          plot.currentStage = ps.stage;
          plot.growingCrop = ps.crop;
          plot.elapsedGrow = ps.elapsedGrow;
          plot.elapsedRipe = ps.elapsedRipe;
        }

        plots.add(plot);
        add(plot);
        plotIndex++;
      }
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _saveTimer += dt;
    if (_saveTimer >= _saveInterval) {
      _saveTimer = 0;
      saveState();
    }
  }

  // ---------- 持久化 ----------
  void saveState() {
    final plotStates =
        plots
            .map(
              (p) => PlotSaveState(
                stage: p.currentStage,
                crop: p.growingCrop,
                elapsedGrow: p.elapsedGrow,
                elapsedRipe: p.elapsedRipe,
              ),
            )
            .toList();
    GamePersistence.save(
      coins: coinNotifier.value,
      seeds: seedInventoryNotifier.value,
      harvest: harvestInventoryNotifier.value,
      plots: plotStates,
    );
  }

  // ---------- 内部金币操作（不触发存档，由外层统一存）----------
  bool _trySpend(int amount) {
    if (coinNotifier.value >= amount) {
      coinNotifier.value -= amount;
      return true;
    }
    return false;
  }

  // ---------- 金币 ----------
  bool spendCoin(int amount) {
    if (_trySpend(amount)) {
      saveState();
      return true;
    }
    return false;
  }

  void earnCoin(int amount) {
    coinNotifier.value += amount;
    saveState();
  }

  // ---------- 种子背包 ----------
  bool buySeed(CropType type, {int qty = 1}) {
    final config = cropRegistry[type]!;
    if (!_trySpend(config.seedPrice * qty)) return false;
    final map = Map<CropType, int>.from(seedInventoryNotifier.value);
    map[type] = (map[type] ?? 0) + qty;
    seedInventoryNotifier.value = map;
    saveState();
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
    saveState();
  }

  void sellHarvest(CropType type) {
    final map = Map<CropType, int>.from(harvestInventoryNotifier.value);
    final count = map[type] ?? 0;
    if (count <= 0) return;
    coinNotifier.value += count * cropRegistry[type]!.sellPrice;
    map.remove(type);
    harvestInventoryNotifier.value = map;
    saveState();
  }

  void sellAllHarvest() {
    final map = harvestInventoryNotifier.value;
    if (map.isEmpty) return;
    int total = 0;
    for (final entry in map.entries) {
      total += entry.value * cropRegistry[entry.key]!.sellPrice;
    }
    coinNotifier.value += total;
    harvestInventoryNotifier.value = {};
    saveState();
  }
}

// ========== 土地组件（地面瓦片 + 作物动画） ==========
class DirtPlot extends PositionComponent
    with TapCallbacks, HasGameReference<FarmGamePage> {
  PlotStage currentStage = PlotStage.empty;
  CropType? growingCrop;
  double elapsedGrow = 0;
  double elapsedRipe = 0;

  final ui.Image groundImage;

  // 像素画用最近邻缩放，避免糊成马赛克
  static final ui.Paint _pixelPaint =
      ui.Paint()..filterQuality = ui.FilterQuality.none;

  DirtPlot({required this.groundImage, required double plotSize})
    : super(size: Vector2.all(plotSize));

  @override
  void update(double dt) {
    super.update(dt);
    if (currentStage == PlotStage.growing && growingCrop != null) {
      final config = cropRegistry[growingCrop]!;
      elapsedGrow += dt;
      if (elapsedGrow >= config.growSeconds) {
        elapsedGrow = config.growSeconds;
        currentStage = PlotStage.ripe;
        game.saveState();
      }
    } else if (currentStage == PlotStage.ripe && growingCrop != null) {
      final config = cropRegistry[growingCrop]!;
      if (config.witherSeconds != null) {
        elapsedRipe += dt;
        if (elapsedRipe >= config.witherSeconds!) {
          currentStage = PlotStage.withered;
          game.saveState();
        }
      }
    }
  }

  @override
  void render(ui.Canvas canvas) {
    super.render(canvas);
    _drawSoil(canvas);

    if (currentStage == PlotStage.empty || growingCrop == null) return;

    final config = cropRegistry[growingCrop]!;
    final sprites = game.cropSprites[growingCrop]!;

    late final Sprite frame;
    if (currentStage == PlotStage.withered) {
      frame = sprites.last;
    } else if (currentStage == PlotStage.ripe) {
      frame = sprites[config.ripeFrameIndex];
    } else {
      final progress = (elapsedGrow / config.growSeconds).clamp(0.0, 1.0);
      final frameIndex = (progress * config.ripeFrameIndex)
          .floor()
          .clamp(0, config.ripeFrameIndex);
      frame = sprites[frameIndex];
    }

    // 按作物素材宽高比动态渲染，高作物（16×32）不会被压扁
    final aspectRatio = config.frameHeight / config.frameWidth;
    final maxW = size.x * 0.70;
    final maxH = size.y * 0.78; // 底部留给进度条
    double dw = maxW;
    double dh = dw * aspectRatio;
    if (dh > maxH) {
      dh = maxH;
      dw = dh / aspectRatio;
    }

    final dx = (size.x - dw) / 2;
    final dy = size.y - dh - 12;

    frame.render(
      canvas,
      position: Vector2(dx, dy),
      size: Vector2(dw, dh),
      overridePaint: _pixelPaint,
    );

    if (currentStage == PlotStage.growing) {
      _drawProgressBar(canvas, size.toRect());
    }
    if (currentStage == PlotStage.ripe && config.witherSeconds != null) {
      _drawWitherWarning(canvas, size.toRect(), config.witherSeconds!);
    }
  }

  // 用地面瓦片平铺填满地块背景
  void _drawSoil(ui.Canvas canvas) {
    final rect = size.toRect();
    canvas.save();
    canvas.clipRRect(
      ui.RRect.fromRectAndRadius(rect, const ui.Radius.circular(8)),
    );

    // 以 32×32（2× 像素画缩放）为单位平铺 ground_01_16x16.png
    const double tileDisplay = 32.0;
    const double tileNative = 16.0;
    final srcRect = ui.Rect.fromLTWH(0, 0, tileNative, tileNative);
    final tilesX = (size.x / tileDisplay).ceil() + 1;
    final tilesY = (size.y / tileDisplay).ceil() + 1;

    for (int tx = 0; tx < tilesX; tx++) {
      for (int ty = 0; ty < tilesY; ty++) {
        canvas.drawImageRect(
          groundImage,
          srcRect,
          ui.Rect.fromLTWH(
            tx * tileDisplay,
            ty * tileDisplay,
            tileDisplay,
            tileDisplay,
          ),
          _pixelPaint,
        );
      }
    }

    canvas.restore();

    // 细边框
    canvas.drawRRect(
      ui.RRect.fromRectAndRadius(rect, const ui.Radius.circular(8)),
      ui.Paint()
        ..color = const ui.Color(0x55000000)
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  void _drawProgressBar(ui.Canvas canvas, ui.Rect rect) {
    final config = cropRegistry[growingCrop]!;
    final barRect = ui.Rect.fromLTWH(
      rect.left + 8,
      rect.bottom - 11,
      rect.width - 16,
      5,
    );
    canvas.drawRRect(
      ui.RRect.fromRectAndRadius(barRect, const ui.Radius.circular(3)),
      ui.Paint()..color = const ui.Color(0x44000000),
    );
    final progress = (elapsedGrow / config.growSeconds).clamp(0.0, 1.0);
    canvas.drawRRect(
      ui.RRect.fromRectAndRadius(
        ui.Rect.fromLTWH(
          barRect.left,
          barRect.top,
          barRect.width * progress,
          barRect.height,
        ),
        const ui.Radius.circular(3),
      ),
      ui.Paint()..color = const ui.Color(0xFF7CFC00),
    );
  }

  void _drawWitherWarning(
    ui.Canvas canvas,
    ui.Rect rect,
    double witherSeconds,
  ) {
    final remain = 1 - (elapsedRipe / witherSeconds).clamp(0.0, 1.0);
    if (remain > 0.4) return;
    final barRect = ui.Rect.fromLTWH(
      rect.left + 8,
      rect.bottom - 11,
      rect.width - 16,
      5,
    );
    canvas.drawRRect(
      ui.RRect.fromRectAndRadius(barRect, const ui.Radius.circular(3)),
      ui.Paint()..color = const ui.Color(0x44000000),
    );
    canvas.drawRRect(
      ui.RRect.fromRectAndRadius(
        ui.Rect.fromLTWH(
          barRect.left,
          barRect.top,
          barRect.width * remain,
          barRect.height,
        ),
        const ui.Radius.circular(3),
      ),
      ui.Paint()..color = const ui.Color(0xFFFF4444),
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
          game.saveState();
        }
        break;
      case PlotStage.ripe:
        if (growingCrop != null) {
          game.addHarvest(growingCrop!);
          _reset();
          game.saveState();
        }
        break;
      case PlotStage.withered:
        _reset();
        game.saveState();
        break;
      case PlotStage.growing:
        break;
    }
  }

  void _reset() {
    currentStage = PlotStage.empty;
    growingCrop = null;
    elapsedGrow = 0;
    elapsedRipe = 0;
  }
}
