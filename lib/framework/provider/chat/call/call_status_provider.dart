import 'package:anoxia/common/constants/API.dart';
import 'package:anoxia/framework/network/DioClient.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 房间通话状态
///
/// 记录指定房间当前是否处于通话中及通话开始时间。
class RoomCallStatus {
  /// 是否正在通话
  final bool calling;

  /// 通话开始时间戳（毫秒）
  final int startTime;

  const RoomCallStatus({required this.calling, required this.startTime});

  /// 空闲状态常量
  const RoomCallStatus.idle() : calling = false, startTime = 0;

  /// 从 JSON 构造 [RoomCallStatus] 实例
  factory RoomCallStatus.fromJson(Map<String, dynamic> json) {
    return RoomCallStatus(
      calling: json['calling'] == true,
      startTime: (json['startTime'] as num?)?.toInt() ?? 0,
    );
  }
}

/// 从后端获取房间通话状态
Future<RoomCallStatus> _fetchCallStatus(String roomId) async {
  if (roomId.isEmpty) return const RoomCallStatus.idle();

  final res = await DioClient().get(
    API.callStatus,
    queryParameters: {'roomId': roomId},
  );

  final data = res.data?['data'];
  if (data is Map<String, dynamic>) {
    return RoomCallStatus.fromJson(data);
  }
  return const RoomCallStatus.idle();
}

/// 通话状态控制器
///
/// 管理所有房间的通话状态，支持状态查询和手动更新。
/// 采用 Notifier 模式，支持细粒度更新单个房间状态。
class CallStatusController extends Notifier<Map<String, RoomCallStatus>> {
  /// 已加载过的房间 ID（避免重复请求）
  final Set<String> _loadedRooms = <String>{};

  /// 正在加载的房间 ID（防止并发请求）
  final Set<String> _loadingRooms = <String>{};

  @override
  Map<String, RoomCallStatus> build() => {};

  /// 获取指定房间的通话状态
  RoomCallStatus statusOf(String roomId) {
    if (roomId.isEmpty) return const RoomCallStatus.idle();
    return state[roomId] ?? const RoomCallStatus.idle();
  }

  /// 确保房间状态已加载
  ///
  /// 首次访问时自动从后端获取，之后使用本地缓存
  Future<void> ensureLoaded(String roomId) async {
    if (roomId.isEmpty) return;
    if (_loadedRooms.contains(roomId) || _loadingRooms.contains(roomId)) return;
    await refresh(roomId);
    _loadedRooms.add(roomId);
  }

  /// 刷新指定房间的通话状态
  Future<void> refresh(String roomId) async {
    if (roomId.isEmpty) return;
    if (_loadingRooms.contains(roomId)) return;

    _loadingRooms.add(roomId);
    try {
      final next = await _fetchCallStatus(roomId);
      state = {...state, roomId: next};
    } catch (_) {
      // 忽略网络异常，保持旧状态
    } finally {
      _loadingRooms.remove(roomId);
    }
  }

  /// 标记通话开始
  ///
  /// [startTime] 指定开始时间戳，未指定时使用当前时间
  void markStarted(String roomId, {int? startTime}) {
    if (roomId.isEmpty) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    state = {
      ...state,
      roomId: RoomCallStatus(
        calling: true,
        startTime: startTime != null && startTime > 0 ? startTime : now,
      ),
    };
    _loadedRooms.add(roomId);
  }

  /// 标记通话结束
  void markEnded(String roomId) {
    if (roomId.isEmpty) return;
    state = {...state, roomId: const RoomCallStatus.idle()};
    _loadedRooms.add(roomId);
  }
}

/// 通话状态 Provider
final callStatusControllerProvider =
    NotifierProvider<CallStatusController, Map<String, RoomCallStatus>>(
      CallStatusController.new,
    );

/// 获取指定房间的通话状态（便捷方法）
///
/// 通过 select 优化，仅在目标房间状态变化时重建
final roomCallStatusProvider = Provider.family<RoomCallStatus, String>((ref, roomId) {
  return ref.watch(
    callStatusControllerProvider.select(
      (map) => map[roomId] ?? const RoomCallStatus.idle(),
    ),
  );
});
