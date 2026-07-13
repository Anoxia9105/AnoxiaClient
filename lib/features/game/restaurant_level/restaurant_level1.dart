import 'dart:math';
import 'package:anoxia/features/game/components/my_waiter.dart';
import 'package:anoxia/features/game/components/random_cleaner.dart';
import 'package:anoxia/features/game/components/facility_placement_controller.dart';
import 'package:anoxia/features/game/components/keyboard_waitress.dart';
import 'package:anoxia/features/game/components/restaurant_customer.dart';
import 'package:anoxia/features/game/components/restaurant_facility.dart';
import 'package:anoxia/features/game/components/restaurant_map.dart';
import 'package:anoxia/features/game/models/facility_placement.dart';
import 'package:anoxia/features/game/models/restaurant_business_state.dart';
import 'package:anoxia/features/game/models/restaurant_level_config.dart';
import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';

/// 桌子状态枚举
enum TableState { available, occupied, dirty, cleaning }

/// 顾客订单状态枚举，完整描述顾客从进店到离店的流程
enum OrderState {
  entering,           // 正在走向座位
  waitingForTable,    // 等待分配空桌
  waitingToOrder,     // 已就坐，等待服务员来点单
  orderQueued,        // 已点单，等待服务员将订单送到厨房
  cooking,            // 厨房正在烹饪
  ready,              // 菜品已准备好，等待服务员取餐
  deliveryQueued,     // 已通知服务员送餐，等待执行
  eating,             // 正在用餐
  goingToCashier,     // 前往收银台
  waitingToPay,       // 在收银台排队等待结账
  paying,             // 正在结账
  leaving,            // 离开餐厅（动画中）
}

/// 服务员任务类型
enum WaiterTaskType { takeOrder, deliverFood, cleanTable }

/// 餐厅第一关的世界组件。
/// 负责管理顾客生成、服务员任务调度、桌子分配、设施交互以及业务状态同步。
class RestaurantLevel1 extends World {
  RestaurantLevel1({RestaurantLevelConfig? config, this.business})
      : config = config ?? level1Config;

  /// 关卡配置（包含地图、设施、顾客名称等）
  final RestaurantLevelConfig config;

  /// 业务状态（经营数据，如是否开门、拥有设施数量等），可为空（用于编辑模式）
  final RestaurantBusinessState? business;

  // ---------- 核心组件 ----------
  late final RestaurantMap map;               // 地图（包含碰撞与寻路）
  late final MyWaiter waiter;                // 服务员（主要角色）
  late final RandomCleaner cleaner;          // 自动清洁工
  late final KeyboardWaitress keyboardWaitress; // 键盘操控的辅助服务员（调试用）
  late final RestaurantFacility kitchenFacility; // 厨房设施
  late final RestaurantFacility cashierFacility; // 收银台设施
  late final FacilityPlacementController placementController; // 设施摆放控制器

  // ---------- 数据集合 ----------
  final facilities = <RestaurantFacility>[];   // 所有设施
  final tables = <_RestaurantTable>[];        // 所有餐桌（封装了设施）
  final customers = <_CustomerSession>[];      // 当前顾客会话列表
  final _taskQueue = <_WaiterTask>[];          // 服务员任务队列
  final _random = Random();                    // 随机数生成器
  _WaiterTask? _activeTask;                    // 当前正在执行的任务
  int _nextCustomerId = 1;                     // 下一个顾客编号
  double _spawnTimer = 1;                      // 顾客生成计时器
  double _cashierTimer = 0;                    // 收银台结账计时器
  int _kitchenVisualState = -1;                // 厨房动画状态（0空闲，1烹饪，2出餐）
  String _facilityOwnershipKey = '';           // 设施拥有状态的缓存键，用于减少更新
  bool editMode = false;                       // 是否为编辑模式（布局摆放）
  RestaurantFacility? selectedFacility;        // 当前选中的设施（编辑模式用）

  // ---------- 经营统计 ----------
  int completedOrders = 0;      // 完成订单数
  int lostCustomers = 0;       // 流失顾客数

  // ---------- 便捷计算属性 ----------
  Vector2 get mapVisualSize => map.visualSize;
  Vector2 get mapVisualCenter => map.visualCenter;
  int get activeCustomers => customers.length;
  int get waitingCustomers =>
      customers.where((c) => c.orderState == OrderState.waitingForTable).length;
  String get phaseLabel =>
      _activeTask == null ? '服务员空闲' : '服务员：${_taskLabel(_activeTask!.type)}';

