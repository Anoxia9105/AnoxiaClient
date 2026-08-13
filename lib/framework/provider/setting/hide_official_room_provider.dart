import 'package:flutter_riverpod/legacy.dart' as legacy;

import '../../../common/utils/sp_util.dart';
import '../../../common/constants/storage_keys.dart';

/// 官方房间显隐状态（持久化）
///
/// true=在会话列表中隐藏官方虚拟房间。
class HideOfficialRoomController extends legacy.StateNotifier<bool> {
  HideOfficialRoomController() : super(_load());

  static bool _load() {
    return SPUtil.instance.getBool(StorageKeys.officialRoomHidden) ?? false;
  }

  void setHidden(bool hidden) {
    if (state == hidden) return;
    state = hidden;
    SPUtil.instance.setBool(StorageKeys.officialRoomHidden, hidden);
  }
}

final hideOfficialRoomProvider =
    legacy.StateNotifierProvider<HideOfficialRoomController, bool>(
      (ref) => HideOfficialRoomController(),
    );
