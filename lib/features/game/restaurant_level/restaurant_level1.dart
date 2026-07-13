import 'dart:math';

import 'package:anoxia/features/game/components/my_waiter.dart';
import 'package:anoxia/features/game/components/restaurant_customer.dart';
import 'package:anoxia/features/game/components/restaurant_map.dart';
import 'package:anoxia/features/game/components/restaurant_person.dart';
import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';

enum TableState { available, occupied, dirty, cleaning }

enum OrderState {
  entering,
  waitingForTable,
  waitingToOrder,
  orderQueued,
  cooking,
  ready,
  deliveryQueued,
  eating,
  goingToCashier,
  waitingToPay,
  paying,
  leaving,
}

enum WaiterTaskType { takeOrder, deliverFood, cleanTable }

class RestaurantLevel1 extends World {
  static const _customerNames = ['yongman', 'yongwoman', 'aunt', 'uncle'];
  static const _maxCustomers = 5;

  late final RestaurantMap map;
  late final MyWaiter waiter;
  final tables = <_RestaurantTable>[];
  final customers = <_CustomerSession>[];
  final _taskQueue = <_WaiterTask>[];
  final _random = Random();
  _WaiterTask? _activeTask;
  int _nextCustomerId = 1;
  double _spawnTimer = 1;
  double _cashierTimer = 0;

