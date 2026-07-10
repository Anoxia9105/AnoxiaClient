import 'package:anoxia/features/game/components/my_waiter.dart';
import 'package:flame/components.dart';

class RestaurantLevel1 extends World {
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    final waiter = MyWaiter();
    await add(waiter);
  }
}
