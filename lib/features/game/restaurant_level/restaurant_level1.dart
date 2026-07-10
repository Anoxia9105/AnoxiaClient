import 'package:anoxia/features/game/components/my_waiter.dart';
import 'package:anoxia/features/game/components/restaurant_map.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';

class RestaurantLevel1 extends World with TapCallbacks {
  late final RestaurantMap map;
  late final MyWaiter waiter;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    map = RestaurantMap();
    await add(map);

    waiter = MyWaiter()
      ..position = map.spawnPoint('waiter_spawn', fallback: Vector2(120, 120));
    await add(waiter);
  }

  @override
  void onTapDown(TapDownEvent event) {
    final pos = event.localPosition;

    if (map.isWalkableAt(pos)) {
      waiter.moveTo(pos);
    }
  }
}
