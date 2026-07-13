import 'package:flame/components.dart';

/// 摆放失败原因，方便 UI 提示和断点调试。
enum PlacementFailure { outsideMap, overlapsFacility }

class PlacementResult {
  const PlacementResult.accepted(this.position) : failure = null;
  const PlacementResult.rejected(this.position, this.failure);

  final Vector2 position;
  final PlacementFailure? failure;
  bool get accepted => failure == null;
}
