import 'dart:async';
import 'package:flame/camera.dart';
import 'package:flame/components.dart';
import 'package:restaurant_game/component/sprite/waiter.dart';
import 'package:restaurant_game/component/sprite/woman_waiter.dart';

class Level1 extends World {
  @override
  FutureOr<void> onLoad() {
    //load waiter sprite
    // final waiter = Waiter();
    final woman_waiter = WomanWaiter();
    addAll([
      // waiter,
      woman_waiter,
    ]);

    return super.onLoad();
  }
}
