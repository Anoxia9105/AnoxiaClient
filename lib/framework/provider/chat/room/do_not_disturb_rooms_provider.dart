// 免打扰房间管理
//
// 维护免打扰房间 ID 集合，支持启用/禁用/切换免打扰状态，并持久化到本地存储。
// 数据策略与置顶一致：服务端为真源（会话列表携带 isMuted 时校准本地），
// SP 为旧部署兜底与乐观回显；切换先本地生效再异步推送，失败回滚并提示。
import 'dart:async';

import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../common/utils/sp_util.dart';
import '../../../domain/chat_room_vo.dart';
import '../../../logs/debug_log.dart';
import '../../core/room_repository_provider.dart';
import '../../core/toast_service_provider.dart';

/// 免打扰房间 Provider
final doNotDisturbRoomsProvider =
    NotifierProvider<DoNotDisturbRooms, Set<String>>(DoNotDisturbRooms.new);

/// 免打扰房间状态管理
///
/// 从本地存储读取免打扰房间列表，并提供增删改查操作，修改后自动持久化。
class DoNotDisturbRooms extends Notifier<Set<String>> {
  static const String storageKey = 'chat_do_not_disturb_room_ids';

  @override
  Set<String> build() {
    final list = SPUtil.instance.getStringList(
      storageKey,
      defValue: const <String>[],
    );
    return (list ?? const <String>[]).toSet();
  }

  /// 用服务端会话列表校准本地免打扰状态。
  ///
  /// 仅覆盖响应中出现且显式携带 isMuted 的房间；
  /// 旧部署未返回字段 → 保留本地值（兼容回落）。
  void reconcileFromServer(Iterable<ChatRoomVO> rooms) {
    final next = Set<String>.of(state);
    var changed = false;
    for (final room in rooms) {
      final id = room.roomId;
      final muted = room.isMuted;
      if (id == null || muted == null) continue;
      if (muted == next.contains(id)) continue;
      changed = true;
      if (muted) {
        next.add(id);
      } else {
        next.remove(id);
      }
    }
    if (!changed) return;
    state = next;
    unawaited(SPUtil.instance.setStringList(storageKey, next.toList()));
  }

  /// 设置指定房间的免打扰状态
  ///
  /// [roomId] 房间 ID
  /// [enabled] 是否启用免打扰
  /// [syncToServer] 是否异步推送服务端（本地清理场景如退房传 false）
  Future<void> setEnabled(
    String roomId,
    bool enabled, {
    bool syncToServer = true,
  }) async {
    final previous = Set<String>.of(state);
    if (previous.contains(roomId) == enabled) return;

    final next = Set<String>.of(previous);
    if (enabled) {
      next.add(roomId);
    } else {
      next.remove(roomId);
    }
    state = next;
    await SPUtil.instance.setStringList(storageKey, next.toList());
    if (!syncToServer) return;
    unawaited(_push(roomId, enabled, previous));
  }

  /// 切换指定房间的免打扰状态
  ///
  /// 本地立即生效并持久化，随后异步推送服务端；推送失败回滚本地并提示。
  Future<void> toggle(String roomId) {
    return setEnabled(roomId, !state.contains(roomId));
  }

  /// 关闭指定房间的免打扰（即将其从列表中移除）
  ///
  /// [roomId] 房间 ID
  Future<void> remove(String roomId) {
    if (!state.contains(roomId)) return Future.value();
    return setEnabled(roomId, false, syncToServer: false);
  }

  /// 检查指定房间是否已开启免打扰
  ///
  /// [roomId] 房间 ID
  bool isEnabled(String roomId) => state.contains(roomId);

  Future<void> _push(String roomId, bool enabled, Set<String> previous) async {
    try {
      final ok = await ref
          .read(roomRepositoryProvider)
          .setRoomDoNotDisturb(roomId, enabled);
      if (!ok) throw StateError('server rejected');
    } catch (e, st) {
      if (!_shouldRollback(e)) {
        debugLog('[DoNotDisturbRooms] 推送免打扰被旧部署忽略', e, st);
        return;
      }
      debugLog('[DoNotDisturbRooms] 免打扰同步失败，回滚本地', e, st);
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
}
