import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:flutter/foundation.dart';

/// 餐厅地图组件，基于等距瓦片地图（Tiled）实现。
/// 负责加载地图、碰撞检测、生成点管理以及路径查找（A*）。
class RestaurantMap extends PositionComponent {
  // 等距瓦片的尺寸（宽x高），单位为像素
  static final Vector2 tileSize = Vector2(32, 16);
  // 地图资源文件路径前缀
  static const String _mapPrefix = 'assets/images/flame_resources/maps/';
  // 寻路网格的单元大小（像素），用于将世界坐标离散化为节点
  static const double _pathNodeSize = 16;

  // 加载的 Tiled 组件
  late final TiledComponent tiled;

  // 构造函数，传入地图文件名（相对于 _mapPrefix）
  RestaurantMap({required this.mapFile});

  final String mapFile;

  // 静态碰撞矩形列表（从 Tiled 的碰撞对象层加载），坐标位于对象空间（未投影）
  final List<Rect> _collisionRects = [];
  // 动态障碍物列表（屏幕空间矩形），用于运行时临时阻挡
  final List<Rect> _dynamicCollisionRects = [];
  // 生成点字典，键为名称，值为对象空间坐标（未投影）
  final Map<String, Vector2> _spawnPoints = {};
  // 可玩区域（对象空间），由碰撞矩形内边缘推导得出
  Rect? _playableObjectBounds;
  // 用于限制碰撞日志输出频率的时间戳
  DateTime? _lastCollisionLogAt;

  /// 地图的视觉尺寸（屏幕空间像素）
  Vector2 get visualSize {
    final map = tiled.tileMap.map;
    return Vector2(
      (map.width + map.height) * tileSize.x / 2,
      (map.width + map.height) * tileSize.y / 2,
    );
  }

  /// 地图视觉中心的世界坐标
  Vector2 get visualCenter => position + visualSize / 2;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // 加载 Tiled 地图，指定瓦片尺寸
    tiled = await TiledComponent.load(mapFile, tileSize, prefix: _mapPrefix);
    await add(tiled);
    size = tiled.size;

