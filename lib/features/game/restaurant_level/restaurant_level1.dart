import 'dart:math';
import 'package:anoxia/features/game/components/my_waiter.dart';
import 'package:anoxia/features/game/components/facility_placement_controller.dart';
import 'package:anoxia/features/game/components/restaurant_customer.dart';
import 'package:anoxia/features/game/components/restaurant_facility.dart';
import 'package:anoxia/features/game/components/restaurant_map.dart';
import 'package:anoxia/features/game/components/restaurant_person.dart';
import 'package:anoxia/features/game/models/facility_placement.dart';
import 'package:anoxia/features/game/models/restaurant_level_config.dart';
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
  RestaurantLevel1({RestaurantLevelConfig? config})
    : config = config ?? level1Config;

  final RestaurantLevelConfig config;

  late final RestaurantMap map;
  late final MyWaiter waiter;
  late final RestaurantFacility kitchenFacility;
  late final RestaurantFacility cashierFacility;
  late final FacilityPlacementController placementController;
  final facilities = <RestaurantFacility>[];
  final tables = <_RestaurantTable>[];
  final customers = <_CustomerSession>[];
  final _taskQueue = <_WaiterTask>[];
  final _random = Random();
  _WaiterTask? _activeTask;
  int _nextCustomerId = 1;
  double _spawnTimer = 1;
  double _cashierTimer = 0;
  int _kitchenVisualState = -1;
  bool editMode = false;
  RestaurantFacility? selectedFacility;

  int completedOrders = 0;
  int lostCustomers = 0;

  Vector2 get mapVisualSize => map.visualSize;
  Vector2 get mapVisualCenter => map.visualCenter;
  int get activeCustomers => customers.length;
  int get waitingCustomers =>
      customers.where((c) => c.orderState == OrderState.waitingForTable).length;
  String get phaseLabel =>
      _activeTask == null ? '服务员空闲' : '服务员：${_taskLabel(_activeTask!.type)}';

  void setEditMode(bool value) {
    editMode = value;
    if (value) {
      for (final session in customers) {
        session.customer.removeFromParent();
      }
      customers.clear();
      _taskQueue.clear();
      _activeTask = null;
      for (final table in tables) {
        table
          ..state = TableState.available
          ..customerId = null;
        table.facility.showFrame(0);
      }
      waiter.stop();
      kitchenFacility.showFrame(1);
      _kitchenVisualState = 0;
      _spawnTimer = 1;
    }
    for (final facility in facilities) {
      facility
        ..editable = value
        ..debugMode = value;
      if (!value) facility.selected = false;
    }
    if (!value) selectedFacility = null;
  }

  void rotateSelectedFacility() {
    selectedFacility?.rotateOrientation();
  }

  PlacementResult _requestFacilityMove(
    RestaurantFacility facility,
    Vector2 position,
  ) => placementController.tryMove(facility, position);

  bool _requestFacilityRotate(RestaurantFacility facility) =>
      placementController.canRotate(facility);

  void _facilityPlacementChanged() {
    placementController.refreshObstacles();
  }

  void _selectFacility(RestaurantFacility facility) {
    selectedFacility = facility;
    for (final item in facilities) {
      item.selected = identical(item, facility);
    }
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    map = RestaurantMap(mapFile: config.mapFile);
    await add(map);
    waiter = MyWaiter()
      ..position = map.spawnPoint('waiter_spawn', fallback: Vector2(250, 110));
    await add(waiter);
    // 家具完全由关卡配置生成。扩展地图时不需要复制这段初始化代码。
    for (final facilityConfig in config.facilities) {
      facilities.add(
        RestaurantFacility(
          config: facilityConfig,
          position: map.spawnPoint(facilityConfig.spawnName),
          onSelected: _selectFacility,
          onMoveRequested: _requestFacilityMove,
          onRotateRequested: _requestFacilityRotate,
          onPlacementChanged: _facilityPlacementChanged,
        ),
      );
    }
    placementController = FacilityPlacementController(
      map: map,
      facilities: facilities,
    );
    await addAll(facilities);
    kitchenFacility = facilities.singleWhere(
      (item) => item.config.type == FacilityType.kitchen,
    );
    cashierFacility = facilities.singleWhere(
      (item) => item.config.type == FacilityType.cashier,
    );
    tables.addAll(
      facilities
          .where((item) => item.config.type == FacilityType.table)
          .toList()
          .asMap()
          .entries
          .map((entry) => _RestaurantTable(entry.key + 1, entry.value)),
    );
    placementController
      ..refreshObstacles()
      ..printLayout();
    await addAll([
      RestaurantPerson(
        characterName: 'cleaner',
        position: map.spawnPoint('cleaner_spawn', fallback: Vector2(330, 120)),
      ),
    ]);
    debugPrint('[餐厅关卡] ${config.id} 加载完成，共 ${tables.length} 张桌子');
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (editMode) return;
    _updateSpawner(dt);
    _updateCustomers(dt);
    _updateCashier(dt);
    _updateWaiter(dt);
    _updateKitchenVisual();
    _seatWaitingCustomers();
    customers.removeWhere((session) => session.customer.isRemoved);
  }

  void _updateSpawner(double dt) {
    _spawnTimer -= dt;
    if (_spawnTimer > 0 || customers.length >= config.maxCustomers) return;
    if (_availableTable() == null) {
      _spawnTimer = .5;
      return;
    }
    _spawnTimer = 4 + _random.nextDouble() * 2;
    _spawnCustomer();
  }

  void _spawnCustomer() {
    final id = _nextCustomerId++;
    final table = _availableTable();
    if (table == null) return;
    final seat = map.clampToPlayableArea(table.seatPosition, margin: 8);
    final customer = RestaurantCustomer(
      customerId: id,
      characterName:
          config.customerNames[(id - 1) % config.customerNames.length],
      position: seat,
    );
    final session = _CustomerSession(customer);
    customers.add(session);
    add(customer);
    customer.loaded.then((_) {
      if (customer.isRemoved) return;
      _assignTable(session, table);
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
            session.table!.facility.showFrame(2);
            session.orderState = OrderState.waitingToPay;
            session.customer.changeState(CustomerState.queueing);
            session.customer.position = _cashierQueuePoint(session);
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
      current.customer.position = map.clampToPlayableArea(
        cashierFacility.position + Vector2(0, 10),
        margin: 8,
      );
      _cashierTimer = 1.5;
      return;
    }
    if (current.customer.isMoving) return;
    _cashierTimer -= dt;
    if (_cashierTimer > 0) return;
    completedOrders++;
    final table = current.table!;
    table.state = TableState.dirty;
    table.customerId = null;
    current.orderState = OrderState.leaving;
    current.customer.changeState(CustomerState.leaving);
    current.customer.removeFromParent();
    _enqueueTask(WaiterTaskType.cleanTable, current);
    debugPrint('[Restaurant] customer#${current.id} checkout complete');
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
        _moveWaiter(
          map.clampToPlayableArea(session.table!.servicePosition, margin: 8),
        );
      case WaiterTaskType.deliverFood:
        _moveWaiter(_kitchenServicePosition);
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
          _moveWaiter(_kitchenServicePosition);
          return;
        }
        session.orderState = OrderState.cooking;
        session.timer = 2.8;
        _finishTask();
      case WaiterTaskType.deliverFood:
        if (task.stage == 0) {
          task.stage = 1;
          task.actionTimer = .5;
          waiter.changeState(WaiterState.carryingFood);
          // Food leaves the kitchen as soon as the waiter picks it up.
          session.orderState = OrderState.ready;
          return;
        }
        if (task.stage == 1) {
          task.stage = 2;
          _moveWaiter(
            map.clampToPlayableArea(session.table!.servicePosition, margin: 8),
            carryingFood: true,
          );
          return;
        }
        waiter.changeState(WaiterState.idle);
        session.orderState = OrderState.eating;
        session.timer = 3 + _random.nextDouble() * 2;
        session.customer.changeState(CustomerState.eating);
        session.table!.facility.showFrame(1);
        _finishTask();
      case WaiterTaskType.cleanTable:
        if (task.stage == 0) {
          task.stage = 1;
          task.actionTimer = 1.5;
          session.table!.state = TableState.cleaning;
          return;
        }
        session.table!.state = TableState.available;
        session.table!.facility.showFrame(0);
        session.table = null;
        debugPrint('[Restaurant] table cleaned');
        _finishTask();
    }
  }

  void _finishTask() {
    _activeTask = null;
  }

  void _updateKitchenVisual() {
    final hasCooking = customers.any(
      (session) => session.orderState == OrderState.cooking,
    );
    final hasReadyFood = customers.any(
      (session) => session.orderState == OrderState.deliveryQueued,
    );
    final nextState = hasCooking ? 1 : (hasReadyFood ? 2 : 0);
    if (nextState == _kitchenVisualState) return;
    _kitchenVisualState = nextState;
    if (nextState == 1) {
      kitchenFacility.animateFrames(const [1, 2]);
    } else if (nextState == 2) {
      kitchenFacility.showFrame(3);
    } else {
      // Frame 1 contains the chef standing inside the separated kitchen.
      kitchenFacility.showFrame(1);
    }
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
      ..orderState = OrderState.waitingToOrder
      ..timer = 1 + _random.nextDouble();
    session.customer
      ..position = map.clampToPlayableArea(table.seatPosition, margin: 8)
      ..changeState(CustomerState.seated);
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

  Vector2 _cashierQueuePoint(_CustomerSession session) {
    final count = customers
        .where(
          (c) =>
              c.orderState == OrderState.goingToCashier ||
              c.orderState == OrderState.waitingToPay ||
              c.orderState == OrderState.paying,
        )
        .length;
    return map.clampToPlayableArea(
      cashierFacility.position +
          Vector2(count <= 1 ? -18 : -34, count <= 1 ? 12 : 20),
      margin: 8,
    );
  }

  Vector2 get _kitchenServicePosition => map.clampToPlayableArea(
    kitchenFacility.position +
        Vector2(kitchenFacility.isVertical ? -55 : 55, 14),
    margin: 8,
  );

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
  _RestaurantTable(this.id, this.facility);
  final int id;
  final RestaurantFacility facility;
  Vector2 get seatPosition =>
      facility.position + Vector2(facility.isVertical ? -28 : 28, -26);
  Vector2 get servicePosition =>
      facility.position + Vector2(facility.isVertical ? 6 : -6, 13);
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
