import 'package:anoxia/features/game/components/my_waiter.dart';
import 'package:anoxia/features/game/components/restaurant_map.dart';
import 'package:anoxia/features/game/components/restaurant_person.dart';
import 'package:flame/components.dart';

class RestaurantLevel1 extends World {
  late final RestaurantMap map;
  late final MyWaiter waiter;

  Vector2 get mapVisualSize => map.visualSize;
  Vector2 get mapVisualCenter => map.visualCenter;

  final List<String> _autoRoute = [
    'door_spawn',
    'customer_spawn',
    'waiter_spawn',
  ];

  var _routeIndex = 0;
  var _routeWait = 0.5;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    map = RestaurantMap();
    await add(map);

    waiter = MyWaiter()
      ..position = map.spawnPoint('waiter_spawn', fallback: Vector2(120, 120));
    await add(waiter);

    // Spawn points describe people positions too; previously they were only
    // used as waypoints, so roles such as the cashier never appeared.
    await addAll([
      RestaurantPerson(
        characterName: 'womanwaiter',
        position: map.spawnPoint('cashier_spawn', fallback: Vector2(164, 61)),
      ),
      RestaurantPerson(
        characterName: 'yongman',
        position: map.spawnPoint('customer_spawn', fallback: Vector2(102, 53)),
      ),
    ]);
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (waiter.isMoving) return;

    _routeWait -= dt;
    if (_routeWait > 0) return;

    _sendWaiterToNextPoint();
    _routeWait = 1;
  }

  void _sendWaiterToNextPoint() {
    if (_autoRoute.isEmpty) return;

    final targetName = _autoRoute[_routeIndex];
    _routeIndex = (_routeIndex + 1) % _autoRoute.length;

    final target = map.spawnPoint(targetName, fallback: waiter.position);
    final path = map.findPath(waiter.position, target);
    if (path.isNotEmpty) {
      waiter.followPath(path);
    }
  }
}
