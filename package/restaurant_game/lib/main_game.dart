import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:restaurant_game/component/level/level1.dart';

class MainGame extends StatefulWidget {
  const MainGame({super.key});

  @override
  State<MainGame> createState() => _MainGameState();
}

class _MainGameState extends State<MainGame> {
  @override
  Widget build(BuildContext context) {
    // return GameWidget(game: MyGame());
    return MaterialApp(
      home: Scaffold(body: GameWidget(game: MyGame())),
    );
  }
}

class MyGame extends FlameGame {
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    final level1 = Level1();
    world = level1;
  }



  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    print('Game resized to: $size');
  }
}
