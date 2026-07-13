import 'dart:math' as math;

import 'package:anoxia/features/game/models/restaurant_balance.dart';
import 'package:anoxia/features/game/models/restaurant_business_state.dart';
import 'package:anoxia/features/game/restaurant_level/restaurant_level1.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

class RestaurantGamePage extends StatefulWidget {
  const RestaurantGamePage({super.key});

  @override
  State<RestaurantGamePage> createState() => _RestaurantGamePageState();
}

class _RestaurantGamePageState extends State<RestaurantGamePage> {
  RestaurantBusinessState? business;
  RestaurantGame? game;
  bool hasSave = false;
  bool checkingSave = true;
  bool editing = false;
  bool _wasOpen = false;
  int? _shownSettlementDay;

  @override
  void initState() {
    super.initState();
    _checkSave();
  }

  Future<void> _checkSave() async {
    hasSave = await RestaurantBusinessState.hasSave();
    if (mounted) setState(() => checkingSave = false);
  }

  void _enterGame(RestaurantBusinessState state) {
    business?.removeListener(_businessChanged);
    state.addListener(_businessChanged);
    setState(() {
      business = state;
      game = RestaurantGame(business: state);
      editing = false;
      _wasOpen = state.shopOpen;
    });
    state.saveGame();
  }

  void _businessChanged() {
    final state = business;
    if (state == null || !mounted) return;
    final ended = _wasOpen && !state.shopOpen && state.lastSettlement != null;
    _wasOpen = state.shopOpen;
    setState(() {});
    if (ended && _shownSettlementDay != state.lastSettlement!.day) {
      _shownSettlementDay = state.lastSettlement!.day;
      WidgetsBinding.instance.addPostFrameCallback((_) => _showSettlement());
    }
  }

  @override
  void dispose() {
    business?.removeListener(_businessChanged);
    business?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (business == null || game == null) return _buildStartScreen();
    return _buildGame();
  }

  Widget _buildStartScreen() {
    return ColoredBox(
      color: const Color(0xFF263238),
      child: Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.restaurant, size: 64),
                const SizedBox(height: 12),
                const Text('开心餐厅', style: TextStyle(fontSize: 28)),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => _enterGame(RestaurantBusinessState()),
                  child: const Text('开始新游戏'),
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: checkingSave || !hasSave
                      ? null
                      : () async {
                          final loaded = await RestaurantBusinessState.load();
                          if (loaded != null && mounted) _enterGame(loaded);
                        },
                  child: Text(checkingSave ? '检查存档…' : '加载游戏'),
                ),
                const SizedBox(height: 12),
                const Text('新游戏初始金币：${RestaurantBalance.initialCoins}'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGame() {
    final state = business!;
    return Stack(
      children: [
        GameWidget<RestaurantGame>(
          game: game!,
          loadingBuilder: (_) => const ColoredBox(
            color: Color(0xFFE8F0F2),
            child: Center(child: CircularProgressIndicator()),
          ),
          errorBuilder: (_, error) => Center(child: Text('游戏加载失败：$error')),
        ),
        Positioned(left: 10, top: 10, child: _ResourceHud(state: state)),
        Positioned(
          right: 10,
          top: 10,
          bottom: 10,
          width: 270,
          child: _ManagementPanel(
            state: state,
            editing: editing,
            onToggleEditing: _toggleEditing,
            onRotate: game!.rotateSelectedFacility,
            onOpen: _openShop,
            onClose: state.closeDay,
          ),
        ),
      ],
    );
  }

  void _toggleEditing() {
    final state = business!;
    if (state.shopOpen) return;
    setState(() => editing = !editing);
    game!.setEditMode(editing);
    if (editing) {
      state.beginLayout();
    } else {
      state.confirmLayout();
    }
  }

  void _openShop() {
    if (!business!.openShop()) return;
    if (editing) {
      editing = false;
      game!.setEditMode(false);
    }
  }

  Future<void> _showSettlement() async {
    if (!mounted || business?.lastSettlement == null) return;
    final result = business!.lastSettlement!;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('第 ${result.day} 天结算'),
        content: Text(
          '订单：${result.orders}\n收入：${result.revenue}\n'
          '支出：${result.expenses}\n净利润：${result.profit}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('继续筹备'),
          ),
        ],
      ),
    );
  }
}

class _ManagementPanel extends StatelessWidget {
  const _ManagementPanel({
    required this.state,
    required this.editing,
    required this.onToggleEditing,
    required this.onRotate,
    required this.onOpen,
    required this.onClose,
  });

