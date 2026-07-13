import 'dart:math' as math;

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
  bool editing = false;

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
          right: 12,
          bottom: 12,
          child: Row(
            children: [
              if (editing)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilledButton.tonalIcon(
                    onPressed: game.rotateSelectedFacility,
                    icon: const Icon(Icons.rotate_90_degrees_cw),
                    label: const Text('旋转选中家具'),
                  ),
                ),
              FilledButton.icon(
                onPressed: () {
                  setState(() => editing = !editing);
                  game.setEditMode(editing);
                },
                icon: Icon(editing ? Icons.check : Icons.chair_alt),
                label: Text(editing ? '完成摆放' : '摆放家具'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class RestaurantGame extends FlameGame {
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

  RestaurantLevel1? _level;
  late final TextComponent _hud;

  @override
  Color backgroundColor() => const Color(0xFFE8F0F2);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
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
    _fitCameraToLevel();
  }

  @override
  void update(double dt) {
    super.update(dt);
    final level = _level;
    if (level == null || !_hud.isMounted) return;
    _hud.text = level.editMode
        ? '摆放模式：点击家具后拖动，红色占地框表示当前位置不可用'
        : '完成 ${level.completedOrders}   顾客 ${level.activeCustomers}   ${level.phaseLabel}';
  }

  void setEditMode(bool value) => _level?.setEditMode(value);
  void rotateSelectedFacility() => _level?.rotateSelectedFacility();

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
