import 'dart:math' as math;

import 'package:anoxia/features/game/models/restaurant_economy.dart';
import 'package:anoxia/features/game/restaurant_level/restaurant_level1.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

class RestaurantGamePage extends StatefulWidget {
  const RestaurantGamePage({super.key});

  @override
  State<RestaurantGamePage> createState() => _RestaurantGamePageState();
}

class _RestaurantGamePageState extends State<RestaurantGamePage> {
  late final RestaurantGame game;

  @override
  void initState() {
    super.initState();
    game = RestaurantGame();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GameWidget<RestaurantGame>(
          game: game,
          loadingBuilder: (_) => const ColoredBox(
            color: Color(0xFFE8F0F2),
            child: Center(child: CircularProgressIndicator()),
          ),
          errorBuilder: (_, error) => ColoredBox(
            color: const Color(0xFFFFEBEE),
            child: Center(child: Text('Restaurant load error:\n$error')),
          ),
        ),
        Positioned(
          left: 12,
          right: 12,
          bottom: 12,
          child: ValueListenableBuilder<RestaurantSnapshot?>(
            valueListenable: game.snapshot,
            builder: (context, value, child) {
              if (value == null) return const SizedBox.shrink();
              return _UpgradePanel(game: game, data: value);
            },
          ),
        ),
      ],
    );
  }
}

class _UpgradePanel extends StatelessWidget {
  const _UpgradePanel({required this.game, required this.data});
  final RestaurantGame game;
  final RestaurantSnapshot data;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xCC17242B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Wrap(
          spacing: 10,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              '等级 ${data.level}  经验 ${data.experience}/${data.experienceToNext}'
              '  人气 ${data.popularity}  菜品 ${data.unlockedRecipes}/5',
              style: const TextStyle(color: Colors.white),
            ),
            FilledButton.tonal(
              onPressed:
                  data.kitchenLevel >= 5 || data.coins < data.kitchenUpgradeCost
                  ? null
                  : game.upgradeKitchen,
              child: Text(
                data.kitchenLevel >= 5
                    ? '厨房 Lv.5'
                    : '升级厨房 Lv.${data.kitchenLevel} (${data.kitchenUpgradeCost}金币)',
              ),
            ),
            FilledButton.tonal(
              onPressed:
                  data.cashierLevel >= 5 || data.coins < data.cashierUpgradeCost
                  ? null
                  : game.upgradeCashier,
              child: Text(
                data.cashierLevel >= 5
                    ? '银台 Lv.5'
                    : '升级银台 Lv.${data.cashierLevel} (${data.cashierUpgradeCost}金币)',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RestaurantGame extends FlameGame {
  static const bool enableDebugMode = true;
  static const characterNames = [
    'waiter',
    'womanwaiter',
    'aunt',
    'uncle',
    'boy',
    'girl',
    'cleaner',
    'cop',
    'oldman',
    'oldwoman',
    'yongman',
    'yongwoman',
  ];

  final snapshot = ValueNotifier<RestaurantSnapshot?>(null);
  RestaurantLevel1? _level;
  late final TextComponent _hud;
  double _snapshotTimer = 0;

  @override
  Color backgroundColor() => const Color(0xFFE8F0F2);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    debugMode = enableDebugMode;
    await images.loadAll([
      for (final name in characterNames) 'flame_sprites/${name}_anim_sheet.png',
    ]);
    final level = RestaurantLevel1();
    _level = level;
    world = level;
    await level.loaded;
    _hud = TextComponent(
      position: Vector2(16, 16),
      priority: 100000,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
          shadows: [Shadow(color: Colors.black, blurRadius: 4)],
        ),
      ),
    );
    await camera.viewport.add(_hud);
    _publishSnapshot();
    _fitCameraToLevel();
  }

  @override
  void update(double dt) {
    super.update(dt);
    final level = _level;
    if (level == null || !_hud.isMounted) return;
    _hud.text =
        '金币 ${level.coins}   完成 ${level.completedOrders}   流失 ${level.lostCustomers}\n'
        '顾客 ${level.activeCustomers}   等位 ${level.waitingCustomers}   ${level.phaseLabel}';
    _snapshotTimer -= dt;
    if (_snapshotTimer <= 0) {
      _snapshotTimer = .25;
      _publishSnapshot();
    }
  }

  void upgradeKitchen() {
    _level?.upgradeKitchen();
    _publishSnapshot();
  }

  void upgradeCashier() {
    _level?.upgradeCashier();
    _publishSnapshot();
  }

  void _publishSnapshot() {
    final level = _level;
    if (level != null) snapshot.value = level.snapshot;
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _fitCameraToLevel();
  }

  void _fitCameraToLevel() {
    final level = _level;
    if (level == null || !level.isLoaded || level.mapVisualSize.isZero()) {
      return;
    }
    final zoom = math.max(
      size.x / level.mapVisualSize.x,
      size.y / level.mapVisualSize.y,
    );
    camera.viewfinder
      ..anchor = Anchor.center
      ..position = level.mapVisualCenter
      ..visibleGameSize = null
      ..zoom = zoom;
  }
}