    // 解析碰撞矩形、可玩区域和生成点
    _loadCollisionRects();
    _calculatePlayableObjectBounds();
    _loadSpawnPoints();
    debugPrint(
      '[RestaurantMap] debug=$debugMode, collisions=${_collisionRects.length}, '
          'spawns=${_spawnPoints.keys.join(', ')}',
    );
  }

  /// 判断世界坐标 (worldPosition) 是否可行走（即未被碰撞阻挡且在可玩区域内）
  bool isWalkableAt(Vector2 worldPosition) {
    // 转换到组件局部坐标
    final local = worldPosition - absolutePosition;
    // 将屏幕局部坐标转换为对象空间坐标（等距反投影）
    final objectPosition = _screenToObject(local);
    final bounds = _playableBounds;
    // 为角色预留内缩边界（防止紧贴墙壁）
    const actorWallInset = 8.0;
    final actorBounds = bounds.deflate(actorWallInset);
    // 检查是否在可玩区域内（对象空间）
    if (!actorBounds.contains(Offset(objectPosition.x, objectPosition.y))) {
      return false;
    }

    // 检查动态障碍物（屏幕空间）
    if (_dynamicCollisionRects.any(
          (rect) => rect.contains(Offset(local.x, local.y)),
    )) {
      return false;
    }
    // 检查静态碰撞矩形（对象空间）
    for (var index = 0; index < _collisionRects.length; index++) {
      final rect = _collisionRects[index];
      if (!rect.contains(Offset(objectPosition.x, objectPosition.y))) continue;

      // 输出碰撞日志（频率限制）
      final now = DateTime.now();
      if (_lastCollisionLogAt == null ||
          now.difference(_lastCollisionLogAt!).inMilliseconds >= 500) {
        _lastCollisionLogAt = now;
        debugPrint(
          '[RestaurantMap] COLLISION #$index screen=$local '
              'object=$objectPosition rect=$rect',
        );
      }
      return false;
    }
    return true;
  }

  /// 获取指定名称的生成点的世界坐标，若不存在则返回 fallback
  Vector2 spawnPoint(String name, {Vector2? fallback}) {
    final objectPosition = _spawnPoints[name];
    if (objectPosition != null) {
      // 将对象空间坐标转换为屏幕空间，再转换到世界坐标（加上组件位置）
      return _objectToScreen(objectPosition) + position;
    }
    return (fallback ?? size / 2) + position;
  }

  /// 更新动态障碍物列表（屏幕空间矩形）
  void setDynamicObstacles(List<Rect> obstacles) {
    _dynamicCollisionRects
      ..clear()
      ..addAll(obstacles);
  }

  /// 将世界坐标限制在可玩区域内，并应用指定的边距 margin
  Vector2 clampToPlayableArea(Vector2 worldPosition, {double margin = 24}) {
    final local = worldPosition - absolutePosition;
    final objectPosition = _screenToObject(local);
    final bounds = _playableBounds;
    final safeBounds = bounds.deflate(margin);
    // 在对象空间内进行裁剪
    final clamped = Vector2(
      objectPosition.x.clamp(safeBounds.left, safeBounds.right),
      objectPosition.y.clamp(safeBounds.top, safeBounds.bottom),
    );
    // 转换回世界坐标
    return _objectToScreen(clamped) + position;
  }

  /// 获取可玩区域（对象空间），若未计算则返回全图范围
  Rect get _playableBounds {
    final map = tiled.tileMap.map;
    return _playableObjectBounds ??
        Rect.fromLTWH(0, 0, map.width * tileSize.y, map.height * tileSize.y);
  }

  /// 从碰撞矩形中推导出可玩区域。
  /// 碰撞层包含四个长矩形墙壁，它们的内边缘围成实际可通行的地面。
  /// 这样可确保家具摆放和角色寻路使用相同的边界。
  void _calculatePlayableObjectBounds() {
    final map = tiled.tileMap.map;
    final fullWidth = map.width * tileSize.y;
    final fullHeight = map.height * tileSize.y;
    var left = 0.0;
    var top = 0.0;
    var right = fullWidth;
    var bottom = fullHeight;

    // 遍历碰撞矩形，根据其位置和尺寸来收缩可玩区域边界
    for (final rect in _collisionRects) {
      // 水平长墙（宽度占地图宽度 60% 以上）
      if (rect.width >= fullWidth * .6) {
        if (rect.center.dy < fullHeight / 2) {
          // 上墙：将顶部边界下推至墙底
          top = top.clamp(rect.bottom, fullHeight);
        } else {
          // 下墙：将底部边界上推至墙顶
          bottom = bottom.clamp(0, rect.top);
        }
      }
      // 垂直长墙（高度占地图高度 60% 以上）
      if (rect.height >= fullHeight * .6) {
        if (rect.center.dx < fullWidth / 2) {
          // 左墙：将左边界右推至墙右
          left = left.clamp(rect.right, fullWidth);
        } else {
          // 右墙：将右边界左推至墙左
          right = right.clamp(0, rect.left);
        }
      }
    }

    if (left < right && top < bottom) {
      _playableObjectBounds = Rect.fromLTRB(left, top, right, bottom);
      debugPrint(
        '[RestaurantMap] playable object bounds=$_playableObjectBounds',
      );
    }
  }

  /// 将对象空间坐标转换为屏幕空间坐标（等距投影）。
  /// Tiled 的对象层坐标位于未投影的平面，而 Flame 渲染使用屏幕坐标，
  /// 因此需要统一投影。
  Vector2 _objectToScreen(Vector2 point) {
    final scale = tileSize.x / tileSize.y;
    return Vector2(
      (point.x - point.y) * scale / 2 +
          tiled.tileMap.map.height * tileSize.x / 2,
      (point.x + point.y) / 2,
    );
  }

  /// 屏幕空间坐标转对象空间坐标（等距反投影）
  Vector2 _screenToObject(Vector2 point) {
    final shiftedX = point.x - tiled.tileMap.map.height * tileSize.x / 2;
    final scale = tileSize.x / tileSize.y;
    return Vector2(point.y + shiftedX / scale, point.y - shiftedX / scale);
  }

  /// A* 寻路：从 worldStart 到 worldTarget 的世界坐标路径。
  /// 返回路径点列表（包含起点和终点），若无法到达则返回空列表。
  List<Vector2> findPath(Vector2 worldStart, Vector2 worldTarget) {
    final start = _nodeForWorldPosition(worldStart);
    final target = _nodeForWorldPosition(worldTarget);

    // 目标节点不可行走则直接返回空
    if (!_isWalkableNode(target)) return const [];
    if (start == target) return [worldTarget.clone()];

    // A* 算法数据结构
    final open = <_PathNode>[start];
    final cameFrom = <_PathNode, _PathNode>{};
    final gScore = <_PathNode, double>{start: 0};
    final fScore = <_PathNode, double>{start: _heuristic(start, target)};
    final closed = <_PathNode>{};

    while (open.isNotEmpty) {
      // 按 fScore 升序排序，取出最优节点
      open.sort((a, b) {
        return (fScore[a] ?? double.infinity).compareTo(
          fScore[b] ?? double.infinity,
        );
      });

      final current = open.removeAt(0);
      if (current == target) {
        // 找到目标，重建路径
        return _rebuildPath(cameFrom, current, worldTarget);
      }

      closed.add(current);

      // 遍历邻居（8方向）
      for (final neighbor in _neighbors(current)) {
        if (closed.contains(neighbor) || !_isWalkableNode(neighbor)) continue;

        // 移动代价：斜向为 sqrt(2) ≈ 1.414，正交为 1
        final moveCost = neighbor.x == current.x || neighbor.y == current.y
            ? 1.0
            : 1.414;
        final tentativeG = (gScore[current] ?? double.infinity) + moveCost;
        if (tentativeG >= (gScore[neighbor] ?? double.infinity)) continue;

        // 更新最优路径
        cameFrom[neighbor] = current;
        gScore[neighbor] = tentativeG;
        fScore[neighbor] = tentativeG + _heuristic(neighbor, target);
        if (!open.contains(neighbor)) {
          open.add(neighbor);
        }
      }
    }

    // 未找到路径
    return const [];
  }

  /// 将世界坐标映射到路径网格节点（离散化）
  _PathNode _nodeForWorldPosition(Vector2 worldPosition) {
    final local = worldPosition - absolutePosition;
    return _PathNode(
      (local.x / _pathNodeSize).floor(),
      (local.y / _pathNodeSize).floor(),
    );
  }

  /// 根据网格节点计算其中心世界坐标
  Vector2 _worldPositionForNode(_PathNode node) {
    return Vector2(
      node.x * _pathNodeSize + _pathNodeSize / 2,
      node.y * _pathNodeSize + _pathNodeSize / 2,
    ) +
        position;
  }

  /// 判断节点是否可行走（调用 isWalkableAt）
  bool _isWalkableNode(_PathNode node) {
    return isWalkableAt(_worldPositionForNode(node));
  }

  /// 生成节点的 8 个邻居
  Iterable<_PathNode> _neighbors(_PathNode node) sync* {
    for (var y = -1; y <= 1; y++) {
      for (var x = -1; x <= 1; x++) {
        if (x == 0 && y == 0) continue;
        yield _PathNode(node.x + x, node.y + y);
      }
    }
  }

  /// 切比雪夫距离（适用于8方向移动的启发函数）
  double _heuristic(_PathNode a, _PathNode b) {
    final dx = (a.x - b.x).abs();
    final dy = (a.y - b.y).abs();
    return dx > dy ? dx.toDouble() : dy.toDouble();
  }

  /// 从 cameFrom 重建路径，并将终点替换为精确的 worldTarget
  List<Vector2> _rebuildPath(
      Map<_PathNode, _PathNode> cameFrom,
      _PathNode current,
      Vector2 worldTarget,
      ) {
    final nodes = <_PathNode>[current];
    while (cameFrom.containsKey(current)) {
      current = cameFrom[current]!;
      nodes.add(current);
    }

    // 反转节点顺序，将每个节点转为世界坐标
    final points = nodes.reversed.map(_worldPositionForNode).toList();
    // 移除起点（已包含在世界起点），并用精确目标点替换终点
    if (points.isNotEmpty) {
      points
        ..removeAt(0)
        ..add(worldTarget.clone());
    }
    return points;
  }

  /// 从 Tiled 的 'collision' 对象层加载静态碰撞矩形（对象空间）
  void _loadCollisionRects() {
    final collisionLayer = tiled.tileMap.getLayer<ObjectGroup>('collision');
    if (collisionLayer == null) return;

    for (final object in collisionLayer.objects) {
      if (object.width <= 0 || object.height <= 0) continue;
      _collisionRects.add(
        Rect.fromLTWH(object.x, object.y, object.width, object.height),
      );
    }
  }

  /// 从 Tiled 的 'spawn' 对象层加载生成点（对象空间）
  void _loadSpawnPoints() {
    final spawnLayer = tiled.tileMap.getLayer<ObjectGroup>('spawn');
    if (spawnLayer == null) return;

    for (final object in spawnLayer.objects) {
      if (object.name.isEmpty) continue;
      _spawnPoints[object.name] = Vector2(object.x, object.y);
      debugPrint(
        '[RestaurantMap] SPAWN ${object.name}: object='
            '(${object.x}, ${object.y}) screen='
            '${_objectToScreen(Vector2(object.x, object.y))}',
      );
    }
  }

  @override
  void renderDebugMode(Canvas canvas) {
    super.renderDebugMode(canvas);

    // 绘制静态碰撞区域（对象空间 -> 屏幕空间）
    final collisionFill = Paint()
      ..color = const Color(0x55FF1744)
      ..style = PaintingStyle.fill;
    final collisionLine = Paint()
      ..color = const Color(0xFFFF1744)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    for (final rect in _collisionRects) {
      final points = [
        _objectToScreen(Vector2(rect.left, rect.top)),
        _objectToScreen(Vector2(rect.right, rect.top)),
        _objectToScreen(Vector2(rect.right, rect.bottom)),
        _objectToScreen(Vector2(rect.left, rect.bottom)),
      ];
      final path = Path()..moveTo(points.first.x, points.first.y);
      for (final point in points.skip(1)) {
        path.lineTo(point.x, point.y);
      }
      path.close();
      canvas
        ..drawPath(path, collisionFill)
        ..drawPath(path, collisionLine);
    }

    // 绘制动态障碍物（屏幕空间，无需转换）
    final dynamicPaint = Paint()
      ..color = const Color(0x559C27B0)
      ..style = PaintingStyle.fill;
    for (final rect in _dynamicCollisionRects) {
      canvas.drawRect(rect, dynamicPaint);
    }

    // 绘制可玩区域边界（对象空间 -> 屏幕空间）
    final playable = _playableBounds;
    final playablePoints = [
      _objectToScreen(Vector2(playable.left, playable.top)),
      _objectToScreen(Vector2(playable.right, playable.top)),
      _objectToScreen(Vector2(playable.right, playable.bottom)),
      _objectToScreen(Vector2(playable.left, playable.bottom)),
    ];
    final playablePath = Path()
      ..moveTo(playablePoints.first.x, playablePoints.first.y);
    for (final point in playablePoints.skip(1)) {
      playablePath.lineTo(point.x, point.y);
    }
    playablePath.close();
    canvas.drawPath(
      playablePath,
      Paint()
        ..color = const Color(0xFF00E5FF)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );

    // 绘制所有生成点（对象空间 -> 屏幕空间）
    final spawnPaint = Paint()
      ..color = const Color(0xFF00E676)
      ..strokeWidth = 2;
    for (final entry in _spawnPoints.entries) {
      final point = _objectToScreen(entry.value);
      canvas
        ..drawCircle(Offset(point.x, point.y), 5, spawnPaint)
        ..drawLine(
          Offset(point.x - 8, point.y),
          Offset(point.x + 8, point.y),
          spawnPaint,
        )
        ..drawLine(
          Offset(point.x, point.y - 8),
          Offset(point.x, point.y + 8),
          spawnPaint,
        );
    }
  }
}

/// 路径网格节点，用于 A* 寻路
class _PathNode {
  const _PathNode(this.x, this.y);

  final int x;
  final int y;

  @override
  bool operator ==(Object other) {
    return other is _PathNode && x == other.x && y == other.y;
  }

  @override
  int get hashCode => Object.hash(x, y);
}