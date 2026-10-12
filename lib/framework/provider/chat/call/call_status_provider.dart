import 'package:anoxia/framework/domain/room_call_status.dart';
import 'package:anoxia/framework/provider/core/call_repository_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/widgets.dart';
import 'dart:async';

/// 通话状态控制器
///
/// 管理所有房间的通话状态，支持状态查询和手动更新。
/// 采用 Notifier 模式，支持细粒度更新单个房间状态。
class CallStatusController extends Notifier<Map<String, RoomCallStatus>> {
  /// 已加载过的房间 ID（避免重复请求）
  final Set<String> _loadedRooms = <String>{};

  /// 正在加载的房间 ID（防止并发请求）
  final Set<String> _loadingRooms = <String>{};
  final Map<String, int> _revisions = {};
  final Map<String, DateTime> _loadedAt = {};
  final Set<String> _refreshAfterResume = {};

  @override
  Map<String, RoomCallStatus> build() {
    final lifecycle = AppLifecycleListener(
      onResume: () {
        // 锁屏期间事件可能丢失，恢复前台时以服务端状态补偿。
        final rooms = {...state.keys, ..._loadedRooms};
        _loadedRooms.clear();
        _loadedAt.clear();
        for (final roomId in rooms) {
          _revisions[roomId] = (_revisions[roomId] ?? 0) + 1;
          if (_loadingRooms.contains(roomId)) {
            _refreshAfterResume.add(roomId);
            continue;
          }
          unawaited(refresh(roomId));
        }
      },
    );
    ref.onDispose(lifecycle.dispose);
    return {};
  }

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
    final loadedAt = _loadedAt[roomId];
    if (_loadingRooms.contains(roomId) ||
        (_loadedRooms.contains(roomId) &&
            loadedAt != null &&
            DateTime.now().difference(loadedAt) <
                const Duration(seconds: 15))) {
      return;
    }
    await refresh(roomId);
  }

  /// 刷新指定房间的通话状态
  Future<void> refresh(String roomId) async {
    if (roomId.isEmpty) return;
    if (_loadingRooms.contains(roomId)) return;

    _loadingRooms.add(roomId);
    final revision = _revisions[roomId] ?? 0;
    try {
      final next = await ref
          .read(callRepositoryProvider)
          .fetchCallStatus(roomId);
      if (!ref.mounted || (_revisions[roomId] ?? 0) != revision) return;
      state = {...state, roomId: next};
      _loadedRooms.add(roomId);
      _loadedAt[roomId] = DateTime.now();
    } catch (_) {
      // 忽略网络异常，保持旧状态
    } finally {
      _loadingRooms.remove(roomId);
      if (ref.mounted && _refreshAfterResume.remove(roomId)) {
        unawaited(refresh(roomId));
      }
    }
  }

  /// 标记通话开始
  ///
  /// [startTime] 指定开始时间戳，未指定时使用当前时间
  void markStarted(String roomId, {int? startTime}) {
    if (roomId.isEmpty) return;
    _revisions[roomId] = (_revisions[roomId] ?? 0) + 1;
    final now = DateTime.now().millisecondsSinceEpoch;
    state = {
      ...state,
      roomId: RoomCallStatus(
        calling: true,
        startTime: startTime != null && startTime > 0 ? startTime : now,
      ),
    };
    _loadedRooms.add(roomId);
    _loadedAt[roomId] = DateTime.now();
  }

  /// 标记通话结束
  void markEnded(String roomId) {
    if (roomId.isEmpty) return;
    _revisions[roomId] = (_revisions[roomId] ?? 0) + 1;
    state = {...state, roomId: const RoomCallStatus.idle()};
    _loadedRooms.add(roomId);
    _loadedAt[roomId] = DateTime.now();
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
final roomCallStatusProvider = Provider.family<RoomCallStatus, String>((
  ref,
  roomId,
) {
  return ref.watch(
    callStatusControllerProvider.select(
      (map) => map[roomId] ?? const RoomCallStatus.idle(),
    ),
  );
});