  /// 设置编辑模式（开启/关闭）。
  /// 开启时清空顾客、任务，重置所有桌子和服务员状态，并允许设施拖动。
  void setEditMode(bool value) {
    editMode = value;
    if (value) {
      // 移除所有顾客
      for (final session in customers) {
        session.customer.removeFromParent();
      }
      customers.clear();
      _taskQueue.clear();
      _activeTask = null;
      // 重置所有桌子为空闲
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
    // 切换所有设施的编辑/调试显示
    for (final facility in facilities) {
      facility
        ..editable = value
        ..debugMode = true; // 编辑模式下强制显示占地和锚点
      if (!value) facility.selected = false;
    }
    if (!value) selectedFacility = null;
  }

  /// 旋转当前选中的设施（编辑模式下调用）
  void rotateSelectedFacility() {
    selectedFacility?.rotateOrientation();
  }

  // ---------- 设施移动/旋转的回调函数 ----------
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

  // ---------- 生命周期 ----------
  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // 加载地图
    map = RestaurantMap(mapFile: config.mapFile);
    await add(map);

    // 创建服务员，位置从地图生成点获取
    waiter = MyWaiter()
      ..position = map.spawnPoint('waiter_spawn', fallback: Vector2(250, 110));
    await add(waiter);

    // 根据关卡配置创建所有设施
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

    // 初始化设施摆放控制器
    placementController = FacilityPlacementController(
      map: map,
      facilities: facilities,
    );
    await addAll(facilities);

    // 获取厨房和收银台引用（假设各只有一个）
    kitchenFacility = facilities.singleWhere(
          (item) => item.config.type == FacilityType.kitchen,
    );
    cashierFacility = facilities.singleWhere(
          (item) => item.config.type == FacilityType.cashier,
    );

    // 从设施列表中提取所有桌子，封装为 _RestaurantTable
    tables.addAll(
      facilities
          .where((item) => item.config.type == FacilityType.table)
          .toList()
          .asMap()
          .entries
          .map((entry) => _RestaurantTable(entry.key + 1, entry.value)),
    );

    placementController.printLayout();
    _syncOwnedFacilities(force: true);

    // 创建键盘操控的服务员（调试用）
    keyboardWaitress = KeyboardWaitress(
      map: map,
      position:
      map.spawnPoint('waiter_spawn', fallback: Vector2(250, 110)) +
          Vector2(28, 12),
    );
    await add(keyboardWaitress);

    // 创建自动清洁工
    cleaner = RandomCleaner(
      map: map,
      position: map.spawnPoint('cleaner_spawn', fallback: Vector2(330, 120)),
    );
    await add(cleaner);

    debugPrint('[餐厅关卡] ${config.id} 加载完成，共 ${tables.length} 张桌子');
  }

  @override
  void update(double dt) {
    super.update(dt);

    // 同步设施拥有状态（根据业务数据更新可见性）
    _syncOwnedFacilities();

    // 根据业务状态显示/隐藏服务员和清洁工
    waiter.opacity = business?.waiterHired == false ? 0 : 1;
    cleaner.opacity = business?.cleanerHired == false ? 0 : 1;
    cleaner.enabled =
        business?.shopOpen == true && business?.cleanerHired == true;

    // 编辑模式或商店关闭时不更新游戏逻辑
    if (editMode || business?.shopOpen == false) return;

    // 更新各个子系统
    _updateSpawner(dt);
    _updateCustomers(dt);
    _updateCashier(dt);
    _updateWaiter(dt);
    _updateKitchenVisual();
    _seatWaitingCustomers();

    // 移除已离开的顾客
    customers.removeWhere((session) => session.customer.isRemoved);
  }

  /// 同步设施拥有状态（根据业务数据决定哪些设施处于激活状态）
  void _syncOwnedFacilities({bool force = false}) {
    final state = business;
    if (state == null) {
      if (force) placementController.refreshObstacles();
      return;
    }
    // 计算拥有状态的缓存键，避免频繁更新
    final key =
        '${state.tablesOwned}-${state.kitchenOwned}-${state.cashierOwned}';
    if (!force && key == _facilityOwnershipKey) return;
    _facilityOwnershipKey = key;

    for (final facility in facilities) {
      facility.active = switch (facility.config.type) {
        FacilityType.table => state.tablesOwned,
        FacilityType.kitchen => state.kitchenOwned,
        FacilityType.cashier => state.cashierOwned,
        FacilityType.toilet || FacilityType.decoration => true,
      };
    }
    placementController.refreshObstacles();
  }

