import 'package:anoxia/features/game/components/my_waiter.dart';
import 'package:anoxia/features/game/components/restaurant_customer.dart';
import 'package:anoxia/features/game/components/restaurant_map.dart';
import 'package:anoxia/features/game/components/restaurant_person.dart';
import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';

enum ServicePhase {
  opening,
  customerEntering,
  waitingToOrder,
  waiterTakingOrder,
  takingOrder,
  waiterToKitchen,
  cooking,
  waiterDelivering,
  eating,
  customerToCashier,
  paying,
  customerLeaving,
  waiterToClean,
  cleaning,
}

class RestaurantLevel1 extends World {
  late final RestaurantMap map;
  late final MyWaiter waiter;
  RestaurantCustomer? customer;

  Vector2 get mapVisualSize => map.visualSize;
  Vector2 get mapVisualCenter => map.visualCenter;
  int coins = 0;
  int completedOrders = 0;
  ServicePhase phase = ServicePhase.opening;
  double _timer = 1;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    map = RestaurantMap();
    await add(map);
    waiter = MyWaiter()
      ..position = map.spawnPoint('waiter_spawn', fallback: Vector2(250, 110));
    await add(waiter);
    await addAll([
      RestaurantPerson(
        characterName: 'womanwaiter',
        position: map.spawnPoint('cashier_spawn', fallback: Vector2(260, 80)),
      ),
      RestaurantPerson(
        characterName: 'cleaner',
        position: map.spawnPoint('cleaner_spawn', fallback: Vector2(330, 120)),
      ),
    ]);
    debugPrint('[MVP] restaurant opened');
  }

  @override
  void update(double dt) {
    super.update(dt);
    switch (phase) {
      case ServicePhase.opening:
        if (_tick(dt)) _spawnCustomer();
      case ServicePhase.customerEntering:
        if (!(customer?.isMoving ?? true)) {
          customer!.changeState(CustomerState.waiting);
          _setPhase(ServicePhase.waitingToOrder, wait: 1.5);
        }
      case ServicePhase.waitingToOrder:
        if (_tick(dt)) {
          _moveWaiter('table_service', ServicePhase.waiterTakingOrder);
        }
      case ServicePhase.waiterTakingOrder:
        if (!waiter.isMoving) _setPhase(ServicePhase.takingOrder, wait: 1);
      case ServicePhase.takingOrder:
        if (_tick(dt)) {
          _moveWaiter('kitchen_service', ServicePhase.waiterToKitchen);
        }
      case ServicePhase.waiterToKitchen:
        if (!waiter.isMoving) _setPhase(ServicePhase.cooking, wait: 2.5);
      case ServicePhase.cooking:
        if (_tick(dt)) {
          waiter.changeState(WaiterState.carryingFood);
          _moveWaiter('table_service', ServicePhase.waiterDelivering);
        }
      case ServicePhase.waiterDelivering:
        if (!waiter.isMoving) {
          waiter.changeState(WaiterState.idle);
          customer!.changeState(CustomerState.eating);
          _setPhase(ServicePhase.eating, wait: 3);
        }
      case ServicePhase.eating:
        if (_tick(dt)) {
          customer!.changeState(CustomerState.paying);
          _moveCustomer('cashier_customer', ServicePhase.customerToCashier);
        }
      case ServicePhase.customerToCashier:
        if (!(customer?.isMoving ?? true)) {
          _setPhase(ServicePhase.paying, wait: 1.5);
        }
      case ServicePhase.paying:
        if (_tick(dt)) {
          coins += 20;
          completedOrders++;
          debugPrint('[MVP] payment complete: +20 coins, total=$coins');
          customer!.changeState(CustomerState.leaving);
          _moveCustomer('door_spawn', ServicePhase.customerLeaving);
        }
      case ServicePhase.customerLeaving:
        if (!(customer?.isMoving ?? true)) {
          customer?.removeFromParent();
          customer = null;
          _moveWaiter('table_service', ServicePhase.waiterToClean);
        }
      case ServicePhase.waiterToClean:
        if (!waiter.isMoving) _setPhase(ServicePhase.cleaning, wait: 1.5);
      case ServicePhase.cleaning:
        if (_tick(dt)) {
          debugPrint('[MVP] table cleaned, ready for next customer');
          _setPhase(ServicePhase.opening, wait: 2);
        }
    }
  }

  bool _tick(double dt) {
    _timer -= dt;
    return _timer <= 0;
  }

  void _setPhase(ServicePhase value, {double wait = 0}) {
    phase = value;
    _timer = wait;
    debugPrint('[MVP] phase -> ${value.name}');
  }

  void _spawnCustomer() {
    final door = map.spawnPoint('door_spawn', fallback: Vector2(370, 200));
    final next = RestaurantCustomer(position: door);
    customer = next;
    add(next);
    next.loaded.then((_) {
      next.changeState(CustomerState.entering);
      _moveCustomer('table_seat', ServicePhase.customerEntering);
    });
  }

  void _moveWaiter(String targetName, ServicePhase nextPhase) {
    final target = map.spawnPoint(targetName, fallback: waiter.position);
    final path = map.findPath(waiter.position, target);
    waiter.followPath(path.isEmpty ? [target] : path);
    _setPhase(nextPhase);
  }

  void _moveCustomer(String targetName, ServicePhase nextPhase) {
    final current = customer;
    if (current == null) return;
    final target = map.spawnPoint(targetName, fallback: current.position);
    final path = map.findPath(current.position, target);
    current.followPath(path.isEmpty ? [target] : path);
    _setPhase(nextPhase);
  }
}
