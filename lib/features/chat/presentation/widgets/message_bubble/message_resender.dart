/// 消息重发器
///
/// 职责：处理发送失败消息的重发逻辑，包括状态更新、重新发送、超时检测。
/// 独立封装便于单元测试和复用。
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:anoxia/framework/codec/v5/im_packet_v5.dart';
import 'package:anoxia/framework/domain/chat_message.dart';
import 'package:anoxia/framework/logs/debug_log.dart';
import 'package:anoxia/framework/protocol/message/message_enum.dart';
import 'package:anoxia/framework/protocol/message/room_message.dart';
import 'package:anoxia/framework/provider/chat/message/room_message_service.dart';
import 'package:anoxia/framework/provider/ws/ws_controller.dart';

/// 消息重发器（纯静态工具类）
class MessageResender {
  const MessageResender._();

  /// 重发消息
  ///
  /// 步骤：
  /// 1. 将消息状态改为“发送中”
  /// 2. 构造 RoomMessage 并通过 WebSocket 发送
  /// 3. 启动超时定时器，超时后标记为失败
  static void resend(WidgetRef ref, ChatMessage message) {
    final roomId = message.roomId;
    if (roomId == null || roomId.isEmpty) {
      debugLog('重发失败：消息缺少 roomId');
      return;
    }

    final messageNotifier = ref.read(chatMessagesProvider.notifier);
    final wsNotifier = ref.read(wsControllerProvider.notifier);
    final clientMsgId = message.clientMsgId ?? message.messageId ?? '';

    // 先更新状态为“发送中”
    messageNotifier.upsertMessage(
      message.copyWith(deliveryStatus: DeliveryStatus.sending),
    );

    // 构建协议消息并发送
    final protoMsg = RoomMessage(
      messageId: '',
      clientMsgId: clientMsgId,
      roomId: roomId,
      senderId: message.senderId ?? 0,
      messageType: message.messageType ?? MessageType.text,
      payload: message.payload,
      clientTimestamp: DateTime.now().millisecondsSinceEpoch,
    );

    wsNotifier.sendMessage(
      ImPacketV5.encodeRoomMessageFrame(protoMsg),
      clientMsgId: clientMsgId,
      ackTimeout: Duration(seconds: _resendTimeoutSeconds(message)),
    );
  }

  /// 根据消息类型和附件数量计算合理超时时间（秒）
  static int _resendTimeoutSeconds(ChatMessage message) {
    final attachmentCount = message.payload?.mediaAttachments.length ?? 0;
    var timeout = 10 + (attachmentCount * 2);

    if (message.messageType == MessageType.audio ||
        message.messageType == MessageType.file ||
        message.messageType == MessageType.video) {
      timeout += 5; // 大文件额外增加
    }

    return timeout.clamp(10, 30);
  }
}
