import 'package:anoxia/framework/domain/ChatMessage.dart';

/// 聊天列表项的展平条目类型
///
/// 使用 sealed 类确保类型安全，只存在两种子类型：
/// - [TimeDividerItem]：时间分隔条
/// - [MessageItem]：消息气泡
sealed class ChatListItem {}

/// 时间分隔条条目
///
/// 用于在消息列表中显示时间分隔，将消息按时间分组
class TimeDividerItem extends ChatListItem {
  /// 时间戳（毫秒）
  final int timestamp;

  TimeDividerItem(this.timestamp);
}

/// 消息气泡条目
///
/// 包装单条消息数据，用于在消息列表中渲染
class MessageItem extends ChatListItem {
  /// 消息数据
  final ChatMessage message;

  MessageItem(this.message);
}

/// 聊天 UI 列表包装类
///
/// 用于解决 Riverpod generator 无法处理 sealed class 列表的问题
class ChatUiListResult {
  /// 聊天列表项
  final List<ChatListItem> items;

  ChatUiListResult(this.items);
}
