import 'package:anoxia/framework/domain/chat_message.dart';

typedef ChatAiHistoryReader =
    Future<List<ChatMessage>> Function({required int limit, int? beforeSeq});

/// 只读、限量补充当前房间的本地历史；失败降级，不触发同步或远端拉取。
Future<List<ChatMessage>> loadChatAiContextMessages({
  required String roomId,
  required List<ChatMessage> loaded,
  required ChatAiHistoryReader readHistory,
  ChatMessage? quotedMessage,
}) async {
  final history = <ChatMessage>[];
  try {
    history.addAll(
      await readHistory(limit: 50).timeout(const Duration(seconds: 2)),
    );
  } catch (_) {}
  if (quotedMessage?.roomId == roomId && (quotedMessage?.seq ?? 0) > 0) {
    try {
      history.addAll(
        await readHistory(
          limit: 8,
          beforeSeq: quotedMessage!.seq! + 3,
        ).timeout(const Duration(seconds: 2)),
      );
    } catch (_) {}
  }
  return mergeChatAiContextMessages(roomId, [...history, ...loaded]);
}

/// 已加载的新状态覆盖同 ID 的缓存快照，稳定保留无 ID 消息的相对顺序。
List<ChatMessage> mergeChatAiContextMessages(
  String roomId,
  List<ChatMessage> messages,
) {
  final indexed = <String, ChatMessage>{};
  for (final message in messages) {
    if (message.roomId != roomId) continue;
    final key =
        message.messageId ??
        message.clientMsgId ??
        'anonymous:${identityHashCode(message)}';
    indexed[key] = message;
  }
  final result = indexed.values.toList();
  final order = {for (var i = 0; i < result.length; i++) result[i]: i};
  result.sort((a, b) {
    if (a.seq != null || b.seq != null) {
      if (a.seq == null) return 1;
      if (b.seq == null) return -1;
      final seq = a.seq!.compareTo(b.seq!);
      if (seq != 0) return seq;
    }
    final time = (a.timestamp ?? 0).compareTo(b.timestamp ?? 0);
    return time == 0 ? order[a]!.compareTo(order[b]!) : time;
  });
  return result;
}
