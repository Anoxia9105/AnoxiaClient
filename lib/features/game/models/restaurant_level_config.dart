import 'package:flame/components.dart';

/// 家具用途。业务代码通过用途查找厨房、收银台和餐桌，不再依赖字符串前缀。
enum FacilityType { table, kitchen, cashier, toilet, decoration }

/// 单个家具在关卡中的静态配置。
///
/// 新增家具时只需要在关卡配置中增加一项，不需要修改关卡加载流程。
class FacilityConfig {
  const FacilityConfig({
    required this.id,
    required this.type,
    required this.assetNames,
    required this.spawnName,
    required this.verticalFootprint,
    this.horizontalFootprint,
    this.initialFrame = 0,
    this.renderOffset = 0,
    this.wallMargin = 12,
    this.placementGap = 4,
  });

  final String id;
  final FacilityType type;
  final List<String> assetNames;
  final String spawnName;
  final Vector2 verticalFootprint;
  final Vector2? horizontalFootprint;
  final int initialFrame;
  final int renderOffset;

  /// 家具中心与墙体内沿至少保留的对象坐标距离。
  final double wallMargin;

  /// 与其他家具至少保留的屏幕像素间距，避免贴边后图片仍然穿插。
  final double placementGap;

  Vector2 footprintFor(bool vertical) =>
      (vertical ? verticalFootprint : horizontalFootprint ?? verticalFootprint)
          .clone();
}

/// 一张餐厅地图需要的全部配置。
///
/// 创建第二关时复制 [level1Config]，替换 tmx、出生点和家具列表即可。
class RestaurantLevelConfig {
  const RestaurantLevelConfig({
    required this.id,
    required this.mapFile,
    required this.facilities,
    this.customerNames = const ['yongman', 'yongwoman', 'aunt', 'uncle'],
    this.maxCustomers = 5,
  });

  final String id;
  final String mapFile;
  final List<FacilityConfig> facilities;
  final List<String> customerNames;
  final int maxCustomers;
}

final level1Config = RestaurantLevelConfig(
  id: 'level_1',
  mapFile: 'restaurant_level_1.tmx',
  facilities: [
    FacilityConfig(
      id: 'table_1',
      type: FacilityType.table,
      assetNames: const ['2pzhuoyi_putong'],
      spawnName: 'table_1_facility',
      // 桌椅是一整套家具，占地必须包含两侧椅子，不能只量桌面。
      verticalFootprint: Vector2(82, 46),
      horizontalFootprint: Vector2(82, 46),
      wallMargin: 32,
      placementGap: 6,
    ),
    FacilityConfig(
      id: 'table_2',
      type: FacilityType.table,
      assetNames: const ['2pzhuoyi_putong'],
      spawnName: 'table_2_facility',
      verticalFootprint: Vector2(82, 46),
      horizontalFootprint: Vector2(82, 46),
      wallMargin: 32,
      placementGap: 6,
    ),
    FacilityConfig(
      id: 'kitchen',
      type: FacilityType.kitchen,
      assetNames: const ['chufang_01'],
      spawnName: 'kitchen_facility',
      verticalFootprint: Vector2(78, 28),
      horizontalFootprint: Vector2(78, 28),
      initialFrame: 1,
      wallMargin: 42,
    ),
    FacilityConfig(
      id: 'cashier',
      type: FacilityType.cashier,
      assetNames: const ['yintai_01'],
      spawnName: 'cashier_facility',
      verticalFootprint: Vector2(70, 26),
      horizontalFootprint: Vector2(70, 26),
      initialFrame: 1,
      wallMargin: 42,
    ),
    FacilityConfig(
      id: 'toilet',
      type: FacilityType.toilet,
      assetNames: const ['wc01'],
      spawnName: 'toilet_facility',
      verticalFootprint: Vector2(64, 25),
      horizontalFootprint: Vector2(64, 25),
      wallMargin: 42,
    ),
  ],
);
