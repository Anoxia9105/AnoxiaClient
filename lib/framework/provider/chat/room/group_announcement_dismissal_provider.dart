/// 群公告关闭状态管理。
///
/// 记录每个房间中被关闭的公告内容，当公告内容变更时自动重新显示。
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../common/utils/sp_util.dart';

/// 群公告关闭状态的全局提供者。
final groupAnnouncementDismissalProvider =
    NotifierProvider<GroupAnnouncementDismissal, Map<String, String>>(
      GroupAnnouncementDismissal.new,
    );

/// Records the exact announcement content dismissed in each room.
/// A changed announcement no longer matches and is therefore shown again.
class GroupAnnouncementDismissal extends Notifier<Map<String, String>> {
  static const String _storageKey = 'chat_group_announcement_dismissed_content';

  @override
  Map<String, String> build() {
    final raw = SPUtil.instance.get(_storageKey);
    if (raw == null || raw.isEmpty) return const <String, String>{};

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return const <String, String>{};
      return decoded.map(
        (key, value) => MapEntry(key.toString(), value.toString()),
      );
    } catch (_) {
      return const <String, String>{};
    }
  }

  /// 检查指定房间的公告是否已被关闭。
  ///
  /// [roomId] 房间 ID。
  /// [announcement] 公告内容，与关闭时记录的内容完全匹配才视为已关闭。
  bool isDismissed(String roomId, String announcement) {
    return state[roomId] == announcement;
  }

  /// 关闭指定房间的公告。
  ///
  /// [roomId] 房间 ID。
  /// [announcement] 公告内容，将持久化存储。
  Future<void> dismiss(String roomId, String announcement) async {
    state = <String, String>{...state, roomId: announcement};
    await SPUtil.instance.set(_storageKey, jsonEncode(state));
  }
}
