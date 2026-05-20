import 'package:anoxia/framework/domain/ChatMessage.dart';

/// 展平列表的条目类型：时间分隔条 或 消息气泡
sealed class ChatListItem {}

/// 时间分隔条条目
class TimeDividerItem extends ChatListItem {
  final int timestamp;
  TimeDividerItem(this.timestamp);
}

/// 消息气泡条目
class MessageItem extends ChatListItem {
  final ChatMessage message;
  MessageItem(this.message);
}