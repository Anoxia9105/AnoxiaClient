import 'dart:convert';

import 'package:anoxia/features/game/models/restaurant_balance.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 跨 UI 与 Flame 关卡共享的经营状态，同时负责单存档读写。
class RestaurantBusinessState extends ChangeNotifier {
  static const _saveKey = 'restaurant_save_v1';

  int coins = RestaurantBalance.initialCoins;
  int day = 1;
  bool waiterHired = false;
  bool cleanerHired = false;
  bool tablesOwned = false;
  bool kitchenOwned = false;
  bool cashierOwned = false;
  bool layoutConfirmed = false;
  bool shopOpen = false;
  double remainingSeconds = RestaurantBalance.dayDurationSeconds.toDouble();
  String activeDishId = 'dish_01';
  final inventory = <String, int>{
    for (final id in RestaurantBalance.ingredientUnitPrices.keys) id: 0,
  };
  final dishLevels = <String, int>{
    for (final id in RestaurantBalance.dishes.keys) id: 1,
  };
  int dayRevenue = 0;
  int dayExpenses = 0;
  int dayOrders = 0;
  DaySettlement? lastSettlement;

  static Future<bool> hasSave() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.containsKey(_saveKey);
  }

  static Future<RestaurantBusinessState?> load() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_saveKey);
    if (raw == null) return null;
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final state = RestaurantBusinessState()
      ..coins = json['coins'] as int? ?? RestaurantBalance.initialCoins
      ..day = json['day'] as int? ?? 1
      ..waiterHired = json['waiterHired'] as bool? ?? false
      ..cleanerHired = json['cleanerHired'] as bool? ?? false
      ..tablesOwned = json['tablesOwned'] as bool? ?? false
      ..kitchenOwned = json['kitchenOwned'] as bool? ?? false
      ..cashierOwned = json['cashierOwned'] as bool? ?? false
      ..layoutConfirmed = json['layoutConfirmed'] as bool? ?? false
      ..activeDishId = json['activeDishId'] as String? ?? 'dish_01';
    state.inventory.addAll(
      (json['inventory'] as Map<String, dynamic>? ?? {}).map(
        (key, value) => MapEntry(key, value as int),
      ),
    );
    state.dishLevels.addAll(
      (json['dishLevels'] as Map<String, dynamic>? ?? {}).map(
        (key, value) => MapEntry(key, value as int),
      ),
    );
    if (!RestaurantBalance.dishes.containsKey(state.activeDishId)) {
      state.activeDishId = 'dish_01';
    }
    // 读档永远回到筹备状态，防止离线期间继续计算营业时间。
    state.shopOpen = false;
    state.remainingSeconds = RestaurantBalance.dayDurationSeconds.toDouble();
    return state;
  }

  List<String> get openingRequirements {
    final missing = <String>[];
    if (!waiterHired) missing.add('雇佣服务员');
    if (!cleanerHired) missing.add('雇佣保洁');
    if (!tablesOwned) missing.add('购买桌椅');
    if (!kitchenOwned) missing.add('购买厨房');
    if (!cashierOwned) missing.add('购买收银台');
    if (tablesOwned && kitchenOwned && cashierOwned && !layoutConfirmed) {
      missing.add('进入摆放模式并确认布局');
    }
    if (!canCookActiveDish) missing.add('购买当前菜品所需食材');
    return missing;
  }

  bool get canOpen => !shopOpen && openingRequirements.isEmpty;
  DishDefinition get activeDish => RestaurantBalance.dishes[activeDishId]!;
  int get activeDishLevel => dishLevels[activeDishId] ?? 1;
  int get activeDishPrice =>
      RestaurantBalance.dishPrice(activeDishId, activeDishLevel);
  bool get canCookActiveDish => activeDish.recipe.entries.every(
    (item) => (inventory[item.key] ?? 0) >= item.value,
  );

  bool buyEquipment(String id) {
    if (shopOpen) return false;
    final alreadyOwned = switch (id) {
      'tables' => tablesOwned,
      'kitchen' => kitchenOwned,
      'cashier' => cashierOwned,
      _ => true,
    };
    final price = RestaurantBalance.equipmentPrices[id];
    if (alreadyOwned || price == null || !_spend(price)) return false;
    switch (id) {
      case 'tables':
        tablesOwned = true;
      case 'kitchen':
        kitchenOwned = true;
      case 'cashier':
        cashierOwned = true;
    }
    layoutConfirmed = false;
    _changed();
    return true;
  }

  bool hire(String id) {
    if (shopOpen) return false;
    final hired = id == 'waiter' ? waiterHired : cleanerHired;
    final price = RestaurantBalance.employeeHirePrices[id];
    if (hired || price == null || !_spend(price)) return false;
    if (id == 'waiter') waiterHired = true;
    if (id == 'cleaner') cleanerHired = true;
    _changed();
    return true;
  }

  bool buyIngredient(String id) {
    final unitPrice = RestaurantBalance.ingredientUnitPrices[id];
    if (unitPrice == null) return false;
    final cost = unitPrice * RestaurantBalance.ingredientBundleSize;
    if (!_spend(cost)) return false;
    inventory[id] =
        (inventory[id] ?? 0) + RestaurantBalance.ingredientBundleSize;
    _changed();
    return true;
  }

  bool upgradeDish(String id) {
    if (shopOpen) return false;
    final level = dishLevels[id] ?? 1;
    if (level >= 5 || !_spend(RestaurantBalance.dishUpgradeCost(level))) {
      return false;
    }
    dishLevels[id] = level + 1;
    _changed();
    return true;
  }

  void selectDish(String id) {
    if (!RestaurantBalance.dishes.containsKey(id)) return;
    activeDishId = id;
    _changed();
  }

  void beginLayout() {
    if (shopOpen) return;
    layoutConfirmed = false;
    _changed(save: false);
  }

  void confirmLayout() {
    if (shopOpen || !tablesOwned || !kitchenOwned || !cashierOwned) return;
    layoutConfirmed = true;
    _changed();
  }

  bool openShop() {
    if (!canOpen) return false;
    shopOpen = true;
    remainingSeconds = RestaurantBalance.dayDurationSeconds.toDouble();
    _changed();
    return true;
  }

  void tick(double dt) {
    if (!shopOpen) return;
    final previousSecond = remainingSeconds.ceil();
    remainingSeconds -= dt;
    if (remainingSeconds <= 0) {
      closeDay();
    } else if (remainingSeconds.ceil() != previousSecond) {
      notifyListeners();
    }
  }

  bool consumeActiveDishIngredients() {
    if (!canCookActiveDish) return false;
    for (final item in activeDish.recipe.entries) {
      inventory[item.key] = inventory[item.key]! - item.value;
    }
    _changed(save: false);
    return true;
  }

  void completeOrder() {
    final income = activeDishPrice;
    coins += income;
    dayRevenue += income;
    dayOrders++;
    _changed();
  }

  DaySettlement? closeDay() {
    if (!shopOpen) return null;
    final wages =
        RestaurantBalance.employeeDailyWages['waiter']! +
        RestaurantBalance.employeeDailyWages['cleaner']!;
    coins -= wages;
    dayExpenses += wages;
    lastSettlement = DaySettlement(
      day: day,
      revenue: dayRevenue,
      expenses: dayExpenses,
      orders: dayOrders,
    );
    day++;
    shopOpen = false;
    remainingSeconds = RestaurantBalance.dayDurationSeconds.toDouble();
    dayRevenue = 0;
    dayExpenses = 0;
    dayOrders = 0;
    _changed();
    return lastSettlement;
  }

  bool _spend(int amount) {
    if (coins < amount) return false;
    coins -= amount;
    dayExpenses += amount;
    return true;
  }

  void _changed({bool save = true}) {
    notifyListeners();
    if (save) saveGame();
  }

  Future<void> saveGame() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _saveKey,
      jsonEncode({
        'coins': coins,
        'day': day,
        'waiterHired': waiterHired,
        'cleanerHired': cleanerHired,
        'tablesOwned': tablesOwned,
        'kitchenOwned': kitchenOwned,
        'cashierOwned': cashierOwned,
        'layoutConfirmed': layoutConfirmed,
        'activeDishId': activeDishId,
        'inventory': inventory,
        'dishLevels': dishLevels,
      }),
    );
  }
}

class DaySettlement {
  const DaySettlement({
    required this.day,
    required this.revenue,
    required this.expenses,
    required this.orders,
  });

  final int day;
  final int revenue;
  final int expenses;
  final int orders;
  int get profit => revenue - expenses;
}