  // ---------- 顾客生成 ----------
  void _updateSpawner(double dt) {
    _spawnTimer -= dt;
    if (_spawnTimer > 0 || customers.length >= config.maxCustomers) return;
    if (_availableTable() == null) {
      _spawnTimer = .5; // 无空桌时快速重试
      return;
    }
    _spawnTimer = 4 + _random.nextDouble() * 2; // 随机间隔
    _spawnCustomer();
  }

  /// 生成一个顾客，并为其分配座位
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
    // 等待顾客加载完成后再分配桌子（此时顾客已就坐）
    customer.loaded.then((_) {
      if (customer.isRemoved) return;
      _assignTable(session, table);
    });
  }

  // ---------- 顾客状态更新 ----------
  void _updateCustomers(double dt) {
    for (final session in List<_CustomerSession>.of(customers)) {
      switch (session.orderState) {
        case OrderState.entering:
        // 顾客移动到座位后改为就坐状态
          if (!session.customer.isMoving && session.table != null) {
            session.customer.changeState(CustomerState.seated);
            session.orderState = OrderState.waitingToOrder;
            session.timer = 1 + _random.nextDouble(); // 等待点单时间
          }
        case OrderState.waitingForTable:
        // 等待空桌时耐心减少
          session.patience -= dt;
          if (session.patience <= 0) _customerGivesUp(session);
        case OrderState.waitingToOrder:
        // 等待服务员来点单
          session.timer -= dt;
          if (session.timer <= 0) {
            session.orderState = OrderState.orderQueued;
            session.customer.changeState(CustomerState.waiting);
            _enqueueTask(WaiterTaskType.takeOrder, session);
          }
        case OrderState.cooking:
        // 等待烹饪完成
          session.timer -= dt;
          if (session.timer <= 0) {
            session.orderState = OrderState.deliveryQueued;
            _enqueueTask(WaiterTaskType.deliverFood, session);
          }
        case OrderState.eating:
        // 用餐时间
          session.timer -= dt;
          if (session.timer <= 0) {
            session.table!.facility.showFrame(2); // 桌子变脏
            session.orderState = OrderState.waitingToPay;
            session.customer.changeState(CustomerState.queueing);
            session.customer.position = _cashierQueuePoint(session);
          }
        case OrderState.goingToCashier:
        // 移动到收银台
          if (!session.customer.isMoving) {
            session.orderState = OrderState.waitingToPay;
          }
        case OrderState.leaving:
        // 离店，移除组件
          if (!session.customer.isMoving) {
            session.customer.removeFromParent();
          }
        case OrderState.orderQueued:
        case OrderState.ready:
        case OrderState.deliveryQueued:
        case OrderState.waitingToPay:
        case OrderState.paying:
        // 这些状态由其他逻辑驱动
          break;
      }
    }
  }

  // ---------- 收银台处理 ----------
  void _updateCashier(double dt) {
    // 获取排队结账的顾客（按ID排序，保持队列顺序）
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
      // 开始结账
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

    // 结账完成
    completedOrders++;
    business?.completeOrder();
    final table = current.table!;
    table.state = TableState.dirty;
    table.customerId = null;
    current.orderState = OrderState.leaving;
    current.customer.changeState(CustomerState.leaving);
    current.customer.removeFromParent(); // 开始离场动画
    _enqueueTask(WaiterTaskType.cleanTable, current);
    debugPrint('[Restaurant] customer#${current.id} checkout complete');
  }

  // ---------- 服务员任务调度 ----------
  void _updateWaiter(double dt) {
    var task = _activeTask;
    if (task == null) {
      if (_taskQueue.isEmpty) return;
      // 按优先级排序（送餐 > 点单 > 清洁）
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

  /// 开始任务的第一阶段（移动）
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

  /// 推进任务到下一阶段
  void _advanceTask(_WaiterTask task) {
    final session = task.session;
    switch (task.type) {
      case WaiterTaskType.takeOrder:
        if (task.stage == 0) {
          // 到达顾客处，记录订单
          task.stage = 1;
          task.actionTimer = .8;
          return;
        }
        if (task.stage == 1) {
          // 前往厨房送单
          task.stage = 2;
          _moveWaiter(_kitchenServicePosition);
          return;
        }
        // 检查食材是否充足
        if (business?.consumeActiveDishIngredients() == false) {
          // 食材不足，让顾客稍后重新点单
          session.orderState = OrderState.waitingToOrder;
          session.timer = 2;
          session.customer.changeState(CustomerState.waiting);
          _finishTask();
          return;
        }
        session.orderState = OrderState.cooking;
        session.timer = 2.8;
        _finishTask();
      case WaiterTaskType.deliverFood:
        if (task.stage == 0) {
          // 在厨房取餐
          task.stage = 1;
          task.actionTimer = .5;
          waiter.changeState(WaiterState.carryingFood);
          session.orderState = OrderState.ready;
          return;
        }
        if (task.stage == 1) {
          // 前往顾客餐桌
          task.stage = 2;
          _moveWaiter(
            map.clampToPlayableArea(session.table!.servicePosition, margin: 8),
            carryingFood: true,
          );
          return;
        }
        // 上餐完毕
        waiter.changeState(WaiterState.idle);
        session.orderState = OrderState.eating;
        session.timer = 3 + _random.nextDouble() * 2;
        session.customer.changeState(CustomerState.eating);
        session.table!.facility.showFrame(1); // 桌子占用状态
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

  // ---------- 厨房视觉更新 ----------
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
      kitchenFacility.showFrame(1);
    }
  }

  // ---------- 任务入队 ----------
  void _enqueueTask(WaiterTaskType type, _CustomerSession session) {
    // 避免重复入队
    if (_taskQueue.any(
          (task) => task.type == type && task.session == session,
    ) ||
        (_activeTask?.type == type && _activeTask?.session == session)) {
      return;
    }
    _taskQueue.add(_WaiterTask(type, session));
  }

  // ---------- 座位分配 ----------
  /// 为等待桌子的顾客分配空桌
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

  /// 顾客因等待太久而离开
  void _customerGivesUp(_CustomerSession session) {
    lostCustomers++;
    session.orderState = OrderState.leaving;
    session.customer.changeState(CustomerState.leaving);
    _moveCustomer(session, map.spawnPoint('door_spawn'));
    debugPrint('[Restaurant] customer#${session.id} left while waiting');
  }

  // ---------- 工具方法 ----------
  _RestaurantTable? _availableTable() {
    for (final table in tables) {
      if (table.state == TableState.available) return table;
    }
    return null;
  }

  /// 计算顾客在收银台前的排队位置
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

  /// 厨房外取餐点的位置
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

/// 封装餐桌设施及其状态
class _RestaurantTable {
  _RestaurantTable(this.id, this.facility);
  final int id;
  final RestaurantFacility facility;

  /// 顾客就坐位置（相对于设施坐标）
  Vector2 get seatPosition =>
      facility.position + Vector2(facility.isVertical ? -28 : 28, -26);

  /// 服务员服务位置（点单、上菜、清洁时站立位置）
  Vector2 get servicePosition =>
      facility.position + Vector2(facility.isVertical ? 6 : -6, 13);

  TableState state = TableState.available;
  int? customerId;
}

/// 顾客会话数据，关联顾客对象及其状态
class _CustomerSession {
  _CustomerSession(this.customer);
  final RestaurantCustomer customer;
  int get id => customer.customerId;

  OrderState orderState = OrderState.entering;
  _RestaurantTable? table;
  double timer = 0;       // 用于等待、烹饪、用餐等计时
  double patience = 18;   // 等待空桌的耐心值（秒）
}

/// 服务员任务，包含类型、关联的顾客、阶段进度和计时
class _WaiterTask {
  _WaiterTask(this.type, this.session);
  final WaiterTaskType type;
  final _CustomerSession session;

  int stage = 0;              // 任务执行阶段
  double actionTimer = 0;     // 动作持续时间（如取餐、清洁）

  /// 任务优先级：送餐最高，清洁最低
  int get priority => switch (type) {
    WaiterTaskType.deliverFood => 0,
    WaiterTaskType.takeOrder => 1,
    WaiterTaskType.cleanTable => 2,
  };
}