  final RestaurantBusinessState state;
  final bool editing;
  final VoidCallback onToggleEditing;
  final VoidCallback onRotate;
  final VoidCallback onOpen;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xEFFFFFFF),
      borderRadius: BorderRadius.circular(12),
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Text(
            '第 ${state.day} 天  金币 ${state.coins}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Text(
            state.shopOpen ? '营业中 ${state.remainingSeconds.ceil()} 秒' : '筹备中',
          ),
          const Divider(),
          const Text('员工'),
          _buyButton(
            '服务员 ${state.waiterHired ? '已雇佣' : '500'}',
            state.waiterHired || state.shopOpen
                ? null
                : () => state.hire('waiter'),
          ),
          _buyButton(
            '保洁 ${state.cleanerHired ? '已雇佣' : '300'}',
            state.cleanerHired || state.shopOpen
                ? null
                : () => state.hire('cleaner'),
          ),
          const Divider(),
          const Text('基础家具'),
          _equipment('tables', '桌椅', state.tablesOwned),
          _equipment('kitchen', '厨房', state.kitchenOwned),
          _equipment('cashier', '收银台', state.cashierOwned),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: state.shopOpen ? null : onToggleEditing,
                  child: Text(editing ? '确认布局' : '摆放家具'),
                ),
              ),
              if (editing)
                IconButton(
                  onPressed: onRotate,
                  icon: const Icon(Icons.rotate_right),
                ),
            ],
          ),
          const Divider(),
          const Text('菜品与食材（营业中也可采购）'),
          DropdownButton<String>(
            isExpanded: true,
            value: state.activeDishId,
            items: [
              for (final dish in RestaurantBalance.dishes.values)
                DropdownMenuItem(
                  value: dish.id,
                  child: Row(
                    children: [
                      Image.asset(
                        dish.iconAsset,
                        width: 24,
                        height: 24,
                        filterQuality: FilterQuality.none,
                      ),
                      const SizedBox(width: 8),
                      Text(dish.name),
                    ],
                  ),
                ),
            ],
            onChanged: (value) {
              if (value != null) state.selectDish(value);
            },
          ),
          Text(
            '${state.activeDish.name} Lv.${state.activeDishLevel}  '
            '售价 ${state.activeDishPrice}',
          ),
          Text(
            '配方：${state.activeDish.recipe.entries.map((e) => '${RestaurantBalance.ingredientNames[e.key]}×${e.value}').join('、')}',
          ),
          OutlinedButton(
            onPressed: state.shopOpen || state.activeDishLevel >= 5
                ? null
                : () => state.upgradeDish(state.activeDishId),
            child: Text(
              '升级菜品 ${RestaurantBalance.dishUpgradeCost(state.activeDishLevel)}',
            ),
          ),
          for (final item in RestaurantBalance.ingredientUnitPrices.entries)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: OutlinedButton(
                onPressed: () => state.buyIngredient(item.key),
                child: Row(
                  children: [
                    _IngredientSprite(
                      index:
                          RestaurantBalance.ingredientSpriteIndexes[item.key]!,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${RestaurantBalance.ingredientNames[item.key]}：'
                        '${state.inventory[item.key]}',
                      ),
                    ),
                    Text(
                      '+10/${item.value * RestaurantBalance.ingredientBundleSize}',
                    ),
                  ],
                ),
              ),
            ),
          const Divider(),
          if (!state.shopOpen && state.openingRequirements.isNotEmpty)
            Text('开店还需：${state.openingRequirements.join('、')}'),
          FilledButton.icon(
            onPressed: state.shopOpen
                ? onClose
                : (state.canOpen ? onOpen : null),
            icon: Icon(state.shopOpen ? Icons.stop : Icons.storefront),
            label: Text(state.shopOpen ? '提前打烊并结算' : '开店'),
          ),
        ],
      ),
    );
  }

  Widget _equipment(String id, String name, bool owned) {
    final price = RestaurantBalance.equipmentPrices[id]!;
    return _buyButton(
      '$name ${owned ? '已购买' : price}',
      owned || state.shopOpen ? null : () => state.buyEquipment(id),
    );
  }

  Widget _buyButton(String text, VoidCallback? action) => Padding(
    padding: const EdgeInsets.only(top: 4),
    child: SizedBox(
      height: 34,
      child: OutlinedButton(onPressed: action, child: Text(text)),
    ),
  );
}

class _ResourceHud extends StatelessWidget {
  const _ResourceHud({required this.state});

  final RestaurantBusinessState state;

