import 'dart:async';
import 'dart:ui';

import 'package:flame/camera.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:restaurant_game/component/sprite/waiter.dart';

class Level1 extends World {
  @override
  FutureOr<void> onLoad() {
    //load waiter sprite
    final waiter = Waiter();
    add(waiter);

    return super.onLoad();
  }
}
