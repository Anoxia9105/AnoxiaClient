import 'package:flame/components.dart';

/// 家具用途类型。
/// 业务代码通过此枚举查找厨房、收银台和餐桌，不再依赖字符串前缀。
enum FacilityType { table, kitchen, cashier, toilet, decoration }

/// 单个家具在关卡中的静态配置。
///
/// 新增家具时只需要在关卡配置中增加一项 [FacilityConfig]，
/// 不需要修改关卡加载流程。
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

  /// 家具唯一标识符
  final String id;

  /// 家具用途类型（餐桌、厨房、收银台等）
  final FacilityType type;

  /// 家具使用的图片资源名称列表（用于多帧动画）
  final List<String> assetNames;

  /// 在地图对象层中定义的生成点名称（Tiled 对象名称）
  final String spawnName;

  /// 家具垂直朝向时的占地矩形尺寸（对象空间坐标单位）
  final Vector2 verticalFootprint;

  /// 家具水平朝向时的占地矩形尺寸（对象空间坐标单位）。
  /// 若为 null，则与垂直朝向相同（即不可旋转或方形）。
  final Vector2? horizontalFootprint;

  /// 初始显示帧索引（从 0 开始）
  final int initialFrame;

  /// 渲染偏移量（像素），用于微调图片显示位置
  final int renderOffset;

  /// 家具中心与墙体内沿至少保留的对象坐标距离。
  /// 用于确保摆放时不会与墙壁穿插。
  final double wallMargin;

  /// 与其他家具至少保留的屏幕像素间距。
  /// 避免贴边后图片仍然穿插。
  final double placementGap;

  /// 根据朝向获取占地尺寸
  Vector2 footprintFor(bool vertical) =>
      (vertical ? verticalFootprint : horizontalFootprint ?? verticalFootprint)
          .clone();
}

/// 一张餐厅地图所需的完整配置。
///
/// 创建第二关时复制 [level1Config]，替换 tmx 地图文件、出生点和家具列表即可。
class RestaurantLevelConfig {
  const RestaurantLevelConfig({
    required this.id,
    required this.mapFile,
    required this.facilities,
    this.customerNames = const ['yongman', 'yongwoman', 'aunt', 'uncle'],
    this.maxCustomers = 5,
  });

  /// 关卡唯一标识符
  final String id;

  /// 地图文件名称（相对于地图资源前缀路径）
  final String mapFile;

  /// 该关卡包含的所有家具配置列表
  final List<FacilityConfig> facilities;

  /// 可能出现的顾客角色名称列表（用于随机生成顾客外观）
  final List<String> customerNames;

  /// 同一时刻最多同时存在的顾客数量
  final int maxCustomers;
}

/// 第一关的静态配置
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
      initialFrame: 1,      // 初始显示厨师站立状态
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
  ],
);