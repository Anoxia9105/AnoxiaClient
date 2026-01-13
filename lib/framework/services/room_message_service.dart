import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/ChatMessage.dart';
import '../protocol/message/RoomMessage.dart';
import '../protocol/PacketType.dart';
import '../provider/ws/ws_controller.dart';
import '../logs/talker.dart';

part 'room_message_service.g.dart';

/// 存储每个房间的消息列表
/// key = roomId, value = List<ChatMessage>
@riverpod
class ChatMessages extends _$ChatMessages {
  @override
  Map<String, List<ChatMessage>> build() {
    // 1️⃣ 获取 WebSocket 消息流
    final stream = ref.watch(wsControllerProvider.notifier).messageStream;

    // 2️⃣ 订阅消息流，只关注 PacketType.message 类型
    final subscription = stream
        .where((frame) => frame.topic == PacketType.message)
        .map((frame) => frame.data as RoomMessage)
        .listen(_handleRoomMessage);

    // 3️⃣ 当 Provider 销毁时取消订阅，防止内存泄漏
    ref.onDispose(() {
      log.info("聊天消息服务销毁，取消订阅");
      subscription.cancel();
    });

    return {}; // 初始状态为空 Map
  }

  /// 内部处理 RoomMessage 并转换为 ChatMessage
  void _handleRoomMessage(RoomMessage msg) {
    final chatMessage = ChatMessage(
      messageId: msg.messageId,
      roomId: msg.roomId,
      senderId: msg.senderId.toInt(),
      messageType: msg.type,
      content: msg.payload?.content ?? '',
      payload: msg.payload,
      attachments: msg.attachments,
      extra: msg.extra,
      messageStatus: msg.state,
      timestamp: msg.timestamp.toInt(),
      seq: msg.seq.toInt(),
    );

    _addMessage(chatMessage);
  }

  /// 添加消息到对应房间
  void _addMessage(ChatMessage msg) {
    final roomId = msg.roomId ?? "system";

    // 获取当前房间旧消息
    final currentRoomMessages = state[roomId] ?? [];

    const int maxMessagePerRoom = 100; // 房间内最大消息数
    List<ChatMessage> newList = [...currentRoomMessages, msg];

    // 超过阈值则裁剪最旧消息
    if (newList.length > maxMessagePerRoom) {
      newList = newList.sublist(newList.length - maxMessagePerRoom);
      log.info("房间 $roomId 超过内存阈值，执行自动清理");
    }

    // 更新状态，必须创建新 Map 才能触发 UI 刷新
    state = {...state, roomId: newList};
  }

  /// 清空某个房间消息
  void clearRoom(String roomId) {
    state = {...state, roomId: []};
  }

  /// 获取总消息数量，用于调试或内存监控
  int get totalMessageCount {
    return state.values.fold(0, (sum, list) => sum + list.length);
  }
}
