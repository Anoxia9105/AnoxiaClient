import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../common/utils/sp_util.dart';

final doNotDisturbRoomsProvider =
    NotifierProvider<DoNotDisturbRooms, Set<String>>(DoNotDisturbRooms.new);

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

  Future<void> toggle(String roomId) {
    return setEnabled(roomId, !state.contains(roomId));
  }

  Future<void> remove(String roomId) {
    if (!state.contains(roomId)) return Future.value();
    return setEnabled(roomId, false);
  }

  bool isEnabled(String roomId) => state.contains(roomId);
}
