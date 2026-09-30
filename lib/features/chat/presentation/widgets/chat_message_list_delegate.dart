import 'package:anoxia/features/chat/models/message_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_list_view/flutter_list_view.dart';

/// 聊天列表的条目身份与复用配置，移动端、桌面端和 Web 共用。
FlutterListViewDelegate buildChatMessageListDelegate(
  List<ChatListItem> items,
  Widget Function(BuildContext, ChatListItem) builder,
) {
  String itemKey(int index) {
    final item = items[index];
    if (item is TimeDividerItem) return 'time:${item.timestamp}';
    final message = (item as MessageItem).message;
    // ACK 会补上服务端 ID；客户端 ID 在发送、落库、确认期间保持不变。
    if (message.clientMsgId?.isNotEmpty == true) {
      return 'client:${message.clientMsgId}';
    }
    if (message.messageId?.isNotEmpty == true) {
      return 'server:${message.messageId}';
    }
    return 'index:$index';
  }

  return FlutterListViewDelegate(
    (context, index) {
      final item = items[index];
      return KeyedSubtree(
        key: ValueKey(itemKey(index)),
        child: builder(context, item),
      );
    },
    childCount: items.length,
    // 仅子组件的 ValueKey 不够：列表内部也必须按消息身份而非索引复用。
    onItemKey: itemKey,
    keepPosition: false,
    addAutomaticKeepAlives: false,
  );
}
