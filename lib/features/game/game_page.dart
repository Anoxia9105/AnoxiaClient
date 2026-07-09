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

  // 素材路径规则：pubspec 里声明的 assets 目录是 assets/images/
  // CropConfig.iconPath 是相对路径，这里拼成完整 asset key
  String _iconAsset(String iconPath) => 'assets/images/$iconPath';

  Widget _cropIcon(String iconPath, {double size = 28}) {
    return Image.asset(
      _iconAsset(iconPath),
      width: size,
      height: size,
      filterQuality: FilterQuality.none, // 像素画禁止模糊插值
    );
  }

  // ============ 顶部栏 ============
  Widget _buildTopBar(BuildContext context, FarmGamePage game) {
    return Positioned(
      top: 20,
      left: 20,
      right: 20,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ValueListenableBuilder<int>(
            valueListenable: game.coinNotifier,
            builder: (context, coins, child) {
              return _pillCard(
                color: Colors.black.withOpacity(0.6),
                child: Row(
                  children: [
                    const Icon(Icons.monetization_on, color: Colors.amber),
                    const SizedBox(width: 8),
                    Text(
                      '$coins',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          ValueListenableBuilder<CropType?>(
            valueListenable: game.selectedSeedNotifier,
            builder: (context, selected, child) {
              if (selected == null) {
                return _pillCard(
                  color: Colors.blueGrey.withOpacity(0.85),
                  child: const Text(
                    '手上空空如也',
                    style: TextStyle(color: Colors.white, fontSize: 15),
                  ),
                );
              }
              final config = cropRegistry[selected]!;
              return _pillCard(
                color: Colors.blueGrey.withOpacity(0.85),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _cropIcon(config.iconPath, size: 20),
                    const SizedBox(width: 6),
                    Text(
                      '装备：${config.name}种子',
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                    ),
                  ],
                ),
              );
            },
          ),
          Row(
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.backpack),
                label: const Text('背包'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.brown,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => game.overlays.add('Backpack'),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                icon: const Icon(Icons.shopping_cart),
                label: const Text('种子商店'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => game.overlays.add('ShopDialog'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pillCard({required Color color, required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: child,
    );
  }

  // ============ 背包面板 ============
  Widget _buildBackpack(BuildContext context, FarmGamePage game) {
    return Center(
      child: Container(
        width: 360,
        constraints: const BoxConstraints(maxHeight: 480),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10)],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '背包',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '种子（点击装备）',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ValueListenableBuilder<Map<CropType, int>>(
                      valueListenable: game.seedInventoryNotifier,
                      builder: (context, seeds, child) {
                        if (seeds.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              '还没有种子，先去商店买吧',
                              style: TextStyle(color: Colors.grey),
                            ),
                          );
                        }
                        return ValueListenableBuilder<CropType?>(
                          valueListenable: game.selectedSeedNotifier,
                          builder: (context, selected, child) {
                            return Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: seeds.entries.map((entry) {
                                final config = cropRegistry[entry.key]!;
                                final isSelected = selected == entry.key;
                                return GestureDetector(
                                  onTap: () => game.selectedSeedNotifier.value =
                                      entry.key,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? Colors.green.withOpacity(0.15)
                                          : Colors.grey.shade100,
                                      border: Border.all(
                                        color: isSelected
                                            ? Colors.green
                                            : Colors.grey.shade300,
                                        width: isSelected ? 2 : 1,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        _cropIcon(config.iconPath),
                                        const SizedBox(width: 6),
                                        Text('${config.name} x${entry.value}'),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            );
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '收获（可出售）',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ValueListenableBuilder<Map<CropType, int>>(
                      valueListenable: game.harvestInventoryNotifier,
                      builder: (context, harvest, child) {
                        if (harvest.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              '还没有收获',
                              style: TextStyle(color: Colors.grey),
                            ),
                          );
                        }
                        return Column(
                          children: harvest.entries.map((entry) {
                            final config = cropRegistry[entry.key]!;
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  _cropIcon(config.iconPath),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '${config.name} x${entry.value}  (单价${config.sellPrice})',
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        game.sellHarvest(entry.key),
                                    child: const Text('出售'),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const Divider(),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      game.sellAllHarvest();
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(const SnackBar(content: Text('已出售全部收获')));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('一键出售'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => game.overlays.remove('Backpack'),
                    child: const Text('关闭'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ============ 商店面板 ============
  Widget _buildShop(BuildContext context, FarmGamePage game) {
    return Center(
      child: Container(
        width: 360,
        constraints: const BoxConstraints(maxHeight: 480),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10)],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '种子商店',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: cropRegistry.values.map((config) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          _cropIcon(config.iconPath, size: 32),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '${config.name}（${config.seedPrice}金币/颗，卖价${config.sellPrice}）',
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              if (game.buySeed(config.type)) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('已购买${config.name}种子，放入背包'),
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('金币不足！')),
                                );
                              }
                            },
                            child: const Text('购买'),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const Divider(),
            ElevatedButton(
              onPressed: () => game.overlays.remove('ShopDialog'),
              child: const Text('返回农场'),
            ),
          ],
        ),
      ),
    );
  }
}
