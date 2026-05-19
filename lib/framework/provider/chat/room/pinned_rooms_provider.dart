import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../common/utils/SPUtil.dart';

part 'pinned_rooms_provider.g.dart';

/// 聊天置顶房间的 Riverpod Provider
@riverpod
class PinnedRooms extends _$PinnedRooms {
  /// 本地存储的 key
  static const String _storageKey = 'chat_pinned_room_ids';

  /// 初始化方法，从本地存储加载置顶房间 ID 集合
  @override
  Set<String> build() {
    final list = SPUtil.instance.getStringList(
      _storageKey,
      defValue: const <String>[],
    );
    // 转换为 Set，避免重复
    return (list ?? const <String>[]).toSet();
  }

  /// 切换某个房间的置顶状态
  /// 如果已置顶则取消，否则添加
  Future<void> toggle(String roomId) async {
    final next = Set<String>.of(state);

    if (next.contains(roomId)) {
      next.remove(roomId);
    } else {
      next.add(roomId);
    }

    state = next;

    // 保存到本地
    await SPUtil.instance.setStringList(_storageKey, state.toList());
  }

  /// 判断某个房间是否已置顶
  bool isPinned(String roomId) => state.contains(roomId);
}