  int coins = 0;
  int completedOrders = 0;
  int lostCustomers = 0;
  Vector2 get mapVisualSize => map.visualSize;
  Vector2 get mapVisualCenter => map.visualCenter;
  int get activeCustomers => customers.length;
  int get waitingCustomers =>
      customers.where((c) => c.orderState == OrderState.waitingForTable).length;
  String get phaseLabel =>
      _activeTask == null ? '服务员空闲' : '服务员：${_taskLabel(_activeTask!.type)}';

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    map = RestaurantMap();
    await add(map);
    waiter = MyWaiter()
      ..position = map.spawnPoint('waiter_spawn', fallback: Vector2(250, 110));
    await add(waiter);
    tables.addAll([
      _RestaurantTable(1, 'table_1_seat', 'table_1_service'),
      _RestaurantTable(2, 'table_2_seat', 'table_2_service'),
    ]);
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
    debugPrint('[Restaurant] stage 2 opened with ${tables.length} tables');
  }

  @override
  void update(double dt) {
    super.update(dt);
    _updateSpawner(dt);
    _updateCustomers(dt);
    _updateCashier(dt);
    _updateWaiter(dt);
    _seatWaitingCustomers();
    customers.removeWhere((session) => session.customer.isRemoved);
  }

  void _updateSpawner(double dt) {
    _spawnTimer -= dt;
    if (_spawnTimer > 0 || customers.length >= _maxCustomers) return;
    _spawnTimer = 4 + _random.nextDouble() * 2;
    _spawnCustomer();
  }

  void _spawnCustomer() {
    final id = _nextCustomerId++;
    final door = map.spawnPoint('door_spawn', fallback: Vector2(370, 200));
    final customer = RestaurantCustomer(
      customerId: id,
      characterName: _customerNames[(id - 1) % _customerNames.length],
      position: door,
    );
    final session = _CustomerSession(customer);
    customers.add(session);
    add(customer);
    customer.loaded.then((_) {
      if (customer.isRemoved) return;
      final table = _availableTable();
      if (table == null) {
        session.orderState = OrderState.waitingForTable;
        customer.changeState(CustomerState.waitingForTable);
        _moveCustomer(session, _waitingPoint(session));
      } else {
        _assignTable(session, table);
      }
    });
  }

  void _updateCustomers(double dt) {
    for (final session in List<_CustomerSession>.of(customers)) {
      switch (session.orderState) {
        case OrderState.entering:
          if (!session.customer.isMoving && session.table != null) {
            session.customer.changeState(CustomerState.seated);
            session.orderState = OrderState.waitingToOrder;
            session.timer = 1 + _random.nextDouble();
          }
        case OrderState.waitingForTable:
          session.patience -= dt;
          if (session.patience <= 0) _customerGivesUp(session);
        case OrderState.waitingToOrder:
          session.timer -= dt;
          if (session.timer <= 0) {
            session.orderState = OrderState.orderQueued;
            session.customer.changeState(CustomerState.waiting);
            _enqueueTask(WaiterTaskType.takeOrder, session);
          }
        case OrderState.cooking:
          session.timer -= dt;
          if (session.timer <= 0) {
            session.orderState = OrderState.deliveryQueued;
            _enqueueTask(WaiterTaskType.deliverFood, session);
          }
        case OrderState.eating:
          session.timer -= dt;
          if (session.timer <= 0) {
            session.orderState = OrderState.goingToCashier;
            session.customer.changeState(CustomerState.queueing);
            _moveCustomer(session, _cashierQueuePoint(session));
          }
        case OrderState.goingToCashier:
          if (!session.customer.isMoving) {
            session.orderState = OrderState.waitingToPay;
          }
        case OrderState.leaving:
          if (!session.customer.isMoving) {
            session.customer.removeFromParent();
          }
        case OrderState.orderQueued:
        case OrderState.ready:
        case OrderState.deliveryQueued:
        case OrderState.waitingToPay:
        case OrderState.paying:
          break;
      }
    }
  }

  void _updateCashier(double dt) {
    final queue =
        customers
            .where(
              (c) =>
                  c.orderState == OrderState.waitingToPay ||
                  c.orderState == OrderState.paying,
            )
            .toList()
          ..sort((a, b) => a.id.compareTo(b.id));
    if (queue.isEmpty) {
      _cashierTimer = 0;
      return;
    }
    final current = queue.first;
    if (current.orderState == OrderState.waitingToPay) {
      current.orderState = OrderState.paying;
      current.customer.changeState(CustomerState.paying);
      _moveCustomer(current, map.spawnPoint('cashier_customer'));
      _cashierTimer = 1.5;
      return;
    }
    if (current.customer.isMoving) return;
    _cashierTimer -= dt;
    if (_cashierTimer > 0) return;
    coins += 20;
    completedOrders++;
    final table = current.table!;
    table.state = TableState.dirty;
    table.customerId = null;
    current.orderState = OrderState.leaving;
    current.customer.changeState(CustomerState.leaving);
    _moveCustomer(current, map.spawnPoint('door_spawn'));
    _enqueueTask(WaiterTaskType.cleanTable, current);
    debugPrint('[Restaurant] customer#${current.id} paid, coins=$coins');
  }

  void _updateWaiter(double dt) {
    var task = _activeTask;
    if (task == null) {
      if (_taskQueue.isEmpty) return;
      _taskQueue.sort((a, b) => a.priority.compareTo(b.priority));
      task = _taskQueue.removeAt(0);
      _activeTask = task;
      _startTaskStage(task);
      return;
    }
    if (waiter.isMoving) return;
    if (task.actionTimer > 0) {
      task.actionTimer -= dt;
      if (task.actionTimer > 0) return;
    }
    _advanceTask(task);
  }

  void _startTaskStage(_WaiterTask task) {
    final session = task.session;
    switch (task.type) {
      case WaiterTaskType.takeOrder:
      case WaiterTaskType.cleanTable:
        _moveWaiter(map.spawnPoint(session.table!.servicePoint));
      case WaiterTaskType.deliverFood:
        _moveWaiter(map.spawnPoint('kitchen_service'));
    }
  }

  void _advanceTask(_WaiterTask task) {
    final session = task.session;
    switch (task.type) {
      case WaiterTaskType.takeOrder:
        if (task.stage == 0) {
          task.stage = 1;
          task.actionTimer = .8;
          return;
        }
        if (task.stage == 1) {
          task.stage = 2;
          _moveWaiter(map.spawnPoint('kitchen_service'));
          return;
        }
        session.orderState = OrderState.cooking;
        session.timer = 2.5;
        _finishTask();
      case WaiterTaskType.deliverFood:
        if (task.stage == 0) {
          task.stage = 1;
          task.actionTimer = .5;
          waiter.changeState(WaiterState.carryingFood);
          return;
        }
        if (task.stage == 1) {
          task.stage = 2;
          _moveWaiter(
            map.spawnPoint(session.table!.servicePoint),
            carryingFood: true,
          );
          return;
        }
        waiter.changeState(WaiterState.idle);
        session.orderState = OrderState.eating;
        session.timer = 3 + _random.nextDouble() * 2;
        session.customer.changeState(CustomerState.eating);
        _finishTask();
      case WaiterTaskType.cleanTable:
        if (task.stage == 0) {
          task.stage = 1;
          task.actionTimer = 1.5;
          session.table!.state = TableState.cleaning;
          return;
        }
        session.table!.state = TableState.available;
        session.table = null;
        debugPrint('[Restaurant] table cleaned');
        _finishTask();
    }
  }

  void _finishTask() {
    _activeTask = null;
  }

  void _enqueueTask(WaiterTaskType type, _CustomerSession session) {
    if (_taskQueue.any(
          (task) => task.type == type && task.session == session,
        ) ||
        (_activeTask?.type == type && _activeTask?.session == session)) {
      return;
    }
    _taskQueue.add(_WaiterTask(type, session));
  }

  void _seatWaitingCustomers() {
    for (final session in customers.where(
      (c) => c.orderState == OrderState.waitingForTable,
    )) {
      final table = _availableTable();
      if (table == null) return;
      _assignTable(session, table);
    }
  }

  void _assignTable(_CustomerSession session, _RestaurantTable table) {
    table
      ..state = TableState.occupied
      ..customerId = session.id;
    session
      ..table = table
      ..orderState = OrderState.entering;
    session.customer.changeState(CustomerState.entering);
    _moveCustomer(session, map.spawnPoint(table.seatPoint));
    debugPrint(
      '[Restaurant] customer#${session.id} assigned table#${table.id}',
    );
  }

  void _customerGivesUp(_CustomerSession session) {
    lostCustomers++;
    session.orderState = OrderState.leaving;
    session.customer.changeState(CustomerState.leaving);
    _moveCustomer(session, map.spawnPoint('door_spawn'));
    debugPrint('[Restaurant] customer#${session.id} left while waiting');
  }

  _RestaurantTable? _availableTable() {
    for (final table in tables) {
      if (table.state == TableState.available) return table;
    }
    return null;
  }

  Vector2 _waitingPoint(_CustomerSession session) {
    final index = customers
        .where((c) => c.orderState == OrderState.waitingForTable)
        .toList()
        .indexOf(session);
    return map.spawnPoint(index.isEven ? 'waiting_1' : 'waiting_2');
  }

  Vector2 _cashierQueuePoint(_CustomerSession session) {
    final count = customers
        .where(
          (c) =>
              c.orderState == OrderState.goingToCashier ||
              c.orderState == OrderState.waitingToPay ||
              c.orderState == OrderState.paying,
        )
        .length;
    return map.spawnPoint(count <= 1 ? 'cashier_queue_1' : 'cashier_queue_2');
  }

  void _moveCustomer(_CustomerSession session, Vector2 target) {
    final path = map.findPath(session.customer.position, target);
    session.customer.followPath(path.isEmpty ? [target] : path);
  }

  void _moveWaiter(Vector2 target, {bool carryingFood = false}) {
    final path = map.findPath(waiter.position, target);
    waiter.followPath(
      path.isEmpty ? [target] : path,
      movingState: carryingFood
          ? WaiterState.carryingFood
          : WaiterState.walking,
    );
  }

  String _taskLabel(WaiterTaskType type) => switch (type) {
    WaiterTaskType.takeOrder => '接单',
    WaiterTaskType.deliverFood => '上菜',
    WaiterTaskType.cleanTable => '清桌',
  };
}

class _RestaurantTable {
  _RestaurantTable(this.id, this.seatPoint, this.servicePoint);
  final int id;
  final String seatPoint;
  final String servicePoint;
  TableState state = TableState.available;
  int? customerId;
}

class _CustomerSession {
  _CustomerSession(this.customer);
  final RestaurantCustomer customer;
  int get id => customer.customerId;
  OrderState orderState = OrderState.entering;
  _RestaurantTable? table;
  double timer = 0;
  double patience = 18;
}

class _WaiterTask {
  _WaiterTask(this.type, this.session);
  final WaiterTaskType type;
  final _CustomerSession session;
  int stage = 0;
  double actionTimer = 0;
  int get priority => switch (type) {
    WaiterTaskType.deliverFood => 0,
    WaiterTaskType.takeOrder => 1,
    WaiterTaskType.cleanTable => 2,
  };
}
