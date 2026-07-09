import 'dart:math' show min;

import 'package:anoxia/features/game/config/crop_type_enum.dart';
import 'package:anoxia/features/game/farm_game_page.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:anoxia/features/game/config/crop_map.dart';

class GamePage extends StatefulWidget {
  const GamePage({super.key});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  @override
  Widget build(BuildContext context) {
    return GameWidget<FarmGamePage>.controlled(
      gameFactory: FarmGamePage.new,
      initialActiveOverlays: const ['TopBar'],
      overlayBuilderMap: {
        'TopBar': _buildTopBar,
        'Backpack': _buildBackpack,
        'ShopDialog': _buildShop,
      },
    );
  }

  String _iconAsset(String iconPath) => 'assets/images/$iconPath';

  Widget _cropIcon(String iconPath, {double size = 28}) {
    return Image.asset(
      _iconAsset(iconPath),
      width: size,
      height: size,
      filterQuality: FilterQuality.none,
    );
  }

  // ============================================================
  // 顶部栏
  // ============================================================
  Widget _buildTopBar(BuildContext context, FarmGamePage game) {
    return Positioned(
      top: 20,
      left: 16,
      right: 16,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 金币
          ValueListenableBuilder<int>(
            valueListenable: game.coinNotifier,
            builder: (context, coins, _) => _pill(
              color: Colors.black.withOpacity(0.65),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.monetization_on,
                    color: Colors.amber,
                    size: 20,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$coins',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // 当前装备种子
          ValueListenableBuilder<CropType?>(
            valueListenable: game.selectedSeedNotifier,
            builder: (context, selected, _) {
              if (selected == null) {
                return _pill(
                  color: Colors.blueGrey.withOpacity(0.80),
                  child: const Text(
                    '手上空空',
                    style: TextStyle(color: Colors.white, fontSize: 13),
                  ),
                );
              }
              final config = cropRegistry[selected]!;
              return _pill(
                color: Colors.green.withOpacity(0.85),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _cropIcon(config.iconPath, size: 18),
                    const SizedBox(width: 5),
                    Text(
                      config.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          // 按钮
          Row(
            children: [
              _iconBtn(
                Icons.backpack_rounded,
                Colors.brown.shade600,
                () => game.overlays.add('Backpack'),
                label: '背包',
              ),
              const SizedBox(width: 8),
              _iconBtn(
                Icons.storefront_rounded,
                Colors.orange.shade700,
                () => game.overlays.add('ShopDialog'),
                label: '商店',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pill({required Color color, required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
      ),
      child: child,
    );
  }

  Widget _iconBtn(
    IconData icon,
    Color color,
    VoidCallback onTap, {
    String? label,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.4),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            if (label != null) ...[
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ============================================================
  // 背包面板（分 Tab：种子 / 收获）
  // ============================================================
  Widget _buildBackpack(BuildContext context, FarmGamePage game) {
    final panelW = min(MediaQuery.of(context).size.width * 0.92, 420.0);
    final panelH = min(MediaQuery.of(context).size.height * 0.76, 560.0);

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: panelW,
          height: panelH,
          decoration: BoxDecoration(
            color: const Color(0xFFFDF6EC),
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(color: Colors.black38, blurRadius: 20, spreadRadius: 2),
            ],
          ),
          child: DefaultTabController(
            length: 2,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 8, 0),
                  child: Row(
                    children: [
                      const Text(
                        '🎒  背包',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => game.overlays.remove('Backpack'),
                      ),
                    ],
                  ),
                ),
                const TabBar(
                  tabs: [
                    Tab(icon: Icon(Icons.grass_rounded), text: '种子'),
                    Tab(icon: Icon(Icons.shopping_basket_rounded), text: '收获'),
                  ],
                  labelColor: Color(0xFF4CAF50),
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: Color(0xFF4CAF50),
                ),
                Expanded(
                  child: TabBarView(
                    children: [_seedsTab(game), _harvestTab(game)],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 种子 Tab
  Widget _seedsTab(FarmGamePage game) {
    return ValueListenableBuilder<Map<CropType, int>>(
      valueListenable: game.seedInventoryNotifier,
      builder: (context, seeds, _) {
        if (seeds.isEmpty) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.shopping_cart_outlined,
                  size: 48,
                  color: Colors.grey,
                ),
                SizedBox(height: 8),
                Text('还没有种子，去商店买吧', style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }
        return ValueListenableBuilder<CropType?>(
          valueListenable: game.selectedSeedNotifier,
          builder: (context, selected, _) {
            final entries = seeds.entries.toList();
            return GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.82,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemCount: entries.length,
              itemBuilder: (context, i) {
                final entry = entries[i];
                final config = cropRegistry[entry.key]!;
                final isSelected = selected == entry.key;
                return GestureDetector(
                  onTap: () {
                    game.selectedSeedNotifier.value = isSelected
                        ? null
                        : entry.key;
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFE8F5E9)
                          : Colors.white,
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF4CAF50)
                            : Colors.grey.shade200,
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _cropIcon(config.iconPath, size: 38),
                        const SizedBox(height: 4),
                        Text(
                          config.name,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '×${entry.value}',
                          style: TextStyle(
                            fontSize: 14,
                            color: isSelected
                                ? const Color(0xFF2E7D32)
                                : Colors.brown.shade600,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (isSelected)
                          Container(
                            margin: const EdgeInsets.only(top: 2),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF4CAF50),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              '已装备',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  // 收获 Tab
  Widget _harvestTab(FarmGamePage game) {
    return ValueListenableBuilder<Map<CropType, int>>(
      valueListenable: game.harvestInventoryNotifier,
      builder: (context, harvest, _) {
        if (harvest.isEmpty) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.inbox_outlined, size: 48, color: Colors.grey),
                SizedBox(height: 8),
                Text('还没有收获，快去种地吧', style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        final totalValue = harvest.entries.fold<int>(
          0,
          (sum, e) => sum + e.value * cropRegistry[e.key]!.sellPrice,
        );

        return Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                children: harvest.entries.map((entry) {
                  final config = cropRegistry[entry.key]!;
                  final itemTotal = entry.value * config.sellPrice;
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          _cropIcon(config.iconPath, size: 36),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  config.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  '×${entry.value}  ·  单价 ${config.sellPrice}  ·  共 $itemTotal 金',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () => game.sellHarvest(entry.key),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4CAF50),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              '出售',
                              style: TextStyle(fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        '全部出售可得',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      Row(
                        children: [
                          const Icon(
                            Icons.monetization_on,
                            color: Colors.amber,
                            size: 16,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '$totalValue',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Color(0xFF2E7D32),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: () {
                      game.sellAllHarvest();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('已出售全部收获 🎉'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    icon: const Icon(Icons.sell_rounded, size: 16),
                    label: const Text('一键出售'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade700,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // 商店面板
  // ============================================================
  Widget _buildShop(BuildContext context, FarmGamePage game) {
    final panelW = min(MediaQuery.of(context).size.width * 0.95, 480.0);
    final panelH = min(MediaQuery.of(context).size.height * 0.80, 600.0);

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: panelW,
          height: panelH,
          decoration: BoxDecoration(
            color: const Color(0xFFFDF6EC),
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(color: Colors.black38, blurRadius: 20, spreadRadius: 2),
            ],
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 8, 6),
                child: Row(
                  children: [
                    const Icon(
                      Icons.storefront_rounded,
                      color: Colors.orange,
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      '种子商店',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    ValueListenableBuilder<int>(
                      valueListenable: game.coinNotifier,
                      builder: (context, coins, _) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.monetization_on,
                              color: Colors.amber,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$coins',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => game.overlays.remove('ShopDialog'),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ValueListenableBuilder<Map<CropType, int>>(
                  valueListenable: game.seedInventoryNotifier,
                  builder: (context, seeds, _) {
                    return ListView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      children: cropRegistry.values.map((config) {
                        final owned = seeds[config.type] ?? 0;
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 3),
                          elevation: 1,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            child: Row(
                              children: [
                                _cropIcon(config.iconPath, size: 36),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        config.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      Text(
                                        '种子 ${config.seedPrice}金  ·  售 ${config.sellPrice}金  ·  ${config.growSeconds.toInt()}秒',
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 11,
                                        ),
                                      ),
                                      if (owned > 0)
                                        Text(
                                          '背包: $owned 颗',
                                          style: const TextStyle(
                                            color: Color(0xFF2E7D32),
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    _buyBtn(context, game, config.type, 1),
                                    const SizedBox(height: 4),
                                    _buyBtn(context, game, config.type, 5),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buyBtn(
    BuildContext context,
    FarmGamePage game,
    CropType type,
    int qty,
  ) {
    final price = cropRegistry[type]!.seedPrice * qty;
    return SizedBox(
      width: 80,
      height: 28,
      child: ElevatedButton(
        onPressed: () {
          if (game.buySeed(type, qty: qty)) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('购买 ${cropRegistry[type]!.name} ×$qty'),
                duration: const Duration(seconds: 1),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('金币不足！'),
                duration: Duration(seconds: 1),
              ),
            );
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: qty == 1
              ? Colors.orange.shade600
              : Colors.deepOrange.shade600,
          foregroundColor: Colors.white,
          padding: EdgeInsets.zero,
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        child: Text(
          '+$qty ($price金)',
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
