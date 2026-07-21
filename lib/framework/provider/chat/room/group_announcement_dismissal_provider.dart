import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../common/utils/SPUtil.dart';

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

  bool isDismissed(String roomId, String announcement) {
    return state[roomId] == announcement;
  }

  Future<void> dismiss(String roomId, String announcement) async {
    state = <String, String>{...state, roomId: announcement};
    await SPUtil.instance.set(_storageKey, jsonEncode(state));
  }
}