  @override
  Widget build(BuildContext context) {
    final popularity = (30 + state.dayOrders * 4).clamp(0, 100);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PixelHudBar(
          background: 'assets/images/flame_resources/raw/timedi.png',
          icon: 'assets/images/flame_resources/raw/timetu.png',
          width: 136,
          digits: 'assets/images/flame_resources/raw/timenum.png',
          digitSheetWidth: 96,
          value: state.shopOpen
              ? '${state.remainingSeconds.ceil()}'
              : '${state.day}',
        ),
        const SizedBox(height: 3),
        _PixelHudBar(
          background: 'assets/images/flame_resources/raw/renqitiao.png',
          icon: 'assets/images/flame_resources/raw/renqitu.png',
          width: 92,
          digits: 'assets/images/flame_resources/raw/timenum.png',
          digitSheetWidth: 96,
          value: '$popularity',
        ),
        const SizedBox(height: 3),
        _PixelHudBar(
          background: 'assets/images/flame_resources/raw/qiandi.png',
          icon: 'assets/images/flame_resources/raw/qiantu.png',
          width: 190,
          digits: 'assets/images/flame_resources/raw/qianupnum.png',
          digitSheetWidth: 88,
          value: '${state.coins}',
        ),
      ],
    );
  }
}

class _PixelHudBar extends StatelessWidget {
  const _PixelHudBar({
    required this.background,
    required this.icon,
    required this.width,
    required this.digits,
    required this.digitSheetWidth,
    required this.value,
  });

  final String background;
  final String icon;
  final double width;
  final String digits;
  final double digitSheetWidth;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: 32,
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          Positioned.fill(
            child: Image.asset(
              background,
              fit: BoxFit.fill,
              filterQuality: FilterQuality.none,
            ),
          ),
          Positioned(
            left: 3,
            child: Image.asset(
              icon,
              width: 30,
              height: 26,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.none,
            ),
          ),
          Positioned(
            left: 38,
            right: 6,
            child: Center(
              child: _SpriteDigits(
                value: value,
                asset: digits,
                sheetWidth: digitSheetWidth,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// timenum/qianupnum 都是横向数字条，每个字符固定为 8×10。
class _SpriteDigits extends StatelessWidget {
  const _SpriteDigits({
    required this.value,
    required this.asset,
    required this.sheetWidth,
  });

  final String value;
  final String asset;
  final double sheetWidth;

  @override
  Widget build(BuildContext context) {
    final characters = value
        .split('')
        .where((item) => int.tryParse(item) != null);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final character in characters)
          SizedBox(
            width: 16,
            height: 20,
            child: ClipRect(
              child: Transform.scale(
                scale: 2,
                alignment: Alignment.topLeft,
                child: Transform.translate(
                  offset: Offset(-8.0 * int.parse(character), 0),
                  child: Image.asset(
                    asset,
                    width: sheetWidth,
                    height: 10,
                    alignment: Alignment.topLeft,
                    fit: BoxFit.none,
                    filterQuality: FilterQuality.none,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// 从 22×88 的 shicaibig.png 中裁出一格 22×22 食材图标。
class _IngredientSprite extends StatelessWidget {
  const _IngredientSprite({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 28,
      height: 28,
      child: ClipRect(
        child: FittedBox(
          fit: BoxFit.fill,
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: 22,
            height: 22,
            child: ClipRect(
              child: Transform.translate(
                offset: Offset(0, -22.0 * index),
                child: Image.asset(
                  'assets/images/flame_resources/raw/shicaibig.png',
                  width: 22,
                  height: 88,
                  alignment: Alignment.topCenter,
                  fit: BoxFit.none,
                  filterQuality: FilterQuality.none,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class RestaurantGame extends FlameGame {
  RestaurantGame({required this.business}) {
    debugMode = true;
  }

  static const characterNames = [
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

  final RestaurantBusinessState business;
  RestaurantLevel1? _level;

  @override
  Color backgroundColor() => const Color(0xFFE8F0F2);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await images.loadAll([
      for (final name in characterNames) 'flame_sprites/${name}_anim_sheet.png',
    ]);
    final level = RestaurantLevel1(business: business);
    _level = level;
    world = level;
    await level.loaded;
    _fitCameraToLevel();
  }

  @override
  void update(double dt) {
    super.update(dt);
    business.tick(dt);
  }

  void setEditMode(bool value) => _level?.setEditMode(value);
  void rotateSelectedFacility() => _level?.rotateSelectedFacility();

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _fitCameraToLevel();
  }

  void _fitCameraToLevel() {
    final level = _level;
    if (level == null || !level.isLoaded || level.mapVisualSize.isZero()) {
      return;
    }
    final zoom = math.max(
      size.x / level.mapVisualSize.x,
      size.y / level.mapVisualSize.y,
    );
    camera.viewfinder
      ..anchor = Anchor.center
      ..position = level.mapVisualCenter
      ..visibleGameSize = null
      ..zoom = zoom;
  }
}
