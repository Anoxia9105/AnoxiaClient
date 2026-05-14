import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../common/utils/SPUtil.dart';


part 'pinned_rooms_provider.g.dart';

@riverpod
class PinnedRooms extends _$PinnedRooms {
  static const String _storageKey = 'chat_pinned_room_ids';

  @override
  Set<String> build() {
    final list = SPUtil.instance.getStringList(
      _storageKey,
      defValue: const <String>[],
    );
    return (list ?? const <String>[]).toSet();
  }

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

  // 辅助方法：判断是否置顶
  bool isPinned(String roomId) => state.contains(roomId);
}