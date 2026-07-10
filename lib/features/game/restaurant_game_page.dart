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
  @override
  Color backgroundColor() => const Color(0xFFE8F0F2);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await images.load('flame_sprites/waiter_sheet.png');

    final level1 = RestaurantLevel1();
    world = level1;
    camera.viewfinder.anchor = Anchor.topLeft;
  }
}
