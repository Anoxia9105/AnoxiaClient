import 'package:anoxia/features/game/farm_game_page.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

class GamePage extends StatefulWidget {
  const GamePage({super.key});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  @override
  Widget build(BuildContext context) {
    return GameWidget(game: FarmGamePage());
  }
}
