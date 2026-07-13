import 'package:anoxia/features/game/components/restaurant_facility.dart';
import 'package:anoxia/features/game/components/restaurant_map.dart';
import 'package:anoxia/features/game/models/facility_placement.dart';
import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';

/// 家具摆放控制器。
/// 负责验证家具移动/旋转的合法性，并更新地图的动态障碍物数据。
/// 它是家具摆放功能的唯一入口，管理墙体边界约束、家具重叠检测以及寻路障碍刷新。
class FacilityPlacementController {
  FacilityPlacementController({required this.map, required this.facilities});

  /// 餐厅地图引用，用于获取可玩区域边界和更新动态障碍物
  final RestaurantMap map;

  /// 所有家具列表（包含当前正在操作的家具）
  final List<RestaurantFacility> facilities;

  /// 尝试将家具移动到指定位置。
  /// 返回 [PlacementResult] 表示移动是否被接受，以及最终位置或失败原因。
  PlacementResult tryMove(
      RestaurantFacility moving,
      Vector2 requestedPosition,
      ) {
    // 将请求位置限制在地图可玩区域内，并应用家具的墙体边距
    final insidePosition = map.clampToPlayableArea(
      requestedPosition,
      margin: moving.config.wallMargin,
    );
    // 如果实际位置与请求位置偏差较大，说明被墙壁挡住了，拒绝移动
    if ((insidePosition - requestedPosition).length > .5) {
      return PlacementResult.rejected(
        moving.position.clone(),
        PlacementFailure.outsideMap,
      );
    }

    // 检查目标位置是否与其他家具重叠
    if (_overlapsAnother(moving, insidePosition, moving.isVertical)) {
      return PlacementResult.rejected(
        moving.position.clone(),
        PlacementFailure.overlapsFacility,
      );
    }
    // 通过所有验证，接受移动
    return PlacementResult.accepted(insidePosition);
  }

  /// 判断家具是否可以被旋转（即旋转后不与其它家具重叠）。
  bool canRotate(RestaurantFacility facility) {
    return !_overlapsAnother(facility, facility.position, !facility.isVertical);
  }

  /// 检测家具在给定位置和朝向下是否与其它激活的家具重叠。
  /// 使用占地矩形（已扩展放置间距的一半）进行相交测试。
  bool _overlapsAnother(
      RestaurantFacility moving,
      Vector2 position,
      bool vertical,
      ) {
    // 计算候选家具的占地矩形，并向外扩展半个放置间距（避免贴得太近）
    final candidate = moving
        .footprintAt(position, vertical: vertical)
        .inflate(moving.config.placementGap / 2);
    // 遍历所有家具，跳过自身和未激活的家具
    for (final other in facilities) {
      if (identical(other, moving) || !other.active) continue;
      final otherArea = other.footprint.inflate(other.config.placementGap / 2);
      if (candidate.overlaps(otherArea)) return true;
    }
    return false;
  }

  /// 刷新地图的动态障碍物列表。
  /// 收集所有激活家具的占地矩形，并将其设置为地图的动态障碍物，
  /// 以确保服务员寻路时会避开家具。
  void refreshObstacles() {
    map.setDynamicObstacles(
      facilities
          .where((item) => item.active)
          .map((item) => item.footprint)
          .toList(),
    );
  }

  /// 打印当前所有家具的摆放状态（用于调试）。
  void printLayout() {
    for (final item in facilities) {
      debugPrint(
        '[家具摆放] ${item.facilityId} 坐标=${item.position} '
            '方向=${item.isVertical ? '竖向' : '横向'} 占地=${item.footprint}',
      );
    }
  }
}