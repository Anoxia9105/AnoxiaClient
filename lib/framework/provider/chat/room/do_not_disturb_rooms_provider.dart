// 免打扰房间管理
//
// 维护免打扰房间 ID 集合，支持启用/禁用/切换免打扰状态，并持久化到本地存储。
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../common/utils/sp_util.dart';

/// 免打扰房间 Provider
final doNotDisturbRoomsProvider =
    NotifierProvider<DoNotDisturbRooms, Set<String>>(DoNotDisturbRooms.new);

/// 免打扰房间状态管理
///
/// 从本地存储读取免打扰房间列表，并提供增删改查操作，修改后自动持久化。
class DoNotDisturbRooms extends Notifier<Set<String>> {
  static const String _storageKey = 'chat_do_not_disturb_room_ids';

  @override
  Set<String> build() {
    final list = SPUtil.instance.getStringList(
      _storageKey,
      defValue: const <String>[],
    );
    return (list ?? const <String>[]).toSet();
  }

  /// 设置指定房间的免打扰状态
  ///
  /// [roomId] 房间 ID
  /// [enabled] 是否启用免打扰
  Future<void> setEnabled(String roomId, bool enabled) async {
    final next = Set<String>.of(state);
    if (enabled) {
      next.add(roomId);
    } else {
      next.remove(roomId);
    }
    state = next;
    await SPUtil.instance.setStringList(_storageKey, state.toList());
  }

  /// 切换指定房间的免打扰状态
  ///
  /// [roomId] 房间 ID
  Future<void> toggle(String roomId) {
    return setEnabled(roomId, !state.contains(roomId));
  }

  /// 关闭指定房间的免打扰（即将其从列表中移除）
  ///
  /// [roomId] 房间 ID
  Future<void> remove(String roomId) {
    if (!state.contains(roomId)) return Future.value();
    return setEnabled(roomId, false);
  }

  /// 检查指定房间是否已开启免打扰
  ///
  /// [roomId] 房间 ID
  bool isEnabled(String roomId) => state.contains(roomId);
}
