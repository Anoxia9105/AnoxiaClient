import 'package:anoxia/features/game/components/my_waiter.dart';
import 'package:anoxia/features/game/components/restaurant_character_preview.dart';
import 'package:anoxia/features/game/components/restaurant_map.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';

class RestaurantLevel1 extends World with TapCallbacks {
  static const _characterNames = [
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

  late final RestaurantMap map;
  late final MyWaiter waiter;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    map = RestaurantMap();
    await add(map);

    waiter = MyWaiter()..position = map.gridToWorld(2, 2);
    await add(waiter);

    waiter.changeState(WaiterState.walking);

    Future.delayed(const Duration(seconds: 4), () {
      waiter.changeState(WaiterState.carryingFood);
    });

    Future.delayed(const Duration(seconds: 8), () {
      waiter.changeState(WaiterState.idle);
    });

    for (var i = 0; i < _characterNames.length; i++) {
      final col = i % 4;
      final row = i ~/ 4;
      await add(
        RestaurantCharacterPreview(
          characterName: _characterNames[i],
          position: Vector2(180 + col * 130, 20 + row * 150),
          previewScale: 2.0,
        ),
      );
    }
  }

  @override
  void onTapDown(TapDownEvent event) {
    final pos = event.localPosition;
    final col = (pos.x / RestaurantMap.cellSize).floor();
    final row = (pos.y / RestaurantMap.cellSize).floor();

    if (map.isWalkable(col, row)) {
      waiter.moveTo(map.gridToWorld(col, row));
    }
  }
}
