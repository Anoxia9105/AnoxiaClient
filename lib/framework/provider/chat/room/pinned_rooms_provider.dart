import 'dart:async';

import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../common/utils/sp_util.dart';
import '../../../domain/chat_room_vo.dart';
import '../../../logs/debug_log.dart';
import '../../core/room_repository_provider.dart';
import '../../core/toast_service_provider.dart';

part 'pinned_rooms_provider.g.dart';

/// 聊天置顶房间的 Riverpod Provider
///
/// 数据策略：服务端为真源（会话列表携带 isPinned 时由 [reconcileFromServer]
/// 覆盖本地），本地 SP 存储作为旧部署兜底与乐观回显；切换时先本地生效再异步
/// 推送，推送失败回滚本地并提示。
@Riverpod(keepAlive: true)
class PinnedRooms extends _$PinnedRooms {
  /// 本地存储的 key
  static const String storageKey = 'chat_pinned_room_ids';

  /// 初始化方法，从本地存储加载置顶房间 ID 集合
  @override
  Set<String> build() {
    final list = SPUtil.instance.getStringList(
      storageKey,
      defValue: const <String>[],
    );
    // 转换为 Set，避免重复
    return (list ?? const <String>[]).toSet();
  }

  /// 用服务端会话列表校准本地置顶状态。
  ///
  /// 仅覆盖响应中出现且显式携带 isPinned 的房间：
  /// - 服务端未返回该字段（旧部署/未查询）→ 保留本地值（兼容回落）；
  /// - 不在响应里的房间 → 不动本地（离线兜底仍生效）。
  void reconcileFromServer(Iterable<ChatRoomVO> rooms) {
    final next = Set<String>.of(state);
    var changed = false;
    for (final room in rooms) {
      final id = room.roomId;
      final pinned = room.isPinned;
      if (id == null || pinned == null) continue;
      if (pinned == next.contains(id)) continue;
      changed = true;
      if (pinned) {
        next.add(id);
      } else {
        next.remove(id);
      }
    }
    if (!changed) return;
    state = next;
    unawaited(SPUtil.instance.setStringList(storageKey, next.toList()));
  }

  /// 切换某个房间的置顶状态
  ///
  /// 如果已置顶则取消，否则添加。本地立即生效并持久化，同时异步推送服务端；
  /// 推送失败时回滚本地状态（旧部署无接口的 404/405/501 静默保留本地）。
  Future<void> toggle(String roomId) {
    return setPinned(roomId, !state.contains(roomId));
  }

  /// 设置某个房间的置顶状态
  ///
  /// 本地立即生效并持久化，随后异步推送服务端；仅在状态确有变化时推送。
  Future<void> setPinned(String roomId, bool pinned) async {
    final previous = Set<String>.of(state);
    if (previous.contains(roomId) == pinned) return;

    final next = Set<String>.of(previous);
    if (pinned) {
      next.add(roomId);
    } else {
      next.remove(roomId);
    }
    state = next;
    await SPUtil.instance.setStringList(storageKey, next.toList());
    unawaited(_push(roomId, pinned, previous));
  }

  Future<void> _push(String roomId, bool pinned, Set<String> previous) async {
    try {
      final ok =
          await ref.read(roomRepositoryProvider).setRoomPinned(roomId, pinned);
      if (!ok) throw StateError('server rejected');
    } catch (e, st) {
      if (!_shouldRollback(e)) {
        debugLog('[PinnedRooms] 推送置顶被旧部署忽略', e, st);
        return;
      }
      debugLog('[PinnedRooms] 置顶同步失败，回滚本地', e, st);
      state = previous;
      unawaited(SPUtil.instance.setStringList(storageKey, previous.toList()));
      ref
          .read(toastServiceProvider)
          .showToast('chat_room_settings_sync_failed'.tr());
    }
  }

  /// 旧部署无接口（404/405/501）时不回滚不提示：保留本地值即现行本地行为。
  bool _shouldRollback(Object error) {
    if (error is DioException) {
      final status = error.response?.statusCode;
      return status != 404 && status != 405 && status != 501;
    }
    return true;
  }

  /// 判断某个房间是否已置顶
  bool isPinned(String roomId) => state.contains(roomId);
}
