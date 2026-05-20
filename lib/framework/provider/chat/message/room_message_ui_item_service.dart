import 'package:anoxia/features/chat/ui_models/message_item.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'room_message_service.dart';

part 'room_message_ui_item_service.g.dart';

/// 专门为某个房间计算 [时间条 + 消息] 混合平铺列表的 ViewProvider
/// 针对反转列表设计：返回的 List 中 index 0 代表最底部最新的消息
@riverpod
List<ChatListItem> chatUiList(Ref ref, String roomId) {
  final messages = ref.watch(chatMessagesProvider.select((state) => state[roomId] ?? []));
  
  if (messages.isEmpty) return const [];

  final List<ChatListItem> items = [];
  const int thirtyMinutesMs = 30 * 60 * 1000; 

  // 正序遍历原始消息（旧到新），保证时间间隔计算正确
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

  // 核心：直接反转列表，使 index 0 对应最新消息，完美适配 reverse: true
  return items.reversed.toList();
}
