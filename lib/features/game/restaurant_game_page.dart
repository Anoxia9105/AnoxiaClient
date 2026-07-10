import 'dart:math' as math;

import 'package:anoxia/features/game/restaurant_level/restaurant_level1.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

class RestaurantGamePage extends StatelessWidget {
  const RestaurantGamePage({super.key});

  @override
  Widget build(BuildContext context) {
    return GameWidget<RestaurantGame>.controlled(
      gameFactory: RestaurantGame.new,
      loadingBuilder: (_) => const ColoredBox(
        color: Color(0xFFE8F0F2),
        child: Center(child: CircularProgressIndicator()),
      ),
      errorBuilder: (_, error) => ColoredBox(
        color: const Color(0xFFFFEBEE),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'RestaurantGame load error:\n$error',
              style: const TextStyle(color: Color(0xFFB71C1C)),
            ),
          ),
        ),
      ),
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

  @override
  Color backgroundColor() => const Color(0xFFE8F0F2);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await images.loadAll([
      for (final name in characterNames) 'flame_sprites/${name}_anim_sheet.png',
    ]);

    final level1 = RestaurantLevel1();
    _level = level1;
    world = level1;
    await level1.loaded;
    _fitCameraToLevel();
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
