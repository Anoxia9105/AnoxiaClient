import 'package:anoxia/framework/domain/chat_message.dart';
import 'package:anoxia/features/chat/models/message_item.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'room_message_service.dart';

part 'room_message_ui_item_service.g.dart';

/// 聊天 UI 列表计算服务
///
/// 专门为某个房间计算「时间条 + 消息」混合平铺列表的 ViewProvider。
/// 针对反转列表设计：返回的 List 中 index 0 代表最底部最新的消息。
///
/// 该服务会自动在消息之间插入时间分隔条，规则如下：
/// - 第一条消息前显示时间分隔条
/// - 两条消息时间间隔超过 30 分钟时显示时间分隔条
///
/// 缓存策略：基于消息列表的引用相等性（identity）做缓存。
/// 当 window 扩大或新消息到达时，消息列表引用会变化，此时全量重算；
/// 当引用未变时，直接返回缓存结果，避免不必要的 O(n) 计算。
@riverpod
ChatUiListResult chatUiList(Ref ref, String roomId) {
  final messages = ref.watch(roomMessagesProvider(roomId)).value ?? const [];

  return _chatUiListCache.compute(messages);
}

/// 时间分隔条计算缓存
///
/// 利用 Dart 的对象引用相等性（identity）判断消息列表是否变化。
/// 只有当消息列表引用真正变化时才重新计算时间分隔条。
class _ChatUiListCache {
  List<ChatMessage>? _lastMessages;
  ChatUiListResult? _lastResult;

  ChatUiListResult compute(List<ChatMessage> messages) {
    if (messages.isEmpty) {
      _lastMessages = null;
      _lastResult = null;
      return ChatUiListResult(const []);
    }
    // 引用相等：同一个 List 对象，直接返回缓存
    if (identical(messages, _lastMessages) && _lastResult != null) {
      return _lastResult!;
    }
    _lastMessages = messages;
    _lastResult = _buildList(messages);
    return _lastResult!;
  }

  ChatUiListResult _buildList(List<ChatMessage> messages) {
    final List<ChatListItem> items = [];
    const int thirtyMinutesMs = 30 * 60 * 1000;

    for (int i = 0; i < messages.length; i++) {
      final msg = messages[i];
      final prevMsg = i > 0 ? messages[i - 1] : null;

      bool showTime = false;
      if (prevMsg == null) {
        showTime = true;
      } else if (msg.timestamp != null && prevMsg.timestamp != null) {
        final diff = msg.timestamp! - prevMsg.timestamp!;
        showTime = diff > thirtyMinutesMs;
      }

      if (showTime && msg.timestamp != null) {
        items.add(TimeDividerItem(msg.timestamp!));
      }
      items.add(MessageItem(msg));
    }

    return ChatUiListResult(items.reversed.toList());
  }
}

final _chatUiListCache = _ChatUiListCache();
