import 'package:anoxia/features/game/components/restaurant_facility.dart';
import 'package:anoxia/features/game/components/restaurant_map.dart';
import 'package:anoxia/features/game/models/facility_placement.dart';
import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';

/// 家具摆放的唯一入口：负责墙体边界、家具重叠和动态寻路障碍。
class FacilityPlacementController {
  FacilityPlacementController({required this.map, required this.facilities});

  final RestaurantMap map;
  final List<RestaurantFacility> facilities;

  PlacementResult tryMove(
    RestaurantFacility moving,
    Vector2 requestedPosition,
  ) {
    final insidePosition = map.clampToPlayableArea(
      requestedPosition,
      margin: moving.config.wallMargin,
    );
    if ((insidePosition - requestedPosition).length > .5) {
      return PlacementResult.rejected(
        moving.position.clone(),
        PlacementFailure.outsideMap,
      );
    }

    if (_overlapsAnother(moving, insidePosition, moving.isVertical)) {
      return PlacementResult.rejected(
        moving.position.clone(),
        PlacementFailure.overlapsFacility,
      );
    }
    return PlacementResult.accepted(insidePosition);
  }

  bool canRotate(RestaurantFacility facility) {
    return !_overlapsAnother(facility, facility.position, !facility.isVertical);
  }

  bool _overlapsAnother(
    RestaurantFacility moving,
    Vector2 position,
    bool vertical,
  ) {
    // 两个占地框各扩一半间距：相交时说明家具本体太近或已经穿插。
    final candidate = moving
        .footprintAt(position, vertical: vertical)
        .inflate(moving.config.placementGap / 2);
    for (final other in facilities) {
      if (identical(other, moving) || !other.active) continue;
      final otherArea = other.footprint.inflate(other.config.placementGap / 2);
      if (candidate.overlaps(otherArea)) return true;
    }
    return false;
  }

  /// 家具位置或方向变化后，重新生成服务员寻路使用的障碍物。
  void refreshObstacles() {
    map.setDynamicObstacles(
      facilities
          .where((item) => item.active)
          .map((item) => item.footprint)
          .toList(),
    );
  }

  void printLayout() {
    for (final item in facilities) {
      debugPrint(
        '[家具摆放] ${item.facilityId} 坐标=${item.position} '
        '方向=${item.isVertical ? '竖向' : '横向'} 占地=${item.footprint}',
      );
    }
  }
}
